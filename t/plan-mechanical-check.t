#!/usr/bin/env perl
#
# plan-mechanical-check.t - Unit/integration tests for
# .cwf/scripts/command-helpers/plan-mechanical-check
#
# Each subtest builds a synthetic CWF-layout repo (git init + a committed
# implementation-guide/<num>-chore-<slug>/d-implementation-plan.md plus any
# seeded source/test files), runs the helper as a subprocess from the repo root,
# and asserts on its stdout confirmation line, the findings `.out` it wrote, and
# its exit code. git ls-files / git grep see only tracked files, so fixtures
# commit everything. No network, no database, never the real repo.
#
use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use Cwd qw(cwd);
use POSIX ();

my $HELPER = "$FindBin::Bin/../.cwf/scripts/command-helpers/plan-mechanical-check";

my $CAPTURE_DIR = tempdir(CLEANUP => 1);
my $CAPTURE_SEQ = 0;

# The .out files hang off a dashified /tmp namespace outside the fixture
# tempdirs, so File::Temp CLEANUP misses them — track and remove explicitly.
my @CLEANUP_OUT;
END {
    for my $p (@CLEANUP_OUT) {
        next unless defined $p;
        unlink $p;
        (my $leaf   = $p)    =~ s{/[^/]+$}{};   # task-<num> leaf
        rmdir $leaf;
        (my $parent = $leaf) =~ s{/[^/]+$}{};   # cwf<dash> parent
        rmdir $parent;
    }
}

sub git_in { my ($dir, @a) = @_; system('git', '-C', $dir, @a) == 0 or die "git @a failed" }

sub write_raw {
    my ($path, $content) = @_;
    (my $dir = $path) =~ s{/[^/]+$}{};
    make_path($dir) if length $dir && !-d $dir;
    open my $f, '>:encoding(UTF-8)', $path or die "open $path: $!";
    print $f $content;
    close $f;
}

