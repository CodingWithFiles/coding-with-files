package CWF::Backlog;
#
# CWF::Backlog - Parser, writer, and validator for BACKLOG.md and CHANGELOG.md.
#
# Section-based two-pass parser: split file by `^---$` separators (outside
# fenced code blocks), then classify each section by its content (active /
# historical / struckthrough / intro / changelog_task / blank / unknown).
#
# Round-trip property: parse_*_file → write_*_file produces byte-identical
# output for unmodified sections. The writer concatenates each section's
# raw_lines verbatim and appends `---\n` when trailing_separator is true.
#
# Modifications (modify, delete, retire) operate on raw_lines via mutator
# helpers; metadata is parsed on-demand via entry_title / entry_metadata.
#
# See: implementation-guide/131-feature-add-backlog-management-helper-script/
#      c-design-plan.md for architecture decisions.
#
use strict;
use warnings;
use utf8;
use Exporter 'import';
use FindBin;
use lib "$FindBin::Bin/../lib";
use CWF::Common qw(generate_slug);
use CWF::ArtefactHelpers qw(atomic_write_text);

our @EXPORT_OK = qw(
    parse_backlog_file
    parse_changelog_file
    write_backlog_file
    write_changelog_file
    validate_backlog
    validate_changelog
    find_active_by_slug
    find_active_by_title
    find_changelog_task
    find_retired_subsection
    block_exists_in_retired
    append_retired_block
    entry_title
    entry_metadata
    entry_body_start_index
    entry_slug
    set_priority_field
    list_active
);

# Priority value is the first word(s); an optional parenthetical annotation may follow.
# E.g., "Low" or "Very Low" or "Low (downgraded post-Task-119)".
our $VALID_PRIORITIES = qr/^(?:Very High|High|Medium|Very Low|Low)(?:\s*\(.*\))?$/;

#==============================================================================
# File IO
#==============================================================================

sub _read_file_with_global_checks {
    my ($path) = @_;
    open(my $fh, '<:raw', $path)
        or die "[CWF] ERROR: cannot read $path: $!\n";
    local $/;
    my $bytes = <$fh>;
    close $fh;

    my @global_errors;

    # GLOBAL-001a: BOM check
    if ($bytes =~ /^\x{ef}\x{bb}\x{bf}/) {
        push @global_errors, {
            file    => $path,
            line    => 1,
            rule    => 'GLOBAL-001',
            message => "UTF-8 BOM not allowed at start of file",
        };
        $bytes =~ s/^\x{ef}\x{bb}\x{bf}//;
    }

    # GLOBAL-001b: CRLF check
    if ($bytes =~ /\r\n/) {
        push @global_errors, {
            file    => $path,
            line    => 1,
            rule    => 'GLOBAL-001',
            message => "CRLF line endings not allowed; file must use LF",
        };
    }

    # Decode UTF-8 (after stripping BOM)
    use Encode qw(decode FB_CROAK LEAVE_SRC);
    my $text = decode('UTF-8', $bytes, FB_CROAK | LEAVE_SRC);

    # Split into lines preserving trailing newlines
    my @lines = ($text =~ /[^\n]*\n?/g);
    # Drop trailing empty match from the regex
    pop @lines while @lines && $lines[-1] eq '';

    return (\@lines, \@global_errors);
}

#==============================================================================
# Section parser (two-pass, fence-aware)
#==============================================================================

