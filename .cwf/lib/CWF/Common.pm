package CWF::Common;
#
# CWF::Common - Common utilities for CWF command helpers
#
# Provides shared functionality like PERL5OPT configuration checking
# and error formatting that was previously duplicated across modules.
#

use strict;
use warnings;
use utf8;
use Exporter 'import';
use POSIX ();

our @EXPORT_OK = qw(check_perl5opt format_error parse_semver version_cmp find_git_root resolve_head_sha generate_slug run_quiet scratch_parent scratch_dir scratch_fail_hint);

# The canonical scratch base: the per-uid writable session temp. Derived purely
# from the effective UID so the SAME path is produced in every process context —
# the unsandboxed context-inject hook, the sandboxed Bash tool, and an off-sandbox
# fallback — which is what makes path-based permissions hold regardless of sandbox
# mode (Task 229). $TMPDIR is deliberately NOT read: it varies by context and can
# already contain a cwf-<slug> segment, which caused path doubling and hook/writer
# divergence (Task 229 bug report). Overridable so tests can point at a tempdir
# instead of the real shared /tmp/claude-<uid>. The initialiser MUST run once at
# load — declaring it inside the sub would re-run every call and clobber a test's
# `local` override. Linux/WSL2 only: on a macOS Seatbelt sandbox the writable temp
# is under /var/folders, so this fails closed (documented known limitation; see
# .cwf/docs/conventions/tmp-paths.md and the BACKLOG platform-specific-base item).
our $SCRATCH_BASE = "/tmp/claude-$>";   # $> = effective UID

# Check PERL5OPT environment configuration
# Args: none
# Returns: none (warns if not configured)
sub check_perl5opt {
    unless ($ENV{PERL5OPT} && $ENV{PERL5OPT} =~ /-C/) {
        warn "WARNING: PERL5OPT lacks the -C flags needed for Unicode handling.\n";
        warn "CWF installs env.PERL5OPT=-CDSLA into this project's .claude/settings.json;\n";
        warn "run 'cwf-manage update' if it is missing, then restart Claude Code so the\n";
        warn "session picks it up. A script run outside a Claude Code tool call won't\n";
        warn "inherit that setting — export PERL5OPT=-CDSLA in your shell for those cases.\n\n";
    }
}

# Format error message consistently
# Args: $type (error type), $message (error message), $usage (optional usage string)
# Returns: formatted error string
sub format_error {
    my ($type, $message, $usage) = @_;
    my $output = "Error: $message\n";
    $output .= "\nUsage: $usage\n" if $usage;
    return $output;
}

# Parse a semver tag of the form vX.Y.Z
# Args: $tag (string, e.g. "v1.0.113")
# Returns: list (major, minor, patch) as numeric scalars; empty list on parse failure
sub parse_semver {
    my ($tag) = @_;
    return () unless defined $tag;
    my @p = ($tag =~ /^v(\d+)\.(\d+)\.(\d+)$/);
    return @p ? ($p[0]+0, $p[1]+0, $p[2]+0) : ();
}

# Resolve the MAIN git repository root (Task 173, worktree-safe).
#
# `git rev-parse --show-toplevel` returns the *worktree* root when run inside a
# linked worktree, so anchoring canonical CWF state (task dirs, config, backlog)
# to it risks operating in a disposable tree (data-loss vector, Task 172).
# Instead derive the main tree from the common git dir: `--git-common-dir`
# resolves to the MAIN repo's `.git` even from a linked worktree, so its parent
# is the main worktree root. Fall back to `--show-toplevel` when the common dir
# is not a `.../.git` directory (e.g. submodule gitdirs under `.git/modules/`).
#
# The git invocation is argument-free, so the backtick form carries no
# interpolation surface; the single-value output needs only chomp (no NUL/list
# parsing). `--path-format=absolute` must precede `--git-common-dir` and
# guarantees an absolute path, so stripping the literal `/.git` suffix is a
# well-defined parent derivation (no need for File::Spec canonicalisation).
#
# Returns: absolute path string, or undef if not inside a git repo.
sub find_git_root {
    my $common = `git rev-parse --path-format=absolute --git-common-dir 2>/dev/null`;
    chomp $common;
    $common =~ s{/+$}{};                      # normalise trailing slash before matching
    if (length $common && $common =~ s{/\.git$}{}) {
        return $common if length $common;     # parent of the common .git dir == main root
    }
    my $root = `git rev-parse --show-toplevel 2>/dev/null`;
    chomp $root;
    return length $root ? $root : undef;
}

