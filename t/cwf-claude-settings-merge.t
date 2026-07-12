#!/usr/bin/env perl
#
# cwf-claude-settings-merge.t — Unit tests for the helper that merges Bash
# allowlist + Stop hook entries into .claude/settings.json from the integrity
# manifest.
#
# Each test builds a tempdir with a synthetic .cwf/security/script-hashes.json
# (and stub files on disk so the existence check passes), optionally drops a
# starting .claude/settings.json, then runs the helper with cwd = tempdir.
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
use JSON::PP;

my $REPO    = File::Spec->rel2abs("$FindBin::Bin/..");
my $HELPER  = "$REPO/.cwf/scripts/command-helpers/cwf-claude-settings-merge";

# Build a tempdir with a synthetic manifest. $manifest is a hashref shaped like
# { scripts => { name => { path => '.cwf/scripts/...', sha256 => '...',
# permissions => '0500' }, ... } }. Stub files are created on disk for every
# manifest path that lives under .cwf/scripts/, unless the test opts out.
sub build_fixture {
    my (%opts) = @_;
    my $tmp = tempdir(CLEANUP => 1);
    my $manifest = $opts{manifest} || {};
    my $skip_disk = $opts{skip_disk_for} || {};

    my %payload = (
        last_updated => '2026-05-05',
        version      => '2.1',
        scripts      => $manifest,
    );
    make_path("$tmp/.cwf/security");
    open(my $fh, '>:raw', "$tmp/.cwf/security/script-hashes.json") or die $!;
    print $fh JSON::PP->new->pretty->canonical->encode(\%payload);
    close $fh;

    for my $name (keys %$manifest) {
        next if $skip_disk->{$name};
        my $rel = $manifest->{$name}{path};
        next unless defined $rel && $rel =~ m{^\.cwf/scripts/};
        my $abs = "$tmp/$rel";
        my ($vol, $dir, undef) = File::Spec->splitpath($abs);
        make_path($dir) unless -d $dir;
        open(my $sf, '>', $abs) or die "stub $abs: $!";
        print $sf "#!/bin/sh\n";
        close $sf;
    }
    return $tmp;
}

sub write_settings {
    my ($tmp, $obj) = @_;
    make_path("$tmp/.claude");
    open(my $fh, '>:raw', "$tmp/.claude/settings.json") or die $!;
    print $fh JSON::PP->new->pretty->canonical->encode($obj);
    close $fh;
}

sub read_settings {
    my ($tmp) = @_;
    my $path = "$tmp/.claude/settings.json";
    return undef unless -e $path;
    open(my $fh, '<:raw', $path) or die $!;
    local $/;
    my $blob = <$fh>;
    close $fh;
    return JSON::PP->new->decode($blob);
}

# Run the helper with cwd = $tmp. Returns ($exit, $stdout, $stderr).
sub run_helper {
    my ($tmp, @args) = @_;
    my $orig = getcwd();
    chdir $tmp or die $!;
    my $stdout_path = "$tmp/.helper.stdout";
    my $stderr_path = "$tmp/.helper.stderr";
    my $rc = system("$HELPER " . join(' ', map { "'$_'" } @args)
                    . " >'$stdout_path' 2>'$stderr_path'");
    my $exit = $rc >> 8;
    chdir $orig or die $!;
    open(my $oh, '<', $stdout_path) or die $!;
    my $out = do { local $/; <$oh> };
    close $oh;
    open(my $eh, '<', $stderr_path) or die $!;
    my $err = do { local $/; <$eh> };
    close $eh;
    return ($exit, $out // '', $err // '');
}

sub mk_entry {
    my ($path) = @_;
    return {
        path => $path,
        sha256 => 'a' x 64,
        permissions => '0500',
    };
}

# Standard "one of each" manifest.
sub standard_manifest {
    return {
        'cwf-manage' => mk_entry('.cwf/scripts/cwf-manage'),
        'a-helper'   => mk_entry('.cwf/scripts/command-helpers/a-helper'),
        'a-helper.d/sub' =>
            mk_entry('.cwf/scripts/command-helpers/a-helper.d/sub'),
        'a-hook' => mk_entry('.cwf/scripts/hooks/a-hook'),
    };
}

# ----- TC-U1: empty input — full population --------------------------------
subtest 'TC-U1: empty .claude/settings.json — full population' => sub {
    plan tests => 9;
    my $tmp = build_fixture(manifest => standard_manifest());
    my ($exit, $out, $err) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    # 2 hook entries: the manifest Stop hook + the always-on rules-inject
    # UserPromptSubmit hook (Task 195).
    # 3 manifest-derived allow entries + 5 Task-227 read-only corpus entries.
    like($out, qr/added 8 allowlist entries, 2 hook entries/,
         'summary reports 8 allow (3 manifest + 5 corpus) + 2 hooks');
    my $s = read_settings($tmp);
    ok($s, 'settings.json was created');
    my %allow = map { $_ => 1 } @{ $s->{permissions}{allow} };
    ok($allow{'Bash(.cwf/scripts/cwf-manage:*)'},
       'cwf-manage as :*');
    ok($allow{'Bash(.cwf/scripts/command-helpers/a-helper:*)'},
       'top-level helper as :*');
    ok(!$allow{'Bash(.cwf/scripts/command-helpers/a-helper.d/sub:*)'},
       '.d/ subcommand NOT in allow');
    ok($allow{'Bash(.cwf/scripts/hooks/a-hook)'},
       'hook as exact (no :*)');
    my $hooks = $s->{hooks}{Stop}[0]{hooks};
    is_deeply($hooks, [{ type => 'command',
                         command => '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/a-hook',
                         timeout => 5 }],
              'Stop[0].hooks contains the one hook (CLAUDE_PROJECT_DIR-prefixed)');
    is_deeply($s->{hooks}{UserPromptSubmit},
              [{ hooks => [{ type => 'command',
                             command => 'cat "${CLAUDE_PROJECT_DIR}/.cwf/rules-inject.txt" 2>/dev/null || true' }] }],
              'UserPromptSubmit holds the rules-inject hook (group-wrapper shape)');
};

# ----- TC-U2: pre-populated allowlist — additive, dedup, idempotent ---------
subtest 'TC-U2: pre-populated allowlist preserved + dedup + idempotent' => sub {
    plan tests => 5;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, {
        permissions => {
            allow => [
                'Bash(git status:*)',
                'Bash(.cwf/scripts/cwf-manage:*)',
            ],
        },
    });
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    my @allow = @{ $s->{permissions}{allow} };
    is($allow[0], 'Bash(git status:*)', 'existing entry preserved at index 0');
    is($allow[1], 'Bash(.cwf/scripts/cwf-manage:*)',
       'existing CWF entry preserved at index 1 (no dup)');
    my $count = grep { $_ eq 'Bash(.cwf/scripts/cwf-manage:*)' } @allow;
    is($count, 1, 'cwf-manage appears exactly once');

    # Idempotency: re-run, byte-identical output
    open(my $f1, '<:raw', "$tmp/.claude/settings.json") or die $!;
    my $first = do { local $/; <$f1> };
    close $f1;
    my ($e2) = run_helper($tmp);
    open(my $f2, '<:raw', "$tmp/.claude/settings.json") or die $!;
    my $second = do { local $/; <$f2> };
    close $f2;
    is($first, $second, 'second run produces byte-identical file');
};

# ----- TC-U3: pre-existing RELATIVE CWF hook is re-linked; user hook preserved
# (Task 204) A bare-relative CWF hook command already in settings.json is pruned
# (its now-empty matcher group dropped) and re-emitted in the prefixed form, while
# a non-CWF user hook in the same event is left untouched. This supersedes the
# old "two matcher objects, no-dup append" expectation: the relative CWF entry is
# no longer kept verbatim — it is migrated.
subtest 'TC-U3: relative CWF hook re-linked to ${CLAUDE_PROJECT_DIR}; user hook kept' => sub {
    plan tests => 4;
    my $manifest = {
        'stop-stale' => mk_entry('.cwf/scripts/hooks/stop-stale'),
        'stop-warn'  => mk_entry('.cwf/scripts/hooks/stop-warn'),
    };
    my $tmp = build_fixture(manifest => $manifest);
    write_settings($tmp, {
        hooks => {
            Stop => [
                { hooks => [ { type => 'command',
                               command => 'user-lint',
                               timeout => 10 } ] },
                { hooks => [ { type => 'command',
                               command => '.cwf/scripts/hooks/stop-stale',
                               timeout => 5 } ] },
            ],
        },
    });
    my ($exit, $out) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    like($out, qr/re-linked 1 stale relative CWF hook command /,
         'surfaced the single re-linked relative CWF hook');
    my $s = read_settings($tmp);
    my $stop = $s->{hooks}{Stop};
    is(scalar(@$stop), 1, 'emptied relative-hook group dropped → 1 group remains');
    my @cmds0 = map { $_->{command} } @{ $stop->[0]{hooks} };
    is_deeply(\@cmds0,
              ['user-lint',
               '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/stop-stale',
               '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/stop-warn'],
              'user hook preserved; stop-stale re-linked + stop-warn added, both prefixed');
};

