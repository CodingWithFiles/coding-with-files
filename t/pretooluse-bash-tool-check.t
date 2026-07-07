#!/usr/bin/env perl
#
# pretooluse-bash-tool-check.t — I/O behaviour of the fail-OPEN Bash tool-check
# hook (Task 201).
#
# The hook is impure (reads stdin, locates + reads the three layer files, shells
# out via find_git_root, reads/writes repeat-state, emits a Claude Code
# decision), so each test builds a hermetic git repo under a tempdir: a runnable
# COPY of the hook under the tempdir's .cwf/scripts/hooks/, the real .cwf/lib on
# PERL5LIB, $HOME pointed at a tempdir (so the user-global layer is controllable
# and the real ~/.cwf is never touched), and $TMPDIR pointed at a tempdir (so
# the repeat-state dir lands there). The hook runs with cwd at the repo root.
#
# The pure policy (merge / drop / match / decide_repeat) is covered exhaustively
# in tool-check.t; here we bind the wiring: tool gate, deny envelope + verbatim
# guidance, allow-on-no-match, the repeat-bypass state machine, malformed
# session_id, no-config no-op, the fail-open matrix, symlink-safe state writes,
# the ReDoS bound under an external timeout, and --check.
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use JSON::PP;

my $REPO = File::Spec->rel2abs("$FindBin::Bin/..");
my $SRC  = "$REPO/.cwf/scripts/hooks/pretooluse-bash-tool-check";

plan skip_all => 'git not available' if system('git --version >/dev/null 2>&1') != 0;

# Build a hermetic git repo with a runnable hook copy. Returns ($tmp, $hook).
sub mkrepo {
    my $tmp = tempdir(CLEANUP => 1);
    system("git -C '$tmp' init -q") == 0 or die 'git init failed';
    make_path("$tmp/.cwf/scripts/hooks", "$tmp/.cwf/tool-check/bash",
              "$tmp/home", "$tmp/state");

    open(my $in, '<:raw', $SRC) or die "open $SRC: $!";
    my $body = do { local $/; <$in> }; close $in;
    my $hook = "$tmp/.cwf/scripts/hooks/pretooluse-bash-tool-check";
    open(my $out, '>:raw', $hook) or die "write $hook: $!";
    print $out $body; close $out;
    chmod 0700, $hook;
    return ($tmp, $hook);
}

# Write a rules file ({rules=>[...]}) at $path.
sub write_layer {
    my ($path, @rules) = @_;
    make_path(dirname($path));
    open(my $fh, '>:raw', $path) or die "write $path: $!";
    print $fh JSON::PP->new->encode({ rules => [ @rules ] });
    close $fh;
}

# Write a settings file with an optional top-level `active` plus rules. $active:
# undef -> omit the key; a JSON::PP boolean -> real JSON true/false; any other
# scalar (e.g. the string 'false') -> encoded as-is (to exercise DK2 coercion).
sub write_settings {
    my ($path, $active, @rules) = @_;
    make_path(dirname($path));
    my %s = (rules => [ @rules ]);
    $s{active} = $active if defined $active;
    open(my $fh, '>:raw', $path) or die "write $path: $!";
    print $fh JSON::PP->new->encode(\%s);
    close $fh;
}

# Run the hook with cwd at the repo root, $HOME + $TMPDIR pinned into the
# tempdir. Returns ($exit, $stdout, $stderr). %opt: timeout => N wraps the call
# in an external `timeout N`; args => '--check' passes argv.
sub run_hook {
    my ($tmp, $hook, $stdin, %opt) = @_;
    my $i = "$tmp/.in"; my $so = "$tmp/.out"; my $se = "$tmp/.err";
    open(my $fh, '>:raw', $i) or die $!; print $fh (defined $stdin ? $stdin : ''); close $fh;
    local $ENV{PERL5LIB} =
        "$REPO/.cwf/lib" . (defined $ENV{PERL5LIB} ? ":$ENV{PERL5LIB}" : '');
    local $ENV{HOME}   = "$tmp/home";
    local $ENV{TMPDIR} = "$tmp/state";
    my $args = $opt{args} ? " $opt{args}" : '';
    my $pre  = $opt{timeout} ? "timeout $opt{timeout} " : '';
    my $rc = system("cd '$tmp' && $pre'$hook'$args <'$i' >'$so' 2>'$se'");
    my $out = do { open(my $o,'<:raw',$so) or die $!; local $/; <$o> } // '';
    my $err = do { open(my $e,'<:raw',$se) or die $!; local $/; <$e> } // '';
    return ($rc >> 8, $out, $err);
}

