#!/usr/bin/env perl
#
# cwf-manage-fix-security.t — Integration tests for the `fix-security` subcommand.
#
# Each test copies the repo's .cwf/ into a tempdir, mutates the fixture, then
# runs `perl -I$tmp/.cwf/lib $tmp/.cwf/scripts/cwf-manage fix-security`
# (cwd = $tmp) and asserts on exit code, captured combined output, and
# resulting filesystem state.
#
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);

my $REPO_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));

# build_fixture()
# Returns a fresh tempdir with a working .cwf/ copied from the repo, plus a
# minimal git repo (cwf-manage's find_git_root requires .git/).
sub build_fixture {
    my $tmp = tempdir(CLEANUP => 1);
    # -p preserves perms (without it, perms are ANDed with the user's umask,
    # which would drop 0755 to 0700 under umask 077 and produce false-positive
    # permission violations).
    my $rc = system("cp", "-rp", "$REPO_ROOT/.cwf", "$tmp/.cwf");
    die "cp .cwf failed (rc=$rc)" if $rc != 0;
    system("git", "-C", $tmp, "init", "-q") == 0 or die "git init failed";
    return $tmp;
}

# run_fix_security($tmp)
# Runs `cwf-manage fix-security` in $tmp. Returns ($exit_code, $combined_output).
sub run_fix_security {
    my ($tmp) = @_;
    my $cwd = getcwd();
    chdir $tmp or die "chdir $tmp: $!";
    # Invoke via perl rather than direct exec: this is the bootstrap
    # surface — fixtures intentionally strip exec bits, so direct
    # invocation would fail to exec.
    my $output = `perl -I.cwf/lib .cwf/scripts/cwf-manage fix-security 2>&1`;
    my $rc = $? >> 8;
    chdir $cwd or die "chdir back: $!";
    return ($rc, $output);
}

sub run_validate {
    my ($tmp) = @_;
    my $cwd = getcwd();
    chdir $tmp or die "chdir $tmp: $!";
    my $output = `perl -I.cwf/lib .cwf/scripts/cwf-manage validate 2>&1`;
    my $rc = $? >> 8;
    chdir $cwd or die "chdir back: $!";
    return ($rc, $output);
}

sub strip_perms_recursive {
    my ($dir) = @_;
    my $rc = system("find", $dir, "-type", "f", "-exec", "chmod", "0644", "{}", ";");
    die "chmod 0644 failed" if $rc != 0;
}

sub file_perms {
    my ($path) = @_;
    return (stat($path))[2] & 07777;
}

sub append_byte {
    my ($path) = @_;
    open my $fh, '>>', $path or die "append $path: $!";
    print $fh "X";
    close $fh;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "read $path: $!";
    local $/;
    my $c = <$fh>;
    close $fh;
    return $c;
}

#==============================================================================

subtest 'TC-1: clean install — no-op, exit 0' => sub {
    plan tests => 3;
    my $tmp = build_fixture();
    my ($rc, $out) = run_fix_security($tmp);
    is($rc, 0, 'exit 0 on clean install');
    like($out, qr{repaired 0 file}i, 'reports zero repairs');
    my ($vrc) = run_validate($tmp);
    is($vrc, 0, 'validate still passes after no-op');
};

subtest 'TC-2: stripped perms, sha intact — repair to recorded perms' => sub {
    plan tests => 5;
    my $tmp = build_fixture();
    strip_perms_recursive("$tmp/.cwf/scripts");

    # Sanity: pre-validate must fail on permissions
    my ($pre_rc, $pre_out) = run_validate($tmp);
    isnt($pre_rc, 0, 'pre-validate fails (perms wrong)');
    like($pre_out, qr{permissions}, 'pre-validate names "permissions" field');

    my ($rc, $out) = run_fix_security($tmp);
    is($rc, 0, 'fix-security exits 0 after repair');

    # Post-validate must pass
    my ($post_rc) = run_validate($tmp);
    is($post_rc, 0, 'post-validate passes');

    # cwf-manage entry recorded as 0700 in script-hashes.json — verify exact perms restored
    my $cwf_manage = "$tmp/.cwf/scripts/cwf-manage";
    is(file_perms($cwf_manage), 0700, "cwf-manage perms restored to recorded 0700 (not blanket 0755)");
};

