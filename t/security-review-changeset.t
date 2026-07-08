#!/usr/bin/env perl
#
# security-review-changeset.t - Integration tests for
# .cwf/scripts/command-helpers/security-review-changeset
#
# Each subtest builds a synthetic git repo with a CWF-shaped task
# layout, runs the helper as a subprocess, and asserts on its stdout,
# stderr, and exit code.
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
use JSON::PP;

my $HELPER = "$FindBin::Bin/../.cwf/scripts/command-helpers/security-review-changeset";

# Capture the helper's stdout/stderr in a temp dir OUTSIDE any repo under test.
# Task 194: the helper now enumerates untracked, non-ignored files, so writing
# these capture files inside $cwd would make the helper sweep them into its own
# changeset (and skew file counts / the empty-diff case). Keep them out of tree.
my $CAPTURE_DIR = tempdir(CLEANUP => 1);
my $CAPTURE_SEQ = 0;

sub git_in {
    my ($dir, @args) = @_;
    my $rc = system('git', '-C', $dir, @args);
    return $rc;
}

sub git_capture {
    my ($dir, @args) = @_;
    my $pid = open(my $fh, '-|', 'git', '-C', $dir, @args)
        or die "fork failed: $!";
    my $out;
    {
        local $/;
        $out = <$fh>;
    }
    close $fh;
    $out //= '';
    $out =~ s/\s+\z//;   # chomp doesn't apply when local $/ was undef
    return $out;
}

# Build a synthetic CWF-layout repo:
#   - implementation-guide/<num>-<type>-<slug>/a-task-plan.md (optionally with baseline)
#   - one initial commit on main, branch <type>/<num>-<slug> created from it
# Returns the repo path.
sub make_synthetic_repo {
    my (%opt) = @_;
    my $base = tempdir(CLEANUP => 1);
    my $repo = "$base/repo";
    make_path($repo);

    # Initialise with --initial-branch=main so we have a deterministic trunk.
    die "git init failed" if git_in($repo, 'init', '-q', '--initial-branch=main') != 0;
    die "git config failed" if git_in($repo, 'config', 'user.email', 'test@example.com') != 0;
    die "git config failed" if git_in($repo, 'config', 'user.name', 'CWFTest') != 0;
    die "git config failed" if git_in($repo, 'config', 'commit.gpgsign', 'false') != 0;

    # README seed commit.
    open my $fh, '>', "$repo/README.md" or die;
    print $fh "seed\n";
    close $fh;
    git_in($repo, 'add', 'README.md');
    git_in($repo, 'commit', '-q', '-m', 'seed');

    my $main_sha = git_capture($repo, 'rev-parse', 'HEAD');

    # Create the task directory under implementation-guide on main itself.
    my $num   = $opt{num}   // '1';
    my $type  = $opt{type}  // 'bugfix';
    my $slug  = $opt{slug}  // 'fix-thing';
    my $task_dir = "$repo/implementation-guide/${num}-${type}-${slug}";
    make_path($task_dir);

    # Write a-task-plan.md with optional baseline.
    my $baseline_line = '';
    if (exists $opt{baseline}) {
        my $sha = $opt{baseline};
        $sha = $main_sha if $sha eq '__MAIN__';
        $baseline_line = "- **Baseline Commit**: $sha\n";
    } elsif ($opt{baseline_raw}) {
        $baseline_line = $opt{baseline_raw};
    }

    open my $tfh, '>', "$task_dir/a-task-plan.md" or die;
    print $tfh "# Plan\n\n## Task Reference\n";
    print $tfh "- **Branch**: ${type}/${num}-${slug}\n";
    print $tfh $baseline_line;
    print $tfh "- **Template Version**: 2.1\n\n";
    close $tfh;
    git_in($repo, 'add', 'implementation-guide/');
    git_in($repo, 'commit', '-q', '-m', "Task $num: a-plan");

    my $branch = "${type}/${num}-${slug}";
    git_in($repo, 'checkout', '-q', '-b', $branch);

    return ($repo, $main_sha, $branch, $task_dir);
}

# Task 182: the helper now self-manages an output file under a main-tree-derived
# /tmp namespace and prints only a confirmation line to stdout. These .out dirs
# live OUTSIDE each synthetic repo's tempdir (they hang off the dashified main
# root), so tempdir(CLEANUP=>1) does not reap them — track and remove them here.
my @CLEANUP_OUT;
my @CLEANUP_SYMLINK;   # Task 203: parent symlinks planted by TC-PARENT-SYMLINK
END {
    # Task 203: scratch is now nested — <base>/cwf<dash>/task-<num>/<file>.
    # Remove the .out, then the now-empty task-<num> leaf, then the now-empty
    # cwf<dash> parent. Each rmdir is a no-op if other entries remain.
    for my $p (@CLEANUP_OUT) {
        next unless defined $p;
        unlink $p;
        (my $leaf = $p) =~ s{/[^/]+$}{};       # task-<num> leaf
        rmdir $leaf;
        (my $parent = $leaf) =~ s{/[^/]+$}{};  # cwf<dash> parent
        rmdir $parent;
    }
    # Planted parent symlinks (defence-in-depth negative test): unlink, never rmdir.
    for my $l (@CLEANUP_SYMLINK) {
        next unless defined $l;
        unlink $l if -l $l;
    }
}

# Run the helper with EXACTLY @args inside $cwd (no defaulting), return
# (stdout, stderr, exit). Any .out the helper reports is queued for cleanup.
sub run_helper_raw {
    my ($cwd, @args) = @_;
    $CAPTURE_SEQ++;
    my $stdout_file = "$CAPTURE_DIR/helper-stdout.$CAPTURE_SEQ";
    my $stderr_file = "$CAPTURE_DIR/helper-stderr.$CAPTURE_SEQ";
    my $orig = cwd();
    chdir $cwd or die "chdir $cwd: $!";
    my $rc;
    {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            open(STDOUT, '>', $stdout_file) or POSIX::_exit(127);
            open(STDERR, '>', $stderr_file) or POSIX::_exit(127);
            exec($HELPER, @args) or POSIX::_exit(127);
        }
        waitpid($pid, 0);
        $rc = $? >> 8;
    }
    chdir $orig;

    my $stdout = do { open my $fh, '<', $stdout_file or die; local $/; <$fh> };
    my $stderr = do { open my $fh, '<', $stderr_file or die; local $/; <$fh> };
    $stdout //= '';
    if ($stdout =~ /^security-review-changeset: wrote \d+ lines to (.+)$/m) {
        push @CLEANUP_OUT, $1;
    }
    # Task 223: an over-cap run also writes a doc-scoped .out in the same leaf.
    # Queue it for cleanup so the leaf rmdir succeeds.
    if ($stdout =~ /^security-review-changeset: wrote \d+ doc lines to (.+)$/m) {
        push @CLEANUP_OUT, $1;
    }
    return ($stdout, $stderr // '', $rc);
}

# Run the helper inside $cwd, injecting a default --wf-step=implementation-exec
# unless the caller supplied its own --wf-step. Existing subtests assert on
# changeset *content* and do not care which step labels the file, so the default
# keeps them green now that --wf-step is mandatory.
sub run_helper {
    my ($cwd, @args) = @_;
    unshift @args, '--wf-step=implementation-exec'
        unless grep { /^--wf-step=/ } @args;
    return run_helper_raw($cwd, @args);
}

# Parse the absolute .out path the helper reported on stdout (undef if none).
sub out_path {
    my ($stdout) = @_;
    return undef unless defined $stdout
        && $stdout =~ /^security-review-changeset: wrote \d+ lines to (.+)$/m;
    return $1;
}

# The count the helper reported in its confirmation line (undef if none).
sub confirm_count {
    my ($stdout) = @_;
    return undef unless defined $stdout
        && $stdout =~ /^security-review-changeset: wrote (\d+) lines to /m;
    return $1;
}

# Task 223: the doc-scoped confirmation line emitted on an over-cap breach when
# directory-structure.base-path is valid (undef when absent — the "docs not
# separable" signal the exec skill distinguishes from a present 0-count line).
sub doc_out_path {
    my ($stdout) = @_;
    return undef unless defined $stdout
        && $stdout =~ /^security-review-changeset: wrote \d+ doc lines to (.+)$/m;
    return $1;
}
sub doc_confirm_count {
    my ($stdout) = @_;
    return undef unless defined $stdout
        && $stdout =~ /^security-review-changeset: wrote (\d+) doc lines to /m;
    return $1;
}

# Read the doc-scoped changeset (Task 223). '' when no doc .out was produced.
sub doc_changeset_of {
    my ($stdout) = @_;
    my $p = doc_out_path($stdout);
    return '' unless defined $p && -e $p;
    open my $fh, '<:raw', $p or die "open $p: $!";
    local $/;
    my $c = <$fh>;
    close $fh;
    return $c // '';
}

# A cap-repo config carrying a directory-structure.base-path (Task 223). The
# base-path is included only when passed (so callers can model an ABSENT key).
# Deliberately NO seeded max-lines-exclude-paths unless the caller supplies one
# — the base-path markdown discount under test must not be masked by this repo's
# real excludes (test-isolation, misalignment F2).
sub cfg_basepath {
    my (%o) = @_;
    my %cfg = ( versioning => { major_minor => 'v1.0' } );
    $cfg{'directory-structure'} = { 'base-path' => $o{base_path} }
        if exists $o{base_path};
    $cfg{security} = { review => { 'max-lines-exclude-paths' => $o{exclude} } }
        if $o{exclude};
    return JSON::PP->new->canonical->encode(\%cfg);
}

# Read the changeset the helper wrote (the new diff destination). Returns ''
# when no .out was produced or the file is empty/absent.
sub changeset_of {
    my ($stdout) = @_;
    my $p = out_path($stdout);
    return '' unless defined $p && -e $p;
    open my $fh, '<:raw', $p or die "open $p: $!";
    local $/;
    my $c = <$fh>;
    close $fh;
    return $c // '';
}

# ---------------------------------------------------------------------------
# TC-F1: A changed file under .cwf/ is reviewed (path-independent inclusion).
# Pairs with TC-F5/F6/WIDEN1 (non-.cwf files) to show inclusion ignores path.
# The diff window also contains the fixture's a-task-plan.md (committed after
# the __MAIN__ baseline), so the file count is 2: the script + the plan.
# ---------------------------------------------------------------------------
subtest 'TC-F1: extensionless file under .cwf/scripts/ is reviewed' => sub {
    my ($repo, $main_sha, $branch, $task_dir) = make_synthetic_repo(baseline => '__MAIN__');

    make_path("$repo/.cwf/scripts");
    open my $fh, '>', "$repo/.cwf/scripts/cwf-foo" or die;
    print $fh "#!/usr/bin/perl\nprint \"x\";\n";
    close $fh;
    git_in($repo, 'add', '.cwf/scripts/cwf-foo');
    git_in($repo, 'commit', '-q', '-m', 'add cwf-foo');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0');
    like(changeset_of($out), qr{\.cwf/scripts/cwf-foo}, 'changeset includes the extensionless file');
    like($err, qr{reviewed 2 files}, 'stderr summary names 2 files (script + a-task-plan.md)');
};

# ---------------------------------------------------------------------------
# TC-F2: Consumer-stack source file is reviewed
# ---------------------------------------------------------------------------
subtest 'TC-F2: consumer-stack python file is included' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

    make_path("$repo/app");
    open my $fh, '>', "$repo/app/main.py" or die;
    print $fh "#!/usr/bin/env python3\nprint('hi')\n";
    close $fh;
    git_in($repo, 'add', 'app/main.py');
    git_in($repo, 'commit', '-q', '-m', 'add app/main.py');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0');
    like(changeset_of($out), qr{app/main\.py}, 'changeset includes consumer-stack python file (all files reviewed)');
};

