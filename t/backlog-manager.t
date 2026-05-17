#!/usr/bin/env perl
#
# backlog-manager.t — End-to-end subcommand tests for the backlog-manager
# script. Each subtest maps to an acceptance criterion (AC1..AC17) from
# b-requirements-plan.md. Tests invoke the script as a subprocess against
# fixture inputs in temp directories.
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use File::Copy qw(copy);
use Cwd qw(getcwd);

my $REPO_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $SCRIPT    = File::Spec->catfile($REPO_ROOT, '.cwf', 'scripts', 'command-helpers', 'backlog-manager');
my $LIVE_BL   = File::Spec->catfile($REPO_ROOT, 'BACKLOG.md');
my $LIVE_CL   = File::Spec->catfile($REPO_ROOT, 'CHANGELOG.md');

#==============================================================================
# Helpers — set up an isolated git repo with BACKLOG.md and CHANGELOG.md
#==============================================================================

# Creates a temp dir, initialises a git repo (so find_git_root works), and
# writes BACKLOG.md / CHANGELOG.md content. Returns the dir path.
sub make_isolated {
    my (%files) = @_;
    my $dir = tempdir(CLEANUP => 1);
    system('git', 'init', '-q', $dir) == 0 or die "git init: $?";
    for my $name (keys %files) {
        my $path = File::Spec->catfile($dir, $name);
        open(my $fh, '>:raw', $path) or die "$path: $!";
        require Encode;
        print {$fh} Encode::encode('UTF-8', $files{$name});
        close $fh;
    }
    return $dir;
}

# Run the backlog-manager script in $dir as cwd; returns ($rc, $stdout, $stderr).
sub run_bm {
    my ($dir, @args) = @_;
    my $cmd = sprintf('cd %s && %s %s 2>%s/.stderr',
        quotemeta($dir), quotemeta($SCRIPT),
        join(' ', map { _shell_quote($_) } @args), $dir);
    my $stdout = `$cmd`;
    my $rc = $? >> 8;
    my $stderr_path = File::Spec->catfile($dir, '.stderr');
    my $stderr = '';
    if (open(my $fh, '<', $stderr_path)) { local $/; $stderr = <$fh>; close $fh; }
    return ($rc, $stdout, $stderr);
}

sub _shell_quote {
    my $s = shift;
    return q{''} if $s eq '';
    return "'" . ($s =~ s/'/'\\''/gr) . "'" if $s =~ /[^A-Za-z0-9_\-=\.]/;
    return $s;
}

sub _slurp {
    open(my $fh, '<:encoding(UTF-8)', $_[0]) or die "$_[0]: $!";
    local $/;
    my $b = <$fh>;
    close $fh;
    return $b;
}

#==============================================================================
# Sample valid CHANGELOG (used as base for several tests)
#==============================================================================

my $VALID_CHANGELOG = <<'END';
# Changelog

All notable changes to the CWF project are documented here.

## Task 131: Add backlog-manager

### Status: Complete (2026-05-07)
### Impact: feature

### Changes
- Added backlog-manager helper

### Notable
- First feature task to use it.
END

my $VALID_BACKLOG_MIN = <<'END';
# CWF System Backlog

Future tasks for the CWF system.


## Task: Sample Active Entry

### Task-Type: chore
### Priority: Medium

This is a sample entry body.
END

#==============================================================================
# AC1 — validate live BACKLOG / CHANGELOG (smoke test)
#==============================================================================

subtest 'AC1: validate against live BACKLOG/CHANGELOG' => sub {
    plan tests => 1;
    TODO: {
        local $TODO = 'live BACKLOG/CHANGELOG migrated to heading-tree format in Task 132 Step 6';
        my $cmd = sprintf('cd %s && %s validate', quotemeta($REPO_ROOT), quotemeta($SCRIPT));
        my $out = `$cmd 2>&1`;
        my $rc = $? >> 8;
        is($rc, 0, "validate exits 0 on live files (output: $out)");
    }
};

#==============================================================================
# AC2 — validate flags malformed inputs
#==============================================================================

subtest 'AC2a: BACKLOG-002 banned priority' => sub {
    plan tests => 2;
    my $bad = $VALID_BACKLOG_MIN;
    $bad =~ s/### Priority: Medium/### Priority: Needs-Triage/;
    my $dir = make_isolated('BACKLOG.md' => $bad, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'validate');
    is($rc, 1, 'exit 1');
    like($err, qr/BACKLOG-002/, 'BACKLOG-002 fired');
};

