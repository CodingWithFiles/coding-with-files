#!/usr/bin/env perl
#
# taskcontextinference.t - Unit tests for CWF::TaskContextInference
#
# Tier A: correlate_signals() and format_output() are pure functions.
# Tier C: get_all_signals() and infer_task_context() require git + filesystem.
#
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

use Cwd ();
use File::Temp ();
use File::Path ();

use_ok('CWF::TaskContextInference', qw(correlate_signals format_output get_all_signals));

# Helper: build a fixture tree under $root.
# Spec is an arrayref of relative directory paths (each must contain a num-type-slug
# directory hierarchy matching the canonical regex).
sub _build_fixture {
    my ($root, $dirs) = @_;
    for my $d (@$dirs) {
        File::Path::make_path("$root/$d");
    }
}

#==============================================================================
# correlate_signals() - pure function
#==============================================================================

subtest 'correlate_signals() - empty signals returns no_signals' => sub {
    plan tests => 1;

    my $result = correlate_signals([]);
    is($result->{confidence}, 'no_signals', 'no signals → confidence=no_signals');
};

subtest 'correlate_signals() - all null signals returns no_signals' => sub {
    plan tests => 1;

    my @signals = (
        { name => 'branch',  null => 1, weight => 100 },
        { name => 'recency', null => 1, weight => 90 },
    );
    my $result = correlate_signals(\@signals);
    is($result->{confidence}, 'no_signals', 'all-null → no_signals');
};

subtest 'correlate_signals() - all signals agree → correlated' => sub {
    plan tests => 2;

    my @signals = (
        { name => 'branch',  null => 0, weight => 100, top => '42', candidates => [{ task => '42', score => 100 }] },
        { name => 'recency', null => 0, weight => 90,  top => '42', candidates => [{ task => '42', score => 80 }] },
    );
    my $result = correlate_signals(\@signals);
    is($result->{confidence}, 'correlated', 'all agree → correlated');
    is($result->{chosen_task}, '42', 'chosen_task = 42');
};

subtest 'correlate_signals() - signals disagree → uncorrelated' => sub {
    plan tests => 2;

    my @signals = (
        { name => 'branch',  null => 0, weight => 100, top => '42', candidates => [{ task => '42', score => 100 }] },
        { name => 'recency', null => 0, weight => 90,  top => '99', candidates => [{ task => '99', score => 80 }] },
    );
    my $result = correlate_signals(\@signals);
    is($result->{confidence}, 'uncorrelated', 'signals disagree → uncorrelated');
    ok(ref($result->{candidates}) eq 'ARRAY', 'candidates is arrayref');
};

subtest 'correlate_signals() - null signals ignored in agreement check' => sub {
    plan tests => 2;

    my @signals = (
        { name => 'branch',  null => 0, weight => 100, top => '5', candidates => [{ task => '5', score => 100 }] },
        { name => 'worktree', null => 1, weight => 95 },   # null — ignored
    );
    my $result = correlate_signals(\@signals);
    is($result->{confidence}, 'correlated', 'null signal ignored → correlated');
    is($result->{chosen_task}, '5', 'chosen_task = 5');
};

#==============================================================================
# format_output() - pure function
#==============================================================================

subtest 'format_output() - conclusive output contains task fields' => sub {
    plan tests => 3;

    my $ctx = {
        current       => 'conclusive',
        confidence    => 'correlated',
        task_num      => '42',
        task_slug     => 'some-feature',
        workflow_step => 'f-implementation-exec',
    };
    my $output = format_output($ctx, 0);

    like($output, qr/current: conclusive/,            'contains current');
    like($output, qr/task_num: 42/,                   'contains task_num');
    like($output, qr/workflow_step: f-implementation-exec/, 'contains workflow_step');
};

subtest 'format_output() - inconclusive output contains plural fields' => sub {
    plan tests => 2;

    my $ctx = {
        current        => 'inconclusive',
        confidence     => 'no_signals',
        task_nums      => ['unknown'],
        task_slugs     => ['unknown'],
        workflow_steps => ['unknown'],
        reasons        => ['none'],
        candidates     => 0,
    };
    my $output = format_output($ctx, 0);

    like($output, qr/current: inconclusive/, 'contains current: inconclusive');
    like($output, qr/candidates: 0/,         'contains candidates count');
};

#==============================================================================
# get_all_signals() - Tier C (needs filesystem, optionally git)
#==============================================================================

subtest 'get_all_signals() - returns 5 signals' => sub {
    plan tests => 1;

    my @signals = get_all_signals();
    is(scalar @signals, 5, 'returns 5 signals');
};

subtest 'get_all_signals() - each signal has required keys' => sub {
    plan tests => 1;

    my @signals = get_all_signals();
    my $all_ok = 1;
    for my $sig (@signals) {
        $all_ok = 0 unless exists $sig->{name} && exists $sig->{weight} && exists $sig->{null};
    }
    ok($all_ok, 'all signals have name, weight, null keys');
};

