#!/usr/bin/env perl
#
# context-inheritance.pl - Extract parent task context with headers, line ranges, and status
#
# Usage: context-inheritance.pl <task-path> [--format=json]
#
# Examples:
#   context-inheritance.pl 1.1.1
#   context-inheritance.pl 1/1.1/1.1.1
#   context-inheritance.pl 1.1 --format=json
#
# Exit codes:
#   0 - Success
#   1 - Invalid path
#   2 - Task not found
#   3 - No parent tasks (top-level task)

use strict;
use warnings;
use File::Basename;
use File::Spec;
use Cwd 'abs_path';

# Parse arguments
if (@ARGV < 1) {
    print STDERR "Error: Missing required argument <task-path>\n";
    print STDERR "Usage: context-inheritance.pl <task-path> [--format=json]\n";
    exit 1;
}

my $task_path = $ARGV[0];
my $format = "markdown";

if (@ARGV > 1 && $ARGV[1] eq "--format=json") {
    $format = "json";
}

# Normalize task path (replace slashes with dots)
$task_path =~ s/\//./g;

# Validate task path format
unless ($task_path =~ /^[0-9]+(\.[0-9]+)*$/) {
    print STDERR "Error: Invalid task path format: $task_path\n";
    exit 1;
}

# Find the task directory
my @path_parts = split(/\./, $task_path);
my $search_pattern = "implementation-guide";

foreach my $i (0 .. $#path_parts) {
    my $component;
    if ($i == 0) {
        $component = "$path_parts[0]-*-*";
    } else {
        my $dot_path = join(".", @path_parts[0..$i]);
        $component = "$dot_path-*-*";
    }
    $search_pattern .= "/$component";
}

# Find matching directory
my @matches = glob($search_pattern);

if (@matches == 0) {
    print STDERR "Error: Task not found: $task_path\n";
    exit 2;
}

my $task_dir = $matches[0];

# Extract parent paths (all except the last component)
if (@path_parts <= 1) {
    print STDERR "Error: No parent tasks found (this is a top-level task)\n";
    exit 3;
}

# Build list of parent tasks
my @parent_tasks;
for my $depth (1 .. $#path_parts) {
    my @parent_parts = @path_parts[0 .. $depth-1];
    my $parent_num = join(".", @parent_parts);

    # Find parent directory
    my $parent_search = "implementation-guide";
    foreach my $i (0 .. $#parent_parts) {
        my $component;
        if ($i == 0) {
            $component = "$parent_parts[0]-*-*";
        } else {
            my $dot_path = join(".", @parent_parts[0..$i]);
            $component = "$dot_path-*-*";
        }
        $parent_search .= "/$component";
    }

    my @parent_matches = glob($parent_search);
    if (@parent_matches > 0) {
        push @parent_tasks, {
            num => $parent_num,
            dir => $parent_matches[0]
        };
    }
}

# Workflow files to check (both old and new format)
my @workflow_files = (
    {old => 'plan.md', new => 'a-plan.md'},
    {old => 'requirements.md', new => 'b-requirements.md'},
    {old => 'design.md', new => 'c-design.md'},
    {old => 'implementation.md', new => 'd-implementation.md'},
    {old => 'testing.md', new => 'e-testing.md'},
    {old => 'rollout.md', new => 'f-rollout.md'},
    {old => 'maintenance.md', new => 'g-maintenance.md'},
    {old => '', new => 'h-retrospective.md'}  # retrospective is new format only
);

