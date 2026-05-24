#!/usr/bin/env perl
#
# versioning.t - Unit tests for CWF::Versioning
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Cwd qw(cwd);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";

BEGIN { use_ok('CWF::Versioning', qw(read_config wf_step_setting next_version current_version bump_to tag_at config_path is_subtask_num)) }

# ---------------------------------------------------------------------------
# Test fixture: chdir into a tempdir holding a fresh git repo with
# implementation-guide/cwf-project.json containing $config_json.
# ---------------------------------------------------------------------------
sub make_repo {
    my ($config_json) = @_;
    my $dir = tempdir(CLEANUP => 1);
    chdir $dir or die "chdir $dir: $!";
    system("git init -q") == 0 or die "git init failed";
    system("git config user.email test\@example.com") == 0 or die;
    system("git config user.name  Test") == 0 or die;
    if (defined $config_json) {
        make_path("$dir/implementation-guide");
        open my $fh, '>', "$dir/implementation-guide/cwf-project.json" or die $!;
        print $fh $config_json;
        close $fh;
    }
    return $dir;
}

my $orig_cwd = cwd();

#==============================================================================
# read_config() - error paths
#==============================================================================

subtest 'TC-V1 read_config: file missing' => sub {
    plan tests => 1;
    make_repo(undef);
    eval { read_config() };
    like($@, qr/cwf-project\.json not found at/, 'dies naming the missing path');
    chdir $orig_cwd;
};

subtest 'TC-V2 read_config: malformed JSON' => sub {
    plan tests => 1;
    make_repo("{ this is not json");
    eval { read_config() };
    like($@, qr/Invalid JSON in/, 'dies identifying the file and parse error');
    chdir $orig_cwd;
};

subtest 'TC-V3 read_config: missing major_minor (no versioning block)' => sub {
    plan tests => 1;
    make_repo('{ "supported-task-types": ["feature"] }');
    eval { read_config() };
    like($@, qr/versioning\.major_minor missing/, 'dies naming the field');
    chdir $orig_cwd;
};

subtest 'TC-V4 read_config: malformed major_minor' => sub {
    plan tests => 2;
    make_repo('{ "versioning": { "major_minor": "1.0" } }');
    eval { read_config() };
    like($@, qr/versioning\.major_minor malformed/, 'dies on missing v-prefix');
    chdir $orig_cwd;

    make_repo('{ "versioning": { "major_minor": "v1" } }');
    eval { read_config() };
    like($@, qr/versioning\.major_minor malformed/, 'dies on missing minor');
    chdir $orig_cwd;
};

#==============================================================================
# wf_step_setting()
#==============================================================================

subtest 'TC-V5 wf_step_setting: defaults applied' => sub {
    plan tests => 2;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');
    is(wf_step_setting('retrospective', 'bump_version', 1), 1, 'default 1 returned');
    is(wf_step_setting('retrospective', 'tag_version',  0), 0, 'default 0 returned');
    chdir $orig_cwd;
};

subtest 'TC-V6 wf_step_setting: explicit override' => sub {
    plan tests => 2;
    make_repo('{
      "versioning": { "major_minor": "v1.0" },
      "wf_step_config": {
        "retrospective": { "bump_version": false, "tag_version": true }
      }
    }');
    is(wf_step_setting('retrospective', 'bump_version', 1), 0, 'false override');
    is(wf_step_setting('retrospective', 'tag_version',  0), 1, 'true override');
    chdir $orig_cwd;
};

#==============================================================================
# next_version() / current_version()
#==============================================================================

subtest 'TC-V7 next_version composition' => sub {
    plan tests => 1;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');
    is(next_version(task_num => 114), 'v1.0.114', 'composes major_minor + task_num');
    chdir $orig_cwd;
};

subtest 'TC-V7b next_version: rejects bad task_num' => sub {
    plan tests => 3;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');
    eval { next_version() };
    like($@, qr/task_num required/, 'missing task_num');
    eval { next_version(task_num => 0) };
    like($@, qr/task_num required/, 'zero rejected');
    eval { next_version(task_num => 'abc') };
    like($@, qr/task_num required/, 'non-numeric rejected');
    chdir $orig_cwd;
};

