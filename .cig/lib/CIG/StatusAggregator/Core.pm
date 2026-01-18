package CIG::StatusAggregator::Core;

=head1 NAME

CIG::StatusAggregator::Core - Version-agnostic status aggregation logic

=head1 SYNOPSIS

    use CIG::StatusAggregator::Core;

    my $progress = CIG::StatusAggregator::Core::aggregate($task_dir, \@workflow_files);

=head1 DESCRIPTION

Core status aggregation algorithm shared across v2.0 and v2.1 workflow versions.
Accepts a list of workflow files and returns aggregated progress percentage.

=cut

use strict;
use warnings;
use CIG::MarkdownParser qw(extract_status);
use CIG::WorkflowFiles qw(status_to_percent);

=head1 FUNCTIONS

=head2 aggregate($task_dir, $workflow_files)

Calculate aggregated progress for a task based on workflow file statuses.

Parameters:
  $task_dir       - Path to task directory
  $workflow_files - Arrayref of workflow file hashes with 'path' and 'name' keys

Returns:
  Progress percentage (0-100)

Algorithm:
  MAX(IF(MAX(all) >= 25%) THEN 25% ELSE 0%, MIN(all status percentages))

=cut

sub aggregate {
    my ($task_dir, $workflow_files) = @_;

    return 0 unless $workflow_files && @$workflow_files;

    my @percentages;
    for my $file (@$workflow_files) {
        my $status = extract_status($file->{path});
        my $pct = status_to_percent($status);

        # Warn on unknown status
        if ($pct == 0 && $status ne "Unknown" && $status !~ /^(Backlog|To-Do)$/i) {
            my $filename = "$task_dir/" . $file->{name};
            print STDERR "Warning: Unknown status \"$status\" in $filename\n";
        }

        push @percentages, $pct;
    }

    return 0 unless @percentages;

    # Calculate progress using formula: MAX(IF(MAX(all) >= 25%) THEN 25% ELSE 0%, MIN(all status))
    my $max_pct = 0;
    my $min_pct = 100;

    for my $pct (@percentages) {
        $max_pct = $pct if $pct > $max_pct;
        $min_pct = $pct if $pct < $min_pct;
    }

    my $base_pct = ($max_pct >= 25) ? 25 : 0;
    my $progress = ($min_pct > $base_pct) ? $min_pct : $base_pct;

    return $progress;
}

=head2 get_workflow_status($task_dir, $workflow_files)

Get detailed status information for all workflow files.

Parameters:
  $task_dir       - Path to task directory
  $workflow_files - Arrayref of workflow file hashes with 'path' and 'name' keys

Returns:
  Arrayref of hashes with name, path, status, percent keys

=cut

sub get_workflow_status {
    my ($task_dir, $workflow_files) = @_;

    my @workflow_status;

    for my $file (@$workflow_files) {
        my $status = extract_status($file->{path});
        my $percent = status_to_percent($status);

        push @workflow_status, {
            name => $file->{name},
            path => $file->{path},
            status => $status,
            percent => $percent
        };
    }

    return \@workflow_status;
}

1;

__END__

=head1 AUTHOR

CIG System

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
