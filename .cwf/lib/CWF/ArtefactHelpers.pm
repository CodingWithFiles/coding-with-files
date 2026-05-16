package CWF::ArtefactHelpers;
#
# CWF::ArtefactHelpers - Shared file/JSON/path utilities for artefact-handling
# helpers (cwf-apply-artefacts, cwf-claude-settings-merge).
#
# Goals:
#   - One validated path-allowlist + atomic-write code path across both helpers.
#   - Binary-safe SHA256 matching CWF::Validate::Security::_sha256.
#   - No side effects beyond what each sub explicitly does.
#
use strict;
use warnings;
use utf8;
use Exporter 'import';
use Digest::SHA qw(sha256_hex);
use JSON::PP;
use File::Temp ();
use File::Basename qw(dirname basename);

our @EXPORT_OK = qw(
    read_json_file
    atomic_write_json
    atomic_write_text
    validate_write_path_allowlist
    validate_read_path_allowlist
    compute_file_sha256
    read_file_raw
);

# read_json_file($path) -> decoded JSON ref, or dies on error.
sub read_json_file {
    my ($path) = @_;
    open(my $fh, '<:raw', $path)
        or die "[CWF] ERROR: cannot open $path: $!\n";
    local $/;
    my $blob = <$fh>;
    close $fh;
    my $obj = eval { JSON::PP->new->decode($blob) };
    die "[CWF] ERROR: cannot parse $path: $@\n" if $@;
    return $obj;
}

# atomic_write_json($path, $data, %opts) -> dies on error.
# Writes pretty-printed canonical JSON via same-directory temp + rename.
sub atomic_write_json {
    my ($path, $data, %opts) = @_;
    my $encoder = JSON::PP->new->pretty->indent_length(2)->canonical;
    my $blob    = $encoder->encode($data);
    return atomic_write_text($path, $blob, %opts);
}

# atomic_write_text($path, $blob, %opts) -> dies on error.
# Writes via same-directory temp + rename. %opts: mode => 0644 (default).
sub atomic_write_text {
    my ($path, $blob, %opts) = @_;
    my $mode = exists $opts{mode} ? $opts{mode} : 0644;

    my $dir = dirname($path);
    unless (-d $dir) {
        require File::Path;
        File::Path::make_path($dir)
            or die "[CWF] ERROR: cannot mkdir $dir: $!\n";
    }

    my $base = basename($path);
    my $tmp  = File::Temp->new(
        DIR      => $dir,
        TEMPLATE => ".${base}.XXXXXX",
        UNLINK   => 0,
    );
    binmode($tmp, ':raw');
    print {$tmp} $blob
        or do { my $e = $!; unlink "$tmp"; die "[CWF] ERROR: cannot write $tmp: $e\n" };
    close $tmp
        or do { my $e = $!; unlink "$tmp"; die "[CWF] ERROR: cannot close $tmp: $e\n" };

    chmod $mode, "$tmp"
        or do { my $e = $!; unlink "$tmp"; die "[CWF] ERROR: cannot chmod $tmp: $e\n" };

    rename "$tmp", $path
        or do {
            my $err = $!;
            unlink "$tmp";
            die "[CWF] ERROR: cannot rename $tmp -> $path: $err\n";
        };
    return;
}

# validate_write_path_allowlist($path, \@allowed_prefixes) -> dies on rejection.
# Use when the caller writes content to $path drawn from untrusted data
# (e.g. a JSON manifest). Defends against directory traversal, absolute
# paths into sensitive locations, and manifest tampering.
sub validate_write_path_allowlist {
    my ($path, $allowed) = @_;
    die "[CWF] ERROR: path is undef\n" unless defined $path;
    die "[CWF] ERROR: path is empty\n" unless length $path;
    die "[CWF] ERROR: refusing absolute path: $path\n"
        if $path =~ m{^/};
    die "[CWF] ERROR: refusing path with '..': $path\n"
        if $path =~ m{(?:^|/)\.\.(?:/|$)};

    for my $prefix (@$allowed) {
        return 1 if index($path, $prefix) == 0;
    }
    die "[CWF] ERROR: path does not match any allowed prefix: $path\n";
}

# validate_read_path_allowlist($path) -> dies on rejection.
# Use when the caller reads from a path the invoker has directly chosen
# (e.g. backlog-manager --body-file). The invoker already has shell access;
# restricting which files may be read defends against nothing the
# filesystem doesn't already enforce. Only checks: defined, non-empty,
# exists, readable.
sub validate_read_path_allowlist {
    my ($path) = @_;
    die "[CWF] ERROR: path is undef\n" unless defined $path;
    die "[CWF] ERROR: path is empty\n" unless length $path;
    die "[CWF] ERROR: file does not exist: $path\n" unless -f $path;
    die "[CWF] ERROR: file is not readable: $path\n" unless -r _;
    return 1;
}

# compute_file_sha256($path) -> hex string, or '' if file unreadable.
# Binary-safe; matches CWF::Validate::Security::_sha256.
sub compute_file_sha256 {
    my ($path) = @_;
    open my $fh, '<:raw', $path or return '';
    local $/;
    my $content = <$fh>;
    close $fh;
    return sha256_hex($content);
}

# read_file_raw($path) -> binary scalar of file content, or dies.
sub read_file_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path
        or die "[CWF] ERROR: cannot open $path: $!\n";
    local $/;
    my $blob = <$fh>;
    close $fh;
    return $blob;
}

1;
