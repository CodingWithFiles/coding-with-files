# Remove moot backlog items: items 12, 15, 20, 24, 26 - Testing Plan
**Task**: 84 (hotfix)

## Task Reference
- **Task ID**: internal-84
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/84-remove-moot-backlog-items-items-12-15-20-24-26
- **Template Version**: 2.1

## Goal
Verify BACKLOG.md edits are correct: removed items gone, replacement comments present, surviving items intact, validate passes.

## Test Strategy
No code changes — pure documentation edit. Testing is structural verification only.

## Test Cases

### TC-1: Removed item blocks are gone
- **Given**: BACKLOG.md has been edited
- **When**: `grep "^## Task: Update Commands/Skills\|^## Task: Document Checkpoint Commit\|^## Task: Create Permanent Security\|^## Task: Migrate CWF to Hybrid\|^## Task: Design Task-Type-Specific\|^## Task: Create Automated Test Harness\|^## Task: Security Review and Hardening\|^## Task: Standardize Script Naming" BACKLOG.md`
- **Then**: Zero matches

### TC-2: HTML removal comments present with rationale
- **Given**: BACKLOG.md has been edited
- **When**: `grep -c "Removed:.*Task 84" BACKLOG.md`
- **Then**: Returns 8

### TC-3: Active item count reduced correctly
- **Given**: BACKLOG.md has been edited
- **When**: `grep -c "^## Task:\|^## Bug:" BACKLOG.md`
- **Then**: Returns 33

### TC-4: Decomposition Checks item scope is corrected
- **Given**: The "Remove Decomposition Checks" item was rewritten
- **When**: Read the item in BACKLOG.md
- **Then**: Scope mentions retaining Step 7 in `*-plan` skills and removing from rollout/maintenance only

### TC-5: cwf-manage validate passes
- **Given**: No scripts or hashes were modified
- **When**: `perl -I.cwf/lib .cwf/scripts/cwf-manage validate`
- **Then**: Exit 0, "[CWF] validate: OK"

### TC-6: No surviving active items reference removed content
- **Given**: Removal comments are HTML (invisible to readers)
- **When**: Read through active `## Task:` blocks around each removal point
- **Then**: Surrounding items intact, no truncated or corrupted blocks

## Validation Criteria
- [ ] TC-1 passes (no active headings for removed items)
- [ ] TC-2 passes (8 removal comments)
- [ ] TC-3 passes (33 active items)
- [ ] TC-4 passes (Decomposition Checks scope corrected)
- [ ] TC-5 passes (validate OK)
- [ ] TC-6 passes (surrounding items intact)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 84
**Blockers**: None

## Actual Results
*To be filled in g-testing-exec.md*

## Lessons Learned
*To be captured during testing execution*
