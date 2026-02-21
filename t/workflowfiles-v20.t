#!/usr/bin/env perl
#
# workflowfiles-v20.t - Unit tests for CWF::WorkflowFiles::V20
#
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

use_ok('CWF::WorkflowFiles::V20');

subtest 'get_workflow_files() - feature task type' => sub {
    plan tests => 2;

    my $files = CWF::WorkflowFiles::V20::get_workflow_files('feature');
    ok(ref($files) eq 'ARRAY', 'returns arrayref');
    ok(grep { $_ eq 'a-plan.md' } @$files, 'feature includes a-plan.md');
};

subtest 'get_workflow_files() - bugfix is smaller than feature' => sub {
    plan tests => 2;

    my $feature = CWF::WorkflowFiles::V20::get_workflow_files('feature');
    my $bugfix  = CWF::WorkflowFiles::V20::get_workflow_files('bugfix');
    ok(scalar @$feature > scalar @$bugfix, 'feature has more files than bugfix');
    ok(!grep { $_ eq 'b-requirements.md' } @$bugfix, 'bugfix has no b-requirements.md');
};

subtest 'get_workflow_files() - v2.0 uses old file names' => sub {
    plan tests => 2;

    my $files = CWF::WorkflowFiles::V20::get_workflow_files('feature');
    ok(grep { $_ eq 'a-plan.md' } @$files,       'v2.0 has a-plan.md');
    ok(!grep { $_ eq 'a-task-plan.md' } @$files, 'v2.0 does not have a-task-plan.md');
};

subtest 'get_workflow_files() - unknown type falls back to feature' => sub {
    plan tests => 1;

    my $files = CWF::WorkflowFiles::V20::get_workflow_files('nonexistent');
    ok(ref($files) eq 'ARRAY' && @$files > 0, 'unknown type falls back to feature list');
};

subtest 'get_workflow_files() - all supported task types return non-empty' => sub {
    plan tests => 5;

    for my $type (qw(feature bugfix hotfix chore discovery)) {
        my $files = CWF::WorkflowFiles::V20::get_workflow_files($type);
        ok(@$files > 0, "$type returns non-empty list");
    }
};

done_testing();
