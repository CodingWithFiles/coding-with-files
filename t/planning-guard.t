#!/usr/bin/env perl
#
# planning-guard.t — unit tests for CWF::PlanningGuard (Task 180, R1).
#
# The policy core is pure and git-free: classify_path() takes the target plus an
# explicit list of repo roots, and decide() takes already-resolved TCI fields.
# classify_path touches the filesystem only to resolve symlinks / canonicalise,
# so each test builds a throwaway tree under a tempdir and passes that as a root
# — no git, no task-context-inference, fully deterministic.
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use_ok('CWF::PlanningGuard',
       qw(classify_path decide is_exec_phase PLANNING_GUARD_VALUES));

# Build a repo-root-shaped tree: <root>/.cwf, <root>/.claude,
# <root>/implementation-guide/180-feature-x/. Returns the absolute root.
sub build_root {
    my $root = tempdir(CLEANUP => 1);
    make_path("$root/.cwf/scripts");
    make_path("$root/.claude/skills");
    make_path("$root/implementation-guide/180-feature-x");
    # A real file in each region so abs_path can resolve the existing prefix.
    for my $f ("$root/.cwf/scripts/x", "$root/.claude/skills/y",
               "$root/implementation-guide/180-feature-x/a-task-plan.md",
               "$root/BACKLOG.md", "$root/README.md") {
        open(my $fh, '>', $f) or die "create $f: $!";
        print $fh "stub\n";
        close $fh;
    }
    return $root;
}

# ----- TC-1: classify_path — crown vs non-crown, traversal, symlink ----------
subtest 'TC-1: classify_path crown/non-crown + canonicalisation' => sub {
    plan tests => 9;
    my $root = build_root();
    my @roots = ($root);

    ok( classify_path("$root/.cwf/scripts/x", \@roots),     '.cwf path → crown');
    ok( classify_path("$root/.claude/skills/y", \@roots),   '.claude path → crown');
    ok( classify_path("$root/.cwf/new-file", \@roots),
        'not-yet-existing file under .cwf → crown');
    ok(!classify_path("$root/implementation-guide/180-feature-x/a-task-plan.md", \@roots),
        'task-own planning file → not crown');
    ok(!classify_path("$root/BACKLOG.md", \@roots),         'BACKLOG.md → not crown');
    ok(!classify_path("$root/README.md", \@roots),          'README → not crown');

    # Traversal that lands inside a crown jewel — canonicalised, not string-matched.
    ok( classify_path("$root/implementation-guide/180-feature-x/../../.cwf/evil", \@roots),
        'task-own/../../.cwf/evil → crown (traversal canonicalised)');

    # A symlink under a non-crown dir that points into .cwf — resolved, → crown.
    my $link = "$root/implementation-guide/link-to-cwf";
    if (symlink("$root/.cwf", $link)) {
        ok( classify_path("$link/escaped", \@roots),
            'symlink into .cwf → crown (symlink resolved)');
    } else {
        ok(1, 'symlink unsupported — skipped (treated as pass)');
    }

    # A path entirely outside every root is not a crown jewel.
    ok(!classify_path("/tmp/somewhere-else/file", \@roots),
        'path outside all roots → not crown');
};

# ----- TC-2: two-root (worktree) rule — most restrictive ---------------------
subtest 'TC-2: a .cwf under a SECOND root in @roots is crown' => sub {
    plan tests => 2;
    my $main     = build_root();
    my $worktree = build_root();
    my @roots = ($main, $worktree);
    ok( classify_path("$worktree/.cwf/scripts/x", \@roots),
        '.cwf under the second (worktree) root → crown');
    ok(!classify_path("$worktree/implementation-guide/180-feature-x/a-task-plan.md", \@roots),
        'task file under the second root → not crown');
};

# ----- TC-3: decide matrix ---------------------------------------------------
subtest 'TC-3: decide(tool, is_crown, confidence, workflow_step)' => sub {
    plan tests => 9;
    my ($d, $tok);

    ($d) = decide('Read', 1, 'correlated', 'c-design-plan');
    is($d, 'allow', 'non-Edit/Write tool → allow');

    ($d) = decide('Bash', 1, 'correlated', 'c-design-plan');
    is($d, 'allow', 'Bash → allow (tool gate)');

    ($d) = decide('Edit', 0, 'correlated', 'c-design-plan');
    is($d, 'allow', 'non-crown Edit → allow');

    ($d) = decide('Write', 0, 'uncorrelated', undef);
    is($d, 'allow', 'non-crown Write → allow regardless of confidence');

    ($d) = decide('Edit', 1, 'correlated', 'f-implementation-exec');
    is($d, 'allow', 'crown + correlated + implementation-exec → allow (letter stripped)');

    ($d, $tok) = decide('Edit', 1, 'correlated', 'c-design-plan');
    is($d, 'deny', 'crown + correlated + planning phase → deny');

    ($d) = decide('Edit', 1, 'correlated', 'g-testing-exec');
    is($d, 'deny', 'crown + correlated + testing-exec → deny (conservative exec set)');

    ($d) = decide('Write', 1, 'no_signals', undef);
    is($d, 'deny', 'crown + no_signals → deny');

    ($d) = decide('Write', 1, 'error', undef);
    is($d, 'deny', 'crown + error → deny');
};

# ----- TC-4: ordering regression — confidence gates first --------------------
subtest 'TC-4: uncorrelated + exec-looking step → deny (confidence first)' => sub {
    plan tests => 1;
    my ($d) = decide('Edit', 1, 'uncorrelated', 'f-implementation-exec');
    is($d, 'deny',
       'uncorrelated must deny even with an exec-looking workflow_step (the '
     . 'correlated check must precede is_exec_phase — fails if the && is reordered)');
};

# ----- TC-5: deny token is a fixed enumeration, never the path/slug ----------
subtest 'TC-5: deny reason is a fixed token (no path, no slug)' => sub {
    plan tests => 5;
    my (undef, $tok) = decide('Edit', 1, 'correlated', 'c-design-plan');
    like($tok, qr/\Qcrown-jewel:.cwf|.claude\E/, 'carries the fixed crown marker');
    like($tok, qr/\bphase:design-plan\b/, 'recognised phase → phase:design-plan');

    (undef, $tok) = decide('Edit', 1, 'no_signals', undef);
    like($tok, qr/\bphase:unknown\b/, 'absent/unknown step → phase:unknown');

    (undef, $tok) = decide('Edit', 1, 'correlated', 'z-not-a-real-phase');
    like($tok, qr/\bphase:unknown\b/, 'unrecognised suffix collapses to phase:unknown');

    # Never leaks an arbitrary slug/path: token chars are a closed set.
    unlike($tok, qr/[^A-Za-z0-9:.|_ -]/, 'token uses only fixed enumeration chars');
};

# ----- enum constant sanity --------------------------------------------------
subtest 'PLANNING_GUARD_VALUES is the shared off/observe/enforce enum' => sub {
    plan tests => 2;
    my @v = PLANNING_GUARD_VALUES();
    is_deeply([sort @v], [sort qw(off observe enforce)], 'exactly off/observe/enforce');
    ok( is_exec_phase('f-implementation-exec') && !is_exec_phase('e-testing-plan'),
        'is_exec_phase: implementation-exec yes, testing-plan no');
};

done_testing();
