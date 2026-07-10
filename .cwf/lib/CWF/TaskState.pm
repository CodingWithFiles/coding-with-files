package CWF::TaskState;

use strict;
use warnings;
use utf8;
use Exporter 'import';
use File::Basename;
use CWF::WorkflowFiles qw(load_config);
use CWF::WorkflowFiles::V20;
use CWF::WorkflowFiles::V21;
use CWF::MarkdownParser qw(find_field_line);

our @EXPORT_OK = qw(
    state_done
    state_achievable
    status_percent
    status_get
    status_set
    status_is_valid
    status_is_terminal
    expected_files
);

our $VERSION = '1.0.0';

# Default status value mappings (if not in cwf-project.json)
my %DEFAULT_STATUS_MAP = (
    'Finished'    => 100,
    'Skipped'     => 100,
    'Testing'     => 75,
    'In Progress' => 25,
    'Blocked'     => 15,
    'To-Do'       => 0,
    'Backlog'     => 0,
    'Cancelled'   => 0,
);

# Cache for status map loaded from config
my $_status_map_cache;

=head1 NAME

TaskState - Task state measurements for retrospective and prospective analysis

=head1 SYNOPSIS

    use CWF::TaskState qw(state_done state_achievable status_percent status_get status_set);

    # Retrospective: How far have we got?
    my $completion = state_done('implementation-guide/32-feature-foo');
    # Returns: 0-100% (MIN bottleneck formula)

    # Prospective: How much room to progress?
    my $potential = state_achievable('implementation-guide/32-feature-foo');
    # Returns: 0-100% (cliff function)

    # Utility: Map status string to percentage
    my $pct = status_percent('In Progress');  # Returns: 25

    # Utility: Get status from workflow file
    my $status = status_get('path/to/a-plan.md');  # Returns: "Finished"

    # Utility: Set status in workflow file (validates, idempotent)
    my $changed = status_set('path/to/a-plan.md', 'In Progress');  # Returns: 1

=head1 DESCRIPTION

