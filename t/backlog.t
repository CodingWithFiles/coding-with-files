#!/usr/bin/env perl
#
# backlog.t — Unit tests for CWF::Backlog (parser, classifier, helpers,
# validator rules). Round-trip byte-identical against the live BACKLOG/CHANGELOG.
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib');

use CWF::Backlog qw(
    parse_backlog_file parse_changelog_file
    write_backlog_file write_changelog_file
    validate_backlog validate_changelog
    find_active_by_slug find_active_by_title
    find_changelog_task find_retired_subsection
    block_exists_in_retired append_retired_block
    entry_title entry_metadata entry_body_start_index entry_slug
    set_priority_field
    list_active
);

my $REPO_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $BACKLOG   = File::Spec->catfile($REPO_ROOT, 'BACKLOG.md');
my $CHANGELOG = File::Spec->catfile($REPO_ROOT, 'CHANGELOG.md');

#==============================================================================
# Round-trip tests against live files (load-bearing)
#==============================================================================

subtest 'round-trip: BACKLOG.md byte-identical' => sub {
    plan tests => 1;
    my ($sections, $errs) = parse_backlog_file($BACKLOG);

    my $tmp = tempdir(CLEANUP => 1);
    my $out = File::Spec->catfile($tmp, 'BACKLOG.md');
    write_backlog_file($out, $sections);

    my $orig = _slurp_raw($BACKLOG);
    my $back = _slurp_raw($out);
    ok($orig eq $back, 'parse → write produces byte-identical output');
    if ($orig ne $back) {
        diag(sprintf("orig length: %d, back length: %d", length($orig), length($back)));
        diag(_first_diff($orig, $back));
    }
};

subtest 'round-trip: CHANGELOG.md byte-identical' => sub {
    plan tests => 1;
    my ($sections, $errs) = parse_changelog_file($CHANGELOG);

    my $tmp = tempdir(CLEANUP => 1);
    my $out = File::Spec->catfile($tmp, 'CHANGELOG.md');
    write_changelog_file($out, $sections);

    my $orig = _slurp_raw($CHANGELOG);
    my $back = _slurp_raw($out);
    ok($orig eq $back, 'parse → write produces byte-identical output');
    if ($orig ne $back) {
        diag(sprintf("orig length: %d, back length: %d", length($orig), length($back)));
        diag(_first_diff($orig, $back));
    }
};

#==============================================================================
# Classification
#==============================================================================

subtest 'classify: active entry' => sub {
    plan tests => 1;
    my $tmp_file = _write_temp(<<"END");
## Task: Hello

**Task-Type**: chore
**Priority**: Medium

Body text.
END
    my ($sects, $errs) = parse_backlog_file($tmp_file);
    is($sects->[0]{kind}, 'active', 'classified as active');
};

subtest 'classify: unknown for marker/struckthrough content' => sub {
    plan tests => 3;
    my $f1 = _write_temp(qq{<!-- Completed: "Foo" — Task 1 (2026-01-01): done -->\n});
    my ($s1, undef) = parse_backlog_file($f1);
    is($s1->[0]{kind}, 'unknown', 'HTML-comment marker -> unknown');

    my $f2 = _write_temp("## ~~Task: Foo~~ ✓ COMPLETED\n");
    my ($s2, undef) = parse_backlog_file($f2);
    is($s2->[0]{kind}, 'unknown', 'tilde-strike heading -> unknown');

    my $f3 = _write_temp("## ✓ Task: Foo\n");
    my ($s3, undef) = parse_backlog_file($f3);
    is($s3->[0]{kind}, 'unknown', 'tick-prefix heading -> unknown');
};

subtest 'classify: intro' => sub {
    plan tests => 1;
    my $f = _write_temp("# CWF System Backlog\n\nIntro prose.\n");
    my ($s, undef) = parse_backlog_file($f);
    is($s->[0]{kind}, 'intro', 'classified as intro');
};

subtest 'classify: changelog_task' => sub {
    plan tests => 1;
    my $f = _write_temp(<<"END");
## Task 42: Fix something

**Status**: Complete (2026-01-01)
**Impact**: bugfix
END
    my ($s, undef) = parse_changelog_file($f);
    is($s->[0]{kind}, 'changelog_task', 'classified as changelog_task');
};

