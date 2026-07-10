#!/usr/bin/env perl
#
# t/validate-hooks.t - CWF::Validate::Hooks
#
# TC-1..TC-9 per implementation-guide/224-.../e-testing-plan.md.

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";

use CWF::Validate::Hooks ();

# --- fixture helpers ---------------------------------------------------------

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>:raw', $path or die "open $path: $!";
    print {$fh} $content or die "print $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}

# Build a fixture git root containing .claude/settings.json with $content.
sub fixture_root {
    my ($content) = @_;
    my $root = tempdir(CLEANUP => 1);
    make_path("$root/.claude");
    write_file("$root/.claude/settings.json", $content) if defined $content;
    return $root;
}

# A settings document whose PreToolUse hook command is $command.
sub settings_with_command {
    my ($command, %extra) = @_;
    my $allow = $extra{allow} ? qq(  "permissions": { "allow": ["$extra{allow}"] },\n) : '';
    return <<"JSON";
{
$allow  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [ { "type": "command", "command": "$command" } ]
      }
    ]
  }
}
JSON
}

my $ROOTED   = '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/pretooluse-bash-tool-check';
my $UNROOTED = '.cwf/scripts/hooks/subagentstop-security-verdict-guard';

# --- unit: the pure predicate ------------------------------------------------

# TC-1: a bare relative .cwf/ command is unrooted
ok(!CWF::Validate::Hooks::command_is_rooted(
        '.cwf/scripts/hooks/subagentstop-security-verdict-guard'),
   'TC-1: bare relative .cwf/ command is unrooted');

# TC-2: the canonical generated form is rooted
ok(CWF::Validate::Hooks::command_is_rooted(
        '${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/pretooluse-bash-tool-check'),
   'TC-2: ${CLAUDE_PROJECT_DIR}/-prefixed command is rooted');

# TC-3: the rules-inject shape carries the prefix mid-string and is rooted
ok(CWF::Validate::Hooks::command_is_rooted(
        'cat "${CLAUDE_PROJECT_DIR}/.cwf/rules-inject.txt" 2>/dev/null || true'),
   'TC-3: mid-string prefix (rules-inject) is rooted');

# TC-5: an absolute path is reported unrooted (accepted false positive)
ok(!CWF::Validate::Hooks::command_is_rooted('/home/u/repo/.cwf/scripts/hooks/x'),
   'TC-5: absolute path is unrooted (accepted false positive)');

# TC-5b: the unbraced expansion is reported unrooted (accepted false positive)
ok(!CWF::Validate::Hooks::command_is_rooted('$CLAUDE_PROJECT_DIR/.cwf/scripts/hooks/x'),
   'TC-5b: unbraced $CLAUDE_PROJECT_DIR is unrooted (accepted false positive)');

# TC-5c: .cwf without a trailing slash is not matched (accepted false negative)
ok(CWF::Validate::Hooks::command_is_rooted('cd .cwf && ./scripts/hooks/x'),
   'TC-5c: .cwf without trailing slash is not flagged (accepted false negative)');

# Totality: undef and non-scalar commands are rooted by definition.
ok(CWF::Validate::Hooks::command_is_rooted(undef), 'predicate: undef is rooted');
ok(CWF::Validate::Hooks::command_is_rooted({}),    'predicate: hashref is rooted');

# --- integration: validate($git_root) ----------------------------------------

# TC-4: permissions.allow entries are never scanned
{
    my $root = fixture_root(settings_with_command(
        $ROOTED, allow => 'Bash(.cwf/scripts/hooks/stop-stale-status-detector)'));
    my @v = CWF::Validate::Hooks::validate($root);
    is(scalar @v, 0, 'TC-4: permissions.allow bare .cwf/ patterns are not flagged');
}

# TC-4b: an unrooted command inside the hooks tree is caught
{
    my $root = fixture_root(settings_with_command($UNROOTED));
    my @v = CWF::Validate::Hooks::validate($root);
    is(scalar @v, 1, 'TC-4b: one violation for the unrooted command');
    is($v[0]{category}, 'HOOKS',                  'TC-4b: category');
    is($v[0]{field},    'hook-command',           'TC-4b: field');
    is($v[0]{file},     '.claude/settings.json',  'TC-4b: file');
    is($v[0]{actual},   $UNROOTED,                'TC-4b: actual is the command verbatim');
    like($v[0]{fix}, qr/cwf-claude-settings-merge/,
         'TC-4b: fix names the remedy helper');
}

# TC-6: malformed JSON degrades to a violation, never a die
{
    my $root = fixture_root('{ not json');
    my @v = eval { CWF::Validate::Hooks::validate($root) };
    is($@, '', 'TC-6: no exception on malformed JSON');
    is(scalar @v, 1, 'TC-6: one violation');
    is($v[0]{field}, 'json-parse', 'TC-6: field is json-parse');
}

