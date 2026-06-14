#!/usr/bin/env perl
#
# taskpath-parent-branch-ancestry.t - Tests for CWF::TaskPath::parent_branch_ancestry
# and the additive context-manager hierarchy output (Task 202).
#
# Tier C: every case needs a synthetic git repo whose history is shaped to
# exercise one row of the c-design edge-case table. The live CWF repo is
# strictly linear and top-level-only here, so the diverged/undecidable paths
# can only be proven against throwaway repos.
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Cwd ();
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

use JSON::PP ();
use CWFTest::Fixtures qw(create_git_repo);
use CWF::TaskPath ();

my $git_available = (system("git --version >/dev/null 2>&1") == 0);

plan skip_all => 'git not available' unless $git_available;

my $CM = "$FindBin::Bin/../.cwf/scripts/command-helpers/context-manager";

# Build a synthetic repo with implementation-guide/ holding a parent task dir
# (1-<ptype>-<pslug>) and, by default, a nested child (1.1-<ctype>-<cslug>).
# The dirs are left untracked — resolve() globs the filesystem, no commit needed.
# Returns the repo path (one initial commit on the default branch) or undef.
sub build_repo {
    my (%o) = @_;
    my $tmp  = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($tmp) or return undef;

    my $ig    = "$repo/implementation-guide";
    my $ptype = $o{parent_type} // 'feature';
    my $pslug = $o{parent_slug} // 'parent';
    my $pdir  = "$ig/1-$ptype-$pslug";
    make_path($pdir);

    unless (defined $o{child} && !$o{child}) {
        my $ctype = $o{child_type} // 'bugfix';
        my $cslug = $o{child_slug} // 'child';
        make_path("$pdir/1.1-$ctype-$cslug");
    }
    return $repo;
}

sub git { my ($repo, @a) = @_; system('git', '-C', $repo, @a) == 0 or die "git @a failed"; }

sub default_branch {
    my ($repo) = @_;
    open my $p, '-|', 'git', '-C', $repo, 'rev-parse', '--abbrev-ref', 'HEAD' or die $!;
    chomp(my $b = <$p>); close $p; return $b;
}

# Call parent_branch_ancestry with cwd inside $repo (the function resolves the
# base dir and runs git relative to cwd), restoring cwd afterwards.
sub anc {
    my ($repo, $path) = @_;
    my $orig = Cwd::cwd();
    chdir $repo or die "chdir $repo: $!";
    my $r = eval { CWF::TaskPath::parent_branch_ancestry($path) };
    chdir $orig;
    die $@ if $@;
    return $r;
}

# Run the real context-manager hierarchy subcommand from cwd=$repo (list form,
# no shell), capturing stdout.
sub run_hier {
    my ($repo, @args) = @_;
    my $orig = Cwd::cwd();
    chdir $repo or die "chdir $repo: $!";
    open my $p, '-|', $CM, 'hierarchy', @args
        or do { chdir $orig; die "run hierarchy: $!" };
    local $/; my $out = <$p>; close $p;
    chdir $orig;
    return defined $out ? $out : '';
}

#==============================================================================
# Functional — tri-state (map to ACs)
#==============================================================================

subtest 'TC-1 (AC1): parent branch is an ancestor of HEAD -> 1' => sub {
    plan tests => 1;
    my $repo = build_repo() or BAIL_OUT('repo build failed');
    git($repo, 'branch', 'feature/1-parent');             # at C0
    git($repo, 'commit', '--allow-empty', '-q', '-m', 'c1'); # HEAD advances past C0
    is(anc($repo, '1.1'), 1, 'ancestor parent branch -> 1');
};

subtest 'TC-2 (AC1): HEAD == parent branch tip -> 1 (own ancestor)' => sub {
    plan tests => 1;
    my $repo = build_repo() or BAIL_OUT('repo build failed');
    git($repo, 'branch', 'feature/1-parent');             # at C0; HEAD also C0
    is(anc($repo, '1.1'), 1, 'same-tip -> 1');
};

