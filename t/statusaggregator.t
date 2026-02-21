#!/usr/bin/env perl
#
# statusaggregator.t - Unit tests for CWF::StatusAggregator::Core
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

use_ok('CWF::StatusAggregator::Core');

my $tmp = tempdir(CLEANUP => 1);
my $idx = 0;

sub make_workflow_file {
    my ($status) = @_;
    my $name = "wf-" . $idx++ . ".md";
    my $path = "$tmp/$name";
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh "# Doc\n\n## Status\n**Status**: $status\n";
    close $fh;
    return { name => $name, path => $path };
}

#==============================================================================
# aggregate()
#==============================================================================

subtest 'aggregate() - all Finished returns 100' => sub {
    plan tests => 1;

    my @files = map { make_workflow_file('Finished') } 1..3;
    my $pct = CWF::StatusAggregator::Core::aggregate($tmp, \@files);
    is($pct, 100, 'all Finished → 100%');
};

subtest 'aggregate() - all Backlog returns 0' => sub {
    plan tests => 1;

    my @files = map { make_workflow_file('Backlog') } 1..3;
    my $pct = CWF::StatusAggregator::Core::aggregate($tmp, \@files);
    is($pct, 0, 'all Backlog → 0%');
};

subtest 'aggregate() - one Testing + one Backlog returns base 25' => sub {
    plan tests => 1;

    # max=75 >= 25 → base=25, min=0 < 25 → result=25
    my @files = (make_workflow_file('Testing'), make_workflow_file('Backlog'));
    my $pct = CWF::StatusAggregator::Core::aggregate($tmp, \@files);
    is($pct, 25, 'one Testing + one Backlog → 25%');
};

subtest 'aggregate() - empty file list returns 0' => sub {
    plan tests => 1;

    my $pct = CWF::StatusAggregator::Core::aggregate($tmp, []);
    is($pct, 0, 'empty list → 0');
};

subtest 'aggregate() - undef file list returns 0' => sub {
    plan tests => 1;

    my $pct = CWF::StatusAggregator::Core::aggregate($tmp, undef);
    is($pct, 0, 'undef → 0');
};

#==============================================================================
# get_workflow_status()
#==============================================================================

subtest 'get_workflow_status() - returns arrayref of status hashes' => sub {
    plan tests => 3;

    my $file = make_workflow_file('Testing');
    my $result = CWF::StatusAggregator::Core::get_workflow_status($tmp, [$file]);

    ok(ref($result) eq 'ARRAY', 'returns arrayref');
    is(scalar @$result, 1, 'one entry per file');
    is($result->[0]{status}, 'Testing', 'status extracted correctly');
};

subtest 'get_workflow_status() - percent field populated' => sub {
    plan tests => 1;

    my $file = make_workflow_file('Finished');
    my $result = CWF::StatusAggregator::Core::get_workflow_status($tmp, [$file]);
    is($result->[0]{percent}, 100, 'Finished = 100%');
};

subtest 'get_workflow_status() - has name and path keys' => sub {
    plan tests => 2;

    my $file = make_workflow_file('Backlog');
    my $result = CWF::StatusAggregator::Core::get_workflow_status($tmp, [$file]);
    ok(defined $result->[0]{name}, 'name key present');
    ok(defined $result->[0]{path}, 'path key present');
};

done_testing();
