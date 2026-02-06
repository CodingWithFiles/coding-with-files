package TaskContextInference;

use strict;
use warnings;
use Exporter 'import';
use Cwd;
use File::Find;
use File::Basename;
use File::Spec;
use TaskState qw(state_achievable);

our $VERSION = '1.0';
our @EXPORT_OK = qw(
    infer_task_context
    get_all_signals
    correlate_signals
    format_output
);

# Weight constants for signal scoring
use constant {
    WEIGHT_BRANCH => 100,
    WEIGHT_WORKTREE => 95,
    WEIGHT_STATE => 85,
    WEIGHT_RECENCY_MAX => 90,
    WEIGHT_PROGRESS_MAX => 60,
    WEIGHT_STATUS_MAX => 80,
    WEIGHT_STEP_STATUS => 100,
    WEIGHT_STEP_RECENCY_MAX => 90,
    WEIGHT_STEP_SEQUENCE => 70,
};

# Decay constant for recency scoring (seconds)
use constant RECENCY_DECAY_CONSTANT => 7200;  # 2 hours

#==============================================================================
# PUBLIC API
#==============================================================================

sub infer_task_context {
    my %opts = @_;
    my $verbose = $opts{verbose} || 0;

    my $result = eval {
        my @signals = get_all_signals();
        my $correlation = correlate_signals(\@signals);

        if ($correlation->{confidence} eq 'no_signals') {
            my $context = {
                confidence => 'no_signals',
                current => 'inconclusive',
                candidates => 0,
                task_nums => ['unknown'],
                task_slugs => ['unknown'],
                workflow_steps => ['unknown'],
                reasons => ['none'],
                signals => \@signals,
            };
            my $output = format_output($context, $verbose);
            $context->{output} = $output;
            return $context;
        }

        if ($correlation->{confidence} eq 'uncorrelated') {
            # Build plural fields for inconclusive case
            my @candidates = @{$correlation->{candidates}};
            my @task_nums = @candidates;
            my @task_slugs;
            my @workflow_steps;
            my @reasons;

            # Get slug and workflow step for each candidate
            for my $task (@candidates) {
                push @task_slugs, _get_task_slug($task) || 'unknown';
                push @workflow_steps, _infer_workflow_step($task) || 'unknown';
            }

            # Determine which signals contributed candidates
            my @non_null = grep { !$_->{null} } @signals;
            for my $signal (@non_null) {
                push @reasons, $signal->{name};
            }

            my $context = {
                confidence => 'uncorrelated',
                current => 'inconclusive',
                candidates => scalar(@candidates),
                task_nums => \@task_nums,
                task_slugs => \@task_slugs,
                workflow_steps => \@workflow_steps,
                reasons => \@reasons,
                signals => \@signals,
                correlation => $correlation,
            };
            my $output = format_output($context, $verbose);
            $context->{output} = $output;
            return $context;
        }

        # Correlated - determine task details
        my $task_num = $correlation->{chosen_task};
        my $task_slug = _get_task_slug($task_num);
        my $workflow_step = _infer_workflow_step($task_num);

        my $context = {
            task_num => $task_num,
            task_slug => $task_slug,
            workflow_step => $workflow_step,
            confidence => 'correlated',
            current => 'conclusive',
            candidates => 1,
            signals => \@signals,
            correlation => $correlation,
        };

        my $output = format_output($context, $verbose);
        $context->{output} = $output;

        return $context;
    };

    if ($@) {
        warn "TaskContextInference error: $@\n";
        return {
            confidence => 'error',
            output => "Error: $@\n",
        };
    }

    return $result;
}

sub get_all_signals {
    my @signals;

    # Task inference signals (5 signals - Status removed during implementation)
    push @signals, _get_branch_signal();
    push @signals, _get_worktree_signal();
    push @signals, _get_state_file_signal();
    push @signals, _get_recency_signal();
    push @signals, _get_progress_signal();
    # Status signal removed: Low quality (manual, stale), heavily correlates with Progress
    # Completed tasks (Finished=100) dominated current task (In Progress=80), causing false negatives

    return @signals;
}