# ---------------------------------------------------------------------------
# TC-F3: Earlier-task work is excluded when its branch is unmerged
# ---------------------------------------------------------------------------
subtest 'TC-F3: unmerged predecessor branch does not pollute the changeset' => sub {
    # Build: main → branch task1 (one commit) → return to main → branch task2.
    # task2's a-task-plan.md records baseline = main's tip.
    my $base = tempdir(CLEANUP => 1);
    my $repo = "$base/repo";
    make_path($repo);
    git_in($repo, 'init', '-q', '--initial-branch=main');
    git_in($repo, 'config', 'user.email', 'test@example.com');
    git_in($repo, 'config', 'user.name', 'CWFTest');
    git_in($repo, 'config', 'commit.gpgsign', 'false');

    open my $fh, '>', "$repo/README.md" or die;
    print $fh "seed\n";
    close $fh;
    git_in($repo, 'add', 'README.md');
    git_in($repo, 'commit', '-q', '-m', 'seed');
    my $main_sha = git_capture($repo, 'rev-parse', 'HEAD');

    # task1 branch: add a script (which would be classified as security-relevant
    # if it leaked into task2's review).
    git_in($repo, 'checkout', '-q', '-b', 'feature/1-task1');
    make_path("$repo/.cwf/scripts");
    open my $t1, '>', "$repo/.cwf/scripts/task1-leak" or die;
    print $t1 "#!/usr/bin/perl\nprint \"task1\";\n";
    close $t1;
    git_in($repo, 'add', '.cwf/scripts/task1-leak');
    git_in($repo, 'commit', '-q', '-m', 'task1 work');

    # task2 branch from main's tip (NOT from task1).
    git_in($repo, 'checkout', '-q', $main_sha);
    git_in($repo, 'checkout', '-q', '-b', 'bugfix/2-task2');

    # task2's task dir + recorded baseline = main's tip.
    my $task_dir = "$repo/implementation-guide/2-bugfix-task2";
    make_path($task_dir);
    open my $a, '>', "$task_dir/a-task-plan.md" or die;
    print $a "# Plan\n\n## Task Reference\n";
    print $a "- **Branch**: bugfix/2-task2\n";
    print $a "- **Baseline Commit**: $main_sha\n";
    print $a "- **Template Version**: 2.1\n";
    close $a;
    git_in($repo, 'add', 'implementation-guide/');
    git_in($repo, 'commit', '-q', '-m', 'task2 a-plan');

    # task2's actual change.
    make_path("$repo/.cwf/scripts");
    open my $t2, '>', "$repo/.cwf/scripts/task2-work" or die "open task2-work: $!";
    print $t2 "#!/usr/bin/perl\nprint \"task2\";\n";
    close $t2;
    git_in($repo, 'add', '.cwf/scripts/task2-work');
    git_in($repo, 'commit', '-q', '-m', 'task2 work');

    my ($out, $err, $rc) = run_helper($repo);
    my $cs = changeset_of($out);
    is($rc, 0, 'helper exits 0');
    like($cs, qr{task2-work}, 'task2 work is in the changeset');
    unlike($cs, qr{task1-leak}, 'task1 work is NOT in the changeset (closes BACKLOG axis 3)');
};

# ---------------------------------------------------------------------------
# TC-F4: Binary file under .cwf/ is reviewed (no file-type or path filter)
# ---------------------------------------------------------------------------
subtest 'TC-F4: binary file under .cwf/scripts/ is reviewed' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

    make_path("$repo/.cwf/scripts");
    open my $fh, '>:raw', "$repo/.cwf/scripts/blob" or die;
    print $fh "\xff\xfe\x00\x00binarystuff\xa3\xa4";
    close $fh;
    git_in($repo, 'add', '.cwf/scripts/blob');
    git_in($repo, 'commit', '-q', '-m', 'binary blob');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0');
    like(changeset_of($out), qr{\.cwf/scripts/blob}, 'binary file is included (all files reviewed)');
};

# ---------------------------------------------------------------------------
# TC-F5: Binary blob outside CWF dirs is reviewed (all files included)
# ---------------------------------------------------------------------------
subtest 'TC-F5: binary blob outside CWF dirs is reviewed' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

    make_path("$repo/tools");
    open my $fh, '>:raw', "$repo/tools/blob" or die;
    print $fh "\xff\xfe\x00\x00not-a-script";
    close $fh;
    git_in($repo, 'add', 'tools/blob');
    git_in($repo, 'commit', '-q', '-m', 'binary tool');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0');
    like(changeset_of($out), qr{tools/blob}, 'binary outside CWF dirs is now reviewed (all files included)');
    like($err, qr{reviewed 2 files}, 'two files: tools/blob + the fixture a-task-plan.md');
};

# ---------------------------------------------------------------------------
# TC-F6: Plain-text file outside CWF dirs is reviewed (all files included)
# ---------------------------------------------------------------------------
subtest 'TC-F6: plain-text notes outside CWF dirs are reviewed' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

    open my $fh, '>', "$repo/notes.txt" or die;
    print $fh "Just a plain text file.\n";
    close $fh;
    git_in($repo, 'add', 'notes.txt');
    git_in($repo, 'commit', '-q', '-m', 'notes');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0');
    like(changeset_of($out), qr{notes\.txt}, 'plain text outside CWF dirs is reviewed');
};

# ---------------------------------------------------------------------------
# TC-F7: Subtask baseline resolves correctly
# ---------------------------------------------------------------------------
subtest 'TC-F7: subtask num resolves into nested directory' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $repo = "$base/repo";
    make_path($repo);
    git_in($repo, 'init', '-q', '--initial-branch=main');
    git_in($repo, 'config', 'user.email', 'test@example.com');
    git_in($repo, 'config', 'user.name', 'CWFTest');
    git_in($repo, 'config', 'commit.gpgsign', 'false');

    open my $fh, '>', "$repo/README.md" or die;
    print $fh "seed\n";
    close $fh;
    git_in($repo, 'add', 'README.md');
    git_in($repo, 'commit', '-q', '-m', 'seed');
    my $main_sha = git_capture($repo, 'rev-parse', 'HEAD');

    # Build parent + nested subtask directories.
    my $parent_dir  = "$repo/implementation-guide/1-feature-parent";
    my $subtask_dir = "$parent_dir/1.1-bugfix-sub";
    make_path($subtask_dir);

    # Parent a-task-plan exists but is irrelevant for the subtask query.
    open my $p, '>', "$parent_dir/a-task-plan.md" or die;
    print $p "# Plan\n";
    close $p;

    # Subtask records its own baseline.
    open my $s, '>', "$subtask_dir/a-task-plan.md" or die;
    print $s "# Plan\n\n## Task Reference\n";
    print $s "- **Baseline Commit**: $main_sha\n";
    close $s;
    git_in($repo, 'add', 'implementation-guide/');
    git_in($repo, 'commit', '-q', '-m', 'parent + sub a-plans');

    git_in($repo, 'checkout', '-q', '-b', 'bugfix/1.1-sub');
    make_path("$repo/.cwf/scripts");
    open my $w, '>', "$repo/.cwf/scripts/sub-work" or die;
    print $w "#!/usr/bin/perl\nprint 'sub';\n";
    close $w;
    git_in($repo, 'add', '.cwf/scripts/sub-work');
    git_in($repo, 'commit', '-q', '-m', 'sub work');

    my ($out, $err, $rc) = run_helper($repo, '--task-num=1.1');
    is($rc, 0, 'helper exits 0 for subtask');
    like(changeset_of($out), qr{sub-work}, 'subtask change is in the changeset');
};

# ---------------------------------------------------------------------------
# TC-F8: Format-unexpected baseline line warns and falls back
# ---------------------------------------------------------------------------
subtest 'TC-F8: malformed Baseline Commit line warns and falls back to merge-base' => sub {
    my ($repo) = make_synthetic_repo(baseline_raw => "- **Baseline Commit**: not-a-sha-at-all\n");

    make_path("$repo/.cwf/scripts");
    open my $fh, '>', "$repo/.cwf/scripts/foo" or die;
    print $fh "#!/usr/bin/perl\nprint 'x';\n";
    close $fh;
    git_in($repo, 'add', '.cwf/scripts/foo');
    git_in($repo, 'commit', '-q', '-m', 'add foo');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper still exits 0 (fell back to merge-base)');
    like($err, qr{Baseline Commit line found but format unexpected}, 'warning emitted');
    like(changeset_of($out), qr{\.cwf/scripts/foo}, 'changeset still produced via fallback path');
};

# ---------------------------------------------------------------------------
# TC-NF1 (Security): Trunk-name with `..` is rejected
# ---------------------------------------------------------------------------
subtest 'TC-NF1: trunk name with `..` is rejected by check-ref-format' => sub {
    # In-flight task layout: baseline field absent, cwf-project.json:trunk = "..".
    my $base = tempdir(CLEANUP => 1);
    my $repo = "$base/repo";
    make_path($repo);
    git_in($repo, 'init', '-q', '--initial-branch=main');
    git_in($repo, 'config', 'user.email', 'test@example.com');
    git_in($repo, 'config', 'user.name', 'CWFTest');
    git_in($repo, 'config', 'commit.gpgsign', 'false');

    open my $fh, '>', "$repo/README.md" or die;
    print $fh "seed\n";
    close $fh;
    git_in($repo, 'add', 'README.md');
    git_in($repo, 'commit', '-q', '-m', 'seed');

    # Task dir, no baseline.
    my $task_dir = "$repo/implementation-guide/1-bugfix-test";
    make_path($task_dir);
    open my $a, '>', "$task_dir/a-task-plan.md" or die;
    print $a "# Plan\n";
    close $a;

    # cwf-project.json with malicious trunk. We need versioning.major_minor
    # so read_config doesn't die — but eval-wrap means even a bare-bones
    # config that fails read_config will just fall through to symbolic-ref.
    # To force the trunk-tier-1 hit we need read_config to succeed.
    my $cfg_dir = "$repo/implementation-guide";
    open my $c, '>', "$cfg_dir/cwf-project.json" or die;
    print $c <<'JSON';
{
  "versioning": {"major_minor": "v1.0"},
  "trunk": ".."
}
JSON
    close $c;
    git_in($repo, 'add', 'implementation-guide/');
    git_in($repo, 'commit', '-q', '-m', 'task setup');
    git_in($repo, 'checkout', '-q', '-b', 'bugfix/1-test');

    my ($out, $err, $rc) = run_helper($repo);
    isnt($rc, 0, 'helper exits non-zero on malicious trunk');
    like($err, qr{not a valid git branch reference}, 'diagnostic names the validation failure');
};

# ---------------------------------------------------------------------------
# TC-NF2 (Security): --task-num with non-numeric input is rejected
# ---------------------------------------------------------------------------
subtest 'TC-NF2: --task-num with non-numeric input is rejected up front' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');
    my ($out, $err, $rc) = run_helper($repo, '--task-num=foo;rm -rf /');
    is($rc, 1, 'exit code is 1');
    like($err, qr{invalid --task-num}, 'diagnostic names the validation regex');
    is($out, '', 'no stdout produced');
};

# ---------------------------------------------------------------------------
# TC-GUARD1a (guard-removal safety): symlink is reviewed; git emits the
# link-TARGET text as the blob and never dereferences/reads the target. Sole
# evidence that deleting looks_like_script's -l guard is DoS-net-neutral (D1).
# ---------------------------------------------------------------------------
subtest 'TC-GUARD1a: symlink is reviewed without dereferencing the target' => sub {
    SKIP: {
        # Symlinks may not be supported on the test filesystem.
        skip 'symlinks not supported here', 3 unless eval { symlink('', ''); 1 } || $!;

        my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

        # Symlink outside CWF dirs pointing at /dev/null. git stores the link
        # TARGET as the blob content; it does not open/read /dev/null.
        symlink('/dev/null', "$repo/dangerous-link") or do {
            skip 'cannot create symlink in tempdir', 3;
        };
        git_in($repo, 'add', 'dangerous-link');
        git_in($repo, 'commit', '-q', '-m', 'add symlink');

        my ($out, $err, $rc) = run_helper($repo);
        my $cs = changeset_of($out);
        is($rc, 0, 'helper exits 0');
        like($cs, qr{dangerous-link}, 'symlink path is now reviewed (no -l guard skips it)');
        like($cs, qr{^\+/dev/null$}m,
             'diff body is the link-target string, proving git did not dereference it');
    }
};

# ---------------------------------------------------------------------------
# TC-GUARD1b (guard-removal safety): a FIFO in the working tree does not make
# the helper hang. With the content sniff (looks_like_script) deleted, the
# helper never opens working-tree files, so non-regular files cannot block it.
# ---------------------------------------------------------------------------
subtest 'TC-GUARD1b: FIFO in working tree does not block the helper' => sub {
    SKIP: {
        eval { require POSIX; POSIX->can('mkfifo') or die "no mkfifo" };
        skip 'POSIX::mkfifo unavailable', 2 if $@;

        my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

        # A real committed change so the diff is non-empty.
        make_path("$repo/.cwf/scripts");
        open my $w, '>', "$repo/.cwf/scripts/real-work" or die;
        print $w "#!/usr/bin/perl\nprint 'x';\n";
        close $w;
        git_in($repo, 'add', '.cwf/scripts/real-work');
        git_in($repo, 'commit', '-q', '-m', 'real work');

        # A FIFO in the working tree (untracked; git ignores it for diff, and
        # the helper never opens it). Pre-fix, a sniff of this would block.
        my $fifo = "$repo/dangerous-fifo";
        my $rc_fifo = POSIX::mkfifo($fifo, oct('0600'));
        skip "mkfifo failed: $!", 2 unless defined $rc_fifo && $rc_fifo == 0;

        my $t0 = time();
        my ($out, $err, $rc) = run_helper($repo);
        my $elapsed = time() - $t0;

        is($rc, 0, 'helper exits 0 with a FIFO present (does not hang)');
        cmp_ok($elapsed, '<', 5, 'helper completes promptly — never blocks on the FIFO');
    }
};

