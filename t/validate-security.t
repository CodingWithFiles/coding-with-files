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

done_testing();
