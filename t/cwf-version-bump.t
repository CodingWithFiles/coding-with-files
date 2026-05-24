#!/usr/bin/env perl
#
# cwf-version-bump.t - Integration tests for the cwf-version-bump helper
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Cwd qw(cwd);
use JSON::PP;
use FindBin;

my $SCRIPT = "$FindBin::Bin/../.cwf/scripts/command-helpers/cwf-version-bump";
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

sub read_cfg {
    open my $fh, '<', 'implementation-guide/cwf-project.json' or die $!;
    local $/; my $blob = <$fh>; close $fh;
    return decode_json($blob);
}

subtest 'TC-S4a bumped (default config: bump_version on)' => sub {
    plan tests => 3;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');
    my ($exit, $out) = run_script('--task-num=114');
    is($exit, 0, 'exit 0');
    like($out, qr/^bumped: v1\.0\.114/, 'stdout: bumped');
    is(read_cfg()->{versioning}{last_released}, 'v1.0.114', 'last_released written');
    chdir $orig_cwd;
};

subtest 'TC-S4b skipped (bump_version=false)' => sub {
    plan tests => 3;
    make_repo('{
      "versioning": { "major_minor": "v1.0" },
      "wf_step_config": { "retrospective": { "bump_version": false } }
    }');
    my ($exit, $out) = run_script('--task-num=114');
    is($exit, 0, 'exit 0');
    like($out, qr/^skipped: bump_version=false/, 'stdout: skipped');
    is(read_cfg()->{versioning}{last_released}, undef, 'last_released untouched');
    chdir $orig_cwd;
};

subtest 'TC-S4c idempotent' => sub {
    plan tests => 2;
    make_repo('{
      "versioning": { "major_minor": "v1.0", "last_released": "v1.0.114" }
    }');
    my ($exit, $out) = run_script('--task-num=114');
    is($exit, 0, 'exit 0');
    like($out, qr/^already at v1\.0\.114/, 'stdout: already at');
    chdir $orig_cwd;
};

subtest 'TC-S5 missing major_minor → exit 1 with file path' => sub {
    plan tests => 3;
    make_repo('{ }');
    my ($exit, $out) = run_script('--task-num=114');
    is($exit, 1, 'exit 1');
    like($out, qr/versioning\.major_minor missing/, 'names the field');
    like($out, qr{implementation-guide/cwf-project\.json}, 'names the file path');
    chdir $orig_cwd;
};

subtest 'missing required arg → exit 1' => sub {
    plan tests => 2;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');
    my ($exit, $out) = run_script();
    is($exit, 1, 'exit 1');
    like($out, qr/--task-num=N/, 'usage shown');
    chdir $orig_cwd;
};

subtest 'TC-163-1 subtask number → clean skip, no write' => sub {
    plan tests => 3;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');
    my ($exit, $out) = run_script('--task-num=3.2');
    is($exit, 0, 'exit 0');
    like($out, qr/^skipped: version actions apply to top-level tasks only \(subtask 3\.2\)/, 'skip line');
    is(read_cfg()->{versioning}{last_released}, undef, 'last_released untouched');
    chdir $orig_cwd;
};

subtest 'TC-163-2 subtask skip short-circuits before read_config' => sub {
    plan tests => 4;
    # No cwf-project.json at all: read_config would die "not found".
    make_repo(undef);
    my ($exit, $out) = run_script('--task-num=3.2');
    is($exit, 0, 'exit 0 with no config present');
    like($out, qr/^skipped: version actions/, 'skip line, not a config error');
    chdir $orig_cwd;
    # Malformed config (no major_minor): read_config would die.
    make_repo('{ }');
    ($exit, $out) = run_script('--task-num=3.2');
    is($exit, 0, 'exit 0 with malformed config');
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
