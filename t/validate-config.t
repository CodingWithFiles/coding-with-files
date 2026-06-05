#!/usr/bin/env perl
#
# validate-config.t - Unit tests for CWF::Validate::Config
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use JSON::PP;
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('CWF::Validate::Config', qw(validate validate_config_hash)) }

# Base valid config — used as a starting point for the new schema-extension tests
sub base_cfg {
    return {
        'supported-task-types' => ['feature', 'bugfix', 'hotfix', 'chore', 'discovery'],
        'source-management' => {
            'branch-naming-convention' => '{task-type}/{task-id}-{description-slug}',
        },
    };
}

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

#==============================================================================
# Schema extension: versioning and wf_step_config (TC-X1..X8)
#==============================================================================

subtest 'TC-X1 both new blocks absent → no violations (back-compat)' => sub {
    plan tests => 1;
    my @v = validate_config_hash(base_cfg(), '/fake/cwf-project.json');
    is(scalar @v, 0, 'absent versioning + wf_step_config still valid');
};

subtest 'TC-X2 versioning.major_minor valid → no violations' => sub {
    plan tests => 2;
    for my $val (qw(v1.0 v2.5)) {
        my $cfg = base_cfg();
        $cfg->{versioning} = { major_minor => $val };
        my @v = validate_config_hash($cfg, '/fake/cwf-project.json');
        is(scalar @v, 0, "$val accepted");
    }
};

subtest 'TC-X3 versioning.major_minor malformed → violation' => sub {
    plan tests => 4;
    for my $val ('1.0', 'v1', 'v1.0.0', '') {
        my $cfg = base_cfg();
        $cfg->{versioning} = { major_minor => $val };
        my @v = validate_config_hash($cfg, '/fake/cwf-project.json');
        ok((grep { $_->{field} eq 'versioning.major_minor' } @v),
           qq{"$val" produces violation});
    }
};

subtest 'TC-X4 versioning.last_released valid vs malformed' => sub {
    plan tests => 3;
    my $cfg = base_cfg();
    $cfg->{versioning} = { major_minor => 'v1.0', last_released => 'v1.0.113' };
    my @v = validate_config_hash($cfg, '/fake/cwf-project.json');
    is(scalar @v, 0, 'v1.0.113 accepted');

    $cfg->{versioning}{last_released} = '1.0.113';
    @v = validate_config_hash($cfg, '/fake/cwf-project.json');
    ok((grep { $_->{field} eq 'versioning.last_released' } @v), '1.0.113 (no v) → violation');

    $cfg->{versioning}{last_released} = 'v1.0';
    @v = validate_config_hash($cfg, '/fake/cwf-project.json');
    ok((grep { $_->{field} eq 'versioning.last_released' } @v), 'v1.0 (no patch) → violation');
};

subtest 'TC-X5 wf_step_config not an object → violation' => sub {
    plan tests => 1;
    my $cfg = base_cfg();
    $cfg->{wf_step_config} = 'not-an-object';
    my @v = validate_config_hash($cfg, '/fake/cwf-project.json');
    ok((grep { $_->{field} eq 'wf_step_config' } @v), 'violation on wf_step_config');
};

subtest 'TC-X6 wf_step_config.<step> not an object → violation' => sub {
    plan tests => 1;
    my $cfg = base_cfg();
    $cfg->{wf_step_config} = { retrospective => 'not-an-object' };
    my @v = validate_config_hash($cfg, '/fake/cwf-project.json');
    ok((grep { $_->{field} eq 'wf_step_config.retrospective' } @v),
       'violation on wf_step_config.retrospective');
};

subtest 'TC-X7 wf_step_config.<step>.<key> non-boolean → violation' => sub {
    plan tests => 2;
    my $cfg = base_cfg();
    $cfg->{wf_step_config} = { retrospective => { bump_version => 'true' } };  # string
    my @v = validate_config_hash($cfg, '/fake/cwf-project.json');
    ok((grep { $_->{field} eq 'wf_step_config.retrospective.bump_version' } @v),
       'string "true" → violation (must be JSON boolean)');

    $cfg->{wf_step_config} = { retrospective => { bump_version => 2 } };
    @v = validate_config_hash($cfg, '/fake/cwf-project.json');
    ok((grep { $_->{field} eq 'wf_step_config.retrospective.bump_version' } @v),
       'integer 2 → violation (only 0/1 accepted)');
};

