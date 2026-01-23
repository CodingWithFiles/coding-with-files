package CIG::TaskPath;
#
# CIG::TaskPath - Task path operations for hierarchical task management
#
# Consolidates path normalization, validation, and resolution logic
# that was previously duplicated in hierarchy-resolver.sh and context-inheritance
#

use strict;
use warnings;
use Exporter 'import';
use File::Basename;
use Cwd 'abs_path';

our @EXPORT_OK = qw(normalize validate build_glob resolve get_parent get_depth find_base_dir);

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
# e.g., "1.1" -> "implementation-guide/1-*-*/1.1-*-*"
#
# Args: $path - normalized task path
#       $base_dir - base directory (optional, defaults to find_base_dir)
# Returns: glob pattern string
#
sub build_glob {
    my ($path, $base_dir) = @_;
    $base_dir //= find_base_dir() // 'implementation-guide';

    my @parts = split(/\./, $path);
    my $pattern = $base_dir;

    for my $i (0 .. $#parts) {
        my $component;
        if ($i == 0) {
            $component = "$parts[0]-*-*";
        } else {
            my $dot_path = join(".", @parts[0..$i]);
            $component = "$dot_path-*-*";
        }
        $pattern .= "/$component";
    }

    return $pattern;
}

# Resolve task path to actual directory and metadata
#
# Args: $path - task path (e.g., "1.1")
#       $base_dir - base directory (optional)
# Returns: hashref with keys: full_path, num, type, slug, format, parent_path, depth
#          or undef if not found
#
sub resolve {
    my ($path, $base_dir) = @_;

    # Normalize and validate
    $path = normalize($path);
    unless (validate($path)) {
        return undef;
    }

    $base_dir //= find_base_dir();
    return undef unless $base_dir;

    # Build and execute glob
    my $pattern = build_glob($path, $base_dir);
    my @matches = glob($pattern);

    return undef unless @matches;

    my $full_path = $matches[0];
    my $dir_name = basename($full_path);

    # Parse directory name: <num>-<type>-<slug>
    unless ($dir_name =~ /^([0-9.]+)-([a-z]+)-(.+)$/) {
        return undef;
    }

    my ($num, $type, $slug) = ($1, $2, $3);

    # Detect format (v1.0 or v2.0)
    my $format = "1.0";
    if (-f "$full_path/a-plan.md" || -f "$full_path/d-implementation.md") {
        $format = "2.0";
    }

    # Calculate depth and parent
    my $depth = get_depth($num);
    my $parent_path = get_parent($num);

    return {
        full_path   => $full_path,
        num         => $num,
        type        => $type,
        slug        => $slug,
        format      => $format,
        parent_path => $parent_path,
        depth       => $depth,
    };
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

1;
