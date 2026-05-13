# Delete most-recent task only - Plan
**Task**: 136 (feature)

## Task Reference
- **Task ID**: internal-136
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/136-delete-most-recent-task-only
- **Baseline Commit**: 599d54590440ac46da7385a47f3956fb328b0eed
- **Template Version**: 2.1

## Goal
Provide a safe, single-shot way to undo a freshly-created task — reversing `/cwf-new-task` — restricted to the most-recent task so no renumbering, gap-filling, or task re-stacking is ever required.

## Success Criteria
- [ ] A user-invocable command exists that deletes the most-recent task and only the most-recent task
- [ ] Deletion reverses everything `/cwf-new-task` created: task directory, task branch, checkpoints branch (if any), task-stack entry (if topmost)
- [ ] Command refuses with a clear, specific error when the target is not the most-recent task (e.g., a lower-numbered sibling, or a parent with surviving subtasks)
- [ ] Command refuses when the target task's squash commit is already on main (already "Finished")
- [ ] Command refuses when the task has uncommitted local work that would be silently lost, unless explicitly forced
- [ ] Tests cover both the happy path and every refusal case

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Low (small surface, but refusal-case enumeration drives the design)
**Dependencies**: None — touches only existing wf-management scripts and skills

## Major Milestones
1. **Define "most-recent"**: Precise rule covering flat tasks, parents with subtasks, and leaf subtasks (design phase)
2. **Helper script**: `task-workflow delete` (or similar) implementing the refusal checks and the reverse-of-create cleanup
3. **Skill wrapper**: `/cwf-delete-task` thin skill that calls the helper and reports outcome
4. **Test coverage**: Happy path + every refusal path

## Risk Assessment
### High Priority Risks
- **Risk 1**: Silent loss of unmerged work if the deleted task's branch holds commits the user wanted to keep
  - **Mitigation**: Refuse by default if the task branch is ahead of its baseline; require an explicit `--force` flag with a clear warning
- **Risk 2**: Ambiguity over what "most recent" means when subtasks exist (e.g. is 100 deletable when 100.1 exists?)
  - **Mitigation**: Resolve in design phase with explicit rules; refuse parent deletion while subtasks survive

### Medium Priority Risks
- **Risk 3**: User assumes deletion also rewrites BACKLOG/CHANGELOG history (it must not — those are records of project history)
  - **Mitigation**: Document scope explicitly: deletion is for tasks that were *never finished*; finished tasks are immutable history
- **Risk 4**: Task-stack corruption if deletion races with `/cwf-current-task`
  - **Mitigation**: Use the same `flock`-based stack operations the existing skill already uses; do not hand-edit the stack file

## Dependencies
- Existing `task-workflow` helper script (the create command lives here — delete is its inverse)
- Existing `.cwf/task-stack` locking convention
- Existing branch-naming convention (`<type>/<num>-<slug>` and `…-checkpoints`)

## Constraints
- Must never modify main, even via reflog-visible side-effects
- Must never touch BACKLOG.md or CHANGELOG.md (finished-task history is immutable)
- Must never renumber any other task (the whole point of the most-recent constraint)
- Must work for both flat tasks and leaf subtasks

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — 1-2 days
- [ ] **People**: Does this need >2 people working on different parts? No
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — single concern (reverse-of-create with refusal logic)
- [ ] **Risk**: Are there high-risk components that need isolation? No — refusal logic prevents the risky cases
- [ ] **Independence**: Can parts be worked on separately? No — script and skill are tightly coupled

No decomposition warranted.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Goal achieved as planned: `/cwf-delete-task` exists, deletes only the most-recent task, refuses every enumerated case, and reverses everything `/cwf-new-task` creates. All 6 success-criteria items met. Effort landed at the optimistic end (1 day vs 1-2 day estimate). No decomposition required.

## Lessons Learned
The "most-recent-only" constraint paid off doubly: it eliminated renumbering complexity *and* it gave the design phase a single obvious axis to enumerate refusal cases along (sibling-version-compare, child-exists, stack-topmost, branch-merged-to-main). Tight scope = clean implementation.
