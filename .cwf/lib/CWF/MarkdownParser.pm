package CWF::MarkdownParser;
#
# CWF::MarkdownParser - Section-scoped, code-block-aware markdown field extraction
#
# General-purpose parser for extracting **Key**: Value fields from specific
# ## sections in markdown files. Ignores code blocks and respects section
# boundaries.
#

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(extract_field find_field_line);

# Find a **Key**: Value line within a specific ## section.
# Code-block-aware, section-scoped, returns position info for read+write.
#
# Args:
#   $file_path  - path to markdown file
#   $section_re - compiled regex matching the ## section header (e.g. qr/^## Status\s*$/i)
#   $key_re     - compiled regex with one capture group for the value (e.g. qr/^\*\*Status\*\*:\s*(.+?)\s*$/)
#
# Returns: ($line_index, $captured_value, @all_lines) or () if not found
#
sub find_field_line {
    my ($file_path, $section_re, $key_re) = @_;

    my @lines;
    { open(my $fh, '<', $file_path) or return (); @lines = <$fh>; close $fh; }

    my $in_code_block = 0;
    my $in_section = 0;

    for my $i (0 .. $#lines) {
        my $line = $lines[$i];
        chomp $line;

        if ($line =~ /^```/) {
            $in_code_block = !$in_code_block;
            next;
        }
        next if $in_code_block;

        if (!$in_section && $line =~ $section_re) {
            $in_section = 1;
            next;
        }

        if ($in_section && $line =~ $key_re) {
            return ($i, $1, @lines);
        }

        last if $in_section && $line =~ /^## /;
    }

    return ();
}

# Extract a field value from a specific section — read-only convenience wrapper.
#
# Args: same as find_field_line
# Returns: value string or "Unknown"
#
sub extract_field {
    my ($file_path, $section_re, $key_re) = @_;

    my ($line_idx, $value) = find_field_line($file_path, $section_re, $key_re);
    return defined $line_idx ? $value : "Unknown";
}

1;
