# Progress-signal inference conflict still present - Testing Execution
**Task**: 157 (discovery)

## Task Reference
- **Task ID**: internal-157
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/157-progress-signal-inference-conflict-still-present
- **Template Version**: 2.1

## Goal
Validate the discovery evidence captured in f-implementation-exec.md against the
e-testing-plan.md test cases (TC-1..TC-6 + NFRs), so the verdict (FR3) and
recommendation (FR4) — written up in j-retrospective.md — rest on checked
evidence, not assumption.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready (scratch fixture + probe from f phase)
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Finished" when all pass

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-1 | Trace citations current (re-read source) | Each FR1 hop resolves at a current file:line | All hops re-grepped in f phase; resolve | PASS | Stale "bell curve" comment at `TaskContextInference.pm:410`; misleading param `$percentage` at `:447`. Comment inside `_score_progress` (`:450-452`) is already accurate. No material drift. |
| TC-2 | Status map in force (guard) | Finished=100, Backlog=0, In Progress=25 | 100 / 0 / 25 | PASS | Defaults == real config for these keys; result config-source-independent |
| TC-3 | Fixtures parsed correctly (guard) | state_done: 201=100, 202=0, 203=25 | 100 / 0 / 25 | PASS | Proves no "Unknown" parse — `201` exclusion is via cliff, not a missing heading |
| TC-4 | Unit scores match matrix | 201→wp0/score0; 202→wp10/score6; 203→wp25/score15 | 0/0, 10/6, 25/15 | PASS | `_score_progress` receives post-cliff work potential, not raw completion |
| TC-5 | Finished task excluded from candidates (core) | `201` absent; top==203 (or 202 if 203 omitted) | candidates=[203:15, 202:6]; `201` absent; top=203 | PASS | The reported symptom does not reproduce |
| TC-6 | Falsifying condition addressed | `201` appearing as candidate/top would confirm premise; recorded as not occurring | `201` confirmed absent from candidate list; falsifying condition stated | PASS | Verdict rests on evidence: the premise-holding outcome was defined and did not occur |

### Non-Functional Tests
- **Reliability (NFR5)**: probe re-run a second time — output byte-identical to the first run (`diff` empty). Candidate list and `top` deterministic. **PASS**
- **Security/Integrity**: `git status -- .cwf/` shows no changes; no hash-tracked file modified. Read-only constraint upheld. **PASS**
- **Performance / Usability**: N/A (one-off discovery).

## Test Failures
None. All six functional test cases and both applicable NFR checks passed.

## Coverage Report
- Three of the four `state_achievable` branches the verdict touches are exercised by fixtures: CLIFF (`201`), FRESH (`202`), ACTIVE (`203`). The DORMANT branch (`int(completion*0.3)`) is not exercised — it is not load-bearing for the premise (a dormant task is non-finished, so it does not bear on whether a *finished* task can be a candidate). BLOCKED→0 is likewise out of scope.
- The falsifying condition (TC-6) is checked explicitly, not only the confirming one.

## Security Review

**State**: no findings

no findings: empty changeset

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
The reliability re-run and the parse-success guards turned a single observation into defensible evidence: the finished-task exclusion is deterministic and attributable to the cliff, not to a fixture artefact. See j-retrospective.md.
