#!/usr/bin/env perl
#
# cwf-manage-list-releases.t — Unit tests for parse_semver and filter_releases
#
# Loads cwf-manage via do() with @ARGV = ('help') so main() runs harmlessly.
# Both subs are pure functions; no network call required.
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

#==============================================================================
# parse_semver
#==============================================================================

subtest 'parse_semver — valid v-prefixed semver' => sub {
    plan tests => 1;
    my @r = main::parse_semver('v1.2.3');
    is_deeply(\@r, [1, 2, 3], 'v1.2.3 → (1, 2, 3)');
};

subtest 'parse_semver — no v prefix' => sub {
    plan tests => 1;
    my @r = main::parse_semver('1.2.3');
    is_deeply(\@r, [], '1.2.3 (no v) → ()');
};

subtest 'parse_semver — 2-part tag' => sub {
    plan tests => 1;
    my @r = main::parse_semver('v1.2');
    is_deeply(\@r, [], 'v1.2 → ()');
};

subtest 'parse_semver — non-numeric' => sub {
    plan tests => 1;
    my @r = main::parse_semver('vabc');
    is_deeply(\@r, [], 'vabc → ()');
};

subtest 'parse_semver — empty string' => sub {
    plan tests => 1;
    my @r = main::parse_semver('');
    is_deeply(\@r, [], '"" → ()');
};

#==============================================================================
# filter_releases (tags pre-sorted descending, as cmd_list_releases passes them)
#==============================================================================

subtest 'filter_releases — already on latest (no upgrades)' => sub {
    plan tests => 1;
    my @r = main::filter_releases('v0.1.90', 'v0.1.90');
    is_deeply(\@r, [], 'on latest → empty list');
};

subtest 'filter_releases — new patch on same minor' => sub {
    plan tests => 1;
    my @r = main::filter_releases('v0.1.88', 'v0.1.90', 'v0.1.89', 'v0.1.88');
    is_deeply(\@r, ['v0.1.90'], 'highest same-minor patch only; v0.1.89 hidden');
};

subtest 'filter_releases — multiple higher minors' => sub {
    plan tests => 1;
    my @r = main::filter_releases(
        'v0.1.88',
        'v0.3.95', 'v0.2.90', 'v0.2.89', 'v0.1.88'
    );
    is_deeply(\@r, ['v0.3.95', 'v0.2.90'], 'one entry per higher minor, descending');
};

subtest 'filter_releases — higher major plus same-minor patch' => sub {
    plan tests => 1;
    my @r = main::filter_releases(
        'v0.1.88',
        'v1.0.103', 'v0.1.90', 'v0.1.88'
    );
    is_deeply(\@r, ['v1.0.103', 'v0.1.90'], 'major bucket + same-minor bucket');
};

subtest 'filter_releases — multiple higher majors' => sub {
    plan tests => 1;
    my @r = main::filter_releases(
        'v0.1.88',
        'v2.0.5', 'v1.0.103', 'v0.1.88'
    );
    is_deeply(\@r, ['v2.0.5', 'v1.0.103'], 'one entry per major, descending');
};

subtest 'filter_releases — non-semver tags silently excluded' => sub {
    plan tests => 1;
    my @r = main::filter_releases(
        'v0.1.88',
        'latest', 'v0.1.90', 'nightly', 'v0.1.88'
    );
    is_deeply(\@r, ['v0.1.90'], 'latest/nightly not in output, no error');
};

done_testing();
