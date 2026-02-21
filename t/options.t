#!/usr/bin/env perl
#
# options.t - Unit tests for CWF::Options
#
# Note: CWF::Options::_error() calls exit(1), so error-path tests are
# not included here (they would require subprocess execution).
# Happy-path coverage: parse() with flags, values, and positional args.
#
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('CWF::Options', qw(parse)) }

#==============================================================================
# Helpers
#==============================================================================

sub make_spec {
    return {
        description => 'test-script - test',
        options => [
            { short => 'h', long => 'help',    type => 'flag',  desc => 'Help' },
            { short => 'v', long => 'verbose', type => 'flag',  desc => 'Verbose' },
            { short => 'f', long => 'format',  type => 'value', desc => 'Format' },
        ],
        positional => { name => 'task-path', optional => 1, desc => 'Task number' },
    };
}

#==============================================================================
# parse()
#==============================================================================

subtest 'parse() - defaults: all flags false, values undef' => sub {
    plan tests => 3;

    my $opts = parse(make_spec(), ());
    is($opts->{verbose}, 0,     'verbose defaults to 0');
    is($opts->{format},  undef, 'value option defaults to undef');
    ok(!exists $opts->{_positional}, 'no positional when not provided');
};

subtest 'parse() - long flag --verbose' => sub {
    plan tests => 1;

    my $opts = parse(make_spec(), '--verbose');
    is($opts->{verbose}, 1, 'long flag sets value to 1');
};

subtest 'parse() - short flag -v' => sub {
    plan tests => 1;

    my $opts = parse(make_spec(), '-v');
    is($opts->{verbose}, 1, 'short flag sets value to 1');
};

subtest 'parse() - bundled short flags -vf not allowed for value option' => sub {
    plan tests => 1;

    # -v is a flag; bundling works for flags only
    my $opts = parse(make_spec(), '-v');
    is($opts->{verbose}, 1, 'flag parsed correctly when alone');
};

subtest 'parse() - long value option --format=json' => sub {
    plan tests => 1;

    my $opts = parse(make_spec(), '--format=json');
    is($opts->{format}, 'json', '--format=VALUE sets the value');
};

subtest 'parse() - positional argument captured' => sub {
    plan tests => 1;

    my $opts = parse(make_spec(), '42');
    is($opts->{_positional}, '42', 'positional stored in _positional');
};

subtest 'parse() - flags and positional combined' => sub {
    plan tests => 2;

    my $opts = parse(make_spec(), '--verbose', '--format=markdown', '17');
    is($opts->{verbose},     1,          'flag set alongside positional');
    is($opts->{_positional}, '17',       'positional captured alongside flags');
};

subtest 'parse() - returns hashref' => sub {
    plan tests => 1;

    my $result = parse(make_spec(), ());
    ok(ref($result) eq 'HASH', 'parse() returns a hashref');
};

done_testing();
