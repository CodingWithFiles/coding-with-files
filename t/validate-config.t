#!/usr/bin/env perl
#
# validate-config.t - Unit tests for CWF::Validate::Config
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('CWF::Validate::Config', qw(validate validate_config_hash)) }

#==============================================================================
# validate_config_hash()
#==============================================================================

subtest 'validate_config_hash() - valid config returns no violations' => sub {
    plan tests => 1;

    my $config = {
        'supported-task-types' => ['feature', 'bugfix', 'hotfix', 'chore', 'discovery'],
        'source-management' => {
            'branch-naming-convention' => '{task-type}/{task-id}-{description-slug}',
        },
    };
    my @v = validate_config_hash($config, '/fake/cwf-project.json');
    is(scalar @v, 0, 'valid config → no violations');
};

subtest 'validate_config_hash() - missing supported-task-types' => sub {
    plan tests => 2;

    my $config = { 'source-management' => { 'branch-naming-convention' => 'x' } };
    my @v = validate_config_hash($config, '/fake/cwf-project.json');
    ok(@v > 0, 'returns violation');
    ok((grep { $_->{field} eq 'supported-task-types' } @v), 'violation on supported-task-types');
};

subtest 'validate_config_hash() - missing source-management' => sub {
    plan tests => 1;

    my $config = { 'supported-task-types' => ['feature', 'bugfix', 'hotfix', 'chore', 'discovery'] };
    my @v = validate_config_hash($config, '/fake/cwf-project.json');
    ok((grep { $_->{field} eq 'source-management' } @v), 'violation on source-management');
};

subtest 'validate_config_hash() - empty branch-naming-convention' => sub {
    plan tests => 1;

    my $config = {
        'supported-task-types' => ['feature', 'bugfix', 'hotfix', 'chore', 'discovery'],
        'source-management' => { 'branch-naming-convention' => '' },
    };
    my @v = validate_config_hash($config, '/fake/cwf-project.json');
    ok((grep { $_->{field} =~ /branch-naming/ } @v), 'violation on branch-naming-convention');
};

subtest 'validate_config_hash() - violation has required keys' => sub {
    plan tests => 1;

    my $config = {};
    my @v = validate_config_hash($config, '/fake/cwf-project.json');
    my $viol = $v[0];
    ok(
        exists $viol->{file} && exists $viol->{field} &&
        exists $viol->{actual} && exists $viol->{expected} && exists $viol->{fix},
        'violation hashref has all required keys',
    );
};

subtest 'validate_config_hash() - non-array supported-task-types' => sub {
    plan tests => 1;

    my $config = {
        'supported-task-types' => 'feature',
        'source-management' => { 'branch-naming-convention' => 'x' },
    };
    my @v = validate_config_hash($config, '/fake/cwf-project.json');
    ok((grep { $_->{field} eq 'supported-task-types' } @v), 'scalar value triggers violation');
};

#==============================================================================
# validate()
#==============================================================================

subtest 'validate() - missing config file returns no violations' => sub {
    plan tests => 1;

    my $tmp = tempdir(CLEANUP => 1);
    my @v = validate($tmp);
    is(scalar @v, 0, 'missing file is not an error (pre-init state)');
};

subtest 'validate() - valid config file returns no violations' => sub {
    plan tests => 1;

    my $tmp = tempdir(CLEANUP => 1);
    require File::Path;
    File::Path::make_path("$tmp/implementation-guide");
    open my $fh, '>', "$tmp/implementation-guide/cwf-project.json" or die $!;
    print $fh '{"supported-task-types":["feature","bugfix","hotfix","chore","discovery"],"source-management":{"branch-naming-convention":"x"}}';
    close $fh;

    my @v = validate($tmp);
    is(scalar @v, 0, 'valid config → no violations');
};

subtest 'validate_config_hash() - unknown task type is a violation' => sub {
    plan tests => 2;

    my $config = {
        'supported-task-types' => ['feature', 'bugfix', 'hotfix', 'chore', 'discovery', 'docs'],
        'source-management' => { 'branch-naming-convention' => 'x' },
    };
    my @v = validate_config_hash($config, '/fake/cwf-project.json');
    ok(@v > 0, 'returns violation');
    ok((grep { $_->{actual} =~ /unknown.*docs/ } @v), 'violation mentions docs as unknown');
};

subtest 'validate_config_hash() - missing canonical type is a violation' => sub {
    plan tests => 2;

    my $config = {
        'supported-task-types' => ['feature', 'bugfix', 'hotfix', 'chore'],
        'source-management' => { 'branch-naming-convention' => 'x' },
    };
    my @v = validate_config_hash($config, '/fake/cwf-project.json');
    ok(@v > 0, 'returns violation');
    ok((grep { $_->{actual} =~ /missing.*discovery/ } @v), 'violation mentions missing discovery');
};

done_testing();