subtest 'TC-V7c is_subtask_num: truth table (no repo needed)' => sub {
    plan tests => 9;
    # true: one or more dotted segments
    ok( is_subtask_num('3.2'),    '3.2 is a subtask');
    ok( is_subtask_num('3.2.1'),  '3.2.1 is a subtask');
    ok( is_subtask_num('163.4'),  '163.4 is a subtask');
    # false: bare integer (top-level)
    ok(!is_subtask_num('163'),    '163 is top-level, not a subtask');
    # false: malformed (locks contract independent of any caller capture regex)
    ok(!is_subtask_num('3.'),     'trailing dot is not a subtask');
    ok(!is_subtask_num('.2'),     'leading dot is not a subtask');
    ok(!is_subtask_num('3..2'),   'double dot is not a subtask');
    ok(!is_subtask_num('x'),      'non-numeric is not a subtask');
    ok(!is_subtask_num(undef),    'undef is not a subtask');
};

subtest 'TC-V8 current_version: absent vs present' => sub {
    plan tests => 2;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');
    is(current_version(), undef, 'undef when last_released absent');
    chdir $orig_cwd;

    make_repo('{ "versioning": { "major_minor": "v1.0", "last_released": "v1.0.113" } }');
    is(current_version(), 'v1.0.113', 'returns last_released when present');
    chdir $orig_cwd;
};

#==============================================================================
# bump_to()
#==============================================================================

# Helper: read current cwf-project.json into a hashref
sub read_raw_config {
    my $path = 'implementation-guide/cwf-project.json';
    open my $fh, '<', $path or die $!;
    local $/; my $blob = <$fh>; close $fh;
    return JSON::PP::decode_json($blob);
}

subtest 'TC-V9 bump_to: skipped when bump_version=false' => sub {
    plan tests => 3;
    make_repo('{
      "versioning": { "major_minor": "v1.0" },
      "wf_step_config": { "retrospective": { "bump_version": false } }
    }');
    my $mtime_before = (stat 'implementation-guide/cwf-project.json')[9];
    sleep 1;  # ensure mtime resolution catches a write
    my $r = bump_to('v1.0.114');
    is($r->{status}, 'skipped', 'returns skipped status');
    like($r->{message}, qr/bump_version=false/, 'message names the flag');
    my $mtime_after = (stat 'implementation-guide/cwf-project.json')[9];
    is($mtime_after, $mtime_before, 'file untouched');
    chdir $orig_cwd;
};

subtest 'TC-V10 bump_to: idempotent when last_released equals target' => sub {
    plan tests => 3;
    make_repo('{
      "versioning": { "major_minor": "v1.0", "last_released": "v1.0.114" }
    }');
    my $mtime_before = (stat 'implementation-guide/cwf-project.json')[9];
    sleep 1;
    my $r = bump_to('v1.0.114');
    is($r->{status}, 'idempotent', 'returns idempotent status');
    like($r->{message}, qr/already at v1\.0\.114/, 'message names current');
    my $mtime_after = (stat 'implementation-guide/cwf-project.json')[9];
    is($mtime_after, $mtime_before, 'file untouched on idempotent path');
    chdir $orig_cwd;
};

subtest 'TC-V11 bump_to: writes valid JSON, preserves other keys' => sub {
    plan tests => 4;
    make_repo('{
      "supported-task-types": ["feature"],
      "versioning": { "major_minor": "v1.0" },
      "extra_block": { "preserved": "value", "n": 42 }
    }');
    my $r = bump_to('v1.0.114');
    is($r->{status}, 'bumped', 'returns bumped status');

    my $cfg = read_raw_config();
    is($cfg->{versioning}{last_released}, 'v1.0.114', 'last_released written');
    is($cfg->{extra_block}{preserved},     'value',    'sibling block preserved');
    is($cfg->{extra_block}{n},             42,         'sibling value preserved');
    chdir $orig_cwd;
};

