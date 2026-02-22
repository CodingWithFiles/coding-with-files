# fix-commercial-license-gpl-to-agpl - Implementation Plan
**Task**: 92 (hotfix)

## Task Reference
- **Task ID**: internal-92
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/92-fix-commercial-license-gpl-to-agpl
- **Template Version**: 2.1

## Goal
Replace all GPL-2.0 references in COMMERCIAL-LICENSE.md with AGPL-3.0.

## Files to Modify
- `COMMERCIAL-LICENSE.md` — three occurrences of GPL-2.0 / GPL v2.0

## Implementation Steps

### Step 1: Replace line 5 (overview sentence)
- [ ] `GNU General Public License v2.0 (GPL-2.0)` → `GNU Affero General Public License v3.0 (AGPL-3.0)`

### Step 2: Replace line 9 (commercial distribution paragraph)
- [ ] `GPL-2.0 license` → `AGPL-3.0 license`

### Step 3: Replace line 24 (important note)
- [ ] `GPL v2.0` → `AGPL-3.0`

## Validation Criteria
- `grep -i "gpl-2\|gpl v2\|gpl2" COMMERCIAL-LICENSE.md` → no matches
- `grep "AGPL-3.0" COMMERCIAL-LICENSE.md` → 3 matches

## Decomposition Check
No — single file, three line edits.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 92
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 3 steps applied as planned. No deviations.

## Lessons Learned
No issues. Three targeted edits executed cleanly.
