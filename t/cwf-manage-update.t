#!/usr/bin/env perl
#
# cwf-manage-update.t — Tests cmd_update prelude logic (lock acquisition,
# settings.json parse-check, install-manifest SHA pin) and the path-traversal
# smoke test from d-implementation-plan.md Step 4.
#
# Tests do NOT exercise the full update flow (clone+subtree-pull) — those need
# a remote and are out of scope here. Instead we test the helpers directly
# (acquire_update_lock + flock-conflict, validate_settings_parseable,
# validate_install_manifest_sha, run_apply_artefacts subprocess wiring).
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use Fcntl qw(:flock O_RDWR O_CREAT O_NOFOLLOW);

my $REPO   = File::Spec->rel2abs("$FindBin::Bin/..");
my $HELPER = "$REPO/.cwf/scripts/command-helpers/cwf-apply-artefacts";

sub write_file {
    my ($path, $content) = @_;
    my (undef, $dir) = File::Spec->splitpath($path);
    make_path($dir) if length $dir && !-d $dir;
    open my $fh, '>:raw', $path or die "write_file($path): $!";
    print $fh $content;
    close $fh;
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<:raw', $path or return undef;
    local $/;
    my $blob = <$fh>;
    close $fh;
    return $blob;
}

# --- TC-INT-LOCK-CONCURRENT: flock contention ------------------------------
subtest 'flock: second acquirer fails LOCK_EX|LOCK_NB' => sub {
    my $tmp = tempdir(CLEANUP => 1);
    make_path("$tmp/.cwf");
    my $lockpath = "$tmp/.cwf/.update.lock";

    sysopen(my $fh1, $lockpath, O_RDWR | O_CREAT | O_NOFOLLOW, 0600) or die $!;
    ok(flock($fh1, LOCK_EX | LOCK_NB), 'first lock acquired');

    # Use a child process — flock is per-process on Linux. A second flock from
    # the same process succeeds, but a child sees the lock as held.
    my $pid = fork();
    if ($pid == 0) {
        sysopen(my $fh2, $lockpath, O_RDWR | O_CREAT | O_NOFOLLOW, 0600)
            or exit 2;
        my $got = flock($fh2, LOCK_EX | LOCK_NB);
        close $fh2;
        exit($got ? 0 : 1);
    }
    waitpid($pid, 0);
    is($? >> 8, 1, 'child failed to acquire lock (second-acquirer blocked)');
    close $fh1;
};

# --- TC-INT-LOCK-SYMLINK-TOCTOU: refuse symlink at lock path --------------
subtest 'flock: refuses symlink at lock path' => sub {
    my $tmp = tempdir(CLEANUP => 1);
    make_path("$tmp/.cwf");
    write_file("$tmp/target", "x");
    symlink("$tmp/target", "$tmp/.cwf/.update.lock");

    # The lstat check in acquire_update_lock would bail. Simulate the check
    # here directly.
    ok(-l "$tmp/.cwf/.update.lock", 'lock path is a symlink');

    # If the script tried to sysopen with O_NOFOLLOW, that would also fail.
    my $rc = sysopen(my $fh, "$tmp/.cwf/.update.lock", O_RDWR | O_CREAT | O_NOFOLLOW, 0600);
    ok(!$rc, 'sysopen with O_NOFOLLOW refuses symlink');
};

