#!/usr/bin/env perl
#
# install-bash-reinstall.t — Task 158. Two install.bash defects + one doc drift.
#
#   item 1: the CWF_FORCE force-reinstall removal commit hard-coded the full
#           pathspec (.cwf .cwf-skills .cwf-rules .cwf-agents). When a pre-state
#           lacked one of them, `git commit -- <missing>` failed, `|| true`
#           swallowed it, and the staged deletions of the *other* dirs were left
#           in the index, breaking the subsequent `git subtree add`. The fix
#           commits only the dirs actually `git rm`'d.
#   item 2: post_install never merged .claude/settings.json, so a raw
#           `CWF_FORCE=1 bash install.bash` migration (no /cwf-init or
#           `cwf-manage update` caller) never landed PERL5OPT/allowlist. The fix
#           invokes cwf-claude-settings-merge (`-x` guarded, before the version
#           write), mirroring cwf-manage's run_settings_merge.
#   item 3: security-review.md §Pathspec coverage omitted .claude/agents/, which
#           the helper's @CWF_INTERNAL_PREFIXES already includes.
#
# E2E cases reuse the Task-155 fixture-server pattern (t/cwf-manage-update-end-to-end.t).
#
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir tempfile);
use File::Find ();
use Cwd qw(getcwd);

my $REPO_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $INSTALL   = "$REPO_ROOT/scripts/install.bash";

# Deterministic git identity for the commits install.bash makes.
local $ENV{GIT_AUTHOR_NAME}     = 'CWF Test';
local $ENV{GIT_AUTHOR_EMAIL}    = 'test@example.invalid';
local $ENV{GIT_COMMITTER_NAME}  = 'CWF Test';
local $ENV{GIT_COMMITTER_EMAIL} = 'test@example.invalid';

my $bash_ok = `bash -c 'echo \$BASH_VERSINFO' 2>/dev/null`;
chomp $bash_ok;
plan skip_all => 'bash 4+ required for install.bash' unless defined $bash_ok && $bash_ok >= 4;

my $REAL_GIT = `sh -c 'command -v git'`;
chomp $REAL_GIT;
plan skip_all => 'git not found' unless length $REAL_GIT && -x $REAL_GIT;

# --- harness (mirrors t/cwf-manage-update-end-to-end.t) -----------------------

sub run {
    my (%a) = @_;            # cmd => [...], dir => path (optional)
    my $cwd = getcwd();
    chdir $a{dir} if $a{dir};

    my ($tfh, $tname) = tempfile(UNLINK => 1);
    close $tfh;
    open(my $savout, '>&', \*STDOUT) or die "save stdout: $!";
    open(my $saverr, '>&', \*STDERR) or die "save stderr: $!";
    open(STDOUT, '>',  $tname)        or die "redirect stdout: $!";
    open(STDERR, '>&', \*STDOUT)      or die "redirect stderr: $!";

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
    # Tracked scripts ship read-only (0500); overwriting a copied fixture script
    # would die "Permission denied". Make it writable first.
    chmod((stat($path))[2] & 07777 | 0200, $path) if -e $path;
    open my $fh, '>', $path or die "write $path: $!";
    print $fh $content;
    close $fh;
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
    return $out;
}

# Build a CWF-shaped upstream source repo with a single v0.0.1 tag.
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

# Fresh consumer git repo with one initial commit.
sub fresh_consumer {
    my ($consumer) = @_;
    system('mkdir', '-p', $consumer) == 0 or die "mkdir $consumer";
    git_ok($consumer, 'init', '-q');
    write_file("$consumer/README.md", "consumer\n");
    git_ok($consumer, 'add', 'README.md');
    git_ok($consumer, 'commit', '-q', '-m', 'initial');
    return $consumer;
}

# Run install.bash in $consumer against $upstream. %opt: force, method, ref,
# path_prepend (a dir prepended to PATH for the run only).
sub do_install {
    my ($consumer, $upstream, %opt) = @_;
    local $ENV{CWF_METHOD} = $opt{method} // 'subtree';
    local $ENV{CWF_SOURCE} = "file://$upstream";
    local $ENV{CWF_REF}    = $opt{ref}    // 'v0.0.1';
    local $ENV{CWF_FORCE}  = $opt{force} ? '1' : '0';
    local $ENV{PATH}       = "$opt{path_prepend}:$ENV{PATH}" if $opt{path_prepend};
    return run(cmd => ['bash', $INSTALL], dir => $consumer);
}

