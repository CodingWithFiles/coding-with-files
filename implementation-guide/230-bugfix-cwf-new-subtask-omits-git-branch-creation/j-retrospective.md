# cwf-new-subtask omits git branch creation - Retrospective
**Task**: 230 (bugfix)

## Task Reference
- **Task ID**: internal-230
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/230-cwf-new-subtask-omits-git-branch-creation
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-14

## Executive Summary
- **Duration**: <1 day (as estimated).
- **Scope**: Held exactly to plan — one file (`.claude/skills/cwf-new-subtask/SKILL.md`): add a branch-creation step mirroring `cwf-new-task`, delete the prose that blessed the omission, renumber, surface the branch in Next Steps and Success Criteria.
- **Outcome**: Success. `cwf-new-subtask` now creates the per-subtask branch the rest of the workflow already assumed existed. All 7 executable test cases passed (TC-8 live invocation deferred to a fresh session by design).

## Variance Analysis
### Time and Effort
- **Estimated**: <1 day, Low complexity.
- **Actual**: matched. Six phases (a,c,d,e,f,g) plus this retrospective; no phase reopened.
- **Variance**: none.

### Scope Changes
- **Additions**: none beyond plan. Review folded in three refinements without widening scope: the slug-source security invariant (use the script-produced slug), the bare-command framing (own step 4 as a deliberate minimal divergence), and an explicit `TaskContextInference` confirmation in testing.
- **Removals**: none.
- **Impact**: none — the fix stayed one file.

### Quality Metrics
- **Test Coverage**: 8 planned cases; 7 PASS, 1 DEFERRED (TC-8, session-cache). Full `prove -r t/` green (1077 tests).
- **Defect Rate**: 0 introduced. 15 plan/exec reviewers + 2 testing-exec reviewers all returned `no findings`.
- **Performance**: N/A (prose change).

## What Went Well
- **The fix's shape was dictated, not invented.** The retrospective merge-suggestion (`retrospective-extras.md:147`) and `TaskContextInference` already assumed a per-subtask branch, so branch name and base were fixed by existing consumers — the change reduced to mirroring `cwf-new-task` step 4.
- **Reviewers earned their keep on a two-line change.** Security pinned the slug-reuse invariant; improvements reframed step 4 as a documented divergence rather than a false "exact mirror"; misalignment surfaced the `TaskContextInference` branch-signal behaviour change, which testing then confirmed benign.
- **Hand-simulated the procedure to work around the skill session-cache**, validating real git state (branch created, parent-is-ancestor, ff-mergeable, signal correlates) without depending on the cached skill.

## What Could Be Improved
- The forensic diagnosis initially entertained a "CwF-upgrade regression" theory; git archaeology (pickaxe + blame across the rename chain) refuted it. Reaching for `git log -S`/`blame` first would have skipped the speculation.

## Key Learnings
### Technical Insights
- A latent bug can hide when the rest of the system silently compensates: the retrospective's ff-merge and the branch-signal correlator were both written to a branch that `cwf-new-subtask` never created, so nothing failed loudly — the omission survived from Task 57 (2025-08-23) to now.
- Editing a `.claude/skills/*.md` file is not live in the same session (skills load at session start); functional testing of an edited skill must either simulate the documented procedure or defer to a fresh session.

### Process Learnings
- For "when did this land" questions, pickaxe (`git log -S`) and `git blame` across the rename chain beat reading successive file versions.
- Distinguish behaviour origin from documentation origin: the missing-branch *behaviour* dates to Task 57; the prose that *blessed* it dates to Task 203. Both were named in the goal so neither was lost.

## Recommendations
### Process Improvements
- None specific to CwF process; the workflow handled a minimal bugfix cleanly.

### Tool and Technique Recommendations
- Keep using pickaxe/blame across renames for "when introduced" forensics.

### Future Work
- **Audit `cwf-new-task` step 4 for the same latent slug-re-derivation ambiguity (FR4(e)).** Multiple security reviewers noted `cwf-new-task` carries the identical unpinned-slug wording; `cwf-new-subtask` now pins "reuse the script-produced slug — do not re-derive it" but `cwf-new-task` does not. Candidate backlog item to align the two.
- **TC-8**: run a live `/cwf-new-subtask` in a fresh session post-merge to confirm the reloaded skill branches as documented.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-07-14
**Sign-off**: CwF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Links to planning documents and artefacts
- Links to implementation PRs and commits
- Links to test results and quality reports
- Links to deployment and monitoring dashboards
