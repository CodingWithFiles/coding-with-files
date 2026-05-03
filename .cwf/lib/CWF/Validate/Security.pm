package CWF::Validate::Security;
#
# CWF::Validate::Security - Script hash and permission verification
#
# Reads .cwf/security/script-hashes.json and verifies each listed file:
#   - exists at the recorded path
#   - has permissions >= 0500 (for scripts) or any valid perms (for lib files)
#   - has a SHA256 hash matching the recorded value
#
# Uses Digest::SHA (Perl core since 5.10) — no shell subprocess.
#
# Usage:
#   use CWF::Validate::Security qw(validate);
#   my @violations = validate($git_root);
#

use strict;
use warnings;
use utf8;
use Exporter 'import';
use Digest::SHA qw(sha256_hex);
use JSON::PP;

our @EXPORT_OK = qw(validate);

my $HASHES_FILE = '.cwf/security/script-hashes.json';

# validate($git_root)
# Returns: list of violation hashrefs
sub validate {
    my ($git_root) = @_;

    my $hashes_path = "$git_root/$HASHES_FILE";
    unless (-f $hashes_path) {
        return _violation(
            $hashes_path,
            'file',
            '(missing)',
            'script-hashes.json to exist',
            "Run cwf-manage to reinstall or restore $hashes_path",
        );
    }

    my $json;
    {
        open my $fh, '<', $hashes_path or return _violation($hashes_path, 'file', '(unreadable)', 'readable', "Check permissions on $hashes_path");
        local $/;
        $json = <$fh>;
        close $fh;
    }

    my $data = eval { decode_json($json) };
    if ($@) {
        return _violation($hashes_path, 'json', '(parse error)', 'valid JSON', "Fix JSON syntax in $hashes_path");
    }

    my @violations;

    # Check all sections (scripts, lib, etc.)
    for my $section (sort keys %$data) {
        next unless ref $data->{$section} eq 'HASH';
        # Skip metadata keys that aren't file entries
        next unless exists $data->{$section}{path} || _looks_like_file_map($data->{$section});

        my $entries = $data->{$section};

        # Handle both flat entries ({path,sha256}) and nested maps ({name => {path,sha256}})
        my %file_entries;
        if (exists $entries->{path}) {
            # Single entry at section level (shouldn't happen but handle it)
            %file_entries = ($section => $entries);
        } else {
            %file_entries = %$entries;
        }

        for my $name (sort keys %file_entries) {
            my $entry = $file_entries{$name};
            next unless ref $entry eq 'HASH' && exists $entry->{path};

            my $file         = "$git_root/$entry->{path}";
            my $expected_sha  = $entry->{sha256} // '';
            my $expected_perms = $entry->{permissions};   # undef means no perm check

            # Check existence
            unless (-e $file) {
                push @violations, _violation(
                    $file, 'existence', '(missing)', 'file to exist',
                    "Restore $file or remove its entry from $HASHES_FILE",
                );
                next;
            }

            # Check permissions only when explicitly recorded
            if (defined $expected_perms) {
                my $actual_perms = (stat($file))[2] & oct('07777');
                my $min_perms    = oct($expected_perms);
                if (($actual_perms & $min_perms) != $min_perms) {
                    push @violations, _violation(
                        $file,
                        'permissions',
                        sprintf('0%o', $actual_perms),
                        $expected_perms,
                        "Run: chmod $expected_perms $file",
                    );
                }
            }

            # Check SHA256
            my $actual_sha = _sha256($file);
            if ($actual_sha ne $expected_sha) {
                push @violations, _violation(
                    $file,
                    'sha256',
                    $actual_sha,
                    $expected_sha,
                    "File has been modified. If intentional, update the hash in $HASHES_FILE with: sha256sum $file",
                );
            }
        }
    }

    return @violations;
}

sub _sha256 {
    my ($file) = @_;
    open my $fh, '<:raw', $file or return '';
    local $/;
    my $content = <$fh>;
    close $fh;
    return sha256_hex($content);
}

sub _looks_like_file_map {
    my ($hash) = @_;
    # Returns true if hash looks like a map of name => {path, sha256} entries
    for my $val (values %$hash) {
        return 1 if ref $val eq 'HASH' && exists $val->{path};
    }
    return 0;
}

sub _violation {
    my ($file, $field, $actual, $expected, $fix) = @_;
    return {
        category => 'SECURITY',
        file     => $file,
        field    => $field,
        actual   => $actual,
        expected => $expected,
        fix      => $fix,
    };
}

1;