# ----- TC-U4: --dry-run does not write -------------------------------------
subtest 'TC-U4: --dry-run prints, does not write' => sub {
    plan tests => 4;
    my $tmp = build_fixture(manifest => standard_manifest());
    my ($exit, $out, $err) = run_helper($tmp, '--dry-run');
    is($exit, 0, 'exit 0');
    ok(!-e "$tmp/.claude/settings.json", 'settings.json not created');
    like($out, qr/"permissions"/, 'stdout contains rendered JSON');
    like($out, qr/would add 8 allowlist entries, 2 hook entries, 1 env keys \(dry-run\)/,
         'dry-run summary present (3 manifest + 5 corpus allow; incl. rules-inject hook)');
};

# ----- TC-U5(a): manifest path traversal ------------------------------------
subtest 'TC-U5a: refuse manifest path with ..' => sub {
    plan tests => 3;
    my $manifest = {
        'evil' => { path => '.cwf/scripts/../../../etc/passwd',
                    sha256 => 'b' x 64, permissions => '0500' },
    };
    my $tmp = build_fixture(manifest => $manifest, skip_disk_for => { evil => 1 });
    my ($exit, $out, $err) = run_helper($tmp);
    isnt($exit, 0, 'non-zero exit');
    like($err, qr{\Q[CWF] ERROR: refusing manifest path:\E .*\Q..\E},
         'rejects path with ..');
    ok(!-e "$tmp/.claude/settings.json", 'no file written');
};

# ----- TC-U5(b): settings.json is a symlink ---------------------------------
subtest 'TC-U5b: refuse settings.json symlink' => sub {
    plan tests => 3;
    my $tmp = build_fixture(manifest => standard_manifest());
    make_path("$tmp/.claude");
    open(my $tf, '>', "$tmp/elsewhere.json") or die $!;
    print $tf "{}\n";
    close $tf;
    symlink("$tmp/elsewhere.json", "$tmp/.claude/settings.json")
        or do { plan skip_all => 'symlink not supported'; return };
    my ($exit, $out, $err) = run_helper($tmp);
    isnt($exit, 0, 'non-zero exit');
    like($err, qr{\Q.claude/settings.json must be a regular file\E},
         'error mentions regular file requirement');
    ok(-l "$tmp/.claude/settings.json", 'symlink unchanged');
};

# ----- TC-U5(c): .claude/ is a symlink --------------------------------------
subtest 'TC-U5c: refuse .claude/ symlink' => sub {
    plan tests => 3;
    my $tmp = build_fixture(manifest => standard_manifest());
    make_path("$tmp/elsewhere");
    symlink("$tmp/elsewhere", "$tmp/.claude")
        or do { plan skip_all => 'symlink not supported'; return };
    my ($exit, $out, $err) = run_helper($tmp);
    isnt($exit, 0, 'non-zero exit');
    like($err, qr{\Q.claude/ must be a regular directory\E},
         'error mentions directory requirement');
    ok(!-e "$tmp/elsewhere/settings.json", 'no file written into target');
};

# ----- TC-U5(d): malformed JSON in settings.json ----------------------------
subtest 'TC-U5d: refuse malformed settings.json' => sub {
    plan tests => 3;
    my $tmp = build_fixture(manifest => standard_manifest());
    make_path("$tmp/.claude");
    open(my $sf, '>', "$tmp/.claude/settings.json") or die $!;
    print $sf "{ this is not valid json";
    close $sf;
    my ($exit, $out, $err) = run_helper($tmp);
    isnt($exit, 0, 'non-zero exit');
    like($err, qr{\Q[CWF] ERROR: cannot parse .claude/settings.json\E},
         'parse-error message');
    open(my $fh, '<:raw', "$tmp/.claude/settings.json") or die $!;
    my $blob = do { local $/; <$fh> };
    close $fh;
    is($blob, "{ this is not valid json", 'original file untouched');
};

# ----- TC-U6: missing-on-disk manifest entry warns and skips ----------------
subtest 'TC-U6: manifest entry references missing file — warn-and-skip' => sub {
    plan tests => 4;
    my $manifest = standard_manifest();
    $manifest->{'missing'} = mk_entry('.cwf/scripts/command-helpers/missing-helper');
    my $tmp = build_fixture(
        manifest      => $manifest,
        skip_disk_for => { missing => 1 },
    );
    my ($exit, $out, $err) = run_helper($tmp);
    is($exit, 0, 'exit 0 (warn-and-skip is non-fatal)');
    like($err,
         qr{\Q[CWF] WARN: manifest entry .cwf/scripts/command-helpers/missing-helper not found on disk; skipping\E},
         'WARN line emitted');
    my $s = read_settings($tmp);
    my %allow = map { $_ => 1 } @{ $s->{permissions}{allow} };
    ok(!$allow{'Bash(.cwf/scripts/command-helpers/missing-helper:*)'},
       'missing helper not in allowlist');
    ok($allow{'Bash(.cwf/scripts/command-helpers/a-helper:*)'},
       'present helper still in allowlist');
};

# ----- TC-U7: env.PERL5OPT absent — added -----------------------------------
subtest 'TC-U7: env.PERL5OPT absent — added as -CDSLA' => sub {
    plan tests => 4;
    my $tmp = build_fixture(manifest => standard_manifest());
    my ($exit, $out, $err) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    like($out, qr/1 env keys/, 'summary reports 1 env key added');
    my $s = read_settings($tmp);
    is($s->{env}{PERL5OPT}, '-CDSLA', 'env.PERL5OPT set to -CDSLA');
    unlike($err, qr/env\.PERL5OPT/, 'no env warning on clean add');
};

# ----- TC-U8: env.PERL5OPT already correct — no-op --------------------------
subtest 'TC-U8: env.PERL5OPT already -CDSLA — no-op, no warn' => sub {
    plan tests => 4;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, { env => { PERL5OPT => '-CDSLA' } });
    my ($exit, $out, $err) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    like($out, qr/0 env keys/, 'summary reports 0 env keys added');
    my $s = read_settings($tmp);
    is($s->{env}{PERL5OPT}, '-CDSLA', 'value unchanged');
    unlike($err, qr/env\.PERL5OPT/, 'no warning when already correct');
};

# ----- TC-U9: env.PERL5OPT mismatch — warn, untouched -----------------------
subtest 'TC-U9: env.PERL5OPT differs — warn, value untouched' => sub {
    plan tests => 4;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, { env => { PERL5OPT => '-CDSL' } });
    my ($exit, $out, $err) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    like($out, qr/0 env keys/, 'summary reports 0 env keys added');
    my $s = read_settings($tmp);
    is($s->{env}{PERL5OPT}, '-CDSL', 'existing value left untouched');
    like($err, qr{\Q[CWF] WARN: .claude/settings.json env.PERL5OPT is "-CDSL"; CWF expects "-CDSLA"\E},
         'mismatch warning names both values');
};

# ----- TC-U10: env present but not an object — warn, untouched --------------
subtest 'TC-U10: env is not an object — warn, untouched' => sub {
    plan tests => 4;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, { env => 'not-an-object' });
    my ($exit, $out, $err) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    like($out, qr/0 env keys/, 'summary reports 0 env keys added');
    my $s = read_settings($tmp);
    is($s->{env}, 'not-an-object', 'env left untouched');
    like($err, qr{\Q[CWF] WARN: .claude/settings.json 'env' is present but not an object\E},
         'non-object env warning emitted');
};

# ----- TC-U11: env.PERL5OPT not a string — warn, untouched ------------------
subtest 'TC-U11: env.PERL5OPT non-scalar — warn, untouched' => sub {
    plan tests => 4;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, { env => { PERL5OPT => ['x'] } });
    my ($exit, $out, $err) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    like($out, qr/0 env keys/, 'summary reports 0 env keys added');
    my $s = read_settings($tmp);
    is_deeply($s->{env}{PERL5OPT}, ['x'], 'non-scalar value left untouched');
    like($err, qr{\Q[CWF] WARN: .claude/settings.json env.PERL5OPT is present but not a string\E},
         'non-string warning emitted');
};

# ----- TC-U12: sibling env keys preserved -----------------------------------
subtest 'TC-U12: sibling env keys preserved when adding PERL5OPT' => sub {
    plan tests => 3;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, { env => { FOO => 'bar' } });
    my ($exit, $out, $err) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    is($s->{env}{PERL5OPT}, '-CDSLA', 'PERL5OPT added');
    is($s->{env}{FOO}, 'bar', 'pre-existing sibling key preserved');
};

