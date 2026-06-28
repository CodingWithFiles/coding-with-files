#!/usr/bin/env perl
#
# backlog-bootstrap-changelog.t — Tests for the bootstrap path that `retire`
# uses when CHANGELOG has no `## Task N:` entry for the requested task
# (Task 147). Covers:
#   * resolve_task_title_from_dir — directory-scan resolver (unit, with chdir
#     into a tempdir fixture);
#   * end-to-end `backlog-manager retire` invocation via system(), exercising
#     the full bootstrap path (CHANGELOG entry created, retired block appended,
#     BACKLOG entry deleted, files mutated atomically).
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Cwd qw(getcwd);
use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib');

# Note: CWF::Backlog caches @_SUPPORTED_TYPES at package scope (loaded lazily
# from cwf-project.json on first call). The resolver tests in this file are
# the first user of that helper in a fresh `prove` process, and all tests
# below use the same supported-task-types list, so the cache is consistent.
# Cross-test fixture isolation comes from chdir-and-back per subtest.

my $SCRIPT = File::Spec->catfile($FindBin::Bin, '..', '.cwf', 'scripts',
                                 'command-helpers', 'backlog-manager');

my $CWF_PROJECT_JSON =
    '{"supported-task-types":["feature","bugfix","hotfix","chore","discovery"]}';

# Make a tempdir initialised as a git repo with a minimal cwf-project.json so
# find_git_root() and load_config() both resolve. Tmp dir name follows the
# project-namespaced template per .cwf/docs/conventions/tmp-paths.md.
sub make_project {
    # Honour $TMPDIR (read-only /tmp under the Claude Code sandbox — Task 215);
    # fall back to /tmp off-sandbox. Mirrors the ${TMPDIR:-/tmp} base in
    # .cwf/docs/conventions/tmp-paths.md.
    my $tmp_base = (defined $ENV{TMPDIR} && length $ENV{TMPDIR}) ? $ENV{TMPDIR} : '/tmp';
    my $dir = tempdir(
        '-home-matt-repo-coding-with-files-task-147-XXXXXX',
        DIR     => $tmp_base,
        CLEANUP => 1,
    );
    chmod 0700, $dir;
    system('git', 'init', '-q', $dir) == 0 or die "git init: $?";
    make_path("$dir/implementation-guide") or die "mkdir: $!";
    open(my $fh, '>', "$dir/implementation-guide/cwf-project.json")
        or die "open cwf-project.json: $!";
    print $fh $CWF_PROJECT_JSON;
    close $fh;
    return $dir;
}

sub touch_dir {
    my ($base, $name) = @_;
    make_path(File::Spec->catdir($base, 'implementation-guide', $name))
        or die "mkdir $name: $!";
}

sub write_file {
    my ($path, $bytes) = @_;
    open(my $fh, '>:raw', $path) or die "$path: $!";
    require Encode;
    print {$fh} Encode::encode('UTF-8', $bytes);
    close $fh;
}

sub slurp {
    open(my $fh, '<:encoding(UTF-8)', $_[0]) or die "$_[0]: $!";
    local $/;
    my $b = <$fh>;
    close $fh;
    return $b;
}

sub _shell_quote {
    my $s = shift;
    return q{''} if $s eq '';
    return "'" . ($s =~ s/'/'\\''/gr) . "'" if $s =~ /[^A-Za-z0-9_\-=\.]/;
    return $s;
}

sub run_bm {
    my ($dir, @args) = @_;
    my $cmd = sprintf('cd %s && %s %s 2>%s/.stderr',
        _shell_quote($dir), _shell_quote($SCRIPT),
        join(' ', map { _shell_quote($_) } @args), _shell_quote($dir));
    my $stdout = `$cmd`;
    my $rc = $? >> 8;
    my $err = '';
    if (open(my $fh, '<', "$dir/.stderr")) { local $/; $err = <$fh>; close $fh; }
    return ($rc, $stdout, $err);
}

my $BACKLOG_WITH_OLD = <<'END';
# CWF System Backlog

