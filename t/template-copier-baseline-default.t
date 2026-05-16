#!/usr/bin/env perl
#
# template-copier-baseline-default.t - Integration tests for the
# --baseline-commit default behaviour of template-copier-v2.1.
#
# Runs the helper as a subprocess from within the live repo (so that
# templates and config are findable), writing into a tempdir destination
# that is cleaned up after each subtest.
#
# Covers:
#   - Flag omitted -> rendered a-task-plan.md contains a 40-char hex SHA
#     matching git rev-parse HEAD of the live repo.
#   - Flag passed explicitly -> rendered a-task-plan.md contains that
#     exact value verbatim (rare expert path preserved).
#
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use Cwd qw(cwd);
use POSIX ();

my $HELPER = File::Spec->catfile(
    $FindBin::Bin, '..', '.cwf', 'scripts', 'command-helpers', 'template-copier-v2.1'
);

# Run helper with cwd inside $repo (where it can find templates/config).
# Return (stdout, stderr, exit_code).
sub run_helper {
    my ($repo, @args) = @_;
    my $stdout_file = File::Temp->new(UNLINK => 1)->filename;
    my $stderr_file = File::Temp->new(UNLINK => 1)->filename;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my $rc;
    {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            open(STDOUT, '>', $stdout_file) or POSIX::_exit(127);
            open(STDERR, '>', $stderr_file) or POSIX::_exit(127);
            exec($HELPER, @args) or POSIX::_exit(127);
        }
        waitpid($pid, 0);
        $rc = $? >> 8;
    }
    chdir $orig;

    my $stdout = do { local $/; open my $fh, '<', $stdout_file or die; <$fh> };
    my $stderr = do { local $/; open my $fh, '<', $stderr_file or die; <$fh> };
    return ($stdout // '', $stderr // '', $rc);
}

my $live_repo = `git rev-parse --show-toplevel 2>/dev/null`;
chomp $live_repo;
plan skip_all => 'not inside a git repo' unless length $live_repo;

my $head_sha = `git -C '$live_repo' rev-parse HEAD 2>/dev/null`;
chomp $head_sha;
plan skip_all => 'cannot resolve HEAD' unless $head_sha =~ /^[0-9a-f]{40}$/;

plan tests => 2;

subtest 'TC-4: flag omitted -> baseline resolved to live HEAD' => sub {
    plan tests => 3;

    my $tmp = tempdir(CLEANUP => 1);
    my $dest = "$tmp/999-chore-resolver-default-test";

    my ($out, $err, $rc) = run_helper(
        $live_repo,
        "--task-type=chore",
        "--task-num=999",
        "--description=resolver default test",
        "--destination=$dest",
    );

    is($rc, 0, 'helper exits 0');
    my $plan_file = "$dest/a-task-plan.md";
    ok(-f $plan_file, 'a-task-plan.md was rendered');

    my $content = do { local $/; open my $fh, '<', $plan_file or die; <$fh> };
    like(
        $content,
        qr/\Q**Baseline Commit**:\E\s+\Q$head_sha\E\b/,
        "baseline line contains current HEAD ($head_sha)",
    );
};

subtest 'TC-5: flag passed explicitly -> verbatim pass-through' => sub {
    plan tests => 3;

    my $synthetic = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef';
    my $tmp = tempdir(CLEANUP => 1);
    my $dest = "$tmp/998-chore-resolver-explicit-test";

    my ($out, $err, $rc) = run_helper(
        $live_repo,
        "--task-type=chore",
        "--task-num=998",
        "--description=resolver explicit test",
        "--destination=$dest",
        "--baseline-commit=$synthetic",
    );

    is($rc, 0, 'helper exits 0');
    my $plan_file = "$dest/a-task-plan.md";
    ok(-f $plan_file, 'a-task-plan.md was rendered');

    my $content = do { local $/; open my $fh, '<', $plan_file or die; <$fh> };
    like(
        $content,
        qr/\Q**Baseline Commit**:\E\s+\Q$synthetic\E\b/,
        'baseline line contains explicit value verbatim',
    );
};
