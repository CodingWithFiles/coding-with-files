# Split workflow-steps into per-anchor docs - Testing Execution
**Task**: 176 (chore)

## Task Reference
- **Task ID**: internal-176
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/176-split-workflow-steps-into-per-anchor-docs
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Finished" when all pass

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | All 10 per-anchor files exist | 10 files in `workflow-steps/` | 10 files present | PASS |
| TC-2 | Content-preserving (no prose drift) | each body verbatim substring of baseline `91d0b4c` section | all 10 bodies verbatim | PASS |
| TC-3 | Each anchor doc has the up-link | exactly 1 `[Workflow Steps](../workflow-steps.md)` per file | 1 per file (all 10) | PASS |
| TC-4 | Skill references resolve, no `#` anchor | 8 targets exist on disk; 0 refs contain `#` | 8/8 resolve; 0 with `#` | PASS |
| TC-5 | No dangling phase-anchor refs repo-wide | 0 matches (excl. history + impl-guide) | 0 | PASS |
| TC-6 | status-values refs intact (D2) | 12 referrers + `#status-values` anchor present | 12 referrers; anchor present | PASS |
| TC-7 | ToC links complete and valid | 10 links, all resolve | 10/10 resolve | PASS |
| TC-8 | Regression — validate + integrity test | `cwf-manage validate` OK; `installmanifest-integrity.t` green | validate OK; 6/6 ok | PASS |

### Non-Functional Tests
- **Output-level check** (the core objective): opening any of the 8 skill targets (e.g. `workflow-steps/planning.md`) is a single `Read` that returns complete, self-contained phase guidance — no `sed`/`awk`, no `grep`+`Read` round-trip, no permission prompt, no over-read of unrelated phases. The `sed`-extraction failure mode that motivated the task is structurally eliminated.

## Test Failures
None. (During re-run an initial TC-2/TC-3 false-negative was traced to the content-checker reading `HEAD` — which is now the post-rewrite ToC — instead of the baseline commit `91d0b4c`. Pointing the checker at the baseline confirmed all 10 bodies are verbatim. Not a product defect; a verification-harness anchor fix.)

## Coverage Report
Every artefact the task ships is checked: 10 new files (existence + content + up-link), 8 changed skill references (resolution + no-anchor), the ToC rewrite (10 links), and the retained `#status-values` anchor with its 12 referrers. Regression covered by `cwf-manage validate` and `installmanifest-integrity.t`.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*

## Security Review

**State**: error

error: cap exceeded: 839 production lines > 500

Note: the cap fired because the cumulative changeset from the task baseline (`91d0b4c`) now includes the 10 new per-anchor doc files, whose markdown bodies count as production lines (`.cwf/docs/` is not in `security.review.max-lines-exclude-paths`). The substantive change surface — the doc split, the 8 skill-reference edits, and the ToC rewrite — was already reviewed in the implementation phase with a `no findings` verdict (see `f-implementation-exec.md`). The testing phase added no executable code, scripts, Perl, shell, or env-var handling; the only new content is more markdown documentation. No subagent was invoked, per the exit-2 contract.
