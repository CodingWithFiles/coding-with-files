#!/usr/bin/env perl
#
# subtask-gate.t - CWF::SubtaskGate and the `workflow-manager gate` CLI (Task 225)
#
# A parent task may not enter an exec or later phase while any direct child
# subtask is non-terminal. The weight here is on the fail-open cases: a safety
# gate that wrongly *permits* is the only failure mode that matters.
#
# Two fixture hazards, both load-bearing:
#   1. $base_dir must reach both resolve() and find_children(), or each falls
#      back to find_base_dir() — the real repo — and the suite passes for the
#      wrong reason. TC-13 exists to detect that.
#   2. The CLI takes no --base-dir, so its tests chdir to a tempdir outside any
#      git repository, where find_base_dir() falls back to ./implementation-guide.
#

use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Basename;
use Cwd qw(getcwd);

use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";

use CWF::SubtaskGate qw(nonterminal_children phase_is_gated format_blocked);
use CWF::TaskState qw(state_done status_percent);

my $WORKFLOW_MANAGER = "$FindBin::Bin/../.cwf/scripts/command-helpers/workflow-manager";
my $ORIG_CWD         = getcwd();

#==============================================================================
# Fixtures
#==============================================================================

# Full v2.1 file set per task type, mirroring CWF::WorkflowFiles::V21.
my %FILES = (
    bugfix => [qw(a-task-plan.md c-design-plan.md d-implementation-plan.md
                  e-testing-plan.md f-implementation-exec.md g-testing-exec.md
                  j-retrospective.md)],
    chore  => [qw(a-task-plan.md d-implementation-plan.md e-testing-plan.md
                  f-implementation-exec.md g-testing-exec.md j-retrospective.md)],
);

# Create a task directory holding one workflow file per entry in %statuses.
# Passing a partial %statuses creates a partial (incomplete) task on purpose.
sub mk_task {
    my ($parent_dir, $num, $type, $slug, $statuses) = @_;

    my $dir = "$parent_dir/$num-$type-$slug";
    make_path($dir);

    for my $file (sort keys %$statuses) {
        my $status = $statuses->{$file};
        open my $fh, '>:encoding(UTF-8)', "$dir/$file" or die "cannot write $dir/$file: $!";
        print $fh "# $slug\n- **Template Version**: 2.1\n\n## Status\n";
        print $fh "**Status**: $status\n" if defined $status;   # undef => Unknown
        close $fh;
    }

    return $dir;
}

# Every expected file of $type at a single status.
sub all_at {
    my ($type, $status) = @_;
    return { map { $_ => $status } @{ $FILES{$type} } };
}

sub new_base {
    my $root = tempdir(CLEANUP => 1);
    my $base = "$root/implementation-guide";
    make_path($base);
    return ($root, $base);
}

#==============================================================================
# Permitted paths - the gate must not fire
#==============================================================================

subtest 'TC-1: no children => permitted' => sub {
    my ($root, $base) = new_base();
    mk_task($base, '1', 'bugfix', 'lonely', all_at('bugfix', 'In Progress'));

    my @blocked = nonterminal_children('1', $base);
    is(scalar @blocked, 0, 'a childless parent is never blocked');
};

subtest 'TC-2/3/4: a child wholly at one terminal status => permitted' => sub {
    for my $status (qw(Finished Skipped Cancelled)) {
        my ($root, $base) = new_base();
        my $parent = mk_task($base, '1', 'bugfix', 'parent', all_at('bugfix', 'Finished'));
        mk_task($parent, '1.1', 'chore', 'child', all_at('chore', $status));

        my @blocked = nonterminal_children('1', $base);
        is(scalar @blocked, 0, "child all-$status permits the parent");
    }
};

subtest 'TC-4b: Cancelled is 0% yet terminal' => sub {
    # Cancelled maps to 0% in the raw status map and is rescued only by the
    # terminality predicate. A percentage-based gate would wrongly block here.
    my ($root, $base) = new_base();
    my $parent = mk_task($base, '1', 'bugfix', 'parent', all_at('bugfix', 'Finished'));
    my $child  = mk_task($parent, '1.1', 'chore', 'child', all_at('chore', 'Cancelled'));

    is(status_percent('Cancelled'), 0, 'Cancelled is 0% in the raw map');
    is(scalar nonterminal_children('1', $base), 0, 'yet it does not block');
};

