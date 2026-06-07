package CWF::Backlog;
#
# CWF::Backlog - Parser, serialiser, validator, and mutator for BACKLOG.md and
# CHANGELOG.md (heading-tree format).
#
# Heading-tree parser: split by `^## (Task|Bug):` (BACKLOG) or `^## Task N:`
# (CHANGELOG) headings. Each entry's H3 children are classified as metadata
# (`### Key: Value`) or subsection (`### Name`). Body content is captured as
# raw lines. No `---` separator semantics.
#
# Round-trip property: `parse_*_tree → serialize_tree` is byte-identical for
# canonical inputs. Postel-liberal inputs are canonicalised on serialise;
# BACKLOG-007 / CHANGELOG-004 warn.
#
# Mutators (set_metadata_field, add_entry, delete_entry, append_retired_block_tree)
# operate in-place on the parsed tree; the writer reads the mutated tree.
#
# See: implementation-guide/132-feature-refactor-backlog-changelog-to-heading-tree-model/
#      c-design-plan.md for architecture decisions.
#
use strict;
use warnings;
use utf8;
use Exporter 'import';
use Encode qw(decode encode FB_CROAK LEAVE_SRC);
use FindBin;
use lib "$FindBin::Bin/../lib";
use CWF::Common qw(generate_slug find_git_root);
use CWF::ArtefactHelpers qw(atomic_write_text);
use CWF::WorkflowFiles qw(load_config);

our @EXPORT_OK = qw(
    parse_backlog_tree
    parse_changelog_tree
    serialize_tree
    write_tree
    write_backlog_tree
    write_changelog_tree
    metadata_get
    metadata_node
    set_metadata_field
    add_entry
    delete_entry
    find_all_entries_by_slug
    find_all_entries_by_title
    find_changelog_entry_by_task_num
    append_retired_block_tree
    block_exists_in_retired_tree
    bootstrap_changelog_entry
    resolve_task_title_from_dir
    validate_backlog_tree
    validate_changelog_tree
    trim_blank_lines
    $VALID_PRIORITIES
    $METADATA_KEY_RE
    @CANONICAL_SUBSECTIONS
);

# Priority value is the first word(s); an optional parenthetical annotation may
# follow (e.g. "Low (downgraded post-Task-119)"). Single source of truth — the
# helper imports this rather than re-stating the alternation.
our $VALID_PRIORITIES = qr/^(?:Very High|High|Medium|Very Low|Low)(?:\s*\(.*\))?$/;

# Retired project name (pre-Task-59 brand). Its presence in the CHANGELOG intro
# means a rebrand was incomplete; CHANGELOG-005 surfaces it. Single source of
# truth for the stale substring.
our $STALE_CHANGELOG_BRAND = 'Code Implementation Guide (CIG)';

# Metadata-key character class — `### Foo: value` and the legacy `**Foo**: value`
# both share this contract. Single source so parser and canonicaliser stay in
# lockstep.
our $METADATA_KEY_RE = qr/[A-Z][\w\- ]*/;

# CHANGELOG canonical subsection order. Validators (CHANGELOG-003) and the
# retired-subsection insertion logic both consult this list.
our @CANONICAL_SUBSECTIONS = ('Changes', 'Notable', 'Retired Backlog Items');

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
    my $text = decode('UTF-8', $bytes, FB_CROAK | LEAVE_SRC);

    # Split into lines preserving trailing newlines
    my @lines = ($text =~ /[^\n]*\n?/g);
    # Drop trailing empty match from the regex
    pop @lines while @lines && $lines[-1] eq '';

    return (\@lines, \@global_errors);
}

#==============================================================================
# Fence-state map (shared across parsers, serialiser, validators)
#==============================================================================

