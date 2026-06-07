#!/usr/bin/env perl
#
# install-bash-read-tree.t — Task 185. The read-tree laydown method.
#
#   TC-1 (AC1): merge-free laydown; each dest prefix tree == mapped source tree;
#               exec mode preserved; laydown is staged, not committed by CWF.
#   TC-2 (AC3): CWF_METHOD=subtree refused with guidance; nothing laid down.
#   TC-3 (AC2): CWF_METHOD=copy installs and records cwf_method=copy.
#   TC-4 (AC9): forced reinstall is deterministic — a stale file under a prefix
#               is gone and the tree matches a clean install; no merge commit.
#   TC-5 (AC8): read-tree path refuses an escaping source symlink, fail-closed,
#               nothing materialised.
#   TC-11:      a second forced read-tree install is idempotent (same tree).
#
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir tempfile);
use Cwd qw(getcwd);

my $REPO_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $INSTALL   = "$REPO_ROOT/scripts/install.bash";

local $ENV{GIT_AUTHOR_NAME}     = 'CWF Test';
local $ENV{GIT_AUTHOR_EMAIL}    = 'test@example.invalid';
local $ENV{GIT_COMMITTER_NAME}  = 'CWF Test';
local $ENV{GIT_COMMITTER_EMAIL} = 'test@example.invalid';

my $bash_ok = `bash -c 'echo \$BASH_VERSINFO' 2>/dev/null`;
chomp $bash_ok;
plan skip_all => 'bash 4+ required for install.bash' unless defined $bash_ok && $bash_ok >= 4;

# --- harness (mirrors t/install-bash-reinstall.t) -----------------------------

sub run {
    my (%a) = @_;
    my $cwd = getcwd();
    chdir $a{dir} if $a{dir};
    my ($tfh, $tname) = tempfile(UNLINK => 1);
    close $tfh;
    open(my $savout, '>&', \*STDOUT) or die "save stdout: $!";
    open(my $saverr, '>&', \*STDERR) or die "save stderr: $!";
    open(STDOUT, '>',  $tname)       or die "redirect stdout: $!";
    open(STDERR, '>&', \*STDOUT)     or die "redirect stderr: $!";
    my $rc = system(@{$a{cmd}});
    open(STDOUT, '>&', $savout) or die "restore stdout: $!";
    open(STDERR, '>&', $saverr) or die "restore stderr: $!";
    chdir $cwd;
    my $buf = slurp($tname) // '';
    unlink $tname;
    return ($rc >> 8, $buf);
}

sub cp_rp { system('cp', '-rp', $_[0], $_[1]) == 0 or die "cp -rp $_[0] $_[1]: $?"; }

sub write_file {
    my ($path, $content) = @_;
    (my $dir = $path) =~ s{/[^/]+$}{};
    system('mkdir', '-p', $dir) if length $dir;
    chmod((stat($path))[2] & 07777 | 0200, $path) if -e $path;
    open my $fh, '>', $path or die "write $path: $!";
    print $fh $content; close $fh;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or return undef;
    local $/; my $c = <$fh>; close $fh; return $c;
}

sub git_ok {
    my ($dir, @args) = @_;
    my ($rc, $out) = run(cmd => ['git', '-C', $dir, @args]);
    die "git @args failed (rc=$rc): $out" if $rc != 0;
    $out =~ s/\s+\z//;
    return $out;
}

sub build_upstream {
    my ($dir) = @_;
    system('mkdir', '-p', $dir) == 0 or die "mkdir $dir";
    git_ok($dir, 'init', '-q');
    cp_rp("$REPO_ROOT/scripts",        "$dir/scripts");
    cp_rp("$REPO_ROOT/.cwf",           "$dir/.cwf");
    system('mkdir', '-p', "$dir/.claude");
    cp_rp("$REPO_ROOT/.claude/skills", "$dir/.claude/skills");
    cp_rp("$REPO_ROOT/.claude/rules",  "$dir/.claude/rules");
    cp_rp("$REPO_ROOT/.claude/agents", "$dir/.claude/agents");
    git_ok($dir, 'add', '-A');
    git_ok($dir, 'commit', '-q', '-m', 'release v0.0.1');
    git_ok($dir, 'tag', 'v0.0.1');
    return $dir;
}

