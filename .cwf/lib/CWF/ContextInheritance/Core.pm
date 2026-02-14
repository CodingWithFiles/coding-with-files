package CWF::ContextInheritance::Core;

=head1 NAME

CWF::ContextInheritance::Core - Version-agnostic context inheritance logic

=head1 SYNOPSIS

    use CWF::ContextInheritance::Core;

    my @parent_data = CWF::ContextInheritance::Core::generate_context(\@parent_tasks, $workflow_mappings);

=head1 DESCRIPTION

Core context inheritance logic shared across v2.0 and v2.1 workflow versions.
Generates structural maps of parent task content with headers and line ranges.

=cut

use strict;
use warnings;
use File::Basename;
use CWF::MarkdownParser qw(extract_status);

=head1 FUNCTIONS

=head2 extract_headers($file_path)

Extract markdown headers with line numbers from a file.

Parameters:
  $file_path - Path to markdown file

Returns:
  Array of hashes with level, title, line keys

=cut

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

=head2 calculate_boundaries(\@headers, $total_lines)

Calculate section boundaries from headers.

Parameters:
  \@headers     - Array of header hashes from extract_headers()
  $total_lines  - Total number of lines in file

Returns:
  Array of section hashes with title, level, start, end keys

=cut

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

=head2 count_lines($file_path)

Count total lines in a file.

Parameters:
  $file_path - Path to file

Returns:
  Number of lines in file

=cut

sub count_lines {
    my ($file_path) = @_;
    open(my $fh, '<', $file_path) or return 0;
    my $count = 0;
    $count++ while <$fh>;
    close($fh);
    return $count;
}

=head2 generate_context(\@parent_tasks, $workflow_mappings)

Generate context data for parent tasks.

Parameters:
  \@parent_tasks      - Array of hashes with num, dir keys
  $workflow_mappings  - Array of workflow file mappings from CWF::WorkflowFiles

Returns:
  Array of parent data hashes with name, num, files keys

=cut

sub generate_context {
    my ($parent_tasks, $workflow_mappings) = @_;

    my @parent_data;

    foreach my $parent (@$parent_tasks) {
        my $parent_dir = $parent->{dir};
        my $parent_name = basename($parent_dir);

        my @files_data;

        # Check each workflow file using provided mappings
        foreach my $wf (@$workflow_mappings) {
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

            # Extract status using shared library
            my $status = extract_status($file_path);

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

    return @parent_data;
}

1;

__END__

=head1 AUTHOR

CIG System

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