sub _parse_sections {
    my ($lines) = @_;
    my @sections;
    my @current = ();
    my $in_fence = 0;

    for my $line (@$lines) {
        # Toggle fence state on triple-backtick lines
        if ($line =~ /^```/) {
            $in_fence = !$in_fence;
        }

        # Separator: only outside fence, exact ^---$ (with optional trailing newline)
        if (!$in_fence && ($line eq "---\n" || $line eq "---")) {
            push @sections, {
                kind               => undef,
                raw_lines          => [@current],
                trailing_separator => 1,
            };
            @current = ();
            next;
        }
        push @current, $line;
    }

    # Final section (no trailing separator)
    if (@current) {
        push @sections, {
            kind               => undef,
            raw_lines          => [@current],
            trailing_separator => 0,
        };
    }

    return \@sections;
}

sub _classify_backlog {
    my ($sect) = @_;
    my $first = _first_non_blank_line($sect);
    return 'blank' unless defined $first;

    return 'intro'  if $first =~ /^# /;
    return 'active' if $first =~ /^## (?:Task|Bug):/;
    return 'unknown';
}

# Fence-state map shared across validators and mutators.
# Returns an arrayref of booleans, one per input line: true when the line is
# inside a fenced code block. A line containing exactly `^```` toggles the
# fence and is itself considered "in fence" (delimiter lines are not editable
# content). Used by all four BACKLOG/CHANGELOG validator rules and the two
# retired-subsection mutators — keeps fence semantics identical across uses.
sub _build_fence_map {
    my ($lines) = @_;
    my @map;
    my $in = 0;
    for my $line (@$lines) {
        if ($line =~ /^```/) {
            push @map, 1;          # delimiter line: in-fence
            $in = !$in;
        }
        else {
            push @map, $in ? 1 : 0;
        }
    }
    return \@map;
}

sub _classify_changelog {
    my ($sect) = @_;
    my $first = _first_non_blank_line($sect);
    return 'blank' unless defined $first;

    # A section is a changelog_task if it CONTAINS a `## Task N:` heading,
    # even if it also includes the file's `# Changelog` intro (which is
    # how the live CHANGELOG.md is structured: intro + most-recent task
    # share the first section, separated only by blank lines).
    for my $l (@{$sect->{raw_lines}}) {
        return 'changelog_task' if $l =~ /^## Task \d+:/;
    }

    return 'intro' if $first =~ /^# Changelog/;
    return 'unknown';
}

sub _first_non_blank_line {
    my ($sect) = @_;
    for my $l (@{$sect->{raw_lines}}) {
        return $l if $l !~ /^\s*$/;
    }
    return undef;
}

#==============================================================================
# Public parse / write
#==============================================================================

sub parse_backlog_file {
    my ($path) = @_;
    my ($lines, $global_errors) = _read_file_with_global_checks($path);
    my $sections = _parse_sections($lines);
    for my $s (@$sections) {
        $s->{kind} = _classify_backlog($s);
    }
    return ($sections, $global_errors);
}

sub parse_changelog_file {
    my ($path) = @_;
    my ($lines, $global_errors) = _read_file_with_global_checks($path);
    my $sections = _parse_sections($lines);
    for my $s (@$sections) {
        $s->{kind} = _classify_changelog($s);
    }
    return ($sections, $global_errors);
}

sub _serialize_sections {
    my ($sections) = @_;
    my $out = '';
    for my $sect (@$sections) {
        $out .= join('', @{$sect->{raw_lines}});
        $out .= "---\n" if $sect->{trailing_separator};
    }
    return $out;
}

sub write_backlog_file {
    my ($path, $sections) = @_;
    die "[CWF] ERROR: refusing symlink at $path\n" if -l $path;
    my $text = _serialize_sections($sections);
    use Encode qw(encode);
    my $bytes = encode('UTF-8', $text);
    atomic_write_text($path, $bytes);
}

sub write_changelog_file {
    my ($path, $sections) = @_;
    die "[CWF] ERROR: refusing symlink at $path\n" if -l $path;
    my $text = _serialize_sections($sections);
    use Encode qw(encode);
    my $bytes = encode('UTF-8', $text);
    atomic_write_text($path, $bytes);
}

#==============================================================================
# Entry helpers (on-demand metadata extraction)
#==============================================================================

sub entry_title {
    my ($sect) = @_;
    return undef unless $sect->{kind} eq 'active';
    my $first = _first_non_blank_line($sect);
    return undef unless defined $first;
    if ($first =~ /^## (?:Task|Bug):\s*(.+?)\s*$/) {
        return $1;
    }
    return undef;
}

sub entry_slug {
    my ($sect) = @_;
    my $title = entry_title($sect);
    return undef unless defined $title;
    return generate_slug($title);
}

# Returns the index in raw_lines where the body begins (after metadata block).
# Body = everything after the first blank line that follows the contiguous
# metadata-field run.
sub entry_body_start_index {
    my ($sect) = @_;
    return 0 unless $sect->{kind} eq 'active';
    my @lines = @{$sect->{raw_lines}};
    my $i = 0;

    # Skip blank lines before the header
    while ($i < @lines && $lines[$i] =~ /^\s*$/) { $i++; }
    # Skip the header
    $i++ if $i < @lines;
    # Skip blank lines after header
    while ($i < @lines && $lines[$i] =~ /^\s*$/) { $i++; }
    # Skip contiguous metadata-field lines
    while ($i < @lines && $lines[$i] =~ /^\*\*[A-Z][\w\- ]*\*\*:/) { $i++; }
    # The body starts here (may begin with blank lines, which are body content)
    return $i;
}

sub entry_metadata {
    my ($sect) = @_;
    return {} unless $sect->{kind} eq 'active';
    my @lines = @{$sect->{raw_lines}};
    my $i = 0;
    my %meta;

    # Skip blank lines and header
    while ($i < @lines && $lines[$i] =~ /^\s*$/) { $i++; }
    $i++ if $i < @lines;
    while ($i < @lines && $lines[$i] =~ /^\s*$/) { $i++; }
    # Read contiguous metadata fields
    while ($i < @lines && $lines[$i] =~ /^\*\*([A-Z][\w\- ]*)\*\*:\s*(.*?)\s*$/) {
        $meta{$1} = $2;
        $i++;
    }
    return \%meta;
}

# Find the (1-based) raw_lines index of the metadata field's line, or undef.
sub _metadata_field_index {
    my ($sect, $field) = @_;
    my @lines = @{$sect->{raw_lines}};
    my $i = 0;
    while ($i < @lines && $lines[$i] =~ /^\s*$/) { $i++; }
    $i++ if $i < @lines;  # header
    while ($i < @lines && $lines[$i] =~ /^\s*$/) { $i++; }
    while ($i < @lines && $lines[$i] =~ /^\*\*([A-Z][\w\- ]*)\*\*:/) {
        return $i if $1 eq $field;
        $i++;
    }
    return undef;
}

#==============================================================================
# Find by slug / title
#==============================================================================

sub list_active {
    my ($sections) = @_;
    return [ grep { $_->{kind} eq 'active' } @$sections ];
}

sub find_active_by_slug {
    my ($sections, $slug) = @_;
    my @hits = grep {
        $_->{kind} eq 'active' && (entry_slug($_) // '') eq $slug
    } @$sections;
    return @hits;
}

sub find_active_by_title {
    my ($sections, $title) = @_;
    my @hits = grep {
        $_->{kind} eq 'active' && (entry_title($_) // '') eq $title
    } @$sections;
    return @hits;
}

#==============================================================================
# Mutators
#==============================================================================

sub set_priority_field {
    my ($sect, $new_value) = @_;
    die "[CWF] ERROR: set_priority_field: not an active entry\n"
        unless $sect->{kind} eq 'active';
    my $idx = _metadata_field_index($sect, 'Priority');
    die "[CWF] ERROR: set_priority_field: no Priority field\n"
        unless defined $idx;
    $sect->{raw_lines}[$idx] = "**Priority**: $new_value\n";
}

# ---- CHANGELOG-side mutators (used by `retire`) ------------------------------

# Find a `## Task N:` entry in CHANGELOG sections. Exact integer match — leading
# zeroes not accepted, since CHANGELOG headers don't have them. Returns the
# section hashref or undef.
sub find_changelog_task {
    my ($sections, $task_num) = @_;
    for my $s (@$sections) {
        next unless $s->{kind} eq 'changelog_task';
        for my $l (@{$s->{raw_lines}}) {
            return $s if $l =~ /^## Task \Q$task_num\E:/;
        }
    }
    return undef;
}

# Locate `### Retired Backlog Items` subsection within a changelog_task entry.
# Returns ($start_idx, $end_idx) where $start_idx is the heading line and
# $end_idx is the next `^### ` heading or scalar @raw_lines (exclusive).
# Both bounds respect fence state. Returns undef if absent.
sub find_retired_subsection {
    my ($sect) = @_;
    my @lines = @{$sect->{raw_lines}};
    my $fence = _build_fence_map(\@lines);
    my $start;
    for (my $i = 0; $i < @lines; $i++) {
        next if $fence->[$i];
        if ($lines[$i] =~ /^### Retired Backlog Items\s*$/) {
            $start = $i;
            last;
        }
    }
    return undef unless defined $start;

    my $end = scalar @lines;
    for (my $i = $start + 1; $i < @lines; $i++) {
        next if $fence->[$i];
        if ($lines[$i] =~ /^### /) {
            $end = $i;
            last;
        }
    }
    return ($start, $end);
}

# Returns true if the given title already appears as a `^####\s+<title>` heading
# inside the entry's `### Retired Backlog Items` subsection. Case-insensitive,
# whitespace-stripped. Fence-aware. The regex `^####\s+` matches the BACKLOG-006
# validator pattern — keeps producer/consumer aligned.
sub block_exists_in_retired {
    my ($sect, $title) = @_;
    my ($start, $end) = find_retired_subsection($sect);
    return 0 unless defined $start;
    my @lines = @{$sect->{raw_lines}};
    my $fence = _build_fence_map(\@lines);
    my $needle = lc($title);
    $needle =~ s/^\s+|\s+$//g;
    for (my $i = $start + 1; $i < $end; $i++) {
        next if $fence->[$i];
        if ($lines[$i] =~ /^####\s+(.*?)\s*$/) {
            my $cand = lc($1);
            $cand =~ s/^\s+|\s+$//g;
            return 1 if $cand eq $needle;
        }
    }
    return 0;
}

# Append a `#### <title>` block (with optional <!-- Note: --> comment) to the
# `### Retired Backlog Items` subsection. Creates the subsection if absent,
# inserting it per c-design § Decision 7: after `### Notable` if present, else
# after `### Changes`, else immediately after the metadata block. Mutates
# $sect->{raw_lines} in place.
sub append_retired_block {
    my ($sect, $title, $body_lines, $note) = @_;
    die "[CWF] ERROR: append_retired_block: not a changelog_task\n"
        unless $sect->{kind} eq 'changelog_task';

    # Build the block lines (the `#### <title>` heading and its content).
    my @body = @{$body_lines // []};
    # Strip leading/trailing blank lines from the supplied body so spacing is
    # uniform regardless of how the source preserved them.
    shift @body while @body && $body[0] =~ /^\s*$/;
    pop @body while @body && $body[-1] =~ /^\s*$/;

    my @block;
    push @block, "#### $title\n";
    push @block, "\n";
    push @block, @body;
    push @block, "\n" if @body;
    if (defined $note && length $note) {
        push @block, "<!-- Note: $note -->\n";
        push @block, "\n";
    }

    my @lines = @{$sect->{raw_lines}};
    my ($r_start, $r_end) = find_retired_subsection($sect);

    if (defined $r_start) {
        # Subsection exists: append block at $r_end (just before next `### ` or eof).
        # Strip trailing blank line(s) from inside the existing subsection so the
        # new block sits flush, then re-add a trailing blank.
        my $insert_at = $r_end;
        while ($insert_at > $r_start + 1 && $lines[$insert_at - 1] =~ /^\s*$/) {
            $insert_at--;
        }
        splice(@lines, $insert_at, 0, "\n", @block);
    }
    else {
        # Subsection absent: compute insertion point per § Decision 7.
        my $fence = _build_fence_map(\@lines);
        my $insert_at = _retired_insertion_point(\@lines, $fence);
        my @new = ("### Retired Backlog Items\n", "\n", @block);
        # Ensure a blank line separates the new subsection from preceding content.
        if ($insert_at > 0 && $lines[$insert_at - 1] !~ /^\s*$/) {
            unshift @new, "\n";
        }
        splice(@lines, $insert_at, 0, @new);
    }

    $sect->{raw_lines} = \@lines;
    return 1;
}

# Decide where to insert a brand-new `### Retired Backlog Items` subsection.
# Returns the index in @$lines where the new heading should be spliced.
# Order of preference (per c-design § Decision 7 step 1):
#   - immediately after the end of `### Notable`
#   - else immediately after the end of `### Changes`
#   - else immediately after the metadata block
# "End of section" = next `### ` heading outside fences, or end-of-entry.
sub _retired_insertion_point {
    my ($lines, $fence) = @_;
    my %sect_end;
    my @sect_starts;
    for (my $i = 0; $i < @$lines; $i++) {
        next if $fence->[$i];
        if ($lines->[$i] =~ /^### (Changes|Notable)\s*$/) {
            push @sect_starts, [$1, $i];
        }
    }
    for my $entry (@sect_starts) {
        my ($name, $idx) = @$entry;
        my $end = scalar @$lines;
        for (my $j = $idx + 1; $j < @$lines; $j++) {
            next if $fence->[$j];
            if ($lines->[$j] =~ /^### /) { $end = $j; last; }
        }
        $sect_end{$name} = $end;
    }
    return $sect_end{Notable} if defined $sect_end{Notable};
    return $sect_end{Changes} if defined $sect_end{Changes};
    # Fall back to "after the metadata block" — the first blank line after the
    # contiguous `^**Field**:` run that follows `^## Task N:`.
    my $i = 0;
    # Skip leading blanks
    while ($i < @$lines && $lines->[$i] =~ /^\s*$/) { $i++; }
    # Skip the `# Changelog` intro line if present (live CHANGELOG.md style).
    $i++ if $i < @$lines && $lines->[$i] =~ /^# Changelog/;
    # Skip blanks again
    while ($i < @$lines && $lines->[$i] =~ /^\s*$/) { $i++; }
    # Skip `## Task N:` header
    $i++ if $i < @$lines && $lines->[$i] =~ /^## Task \d+:/;
    # Skip blanks
    while ($i < @$lines && $lines->[$i] =~ /^\s*$/) { $i++; }
    # Skip metadata field lines
    while ($i < @$lines && $lines->[$i] =~ /^\*\*[A-Z][\w\- ]*\*\*:/) { $i++; }
    return $i;
}

#==============================================================================
# Validators
#==============================================================================

sub _section_start_line {
    my ($sections, $target) = @_;
    my $line = 1;
    for my $s (@$sections) {
        return $line if $s == $target;
        $line += scalar @{$s->{raw_lines}};
        $line++ if $s->{trailing_separator};
    }
    return $line;
}

sub validate_backlog {
    my ($sections, $path) = @_;
    $path //= 'BACKLOG.md';
    my @errors;

    # File-wide rules (BACKLOG-004, BACKLOG-005) walk lines across the entire
    # file with a single fence map so fence semantics match across rules.
    push @errors, _validate_backlog_file_wide($sections, $path);

    for my $sect (@$sections) {
        my $start = _section_start_line($sections, $sect);

        if ($sect->{kind} eq 'active') {
            push @errors, _validate_active_backlog($sect, $start, $path);
        }
        elsif ($sect->{kind} eq 'unknown') {
            push @errors, {
                file    => $path,
                line    => $start,
                rule    => 'BACKLOG-CLASSIFY',
                message => "section could not be classified",
            };
        }
    }
    return \@errors;
}

sub _validate_backlog_file_wide {
    my ($sections, $path) = @_;
    my @errors;

    # Reconstruct the full line stream (matching file order, including separators).
    my @lines;
    for my $s (@$sections) {
        push @lines, @{$s->{raw_lines}};
        push @lines, "---\n" if $s->{trailing_separator};
    }
    my $fence = _build_fence_map(\@lines);

    for (my $i = 0; $i < @lines; $i++) {
        next if $fence->[$i];
        my $l = $lines[$i];

        # BACKLOG-004: no HTML comments anywhere in BACKLOG (active items only;
        # comments belong in CHANGELOG, not here).
        if ($l =~ /<!--/ || $l =~ /-->/) {
            push @errors, {
                file    => $path,
                line    => $i + 1,
                rule    => 'BACKLOG-004',
                message => "HTML comment not permitted in BACKLOG (move to CHANGELOG via retire)",
            };
        }

        # BACKLOG-005: no struck-through entry headings.
        if ($l =~ /^## / && ($l =~ /~~/ || $l =~ /✓/)) {
            push @errors, {
                file    => $path,
                line    => $i + 1,
                rule    => 'BACKLOG-005',
                message => "struck-through entry heading not permitted; use retire to move to CHANGELOG",
            };
        }
    }
    return @errors;
}

sub _validate_active_backlog {
    my ($sect, $start_line, $path) = @_;
    my @errors;
    my $meta  = entry_metadata($sect);
    my $title = entry_title($sect) // '<unknown>';

    # BACKLOG-001: Task-Type required
    unless (exists $meta->{'Task-Type'}) {
        push @errors, {
            file    => $path,
            line    => $start_line,
            rule    => 'BACKLOG-001',
            message => "missing required Task-Type field on entry: '$title'",
        };
    }
    unless (exists $meta->{'Priority'}) {
        push @errors, {
            file    => $path,
            line    => $start_line,
            rule    => 'BACKLOG-001',
            message => "missing required Priority field on entry: '$title'",
        };
    }

    # BACKLOG-002: priority value
    if (exists $meta->{'Priority'}) {
        my $p = $meta->{'Priority'};
        unless ($p =~ $VALID_PRIORITIES) {
            my $idx = _metadata_field_index($sect, 'Priority') // 0;
            push @errors, {
                file    => $path,
                line    => $start_line + $idx,
                rule    => 'BACKLOG-002',
                message => "priority value '$p' is not one of {High, Medium, Low, Very Low}",
            };
        }
    }

    # BACKLOG-003: body lines must not match ^---$
    # BACKLOG-006: body lines must not match `^####\s+` (reserved for retired
    # block headings inside CHANGELOG's `### Retired Backlog Items` subsection;
    # if the entry is later retired, body content is copied verbatim and the
    # `####` heading would collide with the dedup scanner).
    my $body_start = entry_body_start_index($sect);
    my @lines = @{$sect->{raw_lines}};
    my $fence = _build_fence_map(\@lines);
    for (my $i = $body_start; $i < @lines; $i++) {
        next if $fence->[$i];
        if ($lines[$i] eq "---\n") {
            push @errors, {
                file    => $path,
                line    => $start_line + $i,
                rule    => 'BACKLOG-003',
                message => "body line matches separator pattern",
            };
        }
        if ($lines[$i] =~ /^####\s+/) {
            push @errors, {
                file    => $path,
                line    => $start_line + $i,
                rule    => 'BACKLOG-006',
                message => "'####' reserved for retired-block headings in CHANGELOG; rephrase or wrap in code fence",
            };
        }
    }

    return @errors;
}

sub validate_changelog {
    my ($sections, $path) = @_;
    $path //= 'CHANGELOG.md';
    my @errors;

    # CHANGELOG-001: count '# Changelog' headers across all sections
    my $changelog_count = 0;
    my $first_extra_line;
    for my $sect (@$sections) {
        my $sect_start = _section_start_line($sections, $sect);
        for (my $i = 0; $i < @{$sect->{raw_lines}}; $i++) {
            if ($sect->{raw_lines}[$i] =~ /^# Changelog\s*$/) {
                $changelog_count++;
                $first_extra_line = $sect_start + $i if $changelog_count == 2;
            }
        }
    }
    if ($changelog_count == 0) {
        push @errors, {
            file => $path, line => 1,
            rule => 'CHANGELOG-001',
            message => "missing top-level '# Changelog' header",
        };
    }
    elsif ($changelog_count > 1) {
        push @errors, {
            file => $path, line => $first_extra_line // 1,
            rule => 'CHANGELOG-001',
            message => "multiple '# Changelog' headers found",
        };
    }

    for my $sect (@$sections) {
        next unless $sect->{kind} eq 'changelog_task';
        my $start = _section_start_line($sections, $sect);
        push @errors, _validate_changelog_task($sect, $start, $path);
    }
    return \@errors;
}

sub _validate_changelog_task {
    my ($sect, $start_line, $path) = @_;
    my @errors;
    my @lines = @{$sect->{raw_lines}};
    my $body  = join('', @lines);

    # CHANGELOG-002: **Status**: and **Impact**: must be present
    unless ($body =~ /^\*\*Status\*\*:/m) {
        push @errors, {
            file    => $path,
            line    => $start_line,
            rule    => 'CHANGELOG-002',
            message => "changelog entry missing **Status**: field",
        };
    }
    unless ($body =~ /^\*\*Impact\*\*:/m) {
        push @errors, {
            file    => $path,
            line    => $start_line,
            rule    => 'CHANGELOG-002',
            message => "changelog entry missing **Impact**: field",
        };
    }

    # CHANGELOG-003: subsection order must be Changes → Notable → Retired.
    # Walk the entry body, collecting indices of these three headings outside
    # fences. Indices must appear in canonical order (any subset is fine; the
    # constraint is on relative order when multiple are present).
    my $fence = _build_fence_map(\@lines);
    my %order = ('Changes' => 1, 'Notable' => 2, 'Retired Backlog Items' => 3);
    my $last_seen = 0;
    for (my $i = 0; $i < @lines; $i++) {
        next if $fence->[$i];
        if ($lines[$i] =~ /^### (Changes|Notable|Retired Backlog Items)\s*$/) {
            my $rank = $order{$1};
            if ($rank < $last_seen) {
                push @errors, {
                    file    => $path,
                    line    => $start_line + $i,
                    rule    => 'CHANGELOG-003',
                    message => "subsections out of order; expected Changes -> Notable -> Retired Backlog Items",
                };
            }
            $last_seen = $rank;
        }
    }

    return @errors;
}

1;

=head1 NAME

CWF::Backlog - Parse, validate, and edit BACKLOG.md and CHANGELOG.md

=head1 SYNOPSIS

    use CWF::Backlog qw(
        parse_backlog_file write_backlog_file validate_backlog
        find_active_by_slug entry_title entry_metadata
    );

    my ($sections, $global_errors) = parse_backlog_file('BACKLOG.md');
    my $errors = validate_backlog($sections);
    my @hits = find_active_by_slug($sections, 'add-feature-x');
    write_backlog_file('BACKLOG.md', $sections);   # round-trips byte-identical if untouched

=head1 SECTIONS

A "section" is a block between `^---$` separators (outside fenced code blocks).
Each section has a `kind`:

  intro            file header (one only, first section)
  active           `## Task: …` or `## Bug: …` entry (BACKLOG only)
  blank            only blank lines
  changelog_task   `## Task N: …` (CHANGELOG only)
  unknown          failed classification (validator flags)

BACKLOG must contain only active items; HTML comments and struck-through entry
headings are flagged as errors (BACKLOG-004 / BACKLOG-005). Use the `retire`
subcommand of `backlog-manager` to move completed entries to CHANGELOG.

=head1 ROUND-TRIP

`parse_backlog_file → write_backlog_file` is byte-identical for untouched files.
This is the foundation for all editing operations: only `raw_lines` of modified
sections are rewritten; everything else passes through.

=head1 SEE ALSO

L<CWF::Common>, L<CWF::ArtefactHelpers>

=cut
