#!/usr/bin/env perl
#
# task-state.t - Unit tests for TaskState.pm
#
# Tests both retrospective (state_done) and prospective (state_achievable)
# task state measurements.
#

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

# Add library path
use FindBin;
use lib "$FindBin::Bin/../.cig/lib";

# Load TaskState module
BEGIN { use_ok('TaskState', qw(state_done state_achievable status_percent status_extract)) }

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================

# Create a temporary task directory with workflow files
sub create_test_task {
    my ($task_type, @statuses) = @_;

    my $tmpdir = tempdir(CLEANUP => 1);
    my $task_dir = "$tmpdir/1-$task_type-test-task";
    make_path($task_dir);

    # Create workflow files based on task type
    my @files;
    if ($task_type eq 'feature') {
        @files = qw(a-plan.md b-requirements.md c-design.md d-implementation.md
                   e-testing.md f-rollout.md g-maintenance.md h-retrospective.md);
    } elsif ($task_type eq 'bugfix') {
        @files = qw(a-plan.md c-design.md d-implementation.md e-testing.md h-retrospective.md);
    }

    # Create files with status markers
    for (my $i = 0; $i < @files && $i < @statuses; $i++) {
        my $file = "$task_dir/$files[$i]";
        open my $fh, '>', $file or die "Cannot create $file: $!";
        print $fh "# Test Workflow File\n\n";
        print $fh "## Status\n";
        print $fh "**Status**: $statuses[$i]\n";
        close $fh;
    }

    return $task_dir;
}

#==============================================================================
# UTILITY FUNCTION TESTS
#==============================================================================

# Test status_percent mapping
subtest 'status_percent() - status value mapping' => sub {
    plan tests => 7;

    is(status_percent('Finished'), 100, 'Finished = 100%');
    is(status_percent('Testing'), 75, 'Testing = 75%');
    is(status_percent('Implemented'), 50, 'Implemented = 50%');
    is(status_percent('In Progress'), 25, 'In Progress = 25%');
    is(status_percent('Blocked'), 15, 'Blocked = 15%');
    is(status_percent('To-Do'), 0, 'To-Do = 0%');
    is(status_percent('Backlog'), 0, 'Backlog = 0%');
};

# Test status_extract from file
subtest 'status_extract() - extract status from file' => sub {
    plan tests => 2;

    my $tmpdir = tempdir(CLEANUP => 1);
    my $file = "$tmpdir/test.md";

    open my $fh, '>', $file or die $!;
    print $fh "# Test\n\n## Status\n**Status**: In Progress\n";
    close $fh;

    is(status_extract($file), 'In Progress', 'Extract status from file');
    is(status_extract('/nonexistent'), 'Unknown', 'Unknown for missing file');
};

#==============================================================================
# STATE_DONE TESTS (Retrospective - MIN Bottleneck)
#==============================================================================

subtest 'state_done() - blocked task (Task 11 scenario)' => sub {
    plan tests => 1;

    my $task_dir = create_test_task('bugfix', 'Finished', 'Finished', 'Blocked', 'Blocked', 'Blocked');
    is(state_done($task_dir), 25, 'Blocked task shows 25% (bottleneck with base adjustment)');
};

subtest 'state_done() - all finished task' => sub {
    plan tests => 1;

    my $task_dir = create_test_task('feature', ('Finished') x 8);
    is(state_done($task_dir), 100, 'All finished = 100%');
};

subtest 'state_done() - all backlog task' => sub {
    plan tests => 1;

    my $task_dir = create_test_task('feature', ('Backlog') x 8);
    is(state_done($task_dir), 0, 'All backlog = 0%');
};

subtest 'state_done() - mixed progress task' => sub {
    plan tests => 1;

    my $task_dir = create_test_task('feature', 'Finished', 'Testing', 'In Progress', 'Backlog', 'Backlog', 'Backlog', 'Backlog', 'Backlog');
    is(state_done($task_dir), 25, 'Mixed progress bottlenecks at 25% with base adjustment');
};

