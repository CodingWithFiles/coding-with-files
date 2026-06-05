package CWF::PlanningGuard;
#
# CWF::PlanningGuard - Pure decision logic for the phase-scoped planning-write
# guard (Task 180, R1).
#
# This module holds the security-load-bearing policy as TWO pure functions so
# the matrix is unit-testable without git or task-context-inference:
#
#   classify_path($target, \@roots) -> 1 (crown jewel) | 0 (not)
#   decide($tool, $is_crown, $confidence, $workflow_step) -> ($action, $token)
#
# The thin runtime wrapper (.cwf/scripts/hooks/pretooluse-planning-write-guard)
# does the impure work — read stdin, derive roots, shell out via TCI, read the
# knob, emit the Claude Code decision — and delegates every judgement here.
#
# POSIX-only project: paths use `/` and the canonicaliser hardcodes it.
#
use strict;
use warnings;
use utf8;
use Exporter 'import';
use Cwd ();
use File::Spec ();

our @EXPORT_OK = qw(classify_path decide is_exec_phase PLANNING_GUARD_VALUES);

# The planning-write-guard knob enum — SINGLE SOURCE OF TRUTH. Consumed by the
# config validator (CWF::Validate::Config::_validate_sandbox_block), the merge
# helper's validator + registration gate (cwf-claude-settings-merge), and the
# runtime hook. Listed in escalation order (off < observe < enforce); callers
# use membership only.
use constant PLANNING_GUARD_VALUES => ('off', 'observe', 'enforce');

# Crown-jewel top-level directories, relative to a repo root: CWF's own
# machinery (.cwf/) and the Claude Code config that drives it (.claude/). A
# write whose canonical target lands inside any root's .cwf/ or .claude/ is a
# crown-jewel write.
my @CROWN_DIRS = ('.cwf', '.claude');

# Workflow-step suffixes (letter prefix stripped) where production writes to
# crown jewels are expected. Deliberately CONSERVATIVE — implementation-exec
# only. Every other phase (including testing-exec) denies crown-jewel writes;
# the operator drops the knob to observe/off when that is too tight. Fail-closed
# beats a silent leak.
my %EXEC_PHASES = map { $_ => 1 } qw(implementation-exec);

# Closed set of recognised phase-name suffixes. Used ONLY to keep the deny
# token a fixed enumeration: an unrecognised suffix collapses to phase:unknown,
# so no free-form (let alone attacker-influenced) string is interpolated into
# the reason shown to the agent.
my %KNOWN_PHASES = map { $_ => 1 } qw(
    task-plan requirements-plan design-plan implementation-plan testing-plan
    implementation-exec testing-exec rollout maintenance retrospective
);

# Fixed deny marker. No path, slug, or command is ever interpolated into a
# surfaced reason (FR4(c)/(e)) — the `.cwf|.claude` here is a literal naming the
# two crown roots, not a value derived from the target.
my $DENY_CROWN = 'crown-jewel:.cwf|.claude';

# classify_path($target, \@roots) -> 1 if $target canonicalises to a path inside
# any root's crown dir, else 0. Canonical, not string-prefix: `..` is collapsed
# and symlinks on the existing prefix are resolved, so traversal- and symlink-
# based reaches into a crown jewel are caught. Conservative: a target that
# cannot be resolved at all returns 1 (treat-as-crown) rather than risk a leak.
sub classify_path {
    my ($target, $roots) = @_;
    my $abs = _canonical_abs($target);
    return 1 unless defined $abs;           # unresolvable → conservative crown jewel

    for my $root (@{ $roots || [] }) {
        next unless defined $root && length $root;
        my $rabs = Cwd::abs_path($root);
        $rabs = _canonical_abs($root) unless defined $rabs;
        next unless defined $rabs;
        for my $crown (@CROWN_DIRS) {
            my $prefix = "$rabs/$crown";
            return 1 if $abs eq $prefix || index($abs, "$prefix/") == 0;
        }
    }
    return 0;
}

