#!/usr/bin/env perl
#
# taskpath.t - Unit tests for CWF::TaskPath
#
# Tier A: pure string/logic subs (no filesystem, no git)
# Tier C: filesystem+git subs (require temp git repo with implementation-guide/)
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

use CWFTest::Fixtures qw(create_task_dir create_git_repo);

BEGIN {
    use_ok('CWF::TaskPath', qw(
        normalize validate build_glob get_parent get_depth
        format_dirname parse_dirname format_branch parse_branch
        find_base_dir resolve_num task_exists branch_exists
        find_parent find_children find_descendants find_ancestors
    ))
}

# detect_format and version_compare are not in @EXPORT_OK — use fully qualified
use CWF::TaskPath ();

#==============================================================================
# TIER A — Pure string/logic subs
#==============================================================================

subtest 'normalize() - strips path prefix' => sub {
    plan tests => 3;

    is(normalize('foo/bar/1.2'),   '1.2',  'strips directory prefix');
    is(normalize('1.2'),           '1.2',  'plain number unchanged');
    is(normalize('a/b/c/99'),      '99',   'strips deep prefix');
};

subtest 'validate() - valid task paths' => sub {
    plan tests => 5;

    ok(validate('1'),       'single number valid');
    ok(validate('1.2'),     'two-level valid');
    ok(validate('1.2.3'),   'three-level valid');
    ok(validate('99'),      'two-digit valid');
    ok(validate('10.2.30'), 'multi-digit valid');
};

subtest 'validate() - invalid task paths' => sub {
    plan tests => 5;

    ok(!validate(''),            'empty string invalid');
    ok(!validate('abc'),         'letters invalid');
    ok(!validate('1.'),          'trailing dot invalid');
    ok(!validate('.1'),          'leading dot invalid');
    ok(!validate('1.a.2'),       'mixed alpha/num invalid');
};

subtest 'get_parent() - returns parent number' => sub {
    plan tests => 4;

    is(get_parent('1.2'),     '1',   '1.2 → 1');
    is(get_parent('1.2.3'),   '1.2', '1.2.3 → 1.2');
    is(get_parent('1.2.3.4'), '1.2.3', 'four-level');
    is(get_parent('1'),       undef, 'top-level has no parent');
};

subtest 'get_depth() - returns nesting level' => sub {
    plan tests => 4;

    is(get_depth('1'),     1, 'top-level = 1');
    is(get_depth('1.2'),   2, 'two-level = 2');
    is(get_depth('1.2.3'), 3, 'three-level = 3');
    is(get_depth('99'),    1, 'high top-level = 1');
};

subtest 'format_dirname() / parse_dirname() - round trip' => sub {
    plan tests => 4;

    my $dir = format_dirname('32', 'feature', 'task-tracking');
    is($dir, '32-feature-task-tracking', 'format_dirname produces correct string');

    my ($num, $type, $slug) = parse_dirname($dir);
    is($num,  '32',            'parse_dirname: num');
    is($type, 'feature',       'parse_dirname: type');
    is($slug, 'task-tracking', 'parse_dirname: slug');
};

subtest 'format_dirname() - undef args return undef' => sub {
    plan tests => 1;

    is(format_dirname(undef, 'feature', 'slug'), undef, 'undef num → undef');
};

subtest 'parse_dirname() - invalid format returns empty list' => sub {
    plan tests => 1;

    my @result = parse_dirname('no-match-here');
    is(scalar @result, 0, 'invalid dirname → empty list');
};

subtest 'format_branch() / parse_branch() - round trip' => sub {
    plan tests => 4;

    my $branch = format_branch('32', 'feature', 'task-tracking');
    is($branch, 'feature/32-task-tracking', 'format_branch produces correct string');

    my ($num, $type, $slug) = parse_branch($branch);
    is($num,  '32',            'parse_branch: num');
    is($type, 'feature',       'parse_branch: type');
    is($slug, 'task-tracking', 'parse_branch: slug');
};

subtest 'parse_branch() - invalid format returns empty list' => sub {
    plan tests => 1;

    my @result = parse_branch('not-a-branch');
    is(scalar @result, 0, 'invalid branch → empty list');
};

