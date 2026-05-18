# Consolidate Cross-Doc Reference Patterns - Testing Execution
**Task**: 151 (discovery)

## Task Reference
- **Task ID**: internal-151
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/151-consolidate-cross-doc-reference-patterns
- **Template Version**: 2.1

## Goal
Verify AC1-AC8 from b-requirements and the NFR4/NFR5 hardening invariants from c-design against the artefacts produced by f-implementation-exec.

## Verifier Script Source

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

# verify-cites.pl — verify path:line and path:line-range citations in the
# cross-doc references convention. Pure-Perl line counting (no wc shell-out).
# List-form opens only. Core modules only.

my $target = "docs/conventions/cross-doc-references.md";
die "not at repo root: missing .git/\n" unless -d ".git";
die "missing target: $target\n" unless -e $target;

open(my $f, "<", $target) or die "open $target: $!\n";
local $/ = undef;
my $body = <$f>;
close $f;

my $extensions = qr{md|markdown|pl|pm|sh|bash|zsh|json|jsonl|txt|yml|yaml|toml|py|rb|go|rs|c|h|cpp|hpp|js|ts|jsx|tsx|html|css|conf|cfg|ini|log|tmpl|template|d|sample};
my $segment = qr{[\w.\-]+};
my $path_token = qr{
    (?:
        (?:\.{1,2}/)? $segment (?:/ $segment)+
        |
        [\w\-]+\. (?: $extensions )
    )
}x;

my @failures;
my $checked = 0;

while ($body =~ m{($path_token):(\d+)-(\d+)}g) {
    my ($p, $m, $n) = ($1, $2, $3);
    $checked++;
    verify_range($p, $m, $n);
}

while ($body =~ m{($path_token):(\d+)(?!-\d)}g) {
    my ($p, $m) = ($1, $2);
    $checked++;
    verify_range($p, $m, $m);
}

if (@failures) {
    print STDERR "verify-cites: $checked citation(s) checked, " . scalar(@failures) . " failure(s):\n";
    for my $msg (@failures) { print STDERR "  $msg\n"; }
    exit 1;
}
print "verify-cites: $checked citation(s) checked, all pass.\n";
exit 0;

sub verify_range {
    my ($path, $m, $n) = @_;
    unless (-e $path) {
        push @failures, "missing path: $path (cited as $path:$m" . ($m != $n ? "-$n" : "") . ")";
        return;
    }
    my $eff = effective_lines($path);
    if ($m < 1 || $n < $m || $n > $eff) {
        push @failures, "out-of-range: $path:$m" . ($m != $n ? "-$n" : "") . " (file has $eff lines)";
    }
}