subtest 'TC-5: mixed terminal statuses across phases => permitted' => sub {
    my ($root, $base) = new_base();
    my $parent = mk_task($base, '1', 'bugfix', 'parent', all_at('bugfix', 'Finished'));

    my @mix = qw(Finished Skipped Cancelled Finished Skipped Cancelled);
    my %statuses;
    @statuses{ @{ $FILES{chore} } } = @mix;
    mk_task($parent, '1.1', 'chore', 'child', \%statuses);

    is(scalar nonterminal_children('1', $base), 0, 'a mix of terminal statuses permits');
};

subtest 'TC-6: two children, both terminal => permitted' => sub {
    my ($root, $base) = new_base();
    my $parent = mk_task($base, '1', 'bugfix', 'parent', all_at('bugfix', 'Finished'));
    mk_task($parent, '1.1', 'chore', 'first',  all_at('chore', 'Finished'));
    mk_task($parent, '1.2', 'chore', 'second', all_at('chore', 'Skipped'));

    is(scalar nonterminal_children('1', $base), 0, 'both terminal permits');
};

subtest 'TC-7: plan phases are ungated' => sub {
    ok(!phase_is_gated($_), "phase $_ is ungated") for qw(a b c d e);
    ok( phase_is_gated($_), "phase $_ is gated")   for qw(f g h i j);
    ok(!phase_is_gated(undef), 'undef phase is not reported as gated');
};

subtest 'TC-8: a non-terminal grandchild does not block the grandparent' => sub {
    my ($root, $base) = new_base();
    my $parent = mk_task($base, '1', 'bugfix', 'parent', all_at('bugfix', 'Finished'));
    my $child  = mk_task($parent, '1.1', 'chore', 'child', all_at('chore', 'Finished'));
    mk_task($child, '1.1.1', 'chore', 'grandchild', all_at('chore', 'In Progress'));

    is(scalar nonterminal_children('1', $base), 0,
       'parent permitted: 1.1 is terminal, and 1.1 own gate holds back 1.1.1');
    is(scalar nonterminal_children('1.1', $base), 1,
       'the grandchild blocks its own parent, by induction');
};

#==============================================================================
# Blocked paths - the gate must fire
#==============================================================================

subtest 'TC-9: each non-terminal status blocks' => sub {
    for my $status ('In Progress', 'Testing', 'Blocked', 'Backlog', 'To-Do') {
        my ($root, $base) = new_base();
        my $parent = mk_task($base, '1', 'bugfix', 'parent', all_at('bugfix', 'Finished'));

        my %statuses = %{ all_at('chore', 'Finished') };
        $statuses{'d-implementation-plan.md'} = $status;
        mk_task($parent, '1.1', 'chore', 'child', \%statuses);

        my @blocked = nonterminal_children('1', $base);
        is(scalar @blocked, 1, "child at '$status' blocks the parent");
        is($blocked[0]{num}, '1.1', 'the offending child is named');
        is_deeply($blocked[0]{blocking_phases}, [['d-implementation-plan.md', $status]],
                  "the offending phase and status '$status' are named");
    }
};

subtest 'TC-10: an unparseable status blocks (regression: fail-open)' => sub {
    # _get_all_statuses discards Unknown before aggregating, so state_done
    # returns 100 here. Without an explicit check the gate would fail open.
    my ($root, $base) = new_base();
    my $parent = mk_task($base, '1', 'bugfix', 'parent', all_at('bugfix', 'Finished'));

    my %statuses = %{ all_at('chore', 'Finished') };
    $statuses{'e-testing-plan.md'} = undef;   # file present, no **Status**: line
    mk_task($parent, '1.1', 'chore', 'child', \%statuses);

    my @blocked = nonterminal_children('1', $base);
    is(scalar @blocked, 1, 'a corrupt status line blocks');
    is_deeply($blocked[0]{blocking_phases}, [['e-testing-plan.md', 'Unknown']],
              'the unparseable phase is named as Unknown');
};