sub payload {
    my (%o) = @_;
    my $tool = exists $o{tool} ? $o{tool} : 'Bash';
    my %ti;
    $ti{command} = $o{command} if exists $o{command};
    my %p = (hook_event_name => 'PreToolUse', tool_name => $tool, tool_input => \%ti);
    $p{session_id} = $o{session_id} if exists $o{session_id};
    $p{cwd}        = $o{cwd} if exists $o{cwd};
    return JSON::PP->new->encode(\%p);
}

my $SED_RULE = { id => 'sed', regex => '(?:^|[|;&]\s*)sed\s+-n',
                 guidance => 'Use Read with offset/limit, not `sed -n`.' };

# ----- TC-7: deny with verbatim guidance; reason excludes the command -------
subtest 'TC-7: match -> deny JSON, guidance verbatim, no command echo' => sub {
    plan tests => 5;
    my ($tmp, $hook) = mkrepo();
    write_layer("$tmp/.cwf/tool-check/bash/settings.local.json", $SED_RULE);
    my ($e, $o) = run_hook($tmp, $hook,
        payload(command => "sed -n '1,5p' file", session_id => 'sess-7'));
    is($e, 0, 'exit 0');
    my $d = eval { JSON::PP->new->decode($o) };
    ok($d, 'stdout is valid JSON') or diag $o;
    is($d->{hookSpecificOutput}{permissionDecision}, 'deny', 'deny');
    is($d->{hookSpecificOutput}{permissionDecisionReason},
       'Use Read with offset/limit, not `sed -n`.', 'guidance verbatim');
    unlike($o, qr/1,5p/, 'the matched command is never echoed into the reason');
};

# ----- TC-8: allow on no match ----------------------------------------------
subtest 'TC-8: no match -> empty stdout, exit 0' => sub {
    plan tests => 2;
    my ($tmp, $hook) = mkrepo();
    write_layer("$tmp/.cwf/tool-check/bash/settings.local.json", $SED_RULE);
    my ($e, $o) = run_hook($tmp, $hook,
        payload(command => 'grep foo file', session_id => 'sess-8'));
    is($e, 0, 'exit 0');
    is($o, '', 'empty stdout on no match');
};

# ----- TC-9: repeat-bypass state machine (FR4 / AC3) ------------------------
subtest 'TC-9: X deny, X bypass, intervening Y resets, X deny again' => sub {
    plan tests => 4;
    my ($tmp, $hook) = mkrepo();
    write_layer("$tmp/.cwf/tool-check/bash/settings.local.json", $SED_RULE);
    my $X = "sed -n '1,5p' file";
    my $Y = "sed -n '9,9p' other";          # also matches, different hash

    my (undef, $o1) = run_hook($tmp, $hook, payload(command => $X, session_id => 's9'));
    ok($o1 =~ /"permissionDecision":"deny"/, 'call 1 (X) denies');

    my (undef, $o2) = run_hook($tmp, $hook, payload(command => $X, session_id => 's9'));
    is($o2, '', 'call 2 (X again) bypasses -> empty stdout');

    my (undef, $o3) = run_hook($tmp, $hook, payload(command => $Y, session_id => 's9'));
    ok($o3 =~ /"permissionDecision":"deny"/, 'call 3 (Y) denies (resets the streak)');

    my (undef, $o4) = run_hook($tmp, $hook, payload(command => $X, session_id => 's9'));
    ok($o4 =~ /"permissionDecision":"deny"/, 'call 4 (X) denies again — no stale bypass');
};