# Build a consumer whose tracked pre-state contains the named CWF dirs (each
# with one tracked file), committed. Mimics an older copy install.
sub seed_tracked_dirs {
    my ($consumer, @dirs) = @_;
    for my $d (@dirs) {
        write_file("$consumer/$d/placeholder.txt", "old install\n");
    }
    git_ok($consumer, 'add', '-A');
    git_ok($consumer, 'commit', '-q', '-m', 'pre-existing CWF install');
}

#==============================================================================

subtest 'TC-1 (item 1): reinstall with .cwf-agents absent completes cleanly' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $consumer = fresh_consumer("$base/consumer");

    # Pre-state lacks .cwf-agents (the reported trigger).
    seed_tracked_dirs($consumer, '.cwf', '.cwf-skills', '.cwf-rules');

    my ($rc, $out) = do_install($consumer, $upstream, force => 1, method => 'subtree');
    is($rc, 0, 'force subtree reinstall succeeds with a CWF dir absent') or diag $out;

    for my $d ('.cwf', '.cwf-skills', '.cwf-rules', '.cwf-agents') {
        ok(-d "$consumer/$d", "$d present after reinstall");
        ok(length git_ok($consumer, 'ls-files', $d), "$d tracked (subtree add committed it)");
    }
    # The subtree adds each commit, so a clean run leaves the index == HEAD.
    # Leftover staged CWF *deletions* (the bug) would show here. (post_install
    # artefacts — settings.json, symlinks, .cwf/version — are untracked and
    # expected; the consumer commits them, as in t/cwf-manage-update-end-to-end.t.)
    my $staged = git_ok($consumer, 'diff', '--cached', '--name-only');
    is($staged, '', 'no leftover staged changes after the reinstall (clean index for subtree add)')
        or diag "staged:\n$staged";
    # Sanity guard for the rejected Option A: rules-inject.txt ships populated
    # in the .cwf subtree, so a reinstall lays it down populated (it is not
    # emptied). See c-design-plan Resolved Decision.
    ok(-s "$consumer/.cwf/rules-inject.txt", '.cwf/rules-inject.txt non-empty after reinstall');
};

subtest 'TC-3 (item 1, edge): mixed tracked/untracked pre-state' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $consumer = fresh_consumer("$base/consumer");

    seed_tracked_dirs($consumer, '.cwf', '.cwf-skills', '.cwf-rules', '.cwf-agents');
    # Add an untracked file inside a tracked CWF dir.
    write_file("$consumer/.cwf/untracked.txt", "not in index\n");

    my ($rc, $out) = do_install($consumer, $upstream, force => 1, method => 'subtree');
    is($rc, 0, 'reinstall succeeds with mixed tracked/untracked pre-state') or diag $out;
    ok(! -e "$consumer/.cwf/untracked.txt", 'stale untracked file removed by the force block');
    my $staged = git_ok($consumer, 'diff', '--cached', '--name-only');
    is($staged, '', 'no leftover staged changes after the reinstall') or diag "staged:\n$staged";
};

subtest 'TC-2 (item 1, failure path): tracked-dir git-rm failure aborts via die' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $consumer = fresh_consumer("$base/consumer");
    seed_tracked_dirs($consumer, '.cwf');

    # A fake `git` that fails the `rm` subcommand without touching the index
    # (so the dir stays tracked) and passes everything else through to real git.
    # This deterministically exercises the "tracked but git rm failed" branch
    # regardless of platform or uid.
    my $shim_dir = "$base/shim";
    system('mkdir', '-p', $shim_dir) == 0 or die "mkdir shim";
    write_file("$shim_dir/git",
        "#!/usr/bin/env bash\n"
      . "if [[ \"\${1:-}\" == \"rm\" ]]; then\n"
      . "  echo 'fatal: simulated git rm failure' >&2\n"
      . "  exit 1\n"
      . "fi\n"
      . "exec $REAL_GIT \"\$@\"\n");
    chmod 0755, "$shim_dir/git" or die "chmod shim: $!";

    my ($rc, $out) = do_install($consumer, $upstream,
        force => 1, method => 'subtree', path_prepend => $shim_dir);
    isnt($rc, 0, 'install aborts when a tracked dir cannot be git-rm-removed');
    like($out, qr/\[CWF\] ERROR:.*git rm failed for tracked/,
        'die names the tracked-dir git-rm failure (the removed `|| true` no longer hides it)');
};

