#!/usr/bin/env perl
#
# scratch.t - Unit tests for CWF::Common::scratch_parent / scratch_dir /
# scratch_fail_hint (Task 206, 229).
#
# scratch_parent: pure, $num-free, NO filesystem (used by the context-inject
# hook every turn). scratch_dir: scratch_parent + two-level 0700 create + the
# tmp-paths symlink-attack defences (used by writers, e.g.
# security-review-changeset). The scratch base is $CWF::Common::SCRATCH_BASE,
# derived purely from the EUID and never from $TMPDIR (Task 229) — every test
# that needs a hermetic base sets `local $CWF::Common::SCRATCH_BASE = tempdir`,
# and none touches the real shared /tmp/claude-<uid> or reads $TMPDIR.
#
# Covers (e-testing-plan TC-1..TC-13):
#   TC-1  scratch_parent happy path      -> "<base>/cwf<dashified-root>"
#   TC-2  worktree main-root             -> parent uses MAIN root, not the worktree
#   TC-3  not_a_repo                     -> (undef,'not_a_repo'); no filesystem
#   TC-4  scratch_dir happy path         -> ("<parent>/task-<num>", undef), mode 0700
#   TC-5  bad_num rejects + NO FS work   -> (undef,'bad_num'); nothing created
#   TC-6  leading-zero / dotted accepted -> success (contract locked)
#   TC-7  symlinked cwf<dash> parent rejected, target not chmod-ed
#   TC-8  idempotent re-call             -> success, mode unchanged
#   TC-9  default base literal (pure)    -> SCRATCH_BASE eq "/tmp/claude-$>"
#   TC-10 poison-$TMPDIR invariance      -> output independent of $ENV{TMPDIR}
#   TC-11 intermediate symlink guard     -> symlinked BASE rejected, target not chmod-ed
#   TC-12 two-level create + 0700        -> absent base + parent both created 0700
#   TC-13 scratch_fail_hint              -> base-related kinds hint; others ''
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
use CWF::Common qw(scratch_parent scratch_dir scratch_fail_hint);
use CWFTest::Fixtures qw(create_git_repo);

plan tests => 13;

# Only the mechanical /->- transform is factored; the BASE is a hard-coded
# literal at every call site (never a mirrored base-selection), so an oracle
# cannot mask a base-derivation bug.
sub dash { my ($p) = @_; (my $d = $p) =~ s{/}{-}g; return $d; }

sub make_repo_with_worktree {
    my $base = shift;
    my $repo = create_git_repo($base);
    return unless defined $repo;
    my $wt = File::Spec->catdir($base, 'wt');
    system('git', '-C', $repo, 'worktree', 'add', '-q', $wt, '-b', 'wtbranch') == 0
        or return;
    return ($repo, $wt);
}

subtest 'TC-1: scratch_parent happy path -> <base>/cwf<dashified-root>' => sub {
    plan tests => 2;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    my $sbase = tempdir(CLEANUP => 1);
    local $CWF::Common::SCRATCH_BASE = $sbase;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my ($parent, $err) = scratch_parent();
    my $root = CWF::Common::find_git_root();
    chdir $orig;

    is($err, undef, 'no error in a git repo');
    is($parent, "$sbase/cwf" . dash($root),
        'parent == <SCRATCH_BASE>/cwf<dashified-root>');
};

subtest 'TC-2: worktree -> parent uses the MAIN root, not the worktree' => sub {
    my $base = tempdir(CLEANUP => 1);
    my ($main, $wt) = make_repo_with_worktree($base);
    plan skip_all => 'git worktree unavailable' unless defined $main;
    plan tests => 1;

    my $sbase = tempdir(CLEANUP => 1);
    local $CWF::Common::SCRATCH_BASE = $sbase;
    my $orig = cwd();
    chdir $main or die "chdir $main: $!";
    my ($from_main) = scratch_parent();
    chdir $wt or die "chdir $wt: $!";
    my ($from_wt) = scratch_parent();
    chdir $orig;

    is($from_wt, $from_main,
        'scratch_parent from a linked worktree equals the main-tree parent');
};