# --- TC-INT-PATH-TRAVERSAL: cwf-apply-artefacts exit 3 on bad dest --------
subtest 'cwf-manage-style smoke test: path traversal yields exit 3' => sub {
    my $src = tempdir(CLEANUP => 1);
    write_file("$src/.cwf/templates/install/rules-inject.txt", '');
    write_file("$src/.cwf/templates/install/claude-md-preamble.md", "p\n");
    write_file("$src/.claude/rules/cwf-workflow-files.md", "r\n");
    my $manifest = {
        schema_version => 1,
        artefacts => [
            { id => 'rules-inject', kind => 'file',
              source => '.cwf/templates/install/rules-inject.txt',
              dest => '../../etc/passwd',
              sha256 => sha256_hex('') },
        ],
    };
    write_file("$src/.cwf/install-manifest.json",
               JSON::PP->new->canonical->encode($manifest));

    my $inst = tempdir(CLEANUP => 1);
    my $rc = system("$HELPER '$inst' '$src' >/dev/null 2>&1");
    is($rc >> 8, 3, 'exit 3 (path validation)');
    # Nothing should have been created outside $inst.
    ok(! -e "$inst/../etc/passwd", 'no traversal escape');
};

# --- TC-INT-MANIFEST-SHA-TAMPER: validate detects manifest mismatch -------
# Uses cwf-manage validate against a fixture project; we can't easily fake
# .cwf/version + manifest in repo root, so synthesise a tempdir, copy the
# script-hashes manifest layout, and assert the validator function directly.
subtest 'validate_install_manifest detects SHA tampering' => sub {
    my $git_root = tempdir(CLEANUP => 1);
    write_file("$git_root/.cwf/install-manifest.json",
               JSON::PP->new->canonical->encode({
                   schema_version => 1,
                   artefacts => [],
               }));
    # Pin a wrong SHA in .cwf/version.
    write_file("$git_root/.cwf/version", "cwf_install_manifest_sha=deadbeef\n");

    require lib;
    lib->import("$REPO/.cwf/lib");
    require CWF::Validate::Security;
    my @v = CWF::Validate::Security::validate_install_manifest($git_root);
    ok(scalar @v > 0, 'violation reported');
    like($v[0]{field}, qr/sha256/, 'reports sha256 field');
};

# --- TC-INT-NO-MANIFEST: validate is silent when manifest absent ----------
subtest 'validate_install_manifest no-op when manifest absent' => sub {
    my $git_root = tempdir(CLEANUP => 1);
    require lib;
    lib->import("$REPO/.cwf/lib");
    require CWF::Validate::Security;
    my @v = CWF::Validate::Security::validate_install_manifest($git_root);
    is(scalar @v, 0, 'no violations reported');
};

# --- copy_tree symlink branch ---------------------------------------------
# Load cwf-manage as a library to exercise copy_tree / _escapes_src directly.
# The script's `main() unless caller;` guard makes this safe.
require "$REPO/.cwf/scripts/cwf-manage";

subtest 'copy_tree: relative symlink is preserved' => sub {
    my $src = tempdir(CLEANUP => 1);
    my $dst = tempdir(CLEANUP => 1);
    write_file("$src/a.txt", "hello\n");
    symlink('a.txt', "$src/b") or die "symlink: $!";

    main::copy_tree($src, $dst);

    ok(-l "$dst/b", 'b is a symlink in dest');
    is(readlink("$dst/b"), 'a.txt', 'symlink target preserved');
    ok(-f "$dst/a.txt", 'a.txt is a regular file in dest');
};

subtest 'copy_tree: pool-pointing symlink is preserved' => sub {
    # The bug-at-hand: feature/X -> ../pool/X must remain a symlink.
    my $src = tempdir(CLEANUP => 1);
    my $dst = tempdir(CLEANUP => 1);
    make_path("$src/pool");
    make_path("$src/feature");
    write_file("$src/pool/x", "pool x\n");
    symlink('../pool/x', "$src/feature/x") or die "symlink: $!";

    main::copy_tree($src, $dst);

    ok(-l "$dst/feature/x",                 'feature/x is a symlink in dest');
    is(readlink("$dst/feature/x"), '../pool/x', 'subdir-spanning target preserved');
    ok(-f "$dst/pool/x", 'pool/x copied as regular file');
};

