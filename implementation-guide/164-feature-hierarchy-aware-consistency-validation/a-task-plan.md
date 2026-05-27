# hierarchy-aware consistency validation - Plan
**Task**: 164 (feature)

## Task Reference
- **Task ID**: internal-164
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/164-hierarchy-aware-consistency-validation
- **Baseline Commit**: 4e3f341214279f85aed04fb42a2b4cba45b8a71d
- **Template Version**: 2.1

## Goal
Make `CWF::Validate::Consistency` aware of the task hierarchy so it stops emitting
false-positive branch violations against legitimately-active parent tasks while you
work a subtask, validates nested subtask dirs it currently ignores, and gains the
parent/child completeness invariant it is currently missing.

## Background
A downstream adopter on a subtask branch (`feature/28.1`) hit a CONSISTENCY violation
against the **parent** task 28: the parent's later phases sit at the template default
`Backlog` (non-terminal → "active"), its recorded `**Branch**` is `feature/28`, and the
current branch is `feature/28.1`, so the flat equality check fires. Three flat-model
limitations underlie this (`.cwf/lib/CWF/Validate/Consistency.pm:74-84`):
1. The scan only reads top-level `implementation-guide/*` dirs and their direct `.md`
   children — nested subtask dirs are never validated at all.
2. The branch check is flat equality; it has no notion that the current branch may
   legitimately sit *below* an active ancestor task.
3. There is no check that a parent in a terminal status cannot have a non-terminal
   descendant (the completeness asymmetry).

This is the same subtask-awareness class as Task 163 (version helpers); the fix shares
the dotted-number ancestry notion introduced there (`is_subtask_num`).

## Success Criteria
- [ ] Consistency validation descends into nested subtask dirs; a subtask's own
      `**Task**`/`**Branch**` fields are checked (currently unvalidated).
- [ ] An active ancestor task whose recorded branch is an ancestor of the current
      branch produces **no** branch violation (satisfied-by-descendant); the leaf task
      whose branch equals the current branch is still asserted exactly.
- [ ] An active task **not** on the current branch's ancestry chain (e.g. a sibling
      subtask, or an unrelated task) is still flagged — no blanket suppression.
- [ ] A parent in a terminal status (`Finished`/`Skipped`/`Cancelled`) with a
      non-terminal descendant is reported as a new CONSISTENCY violation; the inverse
      (terminal child under an active parent) is **not** flagged.
- [ ] Existing top-level (non-hierarchical) validation behaviour is unchanged; full
      `prove t/` green with new assertions covering each rule above.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium
**Dependencies**: None hard. Reuses the dotted-number ancestry notion from Task 163.

## Major Milestones
1. **Design**: Settle the hierarchy traversal model (recurse vs. flat-with-ancestry),
   the directional branch rule, and the terminal-ancestor invariant — including how the
   "current leaf" is identified from recorded data without branch-name parsing.
2. **Implementation**: Rework `Consistency.pm` traversal to be hierarchy-aware; add the
   directional branch rule and the completeness check.
3. **Verification**: Prove the three corrected behaviours plus no-regression on the
   flat top-level path, against constructed multi-level task trees.

## Risk Assessment
### Medium Priority Risks
- **Risk**: Mapping the current git branch to its task node relies on a heuristic that
   breaks under non-default branch naming, mis-identifying the leaf.
  - **Mitigation**: Prefer recorded data — match the current branch against each dir's
    recorded `**Branch**` field to locate the leaf node, rather than parsing the branch
    string. Decide the exact mechanism in design.
- **Risk**: Recursing the scan changes which violations existing repos see (previously
   silent subtask dirs now validated), surfacing pre-existing latent inconsistencies.
  - **Mitigation**: Treat newly-surfaced real inconsistencies as correct output; verify
    against the live repo before merge and disposition anything that appears.

### Low Priority Risks
- **Risk**: Over-suppression — a genuine wrong-branch edit on an ancestor gets masked by
   the directional rule.
  - **Mitigation**: Suppress only along the *ancestry* axis of the located leaf; siblings
    and off-chain tasks stay flagged (pinned as an explicit test case).

## Dependencies
- None external. Self-contained change to `CWF::Validate::Consistency` and its tests;
  `Consistency.pm` is hash-tracked, so an in-commit `script-hashes.json` refresh applies.

## Constraints
- Core-Perl only (`feedback_perl_core_only`); ancestry is derivable from dotted task
  numbers, no new deps.
- `.cwf/lib` edit requires a same-commit hash refresh (`docs/conventions/hash-updates.md`)
  and working-perms handling per `feedback_hashed_script_working_perms`.
- Validation output is advisory; the change must not alter validate's exit-code contract
  for the existing top-level cases.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — the three observable
      behaviours all fall out of a single mechanism (hierarchy-aware traversal of the
      task tree); splitting would rewrite the same traversal three times.
- [ ] **Risk**: Are there high-risk components that need isolation? No — advisory
      validation module.
- [ ] **Independence**: Can parts be worked on separately? Only superficially; they share
      the traversal rework, so they are best done together.

No decomposition signals triggered; proceed as a single feature task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria delivered; scope unchanged from plan; completed within the
1–2 day / Medium estimate. Implementation committed (`27b531a`), tests (`a6e2766`).

## Lessons Learned
The "no decomposition" call held: the directional branch rule and the completeness
invariant both fell out of one hierarchy-aware traversal, not three separate reworks.