subtest 'TC-4 (item 2): settings-merge applied on a fresh install (no /cwf-init)' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $consumer = fresh_consumer("$base/consumer");

    my ($rc, $out) = do_install($consumer, $upstream, method => 'subtree');
    is($rc, 0, 'fresh subtree install succeeds') or diag $out;

    my $settings = slurp("$consumer/.claude/settings.json");
    ok(defined $settings, '.claude/settings.json written by install.bash');
    like($settings // '', qr/"PERL5OPT"\s*:\s*"-CDSLA"/,
        'env.PERL5OPT merged without a /cwf-init or cwf-manage update caller');
    like($settings // '', qr/Bash\(\.cwf\/scripts\/cwf-manage/,
        'Bash allowlist entries merged');
};

subtest 'TC-5 (item 2, failure path): merge failure aborts before version write' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $consumer = fresh_consumer("$base/consumer");

    # Replace the merge helper with a stub that fails, tag a new release.
    my $helper = "$upstream/.cwf/scripts/command-helpers/cwf-claude-settings-merge";
    write_file($helper, "#!/usr/bin/env bash\nexit 1\n");
    chmod 0755, $helper or die "chmod helper: $!";
    git_ok($upstream, 'add', '-A');
    git_ok($upstream, 'commit', '-q', '-m', 'release v0.0.2 (failing settings-merge)');
    git_ok($upstream, 'tag', 'v0.0.2');

    my ($rc, $out) = do_install($consumer, $upstream, method => 'subtree', ref => 'v0.0.2');
    isnt($rc, 0, 'install aborts when settings-merge fails');
    like($out, qr/\[CWF\] ERROR:.*cwf-claude-settings-merge failed/, 'merge failure diagnosed');
    ok(! -e "$consumer/.cwf/version", '.cwf/version NOT written on merge-failure abort');
    unlike($out, qr/installed successfully/, 'success not logged on abort');
};

subtest 'TC-6 (item 2, guard): missing merge helper is tolerated' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $consumer = fresh_consumer("$base/consumer");

    # Simulate an install predating the helper: remove it, tag a new release.
    unlink "$upstream/.cwf/scripts/command-helpers/cwf-claude-settings-merge"
        or die "unlink helper: $!";
    git_ok($upstream, 'add', '-A');
    git_ok($upstream, 'commit', '-q', '-m', 'release v0.0.2 (no settings-merge helper)');
    git_ok($upstream, 'tag', 'v0.0.2');

    my ($rc, $out) = do_install($consumer, $upstream, method => 'subtree', ref => 'v0.0.2');
    is($rc, 0, 'install completes when the merge helper is absent (-x guard skips it)') or diag $out;
    ok(-e "$consumer/.cwf/version", '.cwf/version written (install reached completion)');
};

