#!/usr/bin/env perl
#
# cwf-detect-merges.t — Task 185. Unit tests for the read-only merge-commit
# detector (FR5/FR6).
#
#   TC-8 (AC5): total / CWF-subset counts, with under-claim on ambiguity.
#   TC-9 (AC6): advisory only — no history rewrite, counts-only output (no raw
#               commit subjects echoed), names re-linearisation + maintainer,
#               exit 0.
#
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir tempfile);
use Cwd qw(getcwd);

my $REPO_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $HELPER    = "$REPO_ROOT/.cwf/scripts/command-helpers/cwf-detect-merges";

my $REAL_GIT = `sh -c 'command -v git'`;
chomp $REAL_GIT;
plan skip_all => 'git not found' unless length $REAL_GIT && -x $REAL_GIT;
plan skip_all => 'git subtree not available'
    unless system("git subtree --help >/dev/null 2>&1") == 0;

# --- harness ------------------------------------------------------------------

sub run {
    my (@cmd) = @_;                      # list-form: args with spaces stay intact
    my ($tfh, $tname) = tempfile(UNLINK => 1);
    close $tfh;
    open(my $savout, '>&', \*STDOUT) or die "save stdout: $!";
    open(my $saverr, '>&', \*STDERR) or die "save stderr: $!";
    open(STDOUT, '>',  $tname)       or die "redirect stdout: $!";
    open(STDERR, '>&', \*STDOUT)     or die "redirect stderr: $!";
    my $rc = system(@cmd);
    open(STDOUT, '>&', $savout) or die "restore stdout: $!";
    open(STDERR, '>&', $saverr) or die "restore stderr: $!";
    open my $rfh, '<:raw', $tname; local $/; my $out = <$rfh>; close $rfh;
    unlink $tname;
    return ($rc >> 8, $out // '');
}

# git in $dir with a deterministic, isolated identity.
sub git {
    my ($dir, @args) = @_;
    my @id = ('-c', 'user.email=t@t', '-c', 'user.name=t',
              '-c', 'commit.gpgsign=false', '-c', 'init.defaultBranch=main');
    my ($rc, $out) = run('git', '-C', $dir, @id, @args);
    die "git @args failed (rc=$rc): $out" if $rc;
    return $out;
}

sub write_file {
    my ($path, $c) = @_;
    (my $d = $path) =~ s{/[^/]+$}{};
    system('mkdir', '-p', $d) if length $d;
    open my $fh, '>', $path or die "write $path: $!";
    print $fh $c; close $fh;
}

# A throwaway source repo whose .cwf/ tree can be subtree-added.
sub make_source {
    my ($dir) = @_;
    write_file("$dir/.cwf/a.txt", "core\n");
    git($dir, 'init', '-q');
    git($dir, 'add', '-A');
    git($dir, 'commit', '-q', '-m', 'source v1');
    return git($dir, 'rev-parse', '--abbrev-ref', 'HEAD') =~ s/\s+//gr;
}

# Add a real `git subtree add --squash` merge (the legacy CWF install shape) at
# $prefix, with the CWF subject for $area.
sub add_cwf_subtree_merge {
    my ($con, $src, $srcbr, $prefix, $area) = @_;
    git($con, 'subtree', 'add', "--prefix=$prefix", $src, $srcbr,
        '--squash', '-m', "Add CWF $area (v1.0)");
}

# Add an ordinary --no-ff merge with an arbitrary subject (not a subtree squash).
sub add_plain_merge {
    my ($con, $branch, $file, $subject) = @_;
    git($con, 'checkout', '-q', '-b', $branch);
    write_file("$con/$file", "x\n");
    git($con, 'add', '-A');
    git($con, 'commit', '-q', '-m', "work on $branch");
    git($con, 'checkout', '-q', 'main');
    git($con, 'merge', '-q', '--no-ff', $branch, '-m', $subject);
}

#==============================================================================

subtest 'TC-8 (AC5): total / CWF-subset / under-claim' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $src  = "$base/src";
    my $srcbr = make_source($src);

    my $con = "$base/con";
    system('mkdir', '-p', $con);
    git($con, 'init', '-q');
    write_file("$con/README.md", "proj\n");
    git($con, 'add', '-A');
    git($con, 'commit', '-q', '-m', 'initial');

    # Two real CWF subtree merges (fingerprinted: subject + squash 2nd parent).
    add_cwf_subtree_merge($con, $src, $srcbr, '.cwf',        'core');
    add_cwf_subtree_merge($con, $src, $srcbr, '.cwf-skills', 'skills');

    # One unrelated real merge (not a CWF subject, not a subtree squash).
    add_plain_merge($con, 'feature', 'feature.txt', "Merge branch 'feature'");

    # One ambiguous merge: CWF-style subject but NO subtree-squash second parent.
    # Must be UNDER-CLAIMED — counted in total, never in the CWF subset.
    add_plain_merge($con, 'decoy', 'decoy.txt', 'Add CWF core (totally not a subtree)');

    my ($rc, $out) = run($HELPER, $con);
    is($rc, 0, 'helper exits 0');
    like($out, qr/Merge commits on this branch: 4 total\./, 'total counts all four merges');
    like($out, qr/2 originate from old CWF subtree installs/, 'CWF subset is the two fingerprinted merges');
    like($out, qr/2 are from elsewhere/, 'the unrelated + ambiguous merges land in "elsewhere"');
};

subtest 'TC-9 (AC6): advisory only — no rewrite, counts-only, exit 0' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $src  = "$base/src";
    my $srcbr = make_source($src);

    my $con = "$base/con";
    system('mkdir', '-p', $con);
    git($con, 'init', '-q');
    write_file("$con/README.md", "proj\n");
    git($con, 'add', '-A');
    git($con, 'commit', '-q', '-m', 'initial');
    add_cwf_subtree_merge($con, $src, $srcbr, '.cwf', 'core');

    my $head_before = git($con, 'rev-parse', 'HEAD') =~ s/\s+//gr;
    my ($rc, $out) = run($HELPER, $con);
    my $head_after  = git($con, 'rev-parse', 'HEAD') =~ s/\s+//gr;

    is($rc, 0, 'exit 0 always');
    is($head_after, $head_before, 'repo HEAD unchanged — read-only, no history rewrite');
    # Counts-only: the squash second parent subject ("Squashed '.cwf/' content
    # …") must never be echoed into the report.
    unlike($out, qr/Squashed '/, 'raw squash commit subject never echoed (counts-only)');
    like($out, qr/re-linearisation/, 'names re-linearisation as the (optional) remedy');
    like($out, qr/maintainer/, 'points the user at the maintainer');

    # An empty (linear) repo reports no merges and still exits 0.
    my $lin = "$base/linear";
    system('mkdir', '-p', $lin);
    git($lin, 'init', '-q');
    write_file("$lin/x", "x\n");
    git($lin, 'add', '-A');
    git($lin, 'commit', '-q', '-m', 'only commit');
    my ($rc2, $out2) = run($HELPER, $lin);
    is($rc2, 0, 'linear repo: exit 0');
    like($out2, qr/No merge commits/, 'linear repo: reports none');
};

done_testing();
