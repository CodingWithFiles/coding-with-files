# Fix stale CIG references in wf step templates and template-copier - Plan
**Task**: 90 (hotfix)

## Task Reference
- **Task ID**: internal-90
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/90-fix-stale-cig-references-in-wf-step-templates-and-t
- **Template Version**: 2.1

## Goal
Fix two stale CIG→CWF rebrand misses that cause every new task to be generated with
wrong file paths and skill names in its wf step files.

## Success Criteria
- [ ] All 10 `*.template` files reference `.cwf/docs/workflow/workflow-steps.md` (not `.cig/...`)
- [ ] `template-copier-v2.1` `name_to_action()` emits `/cwf-` skill names (not `/cig-`)
- [ ] `script-hashes.json` updated for modified `template-copier-v2.1`
- [ ] `cwf-manage validate` passes
- [ ] A newly generated task file contains no `.cig/` or `/cig-` references

## Original Estimate
**Effort**: <0.25 days
**Complexity**: Trivial — two targeted string replacements across known files
**Dependencies**: None

## Major Milestones
1. Templates fixed (10 one-line edits)
2. `template-copier-v2.1` fixed (2 one-line edits)
3. Hash updated, validate passes

## Risk Assessment
### Low Priority Risks
- **Risk**: `template-copier-v2.0` has the same bug
  - **Mitigation**: Check before fixing — grep already showed no output, likely clean
- **Risk**: Other scripts or configs still use `/cig-`
  - **Mitigation**: Broad grep after fix to confirm nothing missed

## Root Cause
Task 59 (CIG→CWF rebrand) updated skills, docs, and scripts but missed:
1. The `**See ...` footer line hardcoded in all 10 wf step templates
2. The `name_to_action()` function in `template-copier-v2.1` that generates `{{nextAction}}`

## Decomposition Check
- [ ] **Time**: No — trivial
- [ ] **People**: No
- [ ] **Complexity**: No
- [ ] **Risk**: No
- [ ] **Independence**: N/A

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 90
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Completed in ~20 minutes. All 10 templates and template-copier-v2.1 fixed.
7/7 TCs passed. No regressions. Broad sweep confirmed nothing else missed.

## Lessons Learned
Rebrand tasks need an output-level test — renaming source strings doesn't guarantee
generated file output is correct. A generation smoke-test would have caught this in Task 59.