# ----- TC-U13: --dry-run on mismatch warns, writes nothing ------------------
subtest 'TC-U13: --dry-run warns on env mismatch, does not write' => sub {
    plan tests => 4;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, { env => { PERL5OPT => '-CDSL' } });
    my ($exit, $out, $err) = run_helper($tmp, '--dry-run');
    is($exit, 0, 'exit 0');
    like($err, qr{\Q[CWF] WARN: .claude/settings.json env.PERL5OPT is "-CDSL"\E},
         'mismatch warning fires under --dry-run');
    my $s = read_settings($tmp);
    is($s->{env}{PERL5OPT}, '-CDSL', 'on-disk value unchanged by dry-run');
    like($out, qr/0 env keys \(dry-run\)/, 'dry-run summary shows 0 env keys');
};

# Overwrite a stub file (created by build_fixture) with explicit content —
# used to give a hook stub its registration directives.
sub overwrite_file {
    my ($tmp, $rel, $content) = @_;
    my $abs = "$tmp/$rel";
    open(my $fh, '>', $abs) or die "overwrite $abs: $!";
    print $fh $content;
    close $fh;
}

# ----- TC-M1: matcher-less Stop group carries no `matcher` key --------------
subtest 'TC-M1: directive-less hook → matcher-less Stop group (no matcher key)' => sub {
    plan tests => 4;
    my $tmp = build_fixture(manifest => standard_manifest());
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    my $stop = $s->{hooks}{Stop};
    is(scalar(@$stop), 1, 'one Stop group');
    ok(!exists $stop->[0]{matcher}, 'Stop group has no matcher key');
    ok(!exists $s->{hooks}{SubagentStop},
       'no SubagentStop event for a directive-less hook');
};

# ----- TC-M2: SubagentStop + matcher directives → matchered group -----------
subtest 'TC-M2: directives register under hooks.SubagentStop as {matcher,hooks}' => sub {
    plan tests => 5;
    my $manifest = {
        'sa-guard' => mk_entry('.cwf/scripts/hooks/sa-guard'),
    };
    my $tmp = build_fixture(manifest => $manifest);
    overwrite_file($tmp, '.cwf/scripts/hooks/sa-guard',
        "#!/usr/bin/env perl\n"
      . "# cwf-hook-event: SubagentStop\n"
      . "# cwf-hook-matcher: cwf-security-reviewer-changeset\n");
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    my $sas = $s->{hooks}{SubagentStop};
    is(scalar(@$sas), 1, 'one SubagentStop group');
    is($sas->[0]{matcher}, 'cwf-security-reviewer-changeset', 'matcher set from directive');
    is_deeply($sas->[0]{hooks},
              [{ type => 'command',
                 command => '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/sa-guard',
                 timeout => 5 }],
              'hook entry under the matcher group (prefixed)');
    ok(!exists $s->{hooks}{Stop} || !grep({
            grep { $_->{command} eq '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/sa-guard' } @{ $_->{hooks} || [] }
        } @{ $s->{hooks}{Stop} }),
       'SubagentStop hook not duplicated under Stop');
};

# ----- TC-M3: idempotency across events -------------------------------------
subtest 'TC-M3: re-run adds nothing; one group per event' => sub {
    plan tests => 3;
    my $manifest = {
        'a-hook'   => mk_entry('.cwf/scripts/hooks/a-hook'),
        'sa-guard' => mk_entry('.cwf/scripts/hooks/sa-guard'),
    };
    my $tmp = build_fixture(manifest => $manifest);
    overwrite_file($tmp, '.cwf/scripts/hooks/sa-guard',
        "#!/usr/bin/env perl\n# cwf-hook-event: SubagentStop\n"
      . "# cwf-hook-matcher: cwf-security-reviewer-changeset\n");
    my ($e1) = run_helper($tmp);
    open(my $f1, '<:raw', "$tmp/.claude/settings.json") or die $!;
    my $first = do { local $/; <$f1> }; close $f1;
    my ($e2) = run_helper($tmp);
    open(my $f2, '<:raw', "$tmp/.claude/settings.json") or die $!;
    my $second = do { local $/; <$f2> }; close $f2;
    is($e2, 0, 'second run exit 0');
    is($first, $second, 'second run byte-identical (idempotent)');
    my $s = read_settings($tmp);
    is(scalar(@{ $s->{hooks}{SubagentStop} }), 1, 'still one SubagentStop group');
};

# ----- TC-M4: bogus directive values fall back to defaults ------------------
subtest 'TC-M4: invalid event/matcher directives → Stop / no matcher' => sub {
    plan tests => 4;
    my $manifest = { 'sneaky' => mk_entry('.cwf/scripts/hooks/sneaky') };
    my $tmp = build_fixture(manifest => $manifest);
    overwrite_file($tmp, '.cwf/scripts/hooks/sneaky',
        "#!/usr/bin/env perl\n"
      . "# cwf-hook-event: PreToolUse;rm\n"          # not in {Stop,SubagentStop}
      . "# cwf-hook-matcher: ../../evil path\n");    # fails [A-Za-z0-9_-]+
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    ok(!exists $s->{hooks}{'PreToolUse;rm'}, 'attacker event key not created');
    my $stop = $s->{hooks}{Stop};
    my @cmds = map { @{ $_->{hooks} } } @$stop;
    ok((grep { $_->{command} eq '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/sneaky' } @cmds),
       'hook fell back to Stop event');
    ok(!exists $stop->[0]{matcher}, 'no matcher applied from invalid directive');
};

# ----- TC-M5: directive read refuses a symlinked hook path ------------------
subtest 'TC-M5: symlinked hook path → directives not read (default Stop)' => sub {
    plan tests => 3;
    my $manifest = { 'linky' => mk_entry('.cwf/scripts/hooks/linky') };
    my $tmp = build_fixture(manifest => $manifest);
    # Target holds SubagentStop directives; if the guard fails and follows the
    # symlink, the hook would wrongly land under SubagentStop.
    open(my $tf, '>', "$tmp/real-hook") or die $!;
    print $tf "#!/usr/bin/env perl\n# cwf-hook-event: SubagentStop\n"
            . "# cwf-hook-matcher: cwf-security-reviewer-changeset\n";
    close $tf;
    unlink "$tmp/.cwf/scripts/hooks/linky";
    symlink("$tmp/real-hook", "$tmp/.cwf/scripts/hooks/linky")
        or do { plan skip_all => 'symlink not supported'; return };
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    ok(!exists $s->{hooks}{SubagentStop},
       'symlinked directives ignored — no SubagentStop group');
    my @cmds = map { @{ $_->{hooks} } } @{ $s->{hooks}{Stop} };
    ok((grep { $_->{command} eq '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/linky' } @cmds),
       'hook registered under default Stop event');
};

# ----- TC-M6: directives are read from the whole leading comment block -------
# (Task 180) The real CWF hooks place their registration directives at ~line 18,
# inside a long header comment. The directive scan must cover the leading
# comment block (stop at the first non-comment line), not a too-small fixed
# window — otherwise a hook's directives are silently missed and it falls back
# to Stop/no-matcher (the latent miss this rewrite fixes for the R3 + R1 hooks).
subtest 'TC-M6: directives deep in the header block are still read' => sub {
    plan tests => 3;
    my $tmp = build_fixture(manifest => { 'deep' => mk_entry('.cwf/scripts/hooks/deep') });
    # A realistic header: shebang + 16 comment lines, THEN the directives, THEN
    # the first code line. Directives sit at lines 18-19, past the old 15 cap.
    my $hdr = "#!/usr/bin/env perl\n" . ("# filler\n" x 16)
            . "# cwf-hook-event: PreToolUse\n# cwf-hook-matcher: Edit|Write\n"
            . "use strict;\n# cwf-hook-event: Stop\n";   # post-code line ignored
    overwrite_file($tmp, '.cwf/scripts/hooks/deep', $hdr);
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    ok($s->{hooks}{PreToolUse}, 'PreToolUse event read from line ~18');
    is($s->{hooks}{PreToolUse}[0]{matcher}, 'Edit|Write',
       'matcher read from the header block (post-code directive ignored)');
};

#=============================================================================
# Task 179 — CWF-managed sandboxing
#=============================================================================

# Write implementation-guide/cwf-project.json into the fixture. $sandbox is a
# hashref for the `sandbox` block, or undef to omit the block entirely.
sub write_config {
    my ($tmp, $sandbox) = @_;
    make_path("$tmp/implementation-guide");
    my %cfg = (
        'supported-task-types' => [qw(feature bugfix hotfix chore discovery)],
        'source-management'    => { 'branch-naming-convention' => 'x' },
    );
    $cfg{sandbox} = $sandbox if defined $sandbox;
    open(my $fh, '>:raw', "$tmp/implementation-guide/cwf-project.json") or die $!;
    print $fh JSON::PP->new->pretty->canonical->encode(\%cfg);
    close $fh;
}

