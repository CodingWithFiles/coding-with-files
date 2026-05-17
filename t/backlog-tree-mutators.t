#!/usr/bin/env perl
#
# backlog-tree-mutators.t — Unit tests for tree mutators (Task 132).
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempfile);
use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib');

use CWF::Backlog qw(
    parse_backlog_tree parse_changelog_tree serialize_tree metadata_get
    set_metadata_field add_entry delete_entry
    find_all_entries_by_slug find_all_entries_by_title
    find_changelog_entry_by_task_num
    append_retired_block_tree block_exists_in_retired_tree
    bootstrap_changelog_entry
    validate_backlog_tree validate_changelog_tree
);

my @TMP;
sub write_tmp {
    my ($bytes) = @_;
    my ($fh, $path) = tempfile('btmutXXXXXX', SUFFIX => '.md', UNLINK => 1, TMPDIR => 1);
    binmode $fh, ':raw';
    print $fh $bytes;
    close $fh;
    push @TMP, $path;
    return $path;
}

my $bl_bytes = join('',
    "# Backlog\n\n",
    "## Task: Add Delete Task Skill\n\n### Task-Type: chore\n### Priority: Low\n\nbody A\n", "\n",
    "## Task: Refactor Foo\n\n### Task-Type: feature\n### Priority: High\n\nbody B\n",
);