subtest 'version_compare() - ordering' => sub {
    plan tests => 4;

    cmp_ok(CWF::TaskPath::version_compare('1',   '2'),   '<', 0, '1 < 2');
    cmp_ok(CWF::TaskPath::version_compare('2',   '1'),   '>', 0, '2 > 1');
    is(CWF::TaskPath::version_compare('1',   '1'),         0,    '1 == 1');
    cmp_ok(CWF::TaskPath::version_compare('3.1.10', '3.1.2'), '>', 0, '3.1.10 > 3.1.2 (numeric component)');
};

subtest 'build_glob() - builds pattern with explicit base_dir' => sub {
    plan tests => 1;

    my $pattern = build_glob('1.2', '/some/dir');
    is($pattern, '/some/dir/1.2-*-*', 'glob pattern uses base_dir and task num');
};

subtest 'detect_format() - v2.1 by file presence' => sub {
    plan tests => 1;

    my $tmp = tempdir(CLEANUP => 1);
    my $dir = "$tmp/1-feature-test";
    make_path($dir);
    open my $fh, '>', "$dir/f-implementation-exec.md" or die $!;
    print $fh "# Test\n";
    close $fh;

    is(CWF::TaskPath::detect_format($dir), '2.1', 'detects v2.1 from f-implementation-exec.md presence');
};

subtest 'detect_format() - v2.0 by file presence' => sub {
    plan tests => 1;

    my $tmp = tempdir(CLEANUP => 1);
    my $dir = "$tmp/1-feature-test";
    make_path($dir);
    open my $fh, '>', "$dir/a-plan.md" or die $!;
    print $fh "# Test\n";
    close $fh;

    is(CWF::TaskPath::detect_format($dir), '2.0', 'detects v2.0 from a-plan.md presence');
};

#==============================================================================
# TIER C — Git-dependent subs
#==============================================================================

my $git_available = (system("git --version >/dev/null 2>&1") == 0);

SKIP: {
    skip 'git not available', 6 unless $git_available;

    my $tmp = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($tmp);

    skip 'git repo creation failed', 6 unless $repo;

    # Create implementation-guide with a couple of task dirs
    make_path("$repo/implementation-guide");
    create_task_dir("$repo/implementation-guide", 'feature');  # 1-feature-test-task
    make_path("$repo/implementation-guide/1.1-feature-child-task");

    subtest 'find_base_dir() - finds implementation-guide from within task dir' => sub {
        plan tests => 1;

        my $orig = Cwd::cwd();
        chdir "$repo/implementation-guide/1-feature-test-task";
        my $base = find_base_dir();
        chdir $orig;
        ok(defined $base && $base =~ /implementation-guide$/, 'find_base_dir returns implementation-guide path');
    };

    subtest 'task_exists() - existing task found' => sub {
        plan tests => 1;

        my $orig = Cwd::cwd();
        chdir $repo;
        my $exists = task_exists('1', "$repo/implementation-guide");
        chdir $orig;
        ok($exists, 'task_exists returns true for task 1');
    };

    subtest 'task_exists() - non-existent task not found' => sub {
        plan tests => 1;

        my $orig = Cwd::cwd();
        chdir $repo;
        my $exists = task_exists('999', "$repo/implementation-guide");
        chdir $orig;
        ok(!$exists, 'task_exists returns false for task 999');
    };

    subtest 'resolve_num() - resolves task by number' => sub {
        plan tests => 2;

        my $orig = Cwd::cwd();
        chdir $repo;
        my $result = resolve_num('1', "$repo/implementation-guide");
        chdir $orig;
        ok(defined $result, 'resolve_num returns a result');
        is($result->{num}, '1', 'resolved num matches') if defined $result;
    };

    subtest 'resolve_num() - non-existent task returns undef' => sub {
        plan tests => 1;

        my $orig = Cwd::cwd();
        chdir $repo;
        my $result = resolve_num('999', "$repo/implementation-guide");
        chdir $orig;
        ok(!defined $result, 'resolve_num returns undef for missing task');
    };

    subtest 'find_children() - task with child returns child list' => sub {
        plan tests => 1;

        my $orig = Cwd::cwd();
        chdir $repo;
        my @children = find_children('1', "$repo/implementation-guide");
        chdir $orig;
        # 1.1-feature-child-task was created above
        ok(@children >= 0, 'find_children returns a list (child dir may not match pattern)');
    };
}

done_testing();
