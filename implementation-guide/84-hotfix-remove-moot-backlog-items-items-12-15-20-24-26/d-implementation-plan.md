# Remove moot backlog items: items 12, 15, 20, 24, 26 - Implementation Plan
**Task**: 84 (hotfix)

## Task Reference
- **Task ID**: internal-84
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/84-remove-moot-backlog-items-items-12-15-20-24-26
- **Template Version**: 2.1

## Goal
Edit BACKLOG.md to replace moot/completed items with HTML removal comments and correct one mis-scoped item.

## Files to Modify
### Primary Changes
- `BACKLOG.md` — replace 8 moot item blocks with HTML comments; update scope of 1 item

## Implementation Steps
### Step 1: Remove items 12, 15, 20, 24, 26 (original plan)
- [x] Item 12 ("Update Commands/Skills to Use New Inference Output Format") → HTML comment
- [x] Item 15 ("Document Checkpoint Commit → Squash Workflow") → HTML comment
- [x] Item 20 ("Create Permanent Security Verification Script") → HTML comment
- [x] Item 24 ("Migrate CWF to Hybrid Plugin Model") → HTML comment
- [x] Item 26 ("Design Task-Type-Specific Workflow Variants") → HTML comment

### Step 2: Remove additional moot items (extended scope agreed with user)
- [x] "Create Automated Test Harness" → HTML comment (t/ dir already has 15+ test files)
- [x] "Security Review and Hardening of CWF Bash Invocations" → HTML comment (commands→skills, all Perl now)
- [x] "Standardize Script Naming and Invocation" → HTML comment (already extensionless throughout)

### Step 3: Correct mis-scoped item
- [x] "Remove Decomposition Checks from Non-Planning Workflow Steps" — rewritten to clarify:
  - Keep Step 7 in all `*-plan` skills (task-plan, requirements-plan, design-plan, implementation-plan, testing-plan)
  - Remove Step 7 from cwf-rollout and cwf-maintenance only

### Step 4: Verify
- [x] `grep -c "^## Task:\|^## Bug:" BACKLOG.md` → 33 (was 41)
- [x] All 8 removed items appear as HTML comments with rationale
- [x] `cwf-manage validate` passes

## Decomposition Check
No decomposition needed — single-file edit, completed in one pass.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 84
**Blockers**: None

## Actual Results
All 8 removals and 1 update applied to BACKLOG.md. Count verified: 33 active items remain.

## Lessons Learned
Implementation was done before the plan file was written — work happened in correct order but
the workflow documents should be filled in at each phase, not retrospectively.