sub correlate_signals {
    my ($signals) = @_;

    my @non_null = grep { !$_->{null} } @$signals;

    if (@non_null == 0) {
        return { confidence => 'no_signals' };
    }

    # Extract top task from each non-null signal
    my @top_tasks = map { $_->{top} } @non_null;

    # Count unique top tasks
    my %seen;
    $seen{$_}++ for @top_tasks;
    my @unique = keys %seen;

    if (@unique == 1) {
        # All agree - correlated
        return {
            confidence => 'correlated',
            chosen_task => $unique[0],
            signals => $signals,
            top_tasks => \@top_tasks,
        };
    } else {
        # Signals disagree - uncorrelated
        return {
            confidence => 'uncorrelated',
            candidates => \@unique,
            signals => $signals,
            top_tasks => \@top_tasks,
        };
    }
}

sub format_output {
    my ($context, $verbose) = @_;

    # Common fields for all scenarios
    my $output = sprintf("current: %s\nconfidence: %s\n",
        $context->{current},
        $context->{confidence}
    );

    if ($context->{current} eq 'conclusive') {
        # Singular fields for conclusive case
        $output .= sprintf(
            "task_num: %s\ntask_slug: %s\nworkflow_step: %s\n",
            $context->{task_num},
            $context->{task_slug},
            $context->{workflow_step}
        );
    } else {
        # Plural fields for inconclusive case
        my $task_nums = join(',', @{$context->{task_nums} || ['unknown']});
        my $task_slugs = join(',', @{$context->{task_slugs} || ['unknown']});
        my $workflow_steps = join(',', @{$context->{workflow_steps} || ['unknown']});
        my $reasons = join(',', @{$context->{reasons} || ['none']});

        $output .= sprintf(
            "task_nums: %s\ntask_slugs: %s\nworkflow_steps: %s\ncandidates: %d\nreasons: %s\n",
            $task_nums,
            $task_slugs,
            $workflow_steps,
            $context->{candidates} || 0,
            $reasons
        );
    }

    if ($verbose) {
        $output .= "\n" . _format_verbose_breakdown($context);
    }

    return $output;
}

#==============================================================================
# SIGNAL COLLECTION - TASK SIGNALS
#==============================================================================