sub deny_set { return { map { $_ => 1 } @{ $_[0]{permissions}{deny} || [] } } }

# ----- TC-1: sandbox OFF — no sandbox surface, no regression ----------------
subtest 'TC-1: OFF (no config / block absent) adds zero sandbox surface' => sub {
    plan tests => 8;
    # (a) config file absent entirely
    my $tmp = build_fixture(manifest => standard_manifest());
    my ($e1) = run_helper($tmp);
    is($e1, 0, '(a) exit 0');
    my $s = read_settings($tmp);
    ok(!exists $s->{sandbox}, '(a) no sandbox key');
    ok(!exists $s->{permissions}{deny}, '(a) no permissions.deny key');
    ok($s->{permissions}{allow} && @{ $s->{permissions}{allow} }, '(a) allow still populated');

    # (b) config present, sandbox block absent
    my $tmp2 = build_fixture(manifest => standard_manifest());
    write_config($tmp2, undef);
    my ($e2) = run_helper($tmp2);
    is($e2, 0, '(b) exit 0');
    my $s2 = read_settings($tmp2);
    ok(!exists $s2->{sandbox}, '(b) no sandbox key');
    ok(!exists $s2->{permissions}{deny}, '(b) no permissions.deny key');
    is($s2->{env}{PERL5OPT}, '-CDSLA', '(b) env.PERL5OPT still added');
};

# ----- TC-2: absent vs malformed -------------------------------------------
subtest 'TC-2: malformed sandbox config surfaces (never silent-OFF)' => sub {
    plan tests => 6;
    # unparseable JSON
    my $tmp = build_fixture(manifest => standard_manifest());
    make_path("$tmp/implementation-guide");
    open(my $bad, '>', "$tmp/implementation-guide/cwf-project.json") or die $!;
    print $bad "{ not valid";
    close $bad;
    my ($e1, $o1, $err1) = run_helper($tmp);
    isnt($e1, 0, 'unparseable JSON → non-zero exit');
    like($err1, qr/\Q[CWF] ERROR:\E/, 'unparseable surfaces [CWF] ERROR');

    # wrong-typed switch
    my $tmp2 = build_fixture(manifest => standard_manifest());
    write_config($tmp2, { enabled => 'yes' });
    my ($e2, $o2, $err2) = run_helper($tmp2);
    isnt($e2, 0, 'non-bool enabled → non-zero exit');
    like($err2, qr/\Qsandbox.enabled must be a boolean\E/, 'names the bad field');

    # non-array deny-list
    my $tmp3 = build_fixture(manifest => standard_manifest());
    write_config($tmp3, { enabled => JSON::PP::true, 'credential-deny-list' => '~/.ssh' });
    my ($e3, $o3, $err3) = run_helper($tmp3);
    isnt($e3, 0, 'non-array deny-list → non-zero exit');
    like($err3, qr/\Qcredential-deny-list must be an array\E/, 'names the bad field');
};

# ----- TC-4/TC-5: paired rules + exact form ---------------------------------
subtest 'TC-4/5: ON emits paired denyRead + Read(...) in the doc-specified form' => sub {
    plan tests => 7;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_config($tmp, {
        enabled                => JSON::PP::true,
        'credential-deny-list' => ['~/.ssh', '~/.aws'],
    });
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    ok($s->{sandbox}{enabled}, 'sandbox.enabled true');
    is_deeply($s->{sandbox}{filesystem}{denyRead}, ['~/.ssh', '~/.aws'],
              'denyRead == the list (~ form, expands to $HOME per Task 178)');
    my $deny = deny_set($s);
    # Exact string-form (Perl cannot exercise Claude Code's runtime matcher).
    ok($deny->{'Read(~/.ssh)'},    'Read(~/.ssh) present');
    ok($deny->{'Read(~/.ssh/**)'}, 'Read(~/.ssh/**) present');
    ok($deny->{'Read(~/.aws)'},    'Read(~/.aws) present');
    ok($deny->{'Read(~/.aws/**)'}, 'Read(~/.aws/**) present');
};

# ----- TC-6: ownership-by-shape reconcile -----------------------------------
subtest 'TC-6: reconcile by shape — removal, preservation, no orphan, AC1c' => sub {
    plan tests => 9;
    my $on = {
        enabled                => JSON::PP::true,
        'credential-deny-list' => ['~/.ssh'],
    };

    # Non-CWF deny + a user-authored Read(~/.ssh) collision pre-seeded.
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, {
        permissions => { deny => ['Bash(curl *)', 'Read(~/.ssh)'] },
    });
    write_config($tmp, $on);
    run_helper($tmp);
    my $s = read_settings($tmp);
    my $d = deny_set($s);
    ok($d->{'Read(~/.ssh)'},    'ON: managed Read present');
    ok($d->{'Read(~/.ssh/**)'}, 'ON: managed Read/** present');
    ok($d->{'Bash(curl *)'},    'ON: non-CWF deny preserved');

    # Change the list while still ON → old entry must not orphan.
    write_config($tmp, { enabled => JSON::PP::true, 'credential-deny-list' => ['~/.aws'] });
    run_helper($tmp);
    $d = deny_set(read_settings($tmp));
    ok(!$d->{'Read(~/.ssh)'},   'changed list: old Read(~/.ssh) removed (no orphan)');
    ok($d->{'Read(~/.aws)'},    'changed list: new Read(~/.aws) present');
    ok($d->{'Bash(curl *)'},    'changed list: non-CWF deny still preserved');

    # Toggle OFF → whole managed family gone, including the AC1c collision entry.
    write_config($tmp, { enabled => JSON::PP::false });
    run_helper($tmp);
    $s = read_settings($tmp);
    ok(!exists $s->{sandbox}, 'OFF: sandbox block removed');
    ok(!grep({ /^Read\(/ } @{ $s->{permissions}{deny} || [] }),
       'OFF: every CWF-shaped Read(...) removed (incl. identical user entry — AC1c)');
    is_deeply($s->{permissions}{deny}, ['Bash(curl *)'], 'OFF: only non-CWF deny remains');
};

# ----- TC-6b: idempotent ON re-run ------------------------------------------
subtest 'TC-6b: ON re-run is byte-identical (idempotent)' => sub {
    plan tests => 1;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_config($tmp, { enabled => JSON::PP::true, 'credential-deny-list' => ['~/.ssh'] });
    run_helper($tmp);
    open(my $f1, '<:raw', "$tmp/.claude/settings.json") or die $!;
    my $first = do { local $/; <$f1> }; close $f1;
    run_helper($tmp);
    open(my $f2, '<:raw', "$tmp/.claude/settings.json") or die $!;
    my $second = do { local $/; <$f2> }; close $f2;
    is($first, $second, 'second ON run byte-identical');
};

# ----- TC-7: failIfUnavailable authoritative (knob wins) --------------------
subtest 'TC-7: failIfUnavailable is authoritative from the knob' => sub {
    plan tests => 3;
    # default true
    my $tmp = build_fixture(manifest => standard_manifest());
    write_config($tmp, { enabled => JSON::PP::true });
    run_helper($tmp);
    ok(read_settings($tmp)->{sandbox}{failIfUnavailable}, 'default → true');

    # knob false reflected
    my $tmp2 = build_fixture(manifest => standard_manifest());
    write_config($tmp2, { enabled => JSON::PP::true, 'fail-if-unavailable' => JSON::PP::false });
    run_helper($tmp2);
    ok(!read_settings($tmp2)->{sandbox}{failIfUnavailable}, 'knob false → false (reflected)');

    # hand-set settings.json value is overwritten by the knob (authoritative;
    # overrides belong in the knob / settings.local.json — c-design D2).
    my $tmp3 = build_fixture(manifest => standard_manifest());
    write_settings($tmp3, { sandbox => { enabled => JSON::PP::true, failIfUnavailable => JSON::PP::false } });
    write_config($tmp3, { enabled => JSON::PP::true });   # knob default true
    run_helper($tmp3);
    ok(read_settings($tmp3)->{sandbox}{failIfUnavailable},
       'hand-set false overwritten → knob true wins (authoritative)');
};

