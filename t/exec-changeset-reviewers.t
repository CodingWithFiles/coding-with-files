#!/usr/bin/env perl
#
# exec-changeset-reviewers.t - Static/structural + classifier-behavioural tests
# for the Task 210 exec-changeset reviewer agents (improvements / robustness /
# misalignment) and their wiring into cwf-implementation-exec Step 8.
#
# These assert the file-level invariants deterministically (the live 5-reviewer
# MAP is verified by output-level smoke in g-testing-exec, not here). Core Perl
# only; reads installed files in place.
#
use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempfile);
use FindBin;

my $ROOT = "$FindBin::Bin/..";

sub slurp {
    my ($path) = @_;
    open my $fh, '<:encoding(UTF-8)', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}

# Frontmatter = text between the leading `---` fence and the next `---`.
sub frontmatter {
    my ($txt) = @_;
    return $txt =~ /\A---\n(.*?)\n---\n/s ? $1 : '';
}

my @LENSES = qw(improvements robustness misalignment);
my %AGENT = map {
    $_ => "$ROOT/.claude/agents/cwf-$_-reviewer-changeset.md"
} @LENSES;

my $PRECEDENT = "$ROOT/.claude/agents/cwf-best-practice-reviewer-changeset.md";
my $IMPL_EXEC = "$ROOT/.claude/skills/cwf-implementation-exec/SKILL.md";
my $TEST_EXEC = "$ROOT/.claude/skills/cwf-testing-exec/SKILL.md";
my $GUARD     = "$ROOT/.cwf/scripts/hooks/subagentstop-security-verdict-guard";
my $CLASSIFY  = "$ROOT/.cwf/scripts/command-helpers/security-review-classify";

# Expected tool grant derived from the cloned precedent, not hand-authored.
my ($EXPECTED_TOOLS) = frontmatter(slurp($PRECEDENT)) =~ /^tools:\s*(.+?)\s*$/m;
ok($EXPECTED_TOOLS, "precedent exposes a tools: line ($EXPECTED_TOOLS)");

# ---------------------------------------------------------------------------
# TC-1: three agents exist, Bash-free (security-load-bearing).
# ---------------------------------------------------------------------------
subtest 'TC-1: three lens agents exist and are Bash-free' => sub {
    for my $lens (@LENSES) {
        my $name = "cwf-$lens-reviewer-changeset";
        ok(-f $AGENT{$lens}, "$name: file exists");
        my $txt = slurp($AGENT{$lens});
        my $fm  = frontmatter($txt);
        # Hard fail: no Bash token anywhere in the frontmatter (the tool grant).
        unlike($fm, qr/Bash/, "$name: frontmatter grants no Bash");
        my ($tools) = $fm =~ /^tools:\s*(.+?)\s*$/m;
        is($tools, $EXPECTED_TOOLS, "$name: tools match the cloned precedent");
        like($fm, qr/^effort:\s*high\s*$/m, "$name: effort: high");
        like($fm, qr/^name:\s*\Q$name\E\s*$/m, "$name: frontmatter name matches file");
        like($txt, qr/cwf-agent-shared-rules\.md/, "$name: shared-rules pointer present");
    }
};

