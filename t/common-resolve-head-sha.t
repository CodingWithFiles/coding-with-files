#!/usr/bin/env perl
#
# common-resolve-head-sha.t - Unit tests for CWF::Common::resolve_head_sha.
#
# Covers the three repo states the function distinguishes:
#   1. Repo with at least one commit  -> returns 40-char hex SHA
#   2. Empty repo (git init, no commits) -> returns undef
#   3. Not inside a git repo at all      -> returns undef
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
use CWF::Common qw(resolve_head_sha);
use CWFTest::Fixtures qw(create_git_repo);

plan tests => 3;

subtest 'TC-1: repo with a commit -> returns matching 40-char SHA' => sub {
    plan tests => 3;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    ok(defined $repo, 'fixture produced a repo (git is available)');

    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";

    my $sha = resolve_head_sha();
    chdir $orig;

    like($sha, qr/^[0-9a-f]{40}$/, 'returns 40-char lowercase hex');

    # Verify it matches what git itself reports for the same repo.
    my $expected = `git -C '$repo' rev-parse HEAD 2>/dev/null`;
    chomp $expected;
    is($sha, $expected, 'matches git rev-parse HEAD output');
};

subtest 'TC-2: empty repo (no commits) -> undef' => sub {
    plan tests => 1;
    my $repo = tempdir(CLEANUP => 1);
    system('git', '-C', $repo, 'init', '-q') == 0
        or plan skip_all => 'git init failed';

    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";

    my $sha = resolve_head_sha();
    chdir $orig;

    is($sha, undef, 'undef inside empty repo (HEAD ref exists, no commit object)');
};

subtest 'TC-3: outside any git repo -> undef' => sub {
    plan tests => 1;
    # tempdir under TMPDIR is not under any git repo on a clean test host.
    my $not_a_repo = tempdir(CLEANUP => 1);

    my $orig = cwd();
    chdir $not_a_repo or die "chdir $not_a_repo: $!";

    my $sha = resolve_head_sha();
    chdir $orig;

    is($sha, undef, 'undef when no enclosing git repo');
};