subtest 'AC2b: BACKLOG-001 missing required field' => sub {
    plan tests => 2;
    my $bad = "## Task: No Type\n\n**Priority**: Low\n";
    my $dir = make_isolated('BACKLOG.md' => $bad, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'validate');
    is($rc, 1, 'exit 1');
    like($err, qr/BACKLOG-001/, 'BACKLOG-001 fired');
};

subtest 'AC2c: GLOBAL-001 BOM rejected' => sub {
    plan tests => 2;
    my $with_bom = "\xef\xbb\xbf" . $VALID_BACKLOG_MIN;
    # Note: make_isolated would re-encode; write raw bytes ourselves.
    my $dir = tempdir(CLEANUP => 1);
    system('git', 'init', '-q', $dir) == 0 or die;
    open(my $fh, '>:raw', "$dir/BACKLOG.md"); print {$fh} $with_bom; close $fh;
    open(my $cf, '>:raw', "$dir/CHANGELOG.md"); print {$cf} $VALID_CHANGELOG; close $cf;
    my ($rc, $out, $err) = run_bm($dir, 'validate');
    is($rc, 1, 'exit 1');
    like($err, qr/GLOBAL-001/, 'GLOBAL-001 fired for BOM');
};

subtest 'AC2d: BACKLOG-004 HTML comment rejected' => sub {
    plan tests => 2;
    my $bad = $VALID_BACKLOG_MIN . qq{\n<!-- stray comment -->\n};
    my $dir = make_isolated('BACKLOG.md' => $bad, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'validate');
    is($rc, 1, 'exit 1');
    like($err, qr/BACKLOG-004/, 'BACKLOG-004 fired');
};

subtest 'AC2e: BACKLOG-005 struck-through title rejected' => sub {
    plan tests => 2;
    my $bad = <<'END';
# CWF System Backlog

Intro.


## Task: ~~Old~~ ✓ COMPLETED

### Task-Type: chore
### Priority: Low

Body.
END
    my $dir = make_isolated('BACKLOG.md' => $bad, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'validate');
    is($rc, 1, 'exit 1');
    like($err, qr/BACKLOG-005/, 'BACKLOG-005 fired');
};

subtest 'AC2f: #### in body now allowed (BACKLOG-006 retired in Task 132)' => sub {
    plan tests => 1;
    my $body_with_h4 = <<'END';
# CWF System Backlog

Intro.


## Task: Has Subhead

### Task-Type: chore
### Priority: Low

Body before.

#### Sub heading

Body after.
END
    my $dir = make_isolated('BACKLOG.md' => $body_with_h4, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'validate');
    is($rc, 0, "validate exit 0; #### in body allowed (err: $err)");
};

subtest 'AC2g: CHANGELOG-003 out-of-order subsections rejected' => sub {
    plan tests => 2;
    my $bad = <<'END';
# Changelog

Intro.

## Task 1: Out of order

### Status: Complete (2026-01-01)
### Impact: chore

### Notable
- bar

### Changes
- foo
END
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $bad);
    my ($rc, $out, $err) = run_bm($dir, 'validate');
    is($rc, 1, 'exit 1');
    like($err, qr/CHANGELOG-003/, 'CHANGELOG-003 fired');
};

#==============================================================================
# AC3 — CHANGELOG accepts HTML comments (BACKLOG does not)
#==============================================================================

subtest 'AC3: CHANGELOG accepts HTML comments' => sub {
    plan tests => 1;
    my $cl = <<'END';
# Changelog

Intro.

## Task 131: Foo

### Status: Complete (2026-05-07)
### Impact: feature

### Changes
- Did stuff.

<!-- Note: implementation diverged because of X -->
END
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $cl);
    my ($rc, $out, $err) = run_bm($dir, 'validate');
    is($rc, 0, "exit 0 — HTML comments OK in CHANGELOG (err: $err)");
};

#==============================================================================
# AC4 — CHANGELOG accepts entries with omitted Duration / Changes / Notable
#==============================================================================

