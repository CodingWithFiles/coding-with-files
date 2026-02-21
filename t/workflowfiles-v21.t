#!/usr/bin/env perl
#
# workflowfiles-v21.t - Unit tests for CWF::WorkflowFiles::V21
#
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

use_ok('CWF::WorkflowFiles::V21');

subtest 'get_workflow_files() - feature task type' => sub {
    plan tests => 2;

    my $files = CWF::WorkflowFiles::V21::get_workflow_files('feature');
    ok(ref($files) eq 'ARRAY', 'returns arrayref');
    ok(grep { $_ eq 'a-task-plan.md' } @$files, 'feature includes a-task-plan.md');
};

subtest 'get_workflow_files() - v2.1 uses new file names' => sub {
    plan tests => 3;

    my $files = CWF::WorkflowFiles::V21::get_workflow_files('feature');
    ok(grep { $_ eq 'a-task-plan.md' }        @$files, 'has a-task-plan.md');
    ok(grep { $_ eq 'f-implementation-exec.md' } @$files, 'has f-implementation-exec.md');
    ok(!grep { $_ eq 'a-plan.md' }             @$files, 'does not have old a-plan.md');
};

subtest 'get_workflow_files() - v2.1 differs from v2.0' => sub {
    plan tests => 1;

    use CWF::WorkflowFiles::V20;
    my $v20 = CWF::WorkflowFiles::V20::get_workflow_files('feature');
    my $v21 = CWF::WorkflowFiles::V21::get_workflow_files('feature');
    isnt(join(',', @$v20), join(',', @$v21), 'v2.0 and v2.1 feature file lists differ');
};

subtest 'get_workflow_files() - bugfix omits b-requirements-plan.md' => sub {
    plan tests => 1;

    my $files = CWF::WorkflowFiles::V21::get_workflow_files('bugfix');
    ok(!grep { $_ eq 'b-requirements-plan.md' } @$files, 'bugfix has no b-requirements-plan.md');
};

subtest 'get_workflow_files() - all supported task types return non-empty' => sub {
    plan tests => 5;

    for my $type (qw(feature bugfix hotfix chore discovery)) {
        my $files = CWF::WorkflowFiles::V21::get_workflow_files($type);
        ok(@$files > 0, "$type returns non-empty list");
    }
};

subtest 'get_workflow_files() - unknown type falls back to feature' => sub {
    plan tests => 1;

    my $files = CWF::WorkflowFiles::V21::get_workflow_files('nonexistent');
    ok(ref($files) eq 'ARRAY' && @$files > 0, 'unknown type falls back to feature list');
};

subtest 'supported_types() - returns canonical list' => sub {
    plan tests => 3;

    use CWF::WorkflowFiles::V21 qw(supported_types);
    my @types = supported_types();
    ok(@types == 5,                              'returns 5 types');
    ok((grep { $_ eq 'discovery' } @types), 'includes discovery');
    ok((grep { $_ eq 'feature'   } @types), 'includes feature');
};

subtest 'supported_types() - all types have workflow files defined' => sub {
    plan tests => 1;

    use CWF::WorkflowFiles::V21 qw(supported_types);
    my $all_have_files = 1;
    for my $type (supported_types()) {
        my $files = CWF::WorkflowFiles::V21::get_workflow_files($type);
        $all_have_files = 0 unless ref($files) eq 'ARRAY' && @$files > 0;
    }
    ok($all_have_files, 'all types from supported_types() have workflow files defined');
};

done_testing();