# Function to extract headers with line numbers
sub extract_headers {
    my ($file_path) = @_;
    my @headers;

    open(my $fh, '<', $file_path) or return @headers;

    my $line_num = 0;
    while (my $line = <$fh>) {
        $line_num++;
        if ($line =~ /^(#{1,6})\s+(.+)$/) {
            my $level = length($1);
            my $title = $2;
            $title =~ s/\s+$//;  # trim trailing whitespace

            push @headers, {
                level => $level,
                title => $title,
                line => $line_num
            };
        }
    }

    close($fh);
    return @headers;
}

# Function to calculate section boundaries
sub calculate_boundaries {
    my ($headers_ref, $total_lines) = @_;
    my @headers = @$headers_ref;
    my @sections;

    for my $i (0 .. $#headers) {
        my $header = $headers[$i];
        my $start_line = $header->{line};
        my $end_line;

        # Find next header at same or higher level
        my $found_end = 0;
        for my $j ($i+1 .. $#headers) {
            if ($headers[$j]->{level} <= $header->{level}) {
                $end_line = $headers[$j]->{line} - 1;
                $found_end = 1;
                last;
            }
        }

        # If no next header, use end of file
        $end_line = $total_lines unless $found_end;

        push @sections, {
            title => $header->{title},
            level => $header->{level},
            start => $start_line,
            end => $end_line
        };
    }

    return @sections;
}

# Function to parse status marker from file
sub parse_status {
    my ($file_path) = @_;

    open(my $fh, '<', $file_path) or return "Unknown";

    while (my $line = <$fh>) {
        # Pattern 1: ## Status: <status>
        if ($line =~ /^##\s+Status:\s+(.+)$/i) {
            close($fh);
            my $status = $1;
            $status =~ s/\s+$//;
            return $status;
        }
        # Pattern 2: **Status**: <status>
        if ($line =~ /\*\*Status\*\*:\s+(.+)$/i) {
            close($fh);
            my $status = $1;
            $status =~ s/\s+$//;
            return $status;
        }
    }

    close($fh);
    return "Unknown";
}

# Function to count lines in file
sub count_lines {
    my ($file_path) = @_;
    open(my $fh, '<', $file_path) or return 0;
    my $count = 0;
    $count++ while <$fh>;
    close($fh);
    return $count;
}

# Process each parent task
my @parent_data;

foreach my $parent (@parent_tasks) {
    my $parent_dir = $parent->{dir};
    my $parent_name = basename($parent_dir);

    my @files_data;

    # Check each workflow file
    foreach my $wf (@workflow_files) {
        my $file_path;
        my $file_name;

        # Check new format first, then old format
        if ($wf->{new} && -f "$parent_dir/$wf->{new}") {
            $file_path = "$parent_dir/$wf->{new}";
            $file_name = $wf->{new};
        } elsif ($wf->{old} && -f "$parent_dir/$wf->{old}") {
            $file_path = "$parent_dir/$wf->{old}";
            $file_name = $wf->{old};
        } else {
            next;  # File doesn't exist, skip
        }

        # Extract status
        my $status = parse_status($file_path);

        # Extract headers
        my @headers = extract_headers($file_path);

        # Calculate boundaries
        my $total_lines = count_lines($file_path);
        my @sections = calculate_boundaries(\@headers, $total_lines);

        push @files_data, {
            name => $file_name,
            path => $file_path,
            status => $status,
            sections => \@sections
        };
    }

    push @parent_data, {
        name => $parent_name,
        num => $parent->{num},
        files => \@files_data
    };
}

# Output results
if ($format eq "json") {
    # JSON output
    print "{\n";
    print "  \"parent_tasks\": [\n";

    for my $i (0 .. $#parent_data) {
        my $parent = $parent_data[$i];
        print "    {\n";
        print "      \"task\": \"$parent->{name}\",\n";
        print "      \"task_num\": \"$parent->{num}\",\n";
        print "      \"files\": [\n";

        my @files = @{$parent->{files}};
        for my $j (0 .. $#files) {
            my $file = $files[$j];
            print "        {\n";
            print "          \"name\": \"$file->{name}\",\n";
            print "          \"path\": \"$file->{path}\",\n";
            print "          \"status\": \"$file->{status}\",\n";
            print "          \"sections\": [\n";

            my @sections = @{$file->{sections}};
            for my $k (0 .. $#sections) {
                my $sect = $sections[$k];
                my $limit = $sect->{end} - $sect->{start} + 1;
                print "            {\n";
                print "              \"title\": \"$sect->{title}\",\n";
                print "              \"start_line\": $sect->{start},\n";
                print "              \"end_line\": $sect->{end},\n";
                print "              \"read_offset\": $sect->{start},\n";
                print "              \"read_limit\": $limit\n";
                print "            }";
                print "," if $k < $#sections;
                print "\n";
            }

            print "          ]\n";
            print "        }";
            print "," if $j < $#files;
            print "\n";
        }

        print "      ]\n";
        print "    }";
        print "," if $i < $#parent_data;
        print "\n";
    }

    print "  ]\n";
    print "}\n";
} else {
    # Markdown output
    print "## Parent Context\n\n";

    foreach my $parent (@parent_data) {
        print "### Parent: $parent->{name}\n\n";

        foreach my $file (@{$parent->{files}}) {
            print "**$file->{name}** [Status: $file->{status}] (`$file->{path}`):\n";

            foreach my $sect (@{$file->{sections}}) {
                my $limit = $sect->{end} - $sect->{start} + 1;
                print "- $sect->{title} (L$sect->{start}-$sect->{end}, Read: offset=$sect->{start} limit=$limit)\n";
            }

            print "\n";
        }
    }
}

exit 0;