# Derive the canonical per-project scratch PARENT directory (Task 206, 215, 229).
#
# Pure string derivation with NO filesystem work — the context-inject hook calls
# it every turn. The base is $SCRATCH_BASE (the EUID-derived per-uid session temp);
# $TMPDIR is NOT consulted, so the parent is identical across every process context
# (unsandboxed hook, sandboxed Bash tool, off-sandbox fallback). This eliminates
# both the path-doubling and the hook/writer path divergence of Task 229, and it
# removes the $TMPDIR-injection surface entirely. Mirrors the dashified-root form
# in .cwf/docs/conventions/tmp-paths.md.
#
# Optional $root lets a caller that has already resolved the main root (e.g. the
# hook, which needs it for the project_root line too) pass it in, so the whole
# turn costs a single `git rev-parse` (NFR1). Omit it and the root is resolved
# here.
#
# Returns: ($parent, undef) on success, or (undef, 'not_a_repo') outside a repo.
sub scratch_parent {
    my ($root) = @_;
    $root = find_git_root() unless defined $root && length $root;
    return (undef, 'not_a_repo') unless defined $root && length $root;
    (my $dashed = $root) =~ s{/}{-}g;   # absolute path => canonical leading-dash form
    return ("$SCRATCH_BASE/cwf${dashed}", undef);   # $TMPDIR not read (mode-invariant)
}

# Derive AND create the per-task scratch directory (Task 206, 229), with the
# tmp-paths symlink-attack defences. Used by writers (e.g.
# security-review-changeset); the hook uses scratch_parent() (no filesystem).
#
# Validates $num against the anchored task-number pattern BEFORE any filesystem
# work (rejects `..`, empty/`.` components, `/`, shell metacharacters; leading
# zeros accepted). Then runs the mkdir-then-lstat-recheck triad TWICE — once for
# the intermediate $SCRATCH_BASE, then for the cwf<dashed> parent — in that order
# (Task 229). The base triad MUST complete before the parent mkdir: since
# $SCRATCH_BASE now names a new intermediate level under world-writable /tmp, a
# symlinked base must be rejected before any mkdir descends through it. Then mkdir
# the leaf at 0700. Deliberately NO chmod-clamp — never auto-chmod a foreign or
# wrong-mode dir (surface, never smooth; design D2).
#
# Returns: ($path, undef) on success, or (undef, $kind) where
# $kind ∈ {not_a_repo, bad_num, symlink_parent, mkdir_failed}.
sub scratch_dir {
    my ($num) = @_;
    return (undef, 'bad_num') unless defined $num && $num =~ /^[0-9]+(\.[0-9]+)*$/;
    my ($parent, $err) = scratch_parent();
    return (undef, $err) unless defined $parent;
    for my $dir ($SCRATCH_BASE, $parent) {              # base BEFORE parent (ordering matters)
        mkdir($dir, 0700) unless -d $dir;
        return (undef, 'symlink_parent') if -l $dir;    # lstat: reject a symlinked level
        return (undef, 'mkdir_failed')   unless -d $dir; # level could not be created
    }
    my $scratch = "$parent/task-$num";
    unless (-d $scratch) {
        mkdir($scratch, 0700) or return (undef, 'mkdir_failed');
    }
    return ($scratch, undef);
}

# A cause-naming diagnostic sentence for the fail-closed $kind values that stem
# from an unusable scratch BASE (Task 229) — so every scratch_dir caller can emit
# the same actionable hint instead of a bare kind token. Returns '' for kinds that
# are not base-related (bad_num, not_a_repo) and for anything unrecognised, so a
# caller can append it unconditionally and get a clean line when there is no hint.
sub scratch_fail_hint {
    my ($kind) = @_;
    return '' unless defined $kind;
    if ($kind eq 'mkdir_failed') {
        return "the scratch base $SCRATCH_BASE is not writable — expected on a "
             . "non-Linux (e.g. macOS Seatbelt) sandbox, where the writable temp "
             . "is elsewhere; see .cwf/docs/conventions/tmp-paths.md";
    }
    if ($kind eq 'symlink_parent') {
        return "a symlink was found at the scratch base $SCRATCH_BASE or its "
             . "cwf<root> parent — refusing to write through it (surface, never smooth)";
    }
    return '';
}

# Resolve the SHA of HEAD in the current git repository.
# Returns: 40-char lowercase hex string, or undef if HEAD cannot be resolved
# (not inside a repo, empty repo with no commits, git unavailable).
# git rev-parse outputs lowercase hex on all platforms, so the regex is anchored.
sub resolve_head_sha {
    my $sha = `git rev-parse HEAD 2>/dev/null`;
    chomp $sha;
    return $sha =~ /^[0-9a-f]{40}$/ ? $sha : undef;
}

