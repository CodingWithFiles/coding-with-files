package CWF::Validate::Workflow;
#
# CWF::Validate::Workflow - Validate workflow step file fields
#
# Scans all task directories under implementation-guide/ and checks
# that each workflow .md file has a valid Status value and a ## Status section.
#
# Usage:
#   use CWF::Validate::Workflow qw(validate);
#   my @violations = validate($git_root);
#

use strict;
use warnings;
use Exporter 'import';
use CWF::MarkdownParser qw(extract_status);

our @EXPORT_OK = qw(validate);

my @ALLOWED_STATUSES = qw(
    Backlog
    In\ Progress
    Implemented
    Testing
    Finished
    Blocked
    Skipped
    Cancelled
);

my %ALLOWED_STATUS_SET = map { $_ => 1 } (
    'Backlog', 'In Progress', 'Implemented', 'Testing',
    'Finished', 'Blocked', 'Skipped', 'Cancelled',
);

# validate($git_root) - scan all workflow files and check status values
# Returns: list of violation hashrefs
sub validate {
    my ($git_root) = @_;
    my @violations;

    my $ig_dir = "$git_root/implementation-guide";
    return () unless -d $ig_dir;

    opendir my $dh, $ig_dir or return ();
    my @task_dirs = grep { /^\d/ && -d "$ig_dir/$_" } readdir $dh;
    closedir $dh;

    for my $task_dir (sort @task_dirs) {
        my $task_path = "$ig_dir/$task_dir";
        opendir my $tdh, $task_path or next;
        my @md_files = grep { /\.md$/ && -f "$task_path/$_" } readdir $tdh;
        closedir $tdh;

        for my $md_file (sort @md_files) {
            my $file = "$task_path/$md_file";
            push @violations, _check_file($file);
        }
    }

    return @violations;
}

sub _check_file {
    my ($file) = @_;
    my @violations;

    my @lines;
    { open my $fh, '<', $file or return (); @lines = <$fh>; close $fh; }

    my $has_status_section = 0;
    my $status_value       = undef;
    my $in_status_section  = 0;
    my $in_code_block      = 0;

    for my $line (@lines) {
        chomp $line;
        if ($line =~ /^```/) {
            $in_code_block = !$in_code_block;
            next;
        }
        next if $in_code_block;

        if ($line =~ /^## (?:Status|Current Status)\s*$/) {
            $has_status_section = 1;
            $in_status_section  = 1;
            next;
        }
        if ($line =~ /^## / && $in_status_section) {
            $in_status_section = 0;
        }
        if ($in_status_section && $line =~ /^\*\*Status\*\*:\s*(.+)$/) {
            $status_value = $1;
            $status_value =~ s/\s+$//;
        }
    }

    unless ($has_status_section) {
        push @violations, _violation(
            $file,
            '## Status section',
            '(missing)',
            'a ## Status section containing **Status**: <value>',
            "Add a ## Status section to $file with a valid status value",
        );
        return @violations;
    }

    if (!defined $status_value || $status_value eq '') {
        push @violations, _violation(
            $file,
            '**Status**',
            '(missing or empty)',
            'one of: ' . join(', ', sort keys %ALLOWED_STATUS_SET),
            "Add **Status**: Finished (or appropriate value) in the ## Status section of $file",
        );
    } elsif (!$ALLOWED_STATUS_SET{$status_value}) {
        push @violations, _violation(
            $file,
            '**Status**',
            $status_value,
            'one of: ' . join(', ', sort keys %ALLOWED_STATUS_SET),
            "Change **Status**: $status_value to a valid value in $file",
        );
    }

    return @violations;
}

sub _violation {
    my ($file, $field, $actual, $expected, $fix) = @_;
    return {
        category => 'WORKFLOW',
        file     => $file,
        field    => $field,
        actual   => $actual,
        expected => $expected,
        fix      => $fix,
    };
}

1;