subtest 'AC4: CHANGELOG optional fields' => sub {
    plan tests => 1;
    my $cl = <<'END';
# Changelog

Intro.

## Task 1: Has all

### Status: Complete (2026-01-01)
### Duration: 1 day
### Impact: chore

### Changes
- foo

### Notable
- bar


## Task 2: No duration

### Status: Complete (2026-01-02)
### Impact: chore

### Changes
- foo


## Task 3: No changes section

### Status: Complete (2026-01-03)
### Impact: chore

### Notable
- bar


## Task 4: No notable section

### Status: Complete (2026-01-04)
### Impact: chore

### Changes
- foo


## Task 5: Bare metadata

### Status: Complete (2026-01-05)
### Impact: chore


## Task 6: With Retired

### Status: Complete (2026-01-06)
### Impact: feature

### Changes
- foo

### Retired Backlog Items

#### Some Retired Item

Body of the retired item.
END
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $cl);
    my ($rc, $out, $err) = run_bm($dir, 'validate');
    is($rc, 0, "exit 0 (err: $err)");
};

#==============================================================================
# AC5 — list grouped output
#==============================================================================

subtest 'AC5: list groups by priority' => sub {
    plan tests => 4;
    my $bl = <<'END';
# CWF System Backlog

Intro.


## Task: Very High Item

### Task-Type: chore
### Priority: Very High

Body.


## Task: High Item

### Task-Type: chore
### Priority: High

Body.


## Task: Medium Item

### Task-Type: chore
### Priority: Medium

Body.


## Task: Low Item

### Task-Type: chore
### Priority: Low

Body.
END
    my $dir = make_isolated('BACKLOG.md' => $bl, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'list');
    is($rc, 0, 'exit 0');
    like($out, qr/^## Very High \(1\)/m, 'Very High band');
    like($out, qr/^## High \(1\)/m, 'High band');
    like($out, qr/^## Medium \(1\)/m, 'Medium band');
};

#==============================================================================
# AC6 — soft cap, --all-items, stable order
#==============================================================================

subtest 'AC6a: soft cap — top band overflow shown in full' => sub {
    plan tests => 2;
    my $bl = "# CWF System Backlog\n\nIntro.\n\n";
    for my $i (1 .. 25) {
        $bl .= "## Task: High Item $i\n\n### Task-Type: chore\n### Priority: High\n\nBody.\n\n";
    }
    for my $i (1 .. 5) {
        $bl .= "## Task: Med Item $i\n\n### Task-Type: chore\n### Priority: Medium\n\nBody.\n";
        $bl .= "\n" if $i < 5;
    }
    my $dir = make_isolated('BACKLOG.md' => $bl, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'list');
    is($rc, 0, 'exit 0');
    my @high = ($out =~ /High Item \d+/g);
    is(scalar @high, 25, 'all 25 High items shown (soft cap, do not split)');
};

subtest 'AC6b: --all-items shows everything' => sub {
    plan tests => 2;
    my $bl = "# CWF System Backlog\n\nIntro.\n\n";
    for my $i (1 .. 25) {
        $bl .= "## Task: High Item $i\n\n### Task-Type: chore\n### Priority: High\n\nBody.\n\n";
    }
    for my $i (1 .. 5) {
        $bl .= "## Task: Med Item $i\n\n### Task-Type: chore\n### Priority: Medium\n\nBody.\n";
        $bl .= "\n" if $i < 5;
    }
    my $dir = make_isolated('BACKLOG.md' => $bl, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'list', '--all-items');
    is($rc, 0, 'exit 0');
    my @all = ($out =~ /Item \d+/g);
    is(scalar @all, 30, 'all 30 items shown');
};

#==============================================================================
# AC7 / AC8 — add
#==============================================================================

subtest 'AC7: add valid entry' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'add',
        '--priority=Low',
        '--task-type=chore',
        '--title=Test Add',
        '--body=Hello world',
    );
    is($rc, 0, "add exit 0 (err: $err)");
    my ($rc2, undef, $err2) = run_bm($dir, 'validate');
    is($rc2, 0, "validate after add (err: $err2)");
};

subtest 'AC8a: add rejects banned priority' => sub {
    plan tests => 1;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'add',
        '--priority=Needs-Triage', '--task-type=chore', '--title=X', '--body=Y',
    );
    is($rc, 1, 'rejected with exit 1');
};