#==============================================================================
# TC-MUT-set-pos: update existing metadata field
#==============================================================================
subtest 'TC-MUT-set-pos update Priority' => sub {
    plan tests => 4;
    my $path = write_tmp($bl_bytes);
    my ($tree, $g) = parse_backlog_tree($path);
    my $e = $tree->{entries}[0];
    my $upd = set_metadata_field($e, 'Priority', 'High');
    is($upd, 1, 'returned 1 for update');
    is(metadata_get($e, 'Priority'), 'High', 'Priority updated');
    my $errs = validate_backlog_tree($tree);
    is(scalar(grep { ($_->{severity}//'error') eq 'error' } @$errs), 0, 'tree validates');
    # Round-trip via serialise → re-parse → values intact
    my $out = serialize_tree($tree);
    my $path2 = write_tmp($out);
    my ($t2, $g2) = parse_backlog_tree($path2);
    is(metadata_get($t2->{entries}[0], 'Priority'), 'High', 're-parsed Priority intact');
};

#==============================================================================
# TC-MUT-set-add: add a metadata key that didn't exist
#==============================================================================
subtest 'TC-MUT-set-add' => sub {
    plan tests => 3;
    my $path = write_tmp($bl_bytes);
    my ($tree, $g) = parse_backlog_tree($path);
    my $e = $tree->{entries}[0];
    is(metadata_get($e, 'Status'), undef, 'no Status initially');
    my $upd = set_metadata_field($e, 'Status', 'Awaiting design');
    is($upd, 0, 'returned 0 for add');
    is(metadata_get($e, 'Status'), 'Awaiting design', 'Status added');
};

#==============================================================================
# TC-MUT-add-pos: append a new entry
#==============================================================================
subtest 'TC-MUT-add-pos' => sub {
    plan tests => 2;
    my $path = write_tmp($bl_bytes);
    my ($tree, $g) = parse_backlog_tree($path);
    my $new = {
        type => 'Task',
        task_num => undef,
        title => 'Brand New',
        header_lineno => 0,
        metadata => [
            { key => 'Task-Type', value => 'feature', lineno => 0 },
            { key => 'Priority',  value => 'Medium',  lineno => 0 },
        ],
        subsections => [],
        body_before_meta => 0,
        body_raw => ["a body line\n"],
    };
    add_entry($tree, $new);
    is(scalar @{$tree->{entries}}, 3, 'three entries after add');
    my $errs = validate_backlog_tree($tree);
    is(scalar(grep { ($_->{severity}//'error') eq 'error' } @$errs), 0, 'tree validates');
};

#==============================================================================
# TC-MUT-delete-pos / oob
#==============================================================================
subtest 'TC-MUT-delete-pos and -oob' => sub {
    plan tests => 4;
    my $path = write_tmp($bl_bytes);
    my ($tree, $g) = parse_backlog_tree($path);
    is(scalar @{$tree->{entries}}, 2, 'start with 2');
    delete_entry($tree, 0);
    is(scalar @{$tree->{entries}}, 1, '1 after delete');
    is($tree->{entries}[0]{title}, 'Refactor Foo', 'remaining entry is Refactor Foo');
    eval { delete_entry($tree, 999); };
    like($@, qr/out of range/, 'oob delete dies');
};

#==============================================================================
# TC-MUT-find-by-slug / -title / -miss
#==============================================================================
subtest 'TC-MUT-find' => sub {
    plan tests => 5;
    my $path = write_tmp($bl_bytes);
    my ($tree, $g) = parse_backlog_tree($path);
    my @hits = find_all_entries_by_slug($tree, 'add-delete-task-skill');
    is(scalar @hits, 1, 'one slug hit');
    is($hits[0][1], 0, 'index 0');

    my @hits2 = find_all_entries_by_title($tree, 'Refactor Foo');
    is(scalar @hits2, 1, 'one title hit');
    is($hits2[0][1], 1);

    my @miss = find_all_entries_by_slug($tree, 'no-such-thing');
    is(scalar @miss, 0, 'miss returns empty list');
};

#==============================================================================
# TC-MUT-retired-create: append to a CHANGELOG entry without Retired subsection
#==============================================================================
subtest 'TC-MUT-retired-create-and-append' => sub {
    plan tests => 5;
    my $cl = join('',
        "# Changelog\n\n",
        "## Task 131: Foo\n\n",
        "### Status: Complete\n### Impact: Feature\n\n",
        "### Changes\n- a\n", "\n",
        "### Notable\n- b\n",
    );
    my $path = write_tmp($cl);
    my ($tree, $g) = parse_changelog_tree($path);
    my ($e) = find_changelog_entry_by_task_num($tree, 131);
    ok(defined $e, 'found Task 131');
    is(scalar @{$e->{subsections}}, 2, '2 subsections initially');

    append_retired_block_tree($e, 'Some Item', ["body line 1\n", "body line 2\n"], undef);
    is(scalar @{$e->{subsections}}, 3, '3 subsections after append');
    is($e->{subsections}[2]{name}, 'Retired Backlog Items', 'subsection name');

    # Validate
    my $errs = validate_changelog_tree($tree);
    is(scalar(grep { ($_->{severity}//'error') eq 'error' } @$errs), 0, 'tree validates');
};

#==============================================================================
# TC-MUT-retired-dedup: block_exists_in_retired_tree
#==============================================================================
subtest 'TC-MUT-retired-dedup' => sub {
    plan tests => 4;
    my $cl = join('',
        "# Changelog\n\n",
        "## Task 131: Foo\n\n",
        "### Status: Complete\n### Impact: Feature\n\n",
        "### Changes\n- a\n",
    );
    my $path = write_tmp($cl);
    my ($tree, $g) = parse_changelog_tree($path);
    my ($e) = find_changelog_entry_by_task_num($tree, 131);
    is(block_exists_in_retired_tree($e, 'Some Item'), 0, 'absent initially');
    append_retired_block_tree($e, 'Some Item', ["body\n"], undef);
    is(block_exists_in_retired_tree($e, 'Some Item'), 1, 'found after append');
    is(block_exists_in_retired_tree($e, 'some item'), 1, 'case-insensitive');
    is(block_exists_in_retired_tree($e, 'Other'), 0, 'unrelated title absent');
};

#==============================================================================
# TC-U1: bootstrap_changelog_entry — empty-tree bootstrap (Task 147)
#==============================================================================
subtest 'TC-U1: bootstrap on empty CHANGELOG tree' => sub {
    plan tests => 6;
    my $path = write_tmp("# Changelog\n");
    my ($tree, $g) = parse_changelog_tree($path);
    is(scalar @{$tree->{entries}}, 0, 'starts empty');
    my $e = bootstrap_changelog_entry($tree, 50, 'something');
    is(scalar @{$tree->{entries}}, 1, 'one entry after bootstrap');
    is($e->{task_num}, 50,          'task_num set');
    is($e->{title},    'something', 'title set');
    is_deeply([map { $_->{key} } @{$e->{metadata}}], ['Status', 'Impact'],
        'metadata keys present in order');
    my @sub_names = map { $_->{name} } @{$e->{subsections}};
    is_deeply(\@sub_names, ['Retired Backlog Items'],
        'single Retired Backlog Items subsection');
};

#==============================================================================
# TC-U2: bootstrap inserts at index 0 against existing entries
#==============================================================================
subtest 'TC-U2: bootstrap inserts at index 0' => sub {
    plan tests => 4;
    my $cl = join('',
        "# Changelog\n\n",
        "## Task 100: Existing One\n\n",
        "### Status: Complete\n### Impact: x\n", "\n",
        "## Task 50: Existing Two\n\n",
        "### Status: Complete\n### Impact: y\n",
    );
    my $path = write_tmp($cl);
    my ($tree, $g) = parse_changelog_tree($path);
    is(scalar @{$tree->{entries}}, 2, 'two existing entries');
    bootstrap_changelog_entry($tree, 200, 'x');
    is($tree->{entries}[0]{task_num}, 200, 'new entry at index 0');
    is($tree->{entries}[1]{task_num}, 100, 'task 100 shifted down');
    is($tree->{entries}[2]{task_num}, 50,  'task 50 still last');
};

#==============================================================================
# TC-U3: bootstrap → serialise → parse round-trip preserves entry shape
#==============================================================================
subtest 'TC-U3: bootstrap serialise/parse round-trip' => sub {
    plan tests => 5;
    my $path = write_tmp("# Changelog\n");
    my ($tree, $g) = parse_changelog_tree($path);
    bootstrap_changelog_entry($tree, 147, 'retire bootstraps missing changelog task entry');
    my $serialised = serialize_tree($tree);
    my $path2 = write_tmp($serialised);
    my ($t2, $g2) = parse_changelog_tree($path2);
    is(scalar @{$t2->{entries}}, 1, 'one entry after round-trip');
    my $e2 = $t2->{entries}[0];
    is($e2->{task_num}, 147, 'task_num preserved');
    is($e2->{title},    'retire bootstraps missing changelog task entry',
        'title preserved');
    is(metadata_get($e2, 'Status'), 'In Progress', 'Status preserved');
    is(metadata_get($e2, 'Impact'), 'Task in progress.', 'Impact preserved');
};

done_testing;