# ---------------------------------------------------------------------------
# TC-NF5 (Performance): Helper completes in O(diff size), not O(repo size)
# ---------------------------------------------------------------------------
subtest 'TC-NF5: helper completes quickly with large working tree but small diff' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

    # Add 200 noise files committed on the task branch (baseline = main's tip,
    # so they ARE in the diff). All 200 are now reviewed (every changed file is
    # included), yet the helper stays fast: git diff is O(diff size) and the
    # helper does no per-file content sniff. Bounded by diff size, not repo size.
    make_path("$repo/noise");
    for my $i (1 .. 200) {
        open my $fh, '>', "$repo/noise/file$i.txt" or die;
        print $fh "noise $i\n";
        close $fh;
    }
    git_in($repo, 'add', 'noise/');
    git_in($repo, 'commit', '-q', '-m', '200 noise files');

    my $t0 = time();
    my ($out, $err, $rc) = run_helper($repo);
    my $elapsed = time() - $t0;

    is($rc, 0, 'helper exits 0');
    cmp_ok($elapsed, '<', 5, 'helper completes in under 5 seconds with 200-file diff');
    like(changeset_of($out), qr{noise/file}, 'all 200 changed files are reviewed');
};

# ---------------------------------------------------------------------------
# TC-Task141-uncommitted: helper sees staged and unstaged changes
# Regression for Task 141: prior helper diffed `anchor..HEAD` only, so any
# invocation before the exec-phase checkpoint commit returned an empty diff.
# Uses two paths to prove both halves of the working tree are scanned:
#   - staged-script: new file, `git add`ed, not committed (index-side change).
#   - baseline-script: file committed on the task branch, then modified
#     without `git add` (working-tree-side change to a tracked file).
# Note: an untracked file (no `git add`) would NOT appear here because
# `git diff` ignores untracked files by design — see c-design-plan.md
# § "Behavioural notes on the widened diff window".
# ---------------------------------------------------------------------------
subtest 'TC-Task141-uncommitted: helper sees staged and unstaged changes' => sub {
    my ($repo, $main_sha, $branch, $task_dir) = make_synthetic_repo(baseline => '__MAIN__');

    make_path("$repo/.cwf/scripts");

    # File 1: commit a script on the task branch, then modify it without
    # `git add` — proves working-tree-side changes to a tracked file are
    # picked up by the widened diff window.
    open my $b_fh, '>', "$repo/.cwf/scripts/baseline-script" or die;
    print $b_fh "#!/usr/bin/perl\nprint \"BASELINE_141\";\n";
    close $b_fh;
    git_in($repo, 'add', '.cwf/scripts/baseline-script');
    git_in($repo, 'commit', '-q', '-m', 'baseline script');

    # Working-tree-only modification (no git add).
    open my $m_fh, '>', "$repo/.cwf/scripts/baseline-script" or die;
    print $m_fh "#!/usr/bin/perl\nprint \"BASELINE_141\";\nprint \"UNSTAGED_MOD_141\";\n";
    close $m_fh;

    # File 2: new file, staged only — proves index-side changes are picked up.
    open my $s_fh, '>', "$repo/.cwf/scripts/staged-script" or die;
    print $s_fh "#!/usr/bin/perl\nprint \"STAGED_141\";\n";
    close $s_fh;
    git_in($repo, 'add', '.cwf/scripts/staged-script');

    my ($out, $err, $rc) = run_helper($repo);
    my $cs = changeset_of($out);

    is($rc, 0, 'helper exits 0');
    like($cs, qr{\.cwf/scripts/staged-script},
         'staged-only file appears in diff (index-side change picked up)');
    like($cs, qr{\.cwf/scripts/baseline-script},
         'modified tracked file appears in diff');
    like($cs, qr{UNSTAGED_MOD_141},
         'working-tree-only modification content appears in diff (not just the committed baseline)');
    like($err, qr{^reviewed 3 files,.+anchor=[0-9a-f]{7}, includes uncommitted$}m,
         'stderr summary anchors disclosure suffix to summary line, count=3 (2 scripts + a-task-plan.md)');
};

# ===========================================================================
# Production-weighted cap (--max-lines) — Task 168
# ===========================================================================

# Build a repo where cwf-project.json AND the task's a-task-plan.md are both
# committed on main, then the task branch is created from main. The a-task-plan
# carries NO baseline line, so the helper anchors on merge-base(HEAD, main) —
# the branch point — and the diff window contains ONLY what each test commits on
# the branch. Now that the review covers every changed file (Task 174), pinning
# the anchor at the branch point is what keeps production counts measuring
# exactly the test's own files (no a-task-plan.md / config noise). Returns
# ($repo, $baseline, $branch, $task_dir); $baseline is the merge-base commit.
# %opt: config_json (required), num/type/slug (optional).
sub make_cap_repo {
    my (%opt) = @_;
    my $base = tempdir(CLEANUP => 1);
    my $repo = "$base/repo";
    make_path($repo);
    git_in($repo, 'init', '-q', '--initial-branch=main');
    git_in($repo, 'config', 'user.email', 'test@example.com');
    git_in($repo, 'config', 'user.name', 'CWFTest');
    git_in($repo, 'config', 'commit.gpgsign', 'false');

    open my $fh, '>', "$repo/README.md" or die;
    print $fh "seed\n";
    close $fh;
    git_in($repo, 'add', 'README.md');
    git_in($repo, 'commit', '-q', '-m', 'seed');

    # cwf-project.json on main.
    make_path("$repo/implementation-guide");
    open my $c, '>', "$repo/implementation-guide/cwf-project.json" or die;
    print $c $opt{config_json};
    close $c;
    git_in($repo, 'add', 'implementation-guide/cwf-project.json');
    git_in($repo, 'commit', '-q', '-m', 'cwf-project.json');

    my $num  = $opt{num}  // '1';
    my $type = $opt{type} // 'chore';
    my $slug = $opt{slug} // 'cap-test';

    # a-task-plan.md on main too, with NO baseline line → the helper falls back
    # to merge-base(HEAD, main). Committing it at the branch point keeps it OUT
    # of the measured diff window.
    my $task_dir = "$repo/implementation-guide/${num}-${type}-${slug}";
    make_path($task_dir);
    open my $a, '>', "$task_dir/a-task-plan.md" or die;
    print $a "# Plan\n\n## Task Reference\n";
    print $a "- **Branch**: ${type}/${num}-${slug}\n";
    print $a "- **Template Version**: 2.1\n";
    close $a;
    git_in($repo, 'add', 'implementation-guide/');
    git_in($repo, 'commit', '-q', '-m', "task $num a-plan");

    # Branch point = the merge-base the helper will anchor on.
    my $baseline = git_capture($repo, 'rev-parse', 'HEAD');

    my $branch = "${type}/${num}-${slug}";
    git_in($repo, 'checkout', '-q', '-b', $branch);
    return ($repo, $baseline, $branch, $task_dir);
}

my $CFG_NO_TESTPATHS = <<'JSON';
{ "versioning": { "major_minor": "v1.0" } }
JSON

my $CFG_T_GLOB = <<'JSON';
{ "versioning": { "major_minor": "v1.0" },
  "security": { "review": { "max-lines-exclude-paths": ["t/**"] } } }
JSON

# Write a file of $n total lines (line 1 is a #!/usr/bin/perl header line).
sub write_script {
    my ($path, $n) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print $fh "#!/usr/bin/perl\n";
    print $fh "print \"line $_\";\n" for (2 .. $n);
    close $fh;
}

# ---------------------------------------------------------------------------
# TC-CAP1: production-only diff over the cap → exit 2
# ---------------------------------------------------------------------------
subtest 'TC-CAP1: production-only diff exceeding --max-lines exits 2' => sub {
    my ($repo) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);

    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/big-script", 30);
    git_in($repo, 'add', '.cwf/scripts/big-script');
    git_in($repo, 'commit', '-q', '-m', 'big script');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=10');
    is($rc, 2, 'helper exits 2 on cap breach');
    like($err, qr{cap exceeded: \d+ production lines > 10}, 'stderr names the breach');
    like(changeset_of($out), qr{\.cwf/scripts/big-script},
         'full diff written to the .out file even on cap breach (AC7)');
    like($out, qr{^security-review-changeset: wrote \d+ lines to }m,
         'confirmation line printed before exit 2 — caller can recover the path (AC7)');
};

# ---------------------------------------------------------------------------
# TC-CAP2: task-166 shape — small production + large test diff stays under cap
# ---------------------------------------------------------------------------
subtest 'TC-CAP2: large t/ diff is discounted; production stays under cap' => sub {
    my ($repo) = make_cap_repo(config_json => $CFG_T_GLOB);

    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/small", 5);          # ~production
    make_path("$repo/t");
    write_script("$repo/t/big.t", 50);                    # test scaffolding
    git_in($repo, 'add', '.cwf/scripts/small', 't/big.t');
    git_in($repo, 'commit', '-q', '-m', 'small prod + big test');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=20');
    is($rc, 0, 'helper exits 0 (production under cap despite large raw diff)');
    like(changeset_of($out), qr{t/big\.t}, 'test file is in the changeset (all files reviewed)');
    ($err =~ /(\d+) lines \((\d+) production\)/)
        or do { fail('stderr summary has the "(P production)" field'); return };
    my ($raw, $prod) = ($1, $2);
    cmp_ok($prod, '<', $raw, 'production count is below the raw line count');
    cmp_ok($prod, '<=', 20, 'production count is within the cap (t/ excluded)');
};

# ---------------------------------------------------------------------------
# TC-CAP3: absent --max-lines now DEFAULTS to 1000 (Task 182 introduced the cap;
# Task 221 raised it from 500). A sub-1000 diff still passes with exit 0 and no
# cap message — the behaviour-neutral half of the default change. The >1000
# (default-fires) half is TC-DEFAULTCAP below.
# ---------------------------------------------------------------------------
subtest 'TC-CAP3: absent --max-lines defaults to 1000; a sub-1000 diff passes' => sub {
    my ($repo) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);

    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/huge", 200);   # 200 production lines < 1000
    git_in($repo, 'add', '.cwf/scripts/huge');
    git_in($repo, 'commit', '-q', '-m', 'huge script');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0 (200 production < default cap of 1000)');
    unlike($err, qr{cap exceeded}, 'no cap message — under the default cap');
};

# ---------------------------------------------------------------------------
# TC-CAP4: production count excludes test + context/header lines
# ---------------------------------------------------------------------------
subtest 'TC-CAP4: production count is added+deleted of non-test files only' => sub {
    my ($repo) = make_cap_repo(config_json => $CFG_T_GLOB);

    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/prod", 4);           # exactly 4 added lines
    make_path("$repo/t");
    write_script("$repo/t/extra.t", 20);
    git_in($repo, 'add', '.cwf/scripts/prod', 't/extra.t');
    git_in($repo, 'commit', '-q', '-m', 'prod + test');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=1000');
    is($rc, 0, 'helper exits 0 (well under cap)');
    like($err, qr{\(4 production\)},
         'production = 4 added lines of the non-test file (test + context excluded)');
    ($err =~ /(\d+) lines \(\d+ production\)/)
        and cmp_ok($1, '>', 4, 'raw line count is larger (headers/context/test included)');
};

# ---------------------------------------------------------------------------
# TC-CAP5: --max-lines argument validation → exit 1
# ---------------------------------------------------------------------------
subtest 'TC-CAP5: invalid --max-lines values are rejected with exit 1' => sub {
    my ($repo) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);
    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/x", 3);
    git_in($repo, 'add', '.cwf/scripts/x');
    git_in($repo, 'commit', '-q', '-m', 'x');

    for my $bad (qw(abc 0 007)) {
        my ($out, $err, $rc) = run_helper($repo, "--max-lines=$bad");
        is($rc, 1, "--max-lines=$bad exits 1");
        like($err, qr{invalid --max-lines}, "--max-lines=$bad names the validation failure");
    }
};

# ---------------------------------------------------------------------------
# TC-CAP6: binary production file contributes 0 to the count
# ---------------------------------------------------------------------------
subtest 'TC-CAP6: binary file in the diff contributes 0 production lines' => sub {
    my ($repo) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);

    make_path("$repo/.cwf/scripts");
    open my $b, '>:raw', "$repo/.cwf/scripts/blob" or die;
    print $b "\xff\xfe\x00\x00binarystuff\xa3\xa4" x 100;   # large binary
    close $b;
    write_script("$repo/.cwf/scripts/txt", 3);              # 3 text lines
    git_in($repo, 'add', '.cwf/scripts/blob', '.cwf/scripts/txt');
    git_in($repo, 'commit', '-q', '-m', 'binary + small text');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=10');
    is($rc, 0, 'helper exits 0 (binary counted as 0, not its byte size)');
    like($err, qr{\(3 production\)}, 'production = 3 (text only); binary numstat "-" → 0');
};

