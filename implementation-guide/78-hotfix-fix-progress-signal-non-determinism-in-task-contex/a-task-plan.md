# Fix progress signal non-determinism in task-context-inference - Plan
**Task**: 78 (hotfix)

## Task Reference
- **Task ID**: internal-78
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/78-fix-progress-signal-non-determinism-in-task-contex
- **Template Version**: 2.1

## Goal
Filter zero-score candidates from the progress signal in `CWF::TaskContextInheritance`
so that completed tasks do not generate spurious non-deterministic inference candidates.

## Success Criteria
- [ ] `task-context-inference` returns `confidence: correlated` / `task_num: 78` consistently when on the task branch with no other signals
- [ ] Running the inference tool 5× in a row on any single-task branch produces identical output
- [ ] `prove t/` still passes after the fix
- [ ] `cwf-manage validate` still exits 0

## Original Estimate
**Effort**: <1 session (trivial one-line fix)
**Complexity**: Low
**Dependencies**: `CWF::TaskContextInheritance` module, `t/taskcontextinference.t`

## Major Milestones
1. **Fix**: Add `grep { $_->{score} > 0 }` filter in `_get_progress_signal`
2. **Test**: Verify determinism and add regression subtest to `t/taskcontextinference.t`
3. **Done**: Squash and ready to merge

## Risk Assessment
### Low Priority Risks
- **Filter removes valid in-progress candidates**: If all active tasks happen to have
  score 0 (unlikely — in-progress tasks have non-zero `state_achievable`), the signal
  becomes null even when it shouldn't.
  - **Mitigation**: The branch signal (weight 100) is the dominant signal; progress is
    secondary (weight 60). Null progress signal is safe when branch signal is present.

## Dependencies
- `.cwf/lib/CWF/TaskContextInheritance.pm` — single file change
- `t/taskcontextinference.t` — add regression test

## Constraints
- Fix must not change behaviour for tasks with genuinely in-progress workflow steps
- Must remain core-Perl-only (no CPAN)

## Decomposition Check
- [ ] **Time**: <1 session — no decomposition needed
- [ ] **People**: Single agent
- [ ] **Complexity**: Single concern (one signal, one filter line)
- [ ] **Risk**: Low — additive filter, no logic change for non-zero scores
- [ ] **Independence**: N/A

**Result**: 0 signals. No decomposition.

## Status
**Status**: Finished
**Next Action**: N/A — complete
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four success criteria met: `task-context-inference` returns `correlated /
task_num: 78` consistently; 5× consecutive runs identical; `prove t/` passes
(158 tests); `cwf-manage validate` exits 0. Completed in <1 session as estimated.

## Lessons Learned
When a root cause is fully diagnosed before a task starts, hotfix planning is
instantaneous and implementation is a single focused edit. The value of the CWF
workflow is the regression test and audit trail it forces, not the time it saves.
