package CIG::WorkflowFiles::V21;

=head1 NAME

CIG::WorkflowFiles::V21 - Workflow file mappings for v2.1 format

=head1 SYNOPSIS

    use CIG::WorkflowFiles::V21;

    my $files = CIG::WorkflowFiles::V21::get_workflow_files($task_type);

=head1 DESCRIPTION

Defines workflow file names and task-type-specific file lists for v2.1 format.
v2.1 uses 10 workflow phases (a-j) with explicit separation of planning and execution.

Key changes from v2.0:
- Added e-implementation-exec.md (execution phase after d-implementation-plan.md)
- Added g-testing-exec.md (execution phase after f-testing-plan.md)
- Sequential a-j lettering for clean alphabetical progression

=cut

use strict;
use warnings;

=head1 WORKFLOW FILES

v2.1 format uses sequential a-j lettering:
  a-task-plan.md           (Planning)
  b-requirements-plan.md   (Planning)
  c-design-plan.md         (Planning)
  d-implementation-plan.md (Planning)
  e-testing-plan.md        (Planning - NEW POSITION in v2.1)
  f-implementation-exec.md (Execution - NEW in v2.1)
  g-testing-exec.md        (Execution - NEW in v2.1)
  h-rollout.md             (Execution)
  i-maintenance.md         (Execution)
  j-retrospective.md       (Retrospective)

=cut

# Workflow file lists by task type
our %WORKFLOW_FILES = (
    feature => [
        'a-task-plan.md',
        'b-requirements-plan.md',
        'c-design-plan.md',
        'd-implementation-plan.md',
        'e-testing-plan.md',
        'f-implementation-exec.md',
        'g-testing-exec.md',
        'h-rollout.md',
        'i-maintenance.md',
        'j-retrospective.md',
    ],
    bugfix => [
        'a-task-plan.md',
        'c-design-plan.md',
        'd-implementation-plan.md',
        'e-testing-plan.md',
        'f-implementation-exec.md',
        'g-testing-exec.md',
        'j-retrospective.md',
    ],
    hotfix => [
        'a-task-plan.md',
        'd-implementation-plan.md',
        'e-testing-plan.md',
        'f-implementation-exec.md',
        'g-testing-exec.md',
        'h-rollout.md',
        'j-retrospective.md',
    ],
    chore => [
        'a-task-plan.md',
        'd-implementation-plan.md',
        'e-testing-plan.md',
        'f-implementation-exec.md',
        'g-testing-exec.md',
        'j-retrospective.md',
    ],
    discovery => [
        'a-task-plan.md',
        'b-requirements-plan.md',
        'c-design-plan.md',
        'd-implementation-plan.md',
        'e-testing-plan.md',
        'f-implementation-exec.md',
        'g-testing-exec.md',
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
