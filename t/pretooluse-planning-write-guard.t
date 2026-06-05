#!/usr/bin/env perl
#
# pretooluse-planning-write-guard.t — I/O behaviour of the R1 fail-closed
# PreToolUse guard hook (Task 180).
#
# The hook is impure (reads stdin, shells out via TCI + git, reads the knob,
# emits a Claude Code decision), so each test builds a hermetic git repo under a
# tempdir: a crafted implementation-guide/cwf-project.json (the knob the hook
# reads, root-anchored), the hook installed as a COPY under the tempdir's
# .cwf/scripts/hooks/ (its FindBin-anchored observe log then lands in the
# tempdir), and the real .cwf/lib on PERL5LIB. The hook runs with cwd at a repo
# SUBDIR (implementation-guide/) so cwd ≠ hook-dir ≠ nothing-relative — proving
# the log is FindBin-anchored, not cwd-relative.
#
# The pure policy matrix (classify_path / decide) is covered exhaustively in
# planning-guard.t; here we bind the wiring: tool gate, target:unresolved,
# deny envelope shape, observe-vs-enforce, knob off/absent/invalid, no leak.
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use JSON::PP;

my $REPO = File::Spec->rel2abs("$FindBin::Bin/..");
my $SRC  = "$REPO/.cwf/scripts/hooks/pretooluse-planning-write-guard";

plan skip_all => 'git not available' if system('git --version >/dev/null 2>&1') != 0;

# Build a hermetic git repo. %o: knob => off|observe|enforce|'bogus' (string) or
# undef (knob absent), no_config => 1 (omit cwf-project.json entirely).
# Returns ($tmp, $hook).
sub mkrepo {
    my (%o) = @_;
    my $tmp = tempdir(CLEANUP => 1);
    system("git -C '$tmp' init -q") == 0 or die "git init failed";

    make_path("$tmp/.cwf/scripts/hooks");
    make_path("$tmp/.claude/skills");
    make_path("$tmp/implementation-guide");

    # Install a runnable copy of the hook.
    open(my $in, '<:raw', $SRC) or die "open $SRC: $!";
    my $body = do { local $/; <$in> }; close $in;
    my $hook = "$tmp/.cwf/scripts/hooks/pretooluse-planning-write-guard";
    open(my $out, '>:raw', $hook) or die "write $hook: $!";
    print $out $body; close $out;
    chmod 0700, $hook;

    unless ($o{no_config}) {
        my %sandbox = (enabled => JSON::PP::true);
        $sandbox{'planning-write-guard'} = $o{knob} if exists $o{knob} && defined $o{knob};
        my %cfg = (
            'supported-task-types' => [qw(feature bugfix hotfix chore discovery)],
            'source-management'    => { 'branch-naming-convention' => 'x' },
            sandbox                => \%sandbox,
        );
        open(my $cf, '>:raw', "$tmp/implementation-guide/cwf-project.json") or die $!;
        print $cf JSON::PP->new->pretty->canonical->encode(\%cfg); close $cf;
    }
    return ($tmp, $hook);
}

# Run the hook with cwd at the repo subdir implementation-guide/. Returns
# ($exit, $stdout, $stderr).
sub run_guard {
    my ($tmp, $hook, $stdin) = @_;
    my $cwd = "$tmp/implementation-guide";
    my $i = "$tmp/.in"; my $so = "$tmp/.out"; my $se = "$tmp/.err";
    open(my $fh, '>:raw', $i) or die $!; print $fh $stdin; close $fh;
    local $ENV{PERL5LIB} =
        "$REPO/.cwf/lib" . (defined $ENV{PERL5LIB} ? ":$ENV{PERL5LIB}" : '');
    my $rc = system("cd '$cwd' && '$hook' <'$i' >'$so' 2>'$se'");
    my $out = do { open(my $o,'<:raw',$so) or die $!; local $/; <$o> } // '';
    my $err = do { open(my $e,'<:raw',$se) or die $!; local $/; <$e> } // '';
    return ($rc >> 8, $out, $err);
}

