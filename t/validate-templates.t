#!/usr/bin/env perl
#
# validate-templates.t - Unit tests for CWF::Validate::Templates
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";

use CWF::Validate::Templates qw(validate);
use CWF::WorkflowFiles::V21 qw(supported_types);

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
}

# Build a minimal fixture: $root/.cwf/templates/pool/ with one file,
# $root/.cwf/templates/<type>/ as an empty dir ready for symlinks.
sub make_fixture {
    my ($type, $name) = @_;
    my $root = tempdir(CLEANUP => 1);
    make_path("$root/.cwf/templates/pool");
    make_path("$root/.cwf/templates/$type");
    write_file("$root/.cwf/templates/pool/$name", "pool content\n");
    return $root;
}

subtest 'TC-V1: happy path → no violations' => sub {
    my $name = 'a-task-plan.md.template';
    my $root = make_fixture('feature', $name);
    symlink("../pool/$name", "$root/.cwf/templates/feature/$name")
        or die "symlink: $!";
    my @v = validate($root);
    is(scalar @v, 0, 'no violations on correct symlink');
};

subtest 'TC-V2: regular file in place of symlink → type/regular file' => sub {
    my $name = 'a-task-plan.md.template';
    my $root = make_fixture('feature', $name);
    write_file("$root/.cwf/templates/feature/$name", "inlined\n");

    my @v = validate($root);
    is(scalar @v, 1, 'one violation');
    is($v[0]{category}, 'TEMPLATES',                              'category');
    is($v[0]{file},     ".cwf/templates/feature/$name",           'file');
    is($v[0]{field},    'type',                                   'field=type');
    is($v[0]{actual},   'regular file',                           'actual=regular file');
    is($v[0]{expected}, "symlink to ../pool/$name",               'expected');
    like($v[0]{fix},    qr/cwf-manage update/,                    'fix mentions cwf-manage update');
    like($v[0]{fix},    qr{ln -sfn \Q../pool/$name\E},            'fix mentions ln -sfn');
};

subtest 'TC-V3: directory in place of symlink → type/directory' => sub {
    my $name = 'a-task-plan.md.template';
    my $root = make_fixture('feature', $name);
    make_path("$root/.cwf/templates/feature/$name");

    my @v = validate($root);
    is(scalar @v, 1,            'one violation');
    is($v[0]{field},  'type',      'field=type');
    is($v[0]{actual}, 'directory', 'actual=directory');
};

subtest 'TC-V4: dangling symlink → target/dangling' => sub {
    my $name = 'a-task-plan.md.template';
    my $root = make_fixture('feature', $name);
    symlink('../pool/does-not-exist', "$root/.cwf/templates/feature/$name")
        or die "symlink: $!";

    my @v = validate($root);
    is(scalar @v, 1,                          'one violation');
    is($v[0]{field},    'target',             'field=target (dangling)');
    is($v[0]{actual},   '../pool/does-not-exist', 'actual is bad link');
    is($v[0]{expected}, "../pool/$name",      'expected is correct link');
};

subtest 'TC-V5: wrong-but-existing pool entry → pool-name' => sub {
    my $name  = 'a-task-plan.md.template';
    my $other = 'c-design-plan.md.template';
    my $root  = make_fixture('feature', $name);
    write_file("$root/.cwf/templates/pool/$other", "other\n");
    symlink("../pool/$other", "$root/.cwf/templates/feature/$name")
        or die "symlink: $!";

    my @v = validate($root);
    is(scalar @v, 1,                          'one violation');
    is($v[0]{field},    'pool-name',          'field=pool-name');
    is($v[0]{actual},   "../pool/$other",     'actual is the wrong link');
    is($v[0]{expected}, "../pool/$name",      'expected is correct link');
};