subtest 'TC-3: not_a_repo -> (undef, not_a_repo), no filesystem' => sub {
    plan tests => 3;
    my $not_a_repo = tempdir(CLEANUP => 1);
    my $sbase      = tempdir(CLEANUP => 1);
    local $CWF::Common::SCRATCH_BASE = $sbase;
    my $orig = cwd();
    chdir $not_a_repo or die "chdir $not_a_repo: $!";
    my ($p, $perr) = scratch_parent();
    my ($d, $derr) = scratch_dir('206');
    chdir $orig;

    is($perr, 'not_a_repo', 'scratch_parent reports not_a_repo');
    is($derr, 'not_a_repo', 'scratch_dir reports not_a_repo');
    is($d, undef, 'no path returned outside a repo');
};

subtest 'TC-4: scratch_dir happy path -> created leaf at mode 0700' => sub {
    plan tests => 3;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    my $sbase = tempdir(CLEANUP => 1);
    local $CWF::Common::SCRATCH_BASE = $sbase;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my ($scratch, $err) = scratch_dir('206');
    my $root = CWF::Common::find_git_root();
    chdir $orig;

    is($err, undef, 'no error');
    is($scratch, "$sbase/cwf" . dash($root) . '/task-206',
        'leaf == <base>/cwf<dashified-root>/task-206');
    is(((stat($scratch))[2] & 07777), 0700, 'leaf mode is 0700');
};

subtest 'TC-5: bad_num rejects with NO filesystem work' => sub {
    my @bad = ('1..2', '..', '', '1/2', 'a', '1.', '.1', '1;rm');
    plan tests => 2 * scalar(@bad);
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    my $sbase = tempdir(CLEANUP => 1);
    local $CWF::Common::SCRATCH_BASE = $sbase;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my $root   = CWF::Common::find_git_root();
    my $parent = "$sbase/cwf" . dash($root);
    for my $n (@bad) {
        my ($d, $err) = scratch_dir($n);
        is($err, 'bad_num', "rejects '$n' as bad_num");
        ok(!-e $parent, "no scratch parent created for '$n' (no FS work)");
    }
    chdir $orig;
};

subtest 'TC-6: leading-zero / dotted numbers accepted' => sub {
    plan tests => 2;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    my $sbase = tempdir(CLEANUP => 1);
    local $CWF::Common::SCRATCH_BASE = $sbase;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my (undef, $e1) = scratch_dir('007');
    my (undef, $e2) = scratch_dir('1.01');
    chdir $orig;

    is($e1, undef, "'007' accepted");
    is($e2, undef, "'1.01' accepted");
};

subtest 'TC-7: symlinked cwf<dash> parent rejected, target not chmod-ed' => sub {
    plan tests => 4;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    my $sbase = tempdir(CLEANUP => 1);
    local $CWF::Common::SCRATCH_BASE = $sbase;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my $root   = CWF::Common::find_git_root();
    my $parent = "$sbase/cwf" . dash($root);

    # Pre-plant the cwf<dash> parent (the inner level) as a symlink to an
    # attacker-controlled directory. The base ($sbase) itself is a real dir.
    my $attacker = File::Temp::tempdir(CLEANUP => 1);
    chmod 0755, $attacker;
    my $before = (stat($attacker))[2] & 07777;
    symlink($attacker, $parent) or do { chdir $orig; plan skip_all => 'symlink unsupported' };

    my ($d, $err) = scratch_dir('206');
    my $after = (stat($attacker))[2] & 07777;
    chdir $orig;

    is($err, 'symlink_parent', 'symlinked cwf<dash> parent rejected');
    is($d, undef, 'no path returned');
    ok(-l $parent, 'parent left as a symlink (not followed/replaced)');
    is($after, $before, 'attacker target mode unchanged (no auto-chmod)');
};

subtest 'TC-8: idempotent re-call -> success, mode unchanged' => sub {
    plan tests => 3;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    my $sbase = tempdir(CLEANUP => 1);
    local $CWF::Common::SCRATCH_BASE = $sbase;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my ($first)  = scratch_dir('206');
    my ($second, $err) = scratch_dir('206');
    chdir $orig;

    is($err, undef, 'second call succeeds');
    is($second, $first, 'same path on re-call');
    is(((stat($second))[2] & 07777), 0700, 'mode still 0700');
};

subtest 'TC-9: default SCRATCH_BASE is the pure EUID literal' => sub {
    plan tests => 2;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    # No `local` override: observe the real default. scratch_parent is pure
    # (no filesystem), so this touches nothing under the real base.
    is($CWF::Common::SCRATCH_BASE, "/tmp/claude-$>",
        'SCRATCH_BASE defaults to /tmp/claude-<euid>');

    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my ($parent) = scratch_parent();
    my $root = CWF::Common::find_git_root();
    chdir $orig;

    is($parent, "/tmp/claude-$>/cwf" . dash($root),
        'scratch_parent composes the EUID base with the dashified root');
};

