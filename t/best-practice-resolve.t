#!/usr/bin/env perl
#
# best-practice-resolve.t - Unit/integration tests for
# .cwf/scripts/command-helpers/best-practice-resolve
#
# Each subtest builds a synthetic CWF-layout repo (and an isolated HOME),
# writes a throwaway best-practices.json, runs the helper as a subprocess, and
# asserts on its stdout confirmation line, the `.out` it wrote, its stderr
# diagnostics, and its exit code. No network is used.
#
# The helper's whole job is: read the config(s), match tags, and emit the
# matched entries' `documentation` paths VERBATIM (one `- <tags>: <path>` line
# each). It does not check existence, confine paths, or list directory contents
# — so the tests assert verbatim path emission and never create doc files.
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

my $HELPER   = "$FindBin::Bin/../.cwf/scripts/command-helpers/best-practice-resolve";
my $CLASSIFY = "$FindBin::Bin/../.cwf/scripts/command-helpers/security-review-classify";
my $J = JSON::PP->new->canonical;

# Capture files live OUTSIDE any repo under test.
my $CAPTURE_DIR = tempdir(CLEANUP => 1);
my $CAPTURE_SEQ = 0;

# Track the .out files the helper reports (they hang off a dashified /tmp
# namespace, outside the synthetic-repo tempdirs, so CLEANUP misses them).
my @CLEANUP_OUT;
END {
    for my $p (@CLEANUP_OUT) {
        next unless defined $p;
        unlink $p;
        (my $leaf = $p)   =~ s{/[^/]+$}{};   # task-<num> leaf
        rmdir $leaf;
        (my $parent = $leaf) =~ s{/[^/]+$}{}; # cwf<dash> parent
        rmdir $parent;
    }
}

sub git_in { my ($dir, @a) = @_; system('git', '-C', $dir, @a) }

# A synthetic repo: git init + implementation-guide/<num>-<type>-<slug>/a-task-plan.md.
# %opt: num/type/slug (defaults 1/feature/demo), task_tags => [..] (optional
# per-task **Tags** line). No commits are needed — the helper reads the working
# tree.
sub new_repo {
    my (%opt) = @_;
    my $repo = tempdir(CLEANUP => 1) . "/repo";
    make_path($repo);
    git_in($repo, 'init', '-q', '--initial-branch=main');

    my $num  = $opt{num}  // '1';
    my $type = $opt{type} // 'feature';
    my $slug = $opt{slug} // 'demo';
    my $tdir = "$repo/implementation-guide/${num}-${type}-${slug}";
    make_path($tdir);
    open my $a, '>:encoding(UTF-8)', "$tdir/a-task-plan.md" or die;
    print $a "# Plan\n\n## Task Reference\n- **Branch**: ${type}/${num}-${slug}\n";
    if ($opt{task_tags}) {
        print $a "- **Tags**: " . join(', ', @{ $opt{task_tags} }) . "\n";
    }
    print $a "- **Template Version**: 2.1\n";
    close $a;
    return $repo;
}

sub new_home { return tempdir(CLEANUP => 1) }

sub proj_config { my ($repo, $data) = @_; write_json("$repo/.cwf/best-practices.json", $data) }
sub user_config { my ($home, $data) = @_; write_json("$home/.cwf/best-practices.json", $data) }

sub write_json {
    my ($path, $data) = @_;
    (my $dir = $path) =~ s{/[^/]+$}{};
    make_path($dir);
    open my $f, '>:raw', $path or die "open $path: $!";
    print $f $J->encode($data);
    close $f;
}

sub write_raw {
    my ($path, $content) = @_;
    (my $dir = $path) =~ s{/[^/]+$}{};
    make_path($dir) if length $dir;
    open my $f, '>:raw', $path or die "open $path: $!";
    print $f $content;
    close $f;
}

