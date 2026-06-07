#!/usr/bin/env perl
#
# cwf-manage-update-end-to-end.t — End-to-end tests for the converged subtree
# update path (Task 155). Builds a real CWF-shaped upstream fixture (a git repo
# containing scripts/install.bash + .cwf/ + .claude/{skills,rules,agents}) with
# multiple version tags, installs it into a consumer repo via install.bash
# (subtree method), then exercises `cwf-manage update` — which now delegates
# laydown back to the *target* ref's install.bash.
#
# Covered: FR2 (target-version laydown), FR3 (no subtree-pull squash conflict
# across a version gap), FR5 (exact perms ⇒ validate passes), FR6 (manifest-SHA
# pin survives a second update), FR9 (ref injection rejected), FR10 / staged-work
# isolation (force-reinstall commit does not sweep unrelated staged work).
#
# Out of scope (per e-testing-plan.md): SIGKILL-during-rename atomicity,
# interactive D/A prompt branches.
#
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir tempfile);
use Cwd qw(getcwd abs_path);

my $REPO_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));

# Deterministic git identity for every child git process (install.bash commits
# during the force remove-then-add). Set in %ENV so all subprocesses inherit.
local $ENV{GIT_AUTHOR_NAME}     = 'CWF Test';
local $ENV{GIT_AUTHOR_EMAIL}    = 'test@example.invalid';
local $ENV{GIT_COMMITTER_NAME}  = 'CWF Test';
local $ENV{GIT_COMMITTER_EMAIL} = 'test@example.invalid';

# Bash 4+ and git are prerequisites of install.bash; skip cleanly if absent.
my $bash_ok = `bash -c 'echo \$BASH_VERSINFO' 2>/dev/null`;
chomp $bash_ok;
plan skip_all => 'bash 4+ required for install.bash' unless defined $bash_ok && $bash_ok >= 4;

sub run {
    my (%a) = @_;            # cmd => [...], dir => path (optional)
    my $cwd = getcwd();
    chdir $a{dir} if $a{dir};

    # Redirect the real fd 1/2 (not just the Perl filehandles) so child
    # processes' output is captured into a temp file. 2>&1 combined.
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
    return ($rc >> 8, $buf, $rc);
}

# Copy a path with cp -rp (preserve perms so recorded perms survive).
sub cp_rp { system('cp', '-rp', $_[0], $_[1]) == 0 or die "cp -rp $_[0] $_[1]: $?"; }

sub write_file {
    my ($path, $content) = @_;
    (my $dir = $path) =~ s{/[^/]+$}{};
    system('mkdir', '-p', $dir) if length $dir;
    open my $fh, '>', $path or die "write $path: $!";
    print $fh $content;
    close $fh;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or return undef;
    local $/; my $c = <$fh>; close $fh; return $c;
}

# git helper: run git in $dir, die on failure.
sub git_ok {
    my ($dir, @args) = @_;
    my ($rc, $out) = run(cmd => ['git', '-C', $dir, @args]);
    die "git @args failed (rc=$rc): $out" if $rc != 0;
    return $out;
}

# Build an upstream CWF source repo at $dir with tags v0.0.1..v0.0.N. Each
# version writes a distinct marker into .cwf/E2E-MARKER so a later assertion can
# prove the *target* version's laydown ran (FR2).
sub build_upstream {
    my ($dir, $n_versions) = @_;
    system('mkdir', '-p', $dir) == 0 or die "mkdir $dir";
    git_ok($dir, 'init', '-q');

    # CWF-shaped content from the real repo.
    cp_rp("$REPO_ROOT/scripts",        "$dir/scripts");
    cp_rp("$REPO_ROOT/.cwf",           "$dir/.cwf");
    system('mkdir', '-p', "$dir/.claude");
    cp_rp("$REPO_ROOT/.claude/skills", "$dir/.claude/skills");
    cp_rp("$REPO_ROOT/.claude/rules",  "$dir/.claude/rules");
    cp_rp("$REPO_ROOT/.claude/agents", "$dir/.claude/agents");

    for my $i (1 .. $n_versions) {
        write_file("$dir/.cwf/E2E-MARKER", "v0.0.$i\n");
        git_ok($dir, 'add', '-A');
        git_ok($dir, 'commit', '-q', '-m', "release v0.0.$i");
        git_ok($dir, 'tag', "v0.0.$i");
    }
    return $dir;
}

