# Template Reference Linter for Pre-Commit Hook - Testing Execution
**Task**: 165 (chore)

## Task Reference
- **Task ID**: internal-165
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/165-template-reference-linter-for-pre-commit-hook
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [ ] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [ ] Verify test environment ready
- [ ] Execute test cases sequentially
- [ ] Record pass/fail for each test
- [ ] Document failures with reproduction steps
- [ ] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

Runner: `prove t/validate-template-refs.t` → 10/10 subtests pass. Full suite `prove t/` → 52 files, 610 tests, all pass (no regressions).

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1  | All-known references | 0 violations | 0 | PASS |
| TC-2  | Genuine orphan `a-bogus.md` | 1 violation, file/line/token captured | 1 (`doc.md`, `line 2`, `a-bogus.md`) | PASS |
| TC-3  | Back-compat name `a-plan.md` (v2.0) | 0 violations | 0 | PASS |
| TC-4  | Substring decoys (`retrospective-extras.md`, `cwf-plan-reviewer-misalignment.md`) | 0 violations | 0 | PASS |
| TC-5  | Compound `f-implementation-exec-audit.md` | 1 violation, whole token | 1 (whole token) | PASS |
| TC-6  | BACKLOG/CHANGELOG excluded, in-scope flagged | 1 violation (`src.md` only) | 1 (`src.md`) | PASS |
| TC-6b | `implementation-guide/` excluded | 0 violations | 0 | PASS |
| TC-7  | Real repo clean at HEAD | 0 violations | 0 | PASS |

### Non-Functional Tests
- **Reliability (fail-closed)**: `_known_names($repo)` carries the asserted minimum (`a-task-plan.md`, `f-implementation-exec.md`, `e-testing.md`) and ≥15 names spanning versions — PASS. The `die` guard refuses to run on an under-populated set.
- **Conventions**: `t/validate-perl-conventions.t` passes over the new module (`use utf8;`, `git ls-files -z`) — PASS.
- **Integrity**: `cwf-manage validate` → OK (hashes for new/edited files correct; new check registered and self-scans clean) — PASS.

## Test Failures

None.

## Coverage Report

All e-testing-plan.md test cases (TC-1…TC-7 + fail-closed) executed and passing. Critical paths (KNOWN derivation, anchored classification, scope exclusions) and edge cases (substring/compound decoys, history-file exclusion) covered.

## Security Review

**State**: no findings

## Security review — Task 165, testing phase

Reviewed the testing-phase changeset (linter module, test, cwf-manage wiring, V21.pm POD fix), weighting test-file safety.

- **(a) Bash injection**: module's git spawn and the test's `git init`/`git add` are all list-form — args reach execvp directly, no shell. Clean.
- **(b) Git output without -z**: `ls-files -z` + `local $/="\0"` + chomp + skip-empty; `_slurp` `<:raw`; read-only, `$rel` from ls-files only. Clean.
- **(c) Prompt injection**: deterministic linter, output to terminal not LLM context. N/A.
- **(d) Env vars**: none read. Clean.
- **(e) Patterns**: test-side `git -C $root` safe (list-form, File::Temp path); fail-closed `die` is the correct fail-loud posture — audit future edits relaxing it to `warn`.

Test-specific: `tempdir(CLEANUP=>1)` isolation, no production-repo mutation (real-repo calls read-only), no git identity required. Interface cross-check of V21/V20/migration APIs confirmed; fail-closed sentinels genuinely producible. No actionable security concerns.

```cwf-review
state: no findings
summary: List-form -z git invocation, read-only linter (no env vars, no LLM-bound output), temp-dir-isolated tests that never mutate the production repo, and a correct fail-closed die; two pattern-based notes are safe-here.
```

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
