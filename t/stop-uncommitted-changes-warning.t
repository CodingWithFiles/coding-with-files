#!/usr/bin/env perl
#
# stop-uncommitted-changes-warning.t - Unit tests for the Stop event hook
# (.cwf/scripts/hooks/stop-uncommitted-changes-warning).
#
# The hook reads no stdin; it runs `git status … -- 'implementation-guide/*/[a-j]-*.md'`
# against the cwd git tree and prints a one-line JSON {"systemMessage":...} (or
# nothing on a clean tree). Each case builds a throwaway git repo, plants
# untracked wf files, runs the hook by absolute path with cwd = the temp repo
# (so its $FindBin::Bin/../../lib still resolves CWF::TaskPath from the real
# repo while the git query sees the planted tree), and asserts the message.
#
# Every non-empty case asserts exit 0 and valid single-line JSON.
#
use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use JSON::PP;

my $HOOK   = "$FindBin::Bin/../.cwf/scripts/hooks/stop-uncommitted-changes-warning";
my $PREFIX = "\x{26A0} Uncommitted: ";   # "⚠ Uncommitted: "

# Build a throwaway git repo, plant @relpaths as untracked files. Returns dir.
sub build_repo {
    my (@relpaths) = @_;
    my $dir = tempdir(CLEANUP => 1);
    system('git', '-C', $dir, 'init', '-q') == 0 or die "git init failed";
    system('git', '-C', $dir, 'config', 'user.email', 'test@example.com');
    system('git', '-C', $dir, 'config', 'user.name', 'CWF Test');
    for my $rel (@relpaths) {
        my $full = File::Spec->catfile($dir, $rel);
        my (undef, $d, undef) = File::Spec->splitpath($full);
        make_path($d);
        open my $fh, '>', $full or die "open $full: $!";
        print $fh "content\n";
        close $fh;
    }
    return $dir;
}

# Run the hook with cwd = $dir. Returns ($stdout, $exit).
sub run_hook {
    my ($dir) = @_;
    my $out  = `cd '$dir' && '$HOOK' 2>/dev/null`;
    my $exit = $? >> 8;
    return ($out // '', $exit);
}

# Decode the systemMessage from hook stdout (dies if not valid JSON).
sub msg_of {
    my ($out) = @_;
    my $obj = JSON::PP->new->decode($out);
    return $obj->{systemMessage};
}

# Assert a non-empty case: exit 0, valid JSON, systemMessage eq $PREFIX.$body.
sub check_msg {
    my ($out, $exit, $body, $label) = @_;
    is($exit, 0, "$label: exit 0");
    my $msg = eval { msg_of($out) };
    ok(defined $msg, "$label: stdout is valid JSON with systemMessage")
        or diag("stdout was: $out");
    is($msg, $PREFIX . $body, "$label: message body");
}

# ----- TC-1: single task, <=3 files (elision) ------------------------------
{
    my $dir = build_repo(
        'implementation-guide/199-discovery-x/a-task-plan.md',
        'implementation-guide/199-discovery-x/c-design-plan.md',
    );
    my ($out, $exit) = run_hook($dir);
    check_msg($out, $exit, 'a-task-plan.md, c-design-plan.md',
              'TC-1 single task <=3, no prefix');
}

# ----- TC-2: single task, >3 files (flat overflow, baseline-identical) -----
{
    my $dir = build_repo(map { "implementation-guide/199-discovery-x/$_" } qw(
        a-task-plan.md b-requirements-plan.md c-design-plan.md
        d-implementation-plan.md e-testing-plan.md f-implementation-exec.md
        g-testing-exec.md h-rollout.md
    ));
    my ($out, $exit) = run_hook($dir);
    check_msg($out, $exit,
              'a-task-plan.md, b-requirements-plan.md, c-design-plan.md +5 more',
              'TC-2 single task >3, flat overflow no prefix');
}

# ----- TC-3: two tasks (grouping) ------------------------------------------
{
    my $dir = build_repo(
        'implementation-guide/199-discovery-x/a-task-plan.md',
        'implementation-guide/199-discovery-x/c-design-plan.md',
        'implementation-guide/30-feature-y/f-implementation-exec.md',
    );
    my ($out, $exit) = run_hook($dir);
    check_msg($out, $exit,
              '199: a-task-plan.md, c-design-plan.md; 30: f-implementation-exec.md',
              'TC-3 two tasks grouped, joined by "; "');
}

# ----- TC-4: nested subtask number -----------------------------------------
{
    my $dir = build_repo(
        'implementation-guide/28-feature-p/28.1-chore-c/f-implementation-exec.md',
        'implementation-guide/30-feature-y/a-task-plan.md',
    );
    my ($out, $exit) = run_hook($dir);
    check_msg($out, $exit,
              '28.1: f-implementation-exec.md; 30: a-task-plan.md',
              'TC-4 nested subtask keyed 28.1 not 28');
}

# ----- TC-5: multi-task with per-group overflow (no group dropped) ---------
{
    my $dir = build_repo(
        (map { "implementation-guide/199-discovery-x/$_" }
            qw(a-task-plan.md c-design-plan.md d-implementation-plan.md e-testing-plan.md)),
        'implementation-guide/30-feature-y/a-task-plan.md',
    );
    my ($out, $exit) = run_hook($dir);
    check_msg($out, $exit,
              '199: a-task-plan.md, c-design-plan.md, d-implementation-plan.md +1 more; '
            . '30: a-task-plan.md',
              'TC-5 per-group overflow, second group still present');
}

# ----- TC-6: non-task parent dir (fallback key) ----------------------------
{
    my $dir = build_repo(
        'implementation-guide/scratch/a-task-plan.md',
        'implementation-guide/30-feature-y/a-task-plan.md',
    );
    my ($out, $exit) = run_hook($dir);
    check_msg($out, $exit,
              '30: a-task-plan.md; scratch: a-task-plan.md',
              'TC-6 non-task dir falls back to raw key "scratch"');
}

# ----- TC-7: clean tree → no output, exit 0 --------------------------------
{
    my $dir = build_repo();   # no dirty wf files
    my ($out, $exit) = run_hook($dir);
    is($out, '', 'TC-7 clean tree → empty stdout');
    is($exit, 0, 'TC-7 exit 0');
}

done_testing();
