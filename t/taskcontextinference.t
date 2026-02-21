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

use_ok('CWF::TaskContextInference', qw(correlate_signals format_output get_all_signals));

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

done_testing();
