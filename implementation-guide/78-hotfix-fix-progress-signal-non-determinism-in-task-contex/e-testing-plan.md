# Fix progress signal non-determinism in task-context-inference - Testing Plan
**Task**: 78 (hotfix)

## Task Reference
- **Task ID**: internal-78
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/78-fix-progress-signal-non-determinism-in-task-contex
- **Template Version**: 2.1

## Goal
Verify the `grep { $_->{score} > 0 }` filter eliminates non-determinism in
`_get_progress_signal` without breaking existing inference behaviour.

## Test Strategy

### Test Levels
- **Unit**: `prove t/` — new regression subtest in `t/taskcontextinference.t` plus
  all 157 existing tests must pass
- **System**: `task-context-inference` invoked 5× consecutively on the task 78 branch
  — all runs must produce identical `confidence: correlated, task_num: 78` output
- **Integrity**: `cwf-manage validate` must exit 0 (SHA256 updated if needed)

### Coverage Targets
- New subtest: `correlate_signals()` with all-zero-score progress signal → null signal
- All existing `t/taskcontextinference.t` subtests continue to pass

## Test Cases

### TC-1: Regression — zero-score progress candidates produce null signal
- **Given**: A synthesised signal set where the progress signal has candidates but
  all have `score == 0`, and a matching branch signal for a real task
- **When**: `CWF::TaskContextInference::correlate_signals()` is called
- **Then**: Output is `confidence: correlated` driven solely by the branch signal;
  the zero-score progress signal does not inject a different task as a candidate

### TC-2: Determinism check — 5 consecutive runs
- **Given**: On branch `hotfix/78-fix-progress-signal-non-determinism-in-task-contex`
  with no other signals except branch + progress
- **When**: `.cwf/scripts/command-helpers/task-context-inference` is run 5× in a row
- **Then**: All 5 outputs are byte-for-byte identical, each showing
  `confidence: correlated` and `task_num: 78`

### TC-3: Existing suite regression
- **Given**: The patched `TaskContextInference.pm`
- **When**: `prove t/` is run
- **Then**: All 158+ tests pass (157 existing + ≥1 new regression subtest)

### TC-4: Integrity check
- **Given**: `TaskContextInference.pm` has been modified
- **When**: `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` is run
- **Then**: Exits 0 — SHA256 in `script-hashes.json` was updated if the file is listed

## Non-Functional Tests

### Determinism (primary NFR)
Run `task-context-inference` back-to-back 10× and diff consecutive outputs —
zero diff lines expected.

### Performance
No performance concern — one `grep` on a list of ~50 items.

## Test Environment

- Perl 5 with `Test::More` (core)
- `prove t/` from repo root
- On task 78 branch (`hotfix/78-fix-progress-signal-non-determinism-in-task-contex`)
- No special env vars or setup required

## Validation Criteria
- [ ] TC-1 regression subtest added and passes
- [ ] TC-2 5× consecutive runs produce identical output
- [ ] TC-3 all 158+ tests pass (`prove t/` exits 0)
- [ ] TC-4 `cwf-manage validate` exits 0

## Status
**Status**: Finished
**Next Action**: N/A — complete
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
4/4 test cases passed. The regression subtest used `get_all_signals()` rather
than the planned `correlate_signals` mock — a stronger test that verifies the
grep filter at the actual emission point.

## Lessons Learned
For private-function fixes, testing via the nearest public function that exercises
the fix is more valuable than testing downstream consumers with synthetic data.