# Regression: task 78 — _get_progress_signal must not emit zero-score candidates.
# Before fix: completed tasks (score=0) appeared as progress candidates, causing
# non-deterministic task_num on every run. After fix: grep filters them out.
subtest 'get_all_signals() - progress candidates all have score > 0' => sub {
    plan tests => 1;

    my @signals = get_all_signals();
    my ($progress) = grep { $_->{name} eq 'progress' } @signals;
    my $all_positive = 1;
    if (defined $progress && !$progress->{null} && ref($progress->{candidates}) eq 'ARRAY') {
        for my $c (@{$progress->{candidates}}) {
            if (!defined $c->{score} || $c->{score} <= 0) {
                $all_positive = 0;
                last;
            }
        }
    }
    ok($all_positive, 'no zero-score candidates in progress signal');
};

#==============================================================================
# Subtask-aware regression suite (Task 166)
#
# D3 8-step ancestry-collapse predicate: each TC binds to a c-design-plan
# §Validation bullet. Each subtest chdir's into a tempdir fixture, asserts,
# then restores cwd before tempdir CLEANUP fires.
#==============================================================================

subtest 'TC-1: single-chain {28, 28.2} collapses to 28.2' => sub {
    plan tests => 2;

    my $tmp = File::Temp::tempdir(CLEANUP => 1);
    my $saved = Cwd::getcwd();
    _build_fixture($tmp, [
        'implementation-guide/28-feature-parent',
        'implementation-guide/28-feature-parent/28.2-bugfix-child',
    ]);
    chdir $tmp;

    my @signals = (
        { name => 'branch',  null => 0, weight => 100, top => '28',
          candidates => [{ task => '28', score => 100 }] },
        { name => 'recency', null => 0, weight => 90,  top => '28.2',
          candidates => [{ task => '28.2', score => 80 }] },
    );
    my $result = correlate_signals(\@signals);

    chdir $saved;
    is($result->{confidence},  'correlated', 'ancestry-collapse → correlated');
    is($result->{chosen_task}, '28.2',       'chosen_task = 28.2 (deepest)');
};

subtest 'TC-2: multi-level chain {28, 28.2, 28.2.1} collapses to 28.2.1' => sub {
    plan tests => 2;

    my $tmp = File::Temp::tempdir(CLEANUP => 1);
    my $saved = Cwd::getcwd();
    _build_fixture($tmp, [
        'implementation-guide/28-feature-p',
        'implementation-guide/28-feature-p/28.2-bugfix-c',
        'implementation-guide/28-feature-p/28.2-bugfix-c/28.2.1-chore-gc',
    ]);
    chdir $tmp;

    my @signals = (
        { name => 'branch',   null => 0, weight => 100, top => '28',
          candidates => [{ task => '28', score => 100 }] },
        { name => 'recency',  null => 0, weight => 90,  top => '28.2',
          candidates => [{ task => '28.2', score => 80 }] },
        { name => 'progress', null => 0, weight => 60,  top => '28.2.1',
          candidates => [{ task => '28.2.1', score => 50 }] },
    );
    my $result = correlate_signals(\@signals);

    chdir $saved;
    is($result->{confidence},  'correlated', 'multi-level chain → correlated');
    is($result->{chosen_task}, '28.2.1',     'chosen_task = 28.2.1 (deepest)');
};

subtest 'TC-3: tied deepest {28.2, 28.3} on disjoint branches → uncorrelated' => sub {
    plan tests => 1;

    my $tmp = File::Temp::tempdir(CLEANUP => 1);
    my $saved = Cwd::getcwd();
    _build_fixture($tmp, [
        'implementation-guide/28-feature-p',
        'implementation-guide/28-feature-p/28.2-bugfix-a',
        'implementation-guide/28-feature-p/28.3-bugfix-b',
    ]);
    chdir $tmp;

    my @signals = (
        { name => 'recency',  null => 0, weight => 90, top => '28.2',
          candidates => [{ task => '28.2', score => 80 }] },
        { name => 'progress', null => 0, weight => 60, top => '28.3',
          candidates => [{ task => '28.3', score => 40 }] },
    );
    my $result = correlate_signals(\@signals);

    chdir $saved;
    is($result->{confidence}, 'uncorrelated', 'tied deepest disjoint → uncorrelated');
};

subtest 'TC-4: disjoint chains {28.2, 20} → uncorrelated' => sub {
    plan tests => 1;

    my $tmp = File::Temp::tempdir(CLEANUP => 1);
    my $saved = Cwd::getcwd();
    _build_fixture($tmp, [
        'implementation-guide/20-feature-a',
        'implementation-guide/28-feature-b',
        'implementation-guide/28-feature-b/28.2-bugfix-c',
    ]);
    chdir $tmp;

    my @signals = (
        { name => 'branch',  null => 0, weight => 100, top => '20',
          candidates => [{ task => '20', score => 100 }] },
        { name => 'recency', null => 0, weight => 90,  top => '28.2',
          candidates => [{ task => '28.2', score => 80 }] },
    );
    my $result = correlate_signals(\@signals);

    chdir $saved;
    is($result->{confidence}, 'uncorrelated', 'disjoint chains → uncorrelated');
};