subtest 'TC-V12 bump_to: temp file is in same dir as target (atomic-rename safety)' => sub {
    plan tests => 1;
    make_repo('{ "versioning": { "major_minor": "v1.0" } }');

    # Wrap rename to capture the source path before letting it through
    my $tmp_dir;
    {
        no warnings 'redefine';
        my $orig_rename = \&CORE::GLOBAL::rename;
        local *CORE::GLOBAL::rename = sub ($$) {
            my ($from, $to) = @_;
            $tmp_dir = (File::Spec->splitpath($from))[1];
            $orig_rename ? $orig_rename->($from, $to) : CORE::rename($from, $to);
        };
        require File::Spec;
        bump_to('v1.0.114');
    }
    # Just verify temp file got placed in implementation-guide/, not /tmp etc
    SKIP: {
        skip "rename hook did not capture", 1 unless defined $tmp_dir;
        like($tmp_dir, qr{implementation-guide/?$}, "temp file under implementation-guide/");
    }
    chdir $orig_cwd;
};

#==============================================================================
# tag_at()
#==============================================================================

# Helper: prepare a repo with main branch and one commit, optional tag_version setting
sub make_repo_with_main {
    my ($extra_config) = @_;
    $extra_config //= '';
    my $config = '{
      "versioning": { "major_minor": "v1.0" }' . ($extra_config ? ", $extra_config" : '') . '
    }';
    my $dir = make_repo($config);
    # Ensure default branch is main (some git versions default to master)
    system("git checkout -q -B main") == 0 or die;
    # Need a commit so HEAD exists
    open my $fh, '>', 'README.md' or die $!;
    print $fh "x"; close $fh;
    system("git add README.md && git commit -q -m initial") == 0 or die;
    return $dir;
}

subtest 'TC-V14 tag_at: skipped when tag_version=false (CwF default)' => sub {
    plan tests => 3;
    make_repo_with_main('"wf_step_config": { "retrospective": { "tag_version": false } }');
    my $r = tag_at('v1.0.114');
    is($r->{status}, 'skipped', 'returns skipped status');
    like($r->{message}, qr/tag_version=false/, 'message names the flag');
    my $tags = `git tag -l 'v1.0.114'`;
    chomp $tags;
    is($tags, '', 'no tag created');
    chdir $orig_cwd;
};

subtest 'TC-V14b tag_at: skipped by default when no flag set' => sub {
    plan tests => 1;
    make_repo_with_main();
    my $r = tag_at('v1.0.114');
    is($r->{status}, 'skipped', 'default (false) skips tagging');
    chdir $orig_cwd;
};

subtest 'TC-V15 tag_at: refuses off main branch' => sub {
    plan tests => 2;
    make_repo_with_main('"wf_step_config": { "retrospective": { "tag_version": true } }');
    system("git checkout -q -b feature/foo") == 0 or die;
    my $r = tag_at('v1.0.114');
    is($r->{status}, 'error', 'returns error status');
    like($r->{message}, qr/not on main/, 'message names the issue');
    chdir $orig_cwd;
};

subtest 'TC-V16 tag_at: refuses on existing tag' => sub {
    plan tests => 2;
    make_repo_with_main('"wf_step_config": { "retrospective": { "tag_version": true } }');
    system("git tag v1.0.114") == 0 or die;
    my $r = tag_at('v1.0.114');
    is($r->{status}, 'error', 'returns error');
    like($r->{message}, qr/already exists/, 'message names the issue');
    chdir $orig_cwd;
};

subtest 'TC-V17 tag_at: creates annotated tag on success' => sub {
    plan tests => 3;
    make_repo_with_main('"wf_step_config": { "retrospective": { "tag_version": true } }');
    my $r = tag_at('v1.0.114', message => 'Task 114');
    is($r->{status}, 'tagged', 'returns tagged status');
    my $tags = `git tag -l 'v1.0.114'`;
    chomp $tags;
    is($tags, 'v1.0.114', 'tag exists');
    my $type = `git cat-file -t v1.0.114`;
    chomp $type;
    is($type, 'tag', 'tag is annotated (object type "tag", not "commit")');
    chdir $orig_cwd;
};

done_testing();