#==============================================================================
# Code-fence handling
#==============================================================================

subtest 'fence: --- inside code fence is not a separator' => sub {
    plan tests => 2;
    my $f = _write_temp(<<'END');
## Task: Outer

**Task-Type**: chore
**Priority**: Low

Body with fence containing `---`:

```
foo
---
bar
```

After fence.
END
    my ($s, undef) = parse_backlog_file($f);
    is(scalar(@$s), 1, 'one section (no spurious split)');
    is($s->[0]{kind}, 'active', 'still classified as active');
};

subtest 'fence: ## Task: inside code fence is body' => sub {
    plan tests => 2;
    my $f = _write_temp(<<'END');
## Task: Outer

**Task-Type**: chore
**Priority**: Low

```
## Task: Inner (this is inside a fence)
```

End.
END
    my ($s, undef) = parse_backlog_file($f);
    is(scalar(@$s), 1, 'one section');
    is(entry_title($s->[0]), 'Outer', 'title is Outer, not Inner');
};

#==============================================================================
# Entry helpers
#==============================================================================

subtest 'entry_title and entry_slug' => sub {
    plan tests => 4;
    my $f = _write_temp(<<"END");
## Task: Add Feature X

**Task-Type**: feature
**Priority**: High

Body.
END
    my ($s, undef) = parse_backlog_file($f);
    is(entry_title($s->[0]), 'Add Feature X', 'title');
    is(entry_slug($s->[0]),  'add-feature-x', 'slug');

    my $f2 = _write_temp("<!-- Completed: foo -->\n");
    my ($s2, undef) = parse_backlog_file($f2);
    is(entry_title($s2->[0]), undef, 'unknown kind: no title');
    is(entry_slug($s2->[0]),  undef, 'unknown kind: no slug');
};

subtest 'entry_metadata: parses fields, ignores body lookalikes' => sub {
    plan tests => 4;
    my $f = _write_temp(<<"END");
## Task: Foo

**Task-Type**: chore
**Priority**: Medium
**Status**: Backlog

Body prose.

**Approach**: this is body text, not metadata.

**Identified in**: also body text.
END
    my ($s, undef) = parse_backlog_file($f);
    my $m = entry_metadata($s->[0]);
    is($m->{'Task-Type'}, 'chore',    'Task-Type extracted');
    is($m->{'Priority'},  'Medium',   'Priority extracted');
    is($m->{'Status'},    'Backlog',  'Status extracted');
    ok(!exists $m->{'Approach'}, 'Approach (body) not in metadata');
};

subtest 'entry_metadata: empty value preserved' => sub {
    plan tests => 1;
    my $f = _write_temp(<<"END");
## Task: Foo

**Task-Type**: chore
**Priority**: Low
**Status**:

Body.
END
    my ($s, undef) = parse_backlog_file($f);
    my $m = entry_metadata($s->[0]);
    is($m->{'Status'}, '', 'empty Status preserved');
};

#==============================================================================
# Find by slug / title
#==============================================================================

subtest 'find_active_by_slug: unique match' => sub {
    plan tests => 1;
    my $f = _write_temp(<<"END");
## Task: Add Foo

**Task-Type**: chore
**Priority**: Low

---
## Task: Add Bar

**Task-Type**: chore
**Priority**: Low
END
    my ($s, undef) = parse_backlog_file($f);
    my @hits = find_active_by_slug($s, 'add-foo');
    is(scalar(@hits), 1, 'one match');
};

subtest 'find_active_by_slug: collision returns multiple' => sub {
    plan tests => 1;
    my $f = _write_temp(<<"END");
## Task: Add Foo

**Task-Type**: chore
**Priority**: Low

---
## Task: Add  Foo

**Task-Type**: chore
**Priority**: Low
END
    my ($s, undef) = parse_backlog_file($f);
    my @hits = find_active_by_slug($s, 'add-foo');
    is(scalar(@hits), 2, 'collision: two matches');
};

#==============================================================================
# Validators — passing input
#==============================================================================