# Install CWF into a fresh consumer repo from the upstream via install.bash.
# $method defaults to 'copy' (method-agnostic update mechanics); pass 'read-tree'
# for that path. The subtree method was removed in Task 185; subtree→read-tree
# migration is covered by t/cwf-manage-update-migrate.t.
sub install_consumer {
    my ($consumer, $upstream, $ref, $method) = @_;
    $method //= 'copy';
    system('mkdir', '-p', $consumer) == 0 or die "mkdir $consumer";
    git_ok($consumer, 'init', '-q');
    write_file("$consumer/README.md", "consumer\n");
    git_ok($consumer, 'add', 'README.md');
    git_ok($consumer, 'commit', '-q', '-m', 'initial');

    my @r;
    {
        local $ENV{CWF_METHOD} = $method;
        local $ENV{CWF_SOURCE} = "file://$upstream";
        local $ENV{CWF_REF}    = $ref;
        @r = run(cmd => ['bash', "$upstream/scripts/install.bash"], dir => $consumer);
    }
    # Mirror post-/cwf-init consumer state: the runtime lock is gitignored
    # (transient), and the rest of the install (incl. .cwf/version) is committed
    # so the working tree is clean for `update`'s check_clean_tree.
    if ($r[0] == 0) {
        write_file("$consumer/.gitignore", ".cwf/.update.lock\n");
        git_ok($consumer, 'add', '-A');
        git_ok($consumer, 'commit', '-q', '-m', 'install CWF');
    }
    return @r;
}

# Run the consumer's installed cwf-manage. CWF_UPGRADE_RESOLVE=new makes
# apply-artefacts resolve any rules-inject/CLAUDE.md conflict non-interactively
# (interactive D/A prompt branches are out of scope per e-testing-plan.md).
sub consumer_manage {
    my ($consumer, @args) = @_;
    local $ENV{CWF_UPGRADE_RESOLVE} = 'new';
    return run(
        cmd => ['perl', "-I$consumer/.cwf/lib", "$consumer/.cwf/scripts/cwf-manage", @args],
        dir => $consumer,
    );
}

#==============================================================================

subtest 'FR9: malformed refs rejected before any side effect' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $consumer = "$base/consumer";
    my $upstream = build_upstream("$base/upstream", 1);
    my ($irc, $iout) = install_consumer($consumer, $upstream, 'v0.0.1');
    is($irc, 0, 'install.bash install succeeds') or diag $iout;

    for my $bad ('--foo', ';rm', '$(touch pwned)', '../escape') {
        my ($rc, $out) = consumer_manage($consumer, 'update', $bad);
        isnt($rc, 0, "ref '$bad' rejected");
        like($out, qr/Invalid ref/, "ref '$bad' names the validation error");
    }
    ok(!-e "$consumer/pwned", 'no injection side effect');
};

subtest 'FR2/FR3/FR5: cross-version-gap update runs target laydown' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $consumer = "$base/consumer";
    my $upstream = build_upstream("$base/upstream", 3);

    my ($irc, $iout) = install_consumer($consumer, $upstream, 'v0.0.1');
    is($irc, 0, 'install v0.0.1 succeeds') or diag $iout;
    is(slurp("$consumer/.cwf/E2E-MARKER"), "v0.0.1\n", 'installed marker is v0.0.1');

    # Update across a gap (v0.0.1 -> v0.0.3): the target version's laydown runs.
    my ($urc, $uout) = consumer_manage($consumer, 'update', 'v0.0.3');
    is($urc, 0, 'update v0.0.1 -> v0.0.3 succeeds') or diag $uout;
    unlike($uout, qr/conflict|CONFLICT/, 'no conflict markers in update output');
    is(slurp("$consumer/.cwf/E2E-MARKER"), "v0.0.3\n",
       'marker now v0.0.3 — target version laydown ran (FR2)');

    # Exact laydown sets perms to recorded; recorded == ceiling, so the
    # ceiling check passes. Guards exact-mode from drifting above the ceiling.
    my ($vrc, $vout) = consumer_manage($consumer, 'validate');
    is($vrc, 0, 'validate passes post-update (exact perms ≤ ceiling, FR5)') or diag $vout;
};

subtest 'FR6: manifest-SHA pin survives a second update' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $consumer = "$base/consumer";
    my $upstream = build_upstream("$base/upstream", 2);
    my ($irc) = install_consumer($consumer, $upstream, 'v0.0.1');
    is($irc, 0, 'install v0.0.1');

    my ($u1, $u1out) = consumer_manage($consumer, 'update', 'v0.0.2');
    is($u1, 0, 'first update writes the pin') or diag $u1out;
    like(slurp("$consumer/.cwf/version"), qr/cwf_install_manifest_sha=\w+/,
         '.cwf/version carries cwf_install_manifest_sha');

    # Real usage commits the update before the next one (the update modifies
    # tracked files); commit so the second update's clean-tree check passes.
    git_ok($consumer, 'add', '-A');
    git_ok($consumer, 'commit', '-q', '-m', 'apply update v0.0.2');

    my ($u2, $u2out) = consumer_manage($consumer, 'update', 'v0.0.2');
    is($u2, 0, 'second update does not false-positive on manifest tamper check') or diag $u2out;
    unlike($u2out, qr/tampered/, 'no tamper false-positive');
};