subtest 'state_done() - one in progress only' => sub {
    plan tests => 1;

    my $task_dir = create_test_task('bugfix', 'In Progress', 'Backlog', 'Backlog', 'Backlog', 'Backlog');
    is(state_done($task_dir), 25, 'Single In Progress = 25% with base');
};

#==============================================================================
# STATE_ACHIEVABLE TESTS (Prospective - Cliff Function)
#==============================================================================

subtest 'state_achievable() - blocked task (0% work potential)' => sub {
    plan tests => 1;

    my $task_dir = create_test_task('bugfix', 'Finished', 'Finished', 'Blocked', 'Blocked', 'Blocked');
    is(state_achievable($task_dir), 0, 'Blocked task = 0% work potential');
};

subtest 'state_achievable() - active task (Task 32 scenario)' => sub {
    plan tests => 1;

    my $task_dir = create_test_task('feature', ('In Progress') x 6, ('Backlog') x 2);

    # With 6 In Progress (25%) and 2 Backlog (0%):
    # state_done = 25% (bottleneck with base)
    # active_count = 6, is_workable = true
    # state_achievable = 25% (linear ramp)
    is(state_achievable($task_dir), 25, 'Active task = 25% work potential (linear ramp)');
};

subtest 'state_achievable() - near completion task' => sub {
    plan tests => 1;

    my $task_dir = create_test_task('bugfix', 'Finished', 'Finished', 'Finished', 'Testing', 'To-Do');

    # With 3 Finished (100%), 1 Testing (75%), 1 To-Do (0%):
    # state_done = 25% (min=0 from To-Do, but base=25% since max>=25)
    # active_count = 1 (Testing), is_workable = true
    # state_achievable = 25% (linear ramp)
    # Note: To get 75%, all files must be at least 75% (no Backlog/To-Do)
    is(state_achievable($task_dir), 25, 'Near completion (with backlog) = 25% work potential');
};

subtest 'state_achievable() - actually near completion (75%)' => sub {
    plan tests => 1;

    my $task_dir = create_test_task('bugfix', 'Finished', 'Finished', 'Finished', 'Testing', 'Testing');

    # With 3 Finished (100%), 2 Testing (75%):
    # state_done = 75% (min=75 from Testing, base=25%, so result=75%)
    # active_count = 2 (Testing), is_workable = true
    # state_achievable = 75% (linear ramp - strong momentum!)
    is(state_achievable($task_dir), 75, 'Task at 75% completion = 75% work potential (strong momentum)');
};

subtest 'state_achievable() - complete task (cliff at 100%)' => sub {
    plan tests => 1;

    my $task_dir = create_test_task('feature', ('Finished') x 8);
    is(state_achievable($task_dir), 0, 'Complete task = 0% work potential (cliff)');
};

subtest 'state_achievable() - fresh task (baseline)' => sub {
    plan tests => 1;

    my $task_dir = create_test_task('feature', ('Backlog') x 8);

    # All Backlog: completion=0%, active_count=0, is_workable=true
    # state_achievable = 10 (fresh baseline)
    is(state_achievable($task_dir), 10, 'Fresh task = 10% work potential (baseline)');
};

subtest 'state_achievable() - dormant task (started but no active)' => sub {
    plan tests => 1;

    my $task_dir = create_test_task('feature', 'Finished', 'Finished', ('Backlog') x 6);

    # 2 Finished, 6 Backlog: completion=25% (with base), active_count=0
    # state_achievable = 25 * 0.3 = 7 (dampened)
    is(state_achievable($task_dir), 7, 'Dormant task = dampened work potential');
};

subtest 'state_achievable() - all blocked task' => sub {
    plan tests => 1;

    my $task_dir = create_test_task('bugfix', ('Blocked') x 5);
    is(state_achievable($task_dir), 0, 'All blocked = 0% work potential');
};

