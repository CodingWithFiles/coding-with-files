# subtask retrospective must not version-bump or tag - Plan
**Task**: 163 (bugfix)

## Task Reference
- **Task ID**: internal-163
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/163-subtask-retrospective-must-not-version-bump-or-tag
- **Baseline Commit**: 53926d07005f7842feba2f217ba252c6726d362d
- **Template Version**: 2.1

## Goal
A subtask's retrospective phase must skip the version-bump and version-tag steps, because both are keyed to an integer top-level task number and only top-level tasks land on trunk.

## Success Criteria
- [ ] The retrospective skill gates Step 9 (`cwf-version-bump`) and Step 11 (`cwf-version-tag`) to top-level tasks only (task number matching `^\d+$`); subtasks skip both.
- [ ] A subtask retrospective no longer invokes either version helper, so the decimal task number never reaches the `--task-num` integer parser (no "unknown argument" error).
- [ ] Top-level task retrospective behaviour is unchanged (still bumps/tags subject to `bump_version`/`tag_version` config).
- [ ] `versioning-standard.md` documents that version actions run only at the top-level task retrospective; subtasks are excluded.

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Design**: Decide where the top-level-vs-subtask gate lives (retrospective skill) and whether the scripts get a defence-in-depth guard.
2. **Implementation**: Add the gate to the retrospective skill; update the versioning-standard doc.
3. **Verification**: Confirm a subtask retrospective skips cleanly and a top-level retrospective is unaffected.

## Risk Assessment
### Medium Priority Risks
- **Risk**: The task number passed to the skill is ambiguous or unavailable, so the gate misclassifies a subtask as top-level.
  - **Mitigation**: Derive top-level status from a strict `^\d+$` match on the resolved task number; a subtask number always contains a dot, so the test is unambiguous.

### Low Priority Risks
- **Risk**: A future caller invokes `cwf-version-bump`/`-tag` directly with a decimal task number, reintroducing the confusing error.
  - **Mitigation**: Consider a defence-in-depth clean-skip in the scripts during design; decide there rather than pre-committing here.

## Dependencies
- None. Self-contained change to the retrospective skill and versioning doc.

## Constraints
- The semver scheme (`v{major}.{minor}.{patch}`, patch = integer task number) is fixed; subtask numbers cannot form a valid patch, so the fix must exclude subtasks rather than reshape the version format.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — single concern (gate two steps).
- [ ] **Risk**: Are there high-risk components that need isolation? No.
- [ ] **Independence**: Can parts be worked on separately? No.

No decomposition signals triggered; proceed as a single bugfix task.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four success criteria met. The subtask skip is enforced in the scripts (not skill prose) via a shared `is_subtask_num` predicate; top-level behaviour is unchanged; `versioning-standard.md` documents the top-level-only policy. Delivered in a single session, on the <1-day estimate.

## Lessons Learned
The "ambiguous task number" medium risk did not materialise — the resolved number is unambiguous and the `^\d+(?:\.\d+)+$` shape test is decisive. The low-priority "future direct caller" risk was promoted to in-scope during design (the script guard now covers it). See `j-retrospective.md`.