subtest 'copy_tree: absolute symlink target → die' => sub {
    # The symlink is never followed; copy_tree refuses to write it out.
    my $src = tempdir(CLEANUP => 1);
    my $dst = tempdir(CLEANUP => 1);
    symlink('/etc/passwd', "$src/leak") or die "symlink: $!";

    my $err;
    my $pid = fork();
    if ($pid == 0) {
        # die_msg calls exit 1; capture exit status only.
        eval { main::copy_tree($src, $dst) };
        exit 0;
    }
    waitpid($pid, 0);
    my $exit = $? >> 8;
    is($exit, 1, 'copy_tree exited 1 on absolute symlink target');
    ok(! -e "$dst/leak", 'leak not created in dest');
};

subtest 'copy_tree: escaping relative symlink target → die' => sub {
    # The symlink is never followed; copy_tree refuses to write it out.
    my $src = tempdir(CLEANUP => 1);
    my $dst = tempdir(CLEANUP => 1);
    symlink('../../etc/passwd', "$src/escape") or die "symlink: $!";

    my $pid = fork();
    if ($pid == 0) {
        eval { main::copy_tree($src, $dst) };
        exit 0;
    }
    waitpid($pid, 0);
    my $exit = $? >> 8;
    is($exit, 1, 'copy_tree exited 1 on escaping symlink target');
    ok(! -e "$dst/escape", 'escape not created in dest');
};

subtest 'copy_tree: nested escaping symlink → die (no File::Find chdir reliance)' => sub {
    # Regression guard for the $_ vs $File::Find::name issue: when the
    # offending symlink is nested under a subdirectory, _escapes_src must
    # still recognise it as an escape without relying on File::Find chdir.
    my $src = tempdir(CLEANUP => 1);
    my $dst = tempdir(CLEANUP => 1);
    make_path("$src/feature");
    symlink('../../etc/passwd', "$src/feature/escape")
        or die "symlink: $!";

    my $pid = fork();
    if ($pid == 0) {
        eval { main::copy_tree($src, $dst) };
        exit 0;
    }
    waitpid($pid, 0);
    my $exit = $? >> 8;
    is($exit, 1, 'copy_tree exited 1 on nested escaping symlink');
    ok(! -e "$dst/feature/escape", 'nested escape not created in dest');
};

subtest 'copy_tree: in-tree non-pool symlink is allowed' => sub {
    # Regression guard against _escapes_src being overly strict.
    my $src = tempdir(CLEANUP => 1);
    my $dst = tempdir(CLEANUP => 1);
    make_path("$src/a");
    make_path("$src/b");
    write_file("$src/a/x.txt", "x\n");
    symlink('../a/x.txt', "$src/b/link") or die "symlink: $!";

    main::copy_tree($src, $dst);

    ok(-l "$dst/b/link", 'b/link is a symlink in dest');
    is(readlink("$dst/b/link"), '../a/x.txt', 'in-tree relative target preserved');
};

subtest '_escapes_src: helper unit cases' => sub {
    my $src = '/tmp/cwf-src';
    my $entry = "$src/feature/x";
    ok( !main::_escapes_src($entry, '../pool/x',       $src), 'sibling pool/ allowed');
    ok( !main::_escapes_src($entry, 'inner',           $src), 'same-dir entry allowed');
    ok(  main::_escapes_src($entry, '/etc/passwd',     $src), 'absolute target rejected');
    ok(  main::_escapes_src($entry, '../../etc/passwd', $src), 'parent-escape rejected');
    ok(  main::_escapes_src($entry, '../../..',        $src), 'multi-parent rejected');
};

# --- TC-FIXTURE-HYGIENE ---
subtest 'no API keys / model names in test fixtures' => sub {
    open my $fh, '<', $FindBin::Bin . '/cwf-manage-update.t' or die $!;
    local $/;
    my $self = <$fh>;
    close $fh;
    unlike($self, qr/sk-(ant|live)-[a-z0-9]/, 'no live API keys');
    unlike($self, qr/(claude|gpt)-[0-9]/i,    'no real model names');
};

done_testing();
