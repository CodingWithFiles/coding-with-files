# Add missing checkpoint commit instructions to cwf-requirements-plan and cwf-maintenance - Testing Execution
**Task**: 71 (hotfix)

## Task Reference
- **Task ID**: internal-71
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/71-fix-checkpoint-steps
- **Template Version**: 2.1

## Goal
Execute tests from e-testing-plan.md and verify both SKILL.md edits are correct.

## Execution Checklist
- [x] Read e-testing-plan.md thoroughly
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps

## Test Results

| Test ID | Description | Status |
|---------|-------------|--------|
| TC-1 | cwf-requirements-plan has checkpoint commit Step 8 with correct Stage | PASS |
| TC-2 | cwf-requirements-plan Next Steps at Step 9 | PASS |
| TC-3 | cwf-maintenance has checkpoint commit Step 8 with correct Stage | PASS |
| TC-4 | cwf-maintenance Next Steps at Step 9 | PASS |
| TC-5 | No other wf step skills missing checkpoint commit | PASS |
| TC-6 | cwf-manage validate exits 0 | PASS |

### TC-1: PASS
- Line 39: `**Step 8**: Checkpoint commit. See \`.cwf/docs/skills/checkpoint-commit.md\`. Stage: \`b-requirements-plan.md\`` ✓

### TC-2: PASS
- Line 41: `**Step 9 (Next Steps)**` ✓ (no `**Step 8 (Next Steps)**` remains)

### TC-3: PASS
- Line 39: `**Step 8**: Checkpoint commit. See \`.cwf/docs/skills/checkpoint-commit.md\`. Stage: \`i-maintenance.md\`` ✓

### TC-4: PASS
- Line 41: `**Step 9 (Next Steps)**` ✓

### TC-5: PASS
Scan of all `cwf-*/SKILL.md` files with "Next Steps" but no `checkpoint-commit` reference found three entries. All are legitimately exempt:
- `cwf-new-task`: "Next Steps" is a plain section heading (`### 5. Provide Next Steps`), not a numbered step — skill creates a task directory, not a workflow doc
- `cwf-subtask`: Same pattern as cwf-new-task
- `cwf-retrospective`: Has Step 9 (squash + checkpoints branch) which is a more comprehensive commit mechanism — no separate checkpoint commit needed

No genuine gaps remain. ✓

### TC-6: PASS
- `[CWF] validate: OK` — exit 0 ✓

## Test Failures

None.

## Coverage Report

6/6 tests pass. All success criteria met.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout 71
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
6/6 PASS on first run. No defects. TC-5 scan also confirmed cwf-new-task, cwf-subtask, and cwf-retrospective are legitimately exempt from checkpoint commit steps.

## Lessons Learned
*To be captured during retrospective*