sub payload {
    my ($tool, $file_path) = @_;
    my %ti;
    $ti{file_path} = $file_path if defined $file_path;
    return JSON::PP->new->encode({
        hook_event_name => 'PreToolUse',
        tool_name       => $tool,
        tool_input      => \%ti,
    });
}

sub read_log {
    my ($tmp) = @_;
    my $p = "$tmp/.cwf/sandbox-violations.log";
    return undef unless -e $p;
    open(my $fh, '<:raw', $p) or die $!; local $/; my $b = <$fh>; close $fh;
    return $b;
}

# ----- TC-10(hook): tool-name gate first ------------------------------------
subtest 'tool-name gate: non-Edit/Write → allow (exit 0, no decision)' => sub {
    plan tests => 4;
    my ($tmp, $hook) = mkrepo(knob => 'enforce');
    for my $tool (qw(Read Bash)) {
        my ($exit, $out) = run_guard($tmp, $hook, payload($tool, "$tmp/.cwf/x"));
        is($exit, 0, "$tool → exit 0");
        is($out, '', "$tool → empty stdout (no decision), even at enforce + crown path");
    }
};

# ----- target:unresolved ----------------------------------------------------
subtest 'missing file_path / malformed stdin under enforce → deny target:unresolved' => sub {
    plan tests => 4;
    my ($tmp, $hook) = mkrepo(knob => 'enforce');

    my ($e1, $o1) = run_guard($tmp, $hook, payload('Edit', undef));   # no file_path
    is($e1, 0, 'exit 0 (decision emitted via JSON, not exit code)');
    my $d1 = eval { JSON::PP->new->decode($o1) };
    like(($d1->{hookSpecificOutput}{permissionDecisionReason} // ''), qr/\Qtarget:unresolved\E/,
         'missing file_path → target:unresolved deny');

    my ($e2, $o2) = run_guard($tmp, $hook, '{ not json');           # malformed
    my $d2 = eval { JSON::PP->new->decode($o2) };
    is($d2->{hookSpecificOutput}{permissionDecision} // '', 'deny', 'malformed stdin → deny');
    like(($d2->{hookSpecificOutput}{permissionDecisionReason} // ''), qr/\Qtarget:unresolved\E/,
         'malformed stdin → target:unresolved');
};

# ----- TC-9: enforce deny on a crown-jewel Edit, real envelope, no path echo -
subtest 'enforce + crown-jewel Edit → deny JSON (verified envelope, no path echo)' => sub {
    plan tests => 6;
    my ($tmp, $hook) = mkrepo(knob => 'enforce');
    my $target = "$tmp/.cwf/scripts/cwf-claude-settings-merge";
    my ($exit, $out, $err) = run_guard($tmp, $hook, payload('Edit', $target));
    is($exit, 0, 'exit 0');
    my $d = eval { JSON::PP->new->decode($out) };
    ok($d, 'stdout is valid JSON (no STDERR leak corrupting it)') or diag $out;
    is($d->{hookSpecificOutput}{hookEventName}, 'PreToolUse', 'hookEventName PreToolUse');
    is($d->{hookSpecificOutput}{permissionDecision}, 'deny', 'permissionDecision deny');
    like($d->{hookSpecificOutput}{permissionDecisionReason},
         qr/\Qcrown-jewel:.cwf|.claude\E/, 'reason carries the fixed crown token');
    unlike($out, qr/\Qcwf-claude-settings-merge\E/, 'target path NOT echoed into output');
};

# ----- non-crown write short-circuits to allow (no TCI, no knob action) ------
subtest 'enforce + non-crown task file → allow (crown-jewel-first short-circuit)' => sub {
    plan tests => 2;
    my ($tmp, $hook) = mkrepo(knob => 'enforce');
    make_path("$tmp/implementation-guide/180-feature-x");
    my $target = "$tmp/implementation-guide/180-feature-x/a-task-plan.md";
    my ($exit, $out) = run_guard($tmp, $hook, payload('Write', $target));
    is($exit, 0, 'exit 0');
    is($out, '', 'non-crown write permitted — never bricks task-own files');
};

# ----- TC-11: observe mode logs (FindBin-anchored) + permits -----------------
subtest 'observe + crown → logs fixed-key record (no raw path) + permits' => sub {
    plan tests => 6;
    my ($tmp, $hook) = mkrepo(knob => 'observe');
    my $target = "$tmp/.claude/skills/secret-skill";
    my ($exit, $out) = run_guard($tmp, $hook, payload('Edit', $target));
    is($exit, 0, 'exit 0');
    is($out, '', 'observe permits (empty stdout — no deny decision)');
    my $log = read_log($tmp);
    ok(defined $log && length $log, 'a record was written to the FindBin-anchored log');
    my @lines = grep { length } split /\n/, ($log // '');
    is(scalar @lines, 1, 'exactly one JSON record');
    my $rec = eval { JSON::PP->new->decode($lines[0]) };
    is(($rec->{event} // ''), 'planning-guard-observe', 'record event tag present');
    unlike($log, qr/\Qsecret-skill\E/, 'raw target path never recorded');
};

# ----- observe log-write failure is swallowed (still permits) ---------------
subtest 'observe + unwritable log → swallowed, still permits' => sub {
    plan tests => 2;
    my ($tmp, $hook) = mkrepo(knob => 'observe');
    make_path("$tmp/.cwf/sandbox-violations.log");   # pre-create as a DIR → append fails
    my ($exit, $out) = run_guard($tmp, $hook, payload('Edit', "$tmp/.cwf/x"));
    is($exit, 0, 'exit 0 despite unwritable log');
    is($out, '', 'still permits');
};

# ----- TC-12: knob off / absent → allow; invalid → enforce (fail-closed) -----
subtest 'knob off/absent → allow passthrough; invalid → enforce' => sub {
    plan tests => 5;
    # off
    my ($t1, $h1) = mkrepo(knob => 'off');
    my ($e1, $o1) = run_guard($t1, $h1, payload('Edit', "$t1/.cwf/x"));
    is($o1, '', 'knob off → allow even for a crown-jewel Edit');

    # knob absent (sandbox block present, no planning-write-guard key)
    my ($t2, $h2) = mkrepo();           # knob not set
    my ($e2, $o2) = run_guard($t2, $h2, payload('Edit', "$t2/.cwf/x"));
    is($o2, '', 'knob absent → allow (defaults off)');

    # config file absent entirely → allow (back-compat)
    my ($t3, $h3) = mkrepo(no_config => 1);
    my ($e3, $o3) = run_guard($t3, $h3, payload('Edit', "$t3/.cwf/x"));
    is($o3, '', 'config absent → allow (feature off)');

    # invalid knob value → enforce (fail-closed)
    my ($t4, $h4) = mkrepo(knob => 'bogus');
    my ($e4, $o4) = run_guard($t4, $h4, payload('Edit', "$t4/.cwf/x"));
    my $d4 = eval { JSON::PP->new->decode($o4) };
    is(($d4->{hookSpecificOutput}{permissionDecision} // ''), 'deny',
       'invalid knob value → enforce → deny');
    like(($d4->{hookSpecificOutput}{permissionDecisionReason} // ''),
         qr/\Qcrown-jewel\E/, 'fail-closed deny carries the crown token');
};

# ----- TC-13: TCI/git STDERR contained — never on the decision stream --------
subtest 'no STDERR leak into the decision (stdout is clean JSON)' => sub {
    plan tests => 2;
    my ($tmp, $hook) = mkrepo(knob => 'enforce');
    my ($exit, $out, $err) = run_guard($tmp, $hook, payload('Edit', "$tmp/.cwf/x"));
    my $d = eval { JSON::PP->new->decode($out) };
    ok($d && $d->{hookSpecificOutput}, 'stdout decodes to exactly the decision envelope');
    unlike($out, qr/TaskContextInference|fatal:|warning:/i,
           'no TCI warning / git stderr text on stdout');
};

done_testing();
