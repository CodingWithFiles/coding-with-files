# fix-commercial-license-gpl-to-agpl - Testing Plan
**Task**: 92 (hotfix)

## Task Reference
- **Task ID**: internal-92
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/92-fix-commercial-license-gpl-to-agpl
- **Template Version**: 2.1

## Goal
Verify all GPL-2.0 references are removed from COMMERCIAL-LICENSE.md and replaced with AGPL-3.0.

## Test Strategy
- **Static**: grep-based checks — no test harness needed for a doc edit
- **Regression**: `prove t/` and `cwf-manage validate`

---

## Test Cases

### TC-1: No GPL-2.0 references remain
- **When**: `grep -i "gpl-2\|gpl v2\|gpl2" COMMERCIAL-LICENSE.md`
- **Then**: no matches

### TC-2: AGPL-3.0 present in all three locations
- **When**: `grep "AGPL-3.0" COMMERCIAL-LICENSE.md`
- **Then**: 3 matches

### TC-3: LICENSE.md still references AGPL-3.0 (no regression)
- **When**: `grep "AGPL" LICENSE.md`
- **Then**: match found

### TC-4: `cwf-manage validate` passes
- **When**: `.cwf/scripts/cwf-manage validate`
- **Then**: OK

### TC-5: `prove t/` — no regressions
- **When**: `prove t/`
- **Then**: all 173 tests pass

---

## Validation Criteria
- [ ] TC-1: no stale GPL-2.0 references
- [ ] TC-2: AGPL-3.0 in all three locations
- [ ] TC-3: LICENSE.md unaffected
- [ ] TC-4: validate OK
- [ ] TC-5: prove clean

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 92
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
5/5 TCs passed first run. No failures.

## Lessons Learned
A future validate check comparing licence identifiers across COMMERCIAL-LICENSE.md and LICENSE.md would catch this automatically.
