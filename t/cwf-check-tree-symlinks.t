#!/usr/bin/env perl
#
# cwf-check-tree-symlinks.t — Tests the standalone symlink-escape guard:
# the ported _escapes_src/_collapse_dotdot logic (unit) and the CLI exit-code
# / STDERR contract over real symlink trees (integration).
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use POSIX ();
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use lib "$FindBin::Bin/../.cwf/lib";

my $REPO   = File::Spec->rel2abs("$FindBin::Bin/..");
my $HELPER = "$REPO/.cwf/scripts/command-helpers/cwf-check-tree-symlinks";

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

# Run the helper as a CLI; capture exit status and STDERR.
sub run_helper {
    my (@roots) = @_;
    my $errfile = File::Spec->catfile(tempdir(CLEANUP => 1), 'err');
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        # POSIX::_exit, not exit: a forked child must not run the parent's
        # inherited END blocks (File::Temp CLEANUP would rmtree parent tempdirs).
        open(STDERR, '>', $errfile) or POSIX::_exit(127);
        exec($HELPER, @roots) or POSIX::_exit(127);   # exec failed
    }
    waitpid($pid, 0);
    my $exit = $? >> 8;
    my $err  = read_file($errfile) // '';
    return ($exit, $err);
}

# Load the helper as a library; the `main(@ARGV) unless caller();` guard
# keeps it from running. Subs land in main:: (no package declaration).
require "$REPO/.cwf/scripts/command-helpers/cwf-check-tree-symlinks";

# --- Unit: _escapes_src -----------------------------------------------------
subtest '_escapes_src: escape-logic unit cases' => sub {
    my $src   = '/tmp/cwf-src';
    my $entry = "$src/feature/x";
    ok( !main::_escapes_src($entry, '../pool/x',        $src), 'sibling pool/ allowed');
    ok( !main::_escapes_src($entry, 'inner',            $src), 'same-dir entry allowed');
    ok(  main::_escapes_src($entry, '/etc/passwd',      $src), 'absolute target rejected');
    ok(  main::_escapes_src($entry, '../../etc/passwd', $src), 'parent-escape rejected');
    ok(  main::_escapes_src($entry, '../../..',         $src), 'multi-parent rejected');
    ok(  main::_escapes_src($entry, '..',               $src), 'source-root-equal rejected');
};

# --- CLI: clean tree --------------------------------------------------------
subtest 'CLI: clean multi-root tree exits 0' => sub {
    my $a = tempdir(CLEANUP => 1);
    my $b = tempdir(CLEANUP => 1);
    write_file("$a/pool/x", "x\n");
    make_path("$a/feature");
    symlink('../pool/x', "$a/feature/x") or die "symlink: $!";   # in-tree
    write_file("$b/y.txt", "y\n");
    symlink('y.txt', "$b/y") or die "symlink: $!";               # same-dir

    my ($exit, $err) = run_helper($a, $b);
    is($exit, 0, 'exit 0 on clean roots');
    is($err, '', 'no STDERR output');
};

# --- CLI: escaping symlink --------------------------------------------------
subtest 'CLI: escaping symlink under a root exits non-zero with message' => sub {
    my $a = tempdir(CLEANUP => 1);
    symlink('/etc/passwd', "$a/leak") or die "symlink: $!";

    my ($exit, $err) = run_helper($a);
    isnt($exit, 0, 'non-zero exit on absolute-target symlink');
    like($err, qr/refusing escaping symlink target: .*leak -> \/etc\/passwd/,
         'STDERR names the offending entry and target');
};

# --- CLI: per-root attribution ----------------------------------------------
subtest 'CLI: escape under the SECOND root is still caught' => sub {
    my $a = tempdir(CLEANUP => 1);   # clean
    my $b = tempdir(CLEANUP => 1);   # contains the escape
    write_file("$a/ok.txt", "ok\n");
    make_path("$b/feature");
    symlink('../../etc/passwd', "$b/feature/escape") or die "symlink: $!";

    my ($exit, $err) = run_helper($a, $b);
    isnt($exit, 0, 'non-zero: second root is walked against itself');
    like($err, qr/refusing escaping symlink target: .*escape/, 'names the escape');
};