subtest 'AC8b: add allows body containing --- (heading-tree format has no separator semantics)' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'add',
        '--priority=Low', '--task-type=chore', '--title=Body With Hr', "--body=line1\n---\nline2",
    );
    is($rc, 0, "add exit 0 (err: $err)");
    my ($rc2, undef, $err2) = run_bm($dir, 'validate');
    is($rc2, 0, "validate after add (err: $err2)");
};

subtest 'AC8c: add allows body containing #### (BACKLOG-006 retired in Task 132)' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'add',
        '--priority=Low', '--task-type=chore', '--title=Body With H4', "--body=before\n#### Subhead\nafter",
    );
    is($rc, 0, "add exit 0 (err: $err)");
    my ($rc2, undef, $err2) = run_bm($dir, 'validate');
    is($rc2, 0, "validate after add (err: $err2)");
};

# Task 140 — --body-file now accepts any readable file (validate_read_path_allowlist)
subtest 'Task140-pos: add accepts --body-file under /tmp' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my $body_dir = tempdir(CLEANUP => 1);
    my $body_path = File::Spec->catfile($body_dir, 'body.md');
    open(my $fh, '>:raw', $body_path) or die "$body_path: $!";
    print {$fh} "Smoke 140 body\n";
    close $fh;
    my ($rc, $out, $err) = run_bm($dir, 'add',
        '--priority=Low', '--task-type=chore', '--title=Smoke140',
        "--body-file=$body_path",
    );
    is($rc, 0, "add exit 0 (err: $err)");
    my $backlog = _slurp(File::Spec->catfile($dir, 'BACKLOG.md'));
    like($backlog, qr/Smoke 140 body/, 'body content reached BACKLOG.md');
};

subtest 'Task140-neg: add rejects non-existent --body-file' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'add',
        '--priority=Low', '--task-type=chore', '--title=NoFile',
        '--body-file=/nonexistent/path-140',
    );
    isnt($rc, 0, 'non-zero exit');
    like($err, qr/does not exist/, 'stderr mentions does not exist');
};

subtest 'Task140-neg: add rejects unreadable --body-file' => sub {
    if ($> == 0) { plan skip_all => 'root effective uid bypasses -r'; }
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my $body_dir = tempdir(CLEANUP => 1);
    my $body_path = File::Spec->catfile($body_dir, 'unreadable.md');
    open(my $fh, '>:raw', $body_path) or die "$body_path: $!";
    close $fh;
    chmod 0000, $body_path or die "chmod: $!";
    my ($rc, $out, $err) = run_bm($dir, 'add',
        '--priority=Low', '--task-type=chore', '--title=NoRead',
        "--body-file=$body_path",
    );
    chmod 0600, $body_path;  # restore so CLEANUP can unlink
    isnt($rc, 0, 'non-zero exit');
    like($err, qr/not readable/, 'stderr mentions not readable');
};

subtest 'Task140-neg: add rejects empty --body-file value' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'add',
        '--priority=Low', '--task-type=chore', '--title=Empty',
        '--body-file=',
    );
    isnt($rc, 0, 'non-zero exit');
    like($err, qr/empty/, 'stderr mentions empty');
};

#==============================================================================
# AC9 — modify byte-preservation of unspecified fields
#==============================================================================

subtest 'AC9: modify priority preserves Status field byte-for-byte' => sub {
    plan tests => 3;
    my $bl = <<'END';
# CWF System Backlog

Intro.


## Task: Test Mod

### Task-Type: chore
### Priority: Medium
### Status: Backlog

Body content here.
END
    my $dir = make_isolated('BACKLOG.md' => $bl, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'modify', '--id=test-mod', '--priority=Low');
    is($rc, 0, "modify exit 0 (err: $err)");
    my $content = _slurp("$dir/BACKLOG.md");
    like($content, qr/^### Priority: Low$/m, 'priority changed to Low');
    like($content, qr/^### Status: Backlog$/m, 'Status preserved');
};

#==============================================================================
# AC10 — slug collision
#==============================================================================

subtest 'AC10: ambiguous slug rejected' => sub {
    plan tests => 2;
    my $bl = <<'END';
# CWF System Backlog

Intro.


## Task: Same Slug

### Task-Type: chore
### Priority: Low

Body.


## Task: Same  Slug

### Task-Type: chore
### Priority: Low

Body.
END
    my $dir = make_isolated('BACKLOG.md' => $bl, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'modify', '--id=same-slug', '--priority=Medium');
    is($rc, 1, 'exit 1');
    like($err, qr/ambiguous/, 'error mentions ambiguity');
};

#==============================================================================
# AC11 — delete safety
#==============================================================================

subtest 'AC11a: delete without --confirm refused' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'delete', '--id=sample-active-entry');
    is($rc, 1, 'exit 1');
    like($err, qr/--confirm/, 'mentions --confirm');
};

