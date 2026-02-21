#!/usr/bin/env perl
#
# versionrouter.t - Unit tests for CWF::VersionRouter
#
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('CWF::VersionRouter', qw(detect_version get_script_dir)) }

#==============================================================================
# detect_version()
#==============================================================================

subtest 'detect_version() - empty string returns v2.0' => sub {
    plan tests => 1;

    my $v = detect_version('');
    is($v, 'v2.0', 'empty arg → v2.0');
};

subtest 'detect_version() - undef returns v2.0' => sub {
    plan tests => 1;

    my $v = detect_version(undef);
    is($v, 'v2.0', 'undef → v2.0');
};

subtest 'detect_version() - non-task string returns v2.0' => sub {
    plan tests => 1;

    my $v = detect_version('not-a-task-number');
    is($v, 'v2.0', 'non-task string → v2.0');
};

#==============================================================================
# get_script_dir()
#==============================================================================

subtest 'get_script_dir() - returns a non-empty string' => sub {
    plan tests => 1;

    my $dir = get_script_dir();
    ok(defined $dir && length($dir) > 0, 'get_script_dir returns non-empty string');
};

done_testing();