subtest 'FR6: downgrade to an earlier tag succeeds' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $consumer = "$base/consumer";
    my $upstream = build_upstream("$base/upstream", 3);
    my ($irc) = install_consumer($consumer, $upstream, 'v0.0.3');
    is($irc, 0, 'install v0.0.3');

    my ($drc, $dout) = consumer_manage($consumer, 'update', 'v0.0.1');
    is($drc, 0, 'downgrade v0.0.3 -> v0.0.1 succeeds') or diag $dout;
    is(slurp("$consumer/.cwf/E2E-MARKER"), "v0.0.1\n", 'marker downgraded to v0.0.1');
};

subtest 'FR10: unrelated staged work is not swept into the reinstall commit' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $consumer = "$base/consumer";
    my $upstream = build_upstream("$base/upstream", 2);
    my ($irc) = install_consumer($consumer, $upstream, 'v0.0.1');
    is($irc, 0, 'install v0.0.1');

    # Stage an unrelated file before the update.
    write_file("$consumer/UNRELATED.txt", "do not commit me\n");
    git_ok($consumer, 'add', 'UNRELATED.txt');

    # Since Task 185 neither laydown method creates a commit at all (read-tree
    # stages; copy writes the worktree) — so there is no reinstall *remove
    # commit* that could ever capture unrelated staged work. The guarantee is
    # structural: confirm no such commit exists and the work is never lost.
    consumer_manage($consumer, 'update', 'v0.0.2');

    my $files = git_ok($consumer, 'log', '--diff-filter=D', '--name-only',
                       '--pretty=format:', '-1',
                       '--grep=remove existing install');
    unlike($files // '', qr/UNRELATED\.txt/,
           'UNRELATED.txt not captured by any reinstall remove commit');
    # And it is never lost — still present in the working tree.
    ok(-f "$consumer/UNRELATED.txt", 'UNRELATED.txt still present in working tree');
};

#==============================================================================
# Task 156: fresh-install hint is scoped to laydown failures.

subtest 'Task 156: laydown failure surfaces the fresh-install hint' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $consumer = "$base/consumer";
    my $upstream = build_upstream("$base/upstream", 1);
    my ($irc, $iout) = install_consumer($consumer, $upstream, 'v0.0.1');
    is($irc, 0, 'install v0.0.1 succeeds') or diag $iout;

    # Tag v0.0.2 with a failing install.bash so the update's delegated laydown
    # errors *after* clone/checkout — i.e. past the $update_in_progress set point.
    write_file("$upstream/scripts/install.bash", "#!/usr/bin/env bash\nexit 1\n");
    git_ok($upstream, 'add', '-A');
    git_ok($upstream, 'commit', '-q', '-m', 'release v0.0.2 (broken install.bash)');
    git_ok($upstream, 'tag', 'v0.0.2');

    my ($urc, $uout) = consumer_manage($consumer, 'update', 'v0.0.2');
    isnt($urc, 0, 'update fails when target laydown errors');
    like($uout, qr/install\.bash laydown failed/, 'laydown failure diagnostic present');
    like($uout, qr/might want to consider a fresh install/, 'fresh-install suggestion present');
    like($uout, qr/CWF_FORCE=1 .*bash install\.bash/, 'bootstrap command shown');
    like($uout, qr/INSTALL\.md/, 'points at INSTALL.md recovery section');
    like($uout, qr/<source-url>/, 'placeholder kept literal (no env-var interpolation)');
};

subtest 'Task 156: pre-flight ref rejection shows no hint' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $consumer = "$base/consumer";
    my $upstream = build_upstream("$base/upstream", 1);
    my ($irc) = install_consumer($consumer, $upstream, 'v0.0.1');
    is($irc, 0, 'install v0.0.1');

    my ($rc, $out) = consumer_manage($consumer, 'update', ';rm');
    isnt($rc, 0, 'malformed ref rejected');
    like($out, qr/Invalid ref/, 'lexical validation error');
    unlike($out, qr/fresh install/, 'no hint for a pre-flight guard failure');
};

