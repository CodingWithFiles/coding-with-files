#!/usr/bin/env perl
#
# common.t - Unit tests for CWF::Common
#
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('CWF::Common', qw(check_perl5opt format_error)) }

#==============================================================================
# check_perl5opt()
#==============================================================================

subtest 'check_perl5opt() - warns when PERL5OPT missing -C' => sub {
    plan tests => 1;

    local $ENV{PERL5OPT} = '';
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    CWF::Common::check_perl5opt();
    ok(@warnings > 0, 'emits warning when PERL5OPT does not contain -C');
};

subtest 'check_perl5opt() - no warning when PERL5OPT contains -C' => sub {
    plan tests => 1;

    local $ENV{PERL5OPT} = '-CDSL';
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    CWF::Common::check_perl5opt();
    is(scalar @warnings, 0, 'no warning when PERL5OPT contains -C');
};

subtest 'check_perl5opt() - warns when PERL5OPT is undef' => sub {
    plan tests => 1;

    local $ENV{PERL5OPT};
    delete $ENV{PERL5OPT};
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    CWF::Common::check_perl5opt();
    ok(@warnings > 0, 'emits warning when PERL5OPT is unset');
};

#==============================================================================
# format_error()
#==============================================================================

subtest 'format_error() - message only' => sub {
    plan tests => 2;

    my $out = format_error('validation', 'Invalid task path');
    like($out, qr/Invalid task path/, 'contains the error message');
    unlike($out, qr/Usage:/, 'no Usage line when usage omitted');
};

subtest 'format_error() - message with usage' => sub {
    plan tests => 2;

    my $out = format_error('validation', 'Missing argument', 'script <task-path>');
    like($out, qr/Missing argument/, 'contains the error message');
    like($out, qr/Usage:.*script <task-path>/s, 'contains the usage string');
};

subtest 'format_error() - type parameter is not in output' => sub {
    plan tests => 1;

    # $type is accepted but not currently surfaced in the formatted string
    my $out = format_error('security', 'Hash mismatch');
    like($out, qr/Hash mismatch/, 'error message appears in output');
};

done_testing();