# --- CLI: in-tree pool-pointing symlink allowed -----------------------------
subtest 'CLI: pool-pointing symlink is preserved (exit 0)' => sub {
    my $a = tempdir(CLEANUP => 1);
    make_path("$a/pool");
    make_path("$a/feature");
    write_file("$a/pool/x", "pool\n");
    symlink('../pool/x', "$a/feature/x") or die "symlink: $!";

    my ($exit, $err) = run_helper($a);
    is($exit, 0, 'exit 0: subdir-spanning in-tree target allowed');
    is($err, '', 'no STDERR output');
};

# --- CLI: usage error -------------------------------------------------------
subtest 'CLI: no roots is a usage error (exit 2)' => sub {
    my ($exit, $err) = run_helper();
    is($exit, 2, 'exit 2 with no arguments');
    like($err, qr/Usage:/, 'prints usage');
};

# Note: the readlink-failure fail-closed branch (defined-guard in check_root)
# cannot be triggered deterministically — lstat reporting -l while readlink
# fails is a TOCTOU/permission race, not reproducible portably. It is covered
# by inspection: the `unless (defined $link)` guard exits 1 before any further
# processing, mirroring the original `readlink(...) // die_msg`.

# --- TC-7: integrity coverage + tamper detection ---------------------------
subtest 'TC-7 (Task 161): guard is in the ledger and tamper-detected' => sub {
    # (a) ledger entry exists and matches the on-disk helper.
    my $ledger = JSON::PP->new->decode(read_file("$REPO/.cwf/security/script-hashes.json"));
    my $entry  = $ledger->{scripts}{'cwf-check-tree-symlinks'};
    ok($entry, 'cwf-check-tree-symlinks has a script-hashes.json entry');
    is($entry->{path}, '.cwf/scripts/command-helpers/cwf-check-tree-symlinks', 'recorded path');
    is($entry->{permissions}, '0500', 'recorded permissions 0500');
    is($entry->{sha256}, sha256_hex(read_file($HELPER)), 'recorded sha256 matches the on-disk helper');

    # (b) The guard is auto-reviewed by the exec-phase security review because,
    # as of Task 174, security-review-changeset reviews EVERY changed file —
    # there is no longer an @CWF_INTERNAL_PREFIXES allow-list to be a member of.
    # The former "prefix-covered" assertion is now vacuous and was removed.

    # (c) tamper detection via the real validator on a tempdir fixture.
    require CWF::Validate::Security;
    my $tmp = tempdir(CLEANUP => 1);
    make_path("$tmp/.cwf/security", "$tmp/.cwf/scripts/command-helpers");
    my $dst = "$tmp/.cwf/scripts/command-helpers/cwf-check-tree-symlinks";
    write_file($dst, read_file($HELPER));
    chmod 0500, $dst;
    write_file("$tmp/.cwf/security/script-hashes.json",
        JSON::PP->new->encode({ scripts => { 'cwf-check-tree-symlinks' => {
            path        => '.cwf/scripts/command-helpers/cwf-check-tree-symlinks',
            sha256      => sha256_hex(read_file($dst)),
            permissions => '0500',
        } } }));
    is(scalar(CWF::Validate::Security::validate($tmp)), 0, 'clean fixture → no violations');

    chmod 0700, $dst;   # 0500 is read-only; make writable to tamper
    open my $fh, '>>', $dst or die "append: $!";
    print $fh "# tamper\n";
    close $fh;
    chmod 0500, $dst;
    my @v = CWF::Validate::Security::validate($tmp);
    ok(scalar @v > 0,            'tampered helper → violation reported');
    is($v[0]{field}, 'sha256',   'violation field = sha256');
};

# --- TC-FIXTURE-HYGIENE -----------------------------------------------------
subtest 'no API keys / model names in test fixtures' => sub {
    my $self = read_file("$FindBin::Bin/cwf-check-tree-symlinks.t");
    unlike($self, qr/sk-(ant|live)-[a-z0-9]/, 'no live API keys');
    unlike($self, qr/(claude|gpt)-[0-9]/i,    'no real model names');
};

done_testing();
