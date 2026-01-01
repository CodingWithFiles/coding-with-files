package CIG::MarkdownParser;
#
# CIG::MarkdownParser - Structure-aware markdown parsing for status extraction
#
# Fixes false positives by only extracting status from the correct section,
# ignoring code blocks and other sections that happen to contain status patterns.
#

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(extract_status);

# Extract status from file, respecting markdown structure
# Only matches **Status**: within ## Status or ## Current Status section
# Ignores status patterns in code blocks and other sections
#
# Args: $file_path - path to markdown file
# Returns: status string or "Unknown"
#
sub extract_status {
    my ($file_path) = @_;

    open(my $fh, '<', $file_path) or return "Unknown";

    my $in_code_block = 0;
    my $in_status_section = 0;
    my $status_sections_found = 0;

    while (my $line = <$fh>) {
        chomp $line;

        # Track code blocks (triple backticks only)
        if ($line =~ /^```/) {
            $in_code_block = !$in_code_block;
            next;
        }
        next if $in_code_block;

        # Detect status section header (## Status or ## Current Status)
        if ($line =~ /^## (Current )?Status\s*$/i) {
            $status_sections_found++;
            if ($status_sections_found > 1) {
                print STDERR "Warning: Multiple '## Status' sections found in $file_path, using first occurrence\n";
            } elsif ($status_sections_found == 1) {
                $in_status_section = 1;
            }
            next;
        }

        # Exit status section on next L2 header
        if ($in_status_section && $line =~ /^## /) {
            $in_status_section = 0;
        }

        # Extract status ONLY if in correct section
        if ($in_status_section && $line =~ /^\*\*Status\*\*:\s*(.+)$/) {
            close($fh);
            my $status = $1;
            $status =~ s/\s+$//;  # Trim trailing whitespace
            return $status;
        }
    }

    close($fh);
    return "Unknown";
}

1;