# ---------------------------------------------------------------------------
# TC-2: verdict-block contract present, bp-input absent.
# ---------------------------------------------------------------------------
subtest 'TC-2: verdict block present, no {bp_context_file}' => sub {
    for my $lens (@LENSES) {
        my $name = "cwf-$lens-reviewer-changeset";
        my $txt  = slurp($AGENT{$lens});
        like($txt, qr/```cwf-review/, "$name: cwf-review fenced block present");
        like($txt, qr/Bash is intentionally withheld/,
             "$name: carries the Bash-withheld paragraph");
        unlike($txt, qr/\{bp_context_file\}/,
               "$name: no {bp_context_file} input (dropped from the clone)");
    }
};

# ---------------------------------------------------------------------------
# TC-3: implementation-exec Step 8 lists five reviewers, no stale 2-reviewer text.
# ---------------------------------------------------------------------------
subtest 'TC-3: impl-exec Step 8 names five reviewers' => sub {
    my $txt = slurp($IMPL_EXEC);
    # Scope the stale-string checks to the Step 8 region (per the TC-DOCS precedent).
    my ($step8) = $txt =~ /(\*\*Step 8.*?)\*\*Step 9\*\*/s;
    ok($step8, 'Step 8 region located');
    for my $name (qw(
        cwf-security-reviewer-changeset
        cwf-best-practice-reviewer-changeset
        cwf-improvements-reviewer-changeset
        cwf-robustness-reviewer-changeset
        cwf-misalignment-reviewer-changeset
    )) {
        like($step8, qr/\Q$name\E/, "Step 8 names $name");
    }
    unlike($step8, qr/Two independent reviewers/i,
           'no stale "Two independent reviewers" text');
    unlike($step8, qr/\(0, 1, or 2 calls\)/,
           'no stale "(0, 1, or 2 calls)" count');
    like($step8, qr/\(0 to 5 calls\)/, 'MAP count updated to 0 to 5 calls');
};

# ---------------------------------------------------------------------------
# TC-4: testing-exec Step 8 lists EXACTLY the two existing reviewers (FR4).
# ---------------------------------------------------------------------------
subtest 'TC-4: testing-exec stays two reviewers, no lens names' => sub {
    my $txt = slurp($TEST_EXEC);
    like($txt, qr/cwf-security-reviewer-changeset/, 'testing-exec keeps security reviewer');
    like($txt, qr/cwf-best-practice-reviewer-changeset/, 'testing-exec keeps best-practice reviewer');
    for my $lens (@LENSES) {
        my $name = "cwf-$lens-reviewer-changeset";
        unlike($txt, qr/\Q$name\E/, "testing-exec does NOT name $name anywhere");
    }
};

# ---------------------------------------------------------------------------
# TC-5: SubagentStop guard matcher directive still scopes only the security
# reviewer (the three new advisory reviewers were not added to its allowlist).
# ---------------------------------------------------------------------------
subtest 'TC-5: guard matcher unchanged (security reviewer only)' => sub {
    my $txt = slurp($GUARD);
    my ($matcher) = $txt =~ /^#\s*cwf-hook-matcher:\s*(.+?)\s*$/m;
    is($matcher, 'cwf-security-reviewer-changeset',
       'matcher directive names only the security reviewer');
    for my $lens (@LENSES) {
        unlike($txt, qr/cwf-$lens-reviewer-changeset/,
               "guard does not reference cwf-$lens-reviewer-changeset");
    }
};

# ---------------------------------------------------------------------------
# TC-6 / TC-7: degradation paths wire ALL FIVE sections (the 2->5 regression).
# The Step 8 prose names all five `## <Lens> Review` headings on the on-main
# branch, and the four security+lens sections on the empty-changeset branch
# (best-practice's empty path is "no changeset to review"). Heading coverage is
# the regression guard: a future collapse back to two would drop a heading.
# ---------------------------------------------------------------------------
my @HEADINGS = (
    '## Security Review', '## Best-Practice Review', '## Improvements Review',
    '## Robustness Review', '## Misalignment Review',
);
subtest 'TC-6: on-main branch names all five sections' => sub {
    my $txt = slurp($IMPL_EXEC);
    my ($onmain) = $txt =~ /(If `main`.*?proceed to Step 9)/s;
    ok($onmain, 'on-main clause located');
    like($onmain, qr/no findings: on main/, 'on-main uses the "on main" reason');
    for my $h (@HEADINGS) {
        like($onmain, qr/\Q$h\E/, "on-main names $h");
    }
};
subtest 'TC-7: empty-changeset branch records security + three lens sections' => sub {
    my $txt = slurp($IMPL_EXEC);
    # Helper #1 count-0 clause drives the security + three lens "empty changeset" records.
    like($txt, qr/no findings: empty changeset/, 'empty-changeset reason present');
    for my $h ('## Security Review', '## Improvements Review',
               '## Robustness Review', '## Misalignment Review') {
        like($txt, qr/\Q$h\E/, "Step 8 wires $h");
    }
    # Best-practice's own empty-input path stays distinct (its own message).
    like($txt, qr/no changeset to review/, 'best-practice empty path is "no changeset to review"');
};

# ---------------------------------------------------------------------------
# Behavioural via the shared classifier.
# ---------------------------------------------------------------------------
sub classify {
    my ($input) = @_;
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh, ':raw';
    print $fh $input;
    close $fh;
    my $out = `'$CLASSIFY' < '$path'`;
    $out =~ s/\n\z// if defined $out;
    return $out // '';
}
sub block { my ($s) = @_; return "```cwf-review\nstate: $s\n```\n"; }

# TC-8: a well-formed verdict block in the shape the new agents document parses
# clean (proves the copied block is wired to the shared classifier).
subtest 'TC-8: new-agent verdict block parses to its token' => sub {
    is(classify("Reasoning prose about the diff.\n\n" . block('no findings')),
       'no findings', 'no findings block -> no findings');
    is(classify("Found a duplicated helper.\n\n" . block('findings')),
       'findings', 'findings block -> findings');
};

# TC-9: error isolation across five independent outputs — one malformed does not
# affect its siblings (each section is classified independently).
subtest 'TC-9: error isolation across five classified outputs' => sub {
    my @outs = (
        block('no findings'),                       # security
        block('no findings'),                       # best-practice
        "prose only, no verdict block at all\n",    # improvements (malformed)
        block('findings'),                          # robustness
        block('no findings'),                       # misalignment
    );
    my @tok = map { classify($_) } @outs;
    is_deeply(\@tok,
        ['no findings', 'no findings', 'error', 'findings', 'no findings'],
        'one malformed output classifies as error; the other four are unaffected');
};

# ---------------------------------------------------------------------------
# TC-10: cwf-manage validate is clean for the three new hashed agents.
# ---------------------------------------------------------------------------
subtest 'TC-10: cwf-manage validate clean for the new agents' => sub {
    my $mgr = "$ROOT/.cwf/scripts/cwf-manage";
    my $pid = open(my $fh, '-|', $mgr, 'validate') or die "fork cwf-manage: $!";
    my $output = do { local $/; <$fh> };
    close $fh;
    my $rc = $? >> 8;
    $output //= '';
    is($rc, 0, 'cwf-manage validate exits 0');
    for my $lens (@LENSES) {
        unlike($output, qr/cwf-$lens-reviewer-changeset/,
               "no integrity violation names cwf-$lens-reviewer-changeset");
    }
};

done_testing();
