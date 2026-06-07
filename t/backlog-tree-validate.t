#!/usr/bin/env perl
#
# backlog-tree-validate.t — Per-rule positive and negative tests for
# validate_backlog_tree / validate_changelog_tree (Task 132).
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
    parse_backlog_tree parse_changelog_tree
    validate_backlog_tree validate_changelog_tree
);

my @TMP;
sub write_tmp {
    my ($bytes) = @_;
    my ($fh, $path) = tempfile('btvalXXXXXX', SUFFIX => '.md', UNLINK => 1, TMPDIR => 1);
    binmode $fh, ':raw';
    print $fh $bytes;
    close $fh;
    push @TMP, $path;
    return $path;
}

sub parse_and_validate_backlog {
    my ($bytes) = @_;
    my $path = write_tmp($bytes);
    my ($tree, $g) = parse_backlog_tree($path);
    my $errs = validate_backlog_tree($tree, $path);
    return ($tree, [@$g, @$errs]);
}

sub parse_and_validate_changelog {
    my ($bytes) = @_;
    my $path = write_tmp($bytes);
    my ($tree, $g) = parse_changelog_tree($path);
    my $errs = validate_changelog_tree($tree, $path);
    return ($tree, [@$g, @$errs]);
}

sub has_rule {
    my ($errs, $rule) = @_;
    return scalar grep { ($_->{rule} // '') eq $rule } @$errs;
}

sub get_rule {
    my ($errs, $rule) = @_;
    return grep { ($_->{rule} // '') eq $rule } @$errs;
}

my $valid_backlog_entry =
    "## Task: Foo\n\n### Task-Type: chore\n### Priority: Low\n\nbody\n";

#==============================================================================
# GLOBAL-001a (BOM)
#==============================================================================
subtest 'TC-VAL-GLOBAL-001a' => sub {
    plan tests => 2;
    my (undef, $clean) = parse_and_validate_backlog($valid_backlog_entry);
    is(has_rule($clean, 'GLOBAL-001'), 0, 'pos: no BOM → silent');

    my (undef, $bom) = parse_and_validate_backlog("\x{ef}\x{bb}\x{bf}" . $valid_backlog_entry);
    cmp_ok(has_rule($bom, 'GLOBAL-001'), '>=', 1, 'neg: BOM fires GLOBAL-001');
};

#==============================================================================
# GLOBAL-001b (CRLF)
#==============================================================================
subtest 'TC-VAL-GLOBAL-001b' => sub {
    plan tests => 2;
    my (undef, $clean) = parse_and_validate_backlog($valid_backlog_entry);
    is(has_rule($clean, 'GLOBAL-001'), 0, 'pos: LF only → silent');

    (my $crlf = $valid_backlog_entry) =~ s/\n/\r\n/g;
    my (undef, $errs) = parse_and_validate_backlog($crlf);
    cmp_ok(has_rule($errs, 'GLOBAL-001'), '>=', 1, 'neg: CRLF fires');
};

#==============================================================================
# GLOBAL-002 (heading control characters)
#==============================================================================
subtest 'TC-VAL-GLOBAL-002' => sub {
    plan tests => 3;
    my (undef, $clean) = parse_and_validate_backlog($valid_backlog_entry);
    is(has_rule($clean, 'GLOBAL-002'), 0, 'pos: clean heading → silent');

    my (undef, $errs) = parse_and_validate_backlog(
        "## Task: Foo\x01Bar\n\n### Task-Type: chore\n### Priority: Low\n");
    cmp_ok(has_rule($errs, 'GLOBAL-002'), '>=', 1, 'neg: \\x01 in title fires');
    my ($e) = get_rule($errs, 'GLOBAL-002');
    is($e->{line}, 1, 'reports H2 line number');
};

#==============================================================================
# BACKLOG-001 (Task-Type and Priority required)
#==============================================================================
subtest 'TC-VAL-BACKLOG-001' => sub {
    plan tests => 4;
    my (undef, $clean) = parse_and_validate_backlog($valid_backlog_entry);
    is(has_rule($clean, 'BACKLOG-001'), 0, 'pos: both fields → silent');

    my (undef, $no_tt) = parse_and_validate_backlog(
        "## Task: Foo\n\n### Priority: Low\n\nbody\n");
    cmp_ok(has_rule($no_tt, 'BACKLOG-001'), '>=', 1, 'neg-tt: missing Task-Type fires');

    my (undef, $no_pri) = parse_and_validate_backlog(
        "## Task: Foo\n\n### Task-Type: chore\n\nbody\n");
    cmp_ok(has_rule($no_pri, 'BACKLOG-001'), '>=', 1, 'neg-pri: missing Priority fires');

    my (undef, $none) = parse_and_validate_backlog("## Task: Foo\n\nbody\n");
    is((scalar grep { $_->{rule} eq 'BACKLOG-001' } @$none), 2, 'neg-both: 2 BACKLOG-001 errors');
};

#==============================================================================
# BACKLOG-002 (Priority value validity)
#==============================================================================
subtest 'TC-VAL-BACKLOG-002' => sub {
    plan tests => 6;
    for my $val ('Very High', 'High', 'Medium', 'Low', 'Very Low') {
        my $b = "## Task: Foo\n\n### Task-Type: chore\n### Priority: $val\n\nbody\n";
        my (undef, $errs) = parse_and_validate_backlog($b);
        is(has_rule($errs, 'BACKLOG-002'), 0, "pos: '$val' silent");
    }
    my (undef, $bad) = parse_and_validate_backlog(
        "## Task: Foo\n\n### Task-Type: chore\n### Priority: Critical\n\nbody\n");
    cmp_ok(has_rule($bad, 'BACKLOG-002'), '>=', 1, 'neg: Critical fires');
};

#==============================================================================
# BACKLOG-004 (no HTML comments)
#==============================================================================
subtest 'TC-VAL-BACKLOG-004' => sub {
    plan tests => 3;
    my (undef, $clean) = parse_and_validate_backlog($valid_backlog_entry);
    is(has_rule($clean, 'BACKLOG-004'), 0, 'pos: no comment → silent');

    my (undef, $errs) = parse_and_validate_backlog(
        "## Task: Foo\n\n### Task-Type: chore\n### Priority: Low\n\nbody <!-- bad --> here\n");
    cmp_ok(has_rule($errs, 'BACKLOG-004'), '>=', 1, 'neg: HTML comment fires');

    # Fence-aware: comment inside fenced code block is ignored.
    my $fenced = join('',
        "## Task: Foo\n\n",
        "### Task-Type: chore\n### Priority: Low\n\n",
        "Example:\n",
        "```\n",
        "<!-- example comment -->\n",
        "```\n",
    );
    my (undef, $f_errs) = parse_and_validate_backlog($fenced);
    is(has_rule($f_errs, 'BACKLOG-004'), 0, 'pos-fence: comment in fence → silent');
};

#==============================================================================
# BACKLOG-005 (struck-through titles)
#==============================================================================
subtest 'TC-VAL-BACKLOG-005' => sub {
    plan tests => 3;
    my (undef, $clean) = parse_and_validate_backlog($valid_backlog_entry);
    is(has_rule($clean, 'BACKLOG-005'), 0, 'pos: clean title silent');

    my (undef, $tilde) = parse_and_validate_backlog(
        "## Task: ~~Foo~~\n\n### Task-Type: chore\n### Priority: Low\n");
    cmp_ok(has_rule($tilde, 'BACKLOG-005'), '>=', 1, 'neg-tilde: ~~ fires');

    my (undef, $tick) = parse_and_validate_backlog(
        "## Task: Foo \x{2713}\n\n### Task-Type: chore\n### Priority: Low\n");
    cmp_ok(has_rule($tick, 'BACKLOG-005'), '>=', 1, 'neg-tick: ✓ fires');
};

#==============================================================================
# BACKLOG-007 (warning: body before metadata)
#==============================================================================
subtest 'TC-VAL-BACKLOG-007' => sub {
    plan tests => 3;
    my (undef, $canon) = parse_and_validate_backlog($valid_backlog_entry);
    is(has_rule($canon, 'BACKLOG-007'), 0, 'pos: canonical → silent');

    my (undef, $errs) = parse_and_validate_backlog(
        "## Task: Foo\n\nprose first\n\n### Task-Type: chore\n### Priority: Low\n");
    cmp_ok(has_rule($errs, 'BACKLOG-007'), '>=', 1, 'neg: body-before-metadata warns');
    my ($w) = get_rule($errs, 'BACKLOG-007');
    is($w->{severity}, 'warning', 'severity is warning');
};

#==============================================================================
# CHANGELOG-001 (single # Changelog header)
#==============================================================================
subtest 'TC-VAL-CHANGELOG-001' => sub {
    plan tests => 3;
    my $valid = "# Changelog\n\n## Task 131: Foo\n\n### Status: Complete\n### Impact: Feature\n";
    my (undef, $clean) = parse_and_validate_changelog($valid);
    is(has_rule($clean, 'CHANGELOG-001'), 0, 'pos: one header → silent');

    my (undef, $zero) = parse_and_validate_changelog(
        "## Task 131: Foo\n\n### Status: Complete\n### Impact: Feature\n");
    cmp_ok(has_rule($zero, 'CHANGELOG-001'), '>=', 1, 'neg-zero: missing fires');

    my (undef, $multi) = parse_and_validate_changelog(
        "# Changelog\n# Changelog\n\n## Task 131: Foo\n\n### Status: Complete\n### Impact: Feature\n");
    cmp_ok(has_rule($multi, 'CHANGELOG-001'), '>=', 1, 'neg-multi: 2 headers fire');
};

#==============================================================================
# CHANGELOG-002 (Status + Impact required)
#==============================================================================
subtest 'TC-VAL-CHANGELOG-002' => sub {
    plan tests => 3;
    my $valid = "# Changelog\n\n## Task 131: Foo\n\n### Status: Complete\n### Impact: Feature\n";
    my (undef, $clean) = parse_and_validate_changelog($valid);
    is(has_rule($clean, 'CHANGELOG-002'), 0, 'pos: both fields silent');

    my (undef, $no_status) = parse_and_validate_changelog(
        "# Changelog\n\n## Task 131: Foo\n\n### Impact: Feature\n");
    cmp_ok(has_rule($no_status, 'CHANGELOG-002'), '>=', 1, 'neg: missing Status fires');

    my (undef, $no_impact) = parse_and_validate_changelog(
        "# Changelog\n\n## Task 131: Foo\n\n### Status: Complete\n");
    cmp_ok(has_rule($no_impact, 'CHANGELOG-002'), '>=', 1, 'neg: missing Impact fires');
};

#==============================================================================
# CHANGELOG-003 (subsection order)
#==============================================================================
subtest 'TC-VAL-CHANGELOG-003' => sub {
    plan tests => 3;
    my $valid = join('',
        "# Changelog\n\n",
        "## Task 131: Foo\n\n",
        "### Status: x\n### Impact: y\n\n",
        "### Changes\n- a\n", "\n",
        "### Notable\n- b\n", "\n",
        "### Retired Backlog Items\n#### bar\n",
    );
    my (undef, $clean) = parse_and_validate_changelog($valid);
    is(has_rule($clean, 'CHANGELOG-003'), 0, 'pos: canonical order silent');

    my $extras = join('',
        "# Changelog\n\n",
        "## Task 131: Foo\n\n",
        "### Status: x\n### Impact: y\n\n",
        "### Changes\n- a\n", "\n",
        "### Notable\n- b\n", "\n",
        "### Retired Backlog Items\n#### bar\n", "\n",
        "### Future Work\n- c\n",
    );
    my (undef, $clean2) = parse_and_validate_changelog($extras);
    is(has_rule($clean2, 'CHANGELOG-003'), 0, 'pos-extra: trailing extras allowed');

    my $bad = join('',
        "# Changelog\n\n",
        "## Task 131: Foo\n\n",
        "### Status: x\n### Impact: y\n\n",
        "### Notable\n- b\n", "\n",
        "### Changes\n- a\n",
    );
    my (undef, $errs) = parse_and_validate_changelog($bad);
    cmp_ok(has_rule($errs, 'CHANGELOG-003'), '>=', 1, 'neg: Notable before Changes fires');
};

#==============================================================================
# CHANGELOG-004 (warning: body before metadata) — same shape as BACKLOG-007
#==============================================================================
subtest 'TC-VAL-CHANGELOG-004' => sub {
    plan tests => 2;
    my $valid = "# Changelog\n\n## Task 131: Foo\n\n### Status: x\n### Impact: y\n\nbody\n";
    my (undef, $clean) = parse_and_validate_changelog($valid);
    is(has_rule($clean, 'CHANGELOG-004'), 0, 'pos: canonical silent');

    my $bad = "# Changelog\n\n## Task 131: Foo\n\nbody first\n\n### Status: x\n### Impact: y\n";
    my (undef, $errs) = parse_and_validate_changelog($bad);
    cmp_ok(has_rule($errs, 'CHANGELOG-004'), '>=', 1, 'neg: body before metadata warns');
};

#==============================================================================
# CHANGELOG-005 (warning: stale project name in intro) — Task 184
# Intro-scoped exactly like CHANGELOG-001: the body legitimately carries
# historical "(CIG)" fragments in retired Task-59 entries, which must not fire.
#==============================================================================
subtest 'TC-VAL-CHANGELOG-005' => sub {
    plan tests => 5;

    my $stale_intro = join('',
        "# Changelog\n\n",
        "All notable changes to the Code Implementation Guide (CIG) project are documented in this file, organized by task.\n\n",
        "## Task 131: Foo\n\n### Status: Complete\n### Impact: Feature\n",
    );
    my (undef, $stale) = parse_and_validate_changelog($stale_intro);
    cmp_ok(has_rule($stale, 'CHANGELOG-005'), '>=', 1, 'neg: stale intro fires CHANGELOG-005');
    my ($w) = get_rule($stale, 'CHANGELOG-005');
    is($w->{severity}, 'warning', 'severity is warning');
    is($w->{line}, 1, 'reports line 1');

    my $canon_intro = join('',
        "# Changelog\n\n",
        "All notable changes to the Coding with Files (CWF) project are documented in this file, organized by task.\n\n",
        "## Task 131: Foo\n\n### Status: Complete\n### Impact: Feature\n",
    );
    my (undef, $canon) = parse_and_validate_changelog($canon_intro);
    is(has_rule($canon, 'CHANGELOG-005'), 0, 'pos: canonical intro → silent');

    # Intro-scoping proof: canonical intro, but a retired-entry body mentions "(CIG)".
    my $body_only = join('',
        "# Changelog\n\n",
        "All notable changes to the Coding with Files (CWF) project are documented in this file, organized by task.\n\n",
        "## Task 59: Rebrand\n\n### Status: Complete\n### Impact: Feature\n\n",
        "### Changes\n- Renamed from Code Implementation Guide (CIG) to Coding with Files.\n",
    );
    my (undef, $body) = parse_and_validate_changelog($body_only);
    is(has_rule($body, 'CHANGELOG-005'), 0, 'pos: body-only "(CIG)" → silent (intro-scoped)');
};

#==============================================================================
# TC-VAL-FENCE-INVARIANT — single fixture with all "violators" in one fence.
# All validator rules silent on the fenced content; the file-wide single-source
# fence map prevents disagreement between rules.
#==============================================================================
subtest 'TC-VAL-FENCE-INVARIANT' => sub {
    plan tests => 4;
    my $bytes = join('',
        "## Task: Foo\n\n",
        "### Task-Type: chore\n### Priority: Low\n\n",
        "Fenced examples:\n",
        "```\n",
        "<!-- foo -->\n",
        "## ~~StruckThrough~~\n",
        "#### body-h4\n",
        "### Changes\n",
        "### Status: x\n",
        "```\n",
    );
    my (undef, $errs) = parse_and_validate_backlog($bytes);
    is(has_rule($errs, 'BACKLOG-004'), 0, 'BACKLOG-004 silent on fenced HTML comment');
    is(has_rule($errs, 'BACKLOG-005'), 0, 'BACKLOG-005 silent on fenced struck title');
    is(has_rule($errs, 'BACKLOG-001'), 0, 'BACKLOG-001 silent (real metadata present)');
    is(has_rule($errs, 'BACKLOG-002'), 0, 'BACKLOG-002 silent');
};

#==============================================================================
# Retired-rule regression: Task 131's BACKLOG-003 (body lines `^---$`) and
# BACKLOG-006 (body lines `^####`) are RETIRED in Task 132. Assert that
# fixtures which would have failed those rules now pass cleanly.
#==============================================================================
subtest 'retired BACKLOG-003: body line `---` no longer fires' => sub {
    plan tests => 2;
    my $bytes = "## Task: Foo\n\n### Task-Type: chore\n### Priority: Low\n\nbody before\n---\nbody after\n";
    my (undef, $errs) = parse_and_validate_backlog($bytes);
    is(has_rule($errs, 'BACKLOG-003'), 0, 'BACKLOG-003 not fired');
    is(scalar(grep { ($_->{severity}//'error') eq 'error' } @$errs), 0, 'no errors');
};

subtest 'retired BACKLOG-006: body line `#### Sub` no longer fires' => sub {
    plan tests => 2;
    my $bytes = "## Task: Foo\n\n### Task-Type: chore\n### Priority: Low\n\nbody\n#### Sub heading\nmore body\n";
    my (undef, $errs) = parse_and_validate_backlog($bytes);
    is(has_rule($errs, 'BACKLOG-006'), 0, 'BACKLOG-006 not fired');
    is(scalar(grep { ($_->{severity}//'error') eq 'error' } @$errs), 0, 'no errors');
};

done_testing;
