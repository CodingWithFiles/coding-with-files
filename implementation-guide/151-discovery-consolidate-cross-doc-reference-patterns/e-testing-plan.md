# Consolidate Cross-Doc Reference Patterns - Testing Plan
**Task**: 151 (discovery)

## Task Reference
- **Task ID**: internal-151
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/151-consolidate-cross-doc-reference-patterns
- **Template Version**: 2.1

## Goal
Define the test strategy and Given/When/Then test cases for verifying b-requirements AC1-AC8 and the c-design hardening invariants against the artefacts produced by f-implementation-exec.

## Test Strategy

### Test Levels
- **Unit-equivalent**: Regex-pipeline behaviour of `audit.pl` on known-input fixtures (synthetic snippets) — confirms each delimiter and target-shape regex matches and doesn't over-match. Optional; the corpus is the real test.
- **Integration**: `audit.pl` + `verify-cites.pl` against the real repo at the recorded baseline commit.
- **Acceptance**: Mechanical verification of AC1-AC8 from b-requirements. This is the load-bearing test level for a discovery task.
- **Regression**: Re-run the audit a second time after the style guide is committed. Output must be byte-identical to the first run (NFR5 determinism).

### Test Coverage Targets
- **AC coverage**: 8/8 (all of AC1-AC8 verified with cited evidence in `g-testing-exec.md`).
- **Hardening invariants** (separate from ACs):
  - Pre-flight check absent (no runtime SHA gate that misfires).
  - All git invocations list-form (grep `audit.pl` and `verify-cites.pl` sources for `qx{`, `` ` ``, and `system " ... "` — must return zero).
  - `mkdir -m 0700` line present in operator command log.
  - Audit appendix and migration-body excerpts wrapped in ` ```markdown ` fences.
- **No coverage of**: existing references that diverge from the new standard — those are migration scope (FR5), not this task's tests.

## Test Cases

### Functional Test Cases

**TC-1: Audit reconciliation (AC1)**
- **Given**: The audit has run and `f-implementation-exec.md` contains an `## Audit Output` fenced block.
- **When**: Operator extracts the unique `source-file` column from the audit table and compares against `git ls-files -z '*.md'` parsed under `LC_ALL=C`.
- **Then**: The set difference is empty in both directions. (`comm -23` and `comm -13` both produce zero lines.) Evidence: the two commands' outputs pasted into `g-testing-exec.md` under `## AC1 Evidence`.

**TC-2: Closed-enum populated (AC2)**
- **Given**: Audit complete.
- **When**: Operator counts rows by `target-shape` value and computes the `other` percentage.
- **Then**: No row has any column = `unknown`; `other` rows ≤ 5% of total non-`parse-warning` rows. Evidence: counts pasted into `g-testing-exec.md`. If `other` exceeds 5%, the audit returns to b-requirements for enum extension before committing.

**TC-3: Rules table cardinality (AC3)**
- **Given**: `docs/conventions/cross-doc-references.md` exists with a rules table.
- **When**: Operator counts table rows and compares against the set of occurring locality cells in the audit.
- **Then**: Row count = occurring-cell count; no row text is "either is fine"; each row has a `rejected` column with at least one alternative or "N/A — no observed alternative".

**TC-4: Citation soundness (AC4)**
- **Given**: Style guide committed.
- **When**: `verify-cites.pl` is run.
- **Then**: Exit code 0. Every rule row has at least one `path:line` (or `path:line-range`) citation; every cited path exists and the line(s) are in bounds. Evidence: `verify-cites.pl` stdout/stderr pasted into `g-testing-exec.md`.

**TC-5: Divergence-count reproducibility (AC5)**
- **Given**: Audit and rule-decisions complete.
- **When**: Operator computes the count two ways: (a) `grep -c` rows with `matches-rule=false`; (b) by hand from the rule decisions section.
- **Then**: Both counts agree. If > 0, `BACKLOG.md` contains a new entry with `Identified in: Task 151 g-testing-exec.md` (or equivalent format match). If = 0, no entry exists.

**TC-6: Index entry format (AC6)**
- **Given**: `CLAUDE.md` updated.
- **When**: `grep -A 4 'cross-doc-references' CLAUDE.md`.
- **Then**: Output shows: bolded entry name, one-line summary ending with `for:`, ≥2 bulleted items immediately following. Entry sits between `**Git Path Handling**` and `**Tmp Paths**`.

**TC-7: External-evidence dogfooding (AC7)**
- **Given**: Style guide committed; rule decisions made.
- **When**: Operator examines the `## Dogfooding Result` section in `f-implementation-exec.md` (which lists `commit-messages.md` references vs the new rules).
- **Then**: Either "No mismatches" is recorded, or every mismatch is listed AND the BACKLOG migration entry's body includes the same list. No silent skips.

**TC-8: Low-divergence outcome (AC8)**
- **Given**: Rule decisions complete.
- **When**: Operator counts occurring locality cells.
- **Then**: If ≤ 2 cells occur, the style guide's `## Why` section explicitly contains the phrase "patterns already consistent" (or equivalent); the rules table is NOT padded with cells that don't occur. If > 2 cells, this TC is trivially satisfied.

### Non-Functional Test Cases

**TC-9: Determinism (NFR5)**
- **Given**: `audit.pl` has been run once and the output preserved.
- **When**: Operator runs `audit.pl` a second time with the same baseline commit, redirecting to a different temp file, then `diff` the two outputs (ignoring the `<!-- audit baseline: SHA -->` header which can vary if HEAD has moved).
- **Then**: Bodies are byte-identical. Diff output recorded in `g-testing-exec.md`.

**TC-10: Hardening — no shell interpolation surfaces (NFR4)**
- **Given**: `audit.pl` and `verify-cites.pl` sources pasted into wf step files.
- **When**: `grep -E 'qx\{|`\w' <audit.pl> <verify-cites.pl>`.
- **Then**: Zero matches. Any `git ...` or `wc ...` calls use list-form `open(... "-|", "git", ...)`.

**TC-11: Hardening — scratch directory permissions**
- **Given**: Operator commands log in `f-implementation-exec.md`.
- **When**: Search for the first reference to `/tmp/-home-matt-repo-coding-with-files-task-151/`.
- **Then**: The preceding command is `mkdir -m 0700 -p /tmp/-home-matt-repo-coding-with-files-task-151/`. The guard is not skipped.

**TC-12: Hardening — prompt-injection fences (NFR4)**
- **Given**: `f-implementation-exec.md` and (if filed) the BACKLOG migration entry.
- **When**: Locate every paste of audit-scraped text (audit appendix, dogfooding excerpt, migration body excerpts).
- **Then**: Each paste is inside a ` ```markdown ` fenced block, NOT inline prose. Verify by grep + visual inspection.

**TC-13: Self-compliance**
- **Given**: `docs/conventions/cross-doc-references.md` exists.
- **When**: Operator applies the audit's classification to this file specifically and compares each reference against the new rules.
- **Then**: All references in the doc match the rules. Mismatches in the doc itself are a hard failure — fix the doc and re-test (the doc must dogfood from the moment of commit, per b-requirements Constraints).

## Test Environment
### Setup Requirements
- Repo cloned at the baseline commit recorded in `a-task-plan.md:9` (`eecb9133b0f716932e57f3ae07cfec0d5822082e`).
- Working tree clean (`git status` empty) OR exactly the in-flight task-151 changes — `audit.pl` reads from the index, not the working tree, so working-tree edits to non-`.md` files don't affect output.
- `/tmp/-home-matt-repo-coding-with-files-task-151/` created with `mkdir -m 0700 -p` (mandatory guard).
- `LC_ALL=C` and `PERL5OPT=-CDSLA` exported in the shell that runs the audit and verifier.
- POSIX-only Perl (core modules only — verified by the audit script itself failing if any non-core module is used).

### Test Data
- The test corpus IS the repo's tracked `.md` files at the baseline commit. No synthetic fixtures.
- Optional unit-equivalent fixtures (a 10-line synthetic markdown snippet with one example of each delimiter × target-shape) are nice-to-have but not required — the corpus exercises the regex pipeline sufficiently.

### Automation
- All tests are operator-driven shell invocations recorded in `g-testing-exec.md`. No CI integration — this is a one-off discovery task.
- The verifier (`verify-cites.pl`) is the only test artefact retained for potential re-runs; it lives in `/tmp/` and is documented by being pasted into `g-testing-exec.md`.

## Validation Criteria
- [ ] All 13 TCs executed and outcome recorded in `g-testing-exec.md`.
- [ ] AC1-AC8 from b-requirements verified with cited evidence (TC-1 through TC-8 cover this).
- [ ] NFR4 hardening invariants verified (TC-10, TC-11, TC-12).
- [ ] NFR5 determinism verified (TC-9).
- [ ] Style guide self-compliance verified (TC-13).
- [ ] `verify-cites.pl` exits 0 against the committed style guide.
- [ ] No TC silently skipped or marked N/A without a one-line rationale.

## Decomposition Check
- [ ] **Time**: Test execution is ~half a day. No trigger.
- [ ] **People**: Single-person. No trigger.
- [ ] **Complexity**: 13 mechanical checks; each is a grep, count, or diff. No trigger.
- [ ] **Risk**: Test design risks are upstream (in c-design and d-plan), not in execution. No trigger.
- [ ] **Independence**: TCs are independent within a level but assume the artefacts exist. No trigger.

**Decomposition verdict**: 0/5 — no subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