subtest 'TC-3 (AC2): parent branch diverged from HEAD -> 0' => sub {
    plan tests => 1;
    my $repo = build_repo() or BAIL_OUT('repo build failed');
    my $def  = default_branch($repo);
    git($repo, 'checkout', '-q', '-b', 'feature/1-parent');  # at C0
    git($repo, 'commit', '--allow-empty', '-q', '-m', 'p1');  # parent -> P1
    git($repo, 'checkout', '-q', $def);                       # back to C0
    git($repo, 'commit', '--allow-empty', '-q', '-m', 'm1');  # HEAD -> M1
    is(anc($repo, '1.1'), 0, 'diverged parent branch -> 0');
};

subtest 'TC-4 (AC3): top-level task (no parent) -> undef' => sub {
    plan tests => 1;
    my $repo = build_repo() or BAIL_OUT('repo build failed');
    git($repo, 'branch', 'feature/1-parent');
    is(anc($repo, '1'), undef, 'no parent task -> undef');
};

subtest 'TC-5 (AC3): parent branch absent -> undef (distinct from 0)' => sub {
    plan tests => 1;
    my $repo = build_repo() or BAIL_OUT('repo build failed');  # no feature/1-parent created
    is(anc($repo, '1.1'), undef, 'missing parent branch -> undef');
};

subtest 'TC-6 (FR4): prefix-collision branch must not false-positive -> undef' => sub {
    plan tests => 1;
    # Parent task slug is "foobar" => parent branch feature/1-foobar (absent).
    # A decoy feature/1-foo exists; an exact rev-parse --verify must not match it.
    my $repo = build_repo(parent_slug => 'foobar') or BAIL_OUT('repo build failed');
    git($repo, 'branch', 'feature/1-foo');                # decoy, NOT feature/1-foobar
    is(anc($repo, '1.1'), undef, 'prefix-collision decoy -> undef');
};

subtest 'TC-7: merge-base cannot answer (unborn HEAD) -> undef' => sub {
    plan tests => 1;
    my $repo = build_repo() or BAIL_OUT('repo build failed');
    git($repo, 'branch', 'feature/1-parent');             # branch exists (guard passes)
    git($repo, 'checkout', '-q', '--orphan', 'orphan');   # HEAD unborn -> merge-base errors
    is(anc($repo, '1.1'), undef, 'unborn HEAD -> undef');
};

#==============================================================================
# Integration — hierarchy output
#==============================================================================

subtest 'TC-8 (AC4): JSON validity via a real parser + additive field' => sub {
    plan tests => 11;
    my $repo = build_repo() or BAIL_OUT('repo build failed');
    git($repo, 'branch', 'feature/1-parent');
    git($repo, 'commit', '--allow-empty', '-q', '-m', 'c1'); # ancestor -> true

    my $raw = run_hier($repo, '1.1', '--format=json');
    my $obj = eval { JSON::PP->new->decode($raw) };
    ok($obj, 'output parses as JSON') or diag("raw: $raw");

    ok(exists $obj->{parent_branch_is_ancestor}, 'new field present');
    ok(JSON::PP::is_bool($obj->{parent_branch_is_ancestor}),
       'new field is a JSON boolean (not a string)');
    ok($obj->{parent_branch_is_ancestor}, 'true for ancestor case');

    for my $f (qw(full_path format task_num task_type task_slug parent_path depth)) {
        ok(exists $obj->{$f}, "pre-existing field '$f' still present");
    }
};

subtest 'TC-9: markdown line present for parented task, absent for top-level' => sub {
    plan tests => 2;
    my $repo = build_repo() or BAIL_OUT('repo build failed');
    git($repo, 'branch', 'feature/1-parent');
    git($repo, 'commit', '--allow-empty', '-q', '-m', 'c1');

    my $child = run_hier($repo, '1.1');
    like($child, qr/^Parent branch ancestor of HEAD: (?:yes|no|unknown)$/m,
         'parented task prints the ancestry line');

    my $top = run_hier($repo, '1');
    unlike($top, qr/Parent branch ancestor of HEAD:/,
           'top-level task prints no ancestry line');
};

done_testing();