subtest 'TC-V6: absolute symlink target → caught' => sub {
    my $name = 'a-task-plan.md.template';
    my $root = make_fixture('feature', $name);
    symlink('/etc/passwd', "$root/.cwf/templates/feature/$name")
        or die "symlink: $!";

    my @v = validate($root);
    is(scalar @v, 1,                  'one violation');
    is($v[0]{actual}, '/etc/passwd',  'actual is the absolute link verbatim');
    # /etc/passwd existence varies by host: target if absent, pool-name if present.
    ok($v[0]{field} eq 'target' || $v[0]{field} eq 'pool-name',
       "field is 'target' or 'pool-name' (got $v[0]{field})");
};

subtest 'TC-V7: escaping relative symlink → caught' => sub {
    # The symlink is never followed by validate; -e performs an existence
    # check but does not read content. Safe even with sensitive target paths.
    my $name = 'a-task-plan.md.template';
    my $root = make_fixture('feature', $name);
    symlink('../../etc/passwd', "$root/.cwf/templates/feature/$name")
        or die "symlink: $!";

    my @v = validate($root);
    is(scalar @v, 1,                       'one violation');
    is($v[0]{actual}, '../../etc/passwd',  'actual shows the bad link verbatim');
    ok($v[0]{field} eq 'target' || $v[0]{field} eq 'pool-name',
       "field is 'target' or 'pool-name' (got $v[0]{field})");
};

subtest 'TC-V8: multiple violations in deterministic order' => sub {
    my $a = 'a-task-plan.md.template';
    my $c = 'c-design-plan.md.template';
    my $d = 'd-implementation-plan.md.template';
    my $root = tempdir(CLEANUP => 1);
    make_path("$root/.cwf/templates/pool");
    write_file("$root/.cwf/templates/pool/$a", "");
    write_file("$root/.cwf/templates/pool/$c", "");
    write_file("$root/.cwf/templates/pool/$d", "");

    # bugfix/<a> as regular file       → type
    # chore/<a>  as dangling symlink   → target
    # feature/<a> -> ../pool/<c>       → pool-name
    make_path("$root/.cwf/templates/bugfix");
    make_path("$root/.cwf/templates/chore");
    make_path("$root/.cwf/templates/feature");
    write_file("$root/.cwf/templates/bugfix/$a", "inlined\n");
    symlink('../pool/nonexistent', "$root/.cwf/templates/chore/$a")
        or die "symlink: $!";
    symlink("../pool/$c", "$root/.cwf/templates/feature/$a")
        or die "symlink: $!";

    my @v = validate($root);
    # Type-iteration order is supported_types(); files are sorted by readdir.
    # All three violations refer to the same file basename so type ordering is
    # the only dimension that matters here.
    my @types = supported_types();
    my %order;
    $order{$types[$_]} = $_ for 0 .. $#types;
    my @sections = map {
        m{\.cwf/templates/([^/]+)/} ? $1 : 'unknown'
    } map { $_->{file} } @v;

    is(scalar @v, 3, 'three violations');
    # Each violation in supported_types() order: walk the sections list and
    # confirm indices are monotonically non-decreasing.
    my @indices = map { $order{$_} } @sections;
    my $monotonic = 1;
    for my $i (1 .. $#indices) {
        $monotonic = 0 if $indices[$i] < $indices[$i - 1];
    }
    ok($monotonic,
        "violations sorted by supported_types() order: @sections [indices @indices]");
};

subtest 'TC-V9: pool/ itself is ignored' => sub {
    my $name = 'a-task-plan.md.template';
    my $root = make_fixture('feature', $name);
    symlink("../pool/$name", "$root/.cwf/templates/feature/$name")
        or die "symlink: $!";
    # Add a non-symlink, non-template file in pool/
    write_file("$root/.cwf/templates/pool/some-extra-file.txt", "x");

    my @v = validate($root);
    is(scalar @v, 0, 'pool/ contents do not produce violations');
};

subtest 'TC-V10: missing task-type directory is not an error' => sub {
    my $name = 'a-task-plan.md.template';
    my $root = make_fixture('feature', $name);
    symlink("../pool/$name", "$root/.cwf/templates/feature/$name")
        or die "symlink: $!";
    # chore/ is not created on disk — validator should silently skip.

    my @v = validate($root);
    is(scalar @v, 0, 'absent type-dir is silently skipped');
};

done_testing();
