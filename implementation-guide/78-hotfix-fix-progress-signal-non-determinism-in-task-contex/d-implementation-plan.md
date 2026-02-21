# Fix progress signal non-determinism in task-context-inference - Implementation Plan
**Task**: 78 (hotfix)

## Task Reference
- **Task ID**: internal-78
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/78-fix-progress-signal-non-determinism-in-task-contex
- **Template Version**: 2.1

## Goal
Filter zero-score candidates from the progress signal so completed tasks no longer
produce spurious non-deterministic inference candidates.

## Files to Modify

### Primary Changes
- `.cwf/lib/CWF/TaskContextInference.pm` — add one `grep` line in `_get_progress_signal`

### Supporting Changes
- `t/taskcontextinference.t` — add regression subtest for zero-score filtering

## Implementation Steps

### Step 1: Fix `_get_progress_signal` in TaskContextInference.pm
- [ ] Locate the sort+splice block in `_get_progress_signal` (lines ~416–420)
- [ ] Add `@candidates = grep { $_->{score} > 0 } @candidates;` after sort, before splice
- [ ] Confirm the `unless @candidates` null-return guard already follows — no other change needed

### Step 2: Update SHA256 hash in script-hashes.json
- [ ] Check whether `TaskContextInference.pm` is listed in `.cwf/security/script-hashes.json`
- [ ] If listed, update its SHA256 after the edit; if not listed, skip

### Step 3: Add regression subtest to t/taskcontextinference.t
- [ ] Add subtest: `correlate_signals() - all-zero progress candidates → null signal`
  - Build a fake progress signal where all candidates have score 0
  - Verify that when mixed with a non-null branch signal they correlate (i.e., the zero-score signal doesn't introduce noise)
  - Actually this is better tested at the `_get_progress_signal` level, but that's a private function. Test via `correlate_signals` with a synthesised all-null signal set plus a single branch signal → should produce `correlated`.

### Step 4: Verify
- [ ] Run `prove t/` — all 157+ tests pass
- [ ] Run `perl -I.cwf/lib .cwf/scripts/cwf-manage validate`
- [ ] Run `.cwf/scripts/command-helpers/task-context-inference` 5× — consistent `correlated` output

## Code Change

### Before (lines ~416–420 of TaskContextInference.pm)
```perl
@candidates = sort { $b->{score} <=> $a->{score} } @candidates;
@candidates = splice(@candidates, 0, 5);

return { name => 'progress', weight => WEIGHT_PROGRESS_MAX, null => 1 }
    unless @candidates;
```

### After
```perl
@candidates = sort { $b->{score} <=> $a->{score} } @candidates;
@candidates = grep { $_->{score} > 0 } @candidates;
@candidates = splice(@candidates, 0, 5);

return { name => 'progress', weight => WEIGHT_PROGRESS_MAX, null => 1 }
    unless @candidates;
```

The `grep` must come after `sort` (so we discard from a sorted list) and before `splice`
(so the top-5 cap applies to meaningful candidates only).

## Test Coverage
- Regression: `t/taskcontextinference.t` — new subtest verifying zero-score signal is null
- Existing: all 157 tests must continue to pass

## Validation Criteria
- `task-context-inference` produces `confidence: correlated, task_num: 78` on 5 consecutive runs
- `prove t/` exits 0
- `cwf-manage validate` exits 0

## Status
**Status**: Finished
**Next Action**: N/A — complete
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four steps executed as planned. The grep line was added at line 418 of
TaskContextInference.pm. SHA256 updated. Regression subtest added via
`get_all_signals()` (more direct than the planned `correlate_signals` mock approach).

## Lessons Learned
Two nearly-identical sort+splice blocks in the same file require extra surrounding
context to uniquely identify the edit target. Always include the nearby distinctive
variable names when using the Edit tool on such files.
