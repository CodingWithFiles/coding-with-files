#!/usr/bin/env perl
#
# backlog-roundtrip-live.t — AC6 round-trip property tests against the live
# BACKLOG.md and CHANGELOG.md. Loads each, parses with the new tree parser,
# serialises, asserts byte-identical to the input. Required to be green
# post-Task-132 Step 6 (live-file migration).
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use Encode qw(encode decode);
use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib');

use CWF::Backlog qw(parse_backlog_tree parse_changelog_tree serialize_tree);

my $REPO = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $BL   = File::Spec->catfile($REPO, 'BACKLOG.md');
my $CL   = File::Spec->catfile($REPO, 'CHANGELOG.md');

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "$path: $!";
    local $/;
    my $bytes = <$fh>;
    close $fh;
    return $bytes;
}

subtest 'TC-ROUNDTRIP-LIVE-BACKLOG: parse → serialize byte-identical' => sub {
    plan tests => 2;
    my $orig = slurp($BL);
    my ($tree, $errs) = parse_backlog_tree($BL);
    is(scalar @$errs, 0, 'no global errors on parse');
    my $out  = encode('UTF-8', serialize_tree($tree));
    is($out, $orig, 'byte-identical round-trip');
};

subtest 'TC-ROUNDTRIP-LIVE-CHANGELOG: parse → serialize byte-identical' => sub {
    plan tests => 2;
    my $orig = slurp($CL);
    my ($tree, $errs) = parse_changelog_tree($CL);
    is(scalar @$errs, 0, 'no global errors on parse');
    my $out  = encode('UTF-8', serialize_tree($tree));
    is($out, $orig, 'byte-identical round-trip');
};

done_testing;
