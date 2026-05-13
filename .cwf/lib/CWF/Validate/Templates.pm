package CWF::Validate::Templates;
#
# CWF::Validate::Templates - Validate task-type template symlink structure
#
# Checks that every entry under .cwf/templates/<type>/ (for each
# supported task type) is a symlink resolving exactly to the
# corresponding entry in .cwf/templates/pool/. Catches the
# symlink-resolution bug in cwf-manage update (regular file where
# symlink expected) and hand-edit errors (wrong pool target,
# dangling link, escaping target).
#
# Returns a list of violation hashrefs, each with keys:
#   category, file, field, actual, expected, fix
#
# Usage:
#   use CWF::Validate::Templates qw(validate);
#   my @violations = validate($git_root);
#

use strict;
use warnings;
use utf8;
use Exporter 'import';
use CWF::WorkflowFiles::V21 qw(supported_types);

our @EXPORT_OK = qw(validate);

sub validate {
    my ($git_root) = @_;
    my @violations;
    for my $type (supported_types()) {
        my $dir = "$git_root/.cwf/templates/$type";
        next unless -d $dir;
        opendir(my $dh, $dir)
            or die "[CWF] Validate::Templates: cannot opendir $dir: $!\n";
        my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh);
        closedir $dh;
        for my $name (@names) {
            my $path = "$dir/$name";
            my $rel  = ".cwf/templates/$type/$name";
            lstat($path);
            if (!-l _) {
                push @violations, _v($rel, 'type',
                    (-d _ ? 'directory' : 'regular file'),
                    "symlink to ../pool/$name",
                    "Re-run 'cwf-manage update' to restore symlinks, or 'ln -sfn ../pool/$name .cwf/templates/$type/$name'.");
                next;
            }
            my $link = readlink($path)
                // die "[CWF] Validate::Templates: readlink $path failed: $!\n";
            # Single pattern check: anything other than the exact form
            # "../pool/<name>" is a violation. This subsumes:
            #   - wrong basename within pool/  ("../pool/other.template")
            #   - subdirectory within pool/    ("../pool/sub/<name>")
            #   - escape outside pool/         ("../../etc/passwd")
            #   - absolute target              ("/etc/passwd")
            my $expected_link = "../pool/$name";
            if ($link ne $expected_link) {
                my $resolved = "$dir/$link";
                my $field    = (-e $resolved) ? 'pool-name' : 'target';
                my $hint     = ($field eq 'target')
                    ? "Re-run 'cwf-manage update'."
                    : "Re-symlink: 'ln -sfn ../pool/$name .cwf/templates/$type/$name'.";
                push @violations, _v($rel, $field,
                    $link, $expected_link, $hint);
            }
        }
    }
    return @violations;
}

sub _v {
    my ($rel, $field, $actual, $expected, $fix) = @_;
    return { category => 'TEMPLATES', file => $rel,
             field => $field, actual => $actual,
             expected => $expected, fix => $fix };
}

1;
