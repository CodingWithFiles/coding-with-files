#!/usr/bin/env perl
#
# version-records-commit-sha.t — Task 175. Both SHA-resolution sites
# (scripts/install.bash and .cwf/scripts/cwf-manage::resolve_sha) must record the
# resolved ref's *commit* SHA in .cwf/version (cwf_sha), not the ref's own object
# SHA. The two differ only for an ANNOTATED tag: `git rev-parse <tag>` returns the
# tag-object SHA, `git rev-parse <tag>^{commit}` peels to the commit.
#
# The shared E2E fixtures use lightweight tags, for which rev-parse already
# returns the commit and the bug cannot reproduce. This test therefore builds its
# own upstream with ANNOTATED tags and turns every assertion on the
# tag-object-vs-commit discriminator (asserted as a precondition in each case).
#
# Same self-contained fixture-server pattern as t/cwf-manage-update-end-to-end.t
# (helpers re-implemented per sibling-test convention, not imported).
#
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir tempfile);
use Cwd qw(getcwd);

my $REPO_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));

# Deterministic git identity for every child git process (install.bash and the
# annotated-tag creation both commit/tag).
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

sub git_ok {
    my ($dir, @args) = @_;
    my ($rc, $out) = run(cmd => ['git', '-C', $dir, @args]);
    die "git @args failed (rc=$rc): $out" if $rc != 0;
    return $out;
}

# rev-parse a ref in $dir, trimmed.
sub rev_parse {
    my ($dir, $ref) = @_;
    my $sha = git_ok($dir, 'rev-parse', $ref);
    $sha =~ s/\s+//g;
    return $sha;
}

# Build an upstream CWF source repo at $dir with ANNOTATED tags v0.0.1..v0.0.N.
# Annotated (git tag -a) is the discriminator: rev-parse <tag> is the tag object,
# rev-parse <tag>^{commit} is the commit.
sub build_upstream {
    my ($dir, $n_versions) = @_;
    system('mkdir', '-p', $dir) == 0 or die "mkdir $dir";
    git_ok($dir, 'init', '-q');

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
        git_ok($dir, 'tag', '-a', "v0.0.$i", '-m', "annotated release v0.0.$i");
    }
    return $dir;
}

sub install_consumer {
    my ($consumer, $upstream, $ref, $method) = @_;
    # Default to the copy method: these tests assert SHA/version recording, which
    # is method-agnostic. The subtree method was removed in Task 185; read-tree
    # and migration recording are covered by t/install-bash-read-tree.t and
    # t/cwf-manage-update-migrate.t.
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
    if ($r[0] == 0) {
        write_file("$consumer/.gitignore", ".cwf/.update.lock\n");
        git_ok($consumer, 'add', '-A');
        git_ok($consumer, 'commit', '-q', '-m', 'install CWF');
    }
    return @r;
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

subtest 'TC-1: install.bash records the annotated tag commit SHA, not the tag object' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $consumer = "$base/consumer";
    my $upstream = build_upstream("$base/upstream", 1);

    my $tagobj = rev_parse($upstream, 'v0.0.1');
    my $commit = rev_parse($upstream, 'v0.0.1^{commit}');
    isnt($tagobj, $commit,
        'precondition: annotated tag object SHA differs from its commit SHA');

    my ($irc, $iout) = install_consumer($consumer, $upstream, 'v0.0.1');
    is($irc, 0, 'install.bash install of an annotated tag succeeds') or diag $iout;

    my $vf = slurp("$consumer/.cwf/version") // '';
    like($vf,   qr/^cwf_sha=\Q$commit\E$/m, 'cwf_sha is the tag\'s commit SHA');
    unlike($vf, qr/^cwf_sha=\Q$tagobj\E$/m, 'cwf_sha is NOT the tag-object SHA (the bug)');
};

subtest 'TC-2: cwf-manage update to an annotated tag records the commit SHA' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $consumer = "$base/consumer";
    my $upstream = build_upstream("$base/upstream", 2);

    my ($irc, $iout) = install_consumer($consumer, $upstream, 'v0.0.1');
    is($irc, 0, 'install v0.0.1 succeeds') or diag $iout;

    my $tagobj = rev_parse($upstream, 'v0.0.2');
    my $commit = rev_parse($upstream, 'v0.0.2^{commit}');
    isnt($tagobj, $commit,
        'precondition: v0.0.2 annotated tag object differs from its commit');

    my ($urc, $uout) = consumer_manage($consumer, 'update', 'v0.0.2');
    is($urc, 0, 'update v0.0.1 -> v0.0.2 succeeds') or diag $uout;

    my $vf = slurp("$consumer/.cwf/version") // '';
    like($vf,   qr/^cwf_sha=\Q$commit\E$/m, 'cwf_sha is the target tag\'s commit SHA');
    unlike($vf, qr/^cwf_sha=\Q$tagobj\E$/m, 'cwf_sha is NOT the tag-object SHA');
    # Regression guard: git_describe_version still resolves the commit to the tag.
    like($vf,   qr/^cwf_version=v0\.0\.2$/m, 'cwf_version remains the tag name');
};

done_testing();