# decide($tool, $is_crown, $confidence, $workflow_step) -> ($action, $token).
# $action is 'allow' or 'deny'; $token is '' for allow, a fixed enumerated
# reason for deny. Caller passes a scalar $workflow_step ONLY when $confidence
# is 'correlated' (TCI exposes a singular workflow_step in that case alone).
sub decide {
    my ($tool, $is_crown, $confidence, $workflow_step) = @_;

    # Tool-name gate first (also enforced by the hook, for matcher-less
    # degradation): only Edit/Write are in scope.
    return ('allow', '') unless _is_write_tool($tool);

    # Non-crown writes are always permitted — this is what guarantees the guard
    # never bricks task-own / BACKLOG / scratch writes.
    return ('allow', '') unless $is_crown;

    # Crown-jewel write: permit ONLY when positively resolved to a recognised
    # exec phase. The confidence check MUST precede is_exec_phase (fail-closed):
    # any non-correlated result (uncorrelated / no_signals / error / unknown)
    # denies, regardless of whatever workflow_step value was passed in.
    return ('allow', '')
        if defined $confidence
        && $confidence eq 'correlated'
        && is_exec_phase($workflow_step);

    return ('deny', "$DENY_CROWN " . _phase_token($workflow_step));
}

# is_exec_phase($workflow_step) -> 1 if the letter-stripped suffix is in the
# (conservative) exec set. Accepts both letter-prefixed (`f-implementation-exec`)
# and bare (`implementation-exec`) forms.
sub is_exec_phase {
    my ($step) = @_;
    return exists $EXEC_PHASES{ _strip_phase($step) } ? 1 : 0;
}

# --- internals -------------------------------------------------------------

sub _is_write_tool {
    my ($tool) = @_;
    return (defined $tool && ($tool eq 'Edit' || $tool eq 'Write')) ? 1 : 0;
}

# Strip a leading workflow-phase letter prefix (a-j) so name-matching is stable
# across the v2.0/v2.1 letter reassignments.
sub _strip_phase {
    my ($step) = @_;
    return '' unless defined $step;
    (my $s = $step) =~ s/^[a-j]-//;
    return $s;
}

sub _phase_token {
    my ($step) = @_;
    my $s = _strip_phase($step);
    return exists $KNOWN_PHASES{$s} ? "phase:$s" : 'phase:unknown';
}

# Resolve $path to a canonical absolute POSIX path: symlinks resolved on the
# longest existing prefix, `.`/`..` collapsed, the trailing (not-yet-existing)
# components re-appended. Returns undef only if nothing in the chain — not even
# the filesystem root — resolves (pathological; the caller treats undef as a
# crown jewel).
sub _canonical_abs {
    my ($path) = @_;
    return undef unless defined $path && length $path;
    my $abs = File::Spec->rel2abs($path);    # cwd-relative → absolute (lexical)

    my @trailing;
    my $cur = $abs;
    while (1) {
        my $real = Cwd::abs_path($cur);
        return _collapse($real, @trailing) if defined $real;

        my (undef, $dirs, $file) = File::Spec->splitpath($cur);
        unshift @trailing, $file if defined $file && length $file;

        my $parent = $dirs;
        $parent =~ s{/+$}{};
        $parent = '/' if $parent eq '' && $abs =~ m{^/};
        last if $parent eq $cur || !length $parent;   # no progress / fell off root
        $cur = $parent;
    }
    return undef;
}

# Join an already-resolved absolute prefix with trailing components, collapsing
# any residual `.`/`..`. POSIX-absolute result.
sub _collapse {
    my ($real, @trailing) = @_;
    my @parts = (File::Spec->splitdir($real), @trailing);
    my @out;
    for my $p (@parts) {
        next if !defined $p || $p eq '' || $p eq '.';
        if ($p eq '..') { pop @out if @out; next; }
        push @out, $p;
    }
    return '/' . join('/', @out);
}

1;