subtest 'TC-11: a partial file set blocks (regression: the D2 bug)' => sub {
    # _get_all_statuses skips absent files, so a child holding only Finished
    # files aggregates to 100% however few of them there are, and no Unknown
    # ever fires — nothing was there to parse. f-implementation-exec.md must be
    # present or the task reads as v2.0, whose filenames all differ; see TC-11b.
    # This test fails against a state_done == 100 -only implementation.
    my ($root, $base) = new_base();
    my $parent = mk_task($base, '1', 'bugfix', 'parent', all_at('bugfix', 'Finished'));
    my $child  = mk_task($parent, '1.1', 'chore', 'child', {
        'a-task-plan.md'           => 'Finished',
        'f-implementation-exec.md' => 'Finished',
    });

    is(state_done($child), 100, 'state_done alone reports the partial child complete');

    my @blocked = nonterminal_children('1', $base);
    is(scalar @blocked, 1, 'yet the gate blocks it');

    my @named = map { $_->[0] } @{ $blocked[0]{blocking_phases} };
    is_deeply([sort @named],
              [qw(d-implementation-plan.md e-testing-plan.md g-testing-exec.md j-retrospective.md)],
              'exactly the four absent workflow files are named');
    is_deeply([map { $_->[1] } @{ $blocked[0]{blocking_phases} }],
              [('missing') x 4], 'each is reported missing');
};

subtest 'TC-11b: a child stripped of its v2.1 marker blocks as a v2.0 task' => sub {
    # Deleting f-implementation-exec.md flips _get_all_statuses to the v2.0 file
    # names (a-plan.md, ...), none of which exist, so state_done reports 0. The
    # gate blocks it too, naming the v2.0 set. Blocked either way — recorded so
    # the two detection paths are not confused for one another.
    my ($root, $base) = new_base();
    my $parent = mk_task($base, '1', 'bugfix', 'parent', all_at('bugfix', 'Finished'));
    my $child  = mk_task($parent, '1.1', 'chore', 'child',
                         { 'a-task-plan.md' => 'Finished' });

    is(state_done($child), 0, 'state_done sees no v2.0 files at all');

    my @blocked = nonterminal_children('1', $base);
    is(scalar @blocked, 1, 'the gate blocks it');
    is_deeply([sort map { $_->[0] } @{ $blocked[0]{blocking_phases} }],
              [qw(a-plan.md d-implementation.md e-testing.md h-retrospective.md)],
              'and names the v2.0 file set it was measured against');
};

subtest 'TC-12: only the non-terminal sibling is reported' => sub {
    my ($root, $base) = new_base();
    my $parent = mk_task($base, '1', 'bugfix', 'parent', all_at('bugfix', 'Finished'));
    mk_task($parent, '1.1', 'chore', 'done', all_at('chore', 'Finished'));
    mk_task($parent, '1.2', 'chore', 'open', all_at('chore', 'In Progress'));

    my @blocked = nonterminal_children('1', $base);
    is(scalar @blocked, 1, 'one child blocks');
    is($blocked[0]{num}, '1.2', 'and it is the open one');
};

#==============================================================================
# Contract and plumbing
#==============================================================================

subtest 'TC-13: $base_dir is honoured, not find_base_dir()' => sub {
    # Runs from inside the real CWF repo, where task 225 exists with no children.
    # If $base_dir failed to reach resolve() or find_children(), the fixture's
    # open child would be invisible and this would wrongly report permitted.
    my ($root, $base) = new_base();
    my $parent = mk_task($base, '225', 'bugfix', 'fixture', all_at('bugfix', 'Finished'));
    mk_task($parent, '225.1', 'chore', 'open-child', all_at('chore', 'In Progress'));

    is(getcwd(), $ORIG_CWD, 'still inside the real repository');
    is(scalar nonterminal_children('225', $ORIG_CWD . '/implementation-guide'), 0,
       'the real task 225 has no children');
    is(scalar nonterminal_children('225', $base), 1,
       'the fixture task 225 has an open child');
};

