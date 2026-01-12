#!/usr/bin/perl -CDSL
#
# status-aggregator.pl - Calculate task progress from status markers
#
# Usage: status-aggregator.pl [task-path] [--format=json]
#
# Examples:
#   status-aggregator.pl                    # All tasks
#   status-aggregator.pl 1                  # Task 1 and descendants
#   status-aggregator.pl 1.1 --format=json  # Task 1.1 in JSON format
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - Task not found

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use File::Basename;

use CIG::TaskPath qw(normalize validate resolve find_base_dir);
use CIG::WorkflowFiles qw(list status_to_percent);
use CIG::MarkdownParser qw(extract_status);

# Parse arguments
my $task_path = "";
my $format = "markdown";

for my $arg (@ARGV) {
    if ($arg eq "--format=json") {
        $format = "json";
    } elsif ($arg !~ /^--/) {
        $task_path = $arg;
    }
}

# Calculate progress for a task directory
sub calculate_progress {
    my ($dir) = @_;

    my $files = list($dir);
    return 0 unless @$files;

    my @percentages;
    for my $file (@$files) {
        my $status = extract_status($file->{path});
        my $pct = status_to_percent($status);

        # Warn on unknown status
        if ($pct == 0 && $status ne "Unknown" && $status !~ /^(Backlog|To-Do)$/i) {
            my $filename = "$dir/" . $file->{name};
            print STDERR "Warning: Unknown status \"$status\" in $filename\n";
        }

        push @percentages, $pct;
    }

    return 0 unless @percentages;

    # Calculate progress using formula: MAX(IF(MAX(all) >= 25%) THEN 25% ELSE 0%, MIN(all status))
    my $max_pct = 0;
    my $min_pct = 100;

    for my $pct (@percentages) {
        $max_pct = $pct if $pct > $max_pct;
        $min_pct = $pct if $pct < $min_pct;
    }

    my $base_pct = ($max_pct >= 25) ? 25 : 0;
    my $progress = ($min_pct > $base_pct) ? $min_pct : $base_pct;

    return $progress;
}

# Build task tree recursively
sub build_tree {
    my ($base_path, $indent, $task_num) = @_;
    $indent //= "";
    $task_num //= "";

    my @output;

    # Build search pattern
    my $pattern;
    if ($task_num) {
        $pattern = "$base_path/*-*-*";  # Glob all, filter below for hierarchical matching
    } else {
        $pattern = "$base_path/[0-9]*-*-*";
    }

    for my $dir (sort glob($pattern)) {
        next unless -d $dir;

        # Filter for hierarchical task matches
        if ($task_num) {
            my $dir_name = (split('/', $dir))[-1];
            # Match task_num followed by dot (subtask) or hyphen (same level)
            # e.g., task_num="1" matches "1-*" and "1.1-*" but not "10-*"
            # Edge cases handled: 1 vs 10, 1.1 vs 1.10, 99 vs 999
            next unless $dir_name =~ /^${task_num}(?:\.|-)./;
        }

        # Extract task info from directory name
        my $dir_name = (split('/', $dir))[-1];
        next unless $dir_name =~ /^([0-9.]+)-([a-z]+)-(.+)$/;

        my ($num, $type, $slug) = ($1, $2, $3);

        # Calculate progress
        my $progress = calculate_progress($dir);

        # Determine status indicator
        my $indicator;
        if ($progress >= 100) {
            $indicator = "\x{2713}";      # ✓
        } elsif ($progress > 0) {
            $indicator = "\x{2699}\x{FE0F}";  # ⚙️
        } else {
            $indicator = "\x{25CB}";      # ○
        }

        push @output, {
            line => "${indent}${indicator} ${num} (${type}): ${slug} - ${progress}%",
            task => $dir_name,
            num => $num,
            type => $type,
            slug => $slug,
            progress => $progress,
        };

        # Recursively process subtasks
        my @subtasks = build_tree($dir, "${indent}  ", $num);
        push @output, @subtasks;
    }

    return @output;
}

# Main execution
my $base_dir = find_base_dir();
unless ($base_dir) {
    print STDERR "Error: Cannot find implementation-guide directory\n";
    exit 1;
}

# If specific task path provided, validate it
if ($task_path) {
    $task_path = normalize($task_path);
    unless (validate($task_path)) {
        print STDERR "Error: Invalid task path format: $task_path\n";
        exit 1;
    }

    my $result = resolve($task_path, $base_dir);
    unless ($result) {
        print STDERR "Error: Task not found: $task_path\n";
        exit 2;
    }

    # FIX 2: For nested tasks (depth > 1), search within parent directory
    # This enables direct nested queries like "status-aggregator.pl 1.4"
    # to work correctly by searching in the parent's subdirectories
    if ($result->{depth} > 1) {
        $base_dir = dirname($result->{full_path});
    }
}

# Build tree
my @tree = build_tree($base_dir, "", $task_path);

# Output
if ($format eq "json") {
    print "{\n  \"tasks\": [\n";
    for my $i (0 .. $#tree) {
        my $t = $tree[$i];
        print "    {";
        print "\"task\": \"$t->{task}\", ";
        print "\"num\": \"$t->{num}\", ";
        print "\"type\": \"$t->{type}\", ";
        print "\"progress\": $t->{progress}";
        print "}";
        print "," if $i < $#tree;
        print "\n";
    }
    print "  ]\n}\n";
} else {
    print "Task Progress:\n\n";
    for my $t (@tree) {
        print "$t->{line}\n";
    }
}

exit 0;