TaskState provides state measurement functions for CIG tasks, separating
retrospective analysis ("where are we?") from prospective analysis ("where
should we work?").

=head2 Retrospective vs Prospective

B<Retrospective> (state_done): Measures completion for status reporting.
Uses MIN bottleneck formula - task is only as complete as its slowest step.
Used by status-aggregator for progress reporting.

B<Prospective> (state_achievable): Measures work potential for inference.
Uses cliff function - "the closer a task is to complete, the more we want
to complete it". Used by task-context-inference for active work prediction.

=head2 Naming Convention

Functions follow MSB (Most Significant Byte) ordering - category first:
- state_* for measurements (nouns - present perfect gerund)
- status_* for utilities (extraction, mapping)

=head1 FUNCTIONS

=head2 state_done($task_dir)

Returns retrospective completion percentage (0-100) using MIN bottleneck formula.

Formula: MAX(MIN(all status percentages), base 25% if any step >= 25%)

This represents "how far we've got" - the task is only as complete as its
slowest step (bottleneck).

=cut

sub state_done {
    my ($task_dir) = @_;

    my @statuses = _get_all_statuses($task_dir);
    return 0 unless @statuses;

    my @percentages = grep { defined $_ } map { _is_closed($_) ? 100 : status_percent($_) } @statuses;
    return 0 unless @percentages;

    # MIN bottleneck formula
    my $max_pct = _max(@percentages);
    my $min_pct = _min(@percentages);
    my $base_pct = ($max_pct >= 25) ? 25 : 0;
    my $progress = ($min_pct > $base_pct) ? $min_pct : $base_pct;

    return $progress;
}

=head2 state_achievable($task_dir)

Returns prospective work potential percentage (0-100) using cliff function.

Cliff function implements: "The closer a task is to complete, the more we
want to complete it" with linear ramp and cliff at 100%.

Rules:
- 100% complete → 0 (CLIFF: no work left)
- Fresh (0%, no active work) → 10 (baseline)
- Dormant (started but no active) → completion * 0.3 (dampened)
- Active (has In Progress/Testing) → completion (linear ramp)

This represents "how much room to progress" - tasks near completion score
higher (momentum to finish), blocked tasks score 0 (can't work).

=cut

sub state_achievable {
    my ($task_dir) = @_;

    # Step 1: Get completion
    my $completion = state_done($task_dir);

    # Step 2: Analyze statuses
    my @statuses = _get_all_statuses($task_dir);
    return 0 unless @statuses;

    my $active_count = grep { _is_active_work($_) } @statuses;

    # Step 3: Cliff function
    my $work_potential;

    if ($completion >= 100) {
        # CLIFF: Complete, no work left
        $work_potential = 0;
    } elsif ($completion == 0 && $active_count == 0) {
        # FRESH: No progress yet, no active work - small baseline
        $work_potential = 10;
    } elsif ($active_count == 0) {
        # DORMANT: Started but no active work currently - dampened
        $work_potential = int($completion * 0.3);
    } else {
        # ACTIVE: Linear ramp - more complete = more desire to finish
        $work_potential = $completion;
    }

    return $work_potential;
}

=head2 status_percent($status)

Maps status string to percentage value (0-100).

Loads mappings from cwf-project.json workflow.status-values, falls back
to defaults if not configured.

Default mappings:
- Finished: 100%, Testing: 75%
- In Progress: 25%, Blocked: 15%
- To-Do: 0%, Backlog: 0%

=cut

sub status_percent {
    my ($status) = @_;

    _ensure_status_map();

    # Look up status (try exact match first, then case-insensitive)
    if (exists $_status_map_cache->{$status}) {
        return $_status_map_cache->{$status};
    }

    # Try lowercase
    my $lower = lc($status);
    for my $key (keys %$_status_map_cache) {
        if (lc($key) eq $lower) {
            return $_status_map_cache->{$key};
        }
    }

    # Unknown status
    return 0;
}

=head2 status_get($file_path)

Extracts status value from workflow markdown file.

Searches for "## Status" or "## Current Status" section and extracts
the value from "**Status**: <value>" line.

Returns: Status string or "Unknown" if not found.

=cut

sub status_get {
    my ($file_path) = @_;

    my ($line_idx, $value, @lines) = _find_status_line($file_path);
    return "Unknown" unless defined $line_idx;
    return $value;
}

=head2 status_set($file_path, $new_status)

Updates the status value in a workflow markdown file.

Validates C<$new_status> against C<cwf-project.json> status-values.
Idempotent: returns 1 if changed, 0 if already at target value.
Dies on invalid status, missing file, or missing status field.

=cut

sub status_set {
    my ($file_path, $new_status) = @_;

    _ensure_status_map();
    unless (exists $_status_map_cache->{$new_status}) {
        my $list = join ', ', sort keys %$_status_map_cache;
        die "Invalid status \"$new_status\" — valid: $list\n";
    }

    my ($line_idx, $current, @lines) = _find_status_line($file_path);
    die "No **Status**: field found in $file_path\n" unless defined $line_idx;
    return 0 if $current eq $new_status;    # idempotent no-op

    $lines[$line_idx] = "**Status**: $new_status\n";

    open my $wfh, '>', $file_path or die "Cannot write $file_path: $!\n";
    print $wfh @lines;
    close $wfh;

    return 1;
}

=head2 status_is_valid($status)

Returns true if C<$status> is a recognised status value in C<cwf-project.json>.

=cut

sub status_is_valid {
    my ($status) = @_;
    _ensure_status_map();
    return exists $_status_map_cache->{$status};
}

=head2 status_is_terminal($status)

Returns true if C<$status> means the step is intentionally ended — Finished,
Skipped, or Cancelled — rather than merely un-started or in flight.

Terminal is not the same as complete: Cancelled maps to 0%, yet a cancelled step
is no longer a progress bottleneck. Callers that need "is this step done with"
must ask this rather than compare percentages.

=cut

sub status_is_terminal {
    my ($status) = @_;
    return 0 unless defined $status;
    return ($status eq 'Finished' || $status eq 'Cancelled' || $status eq 'Skipped') ? 1 : 0;
}

=head2 expected_files($task_dir, $task_type)

Returns an arrayref of the workflow filenames C<$task_dir> is expected to hold,
detecting v2.1 by the presence of C<f-implementation-exec.md> and falling back to
v2.0 otherwise.

Single source of truth for "which files should be here". Callers that measure a
task's completeness must agree with C<state_done> on the expected set, so they
share this detection rather than re-deriving it.

Deliberately not C<CWF::TaskPath::detect_format>, whose file-based rule is broader
(it also accepts C<e-testing-plan.md>) and would disagree with the aggregation here.

=cut

sub expected_files {
    my ($task_dir, $task_type) = @_;

    return -f "$task_dir/f-implementation-exec.md"
        ? CWF::WorkflowFiles::V21::get_workflow_files($task_type)
        : CWF::WorkflowFiles::V20::get_workflow_files($task_type);
}

=head1 PRIVATE FUNCTIONS

=cut

# Ensure $_status_map_cache is populated from config or defaults
sub _ensure_status_map {
    return if $_status_map_cache;
    my $config = load_config();
    if ($config && $config->{workflow} && $config->{workflow}{'status-values'}) {
        $_status_map_cache = $config->{workflow}{'status-values'};
    } else {
        $_status_map_cache = \%DEFAULT_STATUS_MAP;
    }
}

# Status-specific regexes for MarkdownParser delegation
my $STATUS_SECTION_RE = qr/^## (?:Current )?Status\s*$/i;
my $STATUS_KEY_RE     = qr/^\*\*Status\*\*:\s*(.+?)\s*$/;

# Find the **Status**: line — delegates to MarkdownParser::find_field_line.
# Returns: ($line_index, $status_value, @all_lines) or () if not found.
sub _find_status_line {
    my ($file_path) = @_;
    return find_field_line($file_path, $STATUS_SECTION_RE, $STATUS_KEY_RE);
}

# Get all status values from workflow files in task directory
sub _get_all_statuses {
    my ($task_dir) = @_;

    return () unless -d $task_dir;

    # Detect task type from directory name
    my $dir_name = basename($task_dir);
    my ($task_type) = $dir_name =~ /^[0-9.]+-([a-z]+)-/;
    $task_type ||= 'feature';  # Default

    my $workflow_files = expected_files($task_dir, $task_type);

    return () unless $workflow_files && @$workflow_files;

    # Extract statuses from existing files
    my @statuses;
    for my $file_name (@$workflow_files) {
        my $file_path = "$task_dir/$file_name";
        next unless -f $file_path;

        my $status = status_get($file_path);
        push @statuses, $status if $status ne "Unknown";
    }

    return @statuses;
}

# Check if status indicates step is intentionally ended (not a progress bottleneck)
sub _is_closed {
    my ($status) = @_;
    return status_is_terminal($status);
}

# Check if status indicates active work (In Progress, Testing)
sub _is_active_work {
    my ($status) = @_;
    return ($status eq 'In Progress' || $status eq 'Testing');
}

# Return maximum value from array
sub _max {
    my @vals = @_;
    my $max = shift @vals;
    for (@vals) {
        $max = $_ if $_ > $max;
    }
    return $max;
}

# Return minimum value from array
sub _min {
    my @vals = @_;
    my $min = shift @vals;
    for (@vals) {
        $min = $_ if $_ < $min;
    }
    return $min;
}

1;

__END__

=head1 DESIGN RATIONALE

TaskState separates two fundamentally different purposes for progress
measurement:

=head2 Why Two Functions?

During Task 32 implementation, discovered that progress scoring serves
two distinct purposes:

1. B<Retrospective>: "How far have we got?" (completion reporting)
   - Pessimistic MIN bottleneck - task held back by slowest step
   - Used by status-aggregator for project state visibility
   - Answers: "What's blocking us?"

2. B<Prospective>: "How much room to progress?" (work prediction)
   - Optimistic cliff function - momentum to complete
   - Used by task-context-inference for active work inference
   - Answers: "Where should we work?"

=head2 Why Cliff Function?

User insight: "The closer a task is to complete, the more we want to
complete it."

Cliff function creates linear ramp where higher completion = higher score,
with special handling:
- Blocked tasks score 0 (can't progress)
- Complete tasks score 0 (cliff - no work left)
- Active tasks score completion % (linear ramp)

This naturally deprioritizes blocked/complete tasks while emphasizing
tasks that are progressing and near completion.

=head2 Why MSB Naming?

MSB (Most Significant Byte) naming puts category first:
- state_* groups all state measurements
- status_* groups all status utilities
- Aids autocomplete and cognitive load
- Follows "Army naming" convention (Coat, Cold Weather, Field)

=head1 AUTHOR

Created for Task 32: task-tracking-using-inference-scoring

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>

=head1 SEE ALSO

L<CWF::MarkdownParser>, L<CWF::WorkflowFiles>, L<TaskContextInference>

=cut
