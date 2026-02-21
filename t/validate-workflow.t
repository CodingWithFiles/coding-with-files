#!/usr/bin/env perl
#
# validate-workflow.t - Unit tests for CWF::Validate::Workflow
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('CWF::Validate::Workflow', qw(validate)) }

sub write_md {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
}

#==============================================================================
# validate()
#==============================================================================

subtest 'validate() - missing implementation-guide returns empty list' => sub {
    plan tests => 1;

    my $tmp = tempdir(CLEANUP => 1);
    my @v = validate($tmp);
    is(scalar @v, 0, 'no implementation-guide → no violations');
};

subtest 'validate() - valid md file returns no violations' => sub {
    plan tests => 1;

    my $tmp = tempdir(CLEANUP => 1);
    my $dir = "$tmp/implementation-guide/1-feature-test";
    make_path($dir);
    write_md("$dir/a-task-plan.md", "# Plan\n\n## Status\n**Status**: Backlog\n");

    my @v = validate($tmp);
    is(scalar @v, 0, 'valid status → no violations');
};

subtest 'validate() - file missing Status section returns violation' => sub {
    plan tests => 2;

    my $tmp = tempdir(CLEANUP => 1);
    my $dir = "$tmp/implementation-guide/2-feature-test";
    make_path($dir);
    write_md("$dir/a-task-plan.md", "# Plan\n\n## Description\nSome text.\n");

    my @v = validate($tmp);
    ok(@v > 0, 'missing Status section → violation');
    like($v[0]{actual}, qr/missing/, 'actual describes missing section');
};

subtest 'validate() - unknown status returns violation' => sub {
    plan tests => 2;

    my $tmp = tempdir(CLEANUP => 1);
    my $dir = "$tmp/implementation-guide/3-feature-test";
    make_path($dir);
    write_md("$dir/a-task-plan.md", "# Plan\n\n## Status\n**Status**: GibberishStatus\n");

    my @v = validate($tmp);
    ok(@v > 0, 'unknown status → violation');
    is($v[0]{actual}, 'GibberishStatus', 'actual shows the bad status value');
};

subtest 'validate() - all known statuses are valid' => sub {
    plan tests => 7;

    for my $status ('Backlog', 'In Progress', 'Testing', 'Finished', 'Blocked', 'Skipped', 'Cancelled') {
        my $tmp = tempdir(CLEANUP => 1);
        my $dir = "$tmp/implementation-guide/10-feature-test";
        make_path($dir);
        write_md("$dir/a-task-plan.md", "# Plan\n\n## Status\n**Status**: $status\n");

        my @v = validate($tmp);
        is(scalar @v, 0, "\"$status\" is a valid status");
    }
};

done_testing();
