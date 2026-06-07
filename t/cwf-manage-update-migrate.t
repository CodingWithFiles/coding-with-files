#!/usr/bin/env perl
#
# cwf-manage-update-migrate.t — Task 185. subtree→read-tree migrate-on-update
# plus the merge-commit detection surface (FR4/FR7).
#
#   TC-6  (AC4 +): a cwf_method=subtree install updates → method becomes
#                  read-tree, no new merge, validate clean, and the migration
#                  emits the merge-commit warning.
#   TC-7  (AC4 -): a laydown failure mid-migration leaves cwf_method=subtree
#                  (fail-closed — never a half-recorded read-tree).
#   TC-10 (AC7):   `cwf-manage check-merges` is read-only (repo unchanged).
#   TC-12:         a cwf-detect-merges failure does not abort the migration.
#
# A cwf_method=subtree starting state can no longer be produced by install.bash
# (it refuses subtree), so the fixture lays CWF down via the copy method, then
# rewrites .cwf/version to record subtree and (where needed) crafts a real
# `git subtree add --squash` merge in the consumer history.
#
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir tempfile);
use Cwd qw(getcwd);
use Digest::SHA qw(sha256_hex);

my $REPO_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));

local $ENV{GIT_AUTHOR_NAME}     = 'CWF Test';
local $ENV{GIT_AUTHOR_EMAIL}    = 'test@example.invalid';
local $ENV{GIT_COMMITTER_NAME}  = 'CWF Test';
local $ENV{GIT_COMMITTER_EMAIL} = 'test@example.invalid';

my $bash_ok = `bash -c 'echo \$BASH_VERSINFO' 2>/dev/null`;
chomp $bash_ok;
plan skip_all => 'bash 4+ required for install.bash' unless defined $bash_ok && $bash_ok >= 4;
plan skip_all => 'git subtree not available'
    unless system("git subtree --help >/dev/null 2>&1") == 0;

# --- harness ------------------------------------------------------------------

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

# Upstream with $n_versions tags, each carrying the working-tree CWF.
sub build_upstream {
    my ($dir, $n) = @_;
    $n //= 1;
    system('mkdir', '-p', $dir) == 0 or die "mkdir $dir";
    git_ok($dir, 'init', '-q');
    cp_rp("$REPO_ROOT/scripts",        "$dir/scripts");
    cp_rp("$REPO_ROOT/.cwf",           "$dir/.cwf");
    system('mkdir', '-p', "$dir/.claude");
    cp_rp("$REPO_ROOT/.claude/skills", "$dir/.claude/skills");
    cp_rp("$REPO_ROOT/.claude/rules",  "$dir/.claude/rules");
    cp_rp("$REPO_ROOT/.claude/agents", "$dir/.claude/agents");
    for my $i (1 .. $n) {
        write_file("$dir/.cwf/E2E-MARKER", "v0.0.$i\n");
        git_ok($dir, 'add', '-A');
        git_ok($dir, 'commit', '-q', '-m', "release v0.0.$i");
        git_ok($dir, 'tag', "v0.0.$i");
    }
    return $dir;
}

# Fresh consumer, COPY-installed (works regardless of the deprecation), with the
# install committed so the working tree is clean for `update`.
sub copy_install_consumer {
    my ($consumer, $upstream, $ref) = @_;
    system('mkdir', '-p', $consumer) == 0 or die "mkdir $consumer";
    git_ok($consumer, 'init', '-q');
    write_file("$consumer/README.md", "consumer\n");
    git_ok($consumer, 'add', 'README.md');
    git_ok($consumer, 'commit', '-q', '-m', 'initial');
    my @r;
    {
        local $ENV{CWF_METHOD} = 'copy';
        local $ENV{CWF_SOURCE} = "file://$upstream";
        local $ENV{CWF_REF}    = $ref;
        @r = run(cmd => ['bash', "$upstream/scripts/install.bash"], dir => $consumer);
    }
    die "copy install failed: $r[1]" if $r[0] != 0;
    write_file("$consumer/.gitignore", ".cwf/.update.lock\n");
    git_ok($consumer, 'add', '-A');
    git_ok($consumer, 'commit', '-q', '-m', 'install CWF');
    return $consumer;
}

# Rewrite the recorded method to subtree (the pre-migration state).
sub record_method_subtree {
    my ($consumer) = @_;
    my $vf = slurp("$consumer/.cwf/version") // die "no .cwf/version";
    $vf =~ s/^cwf_method=.*$/cwf_method=subtree/m;
    write_file("$consumer/.cwf/version", $vf);
    git_ok($consumer, 'add', '-A');
    git_ok($consumer, 'commit', '-q', '-m', 'record subtree method (fixture)');
}

# Craft a real `git subtree add --squash` merge in the consumer history at
# $prefix with a CWF subject — the exact shape cwf-detect-merges fingerprints.
sub craft_subtree_merge {
    my ($consumer, $base, $prefix, $area) = @_;
    my $src = "$base/sub-src-$area";
    write_file("$src/.cwf/a.txt", "legacy\n");
    git_ok($src, 'init', '-q');
    git_ok($src, 'add', '-A');
    git_ok($src, 'commit', '-q', '-m', 'legacy source');
    my $br = git_ok($src, 'rev-parse', '--abbrev-ref', 'HEAD');
    git_ok($consumer, 'subtree', 'add', "--prefix=$prefix", $src, $br,
           '--squash', '-m', "Add CWF $area (v1.0)");
}