# Build a synthetic repo. %opt:
#   num/slug  - task identity (defaults 1/demo; type is always chore)
#   plan      - d-implementation-plan.md body (required)
#   files     - { relpath => content } seeded + committed before the helper runs
# Returns ($repo, $num).
sub new_repo {
    my (%opt) = @_;
    my $num  = $opt{num}  // '1';
    my $slug = $opt{slug} // 'demo';
    my $repo = tempdir(CLEANUP => 1) . "/repo";
    make_path($repo);
    git_in($repo, 'init', '-q', '--initial-branch=main');
    git_in($repo, 'config', 'user.email', 'test@example.com');
    git_in($repo, 'config', 'user.name',  'Test');

    my $tdir = "$repo/implementation-guide/${num}-chore-${slug}";
    make_path($tdir);
    write_raw("$tdir/d-implementation-plan.md", $opt{plan} // "# Plan\n");

    if ($opt{files}) {
        write_raw("$repo/$_", $opt{files}{$_}) for keys %{ $opt{files} };
    }
    git_in($repo, 'add', '-A');
    git_in($repo, 'commit', '-q', '-m', 'fixture');
    return ($repo, $num);
}

# Run the helper inside $repo; capture (stdout, stderr, exit). Tracks the .out.
sub run {
    my ($repo, @args) = @_;
    $CAPTURE_SEQ++;
    my $of = "$CAPTURE_DIR/out.$CAPTURE_SEQ";
    my $ef = "$CAPTURE_DIR/err.$CAPTURE_SEQ";
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
    my $rc;
    {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            open(STDOUT, '>', $of) or POSIX::_exit(127);
            open(STDERR, '>', $ef) or POSIX::_exit(127);
            exec($HELPER, @args) or POSIX::_exit(127);
        }
        waitpid($pid, 0);
        $rc = $? >> 8;
    }
    chdir $orig;
    my $out = slurp($of);
    my $err = slurp($ef);
    if ($out =~ /^plan-mechanical-check: wrote \d+ findings to (.+)$/m) {
        push @CLEANUP_OUT, $1;
    }
    return ($out, $err, $rc);
}
sub slurp { my ($p) = @_; open my $f, '<:encoding(UTF-8)', $p or return ''; local $/; my $c = <$f>; close $f; return $c // '' }

# Convenience: run a standard implementation-phase scan and return
# ($out, $err, $rc, $findings_text, $count).
sub scan {
    my ($repo, $num) = @_;
    my ($out, $err, $rc) = run($repo, "--task-num=$num", '--plan-type=implementation');
    my ($count) = $out =~ /wrote (\d+) findings/;
    my ($path)  = $out =~ /findings to (.+)$/m;
    my $findings = defined $path ? slurp($path) : '';
    return ($out, $err, $rc, $findings, $count);
}

# --- TC-1: Task-150 regression — high-signal wrong path -------------------
{
    my ($repo, $num) = new_repo(
        plan  => "# Plan\nThe helper lives at `.cwf/scripts/command-helpers/cwf-manage`.\n",
        files => { '.cwf/scripts/cwf-manage' => "#!/usr/bin/env perl\n1;\n" },
    );
    my ($out, $err, $rc, $f, $count) = scan($repo, $num);
    is($rc, 0, 'TC-1 exit 0');
    cmp_ok($count, '>=', 1, 'TC-1 at least one finding');
    like($f, qr/\[path-high\]/, 'TC-1 high-signal classification');
    like($f, qr{\.cwf/scripts/command-helpers/cwf-manage}, 'TC-1 names the bad path');
    like($f, qr{\.cwf/scripts/cwf-manage}, 'TC-1 names the existing alt path');
}

# --- TC-2: advisory — genuine new file ------------------------------------
{
    my ($repo, $num) = new_repo(
        plan => "# Plan\nWe will create `.cwf/scripts/command-helpers/brand-new-xyz`.\n",
    );
    my ($out, $err, $rc, $f, $count) = scan($repo, $num);
    is($rc, 0, 'TC-2 exit 0');
    like($f, qr/\[path-advisory\]/, 'TC-2 advisory classification');
    unlike($f, qr/\[path-high\]/, 'TC-2 not high-signal');
}

# --- TC-10: token-shape rejection -----------------------------------------
{
    my ($repo, $num) = new_repo(
        plan => "# Plan\n"
              . "See `https://example.com/x/y` and `src/*.go` and "
              . "`:!implementation-guide/foo` and `/^\\d+/`.\n",
    );
    my ($out, $err, $rc, $f, $count) = scan($repo, $num);
    is($rc, 0, 'TC-10 exit 0');
    is($count, 0, 'TC-10 no findings — all non-path tokens rejected');
    unlike($f, qr/\[path-/, 'TC-10 no path findings');
}

# --- TC-11: markdown anchor on an existing file is not a finding ----------
{
    my ($repo, $num) = new_repo(
        plan  => "# Plan\nSee `docs/guide.md#some-section` for details.\n",
        files => { 'docs/guide.md' => "# Guide\n" },
    );
    my ($out, $err, $rc, $f, $count) = scan($repo, $num);
    is($rc, 0, 'TC-11 exit 0');
    is($count, 0, 'TC-11 anchor fragment stripped — existing file, no finding');
}

# --- TC-3: Task-174 regression — deleted symbol still referenced ----------
{
    my ($repo, $num) = new_repo(
        plan  => "# Plan\n- **Deletes**: \@CWF_INTERNAL_PREFIXES\n",
        files => {
            'lib/A.pm' => "our \@CWF_INTERNAL_PREFIXES = ('x');\n",
            'lib/B.pm' => "my \$n = \@CWF_INTERNAL_PREFIXES;\n",
        },
    );
    my ($out, $err, $rc, $f, $count) = scan($repo, $num);
    is($rc, 0, 'TC-3 exit 0');
    like($f, qr/\[symbol\]/, 'TC-3 symbol finding');
    like($f, qr{lib/A\.pm}, 'TC-3 names first referencing file');
    like($f, qr{lib/B\.pm}, 'TC-3 names second referencing file');
}

# --- TC-4: zero references — safe to delete (git grep exit 1) --------------
{
    my ($repo, $num) = new_repo(
        plan  => "# Plan\n- **Deletes**: totally_unused_symbol_xyz\n",
        files => { 'lib/A.pm' => "my \$x = 1;\n" },
    );
    my ($out, $err, $rc, $f, $count) = scan($repo, $num);
    is($rc, 0, 'TC-4 exit 0');
    is($count, 0, 'TC-4 no finding — zero references is safe');
}

# --- TC-6: self-match exclusion (only the plan/task dir references it) -----
{
    my ($repo, $num) = new_repo(
        plan => "# Plan\n- **Deletes**: SomeSymbol\nMentions SomeSymbol again here.\n",
    );
    my ($out, $err, $rc, $f, $count) = scan($repo, $num);
    is($rc, 0, 'TC-6 exit 0');
    is($count, 0, 'TC-6 no finding — own task dir excluded');
}

# --- TC-9: leading-dash symbol — option-injection guard -------------------
{
    my ($repo, $num) = new_repo(
        plan  => "# Plan\n- **Deletes**: -O\n",
        files => { 'lib/A.pm' => "my \$flag = '-O';\n" },
    );
    my ($out, $err, $rc, $f, $count) = scan($repo, $num);
    is($rc, 0, 'TC-9 exit 0 — -O searched as pattern, not git option');
    like($f, qr/\[symbol\]/, 'TC-9 finds the -O reference');
    like($f, qr{lib/A\.pm}, 'TC-9 names the file');
}

# --- TC-5: clean no-op ----------------------------------------------------
{
    my ($repo, $num) = new_repo(
        plan  => "# Plan\nEverything valid; see `lib/A.pm`. No deletions.\n",
        files => { 'lib/A.pm' => "1;\n" },
    );
    my ($out, $err, $rc, $f, $count) = scan($repo, $num);
    is($rc, 0, 'TC-5 exit 0');
    is($count, 0, 'TC-5 zero findings');
    like($out, qr/^plan-mechanical-check: wrote 0 findings to /m, 'TC-5 confirmation line');
}

# --- TC-7: resolution failures vs plan-absent -----------------------------
{
    my ($repo, $num) = new_repo(plan => "# Plan\n");

    my ($o1, $e1, $r1) = run($repo, '--task-num=abc', '--plan-type=implementation');
    is($r1, 1, 'TC-7 invalid --task-num exits 1');

    my ($o2, $e2, $r2) = run($repo, "--task-num=$num", '--plan-type=bogus');
    is($r2, 1, 'TC-7 unknown --plan-type exits 1');

    my ($o3, $e3, $r3) = run($repo, '--plan-type=implementation');
    is($r3, 1, 'TC-7 missing --task-num exits 1');

    my ($o4, $e4, $r4) = run($repo, '--task-num=999', '--plan-type=implementation');
    is($r4, 1, 'TC-7 unresolvable task exits 1');

    # task dir resolves but the requirements plan file is absent (chore has no b-)
    my ($o5, $e5, $r5) = run($repo, "--task-num=$num", '--plan-type=requirements');
    is($r5, 0, 'TC-7 absent plan file is fail-open (exit 0)');
    like($o5, qr/wrote 0 findings/, 'TC-7 absent plan file -> 0 findings');
}

# --- TC-8: output location + confirmation format --------------------------
{
    my ($repo, $num) = new_repo(plan => "# Plan\nNo issues.\n");
    my ($out, $err, $rc) = run($repo, "--task-num=$num", '--plan-type=implementation');
    is($rc, 0, 'TC-8 exit 0');
    like($out,
         qr{^plan-mechanical-check: wrote \d+ findings to /.+/task-\Q$num\E/plan-mechanical-check-implementation\.out\n?$}m,
         'TC-8 confirmation line + scratch path shape');
    my ($path) = $out =~ /findings to (.+)$/m;
    ok(-f $path, 'TC-8 .out file exists');
    my $mode = (stat $path)[2] & 07777;
    is($mode, 0600, 'TC-8 .out is mode 0600');
}

done_testing();