# Run the helper inside $repo with HOME=$home; capture (stdout, stderr, exit).
sub run {
    my ($repo, $home, @args) = @_;
    $CAPTURE_SEQ++;
    my $of = "$CAPTURE_DIR/out.$CAPTURE_SEQ";
    my $ef = "$CAPTURE_DIR/err.$CAPTURE_SEQ";
    local $ENV{HOME} = $home;
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
    if ($out =~ /^best-practice-resolve: wrote \d+ matched entries to (.+)$/m) {
        push @CLEANUP_OUT, $1;
    }
    return ($out, $err, $rc);
}
sub slurp { my ($p) = @_; open my $f, '<:encoding(UTF-8)', $p or return ''; local $/; my $c = <$f>; close $f; return $c // '' }

sub conf_count { my ($o) = @_; $o =~ /^best-practice-resolve: wrote (\d+) matched entries to /m ? $1 : undef }
sub conf_path  { my ($o) = @_; $o =~ /^best-practice-resolve: wrote \d+ matched entries to (.+)$/m ? $1 : undef }
sub out_body {
    my ($o) = @_;
    my $p = conf_path($o);
    return '' unless defined $p && -e $p;
    open my $f, '<:encoding(UTF-8)', $p or return '';
    local $/;
    my $c = <$f>;
    close $f;
    return $c // '';
}

# ---------------------------------------------------------------------------
# TC-verbatim: matched entries are emitted as `- <tags>: <path>` lines, the
# path verbatim from the config (a file path and a directory path, as written).
# ---------------------------------------------------------------------------
subtest 'TC-verbatim: matched entries emitted as <tags>: <path>, verbatim' => sub {
    my $repo = new_repo();
    my $home = new_home();
    proj_config($repo, {
        'active-tags'    => ['golang', 'postgres'],
        'best-practices' => [
            { documentation => 'docs/go-style.md',           tags => ['golang'] },
            { documentation => '/home/me/analysis/postgres', tags => ['postgres'] },
        ],
    });
    my ($out, $err, $rc) = run($repo, $home, '--task-num=1', '--phase=plan');
    is($rc, 0, 'exit 0');
    is(conf_count($out), 2, 'two matched entries');
    my $m = out_body($out);
    like($m, qr{^- golang: docs/go-style\.md$}m,           'file path emitted verbatim with its tag');
    like($m, qr{^- postgres: /home/me/analysis/postgres$}m, 'absolute dir path emitted verbatim');
};

# ---------------------------------------------------------------------------
# TC-no-checks: a path that does not exist and a path outside the repo are both
# emitted verbatim (no existence check, no confinement).
# ---------------------------------------------------------------------------
subtest 'TC-no-checks: nonexistent / outside-repo paths are emitted verbatim' => sub {
    my $repo = new_repo();
    my $home = new_home();
    proj_config($repo, {
        'active-tags'    => ['t'],
        'best-practices' => [
            { documentation => '/no/such/path-xyz', tags => ['t'] },
            { documentation => '../outside.md',     tags => ['t'] },
        ],
    });
    my ($out, $err, $rc) = run($repo, $home, '--task-num=1', '--phase=plan');
    is($rc, 0, 'exit 0');
    is(conf_count($out), 2, 'both entries matched (nothing skipped)');
    my $m = out_body($out);
    like($m, qr{^- t: /no/such/path-xyz$}m, 'nonexistent path emitted (no existence check)');
    like($m, qr{^- t: \.\./outside\.md$}m,  'outside-repo path emitted (no confinement)');
};

# ---------------------------------------------------------------------------
# TC-multitag: an entry with several tags shows all of them on its line.
# ---------------------------------------------------------------------------
subtest 'TC-multitag: an entry lists all its tags' => sub {
    my $repo = new_repo();
    my $home = new_home();
    proj_config($repo, {
        'active-tags'    => ['sql'],
        'best-practices' => [ { documentation => 'db/', tags => ['postgres', 'sql'] } ],
    });
    my ($out, $err, $rc) = run($repo, $home, '--task-num=1', '--phase=plan');
    is($rc, 0, 'exit 0');
    like(out_body($out), qr{^- postgres, sql: db/$}m, 'all tags shown, path verbatim');
};

# ---------------------------------------------------------------------------
# TC-schema-invalid: a schema-invalid entry is skipped with a naming
# diagnostic; the valid entry still loads.
# ---------------------------------------------------------------------------
subtest 'TC-schema-invalid: bad entries skipped with diagnostic; valid loads' => sub {
    my $repo = new_repo();
    my $home = new_home();
    proj_config($repo, {
        'active-tags'    => ['t'],
        'best-practices' => [
            { documentation => 'ok.md', tags => ['t'] },
            { tags => ['t'] },                          # missing documentation
            { documentation => 'empty.md', tags => [] }, # empty tags
        ],
    });
    my ($out, $err, $rc) = run($repo, $home, '--task-num=1', '--phase=plan');
    is($rc, 0, 'exit 0 (bad entries are not fatal)');
    is(conf_count($out), 1, 'only the one valid entry matched');
    like($err, qr/entry #1 lacks a non-empty 'documentation'/, 'diagnostic names the missing-doc entry');
    like($err, qr/entry #2 \('empty\.md'\) has empty 'tags'/, 'diagnostic names the empty-tags entry');
    like(out_body($out), qr{^- t: ok\.md$}m, 'the valid entry still emitted');
};

# ---------------------------------------------------------------------------
# TC-failopen-broken: a whole file that is not valid JSON -> zero entries +
# diagnostic, no throw, exit 0.
# ---------------------------------------------------------------------------
subtest 'TC-failopen-broken: unparseable config degrades to zero entries, exit 0' => sub {
    my $repo = new_repo();
    my $home = new_home();
    write_raw("$repo/.cwf/best-practices.json", "{ this is not json ]]");
    my ($out, $err, $rc) = run($repo, $home, '--task-num=1', '--phase=plan');
    is($rc, 0, 'exit 0 (fail-open)');
    is(conf_count($out), 0, 'zero matched entries');
    like($err, qr/is not valid JSON; ignoring it/, 'diagnostic emitted');
};

# ---------------------------------------------------------------------------
# TC-precedence: project wins on `documentation` collision + active-tags union.
# ---------------------------------------------------------------------------
subtest 'TC-precedence: project wins on collision; active-tags unioned' => sub {
    my $repo = new_repo();
    my $home = new_home();
    proj_config($repo, {
        'active-tags'    => ['pt'],
        'best-practices' => [ { documentation => 'dup.txt', tags => ['pt'] } ],
    });
    user_config($home, {
        'active-tags'    => ['ut'],
        'best-practices' => [
            { documentation => 'dup.txt',   tags => ['ut'] },    # collides -> dropped
            { documentation => 'ufile.txt', tags => ['ut'] },    # kept; matches unioned 'ut'
        ],
    });
    my ($out, $err, $rc) = run($repo, $home, '--task-num=1', '--phase=plan');
    is($rc, 0, 'exit 0');
    my $m = out_body($out);
    like($m,   qr{^- pt: dup\.txt$}m,   'project dup.txt wins (its tag shown)');
    unlike($m, qr{^- ut: dup\.txt$}m,   'user dup.txt dropped on collision');
    like($m,   qr{^- ut: ufile\.txt$}m, 'user-only entry matched via unioned active-tags');
};

# ---------------------------------------------------------------------------
# TC-failopen-absent: neither config present -> zero entries, exit 0, and a
# .out is still written.
# ---------------------------------------------------------------------------
subtest 'TC-failopen-absent: absent config is not an error; .out still written' => sub {
    my $repo = new_repo();
    my $home = new_home();
    my ($out, $err, $rc) = run($repo, $home, '--task-num=1', '--phase=plan');
    is($rc, 0, 'exit 0');
    is(conf_count($out), 0, 'zero matched entries');
    my $p = conf_path($out);
    ok(defined $p && -e $p, 'a .out file was written even with 0 matches');
};

# ---------------------------------------------------------------------------
# TC-tags-casefold: casefold, exact-token matching (no substring).
# ---------------------------------------------------------------------------
subtest 'TC-tags-casefold: casefold exact-token match; no substring' => sub {
    my $repo = new_repo();
    my $home = new_home();
    proj_config($repo, {
        'active-tags'    => ['golang'],
        'best-practices' => [
            { documentation => 'go1.md', tags => ['golang'] },
            { documentation => 'go2.md', tags => ['Golang'] },   # casefold
            { documentation => 'pg.md',  tags => ['postgres'] },
        ],
    });
    my ($out, $err, $rc) = run($repo, $home, '--task-num=1', '--phase=plan');
    is($rc, 0, 'exit 0');
    my $m = out_body($out);
    like($m,   qr{^- golang: go1\.md$}m, 'lowercase golang matches');
    like($m,   qr{^- Golang: go2\.md$}m, 'mixed-case Golang matches (casefold)');
    unlike($m, qr{pg\.md},               'postgres does not match T={golang}');
};

# ---------------------------------------------------------------------------
# TC-tags-empty: empty T (no active-tags, no per-task Tags) -> zero matches.
# ---------------------------------------------------------------------------
subtest 'TC-tags-empty: empty tag set yields zero matches' => sub {
    my $repo = new_repo();   # no task_tags
    my $home = new_home();
    proj_config($repo, { 'best-practices' => [ { documentation => 'x.md', tags => ['t'] } ] });
    my ($out, $err, $rc) = run($repo, $home, '--task-num=1', '--phase=plan');
    is($rc, 0, 'exit 0');
    is(conf_count($out), 0, 'zero matches when T is empty');
};

# ---------------------------------------------------------------------------
# TC-tags-union: T = active-tags ∪ per-task **Tags**.
# ---------------------------------------------------------------------------
subtest 'TC-tags-union: per-task **Tags** unions with active-tags' => sub {
    my $repo = new_repo(task_tags => ['postgres']);
    my $home = new_home();
    proj_config($repo, {
        'active-tags'    => ['golang'],
        'best-practices' => [
            { documentation => 'g.md', tags => ['golang'] },
            { documentation => 'p.md', tags => ['postgres'] },
        ],
    });
    my ($out, $err, $rc) = run($repo, $home, '--task-num=1', '--phase=plan');
    is($rc, 0, 'exit 0');
    my $m = out_body($out);
    like($m, qr{^- golang: g\.md$}m,   'active-tags golang matches');
    like($m, qr{^- postgres: p\.md$}m, 'per-task postgres matches (union)');
};

# ---------------------------------------------------------------------------
# TC-argvalidation: task-num + phase + unknown-arg guards reject with exit 1
# and write no confirmation line.
# ---------------------------------------------------------------------------
subtest 'TC-argvalidation: argument guards reject with exit 1, no confirmation' => sub {
    my $repo = new_repo();
    my $home = new_home();
    my @cases = (
        ['--task-num=foo;rm -rf /', '--phase=plan'],
        ['--task-num=1', '--phase=../escape'],
        ['--task-num=1'],                       # missing --phase
        ['--phase=plan'],                        # missing --task-num
        ['--task-num=1', '--phase=plan', '--bogus'], # unknown argument
    );
    for my $args (@cases) {
        my ($out, $err, $rc) = run($repo, $home, @$args);
        is($rc, 1, "@$args exits 1");
        unlike($out, qr/^best-practice-resolve: wrote/m, "@$args writes no confirmation line");
    }
};

# ---------------------------------------------------------------------------
# TC-branch-signal: confirmation count drives the SKILL branch (0 vs >=1).
# ---------------------------------------------------------------------------
subtest 'TC-branch-signal: confirmation count is the exec/plan branch signal' => sub {
    my $repo = new_repo();
    my $home = new_home();
    proj_config($repo, {
        'active-tags'    => ['t'],
        'best-practices' => [ { documentation => 'h.md', tags => ['t'] } ],
    });
    my ($o1, $e1, $r1) = run($repo, $home, '--task-num=1', '--phase=implementation-exec');
    is($r1, 0, 'exit 0');
    cmp_ok(conf_count($o1), '>=', 1, '>=1 match -> reviewer would be invoked');

    my $repo2 = new_repo();
    my $home2 = new_home();   # no config -> 0 matches
    my ($o2, $e2, $r2) = run($repo2, $home2, '--task-num=1', '--phase=implementation-exec');
    is($r2, 0, 'exit 0');
    is(conf_count($o2), 0, '0 matches -> reviewer skipped / no findings');
};

# ---------------------------------------------------------------------------
# TC-classifier: the exec agent's verdict reuses the existing classifier.
# ---------------------------------------------------------------------------
subtest 'TC-classifier: existing security-review-classify classifies the verdict' => sub {
    my $findings = "prose...\n```cwf-review\nstate: findings\nsummary: x\n```\n";
    my $none     = "no verdict block at all\n";
    is(classify($findings), 'findings', 'a findings verdict classifies as findings');
    is(classify($none),     'error',    'an absent verdict classifies as error');
};

sub classify {
    my ($input) = @_;
    my $in = "$CAPTURE_DIR/cls.in";
    write_raw($in, $input);
    # Shell-free: open the input file as the child's STDIN, capture its stdout.
    my $pid = open(my $fh, '-|');
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        open(STDIN, '<', $in) or POSIX::_exit(127);
        exec($CLASSIFY) or POSIX::_exit(127);
    }
    my $tok = do { local $/; <$fh> };
    close $fh;
    $tok //= '';
    chomp $tok;
    return $tok;
}

done_testing();
