package CWF::TaskPath;
#
# CWF::TaskPath - Task path operations for hierarchical task management
#
# Consolidates path normalization, validation, and resolution logic
# that was previously duplicated in hierarchy-resolver.sh and context-inheritance
#

use strict;
use warnings;
use utf8;
use Exporter 'import';
use File::Basename;
use Cwd 'abs_path';

our @EXPORT_OK = qw(
    normalize validate build_glob find_base_dir get_parent get_depth
    resolve_num resolve_branch resolve_path resolve
    format_dirname parse_dirname format_branch parse_branch
    task_exists branch_exists
    find_parent find_children find_siblings find_ancestors find_descendants
    find_first_free version_compare
);

# Find the implementation-guide base directory
# Searches from current directory or script location
#
# Returns: path to implementation-guide directory or undef
#
sub find_base_dir {
    my @search_paths = (
        'implementation-guide',
        '../implementation-guide',
        '../../implementation-guide',
    );

    # Try to find from git root
    my $git_root = `git rev-parse --show-toplevel 2>/dev/null`;
    chomp $git_root;
    if ($git_root && -d "$git_root/implementation-guide") {
        return "$git_root/implementation-guide";
    }

    # Fallback to relative paths
    for my $path (@search_paths) {
        return abs_path($path) if -d $path;
    }

    return undef;
}

