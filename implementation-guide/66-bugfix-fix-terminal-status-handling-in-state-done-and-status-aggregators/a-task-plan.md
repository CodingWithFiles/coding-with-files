# Fix terminal status handling in state_done and status aggregators - Plan
**Task**: 66 (bugfix)

## Task Reference
- **Task ID**: internal-66
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/66-fix-terminal-status-handling-in-state-done-and-status-aggregators
- **Template Version**: 2.1

## Goal
Define a canonical list of terminal states in `CWF::TaskState` and fix `state_done` (and v2.0 equivalents) so that tasks whose workflow files are all in terminal states score 100% rather than 0%.

## Background
`Cancelled => 0` in the `%STATUS_PERCENT` map causes the MIN bottleneck formula to score all-Cancelled tasks as 0%. Terminal states (`Finished`, `Cancelled`, `Skipped`) all mean "this step is definitively closed" — they should not act as bottlenecks. The MIN formula is designed to find the slowest active step; closed steps should be excluded from or treated as satisfied by that calculation.

Discovered via: task 11 (all `Cancelled`) showing 0% in status-aggregator.

## Success Criteria
- [ ] Task 11 (all `Cancelled`) shows 100% in both v2.0 and v2.1 status-aggregators
- [ ] Tasks with all `Skipped` files show 100%
- [ ] Tasks with mixed `Finished`/`Cancelled`/`Skipped` files show 100%
- [ ] Active tasks (mix of in-progress and finished steps) still score correctly — no regression
- [ ] `CWF::TaskState` exports a canonical `@TERMINAL_STATES` or equivalent for reuse

## Original Estimate
**Effort**: <1 session
**Complexity**: Low
**Dependencies**: `CWF::TaskState`, `status-aggregator-v2.1`, `status-aggregator-v2.0`

## Major Milestones
1. **Understand scope**: Confirm which aggregator versions and modules need changing
2. **Fix `CWF::TaskState`**: Add terminal state concept, update `state_done` logic
3. **Fix v2.0 aggregator**: Apply equivalent fix if it has its own scoring logic
4. **Verify**: Task 11 scores 100%, no regressions on active tasks

## Risk Assessment
### Medium Priority Risks
- **Regression in mixed-state tasks**: If a task has some `Cancelled` and some `In Progress` steps, the intent is ambiguous — the `In Progress` steps should still dominate scoring.
  - **Mitigation**: Define rule clearly: terminal non-`Finished` states are excluded from MIN calculation (treated as satisfied), active steps still govern score.
- **v2.0 aggregator has separate scoring logic**: May not share `CWF::TaskState` at all.
  - **Mitigation**: Read v2.0 aggregator source before implementing; apply equivalent fix directly if needed.

## Dependencies
- `CWF::TaskState.pm` — primary fix location
- `status-aggregator-v2.1` — uses `CWF::TaskState`
- `status-aggregator-v2.0` — may have independent scoring

## Constraints
- Do not change what `Cancelled => 0` means in the raw `%STATUS_PERCENT` map — other callers may rely on it. Fix `state_done` logic instead.
- Fix must cover both aggregator versions as they are both in active use (task 11 is v2.0)

## Decomposition Check
- [ ] **Time**: Will this take >1 week? — No
- [ ] **People**: Does this need >2 people? — No
- [ ] **Complexity**: 3+ distinct concerns? — No (single logical fix, two aggregator versions)
- [ ] **Risk**: High-risk components needing isolation? — No
- [ ] **Independence**: Can parts be worked on separately? — No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 66
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
