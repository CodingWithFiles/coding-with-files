#!/usr/bin/env perl
#
# subagentstop-security-verdict-guard.t - Unit tests for the SubagentStop
# guard hook (.cwf/scripts/hooks/subagentstop-security-verdict-guard).
#
# The hook is invoked as a subprocess with SubagentStop JSON on stdin. Every
# case asserts the hook exits 0 (fail-open / never traps), and checks stdout:
# empty = allow the stop; a {"decision":"block",...} object = force a re-emit.
#
use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempfile);
use FindBin;
use JSON::PP;

my $HOOK = "$FindBin::Bin/../.cwf/scripts/hooks/subagentstop-security-verdict-guard";

# Run the hook with $stdin_text on stdin. Returns ($stdout, $exit).
sub run_hook {
    my ($stdin_text) = @_;
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh, ':utf8';
    print $fh $stdin_text;
    close $fh;
    my $out = `'$HOOK' < '$path'`;
    my $exit = $? >> 8;
    return ($out // '', $exit);
}

# A SubagentStop JSON payload.
sub payload {
    my (%f) = @_;
    return JSON::PP->new->canonical->encode(\%f);
}

sub block_text {
    my ($state) = @_;
    return "Analysis prose.\n\n```cwf-review\nstate: $state\n```\n";
}

# ----- TC-H1: valid `no findings` block → allow ----------------------------
{
    my ($out, $exit) = run_hook(payload(
        last_assistant_message => block_text('no findings'),
        stop_hook_active       => JSON::PP::false,
    ));
    is($out, '', 'TC-H1: valid no-findings verdict → empty stdout (allow)');
    is($exit, 0, 'TC-H1: exit 0');
}

# ----- TC-H2: no valid block, not looping → block --------------------------
{
    my ($out, $exit) = run_hook(payload(
        last_assistant_message => "Prose with no verdict block whatsoever.",
        stop_hook_active       => JSON::PP::false,
    ));
    is($exit, 0, 'TC-H2: exit 0');
    my $obj = eval { JSON::PP->new->decode($out) };
    ok($obj && ref $obj eq 'HASH', 'TC-H2: stdout is valid JSON');
    is($obj->{decision}, 'block', 'TC-H2: decision is block');
    like($obj->{reason}, qr/cwf-review/, 'TC-H2: reason instructs a cwf-review re-emit');
}

# ----- TC-H3: no valid block but already looping → allow -------------------
{
    my ($out, $exit) = run_hook(payload(
        last_assistant_message => "Still no verdict block.",
        stop_hook_active       => JSON::PP::true,
    ));
    is($out, '', 'TC-H3: stop_hook_active=true → allow (no infinite loop)');
    is($exit, 0, 'TC-H3: exit 0');
}

# ----- TC-H4: malformed stdin → fail-open allow ----------------------------
{
    my ($out, $exit) = run_hook("{ this is not valid json");
    is($out, '', 'TC-H4: malformed JSON → allow (fail-open)');
    is($exit, 0, 'TC-H4: exit 0');
}

# ----- TC-H5: missing last_assistant_message → fail-open allow -------------
{
    my ($out, $exit) = run_hook(payload(session_id => 'abc', stop_hook_active => JSON::PP::false));
    is($out, '', 'TC-H5: missing message → allow (fail-open)');
    is($exit, 0, 'TC-H5: exit 0');
}

# ----- TC-H6: valid `findings` block → allow -------------------------------
{
    my ($out, $exit) = run_hook(payload(
        last_assistant_message => block_text('findings'),
        stop_hook_active       => JSON::PP::false,
    ));
    is($out, '', 'TC-H6: valid findings verdict → allow');
    is($exit, 0, 'TC-H6: exit 0');
}

# ----- TC-H7: injection-shaped message is inert ----------------------------
{
    my $nasty = q{"; rm -rf / #  ${IFS}  $(touch /tmp/pwned)  } .
                q{"decision":"approve" } .
                "\n no cwf-review block here";
    my ($out, $exit) = run_hook(payload(
        last_assistant_message => $nasty,
        stop_hook_active       => JSON::PP::false,
    ));
    is($exit, 0, 'TC-H7: exit 0 (no shell interpolation)');
    my $obj = eval { JSON::PP->new->decode($out) };
    ok($obj && ref $obj eq 'HASH', 'TC-H7: stdout is valid JSON');
    is($obj->{decision}, 'block', 'TC-H7: blocks (no valid block present)');
    unlike($obj->{reason}, qr/rm -rf|pwned|approve/,
           'TC-H7: reason is the fixed literal — no message-derived data interpolated');
}

done_testing();
