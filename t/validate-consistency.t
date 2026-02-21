#!/usr/bin/env perl
#
# validate-consistency.t - Unit tests for CWF::Validate::Consistency
#
# Tier C: requires git
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

use CWFTest::Fixtures qw(create_git_repo);

BEGIN { use_ok('CWF::Validate::Consistency', qw(validate)) }

sub write_md {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
}

#==============================================================================
# validate() - no-git tests
#==============================================================================

subtest 'validate() - missing implementation-guide returns empty list' => sub {
    plan tests => 1;

    my $tmp = tempdir(CLEANUP => 1);
    my @v = validate($tmp);
    is(scalar @v, 0, 'no implementation-guide → no violations');
};

#==============================================================================
# validate() - git-dependent tests (Tier C)
#==============================================================================

my $git_available = (system("git --version >/dev/null 2>&1") == 0);

SKIP: {
    skip 'git not available', 3 unless $git_available;

    my $tmp  = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($tmp);
    skip 'git repo creation failed', 3 unless $repo;

    make_path("$repo/implementation-guide/1-feature-test");
    my $plan = "$repo/implementation-guide/1-feature-test/a-task-plan.md";

    subtest 'validate() - matching task num returns no task violation' => sub {
        plan tests => 1;

        write_md($plan,
            "# Plan\n\n## Task Reference\n**Task**: 1\n**Branch**: main\n\n## Status\n**Status**: Finished\n");
        my @v = validate($repo);
        ok(!(grep { $_->{field} eq '**Task**' } @v), 'matching task num → no task violation');
    };

    subtest 'validate() - mismatched task num returns violation' => sub {
        plan tests => 1;

        write_md($plan,
            "# Plan\n\n## Task Reference\n**Task**: 99\n**Branch**: main\n\n## Status\n**Status**: Finished\n");
        my @v = validate($repo);
        ok((grep { $_->{field} eq '**Task**' } @v), 'wrong task num → task violation');
    };

    subtest 'validate() - finished task branch mismatch not flagged' => sub {
        plan tests => 1;

        write_md($plan,
            "# Plan\n\n## Task Reference\n**Task**: 1\n**Branch**: some-other-branch\n\n## Status\n**Status**: Finished\n");
        my @v = validate($repo);
        ok(!(grep { $_->{field} eq '**Branch**' } @v), 'finished task → branch not checked');
    };
}

done_testing();