subtest 'validate_backlog: live BACKLOG passes' => sub {
    plan tests => 1;
    my ($s, $g_errs) = parse_backlog_file($BACKLOG);
    my $errs = validate_backlog($s);
    my $total = scalar(@$g_errs) + scalar(@$errs);
    is($total, 0, 'live BACKLOG passes validate')
        or diag(join("\n", map { "$_->{file}:$_->{line} [$_->{rule}] $_->{message}" } (@$g_errs, @$errs)));
};

subtest 'validate_changelog: live CHANGELOG passes' => sub {
    plan tests => 1;
    my ($s, $g_errs) = parse_changelog_file($CHANGELOG);
    my $errs = validate_changelog($s);
    my $total = scalar(@$g_errs) + scalar(@$errs);
    is($total, 0, 'live CHANGELOG passes validate')
        or diag(join("\n", map { "$_->{file}:$_->{line} [$_->{rule}] $_->{message}" } (@$g_errs, @$errs)));
};

subtest 'validate_backlog: clean fixture passes' => sub {
    plan tests => 1;
    my $f = _write_temp(<<"END");
# Backlog

Intro paragraph.

---
## Task: Foo

**Task-Type**: chore
**Priority**: Medium

Body prose.

---
## Task: Bar

**Task-Type**: feature
**Priority**: Very High

Body.
END
    my ($s, $g_errs) = parse_backlog_file($f);
    my $errs = validate_backlog($s);
    is(scalar(@$g_errs) + scalar(@$errs), 0, 'clean fixture passes');
};

#==============================================================================
# Validators — failing input
#==============================================================================

subtest 'validate: BACKLOG-002 banned priority' => sub {
    plan tests => 2;
    my $f = _write_temp(<<"END");
## Task: Foo

**Task-Type**: chore
**Priority**: Needs-Triage
END
    my ($s, undef) = parse_backlog_file($f);
    my $errs = validate_backlog($s);
    is(scalar(@$errs), 1, 'one error');
    is($errs->[0]{rule}, 'BACKLOG-002', 'BACKLOG-002 fired');
};

subtest 'validate: BACKLOG-001 missing required field' => sub {
    plan tests => 1;
    my $f = _write_temp(<<"END");
## Task: Foo

**Priority**: Low
END
    my ($s, undef) = parse_backlog_file($f);
    my $errs = validate_backlog($s);
    ok((grep { $_->{rule} eq 'BACKLOG-001' } @$errs), 'BACKLOG-001 fired');
};

subtest 'validate: BACKLOG-003 body has --- separator collision' => sub {
    plan tests => 1;
    my $f = _write_temp(<<"END");
## Task: Foo

**Task-Type**: chore
**Priority**: Low

Body before separator.
---
Body after.
END
    # Note: the parser will split this into two sections at the ---,
    # so the second section will be classified as 'unknown' and the
    # body separator collision is masked. To exercise BACKLOG-003 we
    # need a body line that is exactly '---' INSIDE a fence — but the
    # fence preserves it. Or we hand-build a section.
    # Instead: test by injecting via raw_lines after parse.
    my ($s, undef) = parse_backlog_file($f);
    # First section is active; inject "---\n" into its body
    push @{$s->[0]{raw_lines}}, "---\n";
    my $errs = validate_backlog($s);
    ok((grep { $_->{rule} eq 'BACKLOG-003' } @$errs), 'BACKLOG-003 fired');
};

