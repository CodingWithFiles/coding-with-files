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
use CWF::TaskState qw(status_get status_is_valid);

our @EXPORT_OK = qw(validate);

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

    my $status_value = status_get($file);

    if ($status_value eq 'Unknown') {
        push @violations, _violation(
            $file,
            '## Status / **Status**',
            '(missing)',
            'a ## Status section containing **Status**: <value>',
            "Add a ## Status section to $file with a valid status value",
        );
    } elsif (!status_is_valid($status_value)) {
        push @violations, _violation(
            $file,
            '**Status**',
            $status_value,
            'a valid status from cwf-project.json',
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
