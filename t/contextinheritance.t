#!/usr/bin/env perl
#
# contextinheritance.t - Unit tests for CWF::ContextInheritance::Core
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

use_ok('CWF::ContextInheritance::Core');

my $tmp = tempdir(CLEANUP => 1);

sub write_md {
    my ($name, $content) = @_;
    my $path = "$tmp/$name";
    open my $fh, '>', $path or die $!;
    print $fh $content;
    close $fh;
    return $path;
}

my $sample_md = write_md('sample.md', <<'MD');
# Top Heading

## Section One
Content here.

### Subsection 1.1
More content.

## Section Two
Other content.
MD

#==============================================================================
# count_lines()
#==============================================================================

subtest 'count_lines() - counts lines correctly' => sub {
    plan tests => 2;

    my $count = CWF::ContextInheritance::Core::count_lines($sample_md);
    is($count, 10, 'counts all 10 lines in sample.md');

    is(CWF::ContextInheritance::Core::count_lines('/nonexistent'), 0, 'missing file returns 0');
};

#==============================================================================
# extract_headers()
#==============================================================================

subtest 'extract_headers() - extracts all headers with levels and lines' => sub {
    plan tests => 4;

    my @headers = CWF::ContextInheritance::Core::extract_headers($sample_md);
    is(scalar @headers, 4, 'finds 4 headers');
    is($headers[0]{level}, 1, 'first header level = 1');
    is($headers[0]{title}, 'Top Heading', 'first header title correct');
    ok($headers[0]{line} >= 1, 'first header has a line number');
};

subtest 'extract_headers() - missing file returns empty list' => sub {
    plan tests => 1;

    my @headers = CWF::ContextInheritance::Core::extract_headers('/nonexistent');
    is(scalar @headers, 0, 'missing file returns empty list');
};

subtest 'extract_headers() - detects h2 and h3 correctly' => sub {
    plan tests => 2;

    my @headers = CWF::ContextInheritance::Core::extract_headers($sample_md);
    my @h2 = grep { $_->{level} == 2 } @headers;
    my @h3 = grep { $_->{level} == 3 } @headers;
    is(scalar @h2, 2, 'finds 2 h2 headers');
    is(scalar @h3, 1, 'finds 1 h3 header');
};

#==============================================================================
# calculate_boundaries()
#==============================================================================

subtest 'calculate_boundaries() - sections have start and end' => sub {
    plan tests => 3;

    my @headers = CWF::ContextInheritance::Core::extract_headers($sample_md);
    my $total   = CWF::ContextInheritance::Core::count_lines($sample_md);
    my @sections = CWF::ContextInheritance::Core::calculate_boundaries(\@headers, $total);

    is(scalar @sections, scalar @headers, 'one section per header');
    ok(defined $sections[0]{start}, 'first section has start');
    ok(defined $sections[0]{end},   'first section has end');
};

subtest 'calculate_boundaries() - last section ends at total_lines' => sub {
    plan tests => 1;

    my @headers  = CWF::ContextInheritance::Core::extract_headers($sample_md);
    my $total    = CWF::ContextInheritance::Core::count_lines($sample_md);
    my @sections = CWF::ContextInheritance::Core::calculate_boundaries(\@headers, $total);
    is($sections[-1]{end}, $total, 'last section ends at total line count');
};

#==============================================================================
# generate_context()
#==============================================================================

subtest 'generate_context() - returns parent data with files' => sub {
    plan tests => 3;

    my $task_dir = "$tmp/1-feature-parent";
    require File::Path;
    File::Path::make_path($task_dir);

    # Write a workflow file
    open my $fh, '>', "$task_dir/a-plan.md" or die $!;
    print $fh "# Plan\n\n## Status\n**Status**: Finished\n";
    close $fh;

    my $mappings = CWF::WorkflowFiles::workflow_file_mappings()
        if eval { require CWF::WorkflowFiles; CWF::WorkflowFiles->import('workflow_file_mappings'); 1 };
    $mappings //= [{ old => 'a-plan.md', new => 'a-task-plan.md' }];

    my @parent_tasks = ({ num => '1', dir => $task_dir });
    my @ctx = CWF::ContextInheritance::Core::generate_context(\@parent_tasks, $mappings);

    ok(@ctx == 1, 'returns one parent data entry');
    ok(defined $ctx[0]{files}, 'parent data has files key');
    ok(@{$ctx[0]{files}} >= 0, 'files is an arrayref');
};

done_testing();
