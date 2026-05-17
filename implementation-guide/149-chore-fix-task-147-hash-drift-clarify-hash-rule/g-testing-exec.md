# Fix Task 147 hash drift, clarify hash rule - Testing Execution
**Task**: 149 (chore)

## Task Reference
- **Task ID**: internal-149
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/149-fix-task-147-hash-drift-clarify-hash-rule
- **Template Version**: 2.1

## Goal
Execute TC-1 through TC-13 from e-testing-plan.md and record results.

## Test Results

### Functional Tests — Pre-refresh provenance (TC-1, TC-2)

| Test ID | Command | Expected | Actual | Status |
|---------|---------|----------|--------|--------|
| TC-1 | `git log --oneline 4f47494..HEAD -- .cwf/lib/CWF/Backlog.pm` | exactly one line, SHA `246e6c4`, Task 147 | `246e6c4 Task 147: retire bootstraps missing CHANGELOG task entry` (single line) | PASS |
| TC-2 | `git log --oneline f833bbf..HEAD -- .cwf/scripts/command-helpers/backlog-manager` | exactly one line, SHA `246e6c4`, Task 147 | `246e6c4 Task 147: retire bootstraps missing CHANGELOG task entry` (single line) | PASS |

### Functional Tests — Post-refresh integrity (TC-3, TC-4)

| Test ID | Command | Expected | Actual | Status |
|---------|---------|----------|--------|--------|
| TC-3 | `cwf-manage validate` | zero `[SECURITY]` lines for `CWF/Backlog.pm` or `backlog-manager` | zero matches for either | PASS |
| TC-4 | `cwf-manage validate` total `[SECURITY]` count | exactly 1 (misalignment-agent perm; out of scope) | exactly 1 — `cwf-plan-reviewer-misalignment.md` permissions 0600 vs 0444 | PASS |

### Reference-Integrity Tests (TC-5 to TC-8)

| Test ID | Command | Expected | Actual | Status |
|---------|---------|----------|--------|--------|
| TC-5 | `grep -F '.cwf/docs/conventions/hash-updates.md' .claude/skills/cwf-implementation-exec/SKILL.md` | ≥1 match, in Gotchas | 1 match at line 17, Gotcha 3 | PASS |
| TC-6 | `grep -F '.cwf/docs/conventions/hash-updates.md' .claude/skills/cwf-retrospective/SKILL.md` | ≥1 match, in Gotchas | 1 match at line 17, Gotcha 4 | PASS |
| TC-7 | `grep -F 'hash-updates' CLAUDE.md` (in `## Conventions`) | ≥1 match | 1 match at line 78, inside `## Conventions` (between `**Tmp Paths**` and `## Architecture Overview`) | PASS |
| TC-8 | `grep -F 'hash-updates' docs/conventions/design-alignment.md` | ≥1 match | 1 match at line 82, inline with existing `script-hashes.json` paragraph | PASS |

### Document-Integrity Tests (TC-9 to TC-11)

| Test ID | Check | Expected | Actual | Status |
|---------|-------|----------|--------|--------|
| TC-9 | `grep -F '.cwf/security/script-hashes.json' .cwf/docs/conventions/hash-updates.md` | ≥1 match | 3 matches (Why §, How § step 3, Plan-time disclosure §) | PASS |
| TC-10 | Case-insensitive grep for 7 required strings | each present ≥1 | all 7 headings/strings present: Convention, Plan-time disclosure, Pre-refresh verification, Carve-out, What NOT to build, Historical example, Task 147 | PASS |
| TC-11 | `awk` Carve-out section, count `^[0-9]+\.` lines | exactly 4 | 4 invariants enumerated: (1) named drifted entries, (2) per-file `git log` verification, (3) no other source edits, (4) originating commit(s) named | PASS |

### Non-Functional Tests (TC-12, TC-13)

| Test ID | Check | Expected | Actual | Status |
|---------|-------|----------|--------|--------|
| TC-12 | `wc -l .cwf/docs/conventions/hash-updates.md` | ≤ 80 | 49 | PASS |
| TC-13 | Edit diff context contains anchor heading, not bare line number | each SKILL hunk includes `## Scope & Boundaries` heading line | both diffs show `## Scope & Boundaries` as the post-context line; the anchor is the heading text, not a line number | PASS |

## Test Failures

None.

## Coverage Report

- **Functional**: 4/4 (TC-1 to TC-4) — both directions of provenance + post-refresh validate covered.
- **Reference integrity**: 4/4 advertised consumers (two SKILLs + CLAUDE.md + design-alignment.md) link the convention doc.
- **Document integrity**: 3/3 (canonical-path reference, required-sections enumeration, four-invariant carve-out).
- **Non-functional**: 2/2 (line-budget, anchor robustness).
- **Total**: 13/13 PASS. No refinement attempts; first-pass clean.

### Plan-deviation note

None. e-testing-plan.md TC-1/TC-2 baseline SHAs and expected outputs matched exactly. The d-plan §Step 1 verification step (per-file baselines `4f47494` for Backlog.pm and `f833bbf` for backlog-manager) was load-bearing — a single shared baseline would have over-included Tasks 139/140's commits on backlog-manager and triggered the STOP rule in error.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 149
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

no findings
Both diff hunks are documentation-only additions to skill files; they tighten the workflow rules around hash-tracked files and explicitly forbid the "smooth the warning" anti-pattern at retrospective time. No code paths, no new inputs, no permission/auth changes — purely guidance text. The retrospective rule correctly reinforces "surface security issues, never smooth them."

Relevant paths:
- /home/matt/repo/coding-with-files/.claude/skills/cwf-implementation-exec/SKILL.md
- /home/matt/repo/coding-with-files/.claude/skills/cwf-retrospective/SKILL.md

## Lessons Learned
*To be captured during retrospective*
