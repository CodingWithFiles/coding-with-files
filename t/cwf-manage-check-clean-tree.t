#!/usr/bin/env perl
#
# cwf-manage-check-clean-tree.t — Unit tests for check_clean_tree.
#
# Loads cwf-manage via do() with @ARGV = ('help') so main() runs harmlessly,
# then overrides main::die_msg so failure paths are catchable via eval{}.
#
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib');

my $SCRIPT = File::Spec->catfile(
    $FindBin::Bin, '..', '.cwf', 'scripts', 'cwf-manage'
);

# Load the script. @ARGV = ('help') keeps main() side-effect-free.
{
    local @ARGV = ('help');
    open(my $saved, '>&', \*STDOUT) or die "Cannot dup STDOUT: $!";
    open(STDOUT, '>', File::Spec->devnull()) or die "Cannot silence STDOUT: $!";
    do $SCRIPT;
    open(STDOUT, '>&', $saved) or die "Cannot restore STDOUT: $!";
}
die "Failed to load $SCRIPT: $@" if $@;

# Override die_msg so failure paths are catchable. The original calls exit 1,
# which would terminate the test process before assertions could run.
{
    no warnings 'redefine', 'once';
    *main::die_msg = sub { die "[CWF] ERROR: @_\n" };
}

sub make_baseline_repo {
    my $dir = tempdir(CLEANUP => 1);
    system("git", "-C", $dir, "init", "-q") == 0                                or die "git init failed";
    system("git", "-C", $dir, "config", "user.email", "test\@example.com") == 0 or die "git config failed";
    system("git", "-C", $dir, "config", "user.name",  "Test") == 0              or die "git config failed";
    mkdir "$dir/.cwf" or die $!;
    open my $vfh, '>', "$dir/.cwf/version" or die $!;
    print $vfh "cwf_method=copy\ncwf_source=https://example.com/x.git\ncwf_version=v0.0.1\n";
    close $vfh;
    system("git", "-C", $dir, "add", ".") == 0                       or die "git add failed";
    system("git", "-C", $dir, "commit", "-q", "-m", "init") == 0     or die "git commit failed";
    return $dir;
}

#==============================================================================
# check_clean_tree — pre-flight working-tree dirtiness check
#==============================================================================

subtest 'TC-1: clean tree -> returns without dying' => sub {
    plan tests => 1;
    my $dir = make_baseline_repo();
    eval { main::check_clean_tree($dir) };
    is($@, '', 'no die on clean tree');
};

subtest 'TC-2: dirty tree (tracked + untracked) -> dies, lists both' => sub {
    plan tests => 4;
    my $dir = make_baseline_repo();
    open my $vfh, '>>', "$dir/.cwf/version" or die $!;
    print $vfh "extra=1\n";
    close $vfh;
    open my $nfh, '>',  "$dir/.cwf/notes.md" or die $!;
    print $nfh "scratch\n";
    close $nfh;
    eval { main::check_clean_tree($dir) };
    like($@, qr{Working tree has uncommitted changes}, 'dies with header');
    like($@, qr{\.cwf/version},                         'mentions tracked-modified path');
    like($@, qr{notes\.md},                             'mentions untracked path');
    like($@, qr{git stash},                             'recipe present in message');
};

subtest 'TC-3: git status fails -> dies with check-failure message' => sub {
    plan tests => 1;
    eval { main::check_clean_tree('/nonexistent/path') };
    like($@, qr{Failed to check working tree status}, 'dies on git-status failure');
};

subtest 'TC-4: tree dirty only by .cwf/.update.lock -> returns without dying' => sub {
    plan tests => 1;
    my $dir = make_baseline_repo();
    open my $lfh, '>', "$dir/.cwf/.update.lock" or die $!; close $lfh;
    eval { main::check_clean_tree($dir) };
    is($@, '', 'lock-only tree treated as clean');
};

subtest 'TC-5: lock + real dirty path -> dies, lists real path only' => sub {
    plan tests => 3;
    my $dir = make_baseline_repo();
    open my $lfh, '>', "$dir/.cwf/.update.lock" or die $!; close $lfh;
    open my $nfh, '>', "$dir/.cwf/notes.md" or die $!; print $nfh "scratch\n"; close $nfh;
    eval { main::check_clean_tree($dir) };
    like($@,   qr{Working tree has uncommitted changes}, 'dies on the real dirty path');
    like($@,   qr{notes\.md},                            'lists the real untracked path');
    unlike($@, qr{\.update\.lock},                       'lock excluded from the dirty list');
};

done_testing();