subtest 'TC-X8 full valid config (CwF actual settings) → no violations' => sub {
    plan tests => 1;
    my $cfg = base_cfg();
    $cfg->{versioning} = {
        major_minor   => 'v1.0',
        last_released => 'v1.0.113',
    };
    $cfg->{wf_step_config} = {
        retrospective => {
            bump_version => JSON::PP::true,
            tag_version  => JSON::PP::false,
        },
    };
    my @v = validate_config_hash($cfg, '/fake/cwf-project.json');
    is(scalar @v, 0, 'CwF-style config validates clean');
};

#==============================================================================
# Schema extension: sandbox block (Task 179, TC-3 / FR1-AC1e)
#==============================================================================

subtest 'TC-S1 sandbox block absent → no violations (back-compat)' => sub {
    plan tests => 1;
    my @v = validate_config_hash(base_cfg(), '/fake/cwf-project.json');
    is(scalar @v, 0, 'absent sandbox block still valid');
};

subtest 'TC-S2 sandbox switches non-boolean → violation' => sub {
    plan tests => 3;
    for my $k (qw(enabled fail-if-unavailable violation-logging)) {
        my $cfg = base_cfg();
        $cfg->{sandbox} = { $k => 'true' };   # string, not JSON bool
        my @v = validate_config_hash($cfg, '/fake/cwf-project.json');
        ok((grep { $_->{field} eq "sandbox.$k" } @v),
           "non-bool sandbox.$k → violation");
    }
};

subtest 'TC-S3 credential-deny-list not an array → violation' => sub {
    plan tests => 1;
    my $cfg = base_cfg();
    $cfg->{sandbox} = { 'credential-deny-list' => '~/.ssh' };  # scalar
    my @v = validate_config_hash($cfg, '/fake/cwf-project.json');
    ok((grep { $_->{field} eq 'sandbox.credential-deny-list' } @v),
       'scalar credential-deny-list → violation');
};

subtest 'TC-S4 credential-deny-list non-string entry → violation' => sub {
    plan tests => 1;
    my $cfg = base_cfg();
    $cfg->{sandbox} = { 'credential-deny-list' => ['~/.ssh', { x => 1 }] };
    my @v = validate_config_hash($cfg, '/fake/cwf-project.json');
    ok((grep { $_->{field} eq 'sandbox.credential-deny-list[1]' } @v),
       'non-string entry → indexed violation');
};

subtest 'TC-S5 enabled:true + absent credential-deny-list → no violation' => sub {
    plan tests => 1;
    my $cfg = base_cfg();
    $cfg->{sandbox} = { enabled => JSON::PP::true };
    my @v = validate_config_hash($cfg, '/fake/cwf-project.json');
    is(scalar @v, 0, 'enabled with no list is valid (empty deny set)');
};

subtest 'TC-S6 sandbox not an object → violation' => sub {
    plan tests => 1;
    my $cfg = base_cfg();
    $cfg->{sandbox} = 'on';
    my @v = validate_config_hash($cfg, '/fake/cwf-project.json');
    ok((grep { $_->{field} eq 'sandbox' } @v), 'scalar sandbox → violation');
};

subtest 'TC-S7 full valid sandbox block → no violations' => sub {
    plan tests => 1;
    my $cfg = base_cfg();
    $cfg->{sandbox} = {
        enabled                => JSON::PP::false,
        'fail-if-unavailable'  => JSON::PP::true,
        'credential-deny-list' => ['~/.ssh', '~/.aws'],
        'violation-logging'    => JSON::PP::false,
    };
    my @v = validate_config_hash($cfg, '/fake/cwf-project.json');
    is(scalar @v, 0, 'well-formed sandbox block validates clean');
};

done_testing();