# ----- TC-8: dep probe + first-run guard ------------------------------------
SKIP: {
    skip 'dep-probe guard is a no-op on darwin (Seatbelt)', 1 if $^O eq 'darwin';
    subtest 'TC-8: missing-dep guard warns; empty/. PATH segment not resolved' => sub {
        plan tests => 4;
        my $tmp = build_fixture(manifest => standard_manifest());
        write_config($tmp, { enabled => JSON::PP::true });
        # A bin dir with ONLY a perl symlink (so the #!/usr/bin/env perl shebang
        # still resolves) and neither bwrap nor socat.
        my $bin = "$tmp/fakebin";
        make_path($bin);
        symlink($^X, "$bin/perl")
            or do { plan skip_all => 'symlink not supported'; return };
        # Plant a fake `bwrap` in the fixture cwd to prove '.'/'' are skipped.
        open(my $fb, '>', "$tmp/bwrap") or die $!;
        print $fb "#!/bin/sh\n"; close $fb;
        chmod 0755, "$tmp/bwrap";

        local $ENV{PATH} = "$bin:.:";   # '.' + trailing empty segment
        my ($exit, $out, $err) = run_helper($tmp);
        is($exit, 0, 'guard never blocks (exit 0)');
        like($err, qr/\Q'bwrap' (package: bubblewrap)\E/,
             "bwrap reported missing — '.'/'' segments not resolved to cwd");
        like($err, qr/\Q'socat' (package: socat)\E/, 'socat reported missing');
        like($err, qr/\Qsandbox.fail-if-unavailable\E/, 'message names the knob to flip');
    };
}

# ----- TC-9: R3 hook registration gated on violation-logging ----------------
subtest 'TC-9: R3 hook registers only when violation-logging is true' => sub {
    plan tests => 4;
    my $manifest = standard_manifest();
    $manifest->{'r3'} = mk_entry('.cwf/scripts/hooks/pretooluse-sandbox-logging');

    # ON + violation-logging true → registers under PreToolUse with Bash matcher
    my $tmp = build_fixture(manifest => $manifest);
    overwrite_file($tmp, '.cwf/scripts/hooks/pretooluse-sandbox-logging',
        "#!/usr/bin/env perl\n# cwf-hook-event: PreToolUse\n# cwf-hook-matcher: Bash\n");
    write_config($tmp, { enabled => JSON::PP::true, 'violation-logging' => JSON::PP::true });
    run_helper($tmp);
    my $s = read_settings($tmp);
    my $grp = $s->{hooks}{PreToolUse};
    is($grp->[0]{matcher}, 'Bash', 'registered under PreToolUse with Bash matcher');
    ok((grep { $_->{command} eq '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/pretooluse-sandbox-logging' }
            @{ $grp->[0]{hooks} }), 'R3 hook command present');

    # ON + violation-logging false → not registered, not in allow
    my $tmp2 = build_fixture(manifest => $manifest);
    overwrite_file($tmp2, '.cwf/scripts/hooks/pretooluse-sandbox-logging',
        "#!/usr/bin/env perl\n# cwf-hook-event: PreToolUse\n# cwf-hook-matcher: Bash\n");
    write_config($tmp2, { enabled => JSON::PP::true, 'violation-logging' => JSON::PP::false });
    run_helper($tmp2);
    my $s2 = read_settings($tmp2);
    ok(!exists $s2->{hooks}{PreToolUse}, 'logging off → no PreToolUse registration');
    my %allow = map { $_ => 1 } @{ $s2->{permissions}{allow} };
    ok(!$allow{'Bash(.cwf/scripts/hooks/pretooluse-sandbox-logging)'},
       'logging off → R3 hook not in allowlist');
};

# ----- TC-10: matcher widened to a pipe-alternation of tool-name tokens ------
# (Task 180, FR1/AC1a-b/d, D5). Rewritten: the old TC-10 asserted Edit|Write was
# REJECTED (matcher-less fallback). Widening the regex to admit a pipe-separated
# allowlist of [A-Za-z0-9_-]+ tokens inverts that — Edit|Write now registers as a
# real matcher group — while every malformed alternation still falls back.
subtest 'TC-10: Edit|Write matcher accepted; malformed alternations rejected' => sub {
    plan tests => 8;
    # (a) well-formed two-token alternation → real matcher group
    my $tmp = build_fixture(manifest => { 'gen' => mk_entry('.cwf/scripts/hooks/gen-hook') });
    overwrite_file($tmp, '.cwf/scripts/hooks/gen-hook',
        "#!/usr/bin/env perl\n# cwf-hook-event: PreToolUse\n# cwf-hook-matcher: Edit|Write\n");
    my ($exit) = run_helper($tmp);
    is($exit, 0, '(a) exit 0');
    my $s = read_settings($tmp);
    ok($s->{hooks}{PreToolUse}, '(a) PreToolUse event present');
    is($s->{hooks}{PreToolUse}[0]{matcher}, 'Edit|Write',
       '(a) matcher registered as "Edit|Write"');

    # (b) malformed alternations → matcher-less fallback (no matcher key, no
    # attacker string reaches a settings key). Edit|;rm fails because `;` is
    # outside [A-Za-z0-9_-], so the anchored alternation rejects the whole value.
    for my $bad ('Edit|', '|Write', '||', 'Edit|;rm') {
        my $t = build_fixture(manifest => { 'gen' => mk_entry('.cwf/scripts/hooks/gen-hook') });
        overwrite_file($t, '.cwf/scripts/hooks/gen-hook',
            "#!/usr/bin/env perl\n# cwf-hook-event: PreToolUse\n# cwf-hook-matcher: $bad\n");
        run_helper($t);
        my $st = read_settings($t);
        ok(!exists $st->{hooks}{PreToolUse}[0]{matcher},
           "(b) malformed matcher '$bad' → matcher-less fallback");
    }

    # (c) single-token matcher still works (TC-M2 semantics unchanged)
    my $t2 = build_fixture(manifest => { 'gen' => mk_entry('.cwf/scripts/hooks/gen-hook') });
    overwrite_file($t2, '.cwf/scripts/hooks/gen-hook',
        "#!/usr/bin/env perl\n# cwf-hook-event: PreToolUse\n# cwf-hook-matcher: Bash\n");
    run_helper($t2);
    is(read_settings($t2)->{hooks}{PreToolUse}[0]{matcher}, 'Bash',
       '(c) single-token matcher unchanged');
};

#=============================================================================
# Task 180 — planning-write guard
#=============================================================================

# ----- TC-PG1: merge-time enum validator dies on a malformed knob -----------
# validate_sandbox_block_or_die rejects a bad planning-write-guard at merge
# time (not only cwf-manage validate) — a corrupt enum must surface, never
# silently degrade.
subtest 'TC-PG1: malformed planning-write-guard → [CWF] ERROR (helper dies)' => sub {
    plan tests => 4;
    # valid value merges cleanly
    my $ok = build_fixture(manifest => standard_manifest());
    write_config($ok, { enabled => JSON::PP::true, 'planning-write-guard' => 'observe' });
    my ($e_ok) = run_helper($ok);
    is($e_ok, 0, 'valid planning-write-guard:observe → exit 0');

    # bogus string value dies
    my $bad = build_fixture(manifest => standard_manifest());
    write_config($bad, { enabled => JSON::PP::true, 'planning-write-guard' => 'on' });
    my ($e_bad, undef, $err_bad) = run_helper($bad);
    isnt($e_bad, 0, 'bogus planning-write-guard → non-zero exit');
    like($err_bad, qr/\Q[CWF] ERROR:\E/, 'surfaces [CWF] ERROR');
    like($err_bad, qr/\Qsandbox.planning-write-guard\E/, 'names the bad field');
};

# Manifest that includes the guard hook (with its real PreToolUse + Edit|Write
# directives), the R3 hook, and the standard one-of-each set.
sub guard_manifest {
    my $m = standard_manifest();
    $m->{'guard'} = mk_entry('.cwf/scripts/hooks/pretooluse-planning-write-guard');
    $m->{'r3'}    = mk_entry('.cwf/scripts/hooks/pretooluse-sandbox-logging');
    return $m;
}
sub stub_guard_directives {
    my ($tmp) = @_;
    overwrite_file($tmp, '.cwf/scripts/hooks/pretooluse-planning-write-guard',
        "#!/usr/bin/env perl\n# cwf-hook-event: PreToolUse\n# cwf-hook-matcher: Edit|Write\n");
    overwrite_file($tmp, '.cwf/scripts/hooks/pretooluse-sandbox-logging',
        "#!/usr/bin/env perl\n# cwf-hook-event: PreToolUse\n# cwf-hook-matcher: Bash\n");
}
sub guard_group {
    my ($s) = @_;
    for my $g (@{ $s->{hooks}{PreToolUse} || [] }) {
        for my $h (@{ $g->{hooks} || [] }) {
            return $g if $h->{command} eq '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/pretooluse-planning-write-guard';
        }
    }
    return undef;
}

