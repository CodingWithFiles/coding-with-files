package CWF::Validate::Consistency;
#
# CWF::Validate::Consistency - Cross-file consistency checks
#
# Checks that task directory names match task numbers in workflow files,
# and that the git branch matches the branch recorded in active task files.
#
# Usage:
#   use CWF::Validate::Consistency qw(validate);
#   my @violations = validate($git_root);
#

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(validate);

my %TERMINAL_STATUSES = map { $_ => 1 } qw(Finished Skipped Cancelled);

# validate($git_root)
# Returns: list of violation hashrefs
sub validate {
    my ($git_root) = @_;
    my @violations;

    my $current_branch = _current_branch($git_root);

    my $ig_dir = "$git_root/implementation-guide";
    return () unless -d $ig_dir;

    opendir my $dh, $ig_dir or return ();
    my @task_dirs = grep { /^\d/ && -d "$ig_dir/$_" } readdir $dh;
    closedir $dh;

    for my $task_dir (sort @task_dirs) {
        # Extract task number from directory name prefix
        my ($dir_num) = $task_dir =~ /^(\d[\d.]*)-/;
        next unless defined $dir_num;

        my $task_path = "$ig_dir/$task_dir";
        opendir my $tdh, $task_path or next;
        my @md_files = grep { /\.md$/ && -f "$task_path/$_" } readdir $tdh;
        closedir $tdh;

        my $task_is_active = 0;
        my $branch_in_file;

        for my $md_file (sort @md_files) {
            my $file = "$task_path/$md_file";
            my ($file_num, $file_branch, $file_status) = _extract_fields($file);

            # Task number consistency
            if (defined $file_num && $file_num ne $dir_num) {
                push @violations, _violation(
                    $file,
                    '**Task**',
                    $file_num,
                    $dir_num,
                    "Update **Task**: $file_num to **Task**: $dir_num in $file to match directory name $task_dir",
                );
            }

            # Track branch and activity for branch check
            $branch_in_file //= $file_branch if defined $file_branch;
            if (defined $file_status && !$TERMINAL_STATUSES{$file_status}) {
                $task_is_active = 1;
            }
        }

        # Branch consistency: only check active tasks
        if ($task_is_active && defined $branch_in_file && defined $current_branch
            && $branch_in_file ne $current_branch) {
            push @violations, _violation(
                "$task_path/",
                '**Branch**',
                $branch_in_file,
                $current_branch,
                "Task $dir_num has active files but **Branch**: $branch_in_file does not match current branch $current_branch. Either checkout the task branch or update the Branch field.",
            );
        }
    }

    return @violations;
}

sub _extract_fields {
    my ($file) = @_;
    my ($task_num, $branch, $status);

    my @lines;
    { open my $fh, '<', $file or return (undef, undef, undef); @lines = <$fh>; close $fh; }

    my $in_task_ref     = 0;
    my $in_status_sec   = 0;
    my $in_code_block   = 0;
    my $lines_read      = 0;

    for my $line (@lines) {
        chomp $line;
        last if $lines_read++ > 200;  # Only scan header/status sections

        if ($line =~ /^```/) { $in_code_block = !$in_code_block; next }
        next if $in_code_block;

        if ($line =~ /^## Task Reference/) { $in_task_ref = 1; next }
        if ($line =~ /^## / && $in_task_ref && $line !~ /^## Task Reference/) { $in_task_ref = 0 }

        if ($in_task_ref) {
            $task_num = $1 if $line =~ /^\*\*Task\*\*:\s*(\S+)/;
            $branch   = $1 if $line =~ /^\*\*Branch\*\*:\s*(\S+)/;
        }

        if ($line =~ /^## (?:Status|Current Status)\s*$/) { $in_status_sec = 1; next }
        if ($line =~ /^## / && $in_status_sec) { $in_status_sec = 0 }
        if ($in_status_sec && $line =~ /^\*\*Status\*\*:\s*(.+)$/) {
            ($status = $1) =~ s/\s+$//;
        }
    }
    return ($task_num, $branch, $status);
}

sub _current_branch {
    my ($git_root) = @_;
    my $branch = `git -C "$git_root" rev-parse --abbrev-ref HEAD 2>/dev/null`;
    chomp $branch;
    return $branch || undef;
}

sub _violation {
    my ($file, $field, $actual, $expected, $fix) = @_;
    return {
        category => 'CONSISTENCY',
        file     => $file,
        field    => $field,
        actual   => $actual,
        expected => $expected,
        fix      => $fix,
    };
}

1;