#==============================================================================
# EDGE CASES
#==============================================================================

subtest 'state_done() - empty directory' => sub {
    plan tests => 1;

    my $tmpdir = tempdir(CLEANUP => 1);
    is(state_done($tmpdir), 0, 'Empty directory = 0%');
};

subtest 'state_achievable() - empty directory' => sub {
    plan tests => 1;

    my $tmpdir = tempdir(CLEANUP => 1);
    is(state_achievable($tmpdir), 0, 'Empty directory = 0% work potential');
};

subtest 'state_done() - nonexistent directory' => sub {
    plan tests => 1;

    is(state_done('/nonexistent/path'), 0, 'Nonexistent directory = 0%');
};

subtest 'state_achievable() - nonexistent directory' => sub {
    plan tests => 1;

    is(state_achievable('/nonexistent/path'), 0, 'Nonexistent directory = 0% work potential');
};

#==============================================================================
# CLIFF FUNCTION PROPERTIES
#==============================================================================

subtest 'state_achievable() - cliff function linear ramp' => sub {
    plan tests => 3;

    # Test that work potential increases linearly with completion for active tasks
    # Must avoid Backlog/To-Do to get actual varying completion percentages
    my $task_25 = create_test_task('bugfix', 'In Progress', 'In Progress', 'In Progress', 'In Progress', 'In Progress');
    my $task_50 = create_test_task('bugfix', 'Implemented', 'Implemented', 'Implemented', 'Implemented', 'Implemented');
    my $task_75 = create_test_task('bugfix', 'Finished', 'Testing', 'Testing', 'Testing', 'Testing');

    # task_25: all In Progress (25%) → state_done=25%, state_achievable=25%
    # task_50: all Implemented (50%) → state_done=50%, state_achievable=50%
    # task_75: 1 Finished, 4 Testing (75%) → state_done=75%, state_achievable=75%
    my $wp_25 = state_achievable($task_25);
    my $wp_50 = state_achievable($task_50);
    my $wp_75 = state_achievable($task_75);

    cmp_ok($wp_25, '>', 0, 'Active task at 25% has positive work potential');
    cmp_ok($wp_50, '>', $wp_25, 'Work potential increases with completion (50% > 25%)');
    cmp_ok($wp_75, '>', $wp_50, 'Work potential continues to increase (75% > 50%, linear ramp)');
};

subtest 'state_achievable() - blocked vs active distinction' => sub {
    plan tests => 1;

    # Two tasks with same completion, one blocked, one active
    my $blocked = create_test_task('bugfix', 'Finished', ('Blocked') x 4);
    my $active = create_test_task('bugfix', 'Finished', ('In Progress') x 4);

    my $wp_blocked = state_achievable($blocked);
    my $wp_active = state_achievable($active);

    cmp_ok($wp_active, '>', $wp_blocked, 'Active task has higher work potential than blocked');
};

#==============================================================================
# INTEGRATION TESTS
#==============================================================================

subtest 'Integration - Task 11 and Task 32 comparison' => sub {
    plan tests => 4;

    # Task 11: blocked (2 Finished, 3 Blocked)
    my $task11 = create_test_task('bugfix', 'Finished', 'Finished', 'Blocked', 'Blocked', 'Blocked');

    # Task 32: active (6 In Progress, 4 Backlog)
    my $task32 = create_test_task('feature', ('In Progress') x 6, ('Backlog') x 4);

    # Test state_done (retrospective)
    is(state_done($task11), 25, 'Task 11 completion = 25% (bottleneck)');
    is(state_done($task32), 25, 'Task 32 completion = 25% (bottleneck)');

    # Test state_achievable (prospective)
    is(state_achievable($task11), 0, 'Task 11 work potential = 0% (blocked)');
    is(state_achievable($task32), 25, 'Task 32 work potential = 25% (active)');
};

done_testing();