# Returns an arrayref of booleans, one per input line: true when the line is
# inside a fenced code block. A line containing exactly `^```` toggles the
# fence and is itself considered "in fence" (delimiter lines are not editable
# content). Single source of fence truth — never rebuild per-rule.
sub _build_fence_map {
    my ($lines) = @_;
    my @map;
    my $in = 0;
    for my $line (@$lines) {
        if ($line =~ /^```/) {
            push @map, 1;
            $in = !$in;
        }
        else {
            push @map, $in ? 1 : 0;
        }
    }
    return \@map;
}

#==============================================================================
# Tree parser: heading-based tree, no `---` separators
#==============================================================================
#
# Tree shape:
#   {
#     intro   => [@raw_lines],
#     entries => [
#       {
#         type          => "Task" | "Bug",        # BACKLOG type marker
#         task_num      => 131 | undef,           # CHANGELOG only; undef for BACKLOG
#         title         => "...",
#         header_lineno => N,
#         metadata      => [{key, value, lineno}, ...],
#         subsections   => [{name, lineno, body_raw}, ...],
#         body_raw      => [@lines],              # entry-level body (between metadata
#                                                 # and first subsection)
#       },
#     ],
#   }
#
# Canonical serialised form per entry:
#   ## <Type>: <Title>\n          (or "## Task <N>: <Title>\n")
#   \n
#   ### <Key1>: <Value1>\n        (zero or more, no blank lines between)
#   ### <Key2>: <Value2>\n
#   \n                            (only if body or subsections follow)
#   <body_raw lines, no leading/trailing blanks>\n
#   \n                            (between body and first subsection)
#   ### <SubName>\n
#   <sub.body_raw lines>\n
#   \n                            (between subsections / before next entry)
#
# Round-trip is byte-identical for entries already in canonical form. Postel-
# liberal inputs (body before metadata, etc.) are reordered to canonical on
# write; BACKLOG-007 / CHANGELOG-004 warn about non-canonical inputs.

sub parse_backlog_tree   { return _parse_path($_[0], 'backlog');   }
sub parse_changelog_tree { return _parse_path($_[0], 'changelog'); }

sub _parse_path {
    my ($path, $kind) = @_;
    my ($lines, $global_errors) = _read_file_with_global_checks($path);
    my ($tree, $parse_errors) = _parse_tree($lines, $kind);
    $_->{file} //= $path for @$parse_errors;
    push @$global_errors, @$parse_errors;
    # Cache the source line stream and fence map on the tree so the file-wide
    # validator can reuse them (avoids a second serialise + tokenise + fence
    # rebuild per validate call).
    $tree->{_source_lines} = $lines;
    $tree->{_source_fence} = _build_fence_map($lines);
    return ($tree, $global_errors);
}

# Trim leading and trailing blank lines in place. Public: the helper script
# uses this from `cmd_add` and the canonicaliser to keep blank-handling
# consistent with the parser.
sub trim_blank_lines {
    my ($arr) = @_;
    return unless ref $arr eq 'ARRAY';
    shift @$arr while @$arr && $arr->[0]  =~ /^[ \t]*\n?\z/;
    pop   @$arr while @$arr && $arr->[-1] =~ /^[ \t]*\n?\z/;
}

sub _check_heading_control {
    my ($text, $lineno, $errs) = @_;
    if ($text =~ /([\x00-\x08\x0a-\x1f])/) {
        push @$errs, {
            line    => $lineno,
            rule    => 'GLOBAL-002',
            message => sprintf("heading text contains control character U+%04X", ord($1)),
        };
    }
}

sub _parse_tree {
    my ($lines, $kind) = @_;
    my $fence = _build_fence_map($lines);
    my $tree  = { intro => [], entries => [] };
    my @errs;

    my $entry_re = $kind eq 'backlog'
        ? qr/^## (Task|Bug):[ \t]*(.+?)[ \t]*\n?\z/
        : qr/^## Task[ \t]+(\d+):[ \t]*(.+?)[ \t]*\n?\z/;
    my $h3_meta_re = qr/^(${METADATA_KEY_RE}):[ \t]*(.*?)\s*\z/;

    my $cur_entry;
    my $body_target = $tree->{intro};

    for (my $i = 0; $i < @$lines; $i++) {
        my $line = $lines->[$i];

        if (!$fence->[$i] && $line =~ $entry_re) {
            my ($cap1, $cap2) = ($1, $2);
            _check_heading_control($cap2, $i + 1, \@errs);
            $cur_entry = {
                type            => $kind eq 'backlog' ? $cap1 : 'Task',
                task_num        => $kind eq 'backlog' ? undef : ($cap1 + 0),
                title           => $cap2,
                header_lineno   => $i + 1,
                metadata        => [],
                subsections     => [],
                body_raw        => [],
                # Set true when body content arrives before the first metadata
                # node — drives BACKLOG-007 / CHANGELOG-004 warnings.
                body_before_meta => 0,
            };
            push @{$tree->{entries}}, $cur_entry;
            $body_target = $cur_entry->{body_raw};
            next;
        }

        if (!$fence->[$i] && $cur_entry && $line =~ /^###[ \t]+(.+?)[ \t]*\n?\z/) {
            my $text = $1;
            _check_heading_control($text, $i + 1, \@errs);
            if ($text =~ $h3_meta_re) {
                push @{$cur_entry->{metadata}}, {
                    key    => $1,
                    value  => $2,
                    lineno => $i + 1,
                };
                # If body_raw already holds non-blank content, this is the
                # first metadata seen *after* body — record for BACKLOG-007.
                $cur_entry->{body_before_meta} = 1
                    if !$cur_entry->{body_before_meta} && _any_nonblank($cur_entry->{body_raw});
            } else {
                my $sub = {
                    name     => $text,
                    lineno   => $i + 1,
                    body_raw => [],
                };
                push @{$cur_entry->{subsections}}, $sub;
                $body_target = $sub->{body_raw};
            }
            next;
        }

        push @$body_target, $line;
    }

    trim_blank_lines($tree->{intro});
    for my $e (@{$tree->{entries}}) {
        trim_blank_lines($e->{body_raw});
        trim_blank_lines($_->{body_raw}) for @{$e->{subsections}};
    }

    return ($tree, \@errs);
}

# Accessors: by key, return value or full node. Single linear scan.
sub metadata_node {
    my ($entry, $key) = @_;
    for my $m (@{$entry->{metadata}}) {
        return $m if $m->{key} eq $key;
    }
    return undef;
}
sub metadata_get {
    my $m = metadata_node(@_);
    return $m ? $m->{value} : undef;
}

#==============================================================================
# Tree serialiser
#==============================================================================

sub serialize_tree {
    my ($tree) = @_;
    my $out = '';

    # Intro: emit verbatim, then ensure a blank line separates it from the
    # first entry (only if both intro and entries are non-empty).
    if (@{$tree->{intro}}) {
        $out .= join('', @{$tree->{intro}});
        $out .= "\n" unless $out =~ /\n\z/;
        $out .= "\n" if @{$tree->{entries}};
    }

    for (my $i = 0; $i < @{$tree->{entries}}; $i++) {
        my $e = $tree->{entries}[$i];
        $out .= _serialize_entry($e);
        # Blank-line separator between entries. The last entry gets no trailing
        # blank — the file ends after its content's final newline.
        $out .= "\n" if $i < $#{$tree->{entries}};
    }

    return $out;
}

sub _serialize_entry {
    my ($e) = @_;
    my $out = defined $e->{task_num}
        ? "## Task $e->{task_num}: $e->{title}\n"
        : "## $e->{type}: $e->{title}\n";

    my $has_meta = @{$e->{metadata}}    > 0;
    my $has_body = @{$e->{body_raw}}    > 0;
    my $has_subs = @{$e->{subsections}} > 0;

    $out .= "\n" if $has_meta || $has_body || $has_subs;

    for my $m (@{$e->{metadata}}) {
        $out .= "### $m->{key}: $m->{value}\n";
    }

    $out .= "\n" if $has_meta && ($has_body || $has_subs);

    if ($has_body) {
        $out .= join('', @{$e->{body_raw}});
        $out .= "\n" unless $out =~ /\n\z/;
    }

    if ($has_subs) {
        $out .= "\n" if $has_body;
        for (my $j = 0; $j < @{$e->{subsections}}; $j++) {
            my $s = $e->{subsections}[$j];
            $out .= "\n" if $j > 0;
            $out .= "### $s->{name}\n";
            if (@{$s->{body_raw}}) {
                $out .= join('', @{$s->{body_raw}});
                $out .= "\n" unless $out =~ /\n\z/;
            }
        }
    }

    return $out;
}

sub write_tree {
    my ($path, $tree) = @_;
    die "[CWF] ERROR: refusing symlink at $path\n" if -l $path;
    atomic_write_text($path, encode('UTF-8', serialize_tree($tree)));
}
*write_backlog_tree   = \&write_tree;
*write_changelog_tree = \&write_tree;

#==============================================================================
# Tree validators
#==============================================================================
#
# All validators receive the parsed tree and the source path. They return a
# list-ref of errors, each `{file, line, rule, severity, message}`. Severity
# defaults to 'error' (caller treats absence as error). Warnings do not fail
# the validate exit code.
#
# A single fence map per file (built from the reconstructed line stream) backs
# the file-wide rule (BACKLOG-004); every other rule is a tree walk and never
# rebuilds the fence map.

# Reconstruct the original line stream from a tree by re-serialising and
# splitting. This gives the file-wide validator the same byte view the parser
# saw, with line numbers preserved relative to the canonical form. For most
# files the canonical and on-disk forms match; for non-canonical inputs the
# fence-aware HTML-comment check still fires correctly because BACKLOG content
# does not introduce new fence boundaries during canonicalisation.
sub validate_backlog_tree {
    my ($tree, $path) = @_;
    $path //= 'BACKLOG.md';
    my @errors;

    # File-wide BACKLOG-004 (HTML comment scan). Reuses the source line stream
    # and fence map cached by the parser — no re-serialisation, no second
    # fence rebuild. For trees built by mutators (no source), fall back to a
    # serialise-and-tokenise pass.
    my ($lines, $fence) = _file_lines_and_fence($tree);
    for (my $i = 0; $i < @$lines; $i++) {
        next if $fence->[$i];
        if ($lines->[$i] =~ /<!--|-->/) {
            push @errors, {
                file => $path, line => $i + 1, rule => 'BACKLOG-004',
                severity => 'error',
                message  => "HTML comment not permitted in BACKLOG (move to CHANGELOG via retire)",
            };
        }
    }

    for my $e (@{$tree->{entries}}) {
        push @errors, _check_required_keys($e, $path, 'BACKLOG-001',
            ['Task-Type', 'Priority']);
        push @errors, _check_priority_value($e, $path);
        push @errors, _check_struck_title($e, $path);
        push @errors, _check_body_before_meta($e, $path, 'BACKLOG-007',
            "entry body appears before metadata (non-canonical order); next write will canonicalise");
    }
    return \@errors;
}

sub validate_changelog_tree {
    my ($tree, $path) = @_;
    $path //= 'CHANGELOG.md';
    my @errors;

    my $count = grep { /^# Changelog\s*$/ } @{$tree->{intro}};
    if ($count != 1) {
        push @errors, {
            file => $path, line => 1, rule => 'CHANGELOG-001', severity => 'error',
            message => $count == 0 ? "missing top-level '# Changelog' header"
                                   : "multiple '# Changelog' headers found",
        };
    }

    # CHANGELOG-005 (warning): stale project name in the intro. Scan the intro
    # array only — the body legitimately carries historical "(CIG)" fragments in
    # retired Task-59 entries, which must never trip this.
    if (grep { index($_, $STALE_CHANGELOG_BRAND) >= 0 } @{$tree->{intro}}) {
        push @errors, {
            file => $path, line => 1, rule => 'CHANGELOG-005', severity => 'warning',
            message => "stale project name in CHANGELOG intro; expected 'Coding with Files (CWF)'",
        };
    }

    for my $e (@{$tree->{entries}}) {
        push @errors, _check_required_keys($e, $path, 'CHANGELOG-002',
            ['Status', 'Impact']);
        push @errors, _check_subsection_order($e, $path);
        push @errors, _check_body_before_meta($e, $path, 'CHANGELOG-004',
            "changelog entry body appears before metadata (non-canonical order); next write will canonicalise");
    }
    return \@errors;
}

# Source line stream + fence map. Prefers parser-cached values; falls back to
# re-serialising the tree (used when callers construct trees via mutators).
sub _file_lines_and_fence {
    my ($tree) = @_;
    return ($tree->{_source_lines}, $tree->{_source_fence})
        if $tree->{_source_lines} && $tree->{_source_fence};
    my @lines = (serialize_tree($tree) =~ /[^\n]*\n?/g);
    pop @lines while @lines && $lines[-1] eq '';
    return (\@lines, _build_fence_map(\@lines));
}

sub _check_required_keys {
    my ($e, $path, $rule, $keys) = @_;
    my $title = $e->{title} // '<unknown>';
    my @errors;
    for my $key (@$keys) {
        next if defined metadata_get($e, $key);
        push @errors, {
            file => $path, line => $e->{header_lineno}, rule => $rule,
            severity => 'error',
            message  => "missing required $key field on entry: '$title'",
        };
    }
    return @errors;
}

sub _check_priority_value {
    my ($e, $path) = @_;
    my $node = metadata_node($e, 'Priority');
    return () unless $node && $node->{value} !~ $VALID_PRIORITIES;
    return {
        file => $path, line => $node->{lineno} // $e->{header_lineno},
        rule => 'BACKLOG-002', severity => 'error',
        message => "priority value '$node->{value}' is not one of {Very High, High, Medium, Low, Very Low}",
    };
}

sub _check_struck_title {
    my ($e, $path) = @_;
    return () unless $e->{title} =~ /~~|✓/;
    return {
        file => $path, line => $e->{header_lineno},
        rule => 'BACKLOG-005', severity => 'error',
        message => "struck-through entry title not permitted; use retire to move to CHANGELOG",
    };
}

sub _check_body_before_meta {
    my ($e, $path, $rule, $message) = @_;
    return () unless $e->{body_before_meta} && @{$e->{metadata}};
    return {
        file => $path, line => $e->{header_lineno}, rule => $rule,
        severity => 'warning', message => $message,
    };
}

sub _check_subsection_order {
    my ($e, $path) = @_;
    my %rank;
    $rank{$CANONICAL_SUBSECTIONS[$_]} = $_ for 0..$#CANONICAL_SUBSECTIONS;
    my $last_rank = -1;
    for my $s (@{$e->{subsections}}) {
        my $r = $rank{$s->{name}};
        last unless defined $r;       # extras after canonical prefix → stop checking
        if ($r < $last_rank) {
            return {
                file => $path, line => $s->{lineno},
                rule => 'CHANGELOG-003', severity => 'error',
                message => "subsections out of order; expected " . join(' -> ', @CANONICAL_SUBSECTIONS),
            };
        }
        $last_rank = $r;
    }
    return ();
}

sub _any_nonblank {
    for (@{$_[0]}) { return 1 if !/^\s*$/ }
    return 0;
}

#==============================================================================
# Tree mutators
#==============================================================================

# Add or update a metadata field on an entry. Returns 1 on update, 0 on add.
sub set_metadata_field {
    my ($entry, $key, $value) = @_;
    die "[CWF] ERROR: set_metadata_field: undefined entry\n" unless $entry;
    if (my $node = metadata_node($entry, $key)) {
        $node->{value} = $value;
        return 1;
    }
    push @{$entry->{metadata}}, { key => $key, value => $value, lineno => undef };
    return 0;
}

sub add_entry {
    my ($tree, $entry) = @_;
    push @{$tree->{entries}}, $entry;
    return $entry;
}

sub delete_entry {
    my ($tree, $idx) = @_;
    die "[CWF] ERROR: delete_entry: index $idx out of range (have "
        . scalar(@{$tree->{entries}}) . " entries)\n"
        if $idx < 0 || $idx >= @{$tree->{entries}};
    return splice(@{$tree->{entries}}, $idx, 1);
}

sub find_all_entries_by_slug {
    my ($tree, $slug) = @_;
    my @hits;
    for (my $i = 0; $i < @{$tree->{entries}}; $i++) {
        my $e = $tree->{entries}[$i];
        my $s = generate_slug($e->{title});
        push @hits, [$e, $i] if defined $s && $s eq $slug;
    }
    return @hits;
}

sub find_all_entries_by_title {
    my ($tree, $title) = @_;
    my @hits;
    for (my $i = 0; $i < @{$tree->{entries}}; $i++) {
        push @hits, [$tree->{entries}[$i], $i]
            if $tree->{entries}[$i]{title} eq $title;
    }
    return @hits;
}

sub find_changelog_entry_by_task_num {
    my ($tree, $num) = @_;
    for (my $i = 0; $i < @{$tree->{entries}}; $i++) {
        my $e = $tree->{entries}[$i];
        return ($e, $i) if defined $e->{task_num} && $e->{task_num} == $num;
    }
    return ();
}

# Find a subsection by name within an entry. Returns the subsection hashref or
# undef. Used by retired-subsection helpers; consumers that need different
# names (none yet) reuse the same lookup.
sub _find_subsection {
    my ($entry, $name) = @_;
    for my $s (@{$entry->{subsections}}) {
        return $s if $s->{name} eq $name;
    }
    return undef;
}

# Locate the `Retired Backlog Items` subsection. Creates it in canonical
# position (after Notable → else after Changes → else at end) if absent.
sub _ensure_retired_subsection {
    my ($entry) = @_;
    if (my $existing = _find_subsection($entry, 'Retired Backlog Items')) {
        return $existing;
    }
    my $sub = { name => 'Retired Backlog Items', lineno => undef, body_raw => [] };
    my @subs = @{$entry->{subsections}};
    my $insert_at;
    for my $anchor ('Notable', 'Changes') {
        for (my $i = 0; $i < @subs; $i++) {
            if ($subs[$i]{name} eq $anchor) { $insert_at = $i + 1; last; }
        }
        last if defined $insert_at;
    }
    $insert_at //= scalar @subs;
    splice(@{$entry->{subsections}}, $insert_at, 0, $sub);
    return $sub;
}

sub append_retired_block_tree {
    my ($entry, $title, $body_raw, $note) = @_;
    die "[CWF] ERROR: append_retired_block_tree: undefined entry\n" unless $entry;
    my $sub = _ensure_retired_subsection($entry);
    my @body = @{$body_raw // []};
    trim_blank_lines(\@body);

    my @block;
    push @block, "\n" if @{$sub->{body_raw}};
    push @block, "#### $title\n";
    push @block, "\n", @body if @body;
    push @block, "\n", "<!-- Note: $note -->\n" if defined $note && length $note;
    push @{$sub->{body_raw}}, @block;
    return 1;
}

#==============================================================================
# CHANGELOG bootstrap (mid-task `retire` against a not-yet-written entry)
#==============================================================================
#
# `bootstrap_changelog_entry` constructs a minimal `## Task N: <title>` node
# in-tree so `cmd_retire` can append its retired block in the same write pass.
# `resolve_task_title_from_dir` derives the title deterministically from
# `implementation-guide/N-<type>-<slug>/`; `<type>` is anchored against the
# project's `supported-task-types` set so a future hyphenated type token does
# not bleed into the slug capture. Both helpers die_user-style on any
# precondition failure; `cmd_retire` writes nothing on a failure path.

my @_SUPPORTED_TYPES;
sub _load_supported_types {
    return @_SUPPORTED_TYPES if @_SUPPORTED_TYPES;
    my $cfg = load_config()
        or die "[CWF] ERROR: backlog-manager: cannot load cwf-project.json\n";
    my @raw = @{ $cfg->{'supported-task-types'} // [] };
    @_SUPPORTED_TYPES = grep { /\A[a-z][a-z0-9-]{0,31}\z/ } @raw;
    die "[CWF] ERROR: backlog-manager: cwf-project.json has no usable "
      . "'supported-task-types' values\n" unless @_SUPPORTED_TYPES;
    return @_SUPPORTED_TYPES;
}

sub _scan_task_dirs {
    my ($task_num) = @_;
    my $root = find_git_root()
        or die "[CWF] ERROR: backlog-manager: not in a git repository\n";
    my $base = "$root/implementation-guide";
    opendir(my $dh, $base)
        or die "[CWF] ERROR: backlog-manager: cannot read $base/: $!\n";
    my @entries = grep { !/^\.\.?$/ } readdir $dh;
    closedir $dh;
    my $types = join('|', map { quotemeta } _load_supported_types());
    my $re = qr/\A\Q$task_num\E-(?:$types)-(.+)\z/;
    # Symlink-reject: cosmetic only (no I/O on these paths follows). Kept so a
    # later helper that reads inside the matched dir inherits the discipline.
    return grep { /$re/ && !-l "$base/$_" && -d _ } @entries;
}

sub resolve_task_title_from_dir {
    my ($task_num) = @_;
    die "[CWF] ERROR: backlog-manager: invalid task num '"
      . (defined $task_num ? $task_num : '<undef>') . "'\n"
        unless defined $task_num && $task_num =~ /^\d+$/;
    my @matches = _scan_task_dirs($task_num);
    if (@matches == 0) {
        die "[CWF] ERROR: backlog-manager: cannot bootstrap CHANGELOG entry "
          . "for Task $task_num: no directory matching "
          . "'implementation-guide/$task_num-*/' found\n";
    }
    if (@matches > 1) {
        my $list = join(', ', map { "'$_'" } @matches);
        die "[CWF] ERROR: backlog-manager: cannot bootstrap CHANGELOG entry "
          . "for Task $task_num: multiple directories match ($list); "
          . "manually create '## Task $task_num: <title>' in CHANGELOG.md "
          . "first, then retry\n";
    }
    my $types = join('|', map { quotemeta } _load_supported_types());
    (my $slug = $matches[0]) =~ s/\A\Q$task_num\E-(?:$types)-//;
    (my $title = $slug) =~ tr/-/ /;
    my $bad;
    if    (length($title) == 0)              { $bad = 'empty' }
    elsif ($title =~ /:/)                    { $bad = 'contains :' }
    elsif ($title =~ /[\x00-\x08\x0a-\x1f]/) { $bad = 'contains control character' }
    if ($bad) {
        die "[CWF] ERROR: backlog-manager: derived title '$title' violates "
          . "CHANGELOG heading constraints ($bad)\n";
    }
    return $title;
}

sub bootstrap_changelog_entry {
    my ($tree, $task_num, $title) = @_;
    my $entry = {
        type             => 'Task',
        task_num         => $task_num + 0,
        title            => $title,
        header_lineno    => undef,
        metadata         => [
            { key => 'Status', value => 'In Progress',       lineno => undef },
            { key => 'Impact', value => 'Task in progress.', lineno => undef },
        ],
        subsections      => [
            { name => 'Retired Backlog Items', lineno => undef, body_raw => [] },
        ],
        body_raw         => [],
        body_before_meta => 0,
    };
    unshift @{$tree->{entries}}, $entry;
    return $entry;
}

sub block_exists_in_retired_tree {
    my ($entry, $title) = @_;
    return 0 unless $entry;
    my $sub = _find_subsection($entry, 'Retired Backlog Items') or return 0;
    my $needle = lc($title);
    $needle =~ s/^\s+|\s+$//g;
    for my $line (@{$sub->{body_raw}}) {
        if ($line =~ /^####\s+(.*?)\s*$/) {
            my $cand = lc($1);
            $cand =~ s/^\s+|\s+$//g;
            return 1 if $cand eq $needle;
        }
    }
    return 0;
}

1;

=head1 NAME

CWF::Backlog - Parse, validate, and edit BACKLOG.md and CHANGELOG.md

=head1 SYNOPSIS

    use CWF::Backlog qw(
        parse_backlog_tree parse_changelog_tree
        serialize_tree write_tree
        validate_backlog_tree validate_changelog_tree
        metadata_get set_metadata_field
        find_all_entries_by_slug find_all_entries_by_title
    );

    my ($tree, $global_errors) = parse_backlog_tree('BACKLOG.md');
    my $errors = validate_backlog_tree($tree, 'BACKLOG.md');
    my @hits = find_all_entries_by_slug($tree, 'add-feature-x');
    my ($entry) = ($hits[0][0]);
    set_metadata_field($entry, 'Priority', 'High');
    write_tree('BACKLOG.md', $tree);

=head1 TREE SHAPE

A parsed file is `{ intro => [@raw_lines], entries => [...] }`. Each entry
holds:

  type             => 'Task' | 'Bug'           (BACKLOG)
  task_num         => integer | undef          (CHANGELOG only)
  title            => 'string'
  header_lineno    => N
  metadata         => [ { key, value, lineno }, ... ]   (H3 with `:`)
  subsections      => [ { name, lineno, body_raw }, ... ] (H3 without `:`)
  body_raw         => [ @raw_lines ]                    (entry body)
  body_before_meta => 0 | 1                             (Postel-liberal flag;
                                                         drives BACKLOG-007 /
                                                         CHANGELOG-004 warnings)

Entry boundaries: each `^## (Task|Bug):` (BACKLOG) or `^## Task N:`
(CHANGELOG) opens a new entry. No `---` separators; the heading itself is the
delimiter.

=head1 ROUND-TRIP

`parse_*_tree → serialize_tree` is byte-identical for canonical inputs (the
common case after migration to canonical form). For Postel-liberal inputs (e.g. body
appearing before metadata), the serialiser canonicalises — output differs
from input by design, and BACKLOG-007 / CHANGELOG-004 warn at validate time.

=head1 SEE ALSO

L<CWF::Common>, L<CWF::ArtefactHelpers>

=cut
