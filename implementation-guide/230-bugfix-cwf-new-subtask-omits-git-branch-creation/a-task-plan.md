# cwf-new-subtask omits git branch creation - Plan
**Task**: 230 (bugfix)

## Task Reference
- **Task ID**: internal-230
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/230-cwf-new-subtask-omits-git-branch-creation
- **Baseline Commit**: cfd304805c4e76bb7a7f707bef11bfa641674ff7
- **Template Version**: 2.1

## Goal
Make `cwf-new-subtask` create the per-subtask git branch, matching `cwf-new-task`.

**Why (intent):** The `cwf-new-subtask` skill never creates a git branch, so subtask
work silently accumulates on the parent task's branch. The rest of the workflow already
assumes a subtask lives on its own branch: the retrospective's "Suggest Merge"
(`.cwf/docs/skills/retrospective-extras.md:147-155`) computes a current-task branch
`<type>/<num>-<slug>` and ff-merges it into the parent branch — a branch `cwf-new-subtask`
never created. The omission is original (present since the skill was first added as
`.claude/commands/cig-subtask.md` in `604201d`, 2025-08-23) and was later blessed as
intentional in prose by Task 203 (`186d539`). Bring the skill into line with the workflow's
existing assumption and with `cwf-new-task`.

**Explicit request:** "create a task to fix these" — the two identified defects:
(a) `cwf-new-subtask` omits the `git checkout -b` step that `cwf-new-task` performs;
(b) the `SKILL.md:102-103` prose ("There is **no `git checkout -b`** in this skill — the
subtask stays on the parent branch") that blessed the omission as intentional.

<!-- The goal is owner-owned. Do not unilaterally narrow or widen it. Surface any
     scope change (either direction) or goal/why tension to the owner as a decision. -->

## Success Criteria
<!-- Criteria must be outcome-shaped (observable results), never named after a
     not-yet-chosen mechanism. See `planning.md`, "Open-decisions gate & outcome-shaped
     criteria", for the definition and worked examples. -->
- [ ] After creating a subtask, the user is left on a new subtask-specific branch, not on the parent task's branch.
- [ ] The created subtask branch's name is exactly the one the retrospective's merge-suggestion computes for that subtask, so the subtask's ff-merge target resolves without manual correction.
- [ ] A freshly created subtask can be ff-merged into its parent branch end-to-end (parent branch is an ancestor of the subtask branch).
- [ ] The skill text no longer states that a subtask stays on the parent branch, and every remaining step/failure-path instruction reads consistently with a branch being created.

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None external

## Major Milestones
1. **Confirm the defect**: Show that creating a subtask leaves you on the parent branch and that the retrospective's merge suggestion references a branch that was never created.
2. **Fix the skill**: Add the branch-creation step to `cwf-new-subtask/SKILL.md`, correct the erroneous prose, renumber the steps, and update the skill's own success criteria.
3. **Verify end-to-end + guard regression**: Round-trip create→branch→ff-merge-to-parent, and settle how this class of drift is caught in future.

## Risk Assessment
### High Priority Risks
- **Risk 1**: The branch name or base diverges from what `cwf-new-task` and the retrospective expect, so the subtask's ff-merge silently targets the wrong ref.
  - **Mitigation**: Derive the name from the same `<type>/<num>-<slug>` pattern used by `cwf-new-task` (step 4) and `retrospective-extras.md:147`; branch off current HEAD (the parent branch); test the create→merge round-trip rather than eyeballing the string.

### Medium Priority Risks
- **Risk 2**: Skill files are LLM-executed prose with no automated test, which is exactly why this bug survived undetected from Task 57 to now — a fix without a guard can silently regress again.
  - **Mitigation**: Treat "how do we catch this class of drift" as an open decision (see Open Decisions); at minimum add a repeatable smoke-test to the testing phase.
- **Risk 3**: Subtasks already created under the old behaviour sit on their parent branches; the fix is forward-only and does not retro-fit them.
  - **Mitigation**: State the forward-only scope explicitly; surface any stranded in-flight subtask to the owner rather than silently rewriting history.

## Dependencies
- The `<type>/<num>-<slug>` branch-naming pattern already established by `cwf-new-task` and consumed by `.cwf/docs/skills/retrospective-extras.md`.

## Constraints
- `SKILL.md` is instruction prose executed by the LLM, not compiled code — "tests" here are reproducible smoke-tests, not unit tests.
- Fix stays within the `cwf-new-subtask` skill; the retrospective and other consumers already assume the correct behaviour and must not be changed to accommodate the bug.

## Open Decisions
List every surface/mechanism/constraint choice not yet made (transport, storage, layout,
licensing-class, …), each as a question to resolve in requirements/design. Naming ≠ choosing.
- Branch-creation failure semantics: is a failed `git checkout -b` (e.g. the branch already exists) fatal for subtask creation — mirroring `cwf-new-task`'s implicit treatment — or non-fatal like the scratch-dir `mkdir`?
- Regression-guard mechanism: do we add an automated check that both task-creation skills contain a branch-creation step, or rely solely on the retrospective round-trip smoke-test?
- DRY vs duplication: is the branch-creation instruction shared from a single source across both skills (per design-alignment), or duplicated in each with a cross-reference?

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? If yes, consider decomposition
- [ ] **People**: Does this need >2 people working on different parts? If yes, consider decomposition
- [ ] **Complexity**: Does this involve 3+ distinct concerns? If yes, consider decomposition
- [ ] **Risk**: Are there high-risk components that need isolation? If yes, consider decomposition
- [ ] **Independence**: Can parts be worked on separately? If yes, consider decomposition

**Assessment**: No signals triggered — single-file prose fix, <1 day, one concern, one person. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered as planned in one file. `cwf-new-subtask` now inserts `### 4. Create Git Branch`
(`git checkout -b "<type>/<num>-<slug>"`, byte-identical to `cwf-new-task` step 4) and the false
"stays on the parent branch" prose is gone. All success criteria met: subtask lands on its own
branch, name matches the retrospective's computation, parent is an ancestor (ff-mergeable), and the
`TaskContextInference` branch signal correlates to the subtask's own number. 7/8 test cases PASS,
TC-8 deferred to a fresh session; 1077-test suite green; all reviewers `no findings`.

## Lessons Learned
The bug was original (Task 57, 2025-08-23), not a CwF-upgrade regression — the whole workflow had
silently compensated for the missing branch. Its fix shape was dictated by existing consumers, so it
reduced to mirroring `cwf-new-task`. See `j-retrospective.md` for the full write-up and the
`cwf-new-task` slug-audit follow-up.
