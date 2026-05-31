# exclude-completed-tasks-from-recency - Plan
**Task**: 171 (bugfix)

## Task Reference
- **Task ID**: internal-171
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/171-exclude-completed-tasks-from-recency
- **Baseline Commit**: 6df7b70f062bbd019b2e82e04ef6300a7b0ee6c9
- **Template Version**: 2.1

## Goal
Make the `recency` task-candidate signal in `CWF::TaskContextInference` pass its
candidates through the existing `state_achievable` work-potential gate, so
completed tasks (zero work left) can no longer be nominated as the current task.

## Success Criteria
- [ ] `_get_recency_signal` excludes any task with zero work potential (`state_achievable($dir) == 0`), reusing `CWF::TaskState` rather than a bespoke completion check
- [ ] On the reported scenario (one active task on a matching branch, several recently-touched 100%-complete tasks), inference returns `correlated`/`conclusive` on the active task instead of `uncorrelated`/`candidates: 2`
- [ ] `recency` and `progress` now apply the same work-potential gate (no divergent notion of "done")
- [ ] Existing TaskContextInference test suite passes; a new regression test covers the recently-touched-completed-task case
- [ ] `.cwf/security/script-hashes.json` refreshed in the same commit for any hashed file edited

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: `CWF::TaskState::state_achievable` (already imported transitively via `_calculate_task_progress`)

## Major Milestones
1. **Design**: Confirm the gate point and decide minimal in-place guard vs. shared "live tasks" enumeration helper
2. **Fix**: Apply the work-potential gate to the recency candidate set
3. **Verify**: Regression test reproducing the completed-task-recency leak, full suite green, hash refresh

## Risk Assessment
### Medium Priority Risks
- **Risk**: Over-filtering — `state_achievable` returns 0 both at the 100% cliff *and* when a task has no statuses at all (`TaskState.pm:143`). Excluding the latter from recency could hide a genuinely-fresh task that was just created.
  - **Mitigation**: A fresh task scores 10 (not 0) once it has any status; a dir with no statuses has no workflow signal anyway. Design phase confirms `== 0` is the correct predicate and the testing phase covers the fresh-task boundary.

### Low Priority Risks
- **Risk**: Hash-tracked file (`TaskContextInference.pm`) edited without same-commit `script-hashes.json` refresh, breaking `cwf-manage validate`.
  - **Mitigation**: Follow the hash-updates convention; refresh in the same commit (flagged in success criteria).

## Dependencies
- None external. Self-contained within `.cwf/lib/CWF/`.

## Constraints
- Perl core modules only; `use utf8;`; POSIX portability.
- No behaviour change to the `progress` signal — it already gates correctly.
- Correlation algorithm (D3 decision tree) stays as-is; this fix only cleans the recency candidate set feeding it.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? **No** — single-function change.
- [x] **People**: Does this need >2 people working on different parts? **No**.
- [x] **Complexity**: Does this involve 3+ distinct concerns? **No** — one signal, one gate.
- [x] **Risk**: Are there high-risk components that need isolation? **No**.
- [x] **Independence**: Can parts be worked on separately? **No**.

No decomposition signals triggered → single task.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered as planned (single guard, regression test, same-commit hash refresh).
The one refinement: the design phase replaced this plan's `state_achievable == 0`
predicate with `state_done >= 100` (see c-design-plan.md Decision 2) — the
authoritative predicate. See j-retrospective.md.

## Lessons Learned
The "Over-filtering" medium risk was the crux: it materialised in design analysis
and was mitigated by the predicate switch plus the TC-10 boundary test, exactly
as the risk's mitigation line anticipated.
