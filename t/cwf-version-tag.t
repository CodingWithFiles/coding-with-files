#!/usr/bin/env perl
#
# cwf-version-tag.t - Integration tests for the cwf-version-tag helper
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Cwd qw(cwd);
use FindBin;

my $SCRIPT = "$FindBin::Bin/../.cwf/scripts/command-helpers/cwf-version-tag";
my $orig_cwd = cwd();

sub make_repo_with_main {
    my ($extra_config) = @_;
    $extra_config //= '';
    my $config = '{
      "versioning": { "major_minor": "v1.0" }' . ($extra_config ? ", $extra_config" : '') . '
    }';
    my $dir = tempdir(CLEANUP => 1);
    chdir $dir or die $!;
    system("git init -q") == 0 or die;
    system("git config user.email test\@example.com") == 0 or die;
    system("git config user.name  Test") == 0 or die;
    system("git checkout -q -B main") == 0 or die;
    make_path("$dir/implementation-guide");
    open my $fh, '>', "$dir/implementation-guide/cwf-project.json" or die $!;
    print $fh $config;
    close $fh;
    open my $fr, '>', 'README.md' or die $!;
    print $fr "x"; close $fr;
    system("git add . && git commit -q -m initial") == 0 or die;
    return $dir;
}

sub run_script {
    my @args = @_;
    my $cmd = join(' ', $SCRIPT, @args) . ' 2>&1';
    my $out = `$cmd`;
    return ($? >> 8, $out);
}

subtest 'TC-S6 skipped (tag_version=false, CwF default)' => sub {
    plan tests => 3;
    make_repo_with_main('"wf_step_config": { "retrospective": { "tag_version": false } }');
    my ($exit, $out) = run_script('--task-num=114', '--message="Task 114"');
    is($exit, 0, 'exit 0');
    like($out, qr/^skipped: tag_version=false/, 'stdout: skipped');
    my $tags = `git tag -l 'v1.0.114'`;
    chomp $tags;
    is($tags, '', 'no tag created');
    chdir $orig_cwd;
};

subtest 'TC-S7 success on main, no existing tag' => sub {
    plan tests => 3;
    make_repo_with_main('"wf_step_config": { "retrospective": { "tag_version": true } }');
    my ($exit, $out) = run_script('--task-num=114', '--message=Task_114');
    is($exit, 0, 'exit 0');
    like($out, qr/^tagged: v1\.0\.114/, 'stdout: tagged');
    my $tags = `git tag -l 'v1.0.114'`;
    chomp $tags;
    is($tags, 'v1.0.114', 'tag exists');
    chdir $orig_cwd;
};

subtest 'TC-S8 refuses off main' => sub {
    plan tests => 2;
    make_repo_with_main('"wf_step_config": { "retrospective": { "tag_version": true } }');
    system("git checkout -q -b feature/foo") == 0 or die;
    my ($exit, $out) = run_script('--task-num=114', '--message=Task_114');
    is($exit, 1, 'exit 1');
    like($out, qr/not on main/, 'message names the issue');
    chdir $orig_cwd;
};

subtest 'refuses on existing tag' => sub {
    plan tests => 2;
    make_repo_with_main('"wf_step_config": { "retrospective": { "tag_version": true } }');
    system("git tag v1.0.114") == 0 or die;
    my ($exit, $out) = run_script('--task-num=114');
    is($exit, 1, 'exit 1');
    like($out, qr/already exists/, 'message names the issue');
    chdir $orig_cwd;
};

subtest 'missing required arg → exit 1' => sub {
    plan tests => 1;
    make_repo_with_main();
    my ($exit, $out) = run_script();
    is($exit, 1, 'exit 1 without --task-num');
    chdir $orig_cwd;
};

subtest 'TC-163-1 subtask number → clean skip, no tag created' => sub {
    plan tests => 3;
    make_repo_with_main('"wf_step_config": { "retrospective": { "tag_version": true } }');
    my ($exit, $out) = run_script('--task-num=3.2');
    is($exit, 0, 'exit 0');
    like($out, qr/^skipped: version actions apply to top-level tasks only \(subtask 3\.2\)/, 'skip line');
    my $tags = `git tag -l`;
    chomp $tags;
    is($tags, '', 'no tag created');
    chdir $orig_cwd;
};

subtest 'TC-163-5 subtask skip with --message present, both arg orders' => sub {
    plan tests => 4;
    make_repo_with_main('"wf_step_config": { "retrospective": { "tag_version": true } }');
    my ($exit, $out) = run_script('--task-num=3.2', '--message=foo');
    is($exit, 0, 'task-num then message → exit 0');
    like($out, qr/^skipped: version actions/, 'skip line (task-num first)');
    ($exit, $out) = run_script('--message=foo', '--task-num=3.2');
    is($exit, 0, 'message then task-num → exit 0');
    like($out, qr/^skipped: version actions/, 'skip line (message first)');
    chdir $orig_cwd;
};

subtest 'TC-163-2 subtask skip short-circuits before read_config' => sub {
    plan tests => 2;
    # Bare git repo, no cwf-project.json: read_config would die "not found".
    my $dir = tempdir(CLEANUP => 1);
    chdir $dir or die $!;
    system("git init -q") == 0 or die;
    my ($exit, $out) = run_script('--task-num=3.2');
    is($exit, 0, 'exit 0 with no config present');
    like($out, qr/^skipped: version actions/, 'skip line, not a config error');
    chdir $orig_cwd;
};

subtest 'TC-163-3 malformed dotted value → error, not skip' => sub {
    plan tests => 3;
    make_repo_with_main();
    for my $bad ('3.', '.2', '3..2') {
        my ($exit, $out) = run_script("--task-num=$bad");
        is($exit, 1, "--task-num=$bad → exit 1 (unknown argument)");
    }
    chdir $orig_cwd;
};

done_testing();
