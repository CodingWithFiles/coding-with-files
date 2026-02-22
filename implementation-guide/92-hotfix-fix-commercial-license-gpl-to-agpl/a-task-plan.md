# fix-commercial-license-gpl-to-agpl - Plan
**Task**: 92 (hotfix)

## Task Reference
- **Task ID**: internal-92
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/92-fix-commercial-license-gpl-to-agpl
- **Template Version**: 2.1

## Goal
Correct COMMERCIAL-LICENSE.md to reference AGPL-3.0 throughout, replacing the incorrect GPL-2.0 references that were carried over from the predecessor project (CIG), which was briefly released under GPL-2.0; CWF has never been released under GPL-2.0.

## Success Criteria
- [ ] All GPL-2.0 references in COMMERCIAL-LICENSE.md replaced with AGPL-3.0
- [ ] `grep -i "gpl-2\|gpl v2\|gpl2" COMMERCIAL-LICENSE.md` → no matches
- [ ] Commit message clearly states CWF was never released under GPL-2.0 (its predecessor was briefly)

## Original Estimate
**Effort**: <15 minutes
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. COMMERCIAL-LICENSE.md corrected
2. Committed with accurate historical note, merged, tagged, pushed

## Risk Assessment
### Medium Priority Risks
- **Legal accuracy**: Ensure the replacement text is correct AGPL-3.0 terminology throughout
  - **Mitigation**: Cross-check against LICENSE.md which already has the correct AGPL-3.0 text

## Decomposition Check
- [ ] No — single file, three line edits, <15 minutes

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 92
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 3 success criteria met. 3 GPL-2.0 references replaced with AGPL-3.0. Commit message documents CIG history accurately.

## Lessons Learned
When relicensing, all docs that reference the licence identifier must be in scope — not just LICENSE.md.