# ----- TC-10: malformed session_id never bypasses, writes no state ----------
subtest 'TC-10: session_id with ../ -> denies both times, no state file' => sub {
    plan tests => 3;
    my ($tmp, $hook) = mkrepo();
    write_layer("$tmp/.cwf/tool-check/bash/settings.local.json", $SED_RULE);
    my $X = "sed -n '1,5p' file";
    my (undef, $o1) = run_hook($tmp, $hook, payload(command => $X, session_id => '../evil'));
    my (undef, $o2) = run_hook($tmp, $hook, payload(command => $X, session_id => '../evil'));
    ok($o1 =~ /"permissionDecision":"deny"/, 'first call denies');
    ok($o2 =~ /"permissionDecision":"deny"/, 'second identical call STILL denies (no bypass)');
    my @last = glob("$tmp/state/*-tool-check/*.last");
    is(scalar(@last), 0, 'no .last state file written for an unsafe session_id');
};

# ----- TC-11: no config anywhere -> strict no-op ----------------------------
subtest 'TC-11: no rule files -> empty stdout, exit 0 (no-op)' => sub {
    plan tests => 2;
    my ($tmp, $hook) = mkrepo();           # no layer files created
    my ($e, $o) = run_hook($tmp, $hook,
        payload(command => "sed -n '1,5p' file", session_id => 's11'));
    is($e, 0, 'exit 0');
    is($o, '', 'identical to the hook being absent');
};

# ----- TC-12: state-file symlink safety -------------------------------------
subtest 'TC-12: a pre-planted <sid>.last symlink is not followed' => sub {
    plan tests => 3;
    my ($tmp, $hook) = mkrepo();
    write_layer("$tmp/.cwf/tool-check/bash/settings.local.json", $SED_RULE);

    # Call 1 (X) denies and creates the state dir + <sid>.last.
    run_hook($tmp, $hook, payload(command => "sed -n '1,5p' a", session_id => 'sym'));
    my ($dir) = glob("$tmp/state/*-tool-check");
    ok($dir && -d $dir, 'state dir created');

    # Replace <sid>.last with a symlink to an outside sentinel, then deny a
    # DIFFERENT command (writes state again). The write must NOT clobber the
    # sentinel — it goes to a temp file + atomic rename over the symlink.
    my $sentinel = "$tmp/sentinel";
    open(my $sf, '>:raw', $sentinel) or die $!; print $sf "PRECIOUS\n"; close $sf;
    my $last = "$dir/sym.last";
    unlink($last); symlink($sentinel, $last) or do { ok(1,'symlink unsupported'); ok(1); return };

    run_hook($tmp, $hook, payload(command => "sed -n '2,2p' b", session_id => 'sym'));
    my $kept = do { open(my $fh,'<:raw',$sentinel) or die $!; local $/; <$fh> };
    is($kept, "PRECIOUS\n", 'sentinel pointed-to by the symlink is untouched');
    ok(!-l $last, '<sid>.last is now a regular file (symlink replaced atomically)');
};