sub fresh_consumer {
    my ($consumer) = @_;
    system('mkdir', '-p', $consumer) == 0 or die "mkdir $consumer";
    git_ok($consumer, 'init', '-q');
    write_file("$consumer/README.md", "consumer\n");
    git_ok($consumer, 'add', 'README.md');
    git_ok($consumer, 'commit', '-q', '-m', 'initial');
    return $consumer;
}

sub do_install {
    my ($consumer, $upstream, %opt) = @_;
    local $ENV{CWF_METHOD} = $opt{method} // 'read-tree';
    local $ENV{CWF_SOURCE} = "file://$upstream";
    local $ENV{CWF_REF}    = $opt{ref} // 'v0.0.1';
    local $ENV{CWF_FORCE}  = $opt{force} ? '1' : '0';
    return run(cmd => ['bash', $INSTALL], dir => $consumer);
}

# Commit everything install.bash staged/wrote, mimicking the consumer's commit.
sub commit_install { git_ok($_[0], 'add', '-A'); git_ok($_[0], 'commit', '-q', '-m', 'Add CWF'); }

# Tree SHA of a subtree currently in the INDEX (no commit needed). Used for
# determinism/idempotence checks that must not be confounded by post_install's
# .cwf/version timestamp (write the index to a tree, then resolve the subtree).
sub staged_subtree {
    my ($repo, $sub) = @_;
    git_ok($repo, 'add', '-A');
    my $tree = git_ok($repo, 'write-tree');
    return git_ok($repo, 'rev-parse', "$tree:$sub");
}

# The source→dest prefix map install_read_tree reproduces.
my %MAP = ('.cwf' => '.cwf', '.claude/skills' => '.cwf-skills',
           '.claude/rules' => '.cwf-rules', '.claude/agents' => '.cwf-agents');

#==============================================================================

subtest 'TC-1 (AC1): read-tree laydown is merge-free + tree-exact' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $consumer = fresh_consumer("$base/consumer");
    my $head_before = git_ok($consumer, 'rev-parse', 'HEAD');

    my ($rc, $out) = do_install($consumer, $upstream, method => 'read-tree');
    is($rc, 0, 'read-tree install succeeds') or diag $out;

    # Laydown is staged, NOT committed by CWF: HEAD is unchanged.
    is(git_ok($consumer, 'rev-parse', 'HEAD'), $head_before,
       'CWF created no commit — laydown left staged for the user');
    isnt(git_ok($consumer, 'diff', '--cached', '--name-only'), '',
       'laydown is present in the index');

    commit_install($consumer);

    # Each dest prefix tree SHA equals its MAPPED source subtree tree SHA. The
    # .cwf prefix is exempt from strict tree equality because post_install
    # writes .cwf/version (provenance) after the laydown — its laydown fidelity
    # is checked via a sentinel blob instead.
    for my $src (sort keys %MAP) {
        next if $src eq '.cwf';
        my $dest = $MAP{$src};
        my $st = git_ok($upstream, 'rev-parse', "v0.0.1:$src");
        my $dt = git_ok($consumer, 'rev-parse', "HEAD:$dest");
        is($dt, $st, "$dest tree == mapped source $src (tree-identity preserved)");
    }
    is(git_ok($consumer, 'rev-parse', 'HEAD:.cwf/scripts/cwf-manage'),
       git_ok($upstream, 'rev-parse', 'v0.0.1:.cwf/scripts/cwf-manage'),
       '.cwf laid down faithfully (sentinel blob identical to source)');

    # Executable mode preserved (git 100755) on a laid-down script.
    like(git_ok($consumer, 'ls-files', '-s', '.cwf/scripts/cwf-manage'),
         qr/^100755 /, 'executable bit preserved on .cwf/scripts/cwf-manage');

    # Merge-free.
    is(git_ok($consumer, 'rev-list', '--merges', "$head_before..HEAD"), '',
       'no merge commit introduced');
    my $parents = git_ok($consumer, 'rev-list', '--parents', '-n1', 'HEAD');
    my @p = split /\s+/, $parents;
    is(scalar(@p) - 1, 1, 'laydown commit has exactly one parent');
};

