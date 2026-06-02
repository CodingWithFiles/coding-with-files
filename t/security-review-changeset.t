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

my $HELPER = "$FindBin::Bin/../.cwf/scripts/command-helpers/security-review-changeset";

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

# Run the helper with @args inside $repo, return (stdout, stderr, exit).
sub run_helper {
    my ($repo, @args) = @_;
    my $stdout_file = "$repo/.helper-stdout";
    my $stderr_file = "$repo/.helper-stderr";
    my $orig = cwd();
    chdir $repo or die "chdir $repo: $!";
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
    return ($stdout // '', $stderr // '', $rc);
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
    like($out, qr{\.cwf/scripts/cwf-foo}, 'changeset includes the extensionless file');
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
    like($out, qr{app/main\.py}, 'changeset includes consumer-stack python file (all files reviewed)');
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
    is($rc, 0, 'helper exits 0');
    like($out, qr{task2-work}, 'task2 work is in the changeset');
    unlike($out, qr{task1-leak}, 'task1 work is NOT in the changeset (closes BACKLOG axis 3)');
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
    like($out, qr{\.cwf/scripts/blob}, 'binary file is included (all files reviewed)');
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
    like($out, qr{tools/blob}, 'binary outside CWF dirs is now reviewed (all files included)');
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
    like($out, qr{notes\.txt}, 'plain text outside CWF dirs is reviewed');
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
    like($out, qr{sub-work}, 'subtask change is in the changeset');
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
    like($out, qr{\.cwf/scripts/foo}, 'changeset still produced via fallback path');
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
        is($rc, 0, 'helper exits 0');
        like($out, qr{dangerous-link}, 'symlink path is now reviewed (no -l guard skips it)');
        like($out, qr{^\+/dev/null$}m,
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
    like($out, qr{noise/file}, 'all 200 changed files are reviewed');
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

    is($rc, 0, 'helper exits 0');
    like($out, qr{\.cwf/scripts/staged-script},
         'staged-only file appears in diff (index-side change picked up)');
    like($out, qr{\.cwf/scripts/baseline-script},
         'modified tracked file appears in diff');
    like($out, qr{UNSTAGED_MOD_141},
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
    like($out, qr{\.cwf/scripts/big-script}, 'full diff still printed to stdout');
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
    like($out, qr{t/big\.t}, 'test file is in the changeset (all files reviewed)');
    ($err =~ /(\d+) lines \((\d+) production\)/)
        or do { fail('stderr summary has the "(P production)" field'); return };
    my ($raw, $prod) = ($1, $2);
    cmp_ok($prod, '<', $raw, 'production count is below the raw line count');
    cmp_ok($prod, '<=', 20, 'production count is within the cap (t/ excluded)');
};

# ---------------------------------------------------------------------------
# TC-CAP3: no --max-lines → never caps (back-compat)
# ---------------------------------------------------------------------------
subtest 'TC-CAP3: absent --max-lines never caps regardless of size' => sub {
    my ($repo) = make_cap_repo(config_json => $CFG_NO_TESTPATHS);

    make_path("$repo/.cwf/scripts");
    write_script("$repo/.cwf/scripts/huge", 200);
    git_in($repo, 'add', '.cwf/scripts/huge');
    git_in($repo, 'commit', '-q', '-m', 'huge script');

    my ($out, $err, $rc) = run_helper($repo);
    is($rc, 0, 'helper exits 0 with no --max-lines');
    unlike($err, qr{cap exceeded}, 'no cap message emitted');
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
    like($out, qr{src/app\.js}, 'consumer source file is in the reviewed changeset');
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
# TC-EMPTY1: a genuinely empty diff (anchor == worktree) yields exit 0,
# "reviewed 0 files", empty stdout. Proves the !@included guard short-circuits
# so a bare `git diff $anchor --` (no pathspec → whole-tree) can never run.
# ---------------------------------------------------------------------------
subtest 'TC-EMPTY1: empty diff stays empty (no whole-tree leak)' => sub {
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
    is($out, '', 'stdout is empty — no whole-tree diff leaked');
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

done_testing();
