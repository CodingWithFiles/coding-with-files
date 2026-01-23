#!/usr/bin/perl -CDSL
#
# hierarchy-resolver.pl - Resolve task paths to full directory paths
#
# Usage: hierarchy-resolver.pl <task-path> [--format=json]
#
# Examples:
#   hierarchy-resolver.pl 1
#   hierarchy-resolver.pl 1.1
#   hierarchy-resolver.pl 1/1.1/1.1.1
#   hierarchy-resolver.pl 3.2 --format=json
#
# Exit codes:
#   0 - Success
#   1 - Invalid path format
#   2 - Task not found
#   3 - Missing required argument

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";

use CIG::TaskPath qw(normalize validate resolve);

# Parse arguments
if (@ARGV < 1) {
    print STDERR "Error: Missing required argument <task-path>\n";
    print STDERR "Usage: hierarchy-resolver.pl <task-path> [--format=json]\n";
    exit 3;
}

my $task_path = $ARGV[0];
my $format = "markdown";

if (@ARGV > 1 && $ARGV[1] eq "--format=json") {
    $format = "json";
}

# Normalize and validate
$task_path = normalize($task_path);

unless (validate($task_path)) {
    print STDERR "Error: Invalid task path format: $task_path\n";
    print STDERR "Expected format: <num> or <num>.<num> or <num>/<num>/<num>\n";
    exit 1;
}

# Resolve task path
my $result = resolve($task_path);

unless ($result) {
    print STDERR "Error: Task not found: $task_path\n";
    exit 2;
}

# Output result
if ($format eq "json") {
    my $parent = $result->{parent_path} // "";
    print qq({
  "full_path": "$result->{full_path}",
  "format": "$result->{format}",
  "task_num": "$result->{num}",
  "task_type": "$result->{type}",
  "task_slug": "$result->{slug}",
  "parent_path": "$parent",
  "depth": $result->{depth}
}
);
} else {
    print "Task: $result->{num} ($result->{type})\n";
    print "Path: $result->{full_path}\n";
    print "Format: v$result->{format}\n";
    if ($result->{parent_path}) {
        print "Parent: $result->{parent_path}\n";
    }
}

exit 0;
