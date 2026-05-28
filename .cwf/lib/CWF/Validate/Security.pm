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

our @EXPORT_OK = qw(validate validate_install_manifest);

my $HASHES_FILE   = '.cwf/security/script-hashes.json';
my $MANIFEST_FILE = '.cwf/install-manifest.json';
my $VERSION_FILE  = '.cwf/version';

my $SUPPORTED_MANIFEST_SCHEMA_VERSION = 1;

# Allowed source/dest path prefixes for install-manifest.json entries.
# Mirrors cwf-apply-artefacts. Kept here so cwf-manage validate detects
# a tampered manifest without needing to invoke the helper.
my @ALLOWED_SOURCE_PREFIXES = (
    '.cwf/templates/',
    '.claude/rules/',
    '.cwf-rules/',
);
my @ALLOWED_DEST_PREFIXES = (
    '.cwf-rules/',
    '.claude/rules/',
    'CLAUDE.md',
    '.gitignore',
);

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

# validate_install_manifest($git_root)
# Returns: list of violation hashrefs.
#
# Per design D11/D12. No-op silently when the manifest is absent
# (pre-feature install) or when cwf_install_manifest_sha is missing
# from .cwf/version (pre-D12 install).
#
# When both exist:
#   - schema_version must equal $SUPPORTED_MANIFEST_SCHEMA_VERSION
#   - on-disk SHA must match cwf_install_manifest_sha
#   - every artefact's source/dest must pass the allowlist
sub validate_install_manifest {
    my ($git_root) = @_;
    my $manifest_path = "$git_root/$MANIFEST_FILE";
    my $version_path  = "$git_root/$VERSION_FILE";

    return () unless -f $manifest_path;

    # Read the version file (tolerant: pre-feature installs may not have one).
    my %v;
    if (-f $version_path) {
        open my $vfh, '<', $version_path or return ();
        while (<$vfh>) {
            chomp;
            next if /^\s*#/ || /^\s*$/;
            $v{$1} = $2 if /^(\w+)=(.*)$/;
        }
        close $vfh;
    }

    my @violations;

    # SHA pin (D12) — only enforced when both sides are present.
    if (defined $v{cwf_install_manifest_sha} && length $v{cwf_install_manifest_sha}) {
        my $actual = _sha256($manifest_path);
        if ($actual ne $v{cwf_install_manifest_sha}) {
            push @violations, _violation(
                $manifest_path, 'sha256', $actual, $v{cwf_install_manifest_sha},
                "install-manifest.json content does not match cwf_install_manifest_sha in $VERSION_FILE. Restore with 'git checkout -- $MANIFEST_FILE' or run 'cwf-manage update' to reinstall.",
            );
            # Don't continue parsing — content is suspect.
            return @violations;
        }
    }

    # Parse + structural checks.
    my $blob;
    {
        open my $fh, '<:raw', $manifest_path or return @violations;
        local $/;
        $blob = <$fh>;
        close $fh;
    }
    my $data = eval { decode_json($blob) };
    if ($@) {
        push @violations, _violation(
            $manifest_path, 'json', '(parse error)', 'valid JSON',
            "Fix JSON syntax in $MANIFEST_FILE or restore from upstream.",
        );
        return @violations;
    }

    my $sv = $data->{schema_version};
    if (!defined $sv || $sv != $SUPPORTED_MANIFEST_SCHEMA_VERSION) {
        push @violations, _violation(
            $manifest_path, 'schema_version',
            (defined $sv ? $sv : '(missing)'),
            $SUPPORTED_MANIFEST_SCHEMA_VERSION,
            "Manifest schema version is not supported. Upgrade cwf-manage or restore the manifest.",
        );
        # Continue to surface allowlist violations too.
    }

    my $artefacts = $data->{artefacts};
    if (ref $artefacts ne 'ARRAY') {
        push @violations, _violation(
            $manifest_path, 'artefacts', '(missing or non-array)', 'array',
            "Manifest must contain an artefacts array.",
        );
        return @violations;
    }

    for my $a (@$artefacts) {
        next unless ref $a eq 'HASH';
        my $id = $a->{id} // '(no-id)';
        for my $field (qw(source dest)) {
            next unless defined $a->{$field};
            eval { _check_path_allowlist($a->{$field}, $field); 1 }
                or push @violations, _violation(
                    $manifest_path, "artefact:$id:$field", $a->{$field}, "allowlisted prefix",
                    $@,
                );
        }
        if (ref $a->{files} eq 'HASH') {
            for my $rel (sort keys %{ $a->{files} }) {
                # Tree-entry files are basenames relative to source/dest dir.
                # Reject traversal and absolute paths; do not allowlist-prefix.
                if ($rel =~ m{^/} || $rel =~ m{(?:^|/)\.\.(?:/|$)}) {
                    push @violations, _violation(
                        $manifest_path, "artefact:$id:files:$rel", $rel, "safe relative path",
                        "[CWF] ERROR: files key contains absolute or traversal path: $rel",
                    );
                }
            }
        }
    }

    return @violations;
}

sub _check_path_allowlist {
    my ($path, $field) = @_;
    die "[CWF] ERROR: refusing absolute path: $path\n" if $path =~ m{^/};
    die "[CWF] ERROR: refusing path with '..': $path\n"
        if $path =~ m{(?:^|/)\.\.(?:/|$)};

    my @prefixes = $field eq 'source' ? @ALLOWED_SOURCE_PREFIXES
                 : $field eq 'dest'   ? @ALLOWED_DEST_PREFIXES
                 :                       (@ALLOWED_SOURCE_PREFIXES, @ALLOWED_DEST_PREFIXES);

    for my $p (@prefixes) {
        return 1 if index($path, $p) == 0 || $path eq $p;
    }
    die "[CWF] ERROR: $field path does not match any allowed prefix: $path\n";
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