sub _get_branch_signal {
    my $branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`;
    chomp $branch if defined $branch;

    return { name => 'branch', weight => WEIGHT_BRANCH, null => 1 }
        unless $branch;

    # Parse task number from branch name: <type>/<num>-<slug>
    if ($branch =~ m{^[^/]+/(\d+)-}) {
        my $task = $1;
        return {
            name => 'branch',
            weight => WEIGHT_BRANCH,
            candidates => [{ task => $task, score => WEIGHT_BRANCH }],
            top => $task,
            null => 0,
        };
    }

    return { name => 'branch', weight => WEIGHT_BRANCH, null => 1 };
}

sub _get_worktree_signal {
    my $cwd = Cwd::getcwd();
    my $worktree_list = `git worktree list 2>/dev/null`;

    return { name => 'worktree', weight => WEIGHT_WORKTREE, null => 1 }
        unless $worktree_list;

    # Check if CWD is in a worktree and extract task number from path
    for my $line (split /\n/, $worktree_list) {
        if ($line =~ /^(\S+)\s+/) {
            my $wt_path = $1;
            if ($cwd =~ /^\Q$wt_path\E/ && $wt_path =~ /task[_-]?(\d+)/i) {
                my $task = $1;
                return {
                    name => 'worktree',
                    weight => WEIGHT_WORKTREE,
                    candidates => [{ task => $task, score => WEIGHT_WORKTREE }],
                    top => $task,
                    null => 0,
                };
            }
        }
    }

    return { name => 'worktree', weight => WEIGHT_WORKTREE, null => 1 };
}

sub _get_state_file_signal {
    my $state_file = '.cig/task-stack';

    return { name => 'state', weight => WEIGHT_STATE, null => 1 }
        unless -f $state_file;

    open my $fh, '<', $state_file or do {
        warn "Cannot read $state_file: $!\n";
        return { name => 'state', weight => WEIGHT_STATE, null => 1 };
    };

    my @lines = <$fh>;
    close $fh;

    return { name => 'state', weight => WEIGHT_STATE, null => 1 }
        unless @lines;

    # Take last 5 entries (most recent)
    my @recent = @lines[($#lines > 4 ? $#lines - 4 : 0) .. $#lines];
    chomp @recent;

    # Parse dirnames to extract task numbers
    my @candidates;
    my $top_task;

    for my $dirname (reverse @recent) {
        # Extract task number from dirname (e.g., "34-feature-add-task-stack-script" → 34)
        if ($dirname =~ /^(\d+(?:\.\d+)*)-/) {
            my $task = $1;
            push @candidates, { task => $task, score => WEIGHT_STATE };
            $top_task = $task unless defined $top_task;  # First (most recent) is top
        }
    }

    if (@candidates) {
        return {
            name => 'state',
            weight => WEIGHT_STATE,
            candidates => \@candidates,
            top => $top_task,
            null => 0,
        };
    }

    return { name => 'state', weight => WEIGHT_STATE, null => 1 };
}

sub _get_recency_signal {
    my $task_dir = 'implementation-guide';
    return { name => 'recency', weight => WEIGHT_RECENCY_MAX, null => 1 }
        unless -d $task_dir;

    my %task_mtimes;

    # Find all task directories
    opendir my $dh, $task_dir or do {
        warn "Cannot read $task_dir: $!\n";
        return { name => 'recency', weight => WEIGHT_RECENCY_MAX, null => 1 };
    };

    my @entries = readdir $dh;
    closedir $dh;

    for my $entry (@entries) {
        next if $entry =~ /^\./;
        my $path = "$task_dir/$entry";
        next unless -d $path;

        # Extract task number from directory name: <num>-<type>-<slug>
        if ($entry =~ /^(\d+)-/) {
            my $task = $1;
            my $max_mtime = _get_dir_max_mtime($path);
            $task_mtimes{$task} = $max_mtime if $max_mtime;
        }
    }

    return { name => 'recency', weight => WEIGHT_RECENCY_MAX, null => 1 }
        unless %task_mtimes;

    # Score tasks by recency (exponential decay)
    my $now = time();
    my @candidates;

    for my $task (keys %task_mtimes) {
        my $seconds_ago = $now - $task_mtimes{$task};
        my $score = _score_recency($seconds_ago);
        push @candidates, { task => $task, score => $score };
    }

    # Sort by score descending, take top 5
    @candidates = sort { $b->{score} <=> $a->{score} } @candidates;
    @candidates = splice(@candidates, 0, 5);

    return { name => 'recency', weight => WEIGHT_RECENCY_MAX, null => 1 }
        unless @candidates;

    return {
        name => 'recency',
        weight => WEIGHT_RECENCY_MAX,
        candidates => \@candidates,
        top => $candidates[0]->{task},
        null => 0,
    };
}

sub _get_progress_signal {
    my $task_dir = 'implementation-guide';
    return { name => 'progress', weight => WEIGHT_PROGRESS_MAX, null => 1 }
        unless -d $task_dir;

    my %task_progress;

    opendir my $dh, $task_dir or return { name => 'progress', weight => WEIGHT_PROGRESS_MAX, null => 1 };
    my @entries = readdir $dh;
    closedir $dh;

    for my $entry (@entries) {
        next if $entry =~ /^\./;
        my $path = "$task_dir/$entry";
        next unless -d $path;

        if ($entry =~ /^(\d+)-/) {
            my $task = $1;
            my $progress_pct = _calculate_task_progress($path);
            $task_progress{$task} = $progress_pct if defined $progress_pct;
        }
    }

    return { name => 'progress', weight => WEIGHT_PROGRESS_MAX, null => 1 }
        unless %task_progress;

    # Score tasks by progress (bell curve, peak at 50%)
    my @candidates;
    for my $task (keys %task_progress) {
        my $score = _score_progress($task_progress{$task});
        push @candidates, { task => $task, score => $score };
    }

    @candidates = sort { $b->{score} <=> $a->{score} } @candidates;
    @candidates = splice(@candidates, 0, 5);

    return { name => 'progress', weight => WEIGHT_PROGRESS_MAX, null => 1 }
        unless @candidates;

    return {
        name => 'progress',
        weight => WEIGHT_PROGRESS_MAX,
        candidates => \@candidates,
        top => $candidates[0]->{task},
        null => 0,
    };
}

sub _get_status_signal {
    my $task_dir = 'implementation-guide';
    return { name => 'status', weight => WEIGHT_STATUS_MAX, null => 1 }
        unless -d $task_dir;

    my %task_status_scores;

    opendir my $dh, $task_dir or return { name => 'status', weight => WEIGHT_STATUS_MAX, null => 1 };
    my @entries = readdir $dh;
    closedir $dh;

    for my $entry (@entries) {
        next if $entry =~ /^\./;
        my $path = "$task_dir/$entry";
        next unless -d $path;

        if ($entry =~ /^(\d+)-/) {
            my $task = $1;
            my $status_score = _get_task_status_score($path);
            $task_status_scores{$task} = $status_score if $status_score > 0;
        }
    }

    return { name => 'status', weight => WEIGHT_STATUS_MAX, null => 1 }
        unless %task_status_scores;

    my @candidates;
    for my $task (keys %task_status_scores) {
        push @candidates, { task => $task, score => $task_status_scores{$task} };
    }

    @candidates = sort { $b->{score} <=> $a->{score} } @candidates;
    @candidates = splice(@candidates, 0, 5);

    return { name => 'status', weight => WEIGHT_STATUS_MAX, null => 1 }
        unless @candidates;

    return {
        name => 'status',
        weight => WEIGHT_STATUS_MAX,
        candidates => \@candidates,
        top => $candidates[0]->{task},
        null => 0,
    };
}

#==============================================================================
# SCORING ALGORITHMS
#==============================================================================

sub _score_recency {
    my ($seconds_ago) = @_;
    return 0 unless defined $seconds_ago && $seconds_ago >= 0;

    # Exponential decay: score = max_weight * exp(-seconds / decay_constant)
    my $score = WEIGHT_RECENCY_MAX * exp(-$seconds_ago / RECENCY_DECAY_CONSTANT);
    return int($score + 0.5);  # Round to nearest integer
}

sub _score_progress {
    my ($percentage) = @_;
    return 0 unless defined $percentage && $percentage >= 0 && $percentage <= 100;

    # Linear scoring: higher work potential = higher score
    # Cliff function from state_achievable creates linear ramp where
    # tasks closer to completion score higher (momentum to finish)
    my $score = int(($percentage / 100) * WEIGHT_PROGRESS_MAX);
    return $score;
}

sub _score_status {
    my ($status) = @_;
    return 0 unless defined $status;

    # Linear mapping of status to score
    my %status_scores = (
        'Finished'    => 100,
        'Testing'     => 75,
        'Implemented' => 50,
        'In Progress' => 80,
        'Blocked'     => 15,
        'Backlog'     => 0,
        'To-Do'       => 0,
    );

    return $status_scores{$status} || 0;
}

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================

sub _get_dir_max_mtime {
    my ($dir) = @_;
    return unless -d $dir;

    my $max_mtime = 0;

    opendir my $dh, $dir or return;
    my @files = readdir $dh;
    closedir $dh;

    for my $file (@files) {
        next if $file =~ /^\./;
        my $path = "$dir/$file";
        next unless -f $path;

        my $mtime = (stat($path))[9];
        $max_mtime = $mtime if $mtime > $max_mtime;
    }

    return $max_mtime > 0 ? $max_mtime : undef;
}

sub _calculate_task_progress {
    my ($task_dir) = @_;
    return unless -d $task_dir;

    # Use TaskState library for work potential calculation (cliff function)
    return TaskState::state_achievable($task_dir);
}

sub _get_task_status_score {
    my ($task_dir) = @_;
    return 0 unless -d $task_dir;

    my $max_score = 0;

    opendir my $dh, $task_dir or return 0;
    my @files = readdir $dh;
    closedir $dh;

    for my $file (@files) {
        next unless $file =~ /^[a-j]-.*\.md$/;
        my $path = "$task_dir/$file";
        next unless -f $path;

        open my $fh, '<', $path or next;
        while (<$fh>) {
            if (/^\*\*Status\*\*:\s*(.+)$/i) {
                my $status = $1;
                my $score = _score_status($status);
                $max_score = $score if $score > $max_score;
                last;
            }
        }
        close $fh;
    }

    return $max_score;
}

sub _get_task_slug {
    my ($task_num) = @_;
    return 'unknown' unless defined $task_num;

    my $task_dir = 'implementation-guide';
    return 'unknown' unless -d $task_dir;

    opendir my $dh, $task_dir or return 'unknown';
    my @entries = readdir $dh;
    closedir $dh;

    for my $entry (@entries) {
        if ($entry =~ /^$task_num-[^-]+-(.+)$/) {
            return $1;
        }
    }

    return 'unknown';
}

sub _infer_workflow_step {
    my ($task_num) = @_;
    return 'unknown' unless defined $task_num;

    my $task_dir = _get_task_dir($task_num);
    return 'unknown' unless $task_dir && -d $task_dir;

    # Look for "In Progress" status in workflow files
    opendir my $dh, $task_dir or return 'unknown';
    my @files = readdir $dh;
    closedir $dh;

    my @workflow_files = grep { /^[a-j]-.*\.md$/ } @files;

    # First pass: find "In Progress" file
    for my $file (sort @workflow_files) {
        my $path = "$task_dir/$file";
        open my $fh, '<', $path or next;
        while (<$fh>) {
            if (/^\*\*Status\*\*:\s*In Progress/i) {
                close $fh;
                $file =~ s/\.md$//;
                return $file;
            }
        }
        close $fh;
    }

    # Second pass: find most recently modified file
    my $newest_file;
    my $newest_mtime = 0;

    for my $file (@workflow_files) {
        my $path = "$task_dir/$file";
        my $mtime = (stat($path))[9];
        if ($mtime > $newest_mtime) {
            $newest_mtime = $mtime;
            $newest_file = $file;
        }
    }

    if ($newest_file) {
        $newest_file =~ s/\.md$//;
        return $newest_file;
    }

    return 'unknown';
}

sub _get_task_dir {
    my ($task_num) = @_;
    return unless defined $task_num;

    my $task_base = 'implementation-guide';
    return unless -d $task_base;

    opendir my $dh, $task_base or return;
    my @entries = readdir $dh;
    closedir $dh;

    for my $entry (@entries) {
        if ($entry =~ /^$task_num-/ && -d "$task_base/$entry") {
            return "$task_base/$entry";
        }
    }

    return;
}

sub _format_uncorrelated {
    my ($correlation, $verbose) = @_;

    # Deprecated: Now handled by unified format_output()
    # This function kept for backward compatibility during migration
    # but should not be called in current code path

    my @candidates = @{$correlation->{candidates}};
    my $output = "Signals disagree on current task.\n\n";
    $output .= "Top candidates:\n";

    for my $task (@candidates) {
        $output .= "  - Task $task\n";
    }

    $output .= "\nPlease specify task number explicitly or clarify context.\n";

    if ($verbose) {
        $output .= "\n" . _format_signal_details($correlation->{signals});
    }

    return $output;
}

sub _format_verbose_breakdown {
    my ($context) = @_;

    my $output = "Signal Breakdown:\n";
    $output .= "=" x 60 . "\n";

    $output .= sprintf("Task: %s (%s)\n", $context->{task_num}, $context->{task_slug});
    $output .= sprintf("Workflow Step: %s\n", $context->{workflow_step});
    $output .= sprintf("Confidence: %s\n\n", $context->{confidence});

    $output .= "Task Signals:\n";
    $output .= _format_signal_details($context->{signals});

    $output .= "\nCorrelation: ALL SIGNALS AGREE\n";

    return $output;
}

sub _format_signal_details {
    my ($signals) = @_;
    my $output = "";

    for my $signal (@$signals) {
        my $name = $signal->{name};
        my $weight = $signal->{weight};

        if ($signal->{null}) {
            $output .= sprintf("  %-15s null\n", "$name:");
            next;
        }

        my $top = $signal->{top};
        my $candidates = $signal->{candidates};
        my $top_score = $candidates->[0]->{score};

        $output .= sprintf("  %-15s task %s (score: %d, top of %d)\n",
            "$name:", $top, $top_score, scalar(@$candidates));
    }

    return $output;
}

1;

__END__

=head1 NAME

TaskContextInference - Signal-based inference for task and workflow step detection

=head1 SYNOPSIS

    use TaskContextInference qw(infer_task_context);

    my $context = infer_task_context(verbose => 0);
    print $context->{output};

=head1 DESCRIPTION

This module implements signal-based inference to automatically determine the
current task and workflow step by correlating multiple environmental signals
(git branch, worktree, file timestamps, status markers, etc.).

=head1 FUNCTIONS

=head2 infer_task_context(%opts)

Main entry point for task and workflow step inference.

B<Parameters:>

=over 4

=item * verbose => 0|1 - Enable verbose signal breakdown (default: 0)

=back

B<Returns:> Hashref with keys:

=over 4

=item * task_num - Inferred task number (e.g., "32")

=item * task_slug - Task slug from directory name

=item * workflow_step - Inferred workflow step (e.g., "f-implementation-exec")

=item * confidence - 'correlated', 'uncorrelated', or 'no_signals'

=item * output - Formatted output string ready to print

=back

B<Example:>

    my $ctx = infer_task_context(verbose => 1);
    print $ctx->{output};
    exit($ctx->{confidence} eq 'correlated' ? 0 : 1);

=head2 get_all_signals()

Collects all task and workflow step signals from environment.

B<Task Signals:> Branch, Worktree, State File, Recency (top 5), Progress (top 5)

B<Workflow Step Signals:> Status, Recency, Sequence

B<Returns:> Array of signal hashrefs, each containing:

=over 4

=item * name - Signal name

=item * weight - Signal weight (importance)

=item * candidates - Arrayref of candidate tasks/steps with scores

=item * top - Top candidate (highest score)

=item * null - 1 if signal provided no information, 0 otherwise

=back

B<Example:>

    my @signals = get_all_signals();
    for my $sig (@signals) {
        next if $sig->{null};
        print "$sig->{name}: task $sig->{top} (score: ...)\n";
    }

=head2 correlate_signals(\@signals)

Checks if all non-null signals agree on the top task.

B<Parameters:>

=over 4

=item * \@signals - Arrayref of signal hashes from get_all_signals()

=back

B<Returns:> Hashref with keys:

=over 4

=item * confidence - 'correlated' (all agree), 'uncorrelated' (disagree), or 'no_signals'

=item * chosen_task - Task number if correlated

=item * candidates - Arrayref of candidate tasks if uncorrelated

=back

B<Correlation Logic:> Filters out null signals, extracts top task from each,
returns 'correlated' if all non-null signals agree on same task.

B<Example:>

    my $corr = correlate_signals(\@signals);
    if ($corr->{confidence} eq 'correlated') {
        print "All signals agree on task $corr->{chosen_task}\n";
    }

=head2 format_output($context, $verbose)

Formats inference results as string for output.

B<Parameters:>

=over 4

=item * $context - Hashref with task_num, task_slug, workflow_step, confidence

=item * $verbose - 0 for simple output, 1 for verbose signal breakdown

=back

B<Returns:> String ready to print to STDOUT

B<Output Formats:>

=over 4

=item * Simple: 3 lines (task_num, task_slug, workflow_step)

=item * Verbose: Simple + signal breakdown with scores and correlation status

=item * Uncorrelated: Shows top candidates and prompts user

=back

B<Example:>

    my $output = format_output($context, 0);
    print $output;  # Prints 3 lines

=head1 SIGNAL WEIGHTS

Task inference uses weighted signal aggregation:

=over 4

=item * Branch: 100 (strongest when present)

=item * Worktree: 95 (strong indication of isolated work)

=item * State File: 85 (explicit but can be stale)

=item * Recency: 0-90 (exponential decay over time)

=item * Progress: 0-60 (linear scoring based on work potential)

=back

Workflow step inference:

=over 4

=item * Status: 100 (current step status marker)

=item * Recency: 0-90 (most recently modified step)

=item * Sequence: 70 (alphabetical progression)

=back

=head1 AUTHOR

Claude Sonnet 4.5 with Matt Keenan

=cut
