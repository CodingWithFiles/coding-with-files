package CIG::WorkflowFiles;
#
# CIG::WorkflowFiles - Workflow file operations for task management
#
# Consolidates workflow file listing, version detection, and status mapping
# that was previously duplicated in status-aggregator.sh and context-inheritance.pl
#

use strict;
use warnings;
use Exporter 'import';
use File::Basename;
use JSON::PP;

our @EXPORT_OK = qw(list get_template_version status_to_percent load_config workflow_file_mappings);

# Workflow file mappings for v1.0 and v2.0 formats
our @WORKFLOW_MAPPINGS = (
    { old => 'plan.md',           new => 'a-plan.md' },
    { old => 'requirements.md',   new => 'b-requirements.md' },
    { old => 'design.md',         new => 'c-design.md' },
    { old => 'implementation.md', new => 'd-implementation.md' },
    { old => 'testing.md',        new => 'e-testing.md' },
    { old => 'rollout.md',        new => 'f-rollout.md' },
    { old => 'maintenance.md',    new => 'g-maintenance.md' },
    { old => '',                  new => 'h-retrospective.md' },  # v2.0 only
);

# Default status to percentage mapping
our %DEFAULT_STATUS_MAP = (
    'Backlog'     => 0,
    'backlog'     => 0,
    'To-Do'       => 0,
    'to-do'       => 0,
    'In Progress' => 25,
    'in progress' => 25,
    'Implemented' => 50,
    'implemented' => 50,
    'Testing'     => 75,
    'testing'     => 75,
    'Finished'    => 100,
    'finished'    => 100,
);

# Cached config and status map
my $_config_cache;
my $_status_map_cache;

# Get workflow file mappings
#
# Returns: arrayref of hashrefs with 'old' and 'new' keys
#
sub workflow_file_mappings {
    return \@WORKFLOW_MAPPINGS;
}

# List workflow files in a task directory
# Returns files that exist, preferring v2.0 format over v1.0
#
# Args: $task_dir - path to task directory
# Returns: arrayref of file paths that exist
#
sub list {
    my ($task_dir) = @_;
    my @files;

    for my $mapping (@WORKFLOW_MAPPINGS) {
        my $file_path;
        my $file_name;

        # Prefer v2.0 format, fall back to v1.0
        if ($mapping->{new} && -f "$task_dir/$mapping->{new}") {
            $file_path = "$task_dir/$mapping->{new}";
            $file_name = $mapping->{new};
        } elsif ($mapping->{old} && -f "$task_dir/$mapping->{old}") {
            $file_path = "$task_dir/$mapping->{old}";
            $file_name = $mapping->{old};
        } else {
            next;
        }

        push @files, {
            path => $file_path,
            name => $file_name,
        };
    }

    return \@files;
}

# Get template version from a workflow file
#
# Args: $file_path - path to workflow file
# Returns: version string ("1.0" or "2.0")
#
sub get_template_version {
    my ($file_path) = @_;

    open(my $fh, '<', $file_path) or return "1.0";

    while (my $line = <$fh>) {
        if ($line =~ /^\- \*\*Template Version\*\*:\s*([0-9.]+)/) {
            close($fh);
            return $1;
        }
        # Stop searching after Task Reference section
        last if $line =~ /^## / && $line !~ /^## Task Reference/;
    }

    close($fh);
    return "1.0";  # Default for files without version marker
}

# Convert status to percentage
#
# Args: $status - status string (e.g., "In Progress", "Finished")
# Returns: percentage (0-100) or 0 if unknown
#
sub status_to_percent {
    my ($status) = @_;

    # Load status map if not cached
    unless ($_status_map_cache) {
        my $config = load_config();
        if ($config && $config->{workflow} && $config->{workflow}{'status-values'}) {
            $_status_map_cache = $config->{workflow}{'status-values'};
        } else {
            $_status_map_cache = \%DEFAULT_STATUS_MAP;
        }
    }

    # Look up status (try exact match first, then case-insensitive)
    if (exists $_status_map_cache->{$status}) {
        return $_status_map_cache->{$status};
    }

    # Try lowercase
    my $lower = lc($status);
    if (exists $_status_map_cache->{$lower}) {
        return $_status_map_cache->{$lower};
    }

    # Unknown status
    return 0;
}

# Load CIG configuration from cig-project.json
#
# Returns: hashref of config or undef
#
sub load_config {
    return $_config_cache if $_config_cache;

    # Find config file
    my @search_paths;

    # Try git root first
    my $git_root = `git rev-parse --show-toplevel 2>/dev/null`;
    chomp $git_root;

    if ($git_root) {
        push @search_paths,
            "$git_root/implementation-guide/cig-project.json",
            "$git_root/cig-project.json",
            "$git_root/.cig/cig-project.json";
    }

    # Add relative paths
    push @search_paths,
        'implementation-guide/cig-project.json',
        'cig-project.json',
        '.cig/cig-project.json';

    for my $path (@search_paths) {
        if (-f $path) {
            eval {
                open(my $fh, '<', $path) or die;
                local $/;
                my $json = <$fh>;
                close($fh);
                $_config_cache = decode_json($json);
            };
            return $_config_cache if $_config_cache;
        }
    }

    return undef;
}

1;