subtest 'TC-3: sha mismatch — refuse, no chmod, recovery hint' => sub {
    plan tests => 6;
    my $tmp = build_fixture();
    # Tamper a script that fix-security itself does NOT depend on at runtime.
    # Cannot tamper cwf-manage here because we run cwf-manage to detect the tamper.
    my $target = "$tmp/.cwf/scripts/command-helpers/cwf-set-status";
    append_byte($target);
    chmod 0644, $target;

    my ($rc, $out) = run_fix_security($tmp);
    is($rc, 1, 'exit 1 on sha mismatch');
    like($out, qr{sha256}, 'output names sha256 field');
    like($out, qr{cwf-set-status}, 'output names tampered file');
    like($out, qr{git pull}, 'recovery hint mentions git pull');
    like($out, qr{cwf-manage update}, 'recovery hint mentions cwf-manage update');

    is(file_perms($target), 0644, 'tampered file perms unchanged (no chmod attempted)');
};

subtest 'TC-4: missing tracked file — refuse, recovery hint, best-effort fix on others' => sub {
    plan tests => 6;
    my $tmp = build_fixture();
    my $missing = "$tmp/.cwf/scripts/command-helpers/task-stack";
    unlink $missing or die "unlink $missing: $!";

    # Strip a different file's perms so we can verify best-effort fix
    my $other = "$tmp/.cwf/scripts/cwf-manage";
    chmod 0644, $other;

    my ($rc, $out) = run_fix_security($tmp);
    is($rc, 1, 'exit 1 on missing file');
    like($out, qr{existence}, 'output names existence field');
    like($out, qr{task-stack}, 'output names missing file');
    like($out, qr{git pull}, 'recovery hint mentions git pull');
    like($out, qr{cwf-manage update}, 'recovery hint mentions cwf-manage update');

    # Best-effort: the still-present file should have been repaired
    is(file_perms($other), 0700, 'other file repaired (best-effort fix despite unfixable peer)');
};

subtest 'TC-5: mixed — repair fixable, refuse unfixable' => sub {
    plan tests => 5;
    my $tmp = build_fixture();
    # File A: strip perms, sha intact
    my $fileA = "$tmp/.cwf/scripts/cwf-manage";
    chmod 0644, $fileA;
    # File B: tamper
    my $fileB = "$tmp/.cwf/scripts/command-helpers/task-stack";
    append_byte($fileB);

    my ($rc, $out) = run_fix_security($tmp);
    is($rc, 1, 'exit 1 because of unfixable B');
    like($out, qr{cwf-manage},   'output mentions repaired A');
    like($out, qr{task-stack},   'output mentions unfixable B');

    is(file_perms($fileA), 0700, 'fixable A repaired');
    # B sha mismatch — no chmod attempted, content unchanged
    like(slurp($fileB), qr{X$}, 'tampered B content unchanged');
};

subtest 'TC-6: unparseable hashes file — exit 1, recovery hint' => sub {
    plan tests => 4;
    my $tmp = build_fixture();
    my $hashes = "$tmp/.cwf/security/script-hashes.json";
    open my $fh, '>', $hashes or die "overwrite hashes: $!";
    print $fh "not-json\n";
    close $fh;

    my ($rc, $out) = run_fix_security($tmp);
    is($rc, 1, 'exit 1 on unparseable hashes file');
    like($out, qr{script-hashes\.json}, 'output names hashes file');
    like($out, qr{git pull}, 'recovery hint mentions git pull');
    like($out, qr{cwf-manage update}, 'recovery hint mentions cwf-manage update');
};

subtest 'TC-7: idempotency — second run is a no-op' => sub {
    plan tests => 3;
    my $tmp = build_fixture();
    strip_perms_recursive("$tmp/.cwf/scripts");

    # First run repairs
    my ($rc1) = run_fix_security($tmp);
    is($rc1, 0, 'first run exits 0');

    # Second run: nothing to do
    my ($rc2, $out2) = run_fix_security($tmp);
    is($rc2, 0, 'second run exits 0');
    like($out2, qr{repaired 0 file}i, 'second run reports zero repairs');
};

done_testing();
