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

# Build a single-file task node at $repo/implementation-guide/$rel.
# $task is the **Task** value (pass a wrong value to exercise FR1); $branch and
# $status are written only when defined (omit $status for a no-status node).
sub mknode {
    my ($repo, $rel, $task, $branch, $status) = @_;
    my $dir = "$repo/implementation-guide/$rel";
    make_path($dir);
    my $body = "# F\n\n## Task Reference\n**Task**: $task\n";
    $body .= "**Branch**: $branch\n" if defined $branch;
    $body .= "\n## Status\n**Status**: $status\n" if defined $status;
    write_md("$dir/a-task-plan.md", $body);
    return $dir;
}

# Create and switch to $branch in the test repo (Tier C helper).
sub set_branch {
    my ($repo, $branch) = @_;
    return system("git -C '$repo' checkout -q -b '$branch'") == 0;
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

#==============================================================================
# Hierarchy tests - structural (no current branch needed; run without git)
#==============================================================================

subtest 'TC-1: nested subtask wrong **Task** is reported (FR1)' => sub {
    plan tests => 2;
    my $root = tempdir(CLEANUP => 1);
    mknode($root, '1-feature-p', '1', 'feature/1', 'Finished');
    mknode($root, '1-feature-p/1.1-bugfix-c', '1', 'feature/1.1', 'Finished'); # **Task** wrong: dir is 1.1
    my @tv = grep { $_->{field} eq '**Task**' } validate($root);
    is(scalar @tv, 1, 'one **Task** violation surfaced from the nested dir');
    like($tv[0]{file}, qr{1\.1-bugfix-c/}, 'violation file is inside the nested subtask dir');
};

subtest 'TC-4a: Finished parent + active child -> completeness violation (FR4)' => sub {
    plan tests => 3;
    my $root = tempdir(CLEANUP => 1);
    mknode($root, '1-feature-p', '1', 'feature/1', 'Finished');
    mknode($root, '1-feature-p/1.1-bugfix-c', '1.1', 'feature/1.1', 'Backlog');
    my @sv = grep { $_->{field} eq '**Status**' } validate($root);
    is(scalar @sv, 1, 'one completeness violation');
    like($sv[0]{file}, qr{1-feature-p/$}, 'violation names the complete parent dir');
    like($sv[0]{expected}, qr{\b1\.1\b}, 'fix names the active descendant 1.1');
};

subtest 'TC-4b: Cancelled parent + active child -> completeness violation (Cancelled terminal)' => sub {
    plan tests => 1;
    my $root = tempdir(CLEANUP => 1);
    mknode($root, '1-feature-p', '1', 'feature/1', 'Cancelled');
    mknode($root, '1-feature-p/1.1-bugfix-c', '1.1', 'feature/1.1', 'Backlog');
    my @sv = grep { $_->{field} eq '**Status**' } validate($root);
    is(scalar @sv, 1, 'Cancelled parent treated as complete');
};

subtest 'TC-4c: terminal child under active parent -> permitted (inverse)' => sub {
    plan tests => 1;
    my $root = tempdir(CLEANUP => 1);
    mknode($root, '1-feature-p', '1', 'feature/1', 'Backlog');
    mknode($root, '1-feature-p/1.1-bugfix-c', '1.1', 'feature/1.1', 'Finished');
    my @sv = grep { $_->{field} eq '**Status**' } validate($root);
    is(scalar @sv, 0, 'no completeness violation for terminal child under active parent');
};

subtest 'TC-4d: missing-status child under complete parent -> no FR4 violation' => sub {
    plan tests => 1;
    my $root = tempdir(CLEANUP => 1);
    mknode($root, '1-feature-p', '1', 'feature/1', 'Finished');
    mknode($root, '1-feature-p/1.1-bugfix-c', '1.1', 'feature/1.1', undef); # no Status section
    my @sv = grep { $_->{field} eq '**Status**' } validate($root);
    is(scalar @sv, 0, 'unparseable/missing status does not count as active');
};

subtest 'TC-4e: complete leaf with no descendants -> no completeness violation' => sub {
    plan tests => 1;
    my $root = tempdir(CLEANUP => 1);
    mknode($root, '1-feature-p', '1', 'feature/1', 'Finished');
    my @sv = grep { $_->{field} eq '**Status**' } validate($root);
    is(scalar @sv, 0, 'self is not its own descendant');
};

subtest 'TC-4f: nearest active descendant is deterministic (shallowest, then version order)' => sub {
    plan tests => 2;
    my $root = tempdir(CLEANUP => 1);
    mknode($root, '1-feature-p', '1', 'feature/1', 'Finished');
    mknode($root, '1-feature-p/1.1-feature-a', '1.1', 'feature/1.1', 'Backlog');
    mknode($root, '1-feature-p/1.2-feature-b', '1.2', 'feature/1.2', 'Backlog');
    mknode($root, '1-feature-p/1.1-feature-a/1.1.1-feature-c', '1.1.1', 'feature/1.1.1', 'Backlog');
    my @sv = grep { $_->{field} eq '**Status**' } validate($root);
    is(scalar @sv, 1, 'exactly one completeness violation for the complete parent');
    is($sv[0]{expected}, 'active descendant 1.1', 'nearest = shallowest, 1.1 before 1.2');
};

subtest 'TC-S1: a symlinked subtask dir is not followed (NFR4)' => sub {
    my $root = tempdir(CLEANUP => 1);
    mknode($root, '1-feature-p', '1', 'feature/1', 'Backlog');
    my $ext = "$root/outside/1.9-feature-evil";
    make_path($ext);
    write_md("$ext/a-task-plan.md",
        "# F\n\n## Task Reference\n**Task**: 99\n**Branch**: feature/evil\n\n## Status\n**Status**: Backlog\n");
    my $link = "$root/implementation-guide/1-feature-p/1.9-feature-evil";
    plan skip_all => 'symlink unsupported on this platform'
        unless eval { symlink($ext, $link) };
    plan tests => 1;
    my @v = validate($root);
    ok(!(grep { $_->{file} =~ m{(?:outside|1\.9-feature-evil)} } @v),
        'no violation references the symlink target outside implementation-guide');
};

subtest 'TC-W: no warnings while exercising the ancestry walk (NFR5)' => sub {
    plan tests => 2;
    my $root = tempdir(CLEANUP => 1);
    mknode($root, '1-feature-p', '1', 'feature/1', 'Finished');                  # complete
    mknode($root, '1-feature-p/1.1-bugfix-c', '1.1', 'feature/1.1', 'Backlog');  # active
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my @v = validate($root);
    is(scalar @warns, 0, 'no warnings (get_parent reaches undef without warning)');
    ok((grep { $_->{field} eq '**Status**' } @v), 'completeness pass ran, so _is_ancestor was exercised');
};

#==============================================================================
# Hierarchy tests - directional branch rule (Tier C: requires git)
#==============================================================================

SKIP: {
    skip 'git not available', 6 unless $git_available;

    subtest 'TC-2: active ancestor on a descendant branch -> no branch violation (FR2)' => sub {
        my $repo = create_git_repo(tempdir(CLEANUP => 1));
        plan skip_all => 'git repo creation failed' unless $repo;
        plan tests => 1;
        mknode($repo, '1-feature-p', '1', 'feature/1', 'Backlog');
        mknode($repo, '1-feature-p/1.1-bugfix-c', '1.1', 'feature/1.1', 'Backlog');
        set_branch($repo, 'feature/1.1');
        my @bv = grep { $_->{field} eq '**Branch**' } validate($repo);
        is(scalar @bv, 0, 'ancestor (1) satisfied-by-descendant; leaf (1.1) matches');
    };

    subtest 'TC-2b: grandparent ancestor (multi-level) -> no branch violation (FR2)' => sub {
        my $repo = create_git_repo(tempdir(CLEANUP => 1));
        plan skip_all => 'git repo creation failed' unless $repo;
        plan tests => 1;
        mknode($repo, '1-feature-p', '1', 'feature/1', 'Backlog');
        mknode($repo, '1-feature-p/1.1-feature-b', '1.1', 'feature/1.1', 'Backlog');
        mknode($repo, '1-feature-p/1.1-feature-b/1.1.1-feature-c', '1.1.1', 'feature/1.1.1', 'Backlog');
        set_branch($repo, 'feature/1.1.1');
        my @bv = grep { $_->{field} eq '**Branch**' } validate($repo);
        is(scalar @bv, 0, 'both 1 and 1.1 are transitive ancestors of the leaf');
    };

    subtest 'TC-2c: numeric near-miss sibling is still flagged (FR2)' => sub {
        my $repo = create_git_repo(tempdir(CLEANUP => 1));
        plan skip_all => 'git repo creation failed' unless $repo;
        plan tests => 2;
        mknode($repo, '1-feature-p', '1', 'feature/1', 'Backlog');
        mknode($repo, '1-feature-p/1.1-feature-a', '1.1', 'feature/1.1', 'Backlog');
        mknode($repo, '1-feature-p/1.10-feature-b', '1.10', 'feature/1.10', 'Backlog');
        set_branch($repo, 'feature/1.10');
        my @bv = grep { $_->{field} eq '**Branch**' } validate($repo);
        is(scalar @bv, 1, 'only the sibling 1.1 is flagged (1 is ancestor, 1.10 is leaf)');
        is($bv[0]{actual}, 'feature/1.1', '1.1 is not mis-read as an ancestor of 1.10');
    };

    subtest 'TC-3a: unrelated active task off the chain is flagged (FR3)' => sub {
        my $repo = create_git_repo(tempdir(CLEANUP => 1));
        plan skip_all => 'git repo creation failed' unless $repo;
        plan tests => 2;
        mknode($repo, '1-feature-p', '1', 'feature/1', 'Backlog');
        mknode($repo, '1-feature-p/1.1-bugfix-c', '1.1', 'feature/1.1', 'Backlog');
        mknode($repo, '2-feature-q', '2', 'feature/2', 'Backlog');
        set_branch($repo, 'feature/1.1');
        my @bv = grep { $_->{field} eq '**Branch**' } validate($repo);
        is(scalar @bv, 1, 'only the off-chain task 2 is flagged');
        is($bv[0]{actual}, 'feature/2', 'chain tasks 1 and 1.1 are not flagged');
    };

    subtest 'TC-3b: duplicate current-branch records -> fail closed (FR3)' => sub {
        my $repo = create_git_repo(tempdir(CLEANUP => 1));
        plan skip_all => 'git repo creation failed' unless $repo;
        plan tests => 2;
        mknode($repo, '1-feature-p', '1', 'feature/shared', 'Backlog');
        mknode($repo, '2-feature-q', '2', 'feature/shared', 'Backlog');
        mknode($repo, '3-feature-r', '3', 'feature/3', 'Backlog');
        set_branch($repo, 'feature/shared');
        my @bv = grep { $_->{field} eq '**Branch**' } validate($repo);
        is(scalar @bv, 1, 'ambiguous leaf disables suppression; only off-chain task 3 flagged');
        is($bv[0]{actual}, 'feature/3', 'tasks on the current branch are not flagged');
    };

    subtest 'TC-R5: flat repo (active + finished) violation set unchanged (FR5)' => sub {
        my $repo = create_git_repo(tempdir(CLEANUP => 1));
        plan skip_all => 'git repo creation failed' unless $repo;
        plan tests => 4;
        mknode($repo, '1-feature-p', '1', 'feature/1', 'Backlog');   # active, off current branch
        mknode($repo, '2-feature-q', '2', 'feature/2', 'Finished');  # terminal
        set_branch($repo, 'feature/other');
        my @v = validate($repo);
        is(scalar @v, 1, 'exactly one violation, as before the change');
        is($v[0]{field}, '**Branch**', 'the active task branch mismatch');
        is($v[0]{actual}, 'feature/1', 'flagged task is the active one');
        is($v[0]{expected}, 'feature/other', 'against the current branch');
    };
}

done_testing();
