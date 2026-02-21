#!/usr/bin/env perl
#
# workflowfiles.t - Unit tests for CWF::WorkflowFiles
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

use CWFTest::Fixtures qw(create_task_dir);

BEGIN { use_ok('CWF::WorkflowFiles', qw(list get_template_version status_to_percent load_config workflow_file_mappings)) }

#==============================================================================
# workflow_file_mappings()
#==============================================================================

subtest 'workflow_file_mappings() - returns arrayref of mappings' => sub {
    plan tests => 2;

    my $mappings = workflow_file_mappings();
    ok(ref($mappings) eq 'ARRAY', 'returns arrayref');
    ok(@$mappings > 0, 'mappings array is non-empty');
};

subtest 'workflow_file_mappings() - each entry has old and new keys' => sub {
    plan tests => 1;

    my $mappings = workflow_file_mappings();
    my $all_have_keys = 1;
    for my $m (@$mappings) {
        $all_have_keys = 0 unless exists $m->{old} && exists $m->{new};
    }
    ok($all_have_keys, 'every mapping has old and new keys');
};

#==============================================================================
# status_to_percent()
#==============================================================================

subtest 'status_to_percent() - known statuses' => sub {
    plan tests => 4;

    is(status_to_percent('Finished'),    100, 'Finished = 100');
    is(status_to_percent('Testing'),      75, 'Testing = 75');
    is(status_to_percent('In Progress'),  25, 'In Progress = 25');
    is(status_to_percent('Backlog'),       0, 'Backlog = 0');
};

subtest 'status_to_percent() - unknown status returns 0' => sub {
    plan tests => 1;

    is(status_to_percent('GibberishStatus'), 0, 'unknown status = 0');
};

#==============================================================================
# get_template_version()
#==============================================================================

subtest 'get_template_version() - detects version from Template Version field' => sub {
    plan tests => 1;

    my $tmp = tempdir(CLEANUP => 1);
    my $f = "$tmp/a-task-plan.md";
    open my $fh, '>', $f or die $!;
    print $fh "# Test\n\n## Task Reference\n- **Template Version**: 2.1\n\n## Status\n**Status**: Backlog\n";
    close $fh;

    is(get_template_version($f), '2.1', 'extracts version 2.1 from header');
};

subtest 'get_template_version() - defaults to 1.0 for missing marker' => sub {
    plan tests => 1;

    my $tmp = tempdir(CLEANUP => 1);
    my $f = "$tmp/plan.md";
    open my $fh, '>', $f or die $!;
    print $fh "# Old Plan\n\n## Status\n**Status**: Backlog\n";
    close $fh;

    is(get_template_version($f), '1.0', 'defaults to 1.0 when no Template Version');
};

subtest 'get_template_version() - missing file defaults to 1.0' => sub {
    plan tests => 1;

    is(get_template_version('/nonexistent.md'), '1.0', 'missing file defaults to 1.0');
};

#==============================================================================
# list()
#==============================================================================

subtest 'list() - returns existing v2.0 files' => sub {
    plan tests => 2;

    my $tmp = tempdir(CLEANUP => 1);
    my $dir = "$tmp/1-feature-test";
    make_path($dir);
    open my $fh, '>', "$dir/a-plan.md" or die $!;
    print $fh "# Plan\n";
    close $fh;

    my $files = list($dir);
    ok(ref($files) eq 'ARRAY', 'returns arrayref');
    ok((grep { $_->{name} eq 'a-plan.md' } @$files), 'finds a-plan.md');
};

subtest 'list() - empty directory returns empty list' => sub {
    plan tests => 1;

    my $tmp = tempdir(CLEANUP => 1);
    my $files = list($tmp);
    is(scalar @$files, 0, 'empty dir returns empty list');
};

done_testing();