# ----- TC-PG2: guard registration gated on the knob, independent of R3 ------
subtest 'TC-PG2: guard hook registers only when planning-write-guard ne off' => sub {
    plan tests => 11;

    # (a) ON + guard off → not registered, not in allow
    my $off = build_fixture(manifest => guard_manifest());
    stub_guard_directives($off);
    write_config($off, { enabled => JSON::PP::true, 'planning-write-guard' => 'off' });
    run_helper($off);
    my $s_off = read_settings($off);
    ok(!guard_group($s_off), '(a) guard off → not registered');
    my %allow_off = map { $_ => 1 } @{ $s_off->{permissions}{allow} };
    ok(!$allow_off{'Bash(.cwf/scripts/hooks/pretooluse-planning-write-guard)'},
       '(a) guard off → not in allowlist');

    # (b) ON + guard observe → registered under PreToolUse, matcher Edit|Write
    my $obs = build_fixture(manifest => guard_manifest());
    stub_guard_directives($obs);
    write_config($obs, { enabled => JSON::PP::true, 'planning-write-guard' => 'observe' });
    run_helper($obs);
    my $g_obs = guard_group(read_settings($obs));
    ok($g_obs, '(b) guard observe → registered');
    is($g_obs->{matcher}, 'Edit|Write', '(b) matcher is Edit|Write');

    # (c) ON + guard enforce → registered too
    my $enf = build_fixture(manifest => guard_manifest());
    stub_guard_directives($enf);
    write_config($enf, { enabled => JSON::PP::true, 'planning-write-guard' => 'enforce' });
    run_helper($enf);
    my $g_enf = guard_group(read_settings($enf));
    ok($g_enf, '(c) guard enforce → registered');
    is($g_enf->{matcher}, 'Edit|Write', '(c) matcher is Edit|Write');
    my %allow_enf = map { $_ => 1 } @{ read_settings($enf)->{permissions}{allow} };
    ok($allow_enf{'Bash(.cwf/scripts/hooks/pretooluse-planning-write-guard)'},
       '(c) guard enforce → in allowlist');

    # (d) sandbox OFF + guard enforce → not registered (gate needs sandbox on)
    my $sboff = build_fixture(manifest => guard_manifest());
    stub_guard_directives($sboff);
    write_config($sboff, { enabled => JSON::PP::false, 'planning-write-guard' => 'enforce' });
    run_helper($sboff);
    ok(!guard_group(read_settings($sboff)),
       '(d) sandbox off → guard not registered even at enforce');

    # (e) R3 independence: guard enforce + violation-logging false → R3 absent,
    #     guard present; and guard off + violation-logging true → R3 present,
    #     guard absent.
    my $only_guard = build_fixture(manifest => guard_manifest());
    stub_guard_directives($only_guard);
    write_config($only_guard, { enabled => JSON::PP::true,
        'planning-write-guard' => 'enforce', 'violation-logging' => JSON::PP::false });
    run_helper($only_guard);
    my $s1 = read_settings($only_guard);
    ok(guard_group($s1), '(e) guard present');
    my $r3_cmds = join ' ', map { @{ $_->{hooks} } ? map { $_->{command} } @{ $_->{hooks} } : () }
                            @{ $s1->{hooks}{PreToolUse} || [] };
    unlike($r3_cmds, qr/pretooluse-sandbox-logging/,
       '(e) R3 absent (violation-logging false) — gates independent');

    my $only_r3 = build_fixture(manifest => guard_manifest());
    stub_guard_directives($only_r3);
    write_config($only_r3, { enabled => JSON::PP::true,
        'planning-write-guard' => 'off', 'violation-logging' => JSON::PP::true });
    run_helper($only_r3);
    my $s2 = read_settings($only_r3);
    ok(!guard_group($s2) && grep({ grep { $_->{command} eq '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/pretooluse-sandbox-logging' } @{ $_->{hooks} } }
            @{ $s2->{hooks}{PreToolUse} || [] }),
       '(e) R3 present, guard absent — gates independent');
};

#=============================================================================
# Task 195 — rules-inject UserPromptSubmit hook + dead-entry migration
#=============================================================================

my $RULES_INJECT_CMD = 'cat "${CLAUDE_PROJECT_DIR}/.cwf/rules-inject.txt" 2>/dev/null || true';

# The dead PreToolUse group that pre-fix /cwf-init wrote (matcher can never fire).
sub dead_group {
    return { matcher => 'UserPromptSubmit',
             hooks   => [ { type => 'command', command => $RULES_INJECT_CMD } ] };
}

# ----- TC-UPS1: fresh add → correct group-wrapper UserPromptSubmit shape -----
subtest 'TC-UPS1: fresh add registers UserPromptSubmit in group-wrapper shape' => sub {
    plan tests => 3;
    my $tmp = build_fixture(manifest => standard_manifest());
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    # Exact structure: group wrapper present, no matcher key, not the flat form.
    is_deeply($s->{hooks}{UserPromptSubmit},
              [{ hooks => [{ type => 'command', command => $RULES_INJECT_CMD }] }],
              'UserPromptSubmit == [ { hooks => [ {type,command} ] } ]');
    ok(!exists $s->{hooks}{UserPromptSubmit}[0]{matcher},
       'no matcher key on the UserPromptSubmit group');
};

# ----- TC-UPS2: migration removes the dead entry, preserves siblings ---------
subtest 'TC-UPS2: dead PreToolUse/UserPromptSubmit pruned; sibling preserved' => sub {
    plan tests => 6;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, {
        hooks => {
            PreToolUse => [
                dead_group(),
                { matcher => 'Edit|Write',
                  hooks   => [ { type => 'command', command => 'x' } ] },
            ],
        },
    });
    my ($exit, $out) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    my $pre = $s->{hooks}{PreToolUse};
    is(scalar(@$pre), 1, 'one PreToolUse group remains');
    is($pre->[0]{matcher}, 'Edit|Write', 'the Edit|Write sibling is preserved');
    ok(!grep({ ref($_) eq 'HASH' && ($_->{matcher} // '') eq 'UserPromptSubmit' } @$pre),
       'no PreToolUse group with matcher UserPromptSubmit survives');
    is_deeply($s->{hooks}{UserPromptSubmit},
              [{ hooks => [{ type => 'command', command => $RULES_INJECT_CMD }] }],
              'rules-inject now lives under UserPromptSubmit in the right shape');
    like($out, qr{\Q(migrated 1 legacy dead PreToolUse/UserPromptSubmit hook entry)\E},
         'stdout surfaces the migration count');
};

# ----- TC-UPS3: PreToolUse key dropped when it empties -----------------------
subtest 'TC-UPS3: PreToolUse key removed when the dead group was its only member' => sub {
    plan tests => 3;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, { hooks => { PreToolUse => [ dead_group() ] } });
    my ($exit, $out) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    ok(!exists $s->{hooks}{PreToolUse}, 'empty PreToolUse key absent (not [])');
    like($out, qr/\Qmigrated 1 legacy dead\E/, 'migration surfaced');
};

# ----- TC-UPS4: idempotent re-run -------------------------------------------
subtest 'TC-UPS4: re-run after convergence is byte-identical, adds 0 hooks' => sub {
    plan tests => 3;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, { hooks => { PreToolUse => [ dead_group() ] } });
    run_helper($tmp);
    open(my $f1, '<:raw', "$tmp/.claude/settings.json") or die $!;
    my $first = do { local $/; <$f1> }; close $f1;
    my ($e2, $out2) = run_helper($tmp);
    open(my $f2, '<:raw', "$tmp/.claude/settings.json") or die $!;
    my $second = do { local $/; <$f2> }; close $f2;
    is($e2, 0, 'second run exit 0');
    is($first, $second, 'second run byte-identical (idempotent)');
    like($out2, qr/added 0 allowlist entries, 0 hook entries/,
         'second run adds nothing and prunes nothing (no migrate note)');
};