# Run a command in list form, suppressing its stdout/stderr.
#
# List form (no shell) so a derived argument — e.g. a branch name taken from an
# on-disk task dirname — cannot inject shell metacharacters. The post-failed-exec
# child uses POSIX::_exit (not exit) to skip inherited END blocks: CWF::Common is
# broadly imported, and a caller's END (e.g. File::Path cleanup) firing in the
# forked child could delete the parent's state (Task-159 convention).
#
# Args: @cmd (command and arguments)
# Returns: the child's exit code ($? >> 8), or -1 if fork failed.
sub run_quiet {
    my @cmd = @_;
    my $pid = fork();
    return -1 unless defined $pid;
    if ($pid == 0) {
        open(STDIN,  '<', '/dev/null');
        open(STDOUT, '>', '/dev/null');
        open(STDERR, '>', '/dev/null');
        exec(@cmd) or POSIX::_exit(127);
    }
    waitpid($pid, 0);
    return $? >> 8;
}

# Generate a slug from a free-text description.
#
# Algorithm: lowercase, drop non-alphanumeric (preserving spaces and hyphens),
# collapse whitespace runs into single hyphens, collapse hyphen runs into
# single hyphens, strip leading/trailing hyphens.
#
# SHARED OWNERSHIP: this function is invoked by both `template-copier-v2.1`
# (during task creation, to slug the user-supplied task description) and by
# `backlog-manager` (to derive a stable identifier for BACKLOG entries from
# their title). Changes MUST preserve idempotency across both contexts —
# `cwf-new-task` slugging a title and `backlog-manager modify --id=<slug>`
# matching against that title MUST produce the same slug.
#
# Args: $description (string)
# Returns: slug string (may be empty if input contains no alphanumerics)
sub generate_slug {
    my ($description) = @_;

    # Lowercase
    $description = lc($description);

    # Remove special characters (keep alphanumeric, spaces, hyphens)
    $description =~ s/[^a-z0-9 -]//g;

    # Replace spaces with hyphens
    $description =~ s/ +/-/g;

    # Collapse consecutive hyphens
    $description =~ s/-+/-/g;

    # Strip leading/trailing hyphens so "---foo---" becomes "foo".
    $description =~ s/^-+//;
    $description =~ s/-+$//;

    return $description;
}

# Compare two version strings numerically component-by-component
# Args: $a, $b (version strings; leading 'v' stripped if present)
# Returns: -1 / 0 / +1 (suitable for sort)
sub version_cmp {
    my ($a, $b) = @_;
    (my $va = $a) =~ s/^v//;
    (my $vb = $b) =~ s/^v//;

    my @pa = split /\./, $va;
    my @pb = split /\./, $vb;

    my $len = @pa > @pb ? scalar @pa : scalar @pb;
    for my $i (0 .. $len - 1) {
        my $na = $pa[$i] // 0;
        my $nb = $pb[$i] // 0;
        my $cmp = $na <=> $nb;
        return $cmp if $cmp;
    }
    return 0;
}

1;

=head1 NAME

CWF::Common - Common utilities for CWF command helpers

=head1 SYNOPSIS

    use CWF::Common qw(check_perl5opt format_error);

    check_perl5opt();  # Warns if PERL5OPT not configured
    die format_error("validation", "Invalid task path", "script <task-path>");

=head1 DESCRIPTION

Common utilities used across all CIG command helper modules.
Eliminates 78 lines of duplication (PERL5OPT check duplicated 13 times).

=head1 FUNCTIONS

=head2 check_perl5opt()

Checks if PERL5OPT is configured for Unicode handling. Warns if not.

The PERL5OPT environment variable should include the -C flag for proper Unicode
handling. CWF installs C<env.PERL5OPT=-CDSLA> into the project's
C<.claude/settings.json> (via C<cwf-claude-settings-merge>), which Claude Code
applies to tool-call environments. If not present at runtime, warns the user
with instructions to run C<cwf-manage update> (and to export the variable for
non-tool-call shells).

=head2 format_error($type, $message, $usage)

Formats error messages consistently across all modules.

Args:
  $type    - Error type (e.g., "validation", "execution")
  $message - Error message text
  $usage   - Optional usage string to append

Returns: Formatted error string ready to print or die with

Example:
  die format_error("validation", "Invalid task path: 999", "context-manager hierarchy <task-path>");

=head1 AUTHOR

Coding with Files (CWF) System

=head1 SEE ALSO

L<CWF::VersionRouter>, L<CWF::TaskPath>

=cut
