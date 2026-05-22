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
use Fcntl qw(:mode);
use JSON::PP qw(decode_json);

my $REPO_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));

# Reads the recorded `permissions` value for an entry from script-hashes.json
# and returns it as an octal integer (e.g. "0700" → 0700). Source of truth
# for every chmod and assertion in this test — no magic numbers.
sub _read_recorded_perms {
    my ($tmp, $entry_name) = @_;
    my $hashes = "$tmp/.cwf/security/script-hashes.json";
    open my $fh, '<', $hashes or die "$hashes: $!";
    local $/;
    my $json = decode_json(<$fh>);
    close $fh;
    my $perms = $json->{scripts}{$entry_name}{permissions}
        or die "no permissions recorded for $entry_name";
    return oct($perms);
}

# Bootstrap: ensure cwf-manage is executable before we exec it directly.
# Mirrors /cwf-init step 1a — chmod to recorded perms (read from JSON, no
# magic numbers). Idempotent; skips when user-x is already set.
sub _ensure_cwf_manage_executable {
    my ($tmp) = @_;
    my $cwf_manage = "$tmp/.cwf/scripts/cwf-manage";
    my $current = (stat($cwf_manage))[2] & 07777;
    return if $current & S_IXUSR;
    chmod _read_recorded_perms($tmp, 'cwf-manage'), $cwf_manage
        or die "chmod $cwf_manage: $!";
}

# _provision_extra_manifest_paths($tmp)
# build_fixture copies .cwf/ wholesale (the cwf-manage runtime tree), but the
# hash manifest also tracks paths *outside* .cwf/ (currently .claude/agents/*.md).
# cmd_validate/cmd_fix_security resolve every manifest path against the fixture
# git root ("$git_root/$rel"), so those files must exist there too or they read
# as missing. Copy each manifest-tracked path whose top segment is not ".cwf".
#
# Read $REPO_ROOT's manifest (byte-identical to the copy just made under $tmp;
# reading $REPO_ROOT keeps this independent of copy ordering — do NOT "align" it
# with _read_recorded_perms's $tmp read). Manifest paths are repo-controlled,
# integrity-tracked, repo-relative strings (no "..", no absolute) — the same
# trust cmd_fix_security places in them at cwf-manage:743. cp -p preserves perms
# (umask-independence) and yields byte-identical content, so the fixture
# satisfies the existence / SHA256 / perm-floor checks.
sub _provision_extra_manifest_paths {
    my ($tmp) = @_;
    my $manifest = "$REPO_ROOT/.cwf/security/script-hashes.json";
    open my $fh, '<', $manifest or die "$manifest: $!";
    local $/;
    my $data = decode_json(<$fh>);
    close $fh;

    for my $section (sort keys %$data) {
        my $entries = $data->{$section};
        next unless ref $entries eq 'HASH';          # skip scalar sections (version, last_updated)
        for my $name (sort keys %$entries) {
            my $entry = $entries->{$name};
            next unless ref $entry eq 'HASH' && exists $entry->{path};
            my $rel = $entry->{path};
            next if $rel =~ m{^\.cwf/};               # .cwf/ already copied wholesale
            # Fail closed: $rel is integrity-tracked + repo-relative today; guard
            # anyway so a future/untrusted manifest can't escape $tmp via the cp.
            die "refusing unsafe manifest path: $rel"
                if $rel =~ m{(?:^/|(?:^|/)\.\.(?:/|$))};
            my $src = "$REPO_ROOT/$rel";
            my $dst = "$tmp/$rel";
            (my $dir = $dst) =~ s{/[^/]+$}{};
            my $mrc = system("mkdir", "-p", $dir);
            die "mkdir -p $dir failed (rc=$mrc)" if $mrc != 0;
            my $crc = system("cp", "-p", $src, $dst);
            die "cp -p $rel into fixture failed (rc=$crc)" if $crc != 0;
        }
    }
}

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
    _provision_extra_manifest_paths($tmp);
    return $tmp;
}

# Run a cwf-manage subcommand against the fixture, returning ($exit_code, $output).
# The bootstrap helper ensures cwf-manage is executable before exec.
sub _run_cwf_manage {
    my ($tmp, $subcmd) = @_;
    _ensure_cwf_manage_executable($tmp);
    my $cwd = getcwd();
    chdir $tmp or die "chdir $tmp: $!";
    my $output = `.cwf/scripts/cwf-manage $subcmd 2>&1`;
    my $rc = $? >> 8;
    chdir $cwd or die "chdir back: $!";
    return ($rc, $output);
}