subtest 'TC-14: an unresolvable task dies (fail closed)' => sub {
    my ($root, $base) = new_base();
    my @blocked = eval { nonterminal_children('99999', $base) };
    ok($@, 'dies rather than returning the empty list');
    like($@, qr/cannot resolve task/, 'and says why');
};

subtest 'TC-15: format_blocked clamps status text' => sub {
    my ($root, $base) = new_base();
    my $parent = mk_task($base, '1', 'bugfix', 'parent', all_at('bugfix', 'Finished'));

    my %statuses = %{ all_at('chore', 'Finished') };
    $statuses{'g-testing-exec.md'} = "A\tB" . ('X' x 200);
    mk_task($parent, '1.1', 'chore', 'child', \%statuses);

    my @blocked = nonterminal_children('1', $base);
    my $msg = format_blocked('1', 'f', \@blocked);

    unlike($msg, qr/\t/, 'no tab survives into the message');
    unlike($msg, qr/X{33}/, 'the status is truncated to 32 characters');
    like($msg, qr/BLOCKED: task 1 cannot enter phase f/, 'names the task and phase');
    like($msg, qr/Finished, Skipped, or Cancelled/, 'states the remedy');
};

subtest 'TC-15b: format_blocked pluralises' => sub {
    my ($root, $base) = new_base();
    my $parent = mk_task($base, '1', 'bugfix', 'parent', all_at('bugfix', 'Finished'));
    mk_task($parent, '1.1', 'chore', 'one', all_at('chore', 'In Progress'));

    my @one = nonterminal_children('1', $base);
    like(format_blocked('1', 'f', \@one), qr/1 subtask not in/, 'singular');

    mk_task($parent, '1.2', 'chore', 'two', all_at('chore', 'To-Do'));
    my @two = nonterminal_children('1', $base);
    like(format_blocked('1', 'f', \@two), qr/2 subtasks not in/, 'plural');
};

#==============================================================================
# CLI exit codes
#==============================================================================

# Run a command without a shell, capturing stdout, stderr and the exit code.
sub run_cmd {
    my (@argv) = @_;

    my $out_file = File::Temp->new;
    my $err_file = File::Temp->new;

    open my $save_out, '>&', \*STDOUT or die "dup stdout: $!";
    open my $save_err, '>&', \*STDERR or die "dup stderr: $!";
    open STDOUT, '>', $out_file->filename or die "redirect stdout: $!";
    open STDERR, '>', $err_file->filename or die "redirect stderr: $!";

    my $rc = system(@argv);

    open STDOUT, '>&', $save_out or die "restore stdout: $!";
    open STDERR, '>&', $save_err or die "restore stderr: $!";

    my $slurp = sub {
        open my $fh, '<', shift or return '';
        local $/;
        return <$fh> // '';
    };

    return ($rc >> 8, $slurp->($out_file->filename), $slurp->($err_file->filename));
}

sub run_gate { return run_cmd($WORKFLOW_MANAGER, 'gate', @_) }

