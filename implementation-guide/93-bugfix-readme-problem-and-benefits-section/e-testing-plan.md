# readme-problem-and-benefits-section - Testing Plan
**Task**: 93 (bugfix)

## Task Reference
- **Task ID**: internal-93
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/93-readme-problem-and-benefits-section
- **Template Version**: 2.1

## Goal
Verify the three new sections are present, correctly positioned, and no regressions introduced.

## Test Strategy
- **Static**: grep-based presence and positioning checks
- **Regression**: `cwf-manage validate` and `prove t/`

---

## Test Cases

### TC-1: "The Problem With AI-Assisted Coding" section present
- **When**: `grep "The Problem With AI-Assisted Coding" README.md`
- **Then**: match found

### TC-2: "What CWF Does" section present
- **When**: `grep "What CWF Does" README.md`
- **Then**: match found

### TC-3: "Why the Structure Matters" section present
- **When**: `grep "Why the Structure Matters" README.md`
- **Then**: match found

### TC-4: Sections positioned correctly
- **When**: Read README.md and check line order
- **Then**: All three sections appear after `## Overview` and before `## Project Status`

### TC-5: Token efficiency figure present
- **When**: `grep "80%" README.md`
- **Then**: match found

### TC-6: Dan Shapiro reference present
- **When**: `grep "Dan Shapiro" README.md`
- **Then**: match found

### TC-7: Level 3 reference present
- **When**: `grep "Level 3" README.md`
- **Then**: match found

### TC-8: `cwf-manage validate` passes
- **When**: `.cwf/scripts/cwf-manage validate`
- **Then**: OK

### TC-9: `prove t/` — no regressions
- **When**: `prove t/`
- **Then**: all 173 tests pass

---

## Validation Criteria
- [ ] TC-1 through TC-7: all grep/read checks pass
- [ ] TC-8: validate OK
- [ ] TC-9: prove clean

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 93
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
9/9 TCs passed first run.

## Lessons Learned
Positioning checks (TC-4 line-order grep) are useful for insertion tasks — confirm placement, not just presence.
