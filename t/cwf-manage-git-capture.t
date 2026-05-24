#!/usr/bin/env perl
#
# cwf-manage-git-capture.t — Unit tests for git_capture and git_describe_version
# (Task 159: FR4 backtick→list-form conversion, FR1 cwf_version derivation).
#
# Loads cwf-manage via do() with @ARGV = ('help') so main() runs harmlessly,
# then calls the two helpers directly against throwaway git repos. No network.
#
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use Cwd qw(getcwd abs_path);
use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib');

my $SCRIPT = File::Spec->catfile(
    $FindBin::Bin, '..', '.cwf', 'scripts', 'cwf-manage'
);

# Deterministic git identity for the throwaway repos built below.
local $ENV{GIT_AUTHOR_NAME}     = 'CWF Test';
local $ENV{GIT_AUTHOR_EMAIL}    = 'test@example.invalid';
local $ENV{GIT_COMMITTER_NAME}  = 'CWF Test';
local $ENV{GIT_COMMITTER_EMAIL} = 'test@example.invalid';

# Load the script. @ARGV = ('help') keeps main() side-effect-free; silence the
# help banner so prove output stays clean.
{
    local @ARGV = ('help');
    open(my $saved, '>&', \*STDOUT) or die "Cannot dup STDOUT: $!";
    open(STDOUT, '>', File::Spec->devnull()) or die "Cannot silence STDOUT: $!";
    do $SCRIPT;
    open(STDOUT, '>&', $saved) or die "Cannot restore STDOUT: $!";
}
die "Failed to load $SCRIPT: $@" if $@;

# git_in($dir, @args) — run git, die on failure, return trimmed stdout.
sub git_in {
    my ($dir, @args) = @_;
    my $out = `git -C "$dir" @args 2>&1`;
    die "git @args failed: $out" if $?;
    chomp $out;
    return $out;
}

# A repo with a single commit tagged $tag.
sub repo_one_tag {
    my ($tag) = @_;
    my $dir = tempdir(CLEANUP => 1);
    git_in($dir, 'init', '-q');
    open my $fh, '>', "$dir/f" or die $!; print $fh "x\n"; close $fh;
    git_in($dir, 'add', '-A');
    git_in($dir, 'commit', '-q', '-m', 'c1');
    git_in($dir, 'tag', $tag);
    return $dir;
}

#==============================================================================
# git_capture
#==============================================================================

subtest 'git_capture: success returns (lines, 0)' => sub {
    plan tests => 3;
    my $dir = repo_one_tag('v1.2.3');
    my ($out, $rc) = main::git_capture('-C', $dir, 'rev-parse', '--show-toplevel');
    is($rc, 0, 'exit 0 on success');
    is(scalar @$out, 1, 'one line captured');
    is(abs_path($out->[0]), abs_path($dir), 'toplevel resolves to the repo dir');
};

subtest 'git_capture: failure returns non-zero and suppresses stderr' => sub {
    plan tests => 2;
    my $dir = repo_one_tag('v1.2.3');
    # A well-formed but non-existent ref: git writes "fatal: ..." to stderr and
    # exits non-zero. The helper must surface the non-zero exit and must NOT
    # leak git's stderr into the captured stdout (proves stderr→/dev/null).
    my ($out, $rc) = main::git_capture('-C', $dir, 'rev-parse', '--verify', 'zzz-nope');
    isnt($rc, 0, 'non-zero exit on a bad ref');
    unlike(join("\n", @$out), qr/fatal/i, 'git stderr not captured into stdout');
};

#==============================================================================
# git_describe_version
#==============================================================================

subtest 'git_describe_version: SHA on a tag → the tag' => sub {
    plan tests => 1;
    my $dir = repo_one_tag('v1.2.3');
    my $sha = git_in($dir, 'rev-parse', 'HEAD');
    is(main::git_describe_version($dir, $sha), 'v1.2.3', 'exact tag returned');
};

subtest 'git_describe_version: SHA past a tag → long form' => sub {
    plan tests => 1;
    my $dir = repo_one_tag('v1.2.3');
    open my $fh, '>', "$dir/g" or die $!; print $fh "y\n"; close $fh;
    git_in($dir, 'add', '-A');
    git_in($dir, 'commit', '-q', '-m', 'c2');
    my $sha = git_in($dir, 'rev-parse', 'HEAD');
    like(main::git_describe_version($dir, $sha), qr/^v1\.2\.3-\d+-g[0-9a-f]+$/,
        'nearest-ancestor long form (vX.Y.Z-N-gHASH)');
};

subtest 'git_describe_version: no tags reachable → abbreviated SHA (not a ref)' => sub {
    plan tests => 1;
    my $dir = tempdir(CLEANUP => 1);
    git_in($dir, 'init', '-q');
    open my $fh, '>', "$dir/f" or die $!; print $fh "x\n"; close $fh;
    git_in($dir, 'add', '-A');
    git_in($dir, 'commit', '-q', '-m', 'untagged');
    my $sha = git_in($dir, 'rev-parse', 'HEAD');
    like(main::git_describe_version($dir, $sha), qr/^[0-9a-f]{7,}$/,
        '--always yields an abbreviated SHA when no tags exist');
};

subtest 'git_describe_version: bad committish → falls back to the input SHA' => sub {
    plan tests => 1;
    my $dir = repo_one_tag('v1.2.3');
    my $bogus = '0' x 40;   # well-formed but non-existent
    is(main::git_describe_version($dir, $bogus), $bogus,
        'non-zero describe exit returns the input SHA (never empty / never a bare ref)');
};

done_testing();
