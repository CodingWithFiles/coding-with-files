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

our @EXPORT_OK = qw(check_perl5opt format_error parse_semver version_cmp find_git_root resolve_head_sha generate_slug);

# Check PERL5OPT environment configuration
# Args: none
# Returns: none (warns if not configured)
sub check_perl5opt {
    unless ($ENV{PERL5OPT} && $ENV{PERL5OPT} =~ /-C/) {
        warn "WARNING: PERL5OPT not configured for Unicode handling.\n";
        warn "Add the following to ~/.claude/settings.json:\n";
        warn "  \"env\": { \"PERL5OPT\": \"-CDSLA\" }\n\n";
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

# Resolve the current git repository root.
# Returns: absolute path string, or undef if not inside a git repo.
sub find_git_root {
    my $root = `git rev-parse --show-toplevel 2>/dev/null`;
    chomp $root;
    return length $root ? $root : undef;
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
handling. If not configured, warns the user with instructions to add it to their
Claude settings.json file.

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
