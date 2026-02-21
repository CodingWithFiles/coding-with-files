package CWFTest::Fixtures;
#
# CWFTest::Fixtures - Shared test helpers for the CWF Perl test suite
#
# Provides three helpers used across multiple test tiers:
#   create_task_dir  - build a v2.1 task directory with workflow files
#   create_git_repo  - initialise a minimal git repo for Tier C tests
#   create_config    - write a minimal cwf-project.json
#

use strict;
use warnings;
use Exporter 'import';
use File::Path qw(make_path);
use File::Spec;

our @EXPORT_OK = qw(create_task_dir create_git_repo create_config);

# v2.1 workflow file lists by task type (mirrors CWF::WorkflowFiles::V21)
my %V21_FILES = (
    feature => [qw(
        a-task-plan.md
        b-requirements-plan.md
        c-design-plan.md
        d-implementation-plan.md
        e-testing-plan.md
        f-implementation-exec.md
        g-testing-exec.md
        h-rollout.md
        i-maintenance.md
        j-retrospective.md
    )],
    bugfix => [qw(
        a-task-plan.md
        c-design-plan.md
        d-implementation-plan.md
        e-testing-plan.md
        f-implementation-exec.md
        g-testing-exec.md
        j-retrospective.md
    )],
    hotfix => [qw(
        a-task-plan.md
        d-implementation-plan.md
        e-testing-plan.md
        f-implementation-exec.md
        g-testing-exec.md
        h-rollout.md
        j-retrospective.md
    )],
    chore => [qw(
        a-task-plan.md
        d-implementation-plan.md
        e-testing-plan.md
        f-implementation-exec.md
        g-testing-exec.md
        j-retrospective.md
    )],
    discovery => [qw(
        a-task-plan.md
        b-requirements-plan.md
        c-design-plan.md
        d-implementation-plan.md
        e-testing-plan.md
        f-implementation-exec.md
        g-testing-exec.md
        j-retrospective.md
    )],
);

# create_task_dir($base_dir, $task_type, @statuses)
#
# Creates a v2.1 task directory under $base_dir containing workflow files.
# Each file has a ## Status section with the given status (defaults to 'Backlog').
# The directory is named "1-$task_type-test-task".
#
# Returns: full path to the task directory
#
sub create_task_dir {
    my ($base, $type, @statuses) = @_;
    $type //= 'feature';

    my $task_dir = "$base/1-$type-test-task";
    make_path($task_dir);

    my $files = $V21_FILES{$type} // $V21_FILES{feature};

    for my $i (0 .. $#$files) {
        my $file   = "$task_dir/$files->[$i]";
        my $status = $statuses[$i] // 'Backlog';

        open my $fh, '>', $file or die "Cannot create $file: $!";
        print $fh "# Test Workflow File\n";
        print $fh "**Task**: 1 (${type})\n\n";
        print $fh "## Task Reference\n";
        print $fh "- **Task ID**: internal-1\n";
        print $fh "- **Branch**: ${type}/1-test-task\n\n";
        print $fh "## Goal\nTest goal.\n\n";
        print $fh "## Status\n";
        print $fh "**Status**: $status\n";
        close $fh;
    }

    return $task_dir;
}

# create_git_repo($base_dir)
#
# Initialises a minimal git repository inside $base_dir/repo with one
# commit. Returns the repo root path, or undef if git is unavailable.
#
sub create_git_repo {
    my ($base) = @_;

    # Verify git is available
    return undef if system("git --version >/dev/null 2>&1") != 0;

    my $repo = "$base/repo";
    make_path($repo);

    # Initialise with local config to avoid polluting global git config
    return undef if system("git -C '$repo' init -q")                            != 0;
    return undef if system("git -C '$repo' config user.email 'test\@example.com'") != 0;
    return undef if system("git -C '$repo' config user.name 'CWFTest'")         != 0;

    # Create an initial commit
    open my $fh, '>', "$repo/README.md" or return undef;
    print $fh "# Test repo\n";
    close $fh;

    return undef if system("git -C '$repo' add README.md")                      != 0;
    return undef if system("git -C '$repo' commit -q -m 'Initial commit'")      != 0;

    return $repo;
}

# create_config($base_dir)
#
# Writes a minimal cwf-project.json under $base_dir/implementation-guide/.
# Returns the path to the config file.
#
sub create_config {
    my ($base) = @_;

    my $dir = "$base/implementation-guide";
    make_path($dir);

    my $path = "$dir/cwf-project.json";
    open my $fh, '>', $path or die "Cannot create $path: $!";
    print $fh <<'END_JSON';
{
  "project-name": "Test Project",
  "supported-task-types": ["feature", "bugfix", "hotfix", "chore", "discovery"],
  "source-management": {
    "branch-naming-convention": "{task-type}/{task-id}-{description-slug}"
  },
  "task-tracking": { "system": "internal" },
  "workflow": {
    "status-values": {
      "Finished": 100,
      "Testing": 75,
      "In Progress": 25,
      "Blocked": 15,
      "To-Do": 0,
      "Backlog": 0
    }
  }
}
END_JSON
    close $fh;
    return $path;
}

1;