# ----- TC-UPS5: defensive against malformed settings (never dies) -----------
subtest 'TC-UPS5: malformed PreToolUse shapes never crash; hook still registered' => sub {
    plan tests => 8;
    my @cases = (
        [ 'PreToolUse not an array', { foo => 1 } ],
        [ 'group is not a hash',     [ 'a-string', { matcher => 'Edit|Write', hooks => [] } ] ],
        [ 'group missing matcher',   [ { hooks => [] } ] ],
        [ 'matcher non-scalar',      [ { matcher => ['x'], hooks => [] } ] ],
    );
    for my $c (@cases) {
        my ($label, $pre) = @$c;
        my $tmp = build_fixture(manifest => standard_manifest());
        write_settings($tmp, { hooks => { PreToolUse => $pre } });
        my ($exit) = run_helper($tmp);
        is($exit, 0, "$label: exit 0 (no die)");
        my $s = read_settings($tmp);
        ok($s->{hooks}{UserPromptSubmit}
           && grep({ ($_->{command} // '') eq $RULES_INJECT_CMD }
                   map { @{ $_->{hooks} || [] } } @{ $s->{hooks}{UserPromptSubmit} }),
           "$label: rules-inject still registered under UserPromptSubmit");
    }
};

# ----- TC-UPS6: index-0 matcher-bearing UserPromptSubmit group --------------
subtest 'TC-UPS6: rules-inject appended into a pre-existing index-0 group; dedupes' => sub {
    plan tests => 4;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, {
        hooks => { UserPromptSubmit => [ { matcher => 'X', hooks => [] } ] },
    });
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    my $grp = $s->{hooks}{UserPromptSubmit};
    is(scalar(@$grp), 1, 'still one UserPromptSubmit group (appended into index 0)');
    is_deeply($grp->[0],
              { matcher => 'X',
                hooks   => [ { type => 'command', command => $RULES_INJECT_CMD } ] },
              'rules-inject appended into the existing matcher-bearing group');
    # Re-run must not add a second copy.
    run_helper($tmp);
    my $s2 = read_settings($tmp);
    my $n = grep { ($_->{command} // '') eq $RULES_INJECT_CMD }
            map { @{ $_->{hooks} || [] } } @{ $s2->{hooks}{UserPromptSubmit} };
    is($n, 1, 're-run dedupes — rules-inject present exactly once');
};

# ----- TC-UPS7: --dry-run writes nothing even with a dead entry -------------
subtest 'TC-UPS7: --dry-run previews migration but writes nothing' => sub {
    plan tests => 4;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, { hooks => { PreToolUse => [ dead_group() ] } });
    open(my $f0, '<:raw', "$tmp/.claude/settings.json") or die $!;
    my $before = do { local $/; <$f0> }; close $f0;
    my ($exit, $out) = run_helper($tmp, '--dry-run');
    is($exit, 0, 'exit 0');
    open(my $f1, '<:raw', "$tmp/.claude/settings.json") or die $!;
    my $after = do { local $/; <$f1> }; close $f1;
    is($before, $after, 'on-disk file untouched by --dry-run');
    like($out, qr/\Qmigrated 1 legacy dead\E.*\Q(dry-run)\E/, 'dry-run previews the migration');
    like($out, qr/"UserPromptSubmit"/, 'dry-run JSON shows the registered hook');
};

# ----- TC-UPS8: directive-driven UserPromptSubmit honoured (D4 widening) -----
subtest 'TC-UPS8: a hook requesting UserPromptSubmit registers there, not Stop' => sub {
    plan tests => 3;
    my $tmp = build_fixture(manifest => { 'ups' => mk_entry('.cwf/scripts/hooks/ups-hook') });
    overwrite_file($tmp, '.cwf/scripts/hooks/ups-hook',
        "#!/usr/bin/env perl\n# cwf-hook-event: UserPromptSubmit\n");
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    my @ups_cmds = map { @{ $_->{hooks} || [] } } @{ $s->{hooks}{UserPromptSubmit} || [] };
    ok((grep { $_->{command} eq '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/ups-hook' } @ups_cmds),
       'directive hook registered under UserPromptSubmit (not downgraded to Stop)');
    my @stop_cmds = map { @{ $_->{hooks} || [] } } @{ $s->{hooks}{Stop} || [] };
    ok(!(grep { $_->{command} eq '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/ups-hook' } @stop_cmds),
       'directive hook NOT under Stop');
};

#=============================================================================
# Task 204 — hook commands resolve from any cwd (${CLAUDE_PROJECT_DIR} prefix)
#=============================================================================

my $PFX       = '${CLAUDE_PROJECT_DIR}/';                       # literal, single-quoted
my $LEGACY_RI = 'cat .cwf/rules-inject.txt 2>/dev/null || true'; # pre-Task-204 form

# TC-13: every emitted CWF hook command carries the non-empty literal prefix.
subtest 'TC-13: hook commands emitted with literal ${CLAUDE_PROJECT_DIR}/ prefix' => sub {
    plan tests => 4;
    my $tmp = build_fixture(manifest => standard_manifest());
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    my @cmds = map { @{ $_->{hooks} || [] } }
               map { @{ $s->{hooks}{$_} || [] } } keys %{ $s->{hooks} };
    my @hookcmds = grep { $_->{command} =~ m{\.cwf/scripts/hooks/} } @cmds;
    ok(@hookcmds, 'at least one hooks/ command emitted');
    ok((!grep { index($_->{command}, $PFX) != 0 } @hookcmds),
       'every hooks/ command begins with the literal ${CLAUDE_PROJECT_DIR}/ (non-empty)');
    my ($ri) = grep { index($_->{command}, 'rules-inject') >= 0 } @cmds;
    is($ri->{command}, 'cat "${CLAUDE_PROJECT_DIR}/.cwf/rules-inject.txt" 2>/dev/null || true',
       'rules-inject command is prefixed');
};

# TC-14: prune is gate-state-independent + replaces (no duplicates) + surfaces count.
subtest 'TC-14: stale relative CWF hooks pruned regardless of sandbox gate; no dups' => sub {
    plan tests => 5;
    # Manifest includes the sandbox-gated R3 hook, but sandbox is OFF (no config),
    # so R3 is NOT re-emitted — yet a prior install's relative R3 entry must still
    # be pruned (gate-state-independence).
    my $manifest = standard_manifest();
    $manifest->{'r3'} = mk_entry('.cwf/scripts/hooks/pretooluse-sandbox-logging');
    my $tmp = build_fixture(manifest => $manifest);
    write_settings($tmp, {
        hooks => {
            Stop => [ { hooks => [
                { type => 'command', command => '.cwf/scripts/hooks/a-hook', timeout => 5 },
            ] } ],
            PreToolUse => [ { matcher => 'Bash', hooks => [
                { type => 'command', command => '.cwf/scripts/hooks/pretooluse-sandbox-logging', timeout => 5 },
            ] } ],
            UserPromptSubmit => [ { hooks => [
                { type => 'command', command => $LEGACY_RI },
            ] } ],
        },
    });
    my ($exit, $out) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    like($out, qr/re-linked 3 stale relative CWF hook commands/,
         'a-hook + R3 + legacy rules-inject all pruned (gate-independent)');
    my $s = read_settings($tmp);
    my @allcmds = map { $_->{command} } map { @{ $_->{hooks} || [] } }
                  map { @{ $s->{hooks}{$_} || [] } } keys %{ $s->{hooks} };
    ok((!grep { $_ eq '.cwf/scripts/hooks/pretooluse-sandbox-logging' } @allcmds),
       'stale relative R3 entry gone (even though R3 not re-emitted under sandbox-off)');
    ok((!grep { $_ eq '.cwf/scripts/hooks/a-hook' } @allcmds),
       'no bare-relative a-hook remains');
    my $dup = grep { $_ eq '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/a-hook' } @allcmds;
    is($dup, 1, 'a-hook present exactly once (prefixed) — no relative+prefixed duplicate');
};

# TC-15: prune is ownership-scoped — a user hook merely CONTAINING the substring is kept.
subtest 'TC-15: prune never deletes a user hook by substring match' => sub {
    plan tests => 3;
    my $tmp = build_fixture(manifest => standard_manifest());
    my $userwrap = 'wrap .cwf/scripts/hooks/a-hook --verbose';  # contains substring, not exact
    write_settings($tmp, {
        hooks => { Stop => [ { hooks => [
            { type => 'command', command => $userwrap, timeout => 5 },
        ] } ] },
    });
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    my @cmds = map { $_->{command} } map { @{ $_->{hooks} || [] } } @{ $s->{hooks}{Stop} };
    ok((grep { $_ eq $userwrap } @cmds), 'user wrapper hook preserved (no substring deletion)');
    ok((grep { $_ eq '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/a-hook' } @cmds),
       'canonical a-hook still emitted prefixed alongside it');
};

# TC-16: the prefixed command resolves+executes from a NON-ROOT cwd (fail-open closed);
# the pre-fix bare-relative form fails (exit 127) from the same cwd.
subtest 'TC-16: prefixed hook resolves from a non-root cwd; relative form does not' => sub {
    plan tests => 3;
    my $tmp = build_fixture(manifest => standard_manifest());
    run_helper($tmp);
    my $s = read_settings($tmp);
    my ($cmd) = grep { defined && m{/a-hook$} }
                map { $_->{command} } map { @{ $_->{hooks} || [] } } @{ $s->{hooks}{Stop} };
    ok(defined $cmd, 'found the prefixed a-hook command');
    chmod 0755, "$tmp/.cwf/scripts/hooks/a-hook";   # make the stub runnable
    my $sub = "$tmp/sub/dir";
    make_path($sub);
    # Mirror the harness firing a hook from the session cwd with CLAUDE_PROJECT_DIR set.
    my $rc_pfx = system("cd '$sub' && CLAUDE_PROJECT_DIR='$tmp' sh -c '$cmd' >/dev/null 2>&1");
    is($rc_pfx >> 8, 0, 'prefixed command runs from a non-root cwd (fail-open closed)');
    my $rc_rel = system("cd '$sub' && sh -c '.cwf/scripts/hooks/a-hook' >/dev/null 2>&1");
    isnt($rc_rel >> 8, 0, 'bare relative command fails from the same non-root cwd');
};

# TC-17: hook allowlist entries stay RELATIVE (agent-invoked surface, D6).
subtest 'TC-17: hook allowlist entries remain relative' => sub {
    plan tests => 2;
    my $tmp = build_fixture(manifest => standard_manifest());
    run_helper($tmp);
    my $s = read_settings($tmp);
    my %allow = map { $_ => 1 } @{ $s->{permissions}{allow} };
    ok($allow{'Bash(.cwf/scripts/hooks/a-hook)'},
       'hook allowlist entry is the bare relative Bash(.cwf/scripts/hooks/a-hook)');
    ok((!grep { /CLAUDE_PROJECT_DIR/ } keys %allow),
       'no allowlist entry carries the ${CLAUDE_PROJECT_DIR} prefix');
};

# ===========================================================================
# Task 227: read-only generic-command allowlist seed
# ===========================================================================
#
# is_read_only_safe() is the fail-closed membership gate for the corpus. It is
# authored HERE from the admission criterion's first principles (read-only for
# every argument vector the glob admits), NEVER by transforming the script's
# @READ_ONLY_ALLOWLIST — deriving it from the corpus would make this check a
# tautology that rubber-stamps whatever the corpus already contains. The two
# sets below are hand-verified and independent of the script.
#
# %SAFE_PREFIX_KEYS — command (+ subcommand) words whose ENTIRE Bash(<key>:*)
#   glob space is read-only: no flag or subcommand anywhere in their option
#   space can mutate, exec an arbitrary child, or do network I/O.
# %SAFE_EXACT_KEYS — inner strings safe ONLY as an exact Bash(<inner>) entry,
#   because the prefix form WOULD admit a mutating sibling (e.g. the
#   `git branch:*` prefix admits `git branch -D`). Kept in a separate set so a
#   prefix entry can never be accepted through an exact slot.
my %SAFE_PREFIX_KEYS = map { $_ => 1 } (
    'ls', 'pwd', 'git status', 'git rev-parse',
);
my %SAFE_EXACT_KEYS = map { $_ => 1 } (
    'git branch --show-current',
);

sub is_read_only_safe {
    my ($entry) = @_;
    return 0 unless defined $entry;
    # Parse Bash(<inner>): negated char class (no greedy .*), ASCII, fully
    # anchored with \A/\z so a trailing newline can never sneak past.
    return 0 unless $entry =~ m{\ABash\(([^()]+)\)\z}aa;
    my $inner = $1;
    # Split the :* suffix by exact substr, not a backtracking regex.
    if (length($inner) >= 2 && substr($inner, -2) eq ':*') {
        my $key = substr($inner, 0, -2);
        return $SAFE_PREFIX_KEYS{$key} ? 1 : 0;
    }
    return $SAFE_EXACT_KEYS{$inner} ? 1 : 0;
}

# ----- TC-RO1: predicate accept/reject controls (both directions, one case) -
subtest 'TC-RO1: is_read_only_safe accepts the corpus, rejects unsafe neighbours' => sub {
    plan tests => 13;
    # Positive controls — the 5 corpus entries (4 prefix + 1 exact).
    ok(is_read_only_safe('Bash(ls:*)'),               'ls:* accepted');
    ok(is_read_only_safe('Bash(pwd:*)'),              'pwd:* accepted');
    ok(is_read_only_safe('Bash(git status:*)'),       'git status:* accepted');
    ok(is_read_only_safe('Bash(git rev-parse:*)'),    'git rev-parse:* accepted');
    ok(is_read_only_safe('Bash(git branch --show-current)'),
       'git branch --show-current (exact) accepted');
    # Negative controls — each unsafe for a distinct reason (see design KD2).
    ok(!is_read_only_safe('Bash(git diff:*)'),  'git diff:* rejected (--output/--ext-diff escape)');
    ok(!is_read_only_safe('Bash(rg:*)'),        'rg:* rejected (--pre child exec)');
    ok(!is_read_only_safe('Bash(git:*)'),       'bare git:* rejected (commit/push/branch -D)');
    ok(!is_read_only_safe('Bash(find:*)'),      'find:* rejected (-exec/-delete)');
    ok(!is_read_only_safe('Bash(sed -i:*)'),    'sed -i:* rejected (in-place write)');
    ok(!is_read_only_safe('Bash(git branch:*)'),
       'git branch:* rejected (nearest dangerous neighbour: -D)');
    # The prefix form of the exact entry — MUST be rejected by the set split.
    ok(!is_read_only_safe('Bash(git branch --show-current:*)'),
       'prefix form of the exact entry rejected (exact/prefix split)');
    # Anchor discipline: a trailing newline must not slip past \z.
    ok(!is_read_only_safe("Bash(ls:*)\n"),
       'trailing-newline entry rejected (\\z, not $, anchoring)');
};

# ----- TC-RO2: exact/prefix split proven independent ------------------------
subtest 'TC-RO2: exact entry accepted, its prefix + parent prefix rejected' => sub {
    plan tests => 3;
    ok(is_read_only_safe('Bash(git branch --show-current)'),
       'exact git branch --show-current accepted');
    ok(!is_read_only_safe('Bash(git branch --show-current:*)'),
       'its prefix form cannot hit the exact slot');
    ok(!is_read_only_safe('Bash(git branch:*)'),
       'the parent prefix stays rejected');
};

# ----- TC-RO3: corpus present after a clean merge; only-safe generic entries -
subtest 'TC-RO3: clean merge seeds the corpus; every generic entry is safe' => sub {
    plan tests => 8;
    my $tmp = build_fixture(manifest => standard_manifest());
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    my @allow = @{ $s->{permissions}{allow} };
    my %allow = map { $_ => 1 } @allow;
    # All 5 corpus entries present.
    ok($allow{'Bash(ls:*)'},                        'ls:* seeded');
    ok($allow{'Bash(pwd:*)'},                       'pwd:* seeded');
    ok($allow{'Bash(git status:*)'},                'git status:* seeded');
    ok($allow{'Bash(git rev-parse:*)'},             'git rev-parse:* seeded');
    ok($allow{'Bash(git branch --show-current)'},   'git branch --show-current seeded');
    # Every allow entry that is NOT a .cwf/scripts/ manifest entry is the
    # generic corpus — each must pass the independent safety gate...
    my @generic = grep { !m{\.cwf/scripts/} } @allow;
    ok((!grep { !is_read_only_safe($_) } @generic),
       'every generic allow entry passes is_read_only_safe');
    # ...and the generic set must equal exactly the expected corpus.
    my @expected = ('Bash(ls:*)', 'Bash(pwd:*)', 'Bash(git status:*)',
                    'Bash(git rev-parse:*)', 'Bash(git branch --show-current)');
    is_deeply([sort @generic], [sort @expected],
              'generic allow set equals exactly the corpus');
};

# ----- TC-RO4: additive — a pre-existing user entry survives ----------------
subtest 'TC-RO4: corpus adds alongside a pre-existing non-CWF user entry' => sub {
    plan tests => 3;
    my $tmp = build_fixture(manifest => standard_manifest());
    write_settings($tmp, { permissions => { allow => ['Bash(npm test:*)'] } });
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    my %allow = map { $_ => 1 } @{ $s->{permissions}{allow} };
    ok($allow{'Bash(npm test:*)'}, 'pre-existing user entry preserved');
    ok($allow{'Bash(ls:*)'},       'corpus added alongside it');
};

# ----- TC-RO5: idempotent — re-run adds zero corpus duplicates --------------
subtest 'TC-RO5: re-running the merge adds no duplicate corpus entries' => sub {
    plan tests => 2;
    my $tmp = build_fixture(manifest => standard_manifest());
    run_helper($tmp);
    run_helper($tmp);
    my $s = read_settings($tmp);
    my @allow = @{ $s->{permissions}{allow} };
    my $ls_count = grep { $_ eq 'Bash(ls:*)' } @allow;
    is($ls_count, 1, 'Bash(ls:*) appears exactly once after a second merge');
    my %uniq; $uniq{$_}++ for @allow;
    ok((!grep { $_ > 1 } values %uniq), 'no allow entry is duplicated');
};

done_testing();