Future tasks.


## Task: Old Item

### Task-Type: chore
### Priority: Low

body of old item
END

my $EMPTY_CHANGELOG = "# Changelog\n";

#==============================================================================
# TC-AC5a (FR4): deterministic title from unique-match directory
#==============================================================================
subtest 'TC-AC5a: deterministic title from unique-match dir' => sub {
    plan tests => 3;
    my $dir = make_project();
    touch_dir($dir, '200-chore-do-the-thing');
    my $orig_cwd = getcwd;
    chdir $dir or die "chdir: $!";
    # Defer the use so the chdir is in effect when the package's load_config
    # first fires; we can then exercise the lazy cache deterministically by
    # invoking the resolver twice.
    require CWF::Backlog;
    my $t1 = eval { CWF::Backlog::resolve_task_title_from_dir(200) };
    is($@, '', 'first call did not die');
    my $t2 = eval { CWF::Backlog::resolve_task_title_from_dir(200) };
    is($t1, 'do the thing', 'title derived (type token stripped, hyphens→spaces)');
    is($t2, $t1, 'idempotent across calls');
    chdir $orig_cwd or die "chdir back: $!";
};

#==============================================================================
# TC-AC5b (FR5): zero-match → die, no file mutation
#==============================================================================
subtest 'TC-AC5b: zero match dies, BACKLOG/CHANGELOG untouched' => sub {
    plan tests => 3;
    my $dir = make_project();
    write_file("$dir/BACKLOG.md", $BACKLOG_WITH_OLD);
    write_file("$dir/CHANGELOG.md", $EMPTY_CHANGELOG);
    my $bl_before = slurp("$dir/BACKLOG.md");
    my $cl_before = slurp("$dir/CHANGELOG.md");
    my ($rc, $out, $err) = run_bm($dir, 'retire', '--id=old-item', '--task=99');
    like($err, qr/cannot bootstrap CHANGELOG entry for Task 99.*no directory matching 'implementation-guide\/99-\*\/'/,
        'zero-match error message');
    is(slurp("$dir/BACKLOG.md"),   $bl_before, 'BACKLOG unchanged');
    is(slurp("$dir/CHANGELOG.md"), $cl_before, 'CHANGELOG unchanged');
};

#==============================================================================
# TC-AC5c (FR6): multi-match → die, lists matches single-quoted
#==============================================================================
subtest 'TC-AC5c: multi-match dies and lists candidates' => sub {
    plan tests => 4;
    my $dir = make_project();
    touch_dir($dir, '1-bugfix-a');
    touch_dir($dir, '1-chore-b');
    touch_dir($dir, '1-feature-c');
    write_file("$dir/BACKLOG.md", $BACKLOG_WITH_OLD);
    write_file("$dir/CHANGELOG.md", $EMPTY_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'retire', '--id=old-item', '--task=1');
    isnt($rc, 0, 'exit non-zero');
    like($err, qr/multiple directories match/, 'multi-match error');
    like($err, qr/'1-bugfix-a'/, 'lists 1-bugfix-a single-quoted');
    like($err, qr/manually create '## Task 1: <title>' in CHANGELOG\.md first/,
        'names the manual workaround');
};

