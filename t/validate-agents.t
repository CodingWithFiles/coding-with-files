#!/usr/bin/env perl
#
# validate-agents.t - Unit tests for CWF::Validate::Agents
#
# Exercises validate($git_root) over synthetic tempdir fixtures: detection of
# the silently-ignored `allowed-tools:` frontmatter key, scan-target
# resolution (.cwf-agents/ vs .claude/agents/), namespace restriction, and the
# violation hashref contract. The real .claude/agents/ tree is never touched.
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";

use CWF::Validate::Agents qw(validate);

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
}

# Build $root/<subdir>/<name> with the given content, creating parents.
sub make_agent {
    my ($root, $subdir, $name, $content) = @_;
    make_path("$root/$subdir");
    write_file("$root/$subdir/$name", $content);
}

my $GOOD_FM = "---\nname: cwf-x\ntools: Read, Grep\n---\nBody text.\n";
my $BAD_FM  = "---\nname: cwf-x\nallowed-tools: Read, Grep\n---\nBody text.\n";

subtest 'TC-1: happy path (tools:) → no violations' => sub {
    my $root = tempdir(CLEANUP => 1);
    make_agent($root, '.claude/agents', 'cwf-x.md', $GOOD_FM);
    my @v = validate($root);
    is(scalar @v, 0, 'no violations on correct tools: key');
};

subtest 'TC-2: bad key flagged (core requirement)' => sub {
    my $root = tempdir(CLEANUP => 1);
    make_agent($root, '.claude/agents', 'cwf-x.md', $BAD_FM);
    my @v = validate($root);
    is(scalar @v, 1, 'one violation');
    is($v[0]{category}, 'AGENTS',                  'category');
    is($v[0]{file},     '.claude/agents/cwf-x.md', 'file');
    is($v[0]{field},    'frontmatter-key',         'field');
    is($v[0]{actual},   'allowed-tools:',          'actual');
    is($v[0]{expected}, 'tools:',                  'expected');
    like($v[0]{fix},    qr/tools:/,                'fix mentions tools:');
};

subtest 'TC-3: body occurrence is not flagged (no false positive)' => sub {
    my $root = tempdir(CLEANUP => 1);
    my $content = "---\nname: cwf-x\ntools: Read\n---\n"
                . "Body mentions allowed-tools: in a code sample.\n";
    make_agent($root, '.claude/agents', 'cwf-x.md', $content);
    my @v = validate($root);
    is(scalar @v, 0, 'body occurrence after closing --- is ignored');
};

subtest 'TC-4: installed-context scan target (.cwf-agents/)' => sub {
    my $root = tempdir(CLEANUP => 1);
    make_agent($root, '.cwf-agents', 'cwf-x.md', $BAD_FM);
    # No .claude/agents/ directory exists.
    my @v = validate($root);
    is(scalar @v, 1, 'one violation from .cwf-agents/ branch');
    is($v[0]{file}, '.cwf-agents/cwf-x.md', 'file path is the .cwf-agents/ real file');
};

subtest 'TC-5: non-CWF filename ignored' => sub {
    my $root = tempdir(CLEANUP => 1);
    make_agent($root, '.claude/agents', 'other.md', $BAD_FM);
    my @v = validate($root);
    is(scalar @v, 0, 'non-cwf-prefixed file is not policed');
};

subtest 'TC-6: no frontmatter → no violations' => sub {
    my $root = tempdir(CLEANUP => 1);
    my $content = "Plain body text mentioning allowed-tools: here.\n";
    make_agent($root, '.claude/agents', 'cwf-x.md', $content);
    my @v = validate($root);
    is(scalar @v, 0, 'line 1 is not --- → no frontmatter to scan');
};

subtest 'TC-7: unterminated frontmatter → no violations' => sub {
    my $root = tempdir(CLEANUP => 1);
    my $content = "---\nname: cwf-x\nallowed-tools: Read\nno closing marker\n";
    make_agent($root, '.claude/agents', 'cwf-x.md', $content);
    my @v = validate($root);
    is(scalar @v, 0, 'unterminated block is not valid frontmatter; whole file not scanned');
};

subtest 'TC-8: multiple bad files, deterministic order' => sub {
    my $root = tempdir(CLEANUP => 1);
    make_agent($root, '.claude/agents', 'cwf-a.md', $BAD_FM);
    make_agent($root, '.claude/agents', 'cwf-b.md', $BAD_FM);
    my @v = validate($root);
    is(scalar @v, 2, 'two violations, one per file');
    is($v[0]{file}, '.claude/agents/cwf-a.md', 'first file sorted');
    is($v[1]{file}, '.claude/agents/cwf-b.md', 'second file sorted');
};

done_testing();