subtest 'TC-7 (item 3): security-review.md doc lists every helper prefix' => sub {
    my $helper_src = slurp("$REPO_ROOT/.cwf/scripts/command-helpers/security-review-changeset");
    my $doc_src    = slurp("$REPO_ROOT/.cwf/docs/skills/security-review.md");
    ok(defined $helper_src && defined $doc_src, 'helper and doc both readable') or return;

    # Helper prefixes: the quoted entries inside @CWF_INTERNAL_PREFIXES = ( ... );
    my ($block) = $helper_src =~ /\@CWF_INTERNAL_PREFIXES\s*=\s*\((.*?)\)\s*;/s;
    ok(defined $block, 'parsed @CWF_INTERNAL_PREFIXES block') or return;
    my @helper_prefixes = $block =~ /'([^']+)'/g;
    cmp_ok(scalar @helper_prefixes, '>=', 9, 'helper enumerates the expected prefixes');

    # Doc prefixes: backtick-quoted tokens ending in '/' in the coverage prose.
    my %doc = map { $_ => 1 } ($doc_src =~ /`(\.[^`]+?\/)`/g);

    for my $p (@helper_prefixes) {
        ok($doc{$p}, "doc enumerates $p");
    }
};

# Structural listing of a tree: sorted "kind relpath" lines (l=symlink, d=dir,
# f=file). Used to compare copy- vs subtree-produced trees (TC-6).
sub tree_list {
    my ($root) = @_;
    return '' unless -d $root;
    my @rel;
    File::Find::find({
        no_chdir => 1,
        wanted => sub {
            return if $_ eq $root;
            (my $r = $_) =~ s{^\Q$root\E/}{};
            my $kind = -l $_ ? 'l' : (-d _ ? 'd' : 'f');
            push @rel, "$kind $r";
        },
    }, $root);
    return join("\n", sort @rel);
}

# Plant escaping symlinks under the upstream's .cwf/ and re-point the tag, so a
# subsequent install of that ref sees a tainted source. @links are link=>target.
sub taint_upstream {
    my ($upstream, $tag, %links) = @_;
    for my $name (keys %links) {
        symlink($links{$name}, "$upstream/.cwf/$name") or die "symlink $name: $!";
    }
    git_ok($upstream, 'add', '-A');
    git_ok($upstream, 'commit', '-q', '-m', 'plant escaping symlink(s)');
    git_ok($upstream, 'tag', '-f', $tag);
}

subtest 'TC-3 (Task 161): fresh copy install refuses an escaping upstream symlink' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $consumer = fresh_consumer("$base/consumer");

    taint_upstream($upstream, 'v0.0.1',
        'abs-leak' => '/etc/passwd',                 # absolute target
        'rel-leak' => '../../../../../etc/passwd');  # ..-escape

    my ($rc, $out) = do_install($consumer, $upstream, method => 'copy');
    isnt($rc, 0, 'fresh copy install aborts on an escaping upstream symlink');
    like($out, qr/out-of-tree symlink/, 'guard message surfaced');
    ok(! -e "$consumer/.cwf", 'no .cwf laid down — refused before any cp -r');
};

subtest 'TC-4 (Task 161): existing install survives a refused copy source (guard before rm -rf)' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $consumer = fresh_consumer("$base/consumer");

    # 1) A clean copy install establishes an existing .cwf/, plus a sentinel.
    my ($rc1, $out1) = do_install($consumer, $upstream, method => 'copy', force => 1);
    is($rc1, 0, 'initial clean copy install succeeds') or diag $out1;
    ok(-d "$consumer/.cwf", '.cwf present after the initial install');
    write_file("$consumer/.cwf/SENTINEL", "preserve me\n");

    # 2) Taint the upstream, then force a re-install over the existing tree.
    #    CWF_FORCE=1 means install_copy would rm -rf — but the guard must fire
    #    first, so the existing install is left intact (the blocking-finding
    #    regression guard).
    taint_upstream($upstream, 'v0.0.1', 'leak' => '/etc/passwd');

    my ($rc2, $out2) = do_install($consumer, $upstream, method => 'copy', force => 1);
    isnt($rc2, 0, 'forced re-install aborts on the escaping source');
    like($out2, qr/out-of-tree symlink/, 'guard message surfaced');
    ok(-d "$consumer/.cwf", 'existing .cwf still present (guard ran before rm -rf)');
    ok(-e "$consumer/.cwf/SENTINEL", 'pre-existing install file survived the refused update');
};

subtest 'TC-6 (Task 161): copy and subtree installs produce a matching .cwf-rules + rules symlinks' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream");
    my $con_copy = fresh_consumer("$base/con_copy");
    my $con_sub  = fresh_consumer("$base/con_sub");

    my ($rcc, $oc) = do_install($con_copy, $upstream, method => 'copy');
    my ($rcs, $os) = do_install($con_sub,  $upstream, method => 'subtree');
    is($rcc, 0, 'copy install succeeds')    or diag $oc;
    is($rcs, 0, 'subtree install succeeds') or diag $os;

    is(tree_list("$con_copy/.cwf-rules"), tree_list("$con_sub/.cwf-rules"),
        '.cwf-rules structure identical across methods (no double-handling)');
    is(tree_list("$con_copy/.claude/rules"), tree_list("$con_sub/.claude/rules"),
        '.claude/rules symlink set identical across methods');
    ok(-l "$con_copy/.claude/rules/cwf-workflow-files.md", 'copy: rules entry is a symlink');
    ok(-l "$con_sub/.claude/rules/cwf-workflow-files.md",  'subtree: rules entry is a symlink');
};

done_testing();