subtest 'AC11b: delete with --confirm succeeds' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'delete', '--id=sample-active-entry', '--confirm');
    is($rc, 0, "delete exit 0 (err: $err)");
    my $content = _slurp("$dir/BACKLOG.md");
    unlike($content, qr/Sample Active Entry/, 'entry removed');
};

#==============================================================================
# AC12 — retire moves entry into Retired Backlog Items subsection
#==============================================================================

subtest 'AC12: retire moves entry to CHANGELOG Retired Backlog Items' => sub {
    plan tests => 6;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'retire',
        '--id=sample-active-entry',
        '--task=131',
    );
    is($rc, 0, "retire exit 0 (err: $err)");
    my $bl_after = _slurp("$dir/BACKLOG.md");
    my $cl_after = _slurp("$dir/CHANGELOG.md");

    # BACKLOG: entry deleted, no marker tombstone, no <!-- comment
    unlike($bl_after, qr/^## Task: Sample Active Entry/m, 'BACKLOG entry deleted');
    unlike($bl_after, qr/<!--/, 'no marker comment in BACKLOG');

    # CHANGELOG: subsection added under Task 131 with the entry block
    like($cl_after, qr/^### Retired Backlog Items$/m, 'Retired subsection created');
    like($cl_after, qr/^#### Sample Active Entry$/m, 'block heading present');

    # Subsequent validate passes
    my ($rcv, undef, $errv) = run_bm($dir, 'validate');
    is($rcv, 0, "validate after retire (err: $errv)");
};

#==============================================================================
# AC13 — retire --note handling
#==============================================================================

subtest 'AC13a: retire --note rendered as HTML comment' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'retire',
        '--id=sample-active-entry', '--task=131',
        '--note=implementation diverged because X',
    );
    is($rc, 0, "retire exit 0 (err: $err)");
    my $cl_after = _slurp("$dir/CHANGELOG.md");
    like($cl_after, qr/<!-- Note: implementation diverged because X -->/,
        'note rendered as HTML comment');
};

subtest 'AC13b: retire --note rejects forbidden content' => sub {
    plan tests => 4;
    for my $bad (
        ['empty',     ''],
        ['embeds-->', 'has --> arrow'],
        ['newline',   "line1\nline2"],
        ['BOM-like',  "\xEF\xBB\xBFnope"],
    ) {
        my ($label, $note) = @$bad;
        my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
        my ($rc, $out, $err) = run_bm($dir, 'retire',
            '--id=sample-active-entry', '--task=131', "--note=$note",
        );
        is($rc, 1, "$label rejected with exit 1");
    }
};

#==============================================================================
# AC14 — retire missing CHANGELOG entry
#==============================================================================

subtest 'AC14: retire bootstrap path refuses + no-write when no task dir matches' => sub {
    # Task 147 replaces the old "no CHANGELOG entry → die" contract with a
    # bootstrap path that derives the entry from
    # `implementation-guide/N-<type>-<slug>/`. When that directory does not
    # exist, retire MUST refuse and write nothing — same no-write invariant as
    # the original AC14 contract.
    plan tests => 4;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    # Provide a minimal cwf-project.json so _load_supported_types can resolve;
    # leave implementation-guide/ empty so the scan returns zero matches.
    mkdir "$dir/implementation-guide" or die "mkdir: $!";
    open(my $fh, '>', "$dir/implementation-guide/cwf-project.json") or die "open: $!";
    print $fh '{"supported-task-types":["feature","bugfix","hotfix","chore","discovery"]}';
    close $fh;

    my $bl_before = _slurp("$dir/BACKLOG.md");
    my $cl_before = _slurp("$dir/CHANGELOG.md");

    my ($rc, $out, $err) = run_bm($dir, 'retire',
        '--id=sample-active-entry', '--task=999',  # no Task 999 in CHANGELOG
    );
    is($rc, 1, 'exit 1');
    like($err, qr/cannot bootstrap CHANGELOG entry for Task 999.*no directory matching/,
        'error names the bootstrap failure');

    # Both files unchanged
    is(_slurp("$dir/BACKLOG.md"), $bl_before, 'BACKLOG unchanged');
    is(_slurp("$dir/CHANGELOG.md"), $cl_before, 'CHANGELOG unchanged');
};