subtest 'TC-10: output is invariant under a poisoned $TMPDIR' => sub {
    # $TMPDIR is deliberately NOT read (Task 229): any value — hostile, doubled,
    # relative, empty, unset — must leave the derived path unchanged. This is the
    # regression test for the reporter's doubling / divergence bug.
    my @poison = ('/tmp/cwf-x', '/tmp/cwf-x/claude-9', '/tmp/a/../b', 'tmp', '');
    plan tests => scalar(@poison) + 1;    # each poison value + the unset case
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    my $sbase = tempdir(CLEANUP => 1);
    local $CWF::Common::SCRATCH_BASE = $sbase;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my $root     = CWF::Common::find_git_root();
    my $expected = "$sbase/cwf" . dash($root);

    for my $t (@poison) {
        local $ENV{TMPDIR} = $t;
        my ($parent) = scratch_parent();
        is($parent, $expected, "invariant under \$TMPDIR='$t'");
    }
    {
        delete local $ENV{TMPDIR};
        my ($parent) = scratch_parent();
        is($parent, $expected, 'invariant when $TMPDIR is unset');
    }
    chdir $orig;
};

subtest 'TC-11: symlinked SCRATCH_BASE (intermediate) rejected, target not chmod-ed' => sub {
    plan tests => 4;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    # The base level itself is a symlink to an attacker dir; the guard must reject
    # it BEFORE the cwf<dash> mkdir descends through it (Task 229 two-level guard).
    my $attacker = tempdir(CLEANUP => 1);
    chmod 0755, $attacker;
    my $before = (stat($attacker))[2] & 07777;
    my $holder = tempdir(CLEANUP => 1);
    my $link   = File::Spec->catdir($holder, 'base-link');
    symlink($attacker, $link) or plan skip_all => 'symlink unsupported';

    local $CWF::Common::SCRATCH_BASE = $link;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my ($d, $err) = scratch_dir('206');
    my $after = (stat($attacker))[2] & 07777;
    chdir $orig;

    is($err, 'symlink_parent', 'symlinked base rejected');
    is($d, undef, 'no path returned');
    ok(-l $link, 'base left as a symlink (not followed/replaced)');
    is($after, $before, 'attacker target mode unchanged (no auto-chmod)');
};

subtest 'TC-12: absent base + parent both created at 0700 (two-level)' => sub {
    plan tests => 4;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    # SCRATCH_BASE points one level below an existing tempdir, so it does not yet
    # exist — scratch_dir must create the base, then the cwf<dash> parent, then
    # the leaf. This is the off-sandbox "create the base" path.
    my $sbase = File::Spec->catdir(tempdir(CLEANUP => 1), 'claude-x');
    local $CWF::Common::SCRATCH_BASE = $sbase;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my $root = CWF::Common::find_git_root();
    my ($scratch, $err) = scratch_dir('206');
    chdir $orig;

    my $parent = "$sbase/cwf" . dash($root);
    is($err, undef, 'no error creating an absent base');
    ok(-d $scratch, 'leaf created');
    is(((stat($sbase))[2]  & 07777), 0700, 'intermediate base mode 0700');
    is(((stat($parent))[2] & 07777), 0700, 'cwf<dash> parent mode 0700');
};

subtest 'TC-13: scratch_fail_hint names the base for base-related kinds only' => sub {
    plan tests => 6;
    local $CWF::Common::SCRATCH_BASE = '/tmp/claude-TESTBASE';

    like(scratch_fail_hint('mkdir_failed'), qr/\Q$CWF::Common::SCRATCH_BASE\E/,
        'mkdir_failed hint names the base');
    like(scratch_fail_hint('symlink_parent'), qr/\Q$CWF::Common::SCRATCH_BASE\E/,
        'symlink_parent hint names the base');
    is(scratch_fail_hint('bad_num'),    '', 'bad_num -> no hint');
    is(scratch_fail_hint('not_a_repo'), '', 'not_a_repo -> no hint');
    is(scratch_fail_hint(''),           '', "'' -> no hint");
    is(scratch_fail_hint(undef),        '', 'undef -> no hint');
};
