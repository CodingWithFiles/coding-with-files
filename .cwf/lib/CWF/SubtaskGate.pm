package CWF::SubtaskGate;

use strict;
use warnings;
use utf8;
use Exporter 'import';
use CWF::TaskPath qw(resolve find_children);
use CWF::TaskState qw(state_done status_get status_is_terminal expected_files);

our @EXPORT_OK = qw(
    nonterminal_children
    phase_is_gated
    format_blocked
);

our $VERSION = '1.0.0';

=head1 NAME

CWF::SubtaskGate - Refuse a parent task's exec and later phases while any child
subtask is non-terminal

=head1 SYNOPSIS

    use CWF::SubtaskGate qw(nonterminal_children phase_is_gated format_blocked);

    if (phase_is_gated($letter)) {
        my @blocked = nonterminal_children($task_num);
        if (@blocked) {
            warn format_blocked($task_num, $letter, \@blocked);
            exit 3;
        }
    }

=head1 DESCRIPTION

A subtask is blocking by definition: work that must not block its parent belongs
in a top-level follow-up task, not a subtask. This module answers one question —
"may task N enter phase L?" — and is the single source of truth for the gated
phase set, for child terminality, and for the operator-facing refusal message.

The gate fires on phase B<entry>, never on subtask creation, so decomposing a
task mid-implementation cannot deadlock it.

=head2 Terminality

A child is terminal only if all three conditions hold:

=over 4

=item 1. B<Completeness> — every workflow file its task type expects is present.

=item 2. B<Parseability> — each of those files yields a status other than C<Unknown>.

=item 3. B<Closure> — every one of those statuses is terminal.

=back

Conditions 1 and 2 are not redundant with 3. C<CWF::TaskState::_get_all_statuses>
skips files that do not exist and discards C<Unknown> statuses before aggregating,
so a child holding nothing but a Finished C<a-task-plan.md> would otherwise
aggregate to 100% and read as terminal.

=cut

# Phases that consume a subtask's outcome, and so may not begin before it lands.
my %GATED_PHASES = map { $_ => 1 } qw(f g h i j);

=head1 FUNCTIONS

=head2 phase_is_gated($letter)

True when phase C<$letter> may not begin while a child subtask is non-terminal.
The planning phases (a-e) are ungated: a parent must be free to plan the work
that its subtasks will carry out.

=cut

sub phase_is_gated {
    my ($letter) = @_;
    return 0 unless defined $letter;
    return $GATED_PHASES{$letter} ? 1 : 0;
}

=head2 nonterminal_children($num, $base_dir)

Returns the list of direct children of task C<$num> that are not terminal, each
as a hashref of C<num>, C<type>, C<percent>, and C<blocking_phases> (an arrayref
of C<[ filename, status ]> pairs, where status is the literal C<missing> for an
absent file).

An empty list means the gate permits entry. Dies when C<$num> cannot be resolved —
an unresolvable task must fail closed, never read as "no children".

Only direct children are examined. Each child's own gate is what holds back its
grandchildren, so the invariant propagates by induction.

=cut

sub nonterminal_children {
    my ($num, $base_dir) = @_;

    my $task = resolve($num, $base_dir)
        or die "CWF::SubtaskGate: cannot resolve task: $num\n";

    my @blocked;
    for my $child (find_children($task->{num}, $base_dir)) {
        my @blocking = _blocking_phases($child);
        next unless @blocking;

        push @blocked, {
            num             => $child->{num},
            type            => $child->{type},
            percent         => state_done($child->{full_path}),
            blocking_phases => \@blocking,
        };
    }

    return @blocked;
}

=head2 format_blocked($num, $letter, \@blocked)

Renders the refusal message shown to the operator. Call sites print it verbatim,
so statuses — which C<status_get> returns unvalidated — are clamped first.

=cut

sub format_blocked {
    my ($num, $letter, $blocked) = @_;

    my $count = scalar @$blocked;
    my $noun  = $count == 1 ? 'subtask' : 'subtasks';

    my $msg = "[CWF] BLOCKED: task $num cannot enter phase $letter\n"
            . "  $count $noun not in a terminal status:\n";

    for my $child (@$blocked) {
        my $detail = join ', ',
            map { "$_->[0]: " . _clamp_status($_->[1]) } @{ $child->{blocking_phases} };
        $msg .= "    $child->{num} ($child->{type}) — $child->{percent}% — $detail\n";
    }

    $msg .= "\nA subtask blocks its parent until it is Finished, Skipped, or Cancelled.\n"
          . "Work that should not block the parent belongs in a top-level follow-up\n"
          . "task, not a subtask.\n";

    return $msg;
}

=head1 PRIVATE FUNCTIONS

=cut

# Every expected workflow file that keeps this child from being terminal, as
# [ filename, status ] pairs. Empty list means the child is terminal.
#
# The expected set comes from CWF::TaskState::expected_files — the same helper
# state_done aggregates over, so the completeness check and the closure check can
# never disagree about which files should be present.
sub _blocking_phases {
    my ($child) = @_;

    my $task_dir = $child->{full_path};
    my $expected = expected_files($task_dir, $child->{type});

    my @blocking;
    for my $file_name (@$expected) {
        my $file_path = "$task_dir/$file_name";

        unless (-f $file_path) {
            push @blocking, [ $file_name, 'missing' ];
            next;
        }

        my $status = status_get($file_path);
        push @blocking, [ $file_name, $status ] unless status_is_terminal($status);
    }

    return @blocking;
}

# status_get returns the raw text following "**Status**:" without validating it
# against the status enum, and call sites print this message verbatim into model
# context. Keep a crafted phase file from routing arbitrary text through it.
sub _clamp_status {
    my ($status) = @_;

    $status =~ s/\s+/ /g;
    $status = substr($status, 0, 32) if length($status) > 32;

    return $status;
}

1;

__END__

=head1 AUTHOR

Coding with Files (CWF) System

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