# TC-6b: a present-but-unreadable settings file degrades to a violation
SKIP: {
    skip 'root effective uid bypasses -r', 3 if $> == 0;
    my $root = fixture_root(settings_with_command($ROOTED));
    my $path = "$root/.claude/settings.json";
    chmod 0000, $path or die "chmod: $!";
    my @v = eval { CWF::Validate::Hooks::validate($root) };
    is($@, '', 'TC-6b: no exception on unreadable settings');
    is(scalar @v, 1, 'TC-6b: one violation');
    is($v[0]{field}, 'json-parse', 'TC-6b: field is json-parse');
    chmod 0600, $path;  # restore so CLEANUP can unlink
}

# TC-6c: a symlinked settings file is refused, not followed
SKIP: {
    my $root = fixture_root(undef);
    my $real = write_file("$root/real-settings.json", settings_with_command($ROOTED));
    skip 'symlink unsupported', 3
        unless eval { symlink($real, "$root/.claude/settings.json") };
    my @v = eval { CWF::Validate::Hooks::validate($root) };
    is($@, '', 'TC-6c: no exception on symlinked settings');
    is(scalar @v, 1, 'TC-6c: one violation');
    is($v[0]{field}, 'json-parse', 'TC-6c: symlink refused, not followed');
}

# TC-7: a canonical fixture with no settings.local.json validates clean
{
    my $root = fixture_root(settings_with_command($ROOTED));
    ok(!-e "$root/.claude/settings.local.json", 'TC-7: no local settings present');
    my @v = CWF::Validate::Hooks::validate($root);
    is(scalar @v, 0, 'TC-7: absence gate skips the missing optional file');
}

# TC-7b: a malformed hooks tree is skipped, not fatal
{
    my @malformed = (
        [ 'hooks is an array'       => '{ "hooks": [] }' ],
        [ 'event maps to a scalar'  => '{ "hooks": { "PreToolUse": "nope" } }' ],
        [ 'group lacks hooks'       => '{ "hooks": { "PreToolUse": [ { "matcher": "Bash" } ] } }' ],
        [ 'command is a hashref'    => '{ "hooks": { "PreToolUse": [ { "hooks": [ { "command": {} } ] } ] } }' ],
        [ 'hooks is a scalar'       => '{ "hooks": "nope" }' ],
        [ 'group is a scalar'       => '{ "hooks": { "PreToolUse": [ "nope" ] } }' ],
        [ 'group hooks is a scalar' => '{ "hooks": { "PreToolUse": [ { "hooks": "nope" } ] } }' ],
    );
    for my $case (@malformed) {
        my ($label, $json) = @$case;
        my $root = fixture_root($json);
        my @v = eval { CWF::Validate::Hooks::validate($root) };
        is($@, '', "TC-7b: no exception ($label)");
        is(scalar @v, 0, "TC-7b: no violations ($label)");
    }
}

# Absent .claude/ entirely: clean, no die.
{
    my $root = tempdir(CLEANUP => 1);
    my @v = eval { CWF::Validate::Hooks::validate($root) };
    is($@, '', 'absent .claude/: no exception');
    is(scalar @v, 0, 'absent .claude/: no violations');
}

# settings.local.json is scanned too.
{
    my $root = fixture_root(settings_with_command($ROOTED));
    write_file("$root/.claude/settings.local.json", settings_with_command($UNROOTED));
    my @v = CWF::Validate::Hooks::validate($root);
    is(scalar @v, 1, 'settings.local.json is scanned');
    is($v[0]{file}, '.claude/settings.local.json', 'violation names the local file');
}

# --- source assertions -------------------------------------------------------

my $REPO = "$FindBin::Bin/..";

# TC-8: the doc teaches only the rooted form.
{
    my $doc = "$REPO/.cwf/docs/workflow/stop-hooks-framework.md";
    open my $fh, '<:encoding(UTF-8)', $doc or die "open $doc: $!";
    my @bad = grep { /"command"\s*:\s*"\.cwf\// } <$fh>;
    close $fh;
    is(scalar @bad, 0,
       'TC-8: stop-hooks-framework.md registers no bare-relative .cwf/ command')
        or diag("offending line(s): @bad");
}

# TC-9: the generator still emits the canonical literal.
{
    my $gen = "$REPO/.cwf/scripts/command-helpers/cwf-claude-settings-merge";
    open my $fh, '<:encoding(UTF-8)', $gen or die "open $gen: $!";
    my $src = do { local $/; <$fh> };
    close $fh;
    like($src, qr/\$\{CLAUDE_PROJECT_DIR\}\//,
         'TC-9: cwf-claude-settings-merge still emits ${CLAUDE_PROJECT_DIR}/');
}

done_testing();
