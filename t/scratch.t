#!/usr/bin/env perl
#
# scratch.t - Unit tests for CWF::Common::scratch_parent / scratch_dir (Task 206).
#
# scratch_parent: pure, $num-free, NO filesystem (used by the context-inject
# hook every turn). scratch_dir: scratch_parent + per-task leaf + the tmp-paths
# symlink-attack defences (used by writers, e.g. security-review-changeset).
#
# Covers (e-testing-plan TC-1..TC-8):
#   TC-1 scratch_parent happy path     -> byte-identical to the tmp-paths snippet form
#   TC-2 worktree main-root            -> parent uses MAIN root, not the worktree
#   TC-3 not_a_repo                    -> (undef,'not_a_repo'); no filesystem
#   TC-4 scratch_dir happy path        -> ("<parent>/task-<num>", undef), mode 0700
#   TC-5 bad_num rejects + NO FS work  -> (undef,'bad_num'); nothing created
#   TC-6 leading-zero accepted         -> success (contract locked)
#   TC-7 symlink-parent reject, no chmod
#   TC-8 idempotent re-call            -> success, mode unchanged
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
use CWF::Common qw(scratch_parent scratch_dir);
use CWFTest::Fixtures qw(create_git_repo);

plan tests => 8;

# Mirror the tmp-paths.md shell Derivation snippet independently of the function
# under test, so the byte-identity assertion is a genuine cross-check:
#   base="${TMPDIR:-/tmp}"; base="${base%/}"
#   scratch_parent="${base}/cwf${repo_root//\//-}"
sub expected_parent {
    my ($root, $tmpdir) = @_;
    (my $dashed = $root) =~ s{/}{-}g;
    my $base = (defined $tmpdir && length $tmpdir) ? $tmpdir : '/tmp';
    $base =~ s{/+$}{};
    return "$base/cwf$dashed";
}

sub make_repo_with_worktree {
    my $base = shift;
    my $repo = create_git_repo($base);
    return unless defined $repo;
    my $wt = File::Spec->catdir($base, 'wt');
    system('git', '-C', $repo, 'worktree', 'add', '-q', $wt, '-b', 'wtbranch') == 0
        or return;
    return ($repo, $wt);
}

subtest 'TC-1: scratch_parent happy path is byte-identical to the snippet form' => sub {
    plan tests => 2;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    my $sandbox = tempdir(CLEANUP => 1);
    local $ENV{TMPDIR} = $sandbox;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my ($parent, $err) = scratch_parent();
    my $root = CWF::Common::find_git_root();
    chdir $orig;

    is($err, undef, 'no error in a git repo');
    is($parent, expected_parent($root, $sandbox),
        'parent == ${TMPDIR}/cwf<dashified-root> (trailing-slash-stripped base)');
};

subtest 'TC-2: worktree -> parent uses the MAIN root, not the worktree' => sub {
    my $base = tempdir(CLEANUP => 1);
    my ($main, $wt) = make_repo_with_worktree($base);
    plan skip_all => 'git worktree unavailable' unless defined $main;
    plan tests => 1;

    my $sandbox = tempdir(CLEANUP => 1);
    local $ENV{TMPDIR} = $sandbox;
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
    my $sandbox    = tempdir(CLEANUP => 1);
    local $ENV{TMPDIR} = $sandbox;
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

    my $sandbox = tempdir(CLEANUP => 1);
    local $ENV{TMPDIR} = $sandbox;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my ($scratch, $err) = scratch_dir('206');
    my $root = CWF::Common::find_git_root();
    chdir $orig;

    is($err, undef, 'no error');
    is($scratch, expected_parent($root, $sandbox) . '/task-206',
        'leaf == <parent>/task-206');
    is(((stat($scratch))[2] & 07777), 0700, 'leaf mode is 0700');
};

subtest 'TC-5: bad_num rejects with NO filesystem work' => sub {
    my @bad = ('1..2', '..', '', '1/2', 'a', '1.', '.1', '1;rm');
    plan tests => 2 * scalar(@bad);
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    my $sandbox = tempdir(CLEANUP => 1);
    local $ENV{TMPDIR} = $sandbox;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my $parent = expected_parent(CWF::Common::find_git_root(), $sandbox);
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

    my $sandbox = tempdir(CLEANUP => 1);
    local $ENV{TMPDIR} = $sandbox;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my (undef, $e1) = scratch_dir('007');
    my (undef, $e2) = scratch_dir('1.01');
    chdir $orig;

    is($e1, undef, "'007' accepted");
    is($e2, undef, "'1.01' accepted");
};

subtest 'TC-7: symlinked parent rejected, target not chmod-ed' => sub {
    plan tests => 4;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    my $sandbox = tempdir(CLEANUP => 1);
    local $ENV{TMPDIR} = $sandbox;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my $parent = expected_parent(CWF::Common::find_git_root(), $sandbox);

    # Pre-plant the parent as a symlink to an attacker-controlled directory.
    my $attacker = File::Temp::tempdir(CLEANUP => 1);
    chmod 0755, $attacker;
    my $before = (stat($attacker))[2] & 07777;
    symlink($attacker, $parent) or do { chdir $orig; plan skip_all => 'symlink unsupported' };

    my ($d, $err) = scratch_dir('206');
    my $after = (stat($attacker))[2] & 07777;
    chdir $orig;

    is($err, 'symlink_parent', 'symlinked parent rejected');
    is($d, undef, 'no path returned');
    ok(-l $parent, 'parent left as a symlink (not followed/replaced)');
    is($after, $before, 'attacker target mode unchanged (no auto-chmod)');
};

subtest 'TC-8: idempotent re-call -> success, mode unchanged' => sub {
    plan tests => 3;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    my $sandbox = tempdir(CLEANUP => 1);
    local $ENV{TMPDIR} = $sandbox;
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my ($first)  = scratch_dir('206');
    my ($second, $err) = scratch_dir('206');
    chdir $orig;

    is($err, undef, 'second call succeeds');
    is($second, $first, 'same path on re-call');
    is(((stat($second))[2] & 07777), 0700, 'mode still 0700');
};