# Normalize task path: extract final component from slash-separated path
# e.g., "1/1.1/1.1.1" -> "1.1.1"
# e.g., "1.1.1" -> "1.1.1" (already normalized)
#
# Args: $path - task path with slashes or dots
# Returns: normalized path (final component)
#
sub normalize {
    my ($path) = @_;
    # If path contains slashes, extract the final component
    if ($path =~ /\//) {
        my @parts = split(/\//, $path);
        return $parts[-1];
    }
    return $path;
}

# Validate task path format
# Must be numbers separated by dots: 1, 1.1, 1.1.1, etc.
#
# Args: $path - task path to validate
# Returns: 1 if valid, 0 if invalid
#
sub validate {
    my ($path) = @_;
    return $path =~ /^[0-9]+(\.[0-9]+)*$/;
}

# Build glob pattern for finding task directory
# Uses flat directory structure - all tasks at same level
# e.g., "1.1" -> "implementation-guide/1.1-*-*"
#
# Args: $path - normalized task path
#       $base_dir - base directory (optional, defaults to find_base_dir)
# Returns: glob pattern string
#
sub build_glob {
    my ($path, $base_dir) = @_;
    $base_dir //= find_base_dir() // 'implementation-guide';

    # Flat structure: all tasks at same level in base_dir
    return "$base_dir/$path-*-*";
}

# Resolve task by number to actual directory and metadata (FR1.1)
# Core resolution function - all other resolve_* functions delegate to this
#
# Uses iterative ancestor walk for nested directory hierarchy:
#   resolve_num("48.1.3") splits into ["48", "48.1", "48.1.3"]
#   and resolves each level inside the previous directory.
#   Top-level tasks (no dots) resolve with a single glob — unchanged.
#
# Args: $num - task number (e.g., "1.1", "33")
#       $base_dir - base directory (optional, defaults to find_base_dir())
# Returns: hashref with keys: full_path, num, type, slug, format, parent_path, depth
#          or undef if not found
#
sub resolve_num {
    my ($num, $base_dir) = @_;

    # Normalize and validate
    $num = normalize($num);
    unless (validate($num)) {
        return undef;
    }

    $base_dir //= find_base_dir();
    return undef unless $base_dir;

    # Iterative ancestor walk: resolve each level inside the previous
    my @parts = split(/\./, $num);
    my $current_dir = $base_dir;

    for my $i (0 .. $#parts) {
        my $ancestor_num = join(".", @parts[0 .. $i]);
        my $pattern = build_glob($ancestor_num, $current_dir);
        my @matches = glob($pattern);
        return undef unless @matches;
        $current_dir = $matches[0];
    }

    my $full_path = $current_dir;
    my $dir_name = basename($full_path);

    # Parse directory name: <num>-<type>-<slug>
    unless ($dir_name =~ /^([0-9.]+)-([a-z]+)-(.+)$/) {
        return undef;
    }

    my ($task_num, $type, $slug) = ($1, $2, $3);

    # Detect format (v1.0, v2.0, or v2.1)
    my $format = detect_format($full_path);

    # Calculate depth and parent
    my $depth = get_depth($task_num);
    my $parent_path = get_parent($task_num);

    return {
        full_path   => $full_path,
        num         => $task_num,
        type        => $type,
        slug        => $slug,
        format      => $format,
        parent_path => $parent_path,
        depth       => $depth,
    };
}

# Resolve task from git branch name (FR1.2)
# Delegates to resolve_num via parse_branch
#
# Args: $branch - git branch name (e.g., "feature/33-slug")
#       $base_dir - base directory (optional)
# Returns: Same hashref structure as resolve_num or undef
#
sub resolve_branch {
    my ($branch, $base_dir) = @_;

    my ($num, $type, $slug) = parse_branch($branch);
    return undef unless $num;

    return resolve_num($num, $base_dir);
}

# Resolve task from filesystem path/dirname (FR1.3)
# Delegates to resolve_num via parse_dirname
#
# Args: $path - filesystem dirname or full path (e.g., "33-feature-slug")
#       $base_dir - base directory (optional)
# Returns: Same hashref structure as resolve_num or undef
#
sub resolve_path {
    my ($path, $base_dir) = @_;

    my $dirname = basename($path);
    my ($num, $type, $slug) = parse_dirname($dirname);
    return undef unless $num;

    return resolve_num($num, $base_dir);
}

# Backward compatibility alias (FR1.4)
# Existing code using resolve() continues to work unchanged
#
sub resolve {
    my ($num, $base_dir) = @_;
    return resolve_num($num, $base_dir);
}

# Get parent task path
# e.g., "1.1.1" -> "1.1", "1.1" -> "1", "1" -> undef
#
# Args: $path - task path
# Returns: parent path or undef if top-level
#
sub get_parent {
    my ($path) = @_;
    $path = normalize($path);

    if ($path =~ /^(.+)\.[0-9]+$/) {
        return $1;
    }

    return undef;  # Top-level task
}

# Get task depth (nesting level)
# e.g., "1" -> 1, "1.1" -> 2, "1.1.1" -> 3
#
# Args: $path - task path
# Returns: depth as integer
#
sub get_depth {
    my ($path) = @_;
    $path = normalize($path);

    my @parts = split(/\./, $path);
    return scalar(@parts);
}

# Detect task format version from headers and files
# Headers are authoritative (Template Version field), with file-based fallback
# Warns if header and file-based detection disagree
#
# Args: $full_path - full path to task directory
# Returns: "1.0", "2.0", or "2.1"
#
sub detect_format {
    my ($full_path) = @_;

    # Step 1: Read header version (authoritative)
    my $header_version = undef;
    for my $file (glob("$full_path/*.md")) {
        open(my $fh, '<', $file) or next;
        while (my $line = <$fh>) {
            if ($line =~ /^\- \*\*Template Version\*\*:\s*([0-9.]+)/) {
                $header_version = $1;
                close($fh);
                last;
            }
            last if $line =~ /^## / && $line !~ /^## Task Reference/;
        }
        last if $header_version;
    }

    # Step 2: File-based detection (fallback/validation)
    my $file_version;
    if (-f "$full_path/e-testing-plan.md" || -f "$full_path/f-implementation-exec.md") {
        $file_version = "2.1";
    } elsif (-f "$full_path/a-plan.md" || -f "$full_path/d-implementation.md") {
        $file_version = "2.0";
    } elsif (-f "$full_path/plan.md") {
        $file_version = "1.0";
    } else {
        $file_version = "1.0";
    }

    # Step 3: Warn if mismatch
    if ($header_version && $header_version ne $file_version) {
        warn "WARNING: Version mismatch in $full_path\n";
        warn "  Header says: v$header_version\n";
        warn "  Files indicate: v$file_version\n";
        warn "  Using header version (v$header_version)\n";
        warn "  Consider running migration to sync files\n\n";
    }

    # Step 4: Return header if present, else file-based
    return $header_version || $file_version;
}

# ============================================================================
# Format Converter Functions (FR3)
# ============================================================================

# Format directory name from components
# e.g., (32, "feature", "task-tracking") -> "32-feature-task-tracking"
#
# Args: $num, $type, $slug
# Returns: formatted directory name string
#
sub format_dirname {
    my ($num, $type, $slug) = @_;
    return undef unless defined $num && defined $type && defined $slug;
    return "$num-$type-$slug";
}

# Parse directory name into components
# e.g., "32-feature-task-tracking" -> (32, "feature", "task-tracking")
#
# Args: $dirname - directory name string
# Returns: list ($num, $type, $slug) or empty list if invalid
#
sub parse_dirname {
    my ($dirname) = @_;
    return () unless defined $dirname;

    if ($dirname =~ /^(\d+(?:\.\d+)*)-(\w+)-(.+)$/) {
        return ($1, $2, $3);
    }

    return ();
}

# Format git branch name from components
# e.g., (32, "feature", "task-tracking") -> "feature/32-task-tracking"
#
# Args: $num, $type, $slug
# Returns: formatted branch name string
#
sub format_branch {
    my ($num, $type, $slug) = @_;
    return undef unless defined $num && defined $type && defined $slug;
    return "$type/$num-$slug";
}

# Parse git branch name into components
# e.g., "feature/32-task-tracking" -> (32, "feature", "task-tracking")
#
# Args: $branch - git branch name string
# Returns: list ($num, $type, $slug) or empty list if invalid
#
sub parse_branch {
    my ($branch) = @_;
    return () unless defined $branch;

    if ($branch =~ /^(\w+)\/(\d+(?:\.\d+)*)-(.+)$/) {
        return ($2, $1, $3);  # Note: num is $2, type is $1
    }

    return ();
}

# ============================================================================
# Tree Traversal Functions (FR4) - Return hashrefs for rich metadata
# ============================================================================

# Find parent task (returns hashref with full metadata)
# e.g., "3.1.2" -> { num => "3.1", type => "feature", ... }
#
# Args: $num - task number, $base_dir - optional base directory
# Returns: hashref or undef if top-level
#
sub find_parent {
    my ($num, $base_dir) = @_;

    # Only find parent if task itself exists
    return undef unless task_exists($num, $base_dir);

    my $parent_num = get_parent($num);
    return undef unless defined $parent_num;

    return resolve($parent_num, $base_dir);
}

# Find direct children (returns list of hashrefs)
# e.g., "3.1" -> ({ num => "3.1.1", ... }, { num => "3.1.2", ... })
#
# Args: $num - task number, $base_dir - optional base directory
# Returns: list of hashrefs (sorted by num)
#
sub find_children {
    my ($num, $base_dir) = @_;

    $base_dir //= find_base_dir();
    return () unless $base_dir;

    # Resolve the task to find its actual directory, then scan inside it
    my $task = resolve_num($num, $base_dir);
    my $search_dir = $task ? $task->{full_path} : $base_dir;
    my @child_dirs = glob("$search_dir/$num.*-*-*");

    # Resolve each child directory to hashref and filter to immediate children only
    my @children;
    for my $dir (@child_dirs) {
        my $dirname = basename($dir);
        my ($child_num) = parse_dirname($dirname);
        next unless $child_num;

        # Verify this is an immediate child (parent must be $num)
        my $parent_num = get_parent($child_num);
        next unless defined $parent_num && $parent_num eq $num;

        my $child_info = resolve($child_num, $base_dir);
        push @children, $child_info if $child_info;
    }

    # Sort by num
    @children = sort { version_compare($a->{num}, $b->{num}) } @children;

    return @children;
}

# Find siblings (returns list of hashrefs, excluding self)
# e.g., "3.1.2" -> ({ num => "3.1.1", ... }, { num => "3.1.3", ... })
#
# Args: $num - task number, $base_dir - optional base directory
# Returns: list of hashrefs
#
sub find_siblings {
    my ($num, $base_dir) = @_;

    $base_dir //= find_base_dir();
    return () unless $base_dir;

    my $parent = find_parent($num, $base_dir);

    my @siblings;
    if ($parent) {
        # Has parent: get parent's children
        @siblings = find_children($parent->{num}, $base_dir);
    } else {
        # Top-level: find all top-level tasks
        my @all_dirs = glob("$base_dir/*-*-*");
        for my $dir (@all_dirs) {
            my $dirname = basename($dir);
            my ($task_num) = parse_dirname($dirname);
            next unless $task_num;
            next if $task_num =~ /\./;  # Skip non-top-level
            my $task_info = resolve($task_num, $base_dir);
            push @siblings, $task_info if $task_info;
        }
        @siblings = sort { version_compare($a->{num}, $b->{num}) } @siblings;
    }

    # Filter out self
    return grep { $_->{num} ne $num } @siblings;
}

# Find all ancestors from parent to root (returns list of hashrefs)
# e.g., "3.1.2" -> ({ num => "3.1", ... }, { num => "3", ... })
#
# Args: $num - task number, $base_dir - optional base directory
# Returns: list of hashrefs (parent to root order)
#
sub find_ancestors {
    my ($num, $base_dir) = @_;

    my @ancestors;
    my $current = find_parent($num, $base_dir);

    while ($current) {
        push @ancestors, $current;
        $current = find_parent($current->{num}, $base_dir);
    }

    return @ancestors;
}

# Find all descendants recursively (returns list of hashrefs in depth-first order)
# e.g., "3" -> ({ num => "3.1", ... }, { num => "3.1.1", ... }, { num => "3.2", ... })
#
# Args: $num - task number, $base_dir - optional base directory
# Returns: list of hashrefs (depth-first pre-order)
#
sub find_descendants {
    my ($num, $base_dir) = @_;

    my @children = find_children($num, $base_dir);
    my @result;

    # Depth-first pre-order: process each child then its descendants
    for my $child (@children) {
        push @result, $child;
        push @result, find_descendants($child->{num}, $base_dir);
    }

    return @result;
}

# ============================================================================
# Allocation Functions (FR2, FR3.5)
# ============================================================================

# Check if task exists (FR2.1)
# Existence predicate - use negatively for availability check
#
# Args: $num - task number, $base_dir - optional base directory (defaults to find_base_dir())
# Returns: 1 if task directory exists, 0 if not found
# Usage: if (not task_exists($num)) { # available for creation }
#
sub task_exists {
    my ($num, $base_dir) = @_;

    my $task = resolve_num($num, $base_dir);
    return $task ? 1 : 0;
}

# Check if git branch exists (FR2.2)
# Existence predicate - use negatively for availability check
#
# Args: $branch - branch name
# Returns: 1 if branch exists in current worktree, 0 if not found
# Usage: if (not branch_exists($branch)) { # available for creation }
#
sub branch_exists {
    my ($branch) = @_;

    my $output = `git branch --list '$branch' 2>/dev/null`;
    chomp $output;

    return $output eq '' ? 0 : 1;
}

# Find first available task number at relative depth
# Depth is relative to current task: 0 = sibling, 1 = child, -1 = uncle, etc.
# For top-level: caller computes find_first_free(-1 * $current->{depth})
#
# Args: $depth - relative depth (integer), $num - anchor task (optional, defaults to current from stack)
# Returns: string task number or undef on error
#
sub find_first_free {
    my ($depth, $num, $base_dir) = @_;

    $depth //= 0;  # Default to sibling
    $base_dir //= find_base_dir();
    return undef unless $base_dir;

    # Resolve anchor task
    my $anchor;
    if (defined $num) {
        $anchor = resolve($num, $base_dir);
    } else {
        # Read from stack (.git/cwf-current-task)
        my $stack_file = `git rev-parse --git-dir 2>/dev/null`;
        chomp $stack_file;
        $stack_file .= "/cwf-current-task" if $stack_file;

        if ($stack_file && -f $stack_file) {
            open(my $fh, '<', $stack_file) or return undef;
            my $current_num = <$fh>;
            chomp $current_num if $current_num;
            close($fh);
            $anchor = resolve($current_num, $base_dir) if $current_num;
        }
    }

    return undef unless $anchor;

    # Calculate target level based on relative depth
    my $target_num;
    my $current_depth = $anchor->{depth};
    my $target_depth = $current_depth + $depth;

    # Validate target depth
    return undef if $target_depth < 1;  # Can't go above top-level
    return undef if $depth < 0 && abs($depth) > $current_depth - 1;  # Too many levels up

    # Build target number prefix
    if ($depth == 0) {
        # Sibling: same parent
        my $parent_num = get_parent($anchor->{num});
        $target_num = $parent_num ? "$parent_num." : "";
    } elsif ($depth > 0) {
        # Child/descendant
        $target_num = $anchor->{num} . ".";
    } else {
        # Uncle/ancestor's sibling: go up abs($depth) levels, then find sibling
        my $target_ancestor = $anchor->{num};
        for (1..abs($depth)) {
            $target_ancestor = get_parent($target_ancestor);
            return undef unless defined $target_ancestor;
        }
        my $parent_of_target = get_parent($target_ancestor);
        $target_num = $parent_of_target ? "$parent_of_target." : "";
    }

    # Find first free number at target level
    my @existing;
    if ($target_num eq "") {
        # Top-level: find all tasks with depth 1
        my @all_dirs = glob("$base_dir/*-*-*");
        for my $dir (@all_dirs) {
            my $dirname = basename($dir);
            my ($task_num) = parse_dirname($dirname);
            next unless $task_num;
            next if $task_num =~ /\./;  # Skip non-top-level
            push @existing, $task_num;
        }
    } else {
        # Has parent prefix: get children
        my $parent_num = $target_num;
        $parent_num =~ s/\.$//;  # Remove trailing dot
        @existing = map { $_->{num} } find_children($parent_num, $base_dir);
    }

    # Extract final component numbers and find first gap
    my @nums = sort { $a <=> $b }
               map { /(\d+)$/; $1 }
               @existing;

    my $next = 1;
    for my $n (@nums) {
        last if $n > $next;
        $next = $n + 1 if $n == $next;
    }

    return $target_num . $next;
}

# Helper: Compare version-like numbers (for sorting hierarchical task numbers)
# e.g., "3.1.10" comes after "3.1.2"
#
sub version_compare {
    my ($a, $b) = @_;

    my @a_parts = split(/\./, $a);
    my @b_parts = split(/\./, $b);

    my $max = (@a_parts > @b_parts) ? @a_parts : @b_parts;

    for my $i (0..$max-1) {
        my $a_part = $a_parts[$i] // 0;
        my $b_part = $b_parts[$i] // 0;

        return $a_part <=> $b_part if $a_part != $b_part;
    }

    return 0;
}

1;