subtest 'TC-2 (AC3): subtree is refused with guidance' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $consumer = fresh_consumer("$base/consumer");

    my ($rc, $out) = do_install($consumer, $upstream, method => 'subtree');
    isnt($rc, 0, 'CWF_METHOD=subtree exits non-zero');
    like($out, qr/subtree is deprecated/, 'message explains the deprecation');
    like($out, qr/read-tree/, 'message names read-tree (primary)');
    like($out, qr/copy/,      'message names copy (fallback)');
    ok(! -e "$consumer/.cwf", 'no .cwf laid down — refused at method validation');
};

subtest 'TC-3 (AC2): copy installs and records cwf_method=copy' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $consumer = fresh_consumer("$base/consumer");

    my ($rc, $out) = do_install($consumer, $upstream, method => 'copy');
    is($rc, 0, 'copy install succeeds') or diag $out;
    like(slurp("$consumer/.cwf/version") // '', qr/^cwf_method=copy$/m,
         '.cwf/version records cwf_method=copy');
};

subtest 'TC-4 (AC9) + TC-11: forced reinstall is deterministic and idempotent' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $consumer = fresh_consumer("$base/consumer");

    # First clean install, committed; record the canonical .cwf-skills tree
    # (no post_install mutation, so it is deterministic across installs — unlike
    # .cwf, which carries the version timestamp).
    my ($rc1, $o1) = do_install($consumer, $upstream, method => 'read-tree');
    is($rc1, 0, 'initial read-tree install succeeds') or diag $o1;
    commit_install($consumer);
    my $clean_skills = git_ok($consumer, 'rev-parse', 'HEAD:.cwf-skills');

    # Plant a stale tracked file under a prefix, commit it.
    write_file("$consumer/.cwf/STALE.txt", "leftover from an older install\n");
    git_ok($consumer, 'add', '-A');
    git_ok($consumer, 'commit', '-q', '-m', 'stale file');
    my $base_head = git_ok($consumer, 'rev-parse', 'HEAD');

    # Forced reinstall: the unconditional clear must drop the stale file.
    my ($rc2, $o2) = do_install($consumer, $upstream, method => 'read-tree', force => 1);
    is($rc2, 0, 'forced reinstall succeeds') or diag $o2;

    ok(! -e "$consumer/.cwf/STALE.txt", 'stale file removed by the unconditional clear');
    is(staged_subtree($consumer, '.cwf-skills'), $clean_skills,
       '.cwf-skills tree byte-identical to a clean install (deterministic)');
    commit_install($consumer);
    is(git_ok($consumer, 'rev-list', '--merges', "$base_head..HEAD"), '',
       'forced reinstall introduces no merge commit');

    # TC-11: a further forced reinstall is idempotent (staged tree unchanged).
    my ($rc3, $o3) = do_install($consumer, $upstream, method => 'read-tree', force => 1);
    is($rc3, 0, 'second forced reinstall succeeds') or diag $o3;
    is(staged_subtree($consumer, '.cwf-skills'), $clean_skills,
       're-run is idempotent — .cwf-skills tree still matches the clean install');
};

subtest 'TC-5 (AC8): read-tree refuses an escaping source symlink (fail-closed)' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $consumer = fresh_consumer("$base/consumer");

    # Plant an out-of-tree symlink under the upstream's .cwf/ and re-point the tag.
    symlink('/etc/passwd', "$upstream/.cwf/leak") or die "symlink: $!";
    git_ok($upstream, 'add', '-A');
    git_ok($upstream, 'commit', '-q', '-m', 'plant escaping symlink');
    git_ok($upstream, 'tag', '-f', 'v0.0.1');

    my ($rc, $out) = do_install($consumer, $upstream, method => 'read-tree');
    isnt($rc, 0, 'read-tree install aborts on an escaping source symlink');
    like($out, qr/out-of-tree symlink/, 'guard message surfaced');
    ok(! -e "$consumer/.cwf", 'nothing materialised — refused before laydown (fail-closed)');
};

done_testing();
