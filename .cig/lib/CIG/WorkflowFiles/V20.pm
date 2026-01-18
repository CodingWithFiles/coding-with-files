package CIG::WorkflowFiles::V20;

=head1 NAME

CIG::WorkflowFiles::V20 - Workflow file mappings for v2.0 format

=head1 SYNOPSIS

    use CIG::WorkflowFiles::V20;

    my $files = CIG::WorkflowFiles::V20::get_workflow_files($task_type);

=head1 DESCRIPTION

Defines workflow file names and task-type-specific file lists for v2.0 format.
v2.0 uses 8 workflow phases (a-h) with consistent naming across all phases.

=cut

use strict;
use warnings;

=head1 WORKFLOW FILES

v2.0 format uses lettered naming:
  a-plan.md
  b-requirements.md
  c-design.md
  d-implementation.md
  e-testing.md
  f-rollout.md
  g-maintenance.md
  h-retrospective.md

=cut

# Workflow file lists by task type
our %WORKFLOW_FILES = (
    feature => [
        'a-task-plan.md',
        'b-requirements-plan.md',
        'c-design-plan.md',
        'd-implementation-plan.md',
        'f-testing-plan.md',
        'h-rollout.md',
        'i-maintenance.md',
        'j-retrospective.md',
    ],
    bugfix => [
        'a-task-plan.md',
        'c-design-plan.md',
        'd-implementation-plan.md',
        'f-testing-plan.md',
        'j-retrospective.md',
    ],
    hotfix => [
        'a-task-plan.md',
        'd-implementation-plan.md',
        'f-testing-plan.md',
        'h-rollout.md',
        'j-retrospective.md',
    ],
    chore => [
        'a-task-plan.md',
        'd-implementation-plan.md',
        'f-testing-plan.md',
        'j-retrospective.md',
    ],
    discovery => [
        'a-task-plan.md',
        'b-requirements-plan.md',
        'c-design-plan.md',
        'd-implementation-plan.md',
        'f-testing-plan.md',
        'j-retrospective.md',
    ],
);

=head1 FUNCTIONS

=head2 get_workflow_files($task_type)

Get workflow file list for a task type.

Parameters:
  $task_type - Task type (feature, bugfix, hotfix, chore, discovery)

Returns:
  Arrayref of workflow filenames

=cut

sub get_workflow_files {
    my ($task_type) = @_;

    return $WORKFLOW_FILES{$task_type} || $WORKFLOW_FILES{feature};
}

1;

__END__

=head1 AUTHOR

CIG System

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
