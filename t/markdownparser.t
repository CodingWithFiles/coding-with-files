#!/usr/bin/env perl
#
# markdownparser.t - Unit tests for CWF::MarkdownParser
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('CWF::MarkdownParser', qw(extract_field find_field_line)) }

#==============================================================================
# Helpers
#==============================================================================

sub write_md {
    my ($dir, $name, $content) = @_;
    my $path = "$dir/$name";
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
    return $path;
}

my $tmp = tempdir(CLEANUP => 1);

# Status-specific regexes (same patterns TaskState will use)
my $STATUS_SECTION_RE = qr/^## (?:Current )?Status\s*$/i;
my $STATUS_KEY_RE     = qr/^\*\*Status\*\*:\s*(.+?)\s*$/;

#==============================================================================
# extract_field() — status extraction (preserves all 7 original scenarios)
#==============================================================================

subtest 'extract_field - standard Status section' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'std.md', <<'MD');
# My File

## Status
**Status**: Finished
MD
    is(extract_field($f, $STATUS_SECTION_RE, $STATUS_KEY_RE), 'Finished', 'extracts status from ## Status section');
};

subtest 'extract_field - Current Status section' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'cur.md', <<'MD');
# My File

## Current Status
**Status**: In Progress
MD
    is(extract_field($f, $STATUS_SECTION_RE, $STATUS_KEY_RE), 'In Progress', 'extracts status from ## Current Status section');
};

subtest 'extract_field - missing section returns Unknown' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'nosec.md', <<'MD');
# My File

## Goal
No status here.
MD
    is(extract_field($f, $STATUS_SECTION_RE, $STATUS_KEY_RE), 'Unknown', 'returns Unknown when no Status section');
};

subtest 'extract_field - status in code block is ignored' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'codeblock.md', <<'MD');
# My File

## Notes
```
**Status**: Fake
```

## Status
**Status**: Backlog
MD
    is(extract_field($f, $STATUS_SECTION_RE, $STATUS_KEY_RE), 'Backlog', 'ignores status patterns inside code blocks');
};

subtest 'extract_field - status outside Status section is ignored' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'wrong-section.md', <<'MD');
# My File

## Goal
**Status**: This should be ignored

## Status
**Status**: Testing
MD
    is(extract_field($f, $STATUS_SECTION_RE, $STATUS_KEY_RE), 'Testing', 'only reads status from ## Status section');
};

subtest 'extract_field - nonexistent file returns Unknown' => sub {
    plan tests => 1;

    is(extract_field('/nonexistent/path/to/file.md', $STATUS_SECTION_RE, $STATUS_KEY_RE), 'Unknown', 'returns Unknown for missing file');
};

subtest 'extract_field - trailing whitespace trimmed' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'trail.md', "## Status\n**Status**: Finished   \n");
    is(extract_field($f, $STATUS_SECTION_RE, $STATUS_KEY_RE), 'Finished', 'trailing whitespace trimmed from status value');
};

#==============================================================================
# extract_field() — non-status fields
#==============================================================================

subtest 'extract_field - Task field from Task Reference section' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'taskref.md', <<'MD');
# My Task

## Task Reference
- **Task ID**: internal-105
- **Task**: 105 (chore)
- **Branch**: chore/105-slug

## Status
**Status**: Finished
MD
    is(extract_field($f, qr/^## Task Reference/, qr/^\- \*\*Task\*\*:\s*(.+?)\s*$/),
       '105 (chore)', 'extracts Task field from Task Reference section');
};

subtest 'extract_field - Branch field from Task Reference section' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'branch.md', <<'MD');
# My Task

## Task Reference
- **Task**: 105 (chore)
- **Branch**: chore/105-slug

## Status
**Status**: Finished
MD
    is(extract_field($f, qr/^## Task Reference/, qr/^\- \*\*Branch\*\*:\s*(.+?)\s*$/),
       'chore/105-slug', 'extracts Branch field from Task Reference section');
};

#==============================================================================
# find_field_line() — returns position info for write-back
#==============================================================================

subtest 'find_field_line - returns line index and value' => sub {
    plan tests => 3;

    my $f = write_md($tmp, 'findline.md', <<'MD');
# My File

## Status
**Status**: In Progress
**Next Action**: /cwf-testing-exec
MD
    my ($idx, $val, @lines) = find_field_line($f, $STATUS_SECTION_RE, $STATUS_KEY_RE);
    ok(defined $idx, 'line index defined');
    is($val, 'In Progress', 'value extracted correctly');
    like($lines[$idx], qr/In Progress/, 'line at index contains the value');
};

subtest 'find_field_line - returns empty list for missing field' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'noline.md', "## Goal\nSome content\n");
    my @result = find_field_line($f, $STATUS_SECTION_RE, $STATUS_KEY_RE);
    is(scalar @result, 0, 'returns empty list when field not found');
};

done_testing();
