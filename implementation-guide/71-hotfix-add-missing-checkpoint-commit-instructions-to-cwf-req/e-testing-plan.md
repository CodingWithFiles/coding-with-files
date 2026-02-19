# Add missing checkpoint commit instructions to cwf-requirements-plan and cwf-maintenance - Testing Plan
**Task**: 71 (hotfix)

## Task Reference
- **Task ID**: internal-71
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/71-fix-checkpoint-steps
- **Template Version**: 2.1

## Goal
Verify that both skill files contain the correct checkpoint commit step and that Next Steps is renumbered to Step 9.

## Test Strategy

Content inspection tests against the two modified SKILL.md files, plus one system test.

## Test Cases

### TC-1: cwf-requirements-plan has checkpoint commit Step 8
- **Given**: `cwf-requirements-plan/SKILL.md` has been updated
- **When**: Step 8 content is read
- **Then**: Contains `checkpoint-commit.md` reference and `Stage: \`b-requirements-plan.md\``

### TC-2: cwf-requirements-plan Next Steps renumbered to Step 9
- **Given**: `cwf-requirements-plan/SKILL.md`
- **When**: Step numbering is inspected
- **Then**: Next Steps heading is `**Step 9 (Next Steps)**`, not `**Step 8 (Next Steps)**`

### TC-3: cwf-maintenance has checkpoint commit Step 8
- **Given**: `cwf-maintenance/SKILL.md` has been updated
- **When**: Step 8 content is read
- **Then**: Contains `checkpoint-commit.md` reference and `Stage: \`i-maintenance.md\``

### TC-4: cwf-maintenance Next Steps renumbered to Step 9
- **Given**: `cwf-maintenance/SKILL.md`
- **When**: Step numbering is inspected
- **Then**: Next Steps heading is `**Step 9 (Next Steps)**`, not `**Step 8 (Next Steps)**`

### TC-5: No other wf step skills are missing checkpoint commit
- **Given**: All `.claude/skills/cwf-*/SKILL.md` files
- **When**: Grepped for `checkpoint-commit.md`
- **Then**: Every skill that has a "Next Steps" step also has a `checkpoint-commit.md` reference (i.e. no remaining gaps)

### TC-6: cwf-manage validate exits 0
- **Given**: Both edits complete
- **When**: `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` is run
- **Then**: Exits 0

## Validation Criteria
- [ ] TC-1: cwf-requirements-plan checkpoint commit step present with correct Stage file
- [ ] TC-2: cwf-requirements-plan Next Steps at Step 9
- [ ] TC-3: cwf-maintenance checkpoint commit step present with correct Stage file
- [ ] TC-4: cwf-maintenance Next Steps at Step 9
- [ ] TC-5: No other wf step skills missing checkpoint commit
- [ ] TC-6: cwf-manage validate exits 0

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 71
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled during g-testing-exec*

## Lessons Learned
*To be captured during retrospective*
