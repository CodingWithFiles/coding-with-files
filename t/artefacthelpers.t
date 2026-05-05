#!/usr/bin/env perl
#
# artefacthelpers.t — Unit tests for CWF::ArtefactHelpers shared module.
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use lib File::Spec->rel2abs("$FindBin::Bin/../.cwf/lib");

use CWF::ArtefactHelpers qw(
    read_json_file
    atomic_write_json
    atomic_write_text
    validate_path_allowlist
    compute_file_sha256
    read_file_raw
);

# read_json_file --------------------------------------------------------------
{
    my $tmp = tempdir(CLEANUP => 1);
    my $path = "$tmp/in.json";
    open my $fh, '>:raw', $path or die $!;
    print $fh '{"a":1,"b":[2,3]}';
    close $fh;
    my $obj = read_json_file($path);
    is_deeply($obj, { a => 1, b => [2, 3] }, 'read_json_file decodes JSON');
}

{
    my $tmp = tempdir(CLEANUP => 1);
    my $path = "$tmp/missing.json";
    eval { read_json_file($path) };
    like($@, qr/cannot open/, 'read_json_file dies on missing file');
}

{
    my $tmp = tempdir(CLEANUP => 1);
    my $path = "$tmp/bad.json";
    open my $fh, '>:raw', $path or die $!;
    print $fh '{not json';
    close $fh;
    eval { read_json_file($path) };
    like($@, qr/cannot parse/, 'read_json_file dies on bad JSON');
}

# atomic_write_text + atomic_write_json --------------------------------------
{
    my $tmp = tempdir(CLEANUP => 1);
    my $path = "$tmp/out.json";
    atomic_write_json($path, { x => [1,2], y => 'z' });
    ok(-f $path, 'atomic_write_json writes file');
    my $obj = read_json_file($path);
    is_deeply($obj, { x => [1,2], y => 'z' }, 'round-trips structure');
    my $perms = (stat($path))[2] & 07777;
    is($perms, 0644, 'atomic_write_json sets default mode 0644');
}

{
    my $tmp = tempdir(CLEANUP => 1);
    my $path = "$tmp/sub/dir/out.txt";
    atomic_write_text($path, "hello\n");
    ok(-f $path, 'atomic_write_text creates intermediate dirs');
    open my $fh, '<:raw', $path or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;
    is($content, "hello\n", 'atomic_write_text writes content');
}

{
    my $tmp = tempdir(CLEANUP => 1);
    my $path = "$tmp/perm.txt";
    atomic_write_text($path, "x", mode => 0600);
    my $perms = (stat($path))[2] & 07777;
    is($perms, 0600, 'atomic_write_text honours mode opt');
}

# validate_path_allowlist -----------------------------------------------------
{
    my @ok = ('.cwf/foo', '.cwf-rules/x.md', 'CLAUDE.md');
    my @prefixes = ('.cwf/', '.cwf-rules/', 'CLAUDE.md');
    for my $p (@ok) {
        ok(eval { validate_path_allowlist($p, \@prefixes) }, "accepts $p");
    }
}

{
    my @prefixes = ('.cwf/');
    eval { validate_path_allowlist('/etc/passwd', \@prefixes) };
    like($@, qr/absolute/, 'rejects absolute path');

    eval { validate_path_allowlist('.cwf/../etc/passwd', \@prefixes) };
    like($@, qr/'\.\.'/, 'rejects path containing ..');

    eval { validate_path_allowlist('../etc/passwd', \@prefixes) };
    like($@, qr/'\.\.'/, 'rejects leading ..');

    eval { validate_path_allowlist('not/allowed', \@prefixes) };
    like($@, qr/allowed prefix/, 'rejects path outside allowlist');

    eval { validate_path_allowlist(undef, \@prefixes) };
    like($@, qr/undef/, 'rejects undef');

    eval { validate_path_allowlist('', \@prefixes) };
    like($@, qr/empty/, 'rejects empty');
}

# compute_file_sha256 ---------------------------------------------------------
{
    my $tmp = tempdir(CLEANUP => 1);
    my $path = "$tmp/empty";
    open my $fh, '>:raw', $path or die $!;
    close $fh;
    my $sha = compute_file_sha256($path);
    is($sha, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
       'empty-file SHA256 matches well-known constant');
}

{
    is(compute_file_sha256('/no/such/file/anywhere'), '',
       'returns empty string for missing file');
}

# read_file_raw ---------------------------------------------------------------
{
    my $tmp = tempdir(CLEANUP => 1);
    my $path = "$tmp/raw.bin";
    my $bytes = "\x00\x01\xff\nhello";
    open my $fh, '>:raw', $path or die $!;
    print $fh $bytes;
    close $fh;
    is(read_file_raw($path), $bytes, 'read_file_raw preserves bytes');
}

done_testing();
