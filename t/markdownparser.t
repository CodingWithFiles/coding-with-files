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

BEGIN { use_ok('CWF::MarkdownParser', qw(extract_status)) }

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

#==============================================================================
# extract_status()
#==============================================================================

subtest 'extract_status() - standard Status section' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'std.md', <<'MD');
# My File

## Status
**Status**: Finished
MD
    is(extract_status($f), 'Finished', 'extracts status from ## Status section');
};

subtest 'extract_status() - Current Status section' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'cur.md', <<'MD');
# My File

## Current Status
**Status**: In Progress
MD
    is(extract_status($f), 'In Progress', 'extracts status from ## Current Status section');
};

subtest 'extract_status() - missing Status section returns Unknown' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'nosec.md', <<'MD');
# My File

## Goal
No status here.
MD
    is(extract_status($f), 'Unknown', 'returns Unknown when no Status section');
};

subtest 'extract_status() - status in code block is ignored' => sub {
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
    is(extract_status($f), 'Backlog', 'ignores status patterns inside code blocks');
};

subtest 'extract_status() - status outside Status section is ignored' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'wrong-section.md', <<'MD');
# My File

## Goal
**Status**: This should be ignored

## Status
**Status**: Testing
MD
    is(extract_status($f), 'Testing', 'only reads status from ## Status section');
};

subtest 'extract_status() - nonexistent file returns Unknown' => sub {
    plan tests => 1;

    is(extract_status('/nonexistent/path/to/file.md'), 'Unknown', 'returns Unknown for missing file');
};

subtest 'extract_status() - trailing whitespace trimmed' => sub {
    plan tests => 1;

    my $f = write_md($tmp, 'trail.md', "## Status\n**Status**: Finished   \n");
    is(extract_status($f), 'Finished', 'trailing whitespace trimmed from status value');
};

done_testing();
