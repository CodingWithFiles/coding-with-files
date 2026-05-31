#!/usr/bin/env perl
#
# find-git-root-worktree.t - Worktree-safety tests for CWF::Common::find_git_root
# (Task 173). find_git_root must return the MAIN worktree root even when invoked
# from inside a linked worktree, where `git rev-parse --show-toplevel` returns the
# (disposable) worktree path - the data-loss vector reproduced in Task 172.
#
# Covers:
#   TC-1: inside a linked worktree -> returns the MAIN tree root (not the worktree)
#   TC-2: inside the main tree     -> equals `git rev-parse --show-toplevel`
#   TC-3: outside any git repo     -> undef (contract preserved)
#   TC-4: derivation guard         -> result is absolute and has no trailing /.git
#
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use Cwd qw(cwd);
use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib');
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use CWF::Common qw(find_git_root);
use CWFTest::Fixtures qw(create_git_repo);

plan tests => 4;

# Build a main repo plus a linked worktree; return ($main_root, $worktree).
# Both paths are canonicalised with Cwd::abs_path so comparisons are robust to
# /tmp -> /private/tmp style symlinks (macOS) and trailing slashes.
sub make_repo_with_worktree {
    my $base = shift;
    my $repo = create_git_repo($base);
    return unless defined $repo;
    my $wt = File::Spec->catdir($base, 'wt');
    system('git', '-C', $repo, 'worktree', 'add', '-q', $wt, '-b', 'wtbranch') == 0
        or return;
    return (Cwd::abs_path($repo), Cwd::abs_path($wt));
}

subtest 'TC-1: inside a linked worktree -> returns the MAIN tree root' => sub {
    my $base = tempdir(CLEANUP => 1);
    my ($main, $wt) = make_repo_with_worktree($base);
    plan skip_all => 'git worktree unavailable' unless defined $main;
    plan tests => 3;

    my $orig = cwd();
    chdir $wt or die "chdir $wt: $!";
    my $got = find_git_root();
    chdir $orig;

    ok(defined $got, 'find_git_root returned a value from inside the worktree');
    my $got_rp = defined $got ? Cwd::abs_path($got) : undef;
    is($got_rp, $main, 'resolves the MAIN tree root, not the worktree');
    isnt($got_rp, $wt,  'does NOT resolve the disposable worktree path');
};

subtest 'TC-2: inside the main tree -> equals git rev-parse --show-toplevel' => sub {
    my $base = tempdir(CLEANUP => 1);
    my ($main, $wt) = make_repo_with_worktree($base);
    plan skip_all => 'git worktree unavailable' unless defined $main;
    plan tests => 1;

    my $orig = cwd();
    chdir $main or die "chdir $main: $!";
    my $got = find_git_root();
    my $top = `git rev-parse --show-toplevel 2>/dev/null`;
    chomp $top;
    chdir $orig;

    is(Cwd::abs_path($got), Cwd::abs_path($top),
        'main-tree behaviour unchanged (equals --show-toplevel)');
};

subtest 'TC-3: outside any git repo -> undef' => sub {
    plan tests => 1;
    my $not_a_repo = tempdir(CLEANUP => 1);
    my $orig = cwd();
    chdir $not_a_repo or die "chdir $not_a_repo: $!";
    my $got = find_git_root();
    chdir $orig;
    is($got, undef, 'undef when no enclosing git repo (contract preserved)');
};

subtest 'TC-4: derivation guard -> absolute, no trailing /.git' => sub {
    my $base = tempdir(CLEANUP => 1);
    my ($main, $wt) = make_repo_with_worktree($base);
    plan skip_all => 'git worktree unavailable' unless defined $main;
    plan tests => 2;

    my $orig = cwd();
    chdir $wt or die "chdir $wt: $!";
    my $got = find_git_root();
    chdir $orig;

    ok(File::Spec->file_name_is_absolute($got // ''),
        'resolved root is an absolute path (--path-format=absolute honoured)');
    unlike($got // '', qr{/\.git/?$}, 'resolved root does not end in /.git');
};