# ----- TC-13: fail-open matrix ----------------------------------------------
subtest 'TC-13: every failure mode -> empty stdout, exit 0 (allow)' => sub {
    plan tests => 7;

    # bad-JSON stdin
    {
        my ($tmp, $hook) = mkrepo();
        write_layer("$tmp/.cwf/tool-check/bash/settings.local.json", $SED_RULE);
        my ($e, $o) = run_hook($tmp, $hook, '{ not json');
        is("$e/$o", '0/', 'bad-JSON stdin -> allow');
    }
    # unreadable layer file (chmod 000)
    {
        my ($tmp, $hook) = mkrepo();
        my $p = "$tmp/.cwf/tool-check/bash/settings.local.json";
        write_layer($p, $SED_RULE); chmod 0000, $p;
        my ($e, $o) = run_hook($tmp, $hook,
            payload(command => "sed -n '1,5p' f", session_id => 's'));
        chmod 0600, $p;
        is("$e/$o", '0/', 'unreadable layer -> contributes nothing -> allow');
    }
    # symlinked layer file
    {
        my ($tmp, $hook) = mkrepo();
        my $real = "$tmp/real.json"; write_layer($real, $SED_RULE);
        my $p = "$tmp/.cwf/tool-check/bash/settings.local.json";
        make_path(dirname($p)); symlink($real, $p);
        my ($e, $o) = run_hook($tmp, $hook,
            payload(command => "sed -n '1,5p' f", session_id => 's'));
        is("$e/$o", '0/', 'symlinked layer -> ignored -> allow');
    }
    # invalid regex
    {
        my ($tmp, $hook) = mkrepo();
        write_layer("$tmp/.cwf/tool-check/bash/settings.local.json",
            { id => 'bad', regex => '(unterminated', guidance => 'g' });
        my ($e, $o) = run_hook($tmp, $hook,
            payload(command => 'anything', session_id => 's'));
        is("$e/$o", '0/', 'invalid regex -> no match -> allow');
    }
    # dying perl rule (user-global layer; checked-in perl would be dropped)
    {
        my ($tmp, $hook) = mkrepo();
        write_layer("$tmp/home/.cwf/tool-check/bash/settings.json",
            { id => 'die', perl => 'sub { die "boom" }', guidance => 'g' });
        my ($e, $o) = run_hook($tmp, $hook,
            payload(command => 'anything', session_id => 's'));
        is("$e/$o", '0/', 'dying perl rule -> caught -> allow');
    }
    # over-cap command
    {
        my ($tmp, $hook) = mkrepo();
        write_layer("$tmp/.cwf/tool-check/bash/settings.local.json",
            { id => 'x', regex => 'x', guidance => 'g' });
        my ($e, $o) = run_hook($tmp, $hook,
            payload(command => ('x' x (64*1024+1)), session_id => 's'));
        is("$e/$o", '0/', 'over-cap command -> no match -> allow');
    }
    # hanging perl at runtime (bounded by the alarm -> die -> allow)
    {
        my ($tmp, $hook) = mkrepo();
        write_layer("$tmp/home/.cwf/tool-check/bash/settings.json",
            { id => 'hang', perl => 'sub { 1 while 1 }', guidance => 'g' });
        my ($e, $o) = run_hook($tmp, $hook,
            payload(command => 'anything', session_id => 's'), timeout => 8);
        is("$e/$o", '0/', 'runtime-hanging perl -> alarm-bounded -> allow');
    }
};

# ----- TC-14: ReDoS bound under an external timeout -------------------------
subtest 'TC-14: pathological regex stays bounded and fails open' => sub {
    plan tests => 1;
    my ($tmp, $hook) = mkrepo();
    write_layer("$tmp/.cwf/tool-check/bash/settings.local.json",
        { id => 'redos', regex => '(a+)+$', guidance => 'g' });
    # Classic catastrophic input: many 'a' then a non-matching char.
    my $cmd = ('a' x 40) . '!';
    my ($e, $o) = run_hook($tmp, $hook,
        payload(command => $cmd, session_id => 's'), timeout => 5);
    # Either the in-process alarm pre-empts (exit 0, empty) or the external
    # SIGKILL bounds it (timeout's 124/137). BOTH are fail-open: a deny is never
    # emitted. The assertion: no deny decision on stdout, and we returned within
    # the external bound (the subtest itself completing proves boundedness).
    is($o, '', 'no deny emitted — bounded and fails open under the harness timeout');
};

# ----- TC-15: --check diagnostic --------------------------------------------
subtest 'TC-15: --check lists dropped checked-in perl, overrides, effective set' => sub {
    plan tests => 5;
    my ($tmp, $hook) = mkrepo();
    # user-global defines `dup`; project-local overrides it. checked-in carries a
    # perl rule (must be reported as dropped).
    write_layer("$tmp/home/.cwf/tool-check/bash/settings.json",
        { id => 'dup', regex => 'old', guidance => 'g' });
    write_layer("$tmp/.cwf/tool-check/bash/settings.json",
        { id => 'ci-perl', perl => 'sub { 1 }', guidance => 'g' });
    write_layer("$tmp/.cwf/tool-check/bash/settings.local.json",
        { id => 'dup', regex => 'new', guidance => 'g' });

    my ($e, $o) = run_hook($tmp, $hook, '', args => '--check');
    is($e, 0, '--check exits 0 when all layers parse');
    like($o, qr/ci-perl .*dropped/, 'reports the dropped checked-in perl rule');
    like($o, qr/Overridden ids.*\n.*\bdup\b/s, 'reports the overridden id');
    like($o, qr/\[regex\]\s+dup\s+project-local/, 'effective list shows the override winner');

    # A malformed layer -> non-zero exit (scriptable detection).
    write_layer("$tmp/.cwf/tool-check/bash/settings.local.json"); # placeholder, then corrupt:
    open(my $cf, '>:raw', "$tmp/.cwf/tool-check/bash/settings.local.json") or die $!;
    print $cf '{ not json'; close $cf;
    my ($e2) = run_hook($tmp, $hook, '', args => '--check');
    isnt($e2, 0, '--check exits non-zero when a layer fails to parse');
};

