#!/usr/bin/env perl
#
# backlog-tree-parse.t — Unit tests for the heading-tree parser/serialiser
# (Task 132). Round-trip byte-identical for canonical heading-tree fixtures.
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempfile);
use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib');

use CWF::Backlog qw(parse_backlog_tree parse_changelog_tree serialize_tree metadata_get);

my $FIX_DIR = File::Spec->catdir($FindBin::Bin, 'fixtures', 'backlog-manager', 'heading-tree');

# Helper: write text bytes to a temp file, return its path. The tempfile is
# unlinked at process exit.
my @TMP_FILES;
sub write_tmp {
    my ($bytes) = @_;
    my ($fh, $path) = tempfile('btparseXXXXXX', SUFFIX => '.md', UNLINK => 1, TMPDIR => 1);
    binmode $fh, ':raw';
    print $fh $bytes;
    close $fh;
    push @TMP_FILES, $path;
    return $path;
}

#==============================================================================
# TC-PARSE-1: minimal BACKLOG fixture (intro + one entry)
#==============================================================================
subtest 'TC-PARSE-1: minimal BACKLOG' => sub {
    plan tests => 8;
    my $bytes = "# Backlog\n\n## Task: Foo\n\n### Task-Type: chore\n### Priority: Low\n\nbody\n";
    my $path = write_tmp($bytes);
    my ($tree, $errs) = parse_backlog_tree($path);
    is(scalar @$errs, 0, 'no global errors');
    is(scalar @{$tree->{entries}}, 1, 'one entry');
    my $e = $tree->{entries}[0];
    is($e->{type}, 'Task', 'type is Task');
    is($e->{title}, 'Foo', 'title');
    is(scalar @{$e->{metadata}}, 2, 'two metadata nodes');
    is(metadata_get($e, 'Task-Type'), 'chore', 'metadata Task-Type');
    is(metadata_get($e, 'Priority'), 'Low', 'metadata Priority');
    is_deeply($e->{body_raw}, ["body\n"], 'body raw lines');
};

#==============================================================================
# TC-PARSE-2: BACKLOG fixture with multiple entries (Task + Task + Bug)
#==============================================================================
subtest 'TC-PARSE-2: multiple entries' => sub {
    plan tests => 5;
    my $bytes = join('',
        "# Backlog\n", "\n",
        "## Task: A\n\n### Task-Type: chore\n### Priority: Low\n\nbody A\n", "\n",
        "## Task: B\n\n### Task-Type: feature\n### Priority: High\n\nbody B\n", "\n",
        "## Bug: C\n\n### Task-Type: bugfix\n### Priority: Medium\n\nbody C\n",
    );
    my $path = write_tmp($bytes);
    my ($tree, $errs) = parse_backlog_tree($path);
    is(scalar @{$tree->{entries}}, 3, 'three entries');
    my @types = map { $_->{type} } @{$tree->{entries}};
    is_deeply(\@types, ['Task', 'Task', 'Bug'], 'types in order');
    is($tree->{entries}[0]{title}, 'A');
    is($tree->{entries}[1]{title}, 'B');
    is($tree->{entries}[2]{title}, 'C');
};

#==============================================================================
# TC-PARSE-3: CHANGELOG fixture with subsections
#==============================================================================
subtest 'TC-PARSE-3: CHANGELOG with subsections' => sub {
    plan tests => 9;
    my $bytes = join('',
        "# Changelog\n\n",
        "## Task 131: Foo\n\n",
        "### Status: Complete\n",
        "### Impact: Feature\n\n",
        "### Changes\n",
        "- bar\n",
        "- baz\n\n",
        "### Notable\n",
        "- quux\n",
    );
    my $path = write_tmp($bytes);
    my ($tree, $errs) = parse_changelog_tree($path);
    is(scalar @{$tree->{entries}}, 1, 'one entry');
    my $e = $tree->{entries}[0];
    is($e->{task_num}, 131, 'task_num');
    is($e->{title}, 'Foo', 'title');
    is(metadata_get($e, 'Status'), 'Complete', 'Status');
    is(metadata_get($e, 'Impact'), 'Feature', 'Impact');
    is(scalar @{$e->{subsections}}, 2, 'two subsections');
    is($e->{subsections}[0]{name}, 'Changes');
    is($e->{subsections}[1]{name}, 'Notable');
    is_deeply($e->{subsections}[0]{body_raw}, ["- bar\n", "- baz\n"], 'Changes body');
};

