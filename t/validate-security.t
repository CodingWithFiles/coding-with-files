#!/usr/bin/env perl
#
# validate-security.t - Unit tests for CWF::Validate::Security
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Digest::SHA qw(sha256_hex);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('CWF::Validate::Security', qw(validate)) }

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
}

sub file_sha256 {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return sha256_hex($content);
}

#==============================================================================
# validate()
#==============================================================================

subtest 'validate() - missing script-hashes.json returns violation' => sub {
    plan tests => 2;

    my $tmp = tempdir(CLEANUP => 1);
    my @v = validate($tmp);

    is(scalar @v, 1, 'one violation for missing hashes file');
    is($v[0]{field}, 'file', 'violation field = file');
};

subtest 'validate() - valid hash and permissions → no violations' => sub {
    plan tests => 1;

    my $tmp = tempdir(CLEANUP => 1);
    make_path("$tmp/.cwf/security");
    make_path("$tmp/.cwf/scripts");

    my $script = "$tmp/.cwf/scripts/test-script";
    write_file($script, "#!/bin/sh\necho hello\n");
    chmod 0755, $script;

    my $sha = file_sha256($script);
    my $json = sprintf(
        '{"scripts":{"test-script":{"path":".cwf/scripts/test-script","sha256":"%s","permissions":"0755"}}}',
        $sha
    );
    write_file("$tmp/.cwf/security/script-hashes.json", $json);

    my @v = validate($tmp);
    is(scalar @v, 0, 'correct hash + permissions → no violations');
};

subtest 'validate() - wrong SHA256 returns violation' => sub {
    plan tests => 2;

    my $tmp = tempdir(CLEANUP => 1);
    make_path("$tmp/.cwf/security");
    make_path("$tmp/.cwf/scripts");

    my $script = "$tmp/.cwf/scripts/test-script2";
    write_file($script, "#!/bin/sh\necho hello\n");
    chmod 0755, $script;

    my $wrong_sha = 'a' x 64;
    my $json = sprintf(
        '{"scripts":{"test-script2":{"path":".cwf/scripts/test-script2","sha256":"%s","permissions":"0755"}}}',
        $wrong_sha
    );
    write_file("$tmp/.cwf/security/script-hashes.json", $json);

    my @v = validate($tmp);
    ok(@v > 0, 'wrong hash → violation');
    is($v[0]{field}, 'sha256', 'violation field = sha256');
};

subtest 'validate() - missing file returns existence violation' => sub {
    plan tests => 1;

    my $tmp = tempdir(CLEANUP => 1);
    make_path("$tmp/.cwf/security");

    my $json = '{"scripts":{"missing":{"path":".cwf/scripts/nonexistent","sha256":"aabbcc","permissions":"0755"}}}';
    write_file("$tmp/.cwf/security/script-hashes.json", $json);

    my @v = validate($tmp);
    ok((grep { $_->{field} eq 'existence' } @v), 'missing file → existence violation');
};

#==============================================================================
# Ceiling permission check (recorded perms are an upper bound)
#==============================================================================

# Build a single-entry tree with a sha-correct script at $on_disk_perms and
# recorded $recorded_perms; return validate()'s violations.
sub ceiling_violations {
    my ($recorded_perms, $on_disk_perms) = @_;
    my $tmp = tempdir(CLEANUP => 1);
    make_path("$tmp/.cwf/security");
    make_path("$tmp/.cwf/scripts");

    my $script = "$tmp/.cwf/scripts/test-script";
    write_file($script, "#!/bin/sh\necho hello\n");
    chmod $on_disk_perms, $script;

    my $sha = file_sha256($script);
    my $json = sprintf(
        '{"scripts":{"test-script":{"path":".cwf/scripts/test-script","sha256":"%s","permissions":"%s"}}}',
        $sha, $recorded_perms
    );
    write_file("$tmp/.cwf/security/script-hashes.json", $json);
    return validate($tmp);
}

subtest 'TC-A1: over-permissive flags (recorded 0444, on disk 0666)' => sub {
    plan tests => 4;

    my @v = ceiling_violations('0444', 0666);
    my @perm = grep { $_->{field} eq 'permissions' } @v;
    is(scalar @perm, 1, 'one permissions violation');
    is($perm[0]{actual},   '0666', 'actual mode reported as 0666');
    is($perm[0]{expected}, '0444', 'recorded mode reported as 0444');
    ok(!(grep { $_->{field} ne 'permissions' } @v), 'no other violations (sha intact)');
};

subtest 'TC-A2: under-permissive allowed (recorded 0500, on disk 0400)' => sub {
    plan tests => 1;

    my @v = ceiling_violations('0500', 0400);
    is(scalar @v, 0, 'less permissive than recorded → no violation (the inversion)');
};

subtest 'TC-A3: setuid acquisition flags (recorded 0500, on disk 04500)' => sub {
    plan tests => 3;

    for my $high (04500, 02500, 01500) {
        my @perm = grep { $_->{field} eq 'permissions' } ceiling_violations('0500', $high);
        ok(scalar @perm >= 1,
            sprintf('high bit 0%o not in recorded → ceiling violation', $high & 07000));
    }
};

subtest 'TC-A4: exact recorded → no violation' => sub {
    plan tests => 1;

    my @v = ceiling_violations('0500', 0500);
    is(scalar @v, 0, 'mode equal to recorded → no violation');
};

subtest 'TC-A5: unrecorded entry (no permissions key) unaffected at 0777' => sub {
    plan tests => 1;

    my $tmp = tempdir(CLEANUP => 1);
    make_path("$tmp/.cwf/security");
    make_path("$tmp/.cwf/lib");

    my $lib = "$tmp/.cwf/lib/Thing.pm";
    write_file($lib, "package Thing; 1;\n");
    chmod 0777, $lib;

    my $sha = file_sha256($lib);
    my $json = sprintf(
        '{"lib":{"Thing":{"path":".cwf/lib/Thing.pm","sha256":"%s"}}}',
        $sha
    );
    write_file("$tmp/.cwf/security/script-hashes.json", $json);

    my @perm = grep { $_->{field} eq 'permissions' } validate($tmp);
    is(scalar @perm, 0, 'entry without permissions key → no permissions check');
};

subtest 'TC-A6: ceiling hint points at excess/fix-security, not chmod <recorded>' => sub {
    plan tests => 2;

    my ($perm) = grep { $_->{field} eq 'permissions' } ceiling_violations('0444', 0666);
    like($perm->{fix}, qr/fix-security/, 'hint references fix-security');
    unlike($perm->{fix}, qr/chmod 0444/, 'hint does not instruct chmod to recorded');
};

done_testing();