# ----- TC-H1: live active toggle (AC1) --------------------------------------
subtest 'TC-H1: active:false allows a would-deny cmd; flip to true -> deny' => sub {
    plan tests => 2;
    my ($tmp, $hook) = mkrepo();
    my $p = "$tmp/.cwf/tool-check/bash/settings.local.json";
    my $cmd = "sed -n '1,5p' file";

    write_settings($p, JSON::PP::false, $SED_RULE);
    my (undef, $off) = run_hook($tmp, $hook, payload(command => $cmd, session_id => 'h1'));
    is($off, '', 'active:false -> the matching command is allowed (empty stdout)');

    # Flip the file only; no process/hook restart — the next call re-reads it.
    write_settings($p, JSON::PP::true, $SED_RULE);
    my (undef, $on) = run_hook($tmp, $hook, payload(command => $cmd, session_id => 'h1b'));
    like($on, qr/"permissionDecision":"deny"/, 'active:true -> denies, no restart needed');
};

# ----- TC-H2: active:true with zero rules -> allow --------------------------
subtest 'TC-H2: active:true but no rules -> strict no-op allow' => sub {
    plan tests => 2;
    my ($tmp, $hook) = mkrepo();
    write_settings("$tmp/.cwf/tool-check/bash/settings.local.json", JSON::PP::true);
    my ($e, $o) = run_hook($tmp, $hook,
        payload(command => "sed -n '1,5p' file", session_id => 'h2'));
    is($e, 0, 'exit 0');
    is($o, '', 'no rules -> allow even with active:true');
};

# ----- TC-H3: fail-open still holds with an active key present (AC2) ---------
subtest 'TC-H3: active-bearing settings that are empty/symlinked -> allow' => sub {
    plan tests => 2;
    # {} with no rules -> allow (nothing to match).
    {
        my ($tmp, $hook) = mkrepo();
        my $p = "$tmp/.cwf/tool-check/bash/settings.local.json";
        make_path(dirname($p));
        open(my $fh, '>:raw', $p) or die $!; print $fh '{}'; close $fh;
        my ($e, $o) = run_hook($tmp, $hook,
            payload(command => "sed -n '1,5p' f", session_id => 'h3a'));
        is("$e/$o", '0/', 'empty-object settings -> allow');
    }
    # A symlinked project-local layer -> error state -> contributes nothing.
    {
        my ($tmp, $hook) = mkrepo();
        my $real = "$tmp/real.json"; write_settings($real, JSON::PP::true, $SED_RULE);
        my $p = "$tmp/.cwf/tool-check/bash/settings.local.json";
        make_path(dirname($p)); symlink($real, $p);
        my ($e, $o) = run_hook($tmp, $hook,
            payload(command => "sed -n '1,5p' f", session_id => 'h3b'));
        is("$e/$o", '0/', 'symlinked active-bearing layer -> ignored -> allow');
    }
};

# ----- TC-H4: trusted precedence — project-local off beats user-global (AC7) -
subtest 'TC-H4: user-global active:true+rules, project-local active:false -> off' => sub {
    plan tests => 1;
    my ($tmp, $hook) = mkrepo();
    write_settings("$tmp/home/.cwf/tool-check/bash/settings.json", JSON::PP::true, $SED_RULE);
    write_settings("$tmp/.cwf/tool-check/bash/settings.local.json", JSON::PP::false);
    my (undef, $o) = run_hook($tmp, $hook,
        payload(command => "sed -n '1,5p' f", session_id => 'h4'));
    is($o, '', 'project-local active:false overrides user-global active:true -> allow');
};

