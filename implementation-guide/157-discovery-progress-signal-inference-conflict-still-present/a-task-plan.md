# Progress-signal inference conflict still present - Plan
**Task**: 157 (discovery)

## Task Reference
- **Task ID**: internal-157
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/157-progress-signal-inference-conflict-still-present
- **Baseline Commit**: 7a6191a14024c512bfc947ceda45d9bfa67a83e1
- **Template Version**: 2.1

## Goal
Determine whether the progress signal can still cause a spurious inconclusive
task-context inference for a correctly-finished task, and decide whether the
"Progress Signal Scores Completed Tasks Highest" backlog item should be retired
or rescoped to a clarity-only fix.

## Background
The backlog item (filed as a `bugfix`, Medium) claims `_score_progress` in
`.cwf/lib/CWF/TaskContextInference.pm` gives a 100%-complete task the maximum
score (60), so finished tasks dominate the progress signal and cause
inconclusive results — observed once in the Task 104 session (103 Finished vs
104 just-started).

A code trace during planning suggests this premise is a misread:
- `_score_progress`'s input is **not** raw completion. `_get_progress_signal`
  feeds it `_calculate_task_progress`, which uses `CWF::TaskState::state_achievable`.
- `state_achievable` applies a **cliff**: completion ≥ 100% → work potential 0
  (`.cwf/lib/CWF/TaskState.pm:150`).
- `_get_progress_signal` then drops zero-score candidates
  (`TaskContextInference.pm:418`).
- So a correctly-finished task arrives as 0 and is filtered out — it cannot be
  the progress signal's `top`, cannot dissent, cannot trigger an inconclusive.

The misleading parameter name `$percentage` (it actually carries post-cliff
work potential) and a stale comment ("bell curve, peak at 50%") are what make
the function read like a bug in isolation. This is the discovery to confirm the
trace empirically and settle the backlog item's fate.

## Purpose of the system (alignment)
Task-context inference is a "where am I?" oracle with two purposes: (1) remind an
agent which task it should be working on, and (2) surface when a *previous* task
was left in an incorrect state. Correlation is unanimity-based — conclusive only
when every non-null signal agrees — so an `inconclusive` result is **diagnostic,
not merely an abstention**. A correctly-finished task can never read as ongoing
work (the cliff guarantees it); conversely, if a "finished" task *does* surface
as a candidate, it is not correctly finished, and the dissent is the alarm
working as intended.

## Success Criteria
- [ ] Code trace confirmed end-to-end (cliff + zero-filter) that a correctly-finished task — all steps terminal, computed completion 100% — cannot be a progress-signal candidate
- [ ] Empirically verified with a fixture (one finished task + one active task) that the progress signal excludes the finished task and inference is not driven inconclusive by it
- [ ] Backlog premise classified as holds / misread, with the specific reason recorded
- [ ] Recommendation recorded — retire the backlog item, or rescope to a clarity chore (rename `$percentage` → work-potential, delete the stale bell-curve comment) — with rationale and any follow-up backlog action

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None (read-only investigation of `TaskContextInference.pm` and `TaskState.pm`)

## Major Milestones
1. **Trace confirmed**: cliff path `state_achievable` → `_calculate_task_progress` → `_score_progress` → zero-filter verified to exclude correctly-finished tasks
2. **Empirical check**: fixture-based observation of progress-signal candidates and inference output for a mixed finished/active task set; review whether genuine inconclusive cases have occurred in practice
3. **Decision recorded**: retire vs rescope, captured for retrospective and backlog action

## Risk Assessment
### Medium Priority Risks
- **Premise partially true at a boundary**: an edge case (e.g. dormant-task dampening, or a task at exactly 100% via a path that bypasses the cliff) could let a finished task score > 0.
  - **Mitigation**: drive the fixture through `_get_progress_signal`/`state_achievable` directly rather than reasoning only from the source.
- **Label vs computed-completion mismatch is common**: tasks marked "Finished" but with a non-terminal step compute < 100% and stay live.
  - **Mitigation**: treat this as the intended diagnostic (purpose #2), document it, do not propose suppressing it.

### Low Priority Risks
- **Scope creep into "improve inference"**: temptation to retune signals or weights.
  - **Mitigation**: keep this discovery bounded to the specific backlog claim; defer any broader change to a separate backlog item.

## Dependencies
- None external. Investigation reads `.cwf/lib/CWF/TaskContextInference.pm` and `.cwf/lib/CWF/TaskState.pm`.

## Constraints
- Discovery task: produces a finding and a recommendation, not a behaviour change. Any code edit that follows (rename/comment removal) is a separate decision; if undertaken, `TaskContextInference.pm` is hash-tracked and requires a `script-hashes.json` refresh in the same commit (hash-updates convention).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No
- [ ] **People**: Does this need >2 people? No
- [ ] **Complexity**: 3+ distinct concerns? No — single, narrowly-scoped question
- [ ] **Risk**: High-risk components needing isolation? No
- [ ] **Independence**: Can parts be worked on separately? No

No decomposition signals triggered — single-session discovery.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four success criteria met in a single session, on estimate: trace confirmed (FR1), empirical exclusion verified via probe (FR2), premise classified as a misread (FR3), recommendation recorded — retire + Low clarity chore (FR4). See j-retrospective.md.

## Lessons Learned
The purpose-of-system framing (an `inconclusive` result is diagnostic; a correctly-finished task cannot read as live work) was the load-bearing insight that prevented proposing a wrong "fix". See j-retrospective.md §Key Learnings.