# ---------------------------------------------------------------------------
# TC-CAP7: malformed exclude-paths pattern fails safe (exit 1, no silent discount)
# ---------------------------------------------------------------------------
subtest 'TC-CAP7: outside-repo max-lines-exclude-paths pattern makes git fatal → exit 1' => sub {
    my $cfg = <<'JSON';
{ "versioning": { "major_minor": "v1.0" },
  "security": { "review": { "max-lines-exclude-paths": ["../escape"] } } }
JSON
    my ($repo) = make_cap_repo(config_json => $cfg);

    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/prod", 5);
    git_in($repo, 'add', '.cwf/scripts/prod');
    git_in($repo, 'commit', '-q', '-m', 'prod');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=100');
    is($rc, 1, 'helper exits 1 when git rejects the exclude pathspec (safe fail)');
    unlike($err, qr{cap exceeded}, 'no cap verdict — bad config never yields a silent discount');
};

# ===========================================================================
# Review-all-files behaviour — Task 174
# ===========================================================================

# ---------------------------------------------------------------------------
# TC-WIDEN1: a non-script consumer source file is reviewed AND counts as
# production. The headline of the bugfix — a consumer's application code
# (no special treatment, outside .cwf/.claude) now reaches both the review
# and the cap count.
# ---------------------------------------------------------------------------
subtest 'TC-WIDEN1: consumer source file is reviewed and counts as production' => sub {
    my ($repo) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);

    make_path("$repo/src");
    open my $fh, '>', "$repo/src/app.js" or die;
    print $fh "function hello() {\n";
    print $fh "  return 'hi';\n";
    print $fh "}\n";
    close $fh;
    git_in($repo, 'add', 'src/app.js');
    git_in($repo, 'commit', '-q', '-m', 'consumer app code');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=1000');
    is($rc, 0, 'helper exits 0');
    like(changeset_of($out), qr{src/app\.js}, 'consumer source file is in the reviewed changeset');
    ($err =~ /\((\d+) production\)/)
        or do { fail('stderr summary has the production field'); return };
    cmp_ok($1, '>', 0, 'consumer source lines count toward the production total');
};

# ---------------------------------------------------------------------------
# TC-CAP8: with NO test-paths configured, a changed test file counts as
# production (fail-safe direction — the cap fires earlier, never later).
# Pairs with TC-CAP2 (configured t/** → discounted → under cap).
# ---------------------------------------------------------------------------
subtest 'TC-CAP8: unconfigured test path counts as production' => sub {
    my ($repo) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);

    make_path("$repo/t");
    write_script("$repo/t/foo.t", 50);
    git_in($repo, 'add', 't/foo.t');
    git_in($repo, 'commit', '-q', '-m', 'test file, no test-paths config');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=10');
    is($rc, 2, 'cap fires: test file counts as production when test-paths unset');
    like($err, qr{cap exceeded: \d+ production lines > 10}, 'breach names the production count');
};

# ---------------------------------------------------------------------------
# TC-EMPTY1 (also covers AC4.3): a genuinely empty diff (anchor == worktree)
# yields exit 0, "reviewed 0 files", and — under the Task 182 contract — a
# 0-line .out file plus a confirmation line reporting count 0 (NOT empty
# stdout, the old discriminator). Proves the unified write path produces ''
# for @included empty, so a bare `git diff $anchor --` (whole-tree) never runs.
# ---------------------------------------------------------------------------
subtest 'TC-EMPTY1: empty diff → 0-line .out + count-0 confirmation (no whole-tree leak)' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $repo = "$base/repo";
    make_path($repo);
    git_in($repo, 'init', '-q', '--initial-branch=main');
    git_in($repo, 'config', 'user.email', 'test@example.com');
    git_in($repo, 'config', 'user.name', 'CWFTest');
    git_in($repo, 'config', 'commit.gpgsign', 'false');

    open my $fh, '>', "$repo/README.md" or die;
    print $fh "seed\n";
    close $fh;
    git_in($repo, 'add', 'README.md');
    git_in($repo, 'commit', '-q', '-m', 'seed');

    # Task dir with NO baseline line → helper falls back to merge-base HEAD main.
    my $task_dir = "$repo/implementation-guide/1-bugfix-empty";
    make_path($task_dir);
    open my $a, '>', "$task_dir/a-task-plan.md" or die;
    print $a "# Plan\n\n## Task Reference\n- **Branch**: bugfix/1-empty\n";
    close $a;
    git_in($repo, 'add', 'implementation-guide/');
    git_in($repo, 'commit', '-q', '-m', 'task setup');

    # Task branch points at the same commit as main → merge-base == HEAD →
    # empty diff window, clean worktree.
    git_in($repo, 'checkout', '-q', '-b', 'bugfix/1-empty');

    my ($out, $err, $rc) = run_helper($repo, '--task-num=1');
    is($rc, 0, 'helper exits 0 on an empty changeset');
    like($err, qr{reviewed 0 files}, 'summary reports zero files');
    like($out, qr{^security-review-changeset: wrote 0 lines to }m,
         'stdout is the confirmation line reporting count 0 (not empty stdout)');
    is(confirm_count($out), 0, 'reported count is 0');
    is(changeset_of($out), '', '.out file written but empty — no whole-tree diff leaked');
};

# ---------------------------------------------------------------------------
# TC-CAP9: the deprecated `test-paths` key is still honoured (with a warning),
# so an adopter who set the old name does not silently lose their exclusions
# when CWF renamed it to max-lines-exclude-paths (Task 174).
# ---------------------------------------------------------------------------
subtest 'TC-CAP9: deprecated test-paths key still discounts, with a warning' => sub {
    my $cfg = <<'JSON';
{ "versioning": { "major_minor": "v1.0" },
  "security": { "review": { "test-paths": ["t/**"] } } }
JSON
    my ($repo) = make_cap_repo(config_json => $cfg);

    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/small", 5);
    make_path("$repo/t");
    write_script("$repo/t/big.t", 50);
    git_in($repo, 'add', '.cwf/scripts/small', 't/big.t');
    git_in($repo, 'commit', '-q', '-m', 'small prod + big test (legacy key)');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=20');
    is($rc, 0, 'legacy test-paths still discounts t/** → production under cap');
    like($err, qr{'security\.review\.test-paths' is deprecated},
         'deprecation warning emitted for the legacy key');
};

# ===========================================================================
# Agent-invocation contract — Task 182
# ===========================================================================

# ---------------------------------------------------------------------------
# TC-WFSTEP-REJECT (AC1/AC2): the removed --phase, an unknown --wf-step, a
# traversal-shaped --wf-step, and a missing --wf-step are all rejected with
# exit 1 and no confirmation line on stdout (no partial output). Uses the RAW
# runner so the default-injection wrapper does not mask the missing-flag case.
# ---------------------------------------------------------------------------
subtest 'TC-WFSTEP-REJECT: bad/missing --wf-step (and removed --phase) exit 1' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');
    make_path("$repo/.cwf/scripts");
    open my $fh, '>', "$repo/.cwf/scripts/foo" or die;
    print $fh "#!/usr/bin/perl\nprint 'x';\n";
    close $fh;
    git_in($repo, 'add', '.cwf/scripts/foo');
    git_in($repo, 'commit', '-q', '-m', 'foo');

    my @cases = (
        ['--phase=implementation'],   # removed flag → unknown argument
        ['--wf-step=bogus'],          # not in the allowlist
        ['--wf-step=../escape'],      # traversal-shaped
        [],                           # missing entirely
    );
    for my $args (@cases) {
        my $label = @$args ? $args->[0] : '(no --wf-step)';
        my ($out, $err, $rc) = run_helper_raw($repo, @$args);
        is($rc, 1, "$label exits 1");
        unlike($out, qr{^security-review-changeset: wrote}m,
               "$label writes no confirmation line (no partial output)");
    }
};

# ---------------------------------------------------------------------------
# TC-WFSTEP-ACCEPT (AC2): a non-exec allowlisted step is accepted and labels
# the output filename, proving the allowlist breadth is real (not just the two
# exec steps).
# ---------------------------------------------------------------------------
subtest 'TC-WFSTEP-ACCEPT: --wf-step=design-plan accepted; filename carries the step' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');
    make_path("$repo/.cwf/scripts");
    open my $fh, '>', "$repo/.cwf/scripts/foo" or die;
    print $fh "#!/usr/bin/perl\nprint 'x';\n";
    close $fh;
    git_in($repo, 'add', '.cwf/scripts/foo');
    git_in($repo, 'commit', '-q', '-m', 'foo');

    my ($out, $err, $rc) = run_helper($repo, '--wf-step=design-plan');
    is($rc, 0, 'design-plan accepted (exit 0)');
    like(out_path($out), qr{/security-review-changeset-design-plan\.out$},
         'output filename carries the wf-step');
};

# ---------------------------------------------------------------------------
# TC-DEFAULTCAP (AC4, Task 221): with NO --max-lines, a >1000-production diff
# trips the default cap (exit 2); an explicit large --max-lines override lets it
# through. Re-baselined from 500 to the raised built-in default of 1000.
# ---------------------------------------------------------------------------
subtest 'TC-DEFAULTCAP: default cap of 1000 fires; explicit override lifts it' => sub {
    my ($repo) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);
    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/big", 1020);  # 1020 production lines > 1000
    git_in($repo, 'add', '.cwf/scripts/big');
    git_in($repo, 'commit', '-q', '-m', 'big script');

    my ($o1, $e1, $r1) = run_helper($repo);
    is($r1, 2, 'no --max-lines: default cap of 1000 fires (exit 2)');
    like($e1, qr{cap exceeded: \d+ production lines > 1000}, 'breach names the default cap of 1000');

    my ($o2, $e2, $r2) = run_helper($repo, '--max-lines=100000');
    is($r2, 0, 'explicit --max-lines=100000 override lets the same diff through');
};

# ---------------------------------------------------------------------------
# TC-CAPBOUNDARY (AC4, Task 221): pin both sides of the 1000 default boundary
# with no flag/config — exactly 1000 passes, 1001 exits 2.
# ---------------------------------------------------------------------------
subtest 'TC-CAPBOUNDARY: 1000 passes, 1001 exits 2 at the default cap' => sub {
    my ($repo_pass) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);
    make_path("$repo_pass/.cwf/scripts");
    write_script("$repo_pass/.cwf/scripts/big", 1000);  # exactly 1000 production lines
    git_in($repo_pass, 'add', '.cwf/scripts/big');
    git_in($repo_pass, 'commit', '-q', '-m', 'exactly 1000');
    my ($op, $ep, $rp) = run_helper($repo_pass);
    is($rp, 0, 'exactly 1000 production lines passes at the default cap (exit 0)');

    my ($repo_fail) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);
    make_path("$repo_fail/.cwf/scripts");
    write_script("$repo_fail/.cwf/scripts/big", 1001);  # one over
    git_in($repo_fail, 'add', '.cwf/scripts/big');
    git_in($repo_fail, 'commit', '-q', '-m', 'one over 1000');
    my ($of, $eff, $rf) = run_helper($repo_fail);
    is($rf, 2, '1001 production lines trips the default cap (exit 2)');
};

# ---------------------------------------------------------------------------
# TC-OUTFILE (AC4): a non-empty change is written to the canonical .out path
# at mode 0600 inside a 0700 dir; the diff is in the file and NOT on stdout.
# ---------------------------------------------------------------------------
subtest 'TC-OUTFILE: changeset written to 0600 .out in 0700 dir; stdout carries no diff' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');
    make_path("$repo/.cwf/scripts");
    open my $fh, '>', "$repo/.cwf/scripts/foo" or die;
    print $fh "#!/usr/bin/perl\nprint 'x';\n";
    close $fh;
    git_in($repo, 'add', '.cwf/scripts/foo');
    git_in($repo, 'commit', '-q', '-m', 'foo');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0');
    my $p = out_path($out);
    ok(defined $p && -f $p, '.out file exists at the reported path');
    is(((stat($p))[2] & 07777), 0600, '.out file mode is 0600');
    (my $dir = $p) =~ s{/[^/]+$}{};
    is(((stat($dir))[2] & 07777), 0700, 'scratch dir (task-<num> leaf) mode is 0700');
    like($p, qr{/cwf[^/]+/task-\d+(?:\.\d+)*/security-review-changeset-[^/]+\.out$},
         '.out path is nested: <base>/cwf<dash>/task-<num>/<file>');
    (my $parent = $dir) =~ s{/[^/]+$}{};
    is(((stat($parent))[2] & 07777), 0700, 'scratch PARENT (cwf<dash>) mode is 0700');
    like(changeset_of($out), qr{\.cwf/scripts/foo}, '.out contains the diff');
    unlike($out, qr{^diff --git}m, 'stdout carries no "diff --git" line');
    unlike($out, qr{^[-+]}m, 'stdout carries no diff +/- body lines');
};