subtest 'CLI exit codes' => sub {
    my ($root, $base) = new_base();
    my $parent = mk_task($base, '1', 'bugfix', 'clean', all_at('bugfix', 'Finished'));
    mk_task($parent, '1.1', 'chore', 'done', all_at('chore', 'Finished'));

    my $blocked_parent = mk_task($base, '2', 'bugfix', 'dirty', all_at('bugfix', 'Finished'));
    mk_task($blocked_parent, '2.1', 'chore', 'open', all_at('chore', 'In Progress'));

    # find_base_dir() falls back to ./implementation-guide only outside a git repo.
    chdir $root or die "chdir $root: $!";

    subtest 'TC-16/22: permitted is exit 0 and silent' => sub {
        my ($rc, $out, $err) = run_gate('--task-path=1', '--phase=j');
        is($rc, 0, 'exit 0');
        is($out, '', 'silent on stdout');
        is($err, '', 'silent on stderr');
    };

    subtest 'TC-17: blocked is exit 3, with the remedy on stderr' => sub {
        my ($rc, $out, $err) = run_gate('--task-path=2', '--phase=f');
        is($rc, 3, 'exit 3');
        like($err, qr/\[CWF\] BLOCKED/, 'stderr carries the marker');
        like($err, qr/\b2\.1\b/, 'names the offending child');
        like($err, qr/Finished, Skipped, or Cancelled/, 'names the terminal statuses');
    };

    subtest 'TC-7b: an ungated phase permits despite an open child' => sub {
        my ($rc) = run_gate('--task-path=2', '--phase=a');
        is($rc, 0, 'phase a exits 0 with an open child');
    };

    subtest 'TC-18: an unknown phase is exit 1, never a silent exit 0' => sub {
        for my $phase (qw(Z 1 aa)) {
            my ($rc) = run_gate('--task-path=2', "--phase=$phase");
            is($rc, 1, "--phase=$phase exits 1");
        }
        my ($rc_empty) = run_gate('--task-path=2', '--phase=');
        is($rc_empty, 1, '--phase= (empty) exits 1');

        my ($rc_missing) = run_gate('--task-path=2');
        is($rc_missing, 1, 'a missing --phase exits 1');
    };

    subtest 'TC-19: a malformed task path is exit 1, and never reaches a shell' => sub {
        for my $path ('1; rm -rf /', 'abc', '../../etc') {
            my ($rc) = run_gate("--task-path=$path", '--phase=f');
            is($rc, 1, "--task-path='$path' exits 1");
        }
        ok(-d $base, 'the fixture tree survived');
    };

    subtest 'TC-20: a missing task is exit 2, distinct from 1 and 3' => sub {
        my ($rc, $out, $err) = run_gate('--task-path=99999', '--phase=f');
        is($rc, 2, 'exit 2');
        like($err, qr/cannot resolve task/, 'and says why');
    };

    subtest 'TC-24: a Unicode digit is not a task path (regression: \d without /a)' => sub {
        # Without /a, \d matches Unicode digits, so this reaches resolve() and
        # reports "task not found" (2) rather than "invalid argument" (1).
        my ($rc) = run_gate("--task-path=\x{0662}\x{0662}\x{0665}", '--phase=f');
        is($rc, 1, 'Arabic-Indic digits are rejected as malformed, not merely unresolvable');
    };

    chdir $ORIG_CWD or die "chdir back: $!";
};

subtest 'TC-25: a trailing newline cannot disable the gate' => sub {
    # `$` matches before a trailing newline, so /^[a-j]$/ accepts "f\n" — which
    # phase_is_gated (an exact hash lookup) then reports ungated. The validators
    # anchor with \A..\z so the letter never reaches the gate in that shape.
    ok(!phase_is_gated("f\n"), 'phase_is_gated rejects "f\\n" (it is not the letter f)');

    ok("f\n" =~ /^[a-j]$/,   'the ^..$ anchors would have admitted it');
    ok("f\n" !~ /\A[a-j]\z/, 'the \\A..\\z anchors do not');

    # cwf-checkpoint-commit reads $letter straight from @ARGV, so this is the
    # reachable path: it must reject the letter, not skip the gate and then fail
    # later on the glob. (CWF::Options::parse strips the newline before the gate
    # CLI ever sees it, so the CLI was never exposed.)
    my $ccc = "$FindBin::Bin/../.cwf/scripts/command-helpers/cwf-checkpoint-commit";
    my ($rc, $out, $err) = run_cmd($ccc, '225', "f\n", 'probe');
    is($rc, 1, 'cwf-checkpoint-commit exits 1');
    like($err, qr/invalid phase letter/, 'rejecting the letter, not falling through to the glob');
};

subtest 'TC-21: the dispatcher registers the subcommand' => sub {
    my $usage = `$WORKFLOW_MANAGER 2>&1`;
    like($usage, qr/\{status\|control\|gate\}/, 'usage names gate');

    my ($rc, $out, $err) = run_gate('--task-path=225', '--phase=a');
    unlike($err, qr/Unknown subcommand/, 'gate dispatches');
    is($rc, 0, 'and runs');
};

done_testing();
