# Remove sed extraction guidance from CWF docs - Plan
**Task**: 160 (chore)

## Task Reference
- **Task ID**: internal-160
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/160-remove-sed-extraction-guidance-from-cwf-docs
- **Baseline Commit**: b5c7b1a8fb84e3a26a83d6afe45c235d369ddb55
- **Template Version**: 2.1

## Goal
Replace the `sed`-based section-extraction guidance in `COMMANDS.md` and `DESIGN.md` with grep-for-line-number + read-with-offset/limit guidance, aligning the docs with the project's no-sed-for-line-range-reads convention.

## Success Criteria
- [ ] `COMMANDS.md` no longer documents the `/cwf-extract` `sed -n '…/p'` **Method** line.
- [ ] `DESIGN.md` success criterion and **Section Extraction Commands** block describe grep+read tools, not `sed`.
- [ ] No stale `sed`-extraction references remain in either file (grep-verified).

## Original Estimate
**Effort**: <0.5 day (single session)
**Complexity**: Low — docs-only, change already staged in `stash@{0}`.
**Dependencies**: The session stash `stash@{0}` ("Task 159 follow-up: sed→grep+read doc edits"), which holds the exact diff to apply.

## Major Milestones
1. **Stash applied**: `stash@{0}` content lands on this branch (COMMANDS.md + DESIGN.md).
2. **Verified**: no stale `sed`-extraction strings remain; full suite still green.

## Risk Assessment
### Low Priority Risks
- **Stash conflicts on apply**: the baseline files may have moved since the stash was taken.
  - **Mitigation**: both files are unchanged on `main` since the stash; apply and inspect, re-create the two edits by hand if `git stash apply` conflicts.
- **Doc/code divergence**: the docs describe a tool pattern, not executable code — no test asserts the doc text.
  - **Mitigation**: grep-verify the absence of `sed`-extraction guidance as the acceptance check.

## Dependencies
- `stash@{0}` (the staged diff). Nothing external.

## Constraints
- Dog-food repo — goes through the CWF workflow; no direct-to-main commits.
- Docs-only: `COMMANDS.md`/`DESIGN.md` are not hash-tracked, so no `script-hashes.json` refresh.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No — single session.
- [ ] **People**: >2 people? No — solo.
- [ ] **Complexity**: 3+ distinct concerns? No — one concern (two files, same edit).
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Separable parts? No — one cohesive doc change.

**Decision**: 0 signals triggered. No decomposition; flat chore task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All three success criteria met: no `sed`-extraction guidance in either file, grep+read guidance present in DESIGN.md, grep-verified. 0 decomposition signals — stayed a flat chore. Delivered by applying `stash@{0}` in one session.

## Lessons Learned
The estimate (<0.5 day) held. The value was not in the edit but in the plan-review gate, which caught a false rationale and an unverifiable check before exec. See j-retrospective.md.