#==============================================================================
# AC15 — retire idempotency + crash-state recovery
#==============================================================================

subtest 'AC15a: retire is idempotent (re-run on already-retired entry)' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc1, undef, $err1) = run_bm($dir, 'retire',
        '--id=sample-active-entry', '--task=131',
    );
    is($rc1, 0, "first retire exit 0 (err: $err1)");

    # Second run: no active entry by that slug — INFO message, exit 0
    my ($rc2, undef, $err2) = run_bm($dir, 'retire',
        '--id=sample-active-entry', '--task=131',
    );
    is($rc2, 0, "second retire (no-op) exit 0 (err: $err2)");
};

subtest 'AC15b: crash recovery — block deduped, BACKLOG completed' => sub {
    plan tests => 4;
    # Pre-stage: BACKLOG still has the entry; CHANGELOG already has a
    # `### Retired Backlog Items` subsection with `#### Sample Active Entry`.
    my $cl_pre = <<'END';
# Changelog

Intro.

## Task 131: Foo

### Status: Complete (2026-05-07)
### Impact: feature

### Changes
- A.

### Retired Backlog Items

#### Sample Active Entry

This is a sample entry body.
END
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $cl_pre);

    my $cl_mtime_before = (stat("$dir/CHANGELOG.md"))[9];
    sleep(1);

    my ($rc, $out, $err) = run_bm($dir, 'retire',
        '--id=sample-active-entry', '--task=131',
    );
    is($rc, 0, "retire exit 0 (err: $err)");

    my $bl_after = _slurp("$dir/BACKLOG.md");
    unlike($bl_after, qr/^## Task: Sample Active Entry/m, 'BACKLOG entry now removed');

    # CHANGELOG mtime unchanged (dedup detected the existing block)
    my $cl_mtime_after = (stat("$dir/CHANGELOG.md"))[9];
    is($cl_mtime_after, $cl_mtime_before, 'CHANGELOG mtime unchanged (deduped)');

    # No duplicate block (only one #### Sample Active Entry under Retired)
    my $cl_after = _slurp("$dir/CHANGELOG.md");
    my @hits = ($cl_after =~ /^#### Sample Active Entry$/mg);
    is(scalar @hits, 1, 'no duplicate block in CHANGELOG');
};

#==============================================================================
# AC16 — help and missing-arg behaviour
#==============================================================================

subtest 'AC16a: no args → exit 1' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir);
    is($rc, 1, 'exit 1');
    like($err, qr/missing subcommand/, 'mentions missing subcommand');
};

subtest 'AC16b: --help' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, '--help');
    is($rc, 0, 'exit 0');
    like($out, qr/Subcommands:/, 'top-level usage');
};

subtest 'AC16c: subcommand --help' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'add', '--help');
    is($rc, 0, 'exit 0');
    like($out, qr/--task-type/, 'subcommand usage shown');
};

subtest 'AC16d: missing required flag → no help printed' => sub {
    plan tests => 2;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'add', '--priority=Low');
    is($rc, 1, 'exit 1');
    unlike($err, qr/Subcommands:/, 'top-level help not printed on missing arg');
};

#==============================================================================
# AC17 — round-trip integration (add → modify → validate → retire)
#==============================================================================

subtest 'AC17: chain add → modify → validate → retire' => sub {
    plan tests => 6;
    my $dir = make_isolated('BACKLOG.md' => $VALID_BACKLOG_MIN, 'CHANGELOG.md' => $VALID_CHANGELOG);

    my ($rc, undef, $err) = run_bm($dir, 'add',
        '--priority=Medium', '--task-type=chore',
        '--title=Chain Test', '--body=hello',
    );
    is($rc, 0, "step 1 add (err: $err)");

    ($rc, undef, $err) = run_bm($dir, 'validate');
    is($rc, 0, "validate after add (err: $err)");

    ($rc, undef, $err) = run_bm($dir, 'modify', '--id=chain-test', '--priority=Low');
    is($rc, 0, "step 2 modify (err: $err)");

    ($rc, undef, $err) = run_bm($dir, 'validate');
    is($rc, 0, "validate after modify (err: $err)");

    ($rc, undef, $err) = run_bm($dir, 'retire',
        '--id=chain-test', '--task=131',
    );
    is($rc, 0, "step 3 retire (err: $err)");

    ($rc, undef, $err) = run_bm($dir, 'validate');
    is($rc, 0, "validate after retire (err: $err)");
};

