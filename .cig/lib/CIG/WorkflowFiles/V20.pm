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
        'a-plan.md',
        'b-requirements.md',
        'c-design.md',
        'd-implementation.md',
        'e-testing.md',
        'f-rollout.md',
        'g-maintenance.md',
        'h-retrospective.md',
    ],
    bugfix => [
        'a-plan.md',
        'c-design.md',
        'd-implementation.md',
        'e-testing.md',
        'h-retrospective.md',
    ],
    hotfix => [
        'a-plan.md',
        'd-implementation.md',
        'e-testing.md',
        'f-rollout.md',
        'h-retrospective.md',
    ],
    chore => [
        'a-plan.md',
        'd-implementation.md',
        'e-testing.md',
        'h-retrospective.md',
    ],
    discovery => [
        'a-plan.md',
        'b-requirements.md',
        'c-design.md',
        'd-implementation.md',
        'e-testing.md',
        'h-retrospective.md',
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
