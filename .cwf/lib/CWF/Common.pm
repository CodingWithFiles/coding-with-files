package CWF::Common;
#
# CWF::Common - Common utilities for CWF command helpers
#
# Provides shared functionality like PERL5OPT configuration checking
# and error formatting that was previously duplicated across modules.
#

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(check_perl5opt format_error);

# Check PERL5OPT environment configuration
# Args: none
# Returns: none (warns if not configured)
sub check_perl5opt {
    unless ($ENV{PERL5OPT} && $ENV{PERL5OPT} =~ /-C/) {
        warn "WARNING: PERL5OPT not configured for Unicode handling.\n";
        warn "Add the following to ~/.claude/settings.json:\n";
        warn "  \"env\": { \"PERL5OPT\": \"-CDSL\" }\n\n";
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
