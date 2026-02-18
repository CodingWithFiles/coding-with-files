package CWF::Validate::Config;
#
# CWF::Validate::Config - Validate cwf-project.json schema
#
# Checks required keys and types in the project config file.
# Returns a list of violation hashrefs, each with keys:
#   file, field, actual, expected, fix
#
# Usage:
#   use CWF::Validate::Config qw(validate validate_config_hash);
#   my @violations = validate($git_root);
#   my @violations = validate_config_hash($hashref, $file_path);
#

use strict;
use warnings;
use Exporter 'import';
use JSON::PP;

our @EXPORT_OK = qw(validate validate_config_hash);

my $CONFIG_PATH = 'implementation-guide/cwf-project.json';

# validate($git_root) - discover and validate cwf-project.json
# Returns: list of violation hashrefs
sub validate {
    my ($git_root) = @_;

    my $file = "$git_root/$CONFIG_PATH";

    # Pre-init state: no config file yet — not an error
    return () unless -f $file;

    my $json;
    {
        open my $fh, '<', $file or return _violation($file, 'file', '(unreadable)', 'readable JSON file', "Check permissions on $file");
        local $/;
        $json = <$fh>;
        close $fh;
    }

    my $config = eval { decode_json($json) };
    if ($@) {
        return _violation($file, 'json', '(parse error)', 'valid JSON', "Fix JSON syntax in $file: $@");
    }

    return validate_config_hash($config, $file);
}

# validate_config_hash($hashref, $file_path) - validate an already-loaded config
# Returns: list of violation hashrefs
sub validate_config_hash {
    my ($config, $file) = @_;
    my @violations;

    # Check supported-task-types: must exist and be an arrayref
    if (!exists $config->{'supported-task-types'}) {
        push @violations, _violation(
            $file,
            'supported-task-types',
            '(missing)',
            'array of task type strings',
            'Add "supported-task-types": ["feature","bugfix","hotfix","chore","discovery"] to ' . $file,
        );
    } elsif (ref $config->{'supported-task-types'} ne 'ARRAY') {
        push @violations, _violation(
            $file,
            'supported-task-types',
            ref($config->{'supported-task-types'}) || 'scalar',
            'array (JSON array)',
            'Change supported-task-types to a JSON array: ["feature","bugfix","hotfix","chore","discovery"]',
        );
    }

    # Check source-management: must exist and be a hashref
    if (!exists $config->{'source-management'}) {
        push @violations, _violation(
            $file,
            'source-management',
            '(missing)',
            'object with branch-naming-convention key',
            'Add "source-management": {"branch-naming-convention": "{task-type}/{task-id}-{description-slug}"} to ' . $file,
        );
    } elsif (ref $config->{'source-management'} ne 'HASH') {
        push @violations, _violation(
            $file,
            'source-management',
            ref($config->{'source-management'}) || 'scalar',
            'object (JSON object)',
            'Change source-management to a JSON object containing branch-naming-convention',
        );
    } else {
        # Check branch-naming-convention inside source-management
        my $bnc = $config->{'source-management'}{'branch-naming-convention'};
        if (!defined $bnc || $bnc eq '') {
            push @violations, _violation(
                $file,
                'source-management.branch-naming-convention',
                defined $bnc ? '(empty string)' : '(missing)',
                'non-empty branch name pattern string (e.g. "{task-type}/{task-id}-{description-slug}")',
                'Set source-management.branch-naming-convention to a pattern like "{task-type}/{task-id}-{description-slug}" in ' . $file,
            );
        }
    }

    return @violations;
}

sub _violation {
    my ($file, $field, $actual, $expected, $fix) = @_;
    return {
        category => 'CONFIG',
        file     => $file,
        field    => $field,
        actual   => $actual,
        expected => $expected,
        fix      => $fix,
    };
}

1;