# ---------------------------------------------------------------------------
# TC-PARENT-SYMLINK (AC6, security): the shared cwf<dash> parent pre-planted as
# a symlink-to-dir is REJECTED (exit 1) by the helper's -d && !-l recheck; no
# .out is written through the link. Defence-in-depth, not the boundary.
# ---------------------------------------------------------------------------
subtest 'TC-PARENT-SYMLINK: symlinked scratch parent is rejected (exit 1)' => sub {
    SKIP: {
        skip 'symlinks not supported here', 3 unless eval { symlink('', ''); 1 } || $!;

        my ($repo) = make_synthetic_repo(baseline => '__MAIN__');
        make_path("$repo/.cwf/scripts");
        write_script("$repo/.cwf/scripts/work", 5);
        git_in($repo, 'add', '.cwf/scripts/work');
        git_in($repo, 'commit', '-q', '-m', 'work');

        # Discover the canonical nested .out path via one clean run, then tear
        # the real parent/leaf down so we can replant the parent as a symlink.
        my ($o1) = run_helper($repo);
        my $p = out_path($o1);
        skip 'no .out path to target', 3 unless defined $p;
        (my $leaf   = $p)    =~ s{/[^/]+$}{};   # .../cwf<dash>/task-<num>
        (my $parent = $leaf) =~ s{/[^/]+$}{};   # .../cwf<dash>
        unlink $p; rmdir $leaf; rmdir $parent;

        # Plant the parent as a symlink to an attacker-controlled directory —
        # the dangerous symlink-to-dir case a bare -d would silently accept.
        my $attacker = "$repo-attacker";
        make_path($attacker);
        symlink($attacker, $parent) or skip 'cannot create symlink at parent', 3;
        push @CLEANUP_SYMLINK, $parent;

        my ($o2, $e2, $rc2) = run_helper($repo);
        is($rc2, 1, 'helper exits 1 on a symlinked scratch parent');
        like($e2, qr{scratch unavailable \(symlink_parent\)},
             'stderr reports the symlink_parent failure kind');
        opendir my $dh, $attacker or die "opendir $attacker: $!";
        my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
        closedir $dh;
        is(scalar @entries, 0, 'attacker dir is empty (no write-through through the link)');
    }
};

# ---------------------------------------------------------------------------
# TC-PARENT-REUSE (AC6, observable no-chmod): a pre-existing shared parent at a
# non-0700 mode (0755) is REUSED as-is — the helper proceeds, writes the leaf,
# and leaves the parent mode UNCHANGED (never auto-chmods). The second-task path.
# ---------------------------------------------------------------------------
subtest 'TC-PARENT-REUSE: pre-existing 0755 parent reused unchanged (no auto-chmod)' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');
    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/work", 5);
    git_in($repo, 'add', '.cwf/scripts/work');
    git_in($repo, 'commit', '-q', '-m', 'work');

    # First run creates parent+leaf at 0700; loosen the PARENT to 0755 to model
    # a pre-existing shared parent created by some other (non-helper) means.
    my ($o1) = run_helper($repo);
    my $p = out_path($o1);
    (my $leaf   = $p)    =~ s{/[^/]+$}{};
    (my $parent = $leaf) =~ s{/[^/]+$}{};
    chmod 0755, $parent or die "chmod $parent: $!";

    # Second run: parent already exists (mkdir skipped), recheck passes (-d && !-l).
    my ($o2, $e2, $rc2) = run_helper($repo);
    is($rc2, 0, 'helper exits 0 reusing the existing parent');
    is(((stat($parent))[2] & 07777), 0755,
       'parent mode left UNCHANGED at 0755 (never auto-chmodded)');
    like(changeset_of($o2), qr{\.cwf/scripts/work}, '.out still written under the reused parent');
};

# ---------------------------------------------------------------------------
# TC-CONFIRM (AC5): stdout is exactly one confirmation line; the reported count
# equals the newline count of the .out file (the wc -l round-trip invariant).
# ---------------------------------------------------------------------------
subtest 'TC-CONFIRM: single confirmation line; count == wc -l of the file' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');
    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/foo", 12);
    git_in($repo, 'add', '.cwf/scripts/foo');
    git_in($repo, 'commit', '-q', '-m', 'foo');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0');
    like($out, qr{^security-review-changeset: wrote \d+ lines to \S+\n\z},
         'stdout is exactly one confirmation line');
    is(scalar(split /\n/, $out), 1, 'exactly one line on stdout');
    my $n  = confirm_count($out);
    my $cs = changeset_of($out);
    is(($cs =~ tr/\n//), $n, 'reported count equals the newline count of the .out file');
};

# ---------------------------------------------------------------------------
# TC-TRUNCATE (AC4.2): a second, smaller run fully REPLACES the prior .out —
# no leftover content from run 1 and a smaller line count (truncate, not append).
# ---------------------------------------------------------------------------
subtest 'TC-TRUNCATE: re-run fully replaces the prior .out (no stale content)' => sub {
    my ($repo) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);
    make_path("$repo/.cwf/scripts");

    # Run 1: a large diff carrying a unique marker line.
    open my $fh, '>', "$repo/.cwf/scripts/work" or die;
    print $fh "#!/usr/bin/perl\n";
    print $fh "print \"RUN1_ONLY_MARKER\";\n";
    print $fh "print \"filler $_\";\n" for (1 .. 40);
    close $fh;
    git_in($repo, 'add', '.cwf/scripts/work');
    git_in($repo, 'commit', '-q', '-m', 'run1 big');
    my ($o1, $e1, $r1) = run_helper($repo, '--max-lines=100000');
    is($r1, 0, 'run 1 exits 0');
    my $n1 = confirm_count($o1);
    like(changeset_of($o1), qr{RUN1_ONLY_MARKER}, 'run 1 .out contains the marker');

    # Run 2: shrink the same file (no marker) → much smaller diff, same .out path.
    open my $fh2, '>', "$repo/.cwf/scripts/work" or die;
    print $fh2 "#!/usr/bin/perl\nprint \"small\";\n";
    close $fh2;
    git_in($repo, 'add', '.cwf/scripts/work');
    git_in($repo, 'commit', '-q', '-m', 'run2 small');
    my ($o2, $e2, $r2) = run_helper($repo, '--max-lines=100000');
    is($r2, 0, 'run 2 exits 0');
    is(out_path($o2), out_path($o1), 'run 2 writes the SAME .out path');
    my $cs2 = changeset_of($o2);
    unlike($cs2, qr{RUN1_ONLY_MARKER}, 'run 2 .out has no leftover run-1 content (full replace)');
    cmp_ok(confirm_count($o2), '<', $n1, 'run 2 line count is smaller (truncate, not append)');
};

# ---------------------------------------------------------------------------
# TC-SYMLINK (AC4.2, security): a pre-planted symlink at the target .out path
# is REPLACED by the atomic rename; its referent file is never written through.
# ---------------------------------------------------------------------------
subtest 'TC-SYMLINK: pre-planted symlink at the target is replaced, referent untouched' => sub {
    SKIP: {
        skip 'symlinks not supported here', 4 unless eval { symlink('', ''); 1 } || $!;

        my ($repo) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);
        make_path("$repo/.cwf/scripts");
        write_script("$repo/.cwf/scripts/work", 5);
        git_in($repo, 'add', '.cwf/scripts/work');
        git_in($repo, 'commit', '-q', '-m', 'work');

        # Run once to discover the canonical .out path, then remove it.
        my ($o1) = run_helper($repo, '--max-lines=100000');
        my $p = out_path($o1);
        ok(defined $p, 'helper reported an .out path');
        skip 'no .out path to target', 3 unless defined $p;
        unlink $p;

        # Plant a sentinel and a symlink at the .out path pointing at it.
        my $sentinel = "$repo/sentinel";
        open my $sf, '>', $sentinel or die; print $sf "SENTINEL_ORIG\n"; close $sf;
        symlink($sentinel, $p) or skip 'cannot create symlink at target', 3;

        # Re-run: rename-replace must not write through the symlink.
        my ($o2) = run_helper($repo, '--max-lines=100000');
        my $sc = do { open my $fh, '<', $sentinel or die; local $/; <$fh> };
        is($sc, "SENTINEL_ORIG\n", 'symlink referent is unmodified (no write-through)');
        ok(-f $p && !-l $p, '.out is now a regular file (symlink replaced)');
        like(changeset_of($o2), qr{\.cwf/scripts/work}, '.out contains the diff');
    }
};

# ---------------------------------------------------------------------------
# TC-WORKTREE (AC4.1): run from inside a linked worktree, the .out resolves to
# the MAIN-tree namespace — identical to the main-tree run, never the worktree.
# ---------------------------------------------------------------------------
subtest 'TC-WORKTREE: .out resolves to the main-tree namespace from a linked worktree' => sub {
    SKIP: {
        my ($repo) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);
        make_path("$repo/.cwf/scripts");
        write_script("$repo/.cwf/scripts/work", 5);
        git_in($repo, 'add', '.cwf/scripts/work');
        git_in($repo, 'commit', '-q', '-m', 'work');

        my $wt = "$repo-wt";
        my $rc_wt = git_in($repo, 'worktree', 'add', '--detach', '-q', $wt, 'HEAD');
        skip 'git worktree unavailable', 3 unless $rc_wt == 0 && -d $wt;

        # --task-num avoids branch parsing in the detached worktree checkout.
        my ($om) = run_helper($repo, '--task-num=1', '--max-lines=100000');
        my ($ow) = run_helper($wt,   '--task-num=1', '--max-lines=100000');
        my $pm = out_path($om);
        my $pw = out_path($ow);
        is($pw, $pm, 'worktree run resolves the SAME main-tree .out path');
        (my $wt_base = $wt) =~ s{.*/}{};
        unlike($pw, qr/\Q$wt_base\E/, '.out path does not contain the worktree dir name');
        like(changeset_of($ow), qr{\.cwf/scripts/work}, 'worktree run still produces the diff');

        git_in($repo, 'worktree', 'remove', '--force', $wt);
    }
};

# ---------------------------------------------------------------------------
# TC-DOCS (AC6): the four consumer sites carry the new contract and no stale
# strings. Output-level smoke test over the real installed files.
# ---------------------------------------------------------------------------
subtest 'TC-DOCS: four consumer sites migrated, no stale --phase/--max-lines=500/{changeset}' => sub {
    my %site = (
        'impl-exec' => "$FindBin::Bin/../.claude/skills/cwf-implementation-exec/SKILL.md",
        'test-exec' => "$FindBin::Bin/../.claude/skills/cwf-testing-exec/SKILL.md",
        'agent'     => "$FindBin::Bin/../.claude/agents/cwf-security-reviewer-changeset.md",
        'doc'       => "$FindBin::Bin/../.cwf/docs/skills/security-review.md",
    );
    my %txt;
    for my $name (sort keys %site) {
        my $f = $site{$name};
        $txt{$name} = do { open my $fh, '<:encoding(UTF-8)', $f or die "open $f: $!"; local $/; <$fh> };
        # The removed flag must not reappear on the security-review-changeset
        # invocation. Scoped to that helper's line so an unrelated helper that
        # legitimately takes a --phase (e.g. best-practice-resolve) does not
        # false-positive here.
        unlike($txt{$name}, qr{security-review-changeset[^\n]*--phase\b},
               "$name: no --phase flag on the changeset invocation");
        unlike($txt{$name}, qr{--max-lines=500},  "$name: no --max-lines=500");
        unlike($txt{$name}, qr{\{changeset\}},    "$name: no inline {changeset} placeholder");
    }
    like($txt{'impl-exec'}, qr{--wf-step=implementation-exec}, 'impl-exec names the exact invocation');
    like($txt{'test-exec'}, qr{--wf-step=testing-exec},        'test-exec names the exact invocation');
    like($txt{'agent'},     qr{\{changeset_file\}},            'agent consumes {changeset_file} (path it Reads)');
    like($txt{'doc'},       qr{--wf-step},                     'doc describes the --wf-step flag');
    like($txt{'doc'},       qr{\.out\b},                       'doc describes the .out file-output model');
};