#==============================================================================
# AC18 — `normalise` subcommand: convert legacy Task-131 format to heading-tree
#==============================================================================

# Legacy-format BACKLOG (mirrors the Task-131 shape pre-migration).
my $LEGACY_BACKLOG = <<'END';
# CWF System Backlog

Future tasks for the CWF system.

---

## Task: Sample Legacy Entry

**Task-Type**: chore
**Priority**: Medium

This is a legacy-format entry body.

**Identified in**: Task 131 retrospective

---

## Task: Second Legacy Entry

**Task-Type**: feature
**Priority**: High

Second body content.
END

# Legacy-format CHANGELOG fixture (Task-131 shape: bold-paragraph metadata
# at entry top, subsection bodies preserved).
my $LEGACY_CHANGELOG = <<'END';
# Changelog

History.

## Task 131: Add backlog-manager

**Status**: Complete (2026-05-07)
**Impact**: feature

### Changes
- Added backlog-manager helper

### Notable
- First feature task to use it.
END

subtest 'AC18a: normalise --dry-run on legacy fixture reports change, writes nothing' => sub {
    plan tests => 4;
    my $dir = make_isolated('BACKLOG.md' => $LEGACY_BACKLOG, 'CHANGELOG.md' => $LEGACY_CHANGELOG);
    my $bl_before = _slurp("$dir/BACKLOG.md");
    my $cl_before = _slurp("$dir/CHANGELOG.md");
    my ($rc, $out, $err) = run_bm($dir, 'normalise', '--dry-run');
    is($rc, 0, "dry-run exit 0 (err: $err)");
    like($err, qr/would normalise/, 'reports planned change');
    is(_slurp("$dir/BACKLOG.md"), $bl_before, 'BACKLOG unchanged on dry-run');
    is(_slurp("$dir/CHANGELOG.md"), $cl_before, 'CHANGELOG unchanged on dry-run');
};

subtest 'AC18b: normalise migrates legacy fixture; subsequent validate clean' => sub {
    plan tests => 5;
    my $dir = make_isolated('BACKLOG.md' => $LEGACY_BACKLOG, 'CHANGELOG.md' => $LEGACY_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'normalise');
    is($rc, 0, "normalise exit 0 (err: $err)");
    my $bl_after = _slurp("$dir/BACKLOG.md");
    my $cl_after = _slurp("$dir/CHANGELOG.md");
    unlike($bl_after, qr/^---$/m, 'no `---` separators in BACKLOG');
    unlike($bl_after, qr/^\*\*Task-Type\*\*:/m, 'no `**Task-Type**:` paragraph metadata in BACKLOG');
    like($bl_after, qr/^### Task-Type: chore$/m, '### Task-Type: chore present');
    my ($rc2, undef, $err2) = run_bm($dir, 'validate');
    is($rc2, 0, "validate exit 0 (err: $err2)");
};

subtest 'AC18c: normalise on canonical fixture is no-op (byte-identical)' => sub {
    plan tests => 3;
    my $dir = make_isolated('BACKLOG.md' => $LEGACY_BACKLOG, 'CHANGELOG.md' => $LEGACY_CHANGELOG);
    # First pass: migrate.
    my ($rc, $out, $err) = run_bm($dir, 'normalise');
    is($rc, 0, "first normalise (err: $err)");
    my $bl_canon = _slurp("$dir/BACKLOG.md");
    my $cl_canon = _slurp("$dir/CHANGELOG.md");
    # Second pass: idempotent.
    my ($rc2, $out2, $err2) = run_bm($dir, 'normalise');
    is($rc2, 0, "second normalise (err: $err2)");
    is(_slurp("$dir/BACKLOG.md") . "|" . _slurp("$dir/CHANGELOG.md"),
       $bl_canon . "|" . $cl_canon,
       'second normalise byte-identical');
};

done_testing();
