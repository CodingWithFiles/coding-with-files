#!/usr/bin/env perl
#
# skill-root-anchor.t — Task 204. Verifies the repo-root anchor idiom that each
# CWF skill runs as its first Bash action: it makes the shell cwd the MAIN repo
# root so subsequent relative `.cwf/...` calls resolve from any cwd; it is a no-op
# at root; it is worktree-safe (anchors to the MAIN root, like find_git_root); and
# it is a tolerant no-op outside a git repo (never `cd ""` to a wrong target).
#
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use Cwd qw(abs_path);
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use CWFTest::Fixtures qw(create_git_repo);

# The canonical anchor idiom — byte-identical to the block inserted into skills.
my $ANCHOR = <<'SH';
gcd=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
if [ -n "$gcd" ]; then r=$(cd "$(dirname "$gcd")" && pwd); [ "$PWD" = "$r" ] || cd "$r"; fi
SH

# Write a script that runs the anchor then prints the resulting pwd; return path.
sub anchor_pwd_script {
    my ($base) = @_;
    my $p = "$base/anchor-pwd.sh";
    open(my $fh, '>', $p) or die $!;
    print $fh $ANCHOR, "pwd\n";
    close $fh;
    return $p;
}

# Run a shell script file with cwd = $cwd; return ($exit, $stdout chomped).
sub sh_in {
    my ($cwd, $script_file) = @_;
    my $out = "$cwd/.anchor.out";
    my $rc  = system("cd '$cwd' && sh '$script_file' >'$out' 2>/dev/null");
    open(my $fh, '<', $out) or return ($rc >> 8, '');
    my $o = do { local $/; <$fh> };
    close $fh;
    chomp $o;
    return ($rc >> 8, $o);
}

# Add a runnable probe at .cwf/scripts/hooks/probe in $repo.
sub add_probe {
    my ($repo) = @_;
    make_path("$repo/.cwf/scripts/hooks");
    my $p = "$repo/.cwf/scripts/hooks/probe";
    open(my $fh, '>', $p) or die $!;
    print $fh "#!/bin/sh\necho probe-ran\n";
    close $fh;
    chmod 0755, $p;
}

plan tests => 4;

subtest 'TC-1: at repo root the anchor is a no-op' => sub {
    plan tests => 1;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base) or do { plan skip_all => 'git unavailable'; return };
    my (undef, $pwd) = sh_in($repo, anchor_pwd_script($base));
    is(abs_path($pwd), abs_path($repo), 'cwd unchanged (still repo root)');
};

subtest 'TC-2: from a subdir — relative call fails, then succeeds after the anchor' => sub {
    plan tests => 2;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base) or do { plan skip_all => 'git unavailable'; return };
    add_probe($repo);
    my $sub = "$repo/implementation-guide/204-x";
    make_path($sub);
    # (a) bare relative call from the subdir → not found (the bug)
    my $rc_bare = system("cd '$sub' && .cwf/scripts/hooks/probe >/dev/null 2>&1") >> 8;
    isnt($rc_bare, 0, 'bare relative .cwf call fails from a subdir (exit non-zero)');
    # (b) anchor, then the same relative call → runs (two-halves regression)
    my $f = "$base/anchor-call.sh";
    open(my $fh, '>', $f) or die $!;
    print $fh $ANCHOR, ".cwf/scripts/hooks/probe\n";
    close $fh;
    my ($rc2, $out2) = sh_in($sub, $f);
    is("$rc2|$out2", "0|probe-ran", 'anchor-then-relative-call succeeds and runs the probe');
};

subtest 'TC-3: from a linked worktree the anchor resolves the MAIN root' => sub {
    plan tests => 1;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base) or do { plan skip_all => 'git unavailable'; return };
    my $wt = "$base/wt";
    system("git -C '$repo' worktree add -q '$wt' -b wtb") == 0
        or do { plan skip_all => 'git worktree unavailable'; return };
    my (undef, $pwd) = sh_in($wt, anchor_pwd_script($base));
    is(abs_path($pwd), abs_path($repo), 'anchored to MAIN root, not the worktree');
};

subtest 'TC-4: outside any git repo the anchor is a tolerant no-op' => sub {
    plan tests => 1;
    my $base = tempdir(CLEANUP => 1);
    my $non  = "$base/notrepo";
    make_path($non);
    my (undef, $pwd) = sh_in($non, anchor_pwd_script($base));
    is(abs_path($pwd), abs_path($non), 'cwd unchanged outside a git repo (no cd "")');
};

done_testing();