# ---------------------------------------------------------------------------
# TC-VALIDATE (AC8): cwf-manage validate reports no integrity violation for the
# changed script (or its agent) — the same-commit hash refresh is consistent.
# ---------------------------------------------------------------------------
subtest 'TC-VALIDATE: no integrity violation for the changed script + agent' => sub {
    my $mgr = "$FindBin::Bin/../.cwf/scripts/cwf-manage";
    open(my $fh, '-|', $mgr, 'validate') or die "fork cwf-manage: $!";
    my $output = do { local $/; <$fh> };
    close $fh;
    $output //= '';
    # No `is($rc, 0)` whole-repo assertion: cwf-manage validate aggregates every
    # sub-validator over the live repo, so its exit code flips on unrelated
    # in-flight state (placeholder phase Statuses, transient perm/hash drift) —
    # environmental noise, not a property of this change. The file-scoped unlike
    # checks below are the actual AC8 assertion. The liveness check guards against
    # a validate that runs-but-dies-early passing the unlike checks vacuously;
    # the `or die` above guards a failed fork. (Task 211)
    like($output, qr/validate: OK|\d+ violation\(s\) found/,
         'cwf-manage validate ran to a verdict');
    unlike($output, qr{security-review-changeset},
           'no integrity violation names the changed helper');
    unlike($output, qr{cwf-security-reviewer-changeset},
           'no integrity violation names the migrated agent');
};

# ===========================================================================
# Untracked-file inclusion (Task 194) — TC-1..TC-7
# A new source file created before the exec checkpoint commit is untracked, so
# the pre-194 `git diff <anchor>` omitted it from both the reviewed body and the
# production count. The helper now makes untracked, non-ignored files visible
# via a transient `git add -N`, restored on exit. These cases pin: body+count
# inclusion, ignored-file exclusion, index restore on normal AND exit-2 paths,
# the untracked-only dirty suffix, and the `--` option-injection guard.
# ===========================================================================

# ---------------------------------------------------------------------------
# TC-1: an untracked, non-ignored file is rendered in the changeset body and
# counted among the reviewed files (anchor = seed; window also holds the
# committed a-task-plan.md + the unstaged README change => 3 files).
# ---------------------------------------------------------------------------
subtest 'TC-1: untracked non-ignored file appears in the changeset body' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

    open my $r, '>>', "$repo/README.md" or die;   # tracked modification (unstaged)
    print $r "tracked change\n";
    close $r;
    open my $n, '>', "$repo/new.txt" or die;        # untracked, 4 added lines
    print $n "u$_\n" for (1 .. 4);
    close $n;

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0');
    my $cs = changeset_of($out);
    like($cs, qr{^\+\+\+ b/new\.txt$}m, 'untracked file rendered as a new-file hunk');
    like($cs, qr{^\+u1$}m, 'untracked file content rendered as additions');
    like($err, qr{reviewed 3 files},
         'reviewed count includes the untracked file (plan + README + new.txt)');
    like($err, qr{includes uncommitted}, 'dirty suffix present');
};

# ---------------------------------------------------------------------------
# TC-2: a .gitignore-matched untracked file is excluded (git's --exclude-standard
# owns the matching); a sibling non-ignored untracked file is still included.
# ---------------------------------------------------------------------------
subtest 'TC-2: gitignored untracked file is excluded from the changeset' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

    open my $gi, '>', "$repo/.gitignore" or die;
    print $gi "*.log\n";
    close $gi;
    git_in($repo, 'add', '.gitignore');
    git_in($repo, 'commit', '-q', '-m', 'gitignore');

    open my $d, '>', "$repo/debug.log" or die;   # untracked + ignored
    print $d "secret $_\n" for (1 .. 5);
    close $d;
    open my $k, '>', "$repo/keep.txt" or die;    # untracked + non-ignored
    print $k "k\n";
    close $k;

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0');
    my $cs = changeset_of($out);
    unlike($cs, qr{debug\.log}, 'ignored file does not appear in the changeset');
    like($cs, qr{^\+\+\+ b/keep\.txt$}m, 'non-ignored untracked file still included');
};

# ---------------------------------------------------------------------------
# TC-3: after a normal (exit 0) run the index is restored — the untracked file
# is back to `?? ` with no residual intent-to-add (`A `/`AM`) entry.
# ---------------------------------------------------------------------------
subtest 'TC-3: index restored to untracked after a normal exit' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

    open my $n, '>', "$repo/new.txt" or die;
    print $n "content\n";
    close $n;

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0');
    my $status = git_capture($repo, 'status', '--porcelain');
    like($status, qr{^\?\? new\.txt$}m,
         'file is back to untracked (??) — no residual intent-to-add');
    unlike($status, qr{^A}m, 'no leftover A / AM intent-to-add entry');
};

# ---------------------------------------------------------------------------
# TC-4: an untracked file pushes the production count over a small cap. Proves
# (a) untracked lines are counted (cap fires => exit 2) and (b) the END-block
# restore still runs on the exit-2 path without clobbering the exit code.
# ---------------------------------------------------------------------------
subtest 'TC-4: untracked lines trip the cap (exit 2) and the index is still restored' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

    open my $n, '>', "$repo/big.txt" or die;   # 30 added lines, alone over a cap of 5
    print $n "line $_\n" for (1 .. 30);
    close $n;

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=5');
    is($rc, 2, 'cap fires on untracked production lines (exit 2)');
    like($err, qr{cap exceeded:}, 'breach reported on stderr');
    like(changeset_of($out), qr{^\+\+\+ b/big\.txt$}m,
         '.out still written with the untracked file on the cap-breach path');
    my $status = git_capture($repo, 'status', '--porcelain');
    like($status, qr{^\?\? big\.txt$}m,
         'index restored despite the early exit 2 (END ran; exit code preserved)');
};

# ---------------------------------------------------------------------------
# TC-5: an all-untracked changeset (no tracked diff in the window) still renders
# the `, includes uncommitted` suffix. Uses make_cap_repo so the anchor is the
# branch point (HEAD) and the tracked tree is clean.
# ---------------------------------------------------------------------------
subtest 'TC-5: untracked-only tree renders the includes-uncommitted suffix' => sub {
    my ($repo) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);

    open my $n, '>', "$repo/new.txt" or die;   # only change on the branch is untracked
    print $n "x\n";
    close $n;

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=1000');
    is($rc, 0, 'helper exits 0');
    like($err, qr{includes uncommitted$}m, 'suffix fires for an all-untracked changeset');
    like(changeset_of($out), qr{^\+\+\+ b/new\.txt$}m, 'the untracked file is the changeset body');
};

# ---------------------------------------------------------------------------
# TC-6: an untracked file literally named `-rf` is handled without a git
# option-parsing error — proves the mandatory `--` separator before the paths
# (FR4(e) option-injection guard) on every git invocation that takes them.
# ---------------------------------------------------------------------------
subtest 'TC-6: dash-prefixed untracked filename is handled (-- option-injection guard)' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

    open my $n, '>', "$repo/-rf" or die "open -rf: $!";   # absolute path => no shell parsing
    print $n "danger\n";
    close $n;

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0 — no git option-parsing error on a -rf path');
    like(changeset_of($out), qr{\Q+++ b/-rf\E}, 'the -rf file is included in the body');
    my $status = git_capture($repo, 'status', '--porcelain');
    like($status, qr{^\?\? "?-rf"?$}m, 'the -rf file is restored to untracked');
};

# ---------------------------------------------------------------------------
# TC-7: with zero untracked files the helper takes the no-op path — tracked diff
# is rendered as before and the working tree is left exactly clean (no add -N,
# no signal-handler install, END no-ops). Regression guard for the pre-194 path.
# ---------------------------------------------------------------------------
subtest 'TC-7: no untracked files — behaviour unchanged, index untouched' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

    open my $r, '>>', "$repo/README.md" or die;   # tracked modification, then committed
    print $r "change\n";
    close $r;
    git_in($repo, 'add', 'README.md');
    git_in($repo, 'commit', '-q', '-m', 'mod');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0');
    like(changeset_of($out), qr{README\.md}, 'tracked diff still rendered');
    my $status = git_capture($repo, 'status', '--porcelain');
    is($status, '', 'working tree clean — no intent-to-add side effects');
};

# ---------------------------------------------------------------------------
# TC-TMPDIR-1/2/3 (Task 199): the scratch .out path honours $TMPDIR, so it lands
# inside the sandbox-permitted temp root (e.g. /tmp/claude) when the sandbox sets
# TMPDIR, and degrades to /tmp off-sandbox. These assert path *construction*; the
# sandbox *denial* check is BLOCKED-ENV (see g-testing-exec.md, FR7).
# ---------------------------------------------------------------------------
subtest 'TC-TMPDIR-1: scratch .out honours a set $TMPDIR' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');
    my $tmpbase = tempdir(CLEANUP => 1);

    my ($out, $err, $rc);
    {
        local $ENV{TMPDIR} = $tmpbase;
        ($out, $err, $rc) = run_helper($repo);
    }
    is($rc, 0, 'helper exits 0');
    my $p = out_path($out);
    ok(defined $p, 'helper reported a .out path');
    like($p, qr{^\Q$tmpbase\E/}, '.out lands under the set $TMPDIR');
};

subtest 'TC-TMPDIR-2: unset $TMPDIR falls back to /tmp (no regression)' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

    my ($out, $err, $rc);
    {
        delete local $ENV{TMPDIR};   # truly unset for this scope, not bare local
        ($out, $err, $rc) = run_helper($repo);
    }
    is($rc, 0, 'helper exits 0');
    like(out_path($out), qr{^/tmp/}, '.out falls back under /tmp when $TMPDIR unset');
};

subtest 'TC-TMPDIR-3: empty $TMPDIR falls back to /tmp (no root collapse)' => sub {
    my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

    my ($out, $err, $rc);
    {
        local $ENV{TMPDIR} = '';
        ($out, $err, $rc) = run_helper($repo);
    }
    is($rc, 0, 'helper exits 0');
    my $p = out_path($out);
    like($p,   qr{^/tmp/}, 'empty $TMPDIR falls back under /tmp');
    unlike($p, qr{^/-},    'empty $TMPDIR does NOT collapse to filesystem root');
};

# ===========================================================================
# Non-regular untracked-file filtering (Task 209)
# `list_untracked_files` now keeps only git-indexable types — regular files
# (-f) and symlinks (-l) — so a non-regular untracked entry (e.g. a sandbox
# /dev/null bind-mount char-device mask) does not abort the `git add -N` sweep.
# ===========================================================================

# ---------------------------------------------------------------------------
# TC-209-1 (portable): untracked symlinks stay in the sweep. A bare -f filter
# would drop a dangling symlink and a symlink-to-device (both -f-false); the
# -l retention keeps them. Guards against a future over-narrowing to bare -f.
# ---------------------------------------------------------------------------
subtest 'TC-209-1: untracked symlinks (dangling + to-device) stay in the changeset' => sub {
    SKIP: {
        skip 'symlinks not supported here', 4 unless eval { symlink('', ''); 1 } || $!;

        my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

        symlink('/dev/null', "$repo/dev-link")         or skip 'cannot symlink', 4;
        symlink('/nonexistent', "$repo/dangling-link") or skip 'cannot symlink', 4;
        open my $k, '>', "$repo/keep.txt" or die;   # normal untracked sibling
        print $k "keep\n";
        close $k;

        my ($out, $err, $rc) = run_helper($repo);
        my $cs = changeset_of($out);
        is($rc, 0, 'helper exits 0');
        like($cs, qr{dev-link},      'untracked symlink-to-device is reviewed (-l retained)');
        like($cs, qr{dangling-link}, 'untracked dangling symlink is reviewed (-l retained)');
        like($cs, qr{keep\.txt},     'untracked regular sibling still reviewed');
    }
};