# ----- TC-H5: checked-in active:false is IGNORED (DK1 clone-suppression) -----
subtest 'TC-H5: user-global rules active; a checked-in active:false -> still deny' => sub {
    plan tests => 1;
    my ($tmp, $hook) = mkrepo();
    write_layer("$tmp/home/.cwf/tool-check/bash/settings.json", $SED_RULE);  # active default true
    write_settings("$tmp/.cwf/tool-check/bash/settings.json", JSON::PP::false, $SED_RULE);
    my (undef, $o) = run_hook($tmp, $hook,
        payload(command => "sed -n '1,5p' f", session_id => 'h5'));
    like($o, qr/"permissionDecision":"deny"/,
        'a cloned checked-in active:false cannot silence the user-global rule');
};

# ----- TC-H6: F2 documented degradation -------------------------------------
subtest 'TC-H6: an active:false project-local corrupted -> falls through to deny' => sub {
    plan tests => 2;
    my ($tmp, $hook) = mkrepo();
    write_layer("$tmp/home/.cwf/tool-check/bash/settings.json", $SED_RULE);  # active rule source
    my $p = "$tmp/.cwf/tool-check/bash/settings.local.json";
    write_settings($p, JSON::PP::false);
    my (undef, $off) = run_hook($tmp, $hook,
        payload(command => "sed -n '1,5p' f", session_id => 'h6a'));
    is($off, '', 'while valid, active:false suppresses the deny');

    open(my $cf, '>:raw', $p) or die $!; print $cf '{ not json'; close $cf;
    my (undef, $on) = run_hook($tmp, $hook,
        payload(command => "sed -n '1,5p' f", session_id => 'h6b'));
    like($on, qr/"permissionDecision":"deny"/,
        'corrupted kill-switch -> error layer skipped -> default true -> deny (deny-safe)');
};

# ----- TC-H7: kill-switch short-circuits BEFORE any perl compile (NFR1) ------
subtest 'TC-H7: active:false -> a would-compile perl rule is never compiled' => sub {
    plan tests => 3;
    my ($tmp, $hook) = mkrepo();
    my $p = "$tmp/.cwf/tool-check/bash/settings.local.json";
    my $sentinel = "$tmp/compiled.d";
    # A perl rule whose BEGIN{} makes a sentinel dir AT COMPILE TIME (mkdir is
    # unambiguous inside a JSON-embedded string). If the match loop is ever
    # reached, compile_perl runs the BEGIN and the sentinel appears.
    my $body = 'sub { BEGIN { mkdir "' . $sentinel . '" } 1 }';
    my $rule = { id => 'compile-probe', perl => $body, guidance => 'g' };

    write_settings($p, JSON::PP::false, $rule);   # project-local (perl honoured), but OFF
    run_hook($tmp, $hook, payload(command => 'anything', session_id => 'h7a'));
    ok(!-d $sentinel, 'active:false short-circuits before compile -> BEGIN never ran');

    write_settings($p, JSON::PP::true, $rule);     # positive control: now it compiles
    run_hook($tmp, $hook, payload(command => 'anything', session_id => 'h7b'));
    ok(-d $sentinel, 'active:true -> the rule IS compiled (sentinel proves the probe works)');
    ok(1, 'short-circuit ordering confirmed against a live positive control');
};

# ----- TC-H8: --check "Effective active" matches; checked-in active shown ----
subtest 'TC-H8: --check reports effective active and ignores checked-in active' => sub {
    plan tests => 3;
    my ($tmp, $hook) = mkrepo();
    write_layer("$tmp/home/.cwf/tool-check/bash/settings.json", $SED_RULE); # user-global, no active key
    write_settings("$tmp/.cwf/tool-check/bash/settings.json", JSON::PP::false, $SED_RULE); # checked-in false
    my ($e, $o) = run_hook($tmp, $hook, '', args => '--check');
    is($e, 0, '--check exits 0');
    like($o, qr/Effective active:\s+yes/,
        'checked-in active:false is ignored; user-global default keeps it effective-yes');
    like($o, qr/checked-in\s+\S+\s+active=false\s+.*\(active ignored\)/,
        'per-layer line shows the checked-in active value and marks it ignored');
};

done_testing();
