package CWF::TemplateCopier::Core;

=head1 NAME

CWF::TemplateCopier::Core - Version-agnostic template copying logic

=head1 SYNOPSIS

    use CWF::TemplateCopier::Core;

    my @templates = CWF::TemplateCopier::Core::discover_templates($templates_dir, $task_type);
    my %vars = CWF::TemplateCopier::Core::compute_variables(\%params);
    my ($created, $overwritten) = CWF::TemplateCopier::Core::copy_templates(\@templates, $dest, \%vars);

=head1 DESCRIPTION

Core template copying logic shared across v2.0 and v2.1 workflow versions.
Handles template discovery, variable substitution, and file copying.

=cut

use strict;
use warnings;
use utf8;
use File::Basename qw(basename);
use File::Spec;
use File::Path qw(make_path);
use CWF::TaskPath qw(get_parent);
use CWF::WorkflowFiles qw(load_config);

=head1 FUNCTIONS

=head2 discover_templates($base_dir, $task_type)

Discover template files for a task type by reading symlinks.

Parameters:
  $base_dir   - Path to templates directory
  $task_type  - Task type (feature, bugfix, hotfix, chore, discovery)

Returns:
  Array of hashes with 'name' and 'pool_file' keys

=cut

sub discover_templates {
    my ($base, $type) = @_;

    my $type_dir = "$base/$type";
    unless (-d $type_dir) {
        print STDERR "Error: Template directory not found: $type_dir\n";
        exit 2;
    }

    opendir(my $dh, $type_dir) or do {
        print STDERR "Error: Cannot read template directory: $type_dir\n";
        print STDERR "Reason: $!\n";
        exit 3;
    };

    my @templates;
    while (my $file = readdir($dh)) {
        next unless $file =~ /\.template$/;

        my $symlink_path = "$type_dir/$file";
        unless (-l $symlink_path) {
            next;  # Skip non-symlinks
        }

        my $target = readlink($symlink_path);
        unless ($target) {
            print STDERR "Error: Cannot read symlink: $symlink_path\n";
            exit 2;
        }

        # Resolve target relative to type directory
        my $pool_file = File::Spec->rel2abs($target, $type_dir);
        unless (-f $pool_file) {
            print STDERR "Error: Broken symlink detected\n";
            print STDERR "Symlink: $symlink_path\n";
            print STDERR "Target: $pool_file (not found)\n";
            exit 2;
        }

        push @templates, {
            name => $file,
            pool_file => $pool_file
        };
    }

    closedir($dh);

    # Sort templates alphabetically for consistent ordering
    @templates = sort { $a->{name} cmp $b->{name} } @templates;

    return @templates;
}

=head2 compute_variables(\%params)

Compute template variables from task parameters.

Parameters:
  \%params - Hash with task_num, description, destination, task_type keys

Returns:
  Hash of template variables (description, taskId, taskUrl, parentTask, branchName)

=cut

sub compute_variables {
    my ($params) = @_;

    my %vars;

    # Simple variables
    $vars{description} = $params->{description};
    $vars{taskId} = "internal-" . $params->{task_num};
    $vars{taskUrl} = "N/A (internal task)";

    # Parent task computation
    my $parent = get_parent($params->{task_num});
    $vars{parentTask} = $parent ? $parent : "N/A";

    # Branch name from config pattern
    my $config = load_config();
    my $pattern = $config->{'branch-naming-convention'};

    # Extract slug from destination basename
    my $basename = basename($params->{destination});
    my $slug;
    if ($basename =~ /^\d+-[^-]+-(.+)$/) {
        $slug = $1;
    } else {
        # Fallback to description if basename doesn't match pattern
        $slug = $params->{description};
    }

    # Substitute variables in branch pattern
    my $branch = $pattern;
    $branch =~ s/\{\{task-type\}\}/$params->{task_type}/g;
    $branch =~ s/\{\{task-id\}\}/$params->{task_num}/g;
    $branch =~ s/\{\{description-slug\}\}/$slug/g;
    $vars{branchName} = $branch;

    return %vars;
}

=head2 substitute_variables($content, \%vars)

Substitute template variables in content.

Parameters:
  $content - Template content string
  \%vars   - Hash of variable name => value mappings

Returns:
  Content with variables substituted

=cut

sub substitute_variables {
    my ($content, $vars) = @_;

    for my $key (keys %$vars) {
        my $value = $vars->{$key};
        $content =~ s/\{\{$key\}\}/$value/g;
    }

    return $content;
}

=head2 copy_templates(\@templates, $dest, \%vars)

Copy templates to destination with variable substitution.

Parameters:
  \@templates - Array of template hashes from discover_templates()
  $dest       - Destination directory path
  \%vars      - Variables hash from compute_variables()

Returns:
  (\@created, \@overwritten) - Arrays of filenames created/overwritten

=cut

sub copy_templates {
    my ($templates, $dest, $vars) = @_;

    my @created;
    my @overwritten;

    # Create destination directory if it doesn't exist
    unless (-d $dest) {
        make_path($dest) or do {
            print STDERR "Error: Cannot create destination directory: $dest\n";
            print STDERR "Reason: $!\n";
            exit 3;
        };
    }

    for my $template (@$templates) {
        my $pool_file = $template->{pool_file};
        my $filename = $template->{name};

        # Remove .template extension for destination
        $filename =~ s/\.template$//;
        my $dest_file = "$dest/$filename";

        # Read pool template
        open(my $fh, '<', $pool_file) or do {
            print STDERR "Error: Cannot read template file: $pool_file\n";
            print STDERR "Reason: $!\n";
            exit 3;
        };

        my $content = do { local $/; <$fh> };
        close($fh);

        # Substitute variables
        $content = substitute_variables($content, $vars);

        # Check if file exists (for idempotency tracking)
        my $exists = -f $dest_file;

        # Write atomically using temp file + rename
        my $temp_file = "$dest_file.tmp.$$";
        open(my $out, '>', $temp_file) or do {
            print STDERR "Error: Cannot write to destination: $temp_file\n";
            print STDERR "Reason: $!\n";
            exit 3;
        };

        print $out $content;
        close($out);

        # Set permissions before rename
        chmod 0600, $temp_file;

        # Atomic rename
        rename $temp_file, $dest_file or do {
            unlink $temp_file;
            print STDERR "Error: Cannot rename temp file: $temp_file -> $dest_file\n";
            print STDERR "Reason: $!\n";
            exit 3;
        };

        # Track created vs overwritten
        if ($exists) {
            print STDERR "Warning: Overwriting existing file: $dest_file\n";
            push @overwritten, $filename;
        } else {
            push @created, $filename;
        }
    }

    return (\@created, \@overwritten);
}

1;

__END__

=head1 AUTHOR

CIG System

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