subtest 'Task 156: clone/resolve failure shows no hint' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $consumer = "$base/consumer";
    my $upstream = build_upstream("$base/upstream", 1);
    my ($irc) = install_consumer($consumer, $upstream, 'v0.0.1');
    is($irc, 0, 'install v0.0.1');

    # Well-formed but non-existent tag: fails at resolve_ref, before laydown.
    my ($rc, $out) = consumer_manage($consumer, 'update', 'v0.0.99');
    isnt($rc, 0, 'non-existent ref fails');
    unlike($out, qr/fresh install/, 'no hint: failure precedes the laydown set point');
};

subtest 'Task 156: $update_in_progress is set in exactly one place' => sub {
    my $src = slurp("$REPO_ROOT/.cwf/scripts/cwf-manage");
    my $count = () = $src =~ /\$update_in_progress = 1/g;
    is($count, 1, 'flag assigned to 1 in exactly one place (cmd_update)');
};

#==============================================================================
# Task 159 FR1: cwf_version records the resolved semver (git describe), cwf_ref
# records the originally-requested ref — not both echoing the resolved value.

subtest 'FR1: update latest → cwf_version=highest tag, cwf_ref=latest' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $consumer = "$base/consumer";
    my $upstream = build_upstream("$base/upstream", 3);   # tags v0.0.1..v0.0.3
    my ($irc, $iout) = install_consumer($consumer, $upstream, 'v0.0.1');
    is($irc, 0, 'install v0.0.1 succeeds') or diag $iout;

    my ($urc, $uout) = consumer_manage($consumer, 'update', 'latest');
    is($urc, 0, "update 'latest' succeeds") or diag $uout;

    my $vf = slurp("$consumer/.cwf/version") // '';
    like($vf, qr/^cwf_version=v0\.0\.3$/m, 'cwf_version is the resolved highest tag');
    like($vf, qr/^cwf_ref=latest$/m,       "cwf_ref preserves the requested 'latest'");
};

subtest 'FR1: update by SHA-on-a-tag → cwf_version=tag, cwf_ref=the SHA' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $consumer = "$base/consumer";
    my $upstream = build_upstream("$base/upstream", 3);
    my ($irc, $iout) = install_consumer($consumer, $upstream, 'v0.0.1');
    is($irc, 0, 'install v0.0.1 succeeds') or diag $iout;

    my $sha = git_ok($upstream, 'rev-parse', 'v0.0.2');
    $sha =~ s/\s+//g;

    my ($urc, $uout) = consumer_manage($consumer, 'update', $sha);
    is($urc, 0, 'update pinned to a tagged commit SHA succeeds') or diag $uout;

    my $vf = slurp("$consumer/.cwf/version") // '';
    # Pre-fix behaviour wrote the SHA into BOTH fields; the fix derives the tag
    # for cwf_version while cwf_ref keeps the requested SHA.
    like($vf, qr/^cwf_version=v0\.0\.2$/m, 'cwf_version describes the SHA to its tag');
    like($vf, qr/^cwf_ref=\Q$sha\E$/m,     'cwf_ref preserves the requested SHA');
    unlike($vf, qr/^cwf_version=\Q$sha\E$/m, 'cwf_version is NOT the bare SHA (the bug)');
};

subtest 'TC-5 (Task 161): copy-method update over an existing install succeeds' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $consumer = "$base/consumer";
    my $upstream = build_upstream("$base/upstream", 2);   # tags v0.0.1, v0.0.2

    my ($irc, $iout) = install_consumer($consumer, $upstream, 'v0.0.1', 'copy');
    is($irc, 0, 'copy install v0.0.1 succeeds') or diag $iout;
    like(slurp("$consumer/.cwf/version") // '', qr/^cwf_method=copy$/m,
        'installed method is copy');

    # The copy update path delegates to install.bash, which runs install_copy
    # with CWF_FORCE=1 over the existing .cwf/ — proving FR4's full env block.
    my ($urc, $uout) = consumer_manage($consumer, 'update', 'v0.0.2');
    is($urc, 0, 'copy-method update succeeds (no "already installed" abort)') or diag $uout;

    my $vf = slurp("$consumer/.cwf/version") // '';
    like($vf, qr/^cwf_method=copy$/m,  'method remains copy after update');
    like($vf, qr/^cwf_ref=v0\.0\.2$/m, 'cwf_ref records the update target');
    ok(-d "$consumer/.cwf" && -d "$consumer/.cwf-rules",
        '.cwf and .cwf-rules present after the converged copy update');
    ok(-l "$consumer/.claude/rules/cwf-workflow-files.md",
        'rules symlink regenerated (run_apply_artefacts parity with subtree)');
};

done_testing();