#==============================================================================
# TC-AC1 (FR1): end-to-end bootstrap path produces well-formed CHANGELOG
#==============================================================================
subtest 'TC-AC1: bootstrap path creates entry + appends retired block' => sub {
    plan tests => 6;
    my $dir = make_project();
    touch_dir($dir, '147-feature-foo-bar');
    write_file("$dir/BACKLOG.md", $BACKLOG_WITH_OLD);
    write_file("$dir/CHANGELOG.md", $EMPTY_CHANGELOG);
    my ($rc, $out, $err) = run_bm($dir, 'retire', '--id=old-item', '--task=147');
    is($rc, 0, "exit 0 (err: $err)");
    my $cl = slurp("$dir/CHANGELOG.md");
    like($cl, qr/^## Task 147: foo bar$/m,         'task heading created');
    like($cl, qr/^### Status: In Progress$/m,      'placeholder Status');
    like($cl, qr/^### Impact: Task in progress\.$/m, 'placeholder Impact');
    like($cl, qr/^### Retired Backlog Items$/m,    'retired subsection present');
    my $bl = slurp("$dir/BACKLOG.md");
    unlike($bl, qr/^## Task: Old Item$/m,          'BACKLOG no longer has Old Item');
};

#==============================================================================
# TC-AC4 (NFR2): bootstrap output passes `backlog-manager validate`
#==============================================================================
subtest 'TC-AC4: post-bootstrap files pass validate' => sub {
    plan tests => 2;
    my $dir = make_project();
    touch_dir($dir, '147-feature-foo-bar');
    write_file("$dir/BACKLOG.md", $BACKLOG_WITH_OLD);
    write_file("$dir/CHANGELOG.md", $EMPTY_CHANGELOG);
    my ($rc, undef, undef) = run_bm($dir, 'retire', '--id=old-item', '--task=147');
    is($rc, 0, 'bootstrap exit 0');
    my ($vrc, undef, $verr) = run_bm($dir, 'validate');
    is($vrc, 0, "validate exit 0 after bootstrap (err: $verr)");
};

#==============================================================================
# TC-AC3 (FR3, NFR3): second retire takes existing-entry path; round-trip clean
#==============================================================================
subtest 'TC-AC3: second retire reuses bootstrapped entry, single heading' => sub {
    plan tests => 5;
    my $dir = make_project();
    touch_dir($dir, '147-feature-foo-bar');
    my $bl_two = <<'END';
# CWF System Backlog

Future tasks.


## Task: Old Item

### Task-Type: chore
### Priority: Low

body 1


## Task: Other Item

### Task-Type: chore
### Priority: Low

body 2
END
    write_file("$dir/BACKLOG.md", $bl_two);
    write_file("$dir/CHANGELOG.md", $EMPTY_CHANGELOG);
    my ($rc1, undef, $err1) = run_bm($dir, 'retire', '--id=old-item',   '--task=147');
    is($rc1, 0, "first retire (bootstrap) exit 0 (err: $err1)");
    my ($rc2, undef, $err2) = run_bm($dir, 'retire', '--id=other-item', '--task=147');
    is($rc2, 0, "second retire (existing-entry path) exit 0 (err: $err2)");
    my $cl = slurp("$dir/CHANGELOG.md");
    my $headings = () = $cl =~ /^## Task 147:/mg;
    is($headings, 1, 'exactly one `## Task 147:` heading after both retires');
    # Both blocks present under Retired Backlog Items, in order
    my $old_pos   = index($cl, "#### Old Item");
    my $other_pos = index($cl, "#### Other Item");
    cmp_ok($old_pos, '>=', 0, 'Old Item block present') and
        cmp_ok($other_pos, '>', $old_pos, 'Other Item appears after Old Item');
};

#==============================================================================
# TC-AC6 (FR8): --help unchanged + --note works in bootstrap path
#==============================================================================
subtest 'TC-AC6: --note in bootstrap path appears in CHANGELOG' => sub {
    plan tests => 2;
    my $dir = make_project();
    touch_dir($dir, '147-feature-foo-bar');
    write_file("$dir/BACKLOG.md", $BACKLOG_WITH_OLD);
    write_file("$dir/CHANGELOG.md", $EMPTY_CHANGELOG);
    my ($rc, undef, $err) = run_bm($dir, 'retire',
        '--id=old-item', '--task=147', '--note=migrated mid-task');
    is($rc, 0, "exit 0 (err: $err)");
    my $cl = slurp("$dir/CHANGELOG.md");
    like($cl, qr/<!-- Note: migrated mid-task -->/, 'note rendered in HTML comment');
};

#==============================================================================
# TC-AC7 (NFR1): re-run after simulated partial state succeeds and dedups
#==============================================================================
subtest 'TC-AC7: re-run after partial state dedups CHANGELOG' => sub {
    plan tests => 3;
    my $dir = make_project();
    touch_dir($dir, '147-feature-foo-bar');
    write_file("$dir/BACKLOG.md", $BACKLOG_WITH_OLD);
    write_file("$dir/CHANGELOG.md", $EMPTY_CHANGELOG);
    # Run once to land the bootstrapped entry + block.
    my ($rc1, undef, undef) = run_bm($dir, 'retire', '--id=old-item', '--task=147');
    is($rc1, 0, 'first retire exit 0');
    my $cl_after_first = slurp("$dir/CHANGELOG.md");
    # Restore BACKLOG to its pre-retire state to simulate the "CHANGELOG
    # written, BACKLOG write crashed" crash window (NFR1 § crash recovery).
    write_file("$dir/BACKLOG.md", $BACKLOG_WITH_OLD);
    my ($rc2, undef, $err2) = run_bm($dir, 'retire', '--id=old-item', '--task=147');
    is($rc2, 0, "re-run exit 0 (err: $err2)");
    my $cl_after_second = slurp("$dir/CHANGELOG.md");
    is($cl_after_second, $cl_after_first, 'CHANGELOG byte-unchanged on dedup re-run');
};

#==============================================================================
# TC-AC8a (NFR4 — symlink): symlinked CHANGELOG.md → refuse
#==============================================================================
subtest 'TC-AC8a: symlinked CHANGELOG.md refused before write' => sub {
    plan tests => 3;
    my $dir = make_project();
    touch_dir($dir, '147-feature-foo-bar');
    write_file("$dir/BACKLOG.md", $BACKLOG_WITH_OLD);
    write_file("$dir/CHANGELOG.target", $EMPTY_CHANGELOG);
    symlink('CHANGELOG.target', "$dir/CHANGELOG.md") or die "symlink: $!";
    my $bl_before = slurp("$dir/BACKLOG.md");
    my ($rc, undef, $err) = run_bm($dir, 'retire', '--id=old-item', '--task=147');
    isnt($rc, 0, 'exit non-zero');
    like($err, qr/refusing symlink/, 'symlink guard fires');
    is(slurp("$dir/BACKLOG.md"), $bl_before, 'BACKLOG unchanged');
};

#==============================================================================
# TC-AC8b (NFR4 — non-integer task): `--task=foo` → refuse before any FS read
#==============================================================================
subtest 'TC-AC8b: --task=foo refused with integer-guard message' => sub {
    plan tests => 2;
    my $dir = make_project();
    touch_dir($dir, '147-feature-foo-bar');
    write_file("$dir/BACKLOG.md", $BACKLOG_WITH_OLD);
    write_file("$dir/CHANGELOG.md", $EMPTY_CHANGELOG);
    my ($rc, undef, $err) = run_bm($dir, 'retire', '--id=old-item', '--task=foo');
    isnt($rc, 0, 'exit non-zero');
    like($err, qr/invalid --task/, 'integer-guard message');
};

#==============================================================================
# TC-AC8d (D7 — title validation rejects `:`)
#==============================================================================
subtest 'TC-AC8d: title containing `:` is rejected' => sub {
    plan tests => 2;
    my $dir = make_project();
    # Hand-create a directory whose slug contains `:` — the regex captures
    # `foo:bar` as the slug, transform yields the same string, validator
    # rejects because `:` would break the `^## Task N:` parser.
    touch_dir($dir, '301-feature-foo:bar');
    write_file("$dir/BACKLOG.md", $BACKLOG_WITH_OLD);
    write_file("$dir/CHANGELOG.md", $EMPTY_CHANGELOG);
    my ($rc, undef, $err) = run_bm($dir, 'retire', '--id=old-item', '--task=301');
    isnt($rc, 0, 'exit non-zero');
    like($err, qr/derived title 'foo:bar' violates CHANGELOG heading constraints \(contains :\)/,
        'title-validation error');
};

done_testing;
