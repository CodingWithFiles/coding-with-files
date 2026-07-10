package CWF::Validate::Hooks;
#
# CWF::Validate::Hooks - Flag a CWF hook command that is not rooted at
# ${CLAUDE_PROJECT_DIR}.
#
# Claude Code runs a hook command with the cwd of the *invoking* process, not
# the project root. A registration like
#     "command": ".cwf/scripts/hooks/pretooluse-bash-tool-check"
# therefore resolves only when the agent happens to be sitting in the repo root.
# From any subdirectory the file is not found, the hook does not run, and
# Claude Code reports nothing: hooks fail OPEN. A guard that silently stops
# guarding is worse than no guard, so the rooted form is mandatory:
#     "command": "${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/..."
#
# cwf-claude-settings-merge already emits the rooted form, but a hand-edited
# .claude/settings.json can reintroduce the bare-relative one with no signal.
# This validator is that signal.
#
# The invariant is "no bare `.cwf/` reference in a hook command", NOT "the
# command starts with the prefix" — the shipped rules-inject hook carries the
# prefix mid-string:
#     cat "${CLAUDE_PROJECT_DIR}/.cwf/rules-inject.txt" 2>/dev/null || true
#
# Scan target: the `hooks` tree of .claude/settings.json and (if present)
# .claude/settings.local.json. `permissions.allow` is deliberately NOT scanned:
# its entries such as Bash(.cwf/scripts/hooks/...) are match patterns, not exec
# paths, and both real settings files carry them.
#
# This validator surfaces; it never repairs. It is not wired into fix-security.
#
# A settings file that is present but unreadable, symlinked, non-regular, or
# undecodable yields ONE 'json-parse' violation and never dies — a die here
# would abort the sibling validators composed alongside it in cwf-manage.
#
# Returns a list of violation hashrefs, each with keys:
#   category, file, field, actual, expected, fix
#
# Usage:
#   use CWF::Validate::Hooks qw(validate);
#   my @violations = validate($git_root);
#

use strict;
use warnings;
use utf8;
use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(validate);

my @SETTINGS_FILES = ('.claude/settings.json', '.claude/settings.local.json');

my $ROOTED_PREFIX = '${CLAUDE_PROJECT_DIR}/';

# A .cwf/ path handed to the harness must be rooted at the project dir.
# Fixed-width lookbehind: '${CLAUDE_PROJECT_DIR}/' is 22 chars.
#
# Accepted imprecision (each pinned by a test in t/validate-hooks.t): an
# absolute path and the unbraced $CLAUDE_PROJECT_DIR/ form are both reported
# unrooted (neither survives a clone); a `.cwf` reference without a trailing
# slash is not matched.
sub command_is_rooted {
    my ($command) = @_;
    return 1 unless defined $command && !ref $command;
    return $command !~ m{(?<!\$\{CLAUDE_PROJECT_DIR\}/)\.cwf/};
}

# Read + decode one settings file. Called ONLY for a path that already exists,
# so $ok == 0 unambiguously means "present but unusable". Mirrors read_layer_file
# in pretooluse-bash-tool-check: degrade a bad file to nothing, never die.
sub _read_settings {
    my ($abs) = @_;
    return (undef, 0) unless -f $abs && !-l $abs;
    open my $fh, '<:raw', $abs or return (undef, 0);
    my $blob = do { local $/; <$fh> };
    close $fh;
    my $decoded = eval { JSON::PP->new->decode($blob) };
    return (undef, 0) unless ref $decoded eq 'HASH';
    return ($decoded, 1);
}

sub validate {
    my ($git_root) = @_;
    my @violations;

    for my $rel (@SETTINGS_FILES) {
        my $abs = "$git_root/$rel";
        next unless -e $abs;   # absence gate: settings.local.json is optional

        my ($settings, $ok) = _read_settings($abs);
        if (!$ok) {
            push @violations, _parse_violation($rel);
            next;
        }
        push @violations, _scan_hooks($settings->{hooks}, $rel);
    }
    return @violations;
}

# Walk hooks -> event -> group -> hooks[] -> command, type-checking every level
# before descent. A malformed tree is skipped, never fatal.
sub _scan_hooks {
    my ($hooks, $rel) = @_;
    my @violations;
    return @violations unless ref $hooks eq 'HASH';

    for my $event (sort keys %$hooks) {
        my $groups = $hooks->{$event};
        next unless ref $groups eq 'ARRAY';

        for my $group (@$groups) {
            next unless ref $group eq 'HASH';
            my $entries = $group->{hooks};
            next unless ref $entries eq 'ARRAY';

            for my $entry (@$entries) {
                next unless ref $entry eq 'HASH';
                my $command = $entry->{command};
                next if command_is_rooted($command);
                push @violations, _command_violation($rel, $command);
            }
        }
    }
    return @violations;
}

sub _command_violation {
    my ($rel, $command) = @_;
    return { category => 'HOOKS', file => $rel,
             field => 'hook-command', actual => $command,
             expected => "a command whose .cwf/ paths are prefixed with $ROOTED_PREFIX",
             fix => 'Re-run .cwf/scripts/command-helpers/cwf-claude-settings-merge '
                  . 'to regenerate the hook registrations.' };
}

sub _parse_violation {
    my ($rel) = @_;
    return { category => 'HOOKS', file => $rel,
             field => 'json-parse', actual => 'unreadable or malformed JSON',
             expected => 'a readable, regular file containing a JSON object',
             fix => "Repair $rel (it must be a regular file, not a symlink, "
                  . 'containing a valid JSON object).' };
}

1;