#==============================================================================
# TC-PARSE-4: fenced code block with H3-looking content
#==============================================================================
subtest 'TC-PARSE-4: fenced code blocks suppress H3 parsing' => sub {
    plan tests => 4;
    my $bytes = join('',
        "## Task: Foo\n\n",
        "### Task-Type: chore\n",
        "### Priority: Low\n\n",
        "Example:\n",
        "```\n",
        "### Fake: NotMetadata\n",
        "### Also Fake\n",
        "```\n",
    );
    my $path = write_tmp($bytes);
    my ($tree, $errs) = parse_backlog_tree($path);
    is(scalar @{$tree->{entries}}, 1, 'one entry');
    my $e = $tree->{entries}[0];
    is(scalar @{$e->{metadata}}, 2, 'two metadata nodes (fence-bound H3 ignored)');
    is(scalar @{$e->{subsections}}, 0, 'no subsections from fenced lines');
    # Body should contain the fenced block
    my $body = join('', @{$e->{body_raw}});
    like($body, qr/### Fake: NotMetadata/, 'fenced text in body');
};

#==============================================================================
# TC-PARSE-5: Postel-liberal body-before-metadata
#==============================================================================
subtest 'TC-PARSE-5: body before metadata captured at entry level' => sub {
    plan tests => 4;
    my $bytes = "## Task: Foo\n\nprose first\n\n### Task-Type: chore\n### Priority: Low\n";
    my $path = write_tmp($bytes);
    my ($tree, $errs) = parse_backlog_tree($path);
    my $e = $tree->{entries}[0];
    is(scalar @{$e->{metadata}}, 2, 'metadata still captured');
    my $body = join('', @{$e->{body_raw}});
    like($body, qr/prose first/, 'body_raw contains pre-metadata prose');
    is($e->{body_before_meta}, 1, 'body_before_meta flag set');
    is(metadata_get($e, 'Task-Type'), 'chore', 'metadata key still found');
};

#==============================================================================
# TC-PARSE-6: empty file
#==============================================================================
subtest 'TC-PARSE-6: empty file' => sub {
    plan tests => 3;
    my $path = write_tmp('');
    my ($tree, $errs) = parse_backlog_tree($path);
    is(scalar @$errs, 0, 'no errors');
    is(scalar @{$tree->{intro}}, 0, 'empty intro');
    is(scalar @{$tree->{entries}}, 0, 'no entries');
};

#==============================================================================
# TC-PARSE-7: round-trip byte-identical for canonical fixtures
#==============================================================================
subtest 'TC-PARSE-7: round-trip canonical fixtures' => sub {
    my @fixtures = (
        # name, parser, content
        ['empty-backlog', \&parse_backlog_tree, ''],
        ['intro-only-backlog', \&parse_backlog_tree, "# Backlog\n\nIntro paragraph.\n"],
        ['minimal-backlog', \&parse_backlog_tree,
            "# Backlog\n\n## Task: Foo\n\n### Task-Type: chore\n### Priority: Low\n\nbody\n"],
        ['multi-backlog', \&parse_backlog_tree, join('',
            "# Backlog\n\n",
            "## Task: A\n\n### Task-Type: chore\n### Priority: Low\n\nbody A\n", "\n",
            "## Task: B\n\n### Task-Type: feature\n### Priority: High\n\nbody B\n",
        )],
        ['changelog-with-subs', \&parse_changelog_tree, join('',
            "# Changelog\n\n",
            "## Task 131: Foo\n\n",
            "### Status: Complete\n### Impact: Feature\n\n",
            "### Changes\n- bar\n",
            "\n",
            "### Notable\n- quux\n",
        )],
    );
    plan tests => scalar @fixtures;
    for my $f (@fixtures) {
        my ($name, $parser, $bytes) = @$f;
        my $path = write_tmp($bytes);
        my ($tree, $errs) = $parser->($path);
        my $out = serialize_tree($tree);
        is($out, $bytes, "round-trip: $name");
    }
};

#==============================================================================
# TC-PARSE-8: GLOBAL-002 control-character rejection
#==============================================================================
subtest 'TC-PARSE-8: GLOBAL-002 control-char in heading' => sub {
    plan tests => 3;
    my $bytes = "## Task: Foo\x01Bar\n\n### Task-Type: chore\n### Priority: Low\n";
    my $path = write_tmp($bytes);
    my ($tree, $errs) = parse_backlog_tree($path);
    ok(scalar(grep { ($_->{rule} // '') eq 'GLOBAL-002' } @$errs) > 0,
       'GLOBAL-002 reported');
    my ($g) = grep { ($_->{rule} // '') eq 'GLOBAL-002' } @$errs;
    is($g->{line}, 1, 'line number reported');
    like($g->{message}, qr/control character/, 'message names control char');
};

#==============================================================================
# Live-file regression: BACKLOG.md and CHANGELOG.md parse without errors
# (parser should not choke on the Task 131-format files; metadata will be
# empty until Step 6 migration converts `**Field**:` → `### Field:`).
#==============================================================================
subtest 'live BACKLOG.md parses cleanly' => sub {
    plan tests => 2;
    my $repo = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
    my $bl   = File::Spec->catfile($repo, 'BACKLOG.md');
    my ($tree, $errs) = parse_backlog_tree($bl);
    is(scalar @$errs, 0, 'no global errors on live BACKLOG.md');
    cmp_ok(scalar @{$tree->{entries}}, '>=', 45, 'entry count plausible');
};

subtest 'live CHANGELOG.md parses cleanly' => sub {
    plan tests => 2;
    my $repo = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
    my $cl   = File::Spec->catfile($repo, 'CHANGELOG.md');
    my ($tree, $errs) = parse_changelog_tree($cl);
    is(scalar @$errs, 0, 'no global errors on live CHANGELOG.md');
    cmp_ok(scalar @{$tree->{entries}}, '>=', 90, 'entry count plausible');
};

done_testing;