sub consumer_manage {
    my ($consumer, @args) = @_;
    local $ENV{CWF_UPGRADE_RESOLVE} = 'new';
    return run(
        cmd => ['perl', "-I$consumer/.cwf/lib", "$consumer/.cwf/scripts/cwf-manage", @args],
        dir => $consumer,
    );
}

#==============================================================================

subtest 'TC-6 (AC4 +): subtree install migrates to read-tree on update' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream", 1);
    my $consumer = copy_install_consumer("$base/consumer", $upstream, 'v0.0.1');

    craft_subtree_merge($consumer, $base, 'legacy', 'core');   # a real subtree merge
    record_method_subtree($consumer);
    like(slurp("$consumer/.cwf/version") // '', qr/^cwf_method=subtree$/m,
         'precondition: recorded method is subtree');
    my $head_before = git_ok($consumer, 'rev-parse', 'HEAD');

    my ($urc, $uout) = consumer_manage($consumer, 'update', 'v0.0.1');
    is($urc, 0, 'update of a subtree install succeeds (migrates, not refuses)') or diag $uout;

    like(slurp("$consumer/.cwf/version") // '', qr/^cwf_method=read-tree$/m,
         'cwf_method rewritten to read-tree');
    is(git_ok($consumer, 'rev-list', '--merges', "$head_before..HEAD"), '',
       'migration introduces no new merge commit');
    like($uout, qr/originate from old CWF subtree installs/,
         'migration emits the merge-commit warning (AC7)');

    my ($vrc, $vout) = consumer_manage($consumer, 'validate');
    is($vrc, 0, 'validate clean post-migration') or diag $vout;
};

subtest 'TC-7 (AC4 -): a failed laydown leaves cwf_method=subtree (fail-closed)' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream", 1);
    my $consumer = copy_install_consumer("$base/consumer", $upstream, 'v0.0.1');
    record_method_subtree($consumer);

    # Tag v0.0.2 whose install.bash fails: the delegated laydown errors after
    # the migration began, before the version write.
    write_file("$upstream/scripts/install.bash", "#!/usr/bin/env bash\nexit 1\n");
    git_ok($upstream, 'add', '-A');
    git_ok($upstream, 'commit', '-q', '-m', 'release v0.0.2 (broken install.bash)');
    git_ok($upstream, 'tag', 'v0.0.2');

    my ($urc, $uout) = consumer_manage($consumer, 'update', 'v0.0.2');
    isnt($urc, 0, 'update fails when the target laydown errors');
    like(slurp("$consumer/.cwf/version") // '', qr/^cwf_method=subtree$/m,
         'recorded method stays subtree — never a half-migrated read-tree label');
};

subtest 'TC-10 (AC7): check-merges is read-only' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream", 1);
    my $consumer = copy_install_consumer("$base/consumer", $upstream, 'v0.0.1');
    craft_subtree_merge($consumer, $base, 'legacy', 'core');

    my $head_before   = git_ok($consumer, 'rev-parse', 'HEAD');
    my $status_before = git_ok($consumer, 'status', '--porcelain');

    my ($rc, $out) = consumer_manage($consumer, 'check-merges');
    is($rc, 0, 'check-merges exits 0');
    like($out, qr/1 originate from old CWF subtree installs/, 'reports the crafted subtree merge');
    is(git_ok($consumer, 'rev-parse', 'HEAD'), $head_before, 'HEAD unchanged (read-only)');
    is(git_ok($consumer, 'status', '--porcelain'), $status_before,
       'working tree/index unchanged (read-only)');
};

subtest 'TC-12: a detection failure does not abort the migration' => sub {
    my $base     = tempdir(CLEANUP => 1);
    my $upstream = build_upstream("$base/upstream", 1);
    my $consumer = copy_install_consumer("$base/consumer", $upstream, 'v0.0.1');
    record_method_subtree($consumer);

    # Make the upstream's detector exit non-zero at runtime — and keep the
    # install integrity-consistent (patch its recorded sha256 to match the
    # stub) so the migration reaches the detection step rather than aborting on
    # a hash drift. run_detect_merges must ignore the stub's non-zero rc.
    my $stub = "#!/usr/bin/env perl\nexit 3;\n";
    my $helper = "$upstream/.cwf/scripts/command-helpers/cwf-detect-merges";
    write_file($helper, $stub);
    chmod 0755, $helper or die "chmod stub: $!";
    my $hashes = "$upstream/.cwf/security/script-hashes.json";
    my $json = slurp($hashes);
    my $new_sha = sha256_hex($stub);
    $json =~ s/("cwf-detect-merges"\s*:\s*\{[^}]*?"sha256"\s*:\s*")[0-9a-f]{64}(")/$1$new_sha$2/s
        or die "could not patch cwf-detect-merges hash";
    write_file($hashes, $json);
    git_ok($upstream, 'add', '-A');
    git_ok($upstream, 'commit', '-q', '-m', 'release v0.0.2 (failing detector, hash-consistent)');
    git_ok($upstream, 'tag', 'v0.0.2');

    my ($urc, $uout) = consumer_manage($consumer, 'update', 'v0.0.2');
    is($urc, 0, 'migration completes despite a failing detector') or diag $uout;
    like(slurp("$consumer/.cwf/version") // '', qr/^cwf_method=read-tree$/m,
         'method still migrated to read-tree (detector rc ignored)');
};

done_testing();
