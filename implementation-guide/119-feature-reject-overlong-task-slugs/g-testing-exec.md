# Reject overlong task slugs - Testing Execution
**Task**: 119 (feature)

## Task Reference
- **Task ID**: internal-119
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/119-reject-overlong-task-slugs
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md
- [x] Verify test environment ready (Perl + prove + sha256sum + git available)
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps (none)
- [x] Update status to "Finished" when all pass

## Test Results

### Functional — Unit (TC-1 through TC-8)
Run via `prove t/template-copier-slug-validation.t`. All 8 subtests pass.

| Test ID | Case | Expected | Actual | Status |
|---------|------|----------|--------|--------|
| TC-1  | Slug 49 chars accepted                 | no die                                            | no die                                       | PASS |
| TC-2  | Slug 50 chars accepted                 | no die                                            | no die                                       | PASS |
| TC-3  | Slug 51 chars rejected                 | die `/Task slug '.+' is 51 chars; limit is 50/`   | matches; recovery hint mentions "briefer"    | PASS |
| TC-4  | 100-char description rejected          | die with length in message                        | die; "100 characters; limit is 50"           | PASS |
| TC-5  | "!!!" → empty slug rejected            | die `/empty slug/i`; original description echoed  | matches both                                 | PASS |
| TC-6  | "---valid-content---" → "valid-content"| no die; slug == "valid-content"                   | matches                                      | PASS |
| TC-7  | Error message contents                 | `[CWF] ERROR:`, length 60, limit 50, recovery hint| all four assertions hold                     | PASS |
| TC-8  | Atomicity — no fs writes on rejection  | tempdir unchanged after eval                      | unchanged                                    | PASS |

### Functional — Integration (TC-9, TC-10)

**TC-9 — Direct script invocation, overlong description.** PASS.
- Command: `template-copier-v2.1 --task-type=feature --task-num=999 --description="$(perl -e 'print "long-" x 20')"` in scratch tmpdir.
- Exit: 1.
- STDERR: `[CWF] ERROR: Task slug 'long-long-...-long' is 99 characters; limit is 50. Use a briefer task description (try fewer or shorter words).`
- Filesystem: scratch tmpdir empty after run.

**TC-10 — Direct script invocation, valid description (happy path).** PASS.
- Command: `template-copier-v2.1 --task-type=chore --task-num=999 --description="short test"` in a configured scratch repo (with `.cwf/`, `cwf-project.json` copied in).
- Exit: 0.
- STDOUT: lists 6 files copied to `implementation-guide/999-chore-short-test`.
- Directory created with all 6 chore-task templates.

### Functional — System / End-to-end (TC-11, TC-12)
Both executed via `task-workflow create` (the dispatcher the skill uses) in a freshly-initialised scratch repo. This exercises the full skill→script wiring without involving the LLM harness.

**TC-11 — End-to-end with overlong description.** PASS.
- Command: `task-workflow create --task-type=chore --task-num=999 --description="this description is deliberately way too long for a slug and should be rejected outright"`.
- Exit: 1.
- STDERR: `[CWF] ERROR: Task slug 'this-description-...-rejected-outright' is 88 characters; limit is 50. Use a briefer task description (try fewer or shorter words).`
- Filesystem: only the pre-seeded `cwf-project.json` remains under `implementation-guide/`; no `999-...` directory created.

**TC-12 — End-to-end with valid description (regression).** PASS.
- Command: `task-workflow create --task-type=chore --task-num=999 --description="short test task"`.
- Exit: 0.
- Directory `implementation-guide/999-chore-short-test-task/` created with the 6 chore-task templates.
- Cleanup: scratch repo wiped after test.

### Functional — FR3 / FR4 / FR5 (TC-13, TC-14, TC-15)

**TC-13 — `SLUG_MAX_LEN` single source of truth.** PASS.
```
.cwf/scripts/command-helpers/template-copier-v2.1:45:use constant SLUG_MAX_LEN => 50;
.cwf/scripts/command-helpers/template-copier-v2.1:97:    if ($slug_len > SLUG_MAX_LEN) {
.cwf/scripts/command-helpers/template-copier-v2.1:98:        my $limit = SLUG_MAX_LEN;
```
One declaration; two usages within the same file. No other source declares the constant.

**TC-14 — SKILL.md no longer instructs LLM to truncate.** PASS.
- `grep -E "truncate.*50|truncate 50 chars" .claude/skills/cwf-new-task/ .claude/skills/cwf-new-subtask/ -r` returns zero matches (exit 1).

**TC-15 — Existing tasks with truncated slugs still operable.** PASS.
- `status-aggregator-v2.1 100` → `* 100 (discovery): identify-deterministic-operations-still-handled-by-agent - 100%` (slug 56 chars).
- `status-aggregator-v2.1 115` → `* 115 (bugfix): honour-cwf-source-env-var-in-cwf-manage-update - 100%` (slug 49 chars).
- No validation error fired against pre-existing directories. (FR5 / AC5.2: validation only triggers in `parse_parameters` of `template-copier-v2.1`, which runs at task-creation time, never against on-disk dirs.)

### Non-Functional Tests
- **NFR-1 Atomicity**: covered by TC-8 (unit) and TC-9/TC-11 (integration/system) — rejection leaves no filesystem state. PASS.
- **NFR-2 Usability**: covered by TC-7 — error contains the offending slug, actual length, the limit, recovery hint, and `[CWF] ERROR:` prefix. PASS.
- **NFR-3 Testability**: 8 unit tests run via `*main::die_msg` symbol-table override + `eval{}` catch (Tasks 115/116 pattern). PASS.
- **NFR-4 Determinism**: same description always yields same outcome — covered by all unit tests passing repeatedly.
- **NFR-5 Exit code**: TC-9 / TC-11 both exit 1. PASS.
- **Performance / Security**: N/A.

### Regression (TC-16, TC-17)

**TC-16 — Full test suite.** PASS.
- `prove t/` reports `Files=26, Tests=246, Result: PASS`.
- Baseline before this task was 238 (per Task 116 CHANGELOG). Delta: +8 — exactly the new file's subtests.

**TC-17 — `cwf-manage validate`.** PASS.
- Reports `[CWF] validate: OK` after the hash refresh in `.cwf/security/script-hashes.json`.

## Test Failures
None.

## Coverage Report
- All 17 test cases from e-testing-plan.md executed: 17 PASS / 0 FAIL.
- All 5 FRs covered: FR1 (TC-3, TC-4, TC-9, TC-11), FR2 (TC-7), FR3 (TC-13), FR4 (TC-14), FR5 (TC-15).
- All NFRs covered: NFR1–NFR5 above.

## Validation Criteria
- [x] All 17 test cases pass
- [x] `prove t/` shows no new failures vs baseline (246 = 238 + 8)
- [x] `cwf-manage validate` returns `OK`
- [x] Manual smoke test (TC-11) shows the `[CWF] ERROR:` message with no filesystem state
- [x] FR3 grep test (TC-13) returns exactly one declaration of `SLUG_MAX_LEN`

## Status
**Status**: Finished
**Next Action**: /cwf-rollout 119
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
See j-retrospective.md.