# ---------------------------------------------------------------------------
# TC-209-2 (Linux-gated): a char-device untracked entry no longer aborts the
# helper. A fifo/socket is NOT enumerated by `git ls-files --others`, so only a
# char/block device reproduces the bug — and that needs a bind-mount, hence a
# user+mount namespace (unshare -rm). The setup writes a marker AFTER the mount
# succeeds, so a missing marker is an environment SKIP, never a helper failure
# (which would otherwise be indistinguishable from the pre-fix exit-1 abort).
# ---------------------------------------------------------------------------
subtest 'TC-209-2: char-device untracked entry (bind-mounted /dev/null) does not abort' => sub {
    SKIP: {
        my $unshare = '/usr/bin/unshare';
        skip 'unshare unavailable', 3 unless -x $unshare;

        my ($repo) = make_synthetic_repo(baseline => '__MAIN__');

        open my $k, '>', "$repo/keep.txt" or die;   # untracked regular sibling
        print $k "keep\n";
        close $k;
        open my $m, '>', "$repo/masked" or die;     # mountpoint (empty regular file)
        close $m;

        my $so     = "$CAPTURE_DIR/uns-stdout.$$";
        my $se     = "$CAPTURE_DIR/uns-stderr.$$";
        my $marker = "$CAPTURE_DIR/uns-marker.$$";
        unlink $so, $se, $marker;

        # cd repo → bind /dev/null over `masked` (=> char device git enumerates
        # as untracked) → mark setup-complete → exec the helper IN the namespace.
        # Params passed via env to avoid any shell interpolation of paths.
        my $script = join(' && ',
            'cd "$R" || exit 70',
            'mount --bind /dev/null masked 2>>"$SE" || exit 71',
            ': > "$MARK"',
            'exec "$H" --wf-step=implementation-exec >"$SO" 2>>"$SE"',
        );
        local $ENV{R}    = $repo;
        local $ENV{H}    = $HELPER;
        local $ENV{SO}   = $so;
        local $ENV{SE}   = $se;
        local $ENV{MARK} = $marker;
        my $rc = system($unshare, '-rm', 'sh', '-c', $script) >> 8;

        skip 'user+mount namespace / bind-mount unavailable', 3 unless -e $marker;

        is($rc, 0, 'helper exits 0 with a char-device untracked entry present');

        my $stdout = do { local $/; open my $fh, '<', $so or die; <$fh> } // '';
        my $p = out_path($stdout);
        push @CLEANUP_OUT, $p if defined $p;
        my $cs = (defined $p && -e $p)
            ? do { local $/; open my $fh, '<:raw', $p or die; <$fh> }
            : '';
        like($cs, qr{keep\.txt}, 'sibling untracked regular file is still reviewed');
        unlike($cs, qr{masked},  'char-device mask is excluded from the changeset');
    }
};

# ===========================================================================
# Task 218: configurable cap via security.review.max-lines (CLI // config // 1000).
# NB: the e-testing-plan named these TC-CAP7..16, but TC-CAP7/8/9 already exist
# for other purposes (exclude-paths pattern, unconfigured test path, deprecated
# test-paths key). Renamed to TC-CONFIGCAP1..10 to avoid collision — same cases.
# ===========================================================================

# Build a cwf-project.json with security.review.max-lines set to a RAW JSON
# token (a number, a "quoted" string, true, [500], null, …).
sub cfg_maxlines {
    my ($raw) = @_;
    return qq({ "versioning": { "major_minor": "v1.0" },\n)
         . qq(  "security": { "review": { "max-lines": $raw } } }\n);
}

# review present but the max-lines key absent → "not configured" (silent default).
my $CFG_REVIEW_NO_MAXLINES =
    qq({ "versioning": { "major_minor": "v1.0" },\n)
  . qq(  "security": { "review": { "max-lines-exclude-paths": [] } } }\n);

my $WARN_RE = qr{'security\.review\.max-lines' is not a positive integer};

# --- Precedence (FR2) -------------------------------------------------------

# TC-CONFIGCAP1 (plan TC-CAP7): config cap used when no CLI flag.
subtest 'TC-CONFIGCAP1: config max-lines used when --max-lines absent' => sub {
    my ($repo) = make_cap_repo(config_json => cfg_maxlines(20));
    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/s", 30);            # 30 production > 20
    git_in($repo, 'add', '.cwf/scripts/s');
    git_in($repo, 'commit', '-q', '-m', 'prod');

    my ($out, $err, $rc) = run_helper($repo);            # no --max-lines
    is($rc, 2, 'config cap of 20 fires (exit 2)');
    like($err, qr{cap exceeded: \d+ production lines > 20}, 'stderr names the config cap');
};

# TC-CONFIGCAP2 (plan TC-CAP8): a 501–1000 diff passes at config cap 1000 (FR4).
subtest 'TC-CONFIGCAP2: 600-line diff passes under config cap of 1000' => sub {
    my ($repo) = make_cap_repo(config_json => cfg_maxlines(1000));
    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/s", 600);           # 600 production < 1000
    git_in($repo, 'add', '.cwf/scripts/s');
    git_in($repo, 'commit', '-q', '-m', 'prod');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'exit 0 — 600 production under the 1000 config cap');
    unlike($err, qr{cap exceeded}, 'no cap message');
};

# TC-CONFIGCAP3 (plan TC-CAP9): CLI flag overrides a higher config cap.
subtest 'TC-CONFIGCAP3: --max-lines=10 beats config cap of 1000' => sub {
    my ($repo) = make_cap_repo(config_json => cfg_maxlines(1000));
    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/s", 30);
    git_in($repo, 'add', '.cwf/scripts/s');
    git_in($repo, 'commit', '-q', '-m', 'prod');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=10');
    is($rc, 2, 'CLI 10 wins over config 1000 (exit 2)');
    like($err, qr{cap exceeded: \d+ production lines > 10}, 'stderr names the CLI cap');
};

# TC-CONFIGCAP4 (plan TC-CAP10): explicit --max-lines=500 beats a higher config —
# the default→unset motivator (500 must not read as "flag absent").
subtest 'TC-CONFIGCAP4: explicit --max-lines=500 beats config cap of 1000' => sub {
    my ($repo) = make_cap_repo(config_json => cfg_maxlines(1000));
    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/s", 600);           # 600 > 500, < 1000
    git_in($repo, 'add', '.cwf/scripts/s');
    git_in($repo, 'commit', '-q', '-m', 'prod');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=500');
    is($rc, 2, 'explicit 500 fires (not treated as absent → 1000)');
    like($err, qr{cap exceeded: \d+ production lines > 500}, 'stderr names the explicit cap');
};

# --- Fail-safe degradation (FR3) -------------------------------------------

# TC-CONFIGCAP5 (plan TC-CAP11): malformed scalar → warn (key only) + degrade to 1000.
subtest 'TC-CONFIGCAP5: non-integer scalar warns and degrades to 1000' => sub {
    my ($repo) = make_cap_repo(config_json => cfg_maxlines('"abc"'));
    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/s", 30);            # 30 < 1000 default
    git_in($repo, 'add', '.cwf/scripts/s');
    git_in($repo, 'commit', '-q', '-m', 'prod');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'exit 0 — degraded to the 1000 default');
    like($err, $WARN_RE, 'warning names the key');
    unlike($err, qr{abc}, 'the offending value is NOT echoed (no info leak)');
};

# TC-CONFIGCAP6 (plan TC-CAP12): ref types (bool, array) warn + degrade — proves
# a structured value is surfaced, not silently discarded.
subtest 'TC-CONFIGCAP6: boolean and array values warn and degrade' => sub {
    for my $raw ('true', '[500]') {
        my ($repo) = make_cap_repo(config_json => cfg_maxlines($raw));
        make_path("$repo/.cwf/scripts");
        write_script("$repo/.cwf/scripts/s", 30);
        git_in($repo, 'add', '.cwf/scripts/s');
        git_in($repo, 'commit', '-q', '-m', 'prod');

        my ($out, $err, $rc) = run_helper($repo);
        is($rc, 0, "exit 0 — degraded to 1000 (max-lines: $raw)");
        like($err, $WARN_RE, "ref value warns (max-lines: $raw)");
    }
};

# TC-CONFIGCAP7 (plan TC-CAP13): non-positive integers (0, -5, "007") warn +
# degrade — confirms CLI/config parity on the ^[1-9]\d*$ contract.
subtest 'TC-CONFIGCAP7: 0, negative, and leading-zero values warn and degrade' => sub {
    for my $raw ('0', '-5', '"007"') {
        my ($repo) = make_cap_repo(config_json => cfg_maxlines($raw));
        make_path("$repo/.cwf/scripts");
        write_script("$repo/.cwf/scripts/s", 30);
        git_in($repo, 'add', '.cwf/scripts/s');
        git_in($repo, 'commit', '-q', '-m', 'prod');

        my ($out, $err, $rc) = run_helper($repo);
        is($rc, 0, "exit 0 — degraded to 1000 (max-lines: $raw)");
        like($err, $WARN_RE, "non-positive-integer warns (max-lines: $raw)");
    }
};

# TC-CONFIGCAP8 (plan TC-CAP14): missing key / JSON null → SILENT default (no
# warning). Absence is not a typo. NB: plan said a ~600-line diff, but a missing
# key degrades to 1000 so a >1000 diff would exit 2 and conflate the signal; a
# small diff isolates "silent + default" cleanly.
subtest 'TC-CONFIGCAP8: missing key and null degrade silently (no warning)' => sub {
    for my $cfg ($CFG_REVIEW_NO_MAXLINES, cfg_maxlines('null')) {
        my ($repo) = make_cap_repo(config_json => $cfg);
        make_path("$repo/.cwf/scripts");
        write_script("$repo/.cwf/scripts/s", 30);        # < 1000 default
        git_in($repo, 'add', '.cwf/scripts/s');
        git_in($repo, 'commit', '-q', '-m', 'prod');

        my ($out, $err, $rc) = run_helper($repo);
        is($rc, 0, 'exit 0 — silent 1000 default');
        unlike($err, $WARN_RE, 'no max-lines warning (absence ≠ typo)');
    }
};

# TC-CONFIGCAP9 (plan TC-CAP15): a numeric string is accepted (JSON-scalar AC).
subtest 'TC-CONFIGCAP9: numeric string "20" is accepted, no warning' => sub {
    my ($repo) = make_cap_repo(config_json => cfg_maxlines('"20"'));
    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/s", 30);            # 30 > 20
    git_in($repo, 'add', '.cwf/scripts/s');
    git_in($repo, 'commit', '-q', '-m', 'prod');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 2, 'string "20" treated as 20 → cap fires');
    like($err, qr{cap exceeded: \d+ production lines > 20}, 'stderr names cap 20');
    unlike($err, $WARN_RE, 'a valid numeric string does not warn');
};

# --- CLI-fatal / config-degrade asymmetry (regression) ----------------------

# TC-CONFIGCAP10 (plan TC-CAP16): an invalid --max-lines CLI value stays FATAL
# (exit 1) even when a valid config cap is present.
subtest 'TC-CONFIGCAP10: invalid --max-lines stays fatal despite valid config' => sub {
    my ($repo) = make_cap_repo(config_json => cfg_maxlines(1000));
    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/s", 30);
    git_in($repo, 'add', '.cwf/scripts/s');
    git_in($repo, 'commit', '-q', '-m', 'prod');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=abc');
    is($rc, 1, 'bad CLI value is fatal (exit 1), not degraded to config/default');
    like($err, qr{invalid --max-lines}, 'stderr names the invalid CLI flag');
};

# ===========================================================================
# Seeded-template exclude defaults (Task 221). These guard the ACTUAL shipped
# template globs (loaded from the template, not hardcoded) through git's real
# :(glob,exclude) engine — never a Perl-side approximation.
# ===========================================================================

my $TEMPLATE = "$FindBin::Bin/../.cwf/templates/cwf-project.json.template";

# The seeded security.review.max-lines-exclude-paths from the shipped template.
sub seeded_exclude_globs {
    open my $fh, '<:raw', $TEMPLATE or die "open $TEMPLATE: $!";
    my $raw = do { local $/; <$fh> };
    close $fh;
    my $cfg = decode_json($raw);
    my $g = $cfg->{security}{review}{'max-lines-exclude-paths'};
    return ref $g eq 'ARRAY' ? @$g : ();
}

# A cap-repo config carrying the seeded globs verbatim (no max-lines → default).
sub cfg_seeded {
    my @globs = seeded_exclude_globs();
    return JSON::PP->new->canonical->encode({
        versioning => { major_minor => 'v1.0' },
        security   => { review => { 'max-lines-exclude-paths' => \@globs } },
    });
}

# TC-SEED-VALID (AC4/FR4): every seeded glob is a valid git pathspec. A malformed
# glob makes git fatal → the helper exits 1, breaking review for every new
# project. Exercised through the real engine (run_helper → git diff --numstat).
subtest 'TC-SEED-VALID: every seeded glob is a valid git pathspec (real engine)' => sub {
    my @globs = seeded_exclude_globs();
    ok(@globs > 0, 'template seeds a non-empty exclude set');

    my ($repo) = make_cap_repo(config_json => cfg_seeded());
    make_path("$repo/src");
    write_script("$repo/src/main.js", 30);   # production, not excluded
    git_in($repo, 'add', 'src/main.js');
    git_in($repo, 'commit', '-q', '-m', 'prod');

    my ($out, $err, $rc) = run_helper($repo);
    isnt($rc, 1, 'no seeded glob makes git fatal (helper does not exit 1)');
    is($rc, 0, 'small production changeset under the seeded config passes');
    unlike($err, qr/fatal:/, 'git raised no fatal on any seeded pathspec');
};

