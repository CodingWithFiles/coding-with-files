package CIG::VersionRouter;
#
# CIG::VersionRouter - Version detection and routing for CIG command helpers
#
# Centralizes version detection and routing logic that was previously duplicated
# across inheritance, status, and create modules.
#

use strict;
use warnings;
use Exporter 'import';
use FindBin;
use CIG::TaskPath qw(resolve);

our @EXPORT_OK = qw(detect_version route_to_version get_script_dir);

# Detect version from task argument
# Args: $task_arg (task path like "41" or "1.2.3", or empty)
# Returns: "v2.0" or "v2.1"
sub detect_version {
    my $task_arg = shift || '';

    # If specific task provided, detect its format
    if ($task_arg && $task_arg =~ /^\d+(\.\d+)*$/) {
        my $result = CIG::TaskPath::resolve($task_arg);
        return "v$result->{format}" if $result;
    }

    # No task specified: default to v2.0
    return 'v2.0';
}

# Route to version-specific script
# Args: $base_name (e.g., "status-aggregator"), $version (e.g., "v2.1"), @args
# Returns: Does not return (execs script)
sub route_to_version {
    my ($base_name, $version, @args) = @_;
    my $script_dir = get_script_dir();
    my $script_path = "$script_dir/$base_name-$version";

    exec($script_path, @args) or die "Failed to exec $script_path: $!\n";
}

# Get command-helpers directory path
# Returns: Absolute path to .cig/scripts/command-helpers/
sub get_script_dir {
    # Module is in context-manager.d/, parent is command-helpers/
    return "$FindBin::Bin/..";
}

1;

=head1 NAME

CIG::VersionRouter - Version detection and routing for CIG command helpers

=head1 SYNOPSIS

    use CIG::VersionRouter qw(detect_version route_to_version);

    my $version = detect_version($ARGV[0]);  # "v2.0" or "v2.1"
    route_to_version("status-aggregator", $version, @ARGV);

=head1 DESCRIPTION

Centralized version detection and routing logic for CIG command helper modules.
Eliminates 108 lines of duplication across inheritance, status, and create modules.

=head1 FUNCTIONS

=head2 detect_version($task_arg)

Detects task format version from task path argument.

Args: $task_arg (task path like "41" or "1.2.3", or empty)
Returns: "v2.0" or "v2.1"

If a specific task is provided, resolves the task path to determine its format.
If no task is provided or resolution fails, defaults to "v2.0" for backward compatibility.

=head2 route_to_version($base_name, $version, @args)

Execs version-specific script with provided arguments.

Args: $base_name (e.g., "status-aggregator"), $version (e.g., "v2.1"), @args
Returns: Does not return (execs script)

Constructs the full path to the version-specific script and execs it with the
provided arguments. Dies if exec fails.

=head2 get_script_dir()

Returns absolute path to command-helpers directory.

Returns: Path to .cig/scripts/command-helpers/

Calculates the path based on the assumption that modules are in subdirectories
of command-helpers/ (e.g., context-manager.d/, workflow-manager.d/).

=head1 AUTHOR

Code Implementation Guide (CIG) System

=head1 SEE ALSO

L<CIG::TaskPath>, L<CIG::Common>

=cut