sub run_fix_security { _run_cwf_manage($_[0], 'fix-security') }
sub run_validate     { _run_cwf_manage($_[0], 'validate')     }

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

    # cwf-manage's recorded perms come from script-hashes.json (no magic numbers).
    my $cwf_manage = "$tmp/.cwf/scripts/cwf-manage";
    is(file_perms($cwf_manage), _read_recorded_perms($tmp, 'cwf-manage'),
       "cwf-manage perms restored to recorded value (not blanket 0755)");
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

    # Strip a non-bootstrap file's perms so fix-security's chmod path is exercised
    # on a target other than cwf-manage (which the bootstrap helper restores).
    my $other = "$tmp/.cwf/scripts/command-helpers/cwf-version-tag";
    chmod 0644, $other;

    my ($rc, $out) = run_fix_security($tmp);
    is($rc, 1, 'exit 1 on missing file');
    like($out, qr{existence}, 'output names existence field');
    like($out, qr{task-stack}, 'output names missing file');
    like($out, qr{git pull}, 'recovery hint mentions git pull');
    like($out, qr{cwf-manage update}, 'recovery hint mentions cwf-manage update');

    # Best-effort: the still-present file should have been repaired
    is(file_perms($other), _read_recorded_perms($tmp, 'cwf-version-tag'),
       'other file repaired (best-effort fix despite unfixable peer)');
};

subtest 'TC-5: mixed — repair fixable, refuse unfixable' => sub {
    plan tests => 5;
    my $tmp = build_fixture();
    # File A: strip perms, sha intact. Use a non-bootstrap script so fix-security's
    # chmod path is exercised on a target the bootstrap helper does not touch.
    my $fileA = "$tmp/.cwf/scripts/command-helpers/cwf-version-tag";
    chmod 0644, $fileA;
    # File B: tamper
    my $fileB = "$tmp/.cwf/scripts/command-helpers/task-stack";
    append_byte($fileB);

    my ($rc, $out) = run_fix_security($tmp);
    is($rc, 1, 'exit 1 because of unfixable B');
    like($out, qr{cwf-version-tag}, 'output mentions repaired A');
    like($out, qr{task-stack},      'output mentions unfixable B');

    is(file_perms($fileA), _read_recorded_perms($tmp, 'cwf-version-tag'), 'fixable A repaired');
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

# TC-8 pins _provision_extra_manifest_paths directly, independent of TC-1's
# broader "validate passes" path. Re-derives the non-.cwf/ manifest set the
# same way the fixture helper does and asserts each path was provisioned
# (exists, byte-identical, perms satisfy recorded floor). Asserts on the
# derived set (≥1, today the 5 .claude/agents/*.md) — never a hard-coded
# count — so it stays correct if the manifest gains or loses a non-.cwf/ path.
subtest 'TC-8: fixture provisions non-.cwf/ manifest paths (drift pin)' => sub {
    my $tmp = build_fixture();

    my $manifest = "$REPO_ROOT/.cwf/security/script-hashes.json";
    open my $fh, '<', $manifest or die "$manifest: $!";
    local $/;
    my $data = decode_json(<$fh>);
    close $fh;

    my @entries;
    for my $section (sort keys %$data) {
        my $sec = $data->{$section};
        next unless ref $sec eq 'HASH';
        for my $name (sort keys %$sec) {
            my $entry = $sec->{$name};
            next unless ref $entry eq 'HASH' && exists $entry->{path};
            next if $entry->{path} =~ m{^\.cwf/};
            push @entries, $entry;
        }
    }

    ok(@entries >= 1, 'manifest tracks at least one non-.cwf/ path');

    for my $entry (@entries) {
        my $rel = $entry->{path};
        my $dst = "$tmp/$rel";
        ok(-e $dst, "provisioned: $rel exists in fixture")
            or next;
        is(slurp($dst), slurp("$REPO_ROOT/$rel"),
           "provisioned: $rel byte-identical to repo");
        next unless defined $entry->{permissions};
        my $floor = oct($entry->{permissions});
        is(file_perms($dst) & $floor, $floor,
           "provisioned: $rel perms satisfy recorded floor $entry->{permissions}");
    }
};

done_testing();