# TC-SEED-EXCLUDE (AC1/FR1): churn confined to seeded test/generated/vendored
# paths counts 0 production lines — proven by passing an intentionally tiny cap.
subtest 'TC-SEED-EXCLUDE: seeded test/generated/vendored churn counts 0 production' => sub {
    my ($repo) = make_cap_repo(config_json => cfg_seeded());
    make_path("$repo/src");
    make_path("$repo/vendor");
    make_path("$repo/dist");
    write_script("$repo/src/foo_test.js", 60);   # **/*_test.*
    write_script("$repo/vendor/lib.go",   60);   # **/vendor/**
    write_script("$repo/dist/app.min.js", 60);   # **/*.min.* (and **/dist/**)
    git_in($repo, 'add', '.');
    git_in($repo, 'commit', '-q', '-m', 'excluded churn');

    # A cap of 1 fires on a single production line, so exit 0 proves count == 0.
    my ($out, $err, $rc) = run_helper($repo, '--max-lines=1');
    is($rc, 0, 'all churn discounted → 0 production lines, passes cap of 1');
    unlike($err, qr{cap exceeded}, 'no cap breach on fully-excluded churn');
};

# TC-SEED-DOC (AC2/FR2): doc markdown is discounted but SCOPED — top-level *.md
# and docs/**/*.md only, never blanket **/*.md. A markdown file in a production
# location still counts.
subtest 'TC-SEED-DOC: doc markdown scoped-discounted; non-doc *.md still counts' => sub {
    # (a) top-level *.md and a top-level docs/ tree are discounted.
    my ($r1) = make_cap_repo(config_json => cfg_seeded());
    make_path("$r1/docs");
    write_script("$r1/NOTES.md",      300);   # top-level *.md
    write_script("$r1/docs/guide.md", 300);   # docs/**/*.md
    git_in($r1, 'add', '.');
    git_in($r1, 'commit', '-q', '-m', 'docs');
    my ($o1, $e1, $c1) = run_helper($r1, '--max-lines=100');
    is($c1, 0, 'top-level and docs/ markdown discounted → passes cap 100');

    # (b) markdown outside a doc location still counts as production.
    my ($r2) = make_cap_repo(config_json => cfg_seeded());
    make_path("$r2/src");
    write_script("$r2/src/inline.md", 150);   # NOT matched by *.md / docs/**/*.md
    git_in($r2, 'add', '.');
    git_in($r2, 'commit', '-q', '-m', 'inline md');
    my ($o2, $e2, $c2) = run_helper($r2, '--max-lines=100');
    is($c2, 2, 'src/inline.md counts as production → trips cap 100 (not blanket **/*.md)');
};

# TC-SEED-GUARDRAIL (AC3/FR3): no seeded glob discounts a security-relevant path.
# Re-runnable against the LIVE tree (not a one-time design assertion) so future
# drift — e.g. a new .cwf/scripts/foo_test.pl — is caught here.
subtest 'TC-SEED-GUARDRAIL: no seeded glob excludes a security-relevant path (live tree)' => sub {
    my @globs = seeded_exclude_globs();
    my $root  = "$FindBin::Bin/..";
    my @hits;
    for my $glob (@globs) {
        open my $gp, '-|', 'git', '-C', $root, 'ls-files', '-z', '--', ":(glob)$glob"
            or die "git ls-files (glob=$glob): $!";
        {
            local $/ = "\0";
            while (my $f = <$gp>) {
                chomp $f;
                next unless length $f;
                push @hits, "$glob -> $f"
                    if $f =~ m{^\.cwf/(?:scripts|hooks|security|docs)/}
                    || $f =~ m{(?:^|/)cwf-project\.json$};
            }
        }
        # Check the close: a non-zero git exit (e.g. an unparseable pathspec)
        # otherwise reads as zero lines → an empty @hits → a false-PASS guardrail.
        close $gp or die "git ls-files failed (glob=$glob): status "
            . ($? >> 8) . "\n";
    }
    is(scalar @hits, 0,
       'seeded globs discount no .cwf/{scripts,hooks,security,docs} or cwf-project.json path')
        or diag("guardrail breach:\n" . join("\n", @hits));
};

# ===========================================================================
# Always-review-docs-regardless-of-line-cap — Task 223
#
# directory-structure.base-path markdown is discounted from the production cap
# always-on (FR1) and, on an over-cap breach, written to a doc-scoped .out for
# review while code review is deferred (FR2). Each case writes its OWN config
# with a NON-default base-path and no overlapping seeded excludes, so the
# discount under test is observable and never masked (test-isolation).
# ===========================================================================

# TC-223-1 (AC1a): markdown under a non-default base-path is discounted.
subtest 'TC-223-1: base-path markdown is discounted from the cap' => sub {
    my ($repo) = make_cap_repo(config_json => cfg_basepath(base_path => 'docs-tree'));
    make_path("$repo/docs-tree");
    make_path("$repo/.cwf/scripts");
    write_script("$repo/docs-tree/guide.md", 300);   # discounted prose
    write_script("$repo/.cwf/scripts/small", 3);      # 3 production lines
    git_in($repo, 'add', '.');
    git_in($repo, 'commit', '-q', '-m', 'prose + small code');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=100');
    is($rc, 0, 'exit 0 — 300 lines of base-path markdown discounted, code under cap');
    unlike($err, qr{cap exceeded}, 'no breach: prose volume does not trip the cap');
    like(changeset_of($out), qr{docs-tree/guide\.md},
         'the discounted markdown is still fully REVIEWED (present in the .out)');
};

# TC-223-2 (AC1/security): a CODE file under the task-doc tree still counts —
# proves the discount is markdown-scoped, not whole-tree (no cap-bypass).
subtest 'TC-223-2: code under base-path still counts (markdown-scoped, not tree)' => sub {
    my ($repo) = make_cap_repo(config_json => cfg_basepath(base_path => 'docs-tree'));
    make_path("$repo/docs-tree");
    write_script("$repo/docs-tree/tool.pl", 60);   # code UNDER the doc tree
    git_in($repo, 'add', '.');
    git_in($repo, 'commit', '-q', '-m', 'code under doc tree');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=10');
    is($rc, 2, 'exit 2 — a .pl under base-path is NOT discounted (markdown-only)');
    like($err, qr{cap exceeded: \d+ production lines > 10}, 'breach names the count');
};

# TC-223-3 (AC2, HARD): base-path=.cwf is REJECTED, so CWF's own security-doc
# markdown is never discounted. The control that stops base-path from turning
# into a discount of .cwf security docs.
subtest 'TC-223-3: base-path=.cwf rejected → .cwf markdown never discounted' => sub {
    my ($repo) = make_cap_repo(config_json => cfg_basepath(base_path => '.cwf'));
    make_path("$repo/.cwf/docs");
    write_script("$repo/.cwf/docs/threat-model.md", 60);   # would-be-discounted
    git_in($repo, 'add', '.');
    git_in($repo, 'commit', '-q', '-m', 'cwf security doc');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=10');
    is($rc, 2, 'exit 2 — .cwf markdown counts as production (base-path guard rejects .cwf)');
    like($err, qr{directory-structure\.base-path '\.cwf' names or is under \.cwf},
         'diagnostic names the rejected .cwf base-path');
};

# TC-223-4 (AC2/AC1c): every adversarial/malformed base-path fails safe (no
# discount). A PRESENT-but-malformed value emits a diagnostic; absent/empty is
# silent. The "x\n" sub-case proves \A..\z anchoring (a ^..$ guard would accept
# it silently — the diagnostic firing is the discriminator).
subtest 'TC-223-4: adversarial base-path fails safe (no discount)' => sub {
    my @malformed = (
        ['.'       => qr{resolves to the repo root}],
        ['./'      => qr{resolves to the repo root}],
        ['content/' => qr{has a trailing /}],
        ['./content' => qr{has a leading \./}],
        ['../escape' => qr{contains \.\.}],
        ['/abs'    => qr{is absolute}],
        ['**'      => qr{contains disallowed characters}],
        ['a*b'     => qr{contains disallowed characters}],
        ['a,b'     => qr{contains disallowed characters}],
        ["content\n" => qr{contains disallowed characters}],   # proves \A..\z
    );
    for my $case (@malformed) {
        my ($bp, $diag_re) = @$case;
        my ($repo) = make_cap_repo(config_json => cfg_basepath(base_path => $bp));
        make_path("$repo/content");
        write_script("$repo/content/big.md", 60);   # a valid base-path='content' would discount this
        git_in($repo, 'add', '.');
        git_in($repo, 'commit', '-q', '-m', 'markdown');

        my ($out, $err, $rc) = run_helper($repo, '--max-lines=1');
        (my $show = $bp) =~ s/\n/\\n/g;
        is($rc, 2, "base-path '$show' → markdown counts as production (no silent discount)");
        like($err, $diag_re, "base-path '$show' emits the fail-safe diagnostic");
    }

    # Absent and empty are SILENT fail-safes (no diagnostic).
    for my $case (['(absent)', cfg_basepath()],
                  ['(empty)',  cfg_basepath(base_path => '')]) {
        my ($label, $cfg) = @$case;
        my ($repo) = make_cap_repo(config_json => $cfg);
        make_path("$repo/content");
        write_script("$repo/content/big.md", 60);
        git_in($repo, 'add', '.');
        git_in($repo, 'commit', '-q', '-m', 'markdown');

        my ($out, $err, $rc) = run_helper($repo, '--max-lines=1');
        is($rc, 2, "base-path $label → markdown still counts (fail-safe)");
        unlike($err, qr{directory-structure\.base-path},
               "base-path $label is silent (no diagnostic)");
    }
};

# TC-223-5 (AC3a): an over-cap breach writes a doc-scoped .out containing ONLY
# the base-path markdown diff, prints a second confirmation line (D>0), and still
# exits 2 with the cap-exceeded stderr. The full .out remains code+docs.
subtest 'TC-223-5: over-cap breach writes the deferred doc artefact' => sub {
    my ($repo) = make_cap_repo(config_json => cfg_basepath(base_path => 'docs-tree'));
    make_path("$repo/docs-tree");
    make_path("$repo/.cwf/scripts");
    write_script("$repo/docs-tree/design.md", 40);   # discounted, but reviewed on the doc .out
    write_script("$repo/.cwf/scripts/big", 60);       # 60 production lines > cap
    git_in($repo, 'add', '.');
    git_in($repo, 'commit', '-q', '-m', 'big code + docs');

    my ($out, $err, $rc) = run_helper($repo, '--max-lines=10');
    is($rc, 2, 'exit 2 — code over cap (docs discounted)');
    like($err, qr{cap exceeded: \d+ production lines > 10}, 'stderr still carries the code breach');
    like($out, qr{^security-review-changeset: wrote \d+ lines to }m, 'primary confirmation line present');

    my $dp = doc_out_path($out);
    ok(defined $dp, 'a second, doc-scoped confirmation line is printed');
    like($dp, qr{/security-review-changeset-implementation-exec-docs\.out$},
         'doc .out carries the -docs suffix');
    cmp_ok(doc_confirm_count($out), '>', 0, 'reported doc-line count is > 0');
    is(((stat($dp))[2] & 07777), 0600, 'doc .out mode is 0600 (no world-read widening)');

    my $dc = doc_changeset_of($out);
    like($dc, qr{docs-tree/design\.md}, 'doc .out contains the base-path markdown diff');
    unlike($dc, qr{\.cwf/scripts/big}, 'doc .out excludes the code (docs-only)');
};

# TC-223-6 (AC2c/robustness F1): the doc line PRESENT-with-0 (configured, no
# docs in this changeset) is distinguishable on the wire from ABSENT (base-path
# unconfigured → docs not separable). The exec skill keys off this distinction.
subtest 'TC-223-6: present-0 doc line vs absent doc line are distinguishable' => sub {
    # (a) valid base-path, over-cap code, NO markdown → line present, count 0.
    my ($ra) = make_cap_repo(config_json => cfg_basepath(base_path => 'docs-tree'));
    make_path("$ra/.cwf/scripts");
    write_script("$ra/.cwf/scripts/big", 60);
    git_in($ra, 'add', '.');
    git_in($ra, 'commit', '-q', '-m', 'code only, valid base-path');
    my ($oa, $ea, $rca) = run_helper($ra, '--max-lines=10');
    is($rca, 2, '(a) exit 2');
    is(doc_confirm_count($oa), 0,
       '(a) configured base-path with no doc churn → "wrote 0 doc lines" (present, zero)');
    is(doc_changeset_of($oa), '', '(a) doc .out written but empty');

    # (b) base-path unconfigured, over-cap code → NO doc line at all.
    my ($rb) = make_cap_repo(config_json => cfg_basepath());   # no directory-structure
    make_path("$rb/.cwf/scripts");
    write_script("$rb/.cwf/scripts/big", 60);
    git_in($rb, 'add', '.');
    git_in($rb, 'commit', '-q', '-m', 'code only, no base-path');
    my ($ob, $eb, $rcb) = run_helper($rb, '--max-lines=10');
    is($rcb, 2, '(b) exit 2');
    is(doc_out_path($ob), undef,
       '(b) unconfigured base-path → NO doc line (docs not separable, not mislabelled "no docs")');
};

done_testing();
