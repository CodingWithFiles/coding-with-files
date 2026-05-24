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
    plan tests => 8;
    my $tmp = build_fixture(manifest => standard_manifest());
    my ($exit, $out, $err) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    like($out, qr/added 3 allowlist entries, 1 hook entries/,
         'summary reports 3 allow + 1 hook');
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
                         command => '.cwf/scripts/hooks/a-hook',
                         timeout => 5 }],
              'Stop[0].hooks contains the one hook');
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

# ----- TC-U3: hooks across multiple matcher objects ------------------------
subtest 'TC-U3: hooks across multiple matchers — no dup, append into [0]' => sub {
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
    my ($exit) = run_helper($tmp);
    is($exit, 0, 'exit 0');
    my $s = read_settings($tmp);
    my $stop = $s->{hooks}{Stop};
    is(scalar(@$stop), 2, 'still 2 matcher objects');
    # Stop[0]: original user-lint + appended stop-warn
    my @cmds0 = map { $_->{command} } @{ $stop->[0]{hooks} };
    is_deeply(\@cmds0,
              ['user-lint', '.cwf/scripts/hooks/stop-warn'],
              'Stop[0] = user-lint + appended stop-warn');
    # Stop[1]: untouched (no dup of stop-stale into [0])
    my @cmds1 = map { $_->{command} } @{ $stop->[1]{hooks} };
    is_deeply(\@cmds1,
              ['.cwf/scripts/hooks/stop-stale'],
              'Stop[1] unchanged — stop-stale not duplicated');
};

# ----- TC-U4: --dry-run does not write -------------------------------------
subtest 'TC-U4: --dry-run prints, does not write' => sub {
    plan tests => 4;
    my $tmp = build_fixture(manifest => standard_manifest());
    my ($exit, $out, $err) = run_helper($tmp, '--dry-run');
    is($exit, 0, 'exit 0');
    ok(!-e "$tmp/.claude/settings.json", 'settings.json not created');
    like($out, qr/"permissions"/, 'stdout contains rendered JSON');
    like($out, qr/would add 3 allowlist entries, 1 hook entries, 1 env keys \(dry-run\)/,
         'dry-run summary present');
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
                 command => '.cwf/scripts/hooks/sa-guard',
                 timeout => 5 }],
              'hook entry under the matcher group');
    ok(!exists $s->{hooks}{Stop} || !grep({
            grep { $_->{command} eq '.cwf/scripts/hooks/sa-guard' } @{ $_->{hooks} || [] }
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
    ok((grep { $_->{command} eq '.cwf/scripts/hooks/sneaky' } @cmds),
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
    ok((grep { $_->{command} eq '.cwf/scripts/hooks/linky' } @cmds),
       'hook registered under default Stop event');
};

done_testing();
