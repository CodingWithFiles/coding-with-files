#!/usr/bin/env perl
#
# cwf-version-next.t - Integration tests for the cwf-version-next helper
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Cwd qw(cwd);
use FindBin;

my $SCRIPT = "$FindBin::Bin/../.cwf/scripts/command-helpers/cwf-version-next";
my $orig_cwd = cwd();

sub make_repo {
    my ($config_json) = @_;
    my $dir = tempdir(CLEANUP => 1);
    chdir $dir or die $!;
    system("git init -q") == 0 or die;
    if (defined $config_json) {
        make_path("$dir/implementation-guide");
        open my $fh, '>', "$dir/implementation-guide/cwf-project.json" or die $!;
        print $fh $config_json;
        close $fh;
    }
    return $dir;
}

sub run_script {
    my @args = @_;
    my $cmd = join(' ', $SCRIPT, @args) . ' 2>&1';
    my $out = `$cmd`;
    return ($? >> 8, $out);
}

subtest 'TC-S1 missing required arg → exit 1' => sub {
    plan tests => 2;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');
    my ($exit, $out) = run_script();
    is($exit, 1, 'exit 1 with no args');
    like($out, qr/--task-num=N/, 'usage names the required arg');
    chdir $orig_cwd;
};

subtest 'TC-S2 bad args → exit 1' => sub {
    plan tests => 4;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');
    my ($exit, $out);

    ($exit, $out) = run_script('--task-num=abc');
    is($exit, 1, '--task-num=abc → exit 1');

    ($exit, $out) = run_script('--task-num=0');
    is($exit, 1, '--task-num=0 → exit 1');

    ($exit, $out) = run_script('--task-num=-1');
    is($exit, 1, '--task-num=-1 → exit 1');

    ($exit, $out) = run_script('--unknown=foo');
    is($exit, 1, 'unknown arg → exit 1');
    chdir $orig_cwd;
};

subtest 'TC-S3 happy path' => sub {
    plan tests => 2;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');
    my ($exit, $out) = run_script('--task-num=114');
    is($exit, 0, 'exit 0');
    is($out, "v1.0.114\n", 'stdout exactly v1.0.114');
    chdir $orig_cwd;
};

subtest '--help → exit 0' => sub {
    plan tests => 2;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');
    my ($exit, $out) = run_script('--help');
    is($exit, 0, '--help exits 0');
    like($out, qr/Usage:/, '--help prints usage');
    chdir $orig_cwd;
};

subtest 'missing major_minor → exit 1 with field name' => sub {
    plan tests => 2;
    make_repo('{ }');
    my ($exit, $out) = run_script('--task-num=114');
    is($exit, 1, 'exit 1');
    like($out, qr/versioning\.major_minor missing/, 'names the field');
    chdir $orig_cwd;
};

subtest 'TC-163-1 subtask number → clean skip, no version printed' => sub {
    plan tests => 2;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');
    my ($exit, $out) = run_script('--task-num=3.2');
    is($exit, 0, 'exit 0');
    like($out, qr/^skipped: version actions apply to top-level tasks only \(subtask 3\.2\)/, 'skip line');
    chdir $orig_cwd;
};

subtest 'TC-163-2 subtask skip short-circuits before read_config' => sub {
    plan tests => 2;
    make_repo(undef);
    my ($exit, $out) = run_script('--task-num=3.2');
    is($exit, 0, 'exit 0 with no config present');
    like($out, qr/^skipped: version actions/, 'skip line, not a config error');
    chdir $orig_cwd;
};

subtest 'TC-163-3 malformed dotted value → error, not skip' => sub {
    plan tests => 3;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');
    for my $bad ('3.', '.2', '3..2') {
        my ($exit, $out) = run_script("--task-num=$bad");
        is($exit, 1, "--task-num=$bad → exit 1 (unknown argument)");
    }
    chdir $orig_cwd;
};

done_testing();