sub effective_lines {
    my ($path) = @_;
    open(my $f, "<", $path) or do {
        push @failures, "open $path: $!";
        return 0;
    };
    local $/ = undef;
    my $buf = <$f>;
    close $f;
    return 0 unless defined $buf && length $buf;
    my $nl = ($buf =~ tr/\n//);
    $nl++ if substr($buf, -1) ne "\n";
    return $nl;
}
```

Run:
```
$ LC_ALL=C PERL5OPT=-CDSLA /tmp/-home-matt-repo-coding-with-files-task-151/verify-cites.pl
verify-cites: 6 citation(s) checked, all pass.
$ echo $?
0
```

## Acceptance Criteria Verification

### AC1: Audit reconciliation — PASS

The audit's scanned-files manifest is bidirectionally equivalent to `git ls-tree -r '*.md'` at the audit's baseline commit (`084774d3c7a120b6e6a1d21e8b288b38520f1037`):

```
$ sha=084774d3c7a120b6e6a1d21e8b288b38520f1037
$ git ls-tree -r --name-only $sha | grep '\.md$' | wc -l
1172
$ grep -c '^scanned: ' implementation-guide/151-.../audit-appendix.md
1172
$ comm -23 <(git ls-tree -r --name-only $sha | grep '\.md$' | sort) \
           <(grep '^scanned: ' implementation-guide/151-.../audit-appendix.md | sed 's/^scanned: //' | sort) | wc -l
0
$ comm -13 <(git ls-tree -r --name-only $sha | grep '\.md$' | sort) \
           <(grep '^scanned: ' implementation-guide/151-.../audit-appendix.md | sed 's/^scanned: //' | sort) | wc -l
0
```

Note: A bidirectional comparison against *current* `git ls-files` (post-f-implementation-exec) finds 3 files in current HEAD but not in the manifest (`docs/conventions/cross-doc-references.md`, `implementation-guide/151-*/audit-appendix.md`, `implementation-guide/151-*/f-implementation-exec.md`). These are task-created files post-baseline, expected. The AC binds the audit to its baseline commit; that comparison is the load-bearing one.

### AC2: Closed-enum populated — PASS

```
$ total=$(awk -F'|' '/^\| [^ ]/' implementation-guide/151-.../audit-appendix.md | wc -l); echo $total
21161
$ other=$(awk -F'|' '/^\| [^ ]/ && $5 == " other "' implementation-guide/151-.../audit-appendix.md | wc -l); echo $other
12
$ awk -v o=$other -v t=$total 'BEGIN{printf "%.4f\n", o/t}'
0.0006
```

12 / 21,161 = 0.06%, well under the 5% AC2 cap. All 12 `other` rows are `parse-warning` markers (unmatched fences at EOF), not classification failures. No row has any cell with `unknown`.

### AC3: Rules table cardinality — PASS

```
$ awk '/^\| Locality \|/,/^$/' docs/conventions/cross-doc-references.md | tail -n +2 | grep -c '^| '
4
$ awk -F'|' '/^\| [^ ]/ && $8 == " instructional " {print $6}' implementation-guide/151-.../audit-appendix.md | sort -u
 external
 intra-file
 intra-repo
 intra-task
```

4 rule rows for 4 occurring locality cells. No row contains "either is fine"; every locality has a preferred form. A `### Rejected alternatives` sub-section follows the table with 5 documented rejected alternatives, each with rationale.

### AC4: Citation soundness — PASS

```
$ LC_ALL=C PERL5OPT=-CDSLA /tmp/-home-matt-repo-coding-with-files-task-151/verify-cites.pl
verify-cites: 6 citation(s) checked, all pass.
$ echo $?
0
```

Every rule row in the style guide cites a `path:line` (or `path:line-range`) from the audit. The 6 citations are: `.cwf/docs/dead-code-audit.md:8`, `implementation-guide/102-feature-add-checkpoint-commit-helper-script-cwf-checkpoin/c-design-plan.md:61`, `.cwf/docs/skills/security-review.md:94`, `docs/conventions/commit-messages.md:138`, `.claude/skills/cwf-config/SKILL.md:34`, and the citation embedded in the style guide's intro (`commit-messages.md` again, in prose). All resolve; all lines within bounds.

### AC5: Divergence-count reproducibility — PASS

Total divergent rows (from f-implementation-exec.md ## Divergence Report) ≈ 7,964 — non-zero. BACKLOG entry filed:

```
$ grep -c 'Migrate cross-doc references to canonical style' BACKLOG.md
1
$ grep -A 1 'Migrate cross-doc references to canonical style' BACKLOG.md | head -3
#### Migrate cross-doc references to canonical style
##### Identified in
Task 151 g-testing-exec.md
```

Entry uses the `Task 151 g-testing-exec.md` format pinned in b-requirements FR5. The "iff count > 0" rule holds (count > 0, entry present).

### AC6: CLAUDE.md `## Conventions` entry format — PASS

```
$ grep -A 4 'cross-doc-references' CLAUDE.md
**Cross-Doc References**: Standard for how to reference other documents from CWF docs, templates, skills, and wf step files. See `docs/conventions/cross-doc-references.md` for:
- Rules table by locality (intra-file, intra-task, intra-repo, external)
- Rejected alternatives with rationale
- BACKLOG/CHANGELOG carve-out
```

Bolded entry name, one-line summary ending with `for:`, 3 bulleted items. Insertion confirmed between `**Git Path Handling**` (line 69) and `**Tmp Paths**` (line 78) per c-design D4.

### AC7: External-evidence dogfooding — PASS

`f-implementation-exec.md` ## Dogfooding Result section: `docs/conventions/commit-messages.md` has 7 references (all external URLs). 6 match the new rules directly; 1 (`https://github.com/org/repo/issues/123` on line 66) is a template placeholder and qualifies for the example/template URL carve-out. **0 mismatches**. The dogfooding result is recorded; the BACKLOG migration entry body includes the result for reference.

### AC8: Low-divergence outcome — PASS (trivially)

4 locality cells occur. The AC8 branch fires only at ≤ 2 occurring cells. With 4 cells, the rules table is genuinely populated (not "patterns already consistent" theatre); the AC is satisfied trivially.

## NFR Hardening Verification

### TC-9: NFR5 determinism — PASS

```
$ LC_ALL=C PERL5OPT=-CDSLA /tmp/-home-matt-repo-coding-with-files-task-151/audit.pl > /tmp/-home-matt-repo-coding-with-files-task-151/audit-output-run1.md
$ LC_ALL=C PERL5OPT=-CDSLA /tmp/-home-matt-repo-coding-with-files-task-151/audit.pl > /tmp/-home-matt-repo-coding-with-files-task-151/audit-output-run2.md
$ diff <(grep -v '<!-- audit baseline' /tmp/-home-matt-repo-coding-with-files-task-151/audit-output-run1.md) \
       <(grep -v '<!-- audit baseline' /tmp/-home-matt-repo-coding-with-files-task-151/audit-output-run2.md); echo $?
0
```

Bodies are byte-identical. (The `<!-- audit baseline: SHA -->` header is excluded from the diff because HEAD moves with each checkpoint commit during the task.)

### TC-10: NFR4 — no shell-interpolation surfaces — PASS

```
$ grep -E 'qx\{' /tmp/-home-matt-repo-coding-with-files-task-151/audit.pl /tmp/-home-matt-repo-coding-with-files-task-151/verify-cites.pl
(no matches)
$ grep -E '`[^`]*\$' /tmp/-home-matt-repo-coding-with-files-task-151/audit.pl /tmp/-home-matt-repo-coding-with-files-task-151/verify-cites.pl
audit.pl:80:    if ($line =~ /^( {0,3})(`{3,}|~{3,})(.*)$/) {
```

The single grep match is a false positive: the backtick is inside a regex literal pattern (`` `{3,} `` matches 3-or-more literal backticks for CommonMark fence detection), not a shell-out surface. No `qx{}`. All git invocations are list-form `open(... "-|", "git", ...)` (2 in audit.pl: `git rev-parse HEAD` and `git ls-files -z '*.md'`; verify-cites.pl makes no external calls).

### TC-11: NFR4 — scratch directory permissions — PASS

f-implementation-exec.md ## Operator Commands logs the very first command as `mkdir -m 0700 -p /tmp/-home-matt-repo-coding-with-files-task-151/`. The 0700 guard precedes any write to that path.

```
$ ls -ld /tmp/-home-matt-repo-coding-with-files-task-151/
drwx------ ... /tmp/-home-matt-repo-coding-with-files-task-151/
```

### TC-12: NFR4 — prompt-injection fence wrap — PASS

- `audit-appendix.md` opens with intro prose then a ` ```markdown ` fence containing the entire 21,161-row table including all path-shaped target cells scraped from skill bodies and agent definitions. Targets that previously contained backticks were transliterated to `'` by the audit script (line 363 of the embedded source) so no inner triple-backticks risk closing the outer fence.
- The dogfooding excerpt in `f-implementation-exec.md` is inside a ` ```markdown ` fence.
- The migration-body excerpts in BACKLOG.md (Migrate-cross-doc-references entry) are wrapped in ` ```markdown ` fences.

### TC-13: Self-compliance — PASS

`verify-cites.pl` passing exit-0 on `docs/conventions/cross-doc-references.md` is the self-compliance gate: every citation in the style guide resolves to a real path with in-bounds line numbers. The style guide is, by its own rules, internally consistent at commit time.

## Test Summary

| Test case | Result |
|---|---|
| TC-1 / AC1: Audit reconciliation | PASS |
| TC-2 / AC2: Closed-enum populated | PASS |
| TC-3 / AC3: Rules table cardinality | PASS |
| TC-4 / AC4: Citation soundness | PASS |
| TC-5 / AC5: Divergence-count reproducibility | PASS |
| TC-6 / AC6: CLAUDE.md entry format | PASS |
| TC-7 / AC7: External-evidence dogfooding | PASS |
| TC-8 / AC8: Low-divergence outcome (trivially) | PASS |
| TC-9: NFR5 determinism | PASS |
| TC-10: NFR4 no shell-interpolation surfaces | PASS |
| TC-11: NFR4 scratch dir permissions | PASS |
| TC-12: NFR4 prompt-injection fence wrap | PASS |
| TC-13: Self-compliance | PASS |

**13 / 13 PASS**. No failures, no skips, no N/A-without-rationale.

## Security Review

**State**: no findings

no findings: empty changeset (only `g-testing-exec.md` is in flight; not in CWF-internal pathspec dirs)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 13 test cases pass on the artefacts produced by f-implementation-exec.

## Lessons Learned
- AC1's bidirectional set difference is sensitive to whether the comparison anchor is "audit baseline" or "current HEAD". Pinning the comparison to the audit's recorded baseline SHA is the correct semantics; documenting this in the test evidence avoids spurious "missing-from-manifest" false positives when the task itself adds new files.
- `verify-cites.pl` is small enough (~70 lines) to be a one-file pure-Perl tool. Pure-Perl `tr/\n//` line counting matched the file's actual line count in every case; the trailing-newline carry-over rule (add 1 iff buffer doesn't end with `\n`) didn't fire on any tested file (every file in the corpus ends with a newline) but is preserved against drift.