subtest 'validate: BACKLOG-004 rejects HTML comments anywhere in BACKLOG' => sub {
    plan tests => 2;
    my $f = _write_temp(qq{<!-- Completed: "Foo" — Task 1 (2026-01-01): done -->\n});
    my ($s, undef) = parse_backlog_file($f);
    my $errs = validate_backlog($s);
    ok((grep { $_->{rule} eq 'BACKLOG-004' } @$errs), 'BACKLOG-004 fired on completed marker');

    my $f2 = _write_temp(qq{# Backlog\n\n<!-- some other comment -->\n});
    my ($s2, undef) = parse_backlog_file($f2);
    my $errs2 = validate_backlog($s2);
    ok((grep { $_->{rule} eq 'BACKLOG-004' } @$errs2), 'BACKLOG-004 fired on stray comment');
};

subtest 'validate: BACKLOG-005 rejects struck-through headings' => sub {
    plan tests => 2;
    my $f1 = _write_temp("## ~~Task: Old~~ ✓ COMPLETED\n");
    my ($s1, undef) = parse_backlog_file($f1);
    my $errs1 = validate_backlog($s1);
    ok((grep { $_->{rule} eq 'BACKLOG-005' } @$errs1), 'BACKLOG-005 fires on tilde-strike');

    my $f2 = _write_temp("## ✓ Task: Old\n");
    my ($s2, undef) = parse_backlog_file($f2);
    my $errs2 = validate_backlog($s2);
    ok((grep { $_->{rule} eq 'BACKLOG-005' } @$errs2), 'BACKLOG-005 fires on tick-prefix');
};

subtest 'validate: BACKLOG-006 rejects #### in active body' => sub {
    plan tests => 2;
    my $f = _write_temp(<<"END");
## Task: Foo

**Task-Type**: chore
**Priority**: Low

Body before subhead.

#### Some Subhead

More body.
END
    my ($s, undef) = parse_backlog_file($f);
    my $errs = validate_backlog($s);
    ok((grep { $_->{rule} eq 'BACKLOG-006' } @$errs), 'BACKLOG-006 fired');

    # `^####` inside a code fence is permitted (fence-aware rule).
    my $f2 = _write_temp(<<'END');
## Task: Foo

**Task-Type**: chore
**Priority**: Low

```
#### Inside fence — should be tolerated
```
END
    my ($s2, undef) = parse_backlog_file($f2);
    my $errs2 = validate_backlog($s2);
    ok(!(grep { $_->{rule} eq 'BACKLOG-006' } @$errs2), 'BACKLOG-006 silent inside code fence');
};

subtest 'validate: CHANGELOG-003 enforces subsection order' => sub {
    plan tests => 2;
    # Notable before Changes — out of order.
    my $f1 = _write_temp(<<"END");
# Changelog

## Task 42: Foo

**Status**: Complete (2026-01-01)
**Impact**: chore

### Notable
- Note line.

### Changes
- Change line.
END
    my ($s1, undef) = parse_changelog_file($f1);
    my $errs1 = validate_changelog($s1);
    ok((grep { $_->{rule} eq 'CHANGELOG-003' } @$errs1), 'CHANGELOG-003 fired on Notable-before-Changes');

    # Canonical order — Changes → Notable → Retired — passes.
    my $f2 = _write_temp(<<"END");
# Changelog

## Task 42: Foo

**Status**: Complete (2026-01-01)
**Impact**: chore

### Changes
- A.

### Notable
- B.

### Retired Backlog Items

#### Some Title

Body.
END
    my ($s2, undef) = parse_changelog_file($f2);
    my $errs2 = validate_changelog($s2);
    ok(!(grep { $_->{rule} eq 'CHANGELOG-003' } @$errs2), 'canonical order accepted');
};

subtest 'validate: GLOBAL-001 BOM rejected' => sub {
    plan tests => 1;
    my $tmp = tempdir(CLEANUP => 1);
    my $f = File::Spec->catfile($tmp, 'BACKLOG.md');
    open(my $fh, '>:raw', $f);
    print {$fh} "\xef\xbb\xbf# CWF System Backlog\n";
    close $fh;
    my ($s, $g_errs) = parse_backlog_file($f);
    ok((grep { $_->{rule} eq 'GLOBAL-001' } @$g_errs), 'GLOBAL-001 fired for BOM');
};

subtest 'validate: GLOBAL-001 CRLF rejected' => sub {
    plan tests => 1;
    my $tmp = tempdir(CLEANUP => 1);
    my $f = File::Spec->catfile($tmp, 'BACKLOG.md');
    open(my $fh, '>:raw', $f);
    print {$fh} "## Task: Foo\r\n\r\n**Task-Type**: chore\r\n**Priority**: Low\r\n";
    close $fh;
    my ($s, $g_errs) = parse_backlog_file($f);
    ok((grep { $_->{rule} eq 'GLOBAL-001' } @$g_errs), 'GLOBAL-001 fired for CRLF');
};

#==============================================================================
# Mutators
#==============================================================================

subtest 'set_priority_field: changes only priority line' => sub {
    plan tests => 3;
    my $f = _write_temp(<<"END");
## Task: Foo

**Task-Type**: chore
**Priority**: Medium
**Status**: Backlog

Body.
END
    my ($s, undef) = parse_backlog_file($f);
    my $orig_lines = join('', @{$s->[0]{raw_lines}});
    set_priority_field($s->[0], 'Low');
    my $new_lines = join('', @{$s->[0]{raw_lines}});

    like($new_lines, qr/^\*\*Priority\*\*: Low$/m, 'new priority present');
    unlike($new_lines, qr/^\*\*Priority\*\*: Medium$/m, 'old priority absent');
    is(entry_metadata($s->[0])->{'Status'}, 'Backlog', 'Status field unchanged');
};

subtest 'find_changelog_task: matches integer task number' => sub {
    plan tests => 3;
    my $f = _write_temp(<<"END");
# Changelog

## Task 42: Foo

**Status**: Complete (2026-01-01)
**Impact**: chore

---

## Task 7: Bar

**Status**: Complete (2026-01-01)
**Impact**: chore
END
    my ($s, undef) = parse_changelog_file($f);
    ok(defined find_changelog_task($s, 42), 'finds Task 42');
    ok(defined find_changelog_task($s, 7),  'finds Task 7');
    is(find_changelog_task($s, 999), undef, 'returns undef when missing');
};

subtest 'find_retired_subsection: locates bounds, respects fences' => sub {
    plan tests => 2;
    my $f = _write_temp(<<"END");
# Changelog

## Task 42: Foo

**Status**: Complete (2026-01-01)
**Impact**: chore

### Changes
- A.

### Retired Backlog Items

#### Some Title

Body.

### Notable
- B.
END
    my ($s, undef) = parse_changelog_file($f);
    my $entry = find_changelog_task($s, 42);
    my ($start, $end) = find_retired_subsection($entry);
    ok(defined $start, 'subsection start located');
    # Bounds: start at the heading, end before next `### Notable` heading.
    my $heading = $entry->{raw_lines}[$start];
    like($heading, qr/^### Retired Backlog Items/, 'start points at heading');
};

subtest 'block_exists_in_retired: case-insensitive title match' => sub {
    plan tests => 3;
    my $f = _write_temp(<<"END");
## Task 42: Foo

**Status**: Complete (2026-01-01)
**Impact**: chore

### Retired Backlog Items

#### Some Title

Body.

#### Another One

Body.
END
    my ($s, undef) = parse_changelog_file($f);
    my $entry = find_changelog_task($s, 42);
    ok(block_exists_in_retired($entry, 'Some Title'),  'exact match');
    ok(block_exists_in_retired($entry, 'some title'),  'case-insensitive match');
    ok(!block_exists_in_retired($entry, 'Nope'),       'no match returns false');
};

subtest 'append_retired_block: creates subsection at correct position' => sub {
    plan tests => 3;
    # Notable present → insert after Notable.
    my $f = _write_temp(<<"END");
## Task 42: Foo

**Status**: Complete (2026-01-01)
**Impact**: chore

### Changes
- A.

### Notable
- B.
END
    my ($s, undef) = parse_changelog_file($f);
    my $entry = find_changelog_task($s, 42);
    append_retired_block($entry, 'New Title', ["Body line one.\n"], undef);
    my $body = join('', @{$entry->{raw_lines}});
    like($body, qr/### Notable.*?- B\..*?### Retired Backlog Items.*?#### New Title.*?Body line one\./s,
        'inserted after Notable');

    # Only Changes present → insert after Changes.
    my $f2 = _write_temp(<<"END");
## Task 42: Foo

**Status**: Complete (2026-01-01)
**Impact**: chore

### Changes
- A.
END
    my ($s2, undef) = parse_changelog_file($f2);
    my $entry2 = find_changelog_task($s2, 42);
    append_retired_block($entry2, 'New Title', ["Body.\n"], undef);
    my $body2 = join('', @{$entry2->{raw_lines}});
    like($body2, qr/### Changes.*?- A\..*?### Retired Backlog Items/s,
        'inserted after Changes when Notable absent');

    # Neither present → insert after metadata.
    my $f3 = _write_temp(<<"END");
## Task 42: Foo

**Status**: Complete (2026-01-01)
**Impact**: chore
END
    my ($s3, undef) = parse_changelog_file($f3);
    my $entry3 = find_changelog_task($s3, 42);
    append_retired_block($entry3, 'New Title', ["Body.\n"], 'a note');
    my $body3 = join('', @{$entry3->{raw_lines}});
    like($body3, qr/\*\*Impact\*\*: chore.*?### Retired Backlog Items.*?<!-- Note: a note -->/s,
        'inserted after metadata when no other sections; --note rendered');
};

subtest 'append_retired_block: appends to existing subsection' => sub {
    plan tests => 2;
    my $f = _write_temp(<<"END");
## Task 42: Foo

**Status**: Complete (2026-01-01)
**Impact**: chore

### Retired Backlog Items

#### Existing Block

Existing body.
END
    my ($s, undef) = parse_changelog_file($f);
    my $entry = find_changelog_task($s, 42);
    append_retired_block($entry, 'New Block', ["New body.\n"], undef);
    my $body = join('', @{$entry->{raw_lines}});
    like($body, qr/#### Existing Block.*?Existing body\..*?#### New Block.*?New body\./s,
        'new block appended after existing');
    my @count = ($body =~ /^### Retired Backlog Items$/mg);
    is(scalar @count, 1, 'subsection heading not duplicated');
};

subtest 'fence-parity invariant: validators silent on patterns inside fences' => sub {
    plan tests => 1;
    my $f = _write_temp(<<'END');
## Task: Foo

**Task-Type**: chore
**Priority**: Low

Body before fence.

```
<!-- This is a comment, but it's inside a fence -->
## ~~Task: Fake struck-through inside fence~~
#### Fake h4 inside fence
### Notable inside fence
```

After fence.
END
    my ($s, undef) = parse_backlog_file($f);
    my $errs = validate_backlog($s);
    is(scalar(@$errs), 0, 'no validator findings on fenced patterns');
};

#==============================================================================
# Symlink-write defence
#==============================================================================

subtest 'write_backlog_file: refuses symlink target' => sub {
    plan tests => 1;
    my $tmp = tempdir(CLEANUP => 1);
    my $real = File::Spec->catfile($tmp, 'real.md');
    open(my $fh, '>', $real) or die; print {$fh} "## Task: Foo\n"; close $fh;
    my $link = File::Spec->catfile($tmp, 'BACKLOG.md');
    symlink($real, $link) or skip("symlink not supported", 1);

    eval { write_backlog_file($link, []) };
    like($@, qr/refusing symlink/, 'symlink target refused');
};

#==============================================================================
# Helpers
#==============================================================================

sub _write_temp {
    my ($content) = @_;
    my $tmp = tempdir(CLEANUP => 1);
    my $f = File::Spec->catfile($tmp, 'BACKLOG.md');
    open(my $fh, '>:raw', $f) or die "tempfile: $!";
    require Encode;
    print {$fh} Encode::encode('UTF-8', $content);
    close $fh;
    return $f;
}

sub _slurp_raw {
    my ($path) = @_;
    open(my $fh, '<:raw', $path) or die "$path: $!";
    local $/;
    my $bytes = <$fh>;
    close $fh;
    return $bytes;
}

sub _first_diff {
    my ($a, $b) = @_;
    my $min = length($a) < length($b) ? length($a) : length($b);
    for (my $i = 0; $i < $min; $i++) {
        if (substr($a, $i, 1) ne substr($b, $i, 1)) {
            my $start = $i > 30 ? $i - 30 : 0;
            return sprintf(
                "first diff at byte %d:\n  orig: %s\n  back: %s\n",
                $i,
                _esc(substr($a, $start, 60)),
                _esc(substr($b, $start, 60)),
            );
        }
    }
    return sprintf("identical up to byte %d, then orig has %d more / back has %d more bytes",
        $min, length($a) - $min, length($b) - $min);
}

sub _esc {
    my ($s) = @_;
    $s =~ s/\n/\\n/g;
    $s =~ s/\r/\\r/g;
    return $s;
}

done_testing();
