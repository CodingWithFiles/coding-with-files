#!/usr/bin/env perl
#
# cwf-manage-resolve-source.t — Unit tests for resolve_source.
#
# Loads cwf-manage via do() with @ARGV = ('help') so main() runs harmlessly,
# then overrides main::die_msg so failure paths are catchable via eval{}.
#
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib');

my $SCRIPT = File::Spec->catfile(
    $FindBin::Bin, '..', '.cwf', 'scripts', 'cwf-manage'
);

# Load the script. @ARGV = ('help') keeps main() side-effect-free.
# Silence the help output so prove output stays clean.
{
    local @ARGV = ('help');
    open(my $saved, '>&', \*STDOUT) or die "Cannot dup STDOUT: $!";
    open(STDOUT, '>', File::Spec->devnull()) or die "Cannot silence STDOUT: $!";
    do $SCRIPT;
    open(STDOUT, '>&', $saved) or die "Cannot restore STDOUT: $!";
}
die "Failed to load $SCRIPT: $@" if $@;

# Override die_msg so failure paths are catchable. The original calls exit 1,
# which would terminate the test process before assertions could run.
{
    no warnings 'redefine', 'once';
    *main::die_msg = sub { die "[CWF] ERROR: @_\n" };
}

#==============================================================================
# resolve_source — env > file precedence with defined-and-non-empty checks
#==============================================================================

subtest 'TC-1: env set + file present → env wins' => sub {
    plan tests => 2;
    local $ENV{CWF_SOURCE} = 'file:///env/path';
    my %v = (cwf_source => 'file:///file/path');
    my ($src, $origin) = main::resolve_source(\%v);
    is($src,    'file:///env/path',     'returns env value');
    is($origin, 'CWF_SOURCE env var',   'origin is env');
};

subtest 'TC-2: env unset + file present → file wins' => sub {
    plan tests => 2;
    local %ENV = %ENV;
    delete $ENV{CWF_SOURCE};
    my %v = (cwf_source => 'file:///file/path');
    my ($src, $origin) = main::resolve_source(\%v);
    is($src,    'file:///file/path', 'returns file value');
    is($origin, '.cwf/version',      'origin is file');
};

subtest 'TC-3: env empty + file present → file wins' => sub {
    plan tests => 2;
    local $ENV{CWF_SOURCE} = '';
    my %v = (cwf_source => 'file:///file/path');
    my ($src, $origin) = main::resolve_source(\%v);
    is($src,    'file:///file/path', 'empty env does not override file');
    is($origin, '.cwf/version',      'origin is file');
};

subtest 'TC-4: env set + file missing key → env still wins' => sub {
    plan tests => 2;
    local $ENV{CWF_SOURCE} = 'file:///env/path';
    my %v;
    my ($src, $origin) = main::resolve_source(\%v);
    is($src,    'file:///env/path',     'returns env value');
    is($origin, 'CWF_SOURCE env var',   'origin is env');
};

subtest 'TC-5: env unset + file missing key → dies' => sub {
    plan tests => 1;
    local %ENV = %ENV;
    delete $ENV{CWF_SOURCE};
    my %v;
    eval { main::resolve_source(\%v) };
    like(
        $@,
        qr{No CWF source: CWF_SOURCE unset and cwf_source missing/empty in \.cwf/version},
        'dies with documented message',
    );
};

subtest 'TC-6: env empty + file empty → dies' => sub {
    plan tests => 1;
    local $ENV{CWF_SOURCE} = '';
    my %v = (cwf_source => '');
    eval { main::resolve_source(\%v) };
    like(
        $@,
        qr{No CWF source: CWF_SOURCE unset and cwf_source missing/empty in \.cwf/version},
        'dies with documented message',
    );
};

done_testing();