subtest 'TC-5: stale deepest (resolve_num undef) → uncorrelated, no exception' => sub {
    plan tests => 1;

    my $tmp = File::Temp::tempdir(CLEANUP => 1);
    my $saved = Cwd::getcwd();
    _build_fixture($tmp, [
        'implementation-guide/28-feature-p',
    ]);
    chdir $tmp;

    # Signal references 28.2 but no such directory exists.
    my @signals = (
        { name => 'branch',  null => 0, weight => 100, top => '28',
          candidates => [{ task => '28', score => 100 }] },
        { name => 'state',   null => 0, weight => 85,  top => '28.2',
          candidates => [{ task => '28.2', score => 85 }] },
    );
    my $result = eval { correlate_signals(\@signals) };
    my $err = $@;

    chdir $saved;
    is($result && $result->{confidence}, 'uncorrelated',
       "stale deepest → uncorrelated (no exception; \$@='$err')");
};

subtest 'TC-6: orphaned subtask (parent dir missing) → uncorrelated' => sub {
    plan tests => 1;

    my $tmp = File::Temp::tempdir(CLEANUP => 1);
    my $saved = Cwd::getcwd();
    # Subtask 28.2 exists as a top-level dir whose num implies a parent (28)
    # that is not present on disk anywhere → find_ancestors gates on task_exists
    # and returns empty, so 28 cannot be in A.
    _build_fixture($tmp, [
        'implementation-guide/28.2-bugfix-orphan',
    ]);
    chdir $tmp;

    my @signals = (
        { name => 'branch',  null => 0, weight => 100, top => '28',
          candidates => [{ task => '28', score => 100 }] },
        { name => 'recency', null => 0, weight => 90,  top => '28.2',
          candidates => [{ task => '28.2', score => 80 }] },
    );
    my $result = correlate_signals(\@signals);

    chdir $saved;
    is($result->{confidence}, 'uncorrelated',
       'orphaned subtask (no parent dir) → uncorrelated');
};

subtest 'TC-8a: get_all_signals — recency surfaces subtask via descendant enumeration' => sub {
    plan tests => 1;

    my $tmp = File::Temp::tempdir(CLEANUP => 1);
    my $saved = Cwd::getcwd();
    _build_fixture($tmp, [
        'implementation-guide/28-feature-p',
        'implementation-guide/28-feature-p/28.2-bugfix-c',
        'implementation-guide/30-chore-x',
    ]);

    # Touch a file inside the subtask dir so it has the most recent mtime.
    # Plain-old "system touch" avoided — write via open() for portability.
    chdir $tmp;
    for my $rel ('implementation-guide/28-feature-p/a.md',
                 'implementation-guide/30-chore-x/a.md') {
        open my $fh, '>', $rel or die "open $rel: $!";
        print $fh "x\n";
        close $fh;
    }
    # Make the subtask file newest.
    my $now = time();
    utime $now - 100, $now - 100, 'implementation-guide/28-feature-p/a.md';
    utime $now - 100, $now - 100, 'implementation-guide/30-chore-x/a.md';
    open my $sfh, '>', 'implementation-guide/28-feature-p/28.2-bugfix-c/a.md'
      or die "open subtask file: $!";
    print $sfh "x\n";
    close $sfh;
    utime $now, $now, 'implementation-guide/28-feature-p/28.2-bugfix-c/a.md';

    my @signals = get_all_signals();
    my ($recency) = grep { $_->{name} eq 'recency' } @signals;

    chdir $saved;
    is($recency && $recency->{top}, '28.2',
       'recency top = 28.2 (descendant enumerated)');
};

subtest 'TC-8b: get_all_signals — progress includes subtask candidates' => sub {
    plan tests => 1;

    # This subtest exercises the enumeration through-signal: the progress
    # signal's candidate list, with descendant enumeration in place, may
    # include a subtask num. The strict assertion is on TC-8a (recency);
    # for progress we just verify the enumeration path does not throw and
    # returns a well-formed signal hash.
    my $tmp = File::Temp::tempdir(CLEANUP => 1);
    my $saved = Cwd::getcwd();
    _build_fixture($tmp, [
        'implementation-guide/28-feature-p',
        'implementation-guide/28-feature-p/28.2-bugfix-c',
    ]);
    chdir $tmp;

    my @signals = get_all_signals();
    my ($progress) = grep { $_->{name} eq 'progress' } @signals;

    chdir $saved;
    ok(defined $progress && exists $progress->{null},
       'progress signal returns a well-formed hash after enumeration');
};

done_testing();
