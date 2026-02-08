# Clean up missed items from 39/40/41 - Implementation

## Task Reference
- **Task ID**: internal-43
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/43-clean-up-missed-items-from-39-40-41
- **Template Version**: 2.1

## Goal
Remove 7 obsolete standalone scripts and update security configuration.

## Workflow
Verify → Delete → Update security → Test → Commit with "why"

## Files to Modify

### Primary Changes (Deletions)
- `.cig/scripts/command-helpers/context-inheritance` - DELETE (superseded by context-manager)
- `.cig/scripts/command-helpers/format-detector` - DELETE (superseded by context-manager hierarchy)
- `.cig/scripts/command-helpers/hierarchy-resolver` - DELETE (superseded by context-manager hierarchy)
- `.cig/scripts/command-helpers/status-aggregator` - DELETE (superseded by workflow-manager status)
- `.cig/scripts/command-helpers/template-copier` - DELETE (superseded by task-workflow create)
- `.cig/scripts/command-helpers/template-version-parser` - DELETE (superseded by context-manager version)
- `.cig/scripts/command-helpers/workflow-control` - DELETE (superseded by workflow-manager control)

### Supporting Changes
- `.cig/security/script-hashes.json` - Remove SHA256 hashes for 7 deleted scripts

## Implementation Steps

### Step 1: Pre-removal Verification
- [ ] Grep `.claude/commands/` for references to 7 script names
- [ ] Grep `.cig/scripts/` for invocations of 7 scripts (exclude historical docs)
- [ ] Check `.claude/commands/cig-security-check.md` for hardcoded references
- [ ] Expected result: Zero active references (all migrated in Tasks 39/40/41)

### Step 2: Delete Obsolete Scripts
- [ ] `rm .cig/scripts/command-helpers/context-inheritance`
- [ ] `rm .cig/scripts/command-helpers/format-detector`
- [ ] `rm .cig/scripts/command-helpers/hierarchy-resolver`
- [ ] `rm .cig/scripts/command-helpers/status-aggregator`
- [ ] `rm .cig/scripts/command-helpers/template-copier`
- [ ] `rm .cig/scripts/command-helpers/template-version-parser`
- [ ] `rm .cig/scripts/command-helpers/workflow-control`
- [ ] Verify: `git status` shows 7 deletions

### Step 3: Update Security Configuration
- [ ] Read `.cig/security/script-hashes.json` to identify entries for deleted scripts
- [ ] Remove hash entries for 7 scripts from JSON file
- [ ] Verify: JSON file is still valid (no syntax errors)
- [ ] Stage changes: `git add .cig/security/script-hashes.json`

### Step 4: Post-removal Testing
- [ ] Test `/cig-status 43` (uses workflow-manager status)
- [ ] Test `/cig-new-task 99 bugfix "test"` (uses task-workflow create, delete afterward)
- [ ] Run `/cig-security-check verify` (should pass with updated hashes)
- [ ] Verify: All tests pass, no errors

### Step 5: Commit Changes
- [ ] Stage all deletions: `git add .cig/scripts/command-helpers/`
- [ ] Verify staged: `git status` shows 7 deletions + 1 modification
- [ ] Commit with "why" message explaining obsolescence
- [ ] Include Co-Authored-By trailer

## Verification Commands

### Pre-removal grep commands:
```bash
# Check active commands for references
grep -r "context-inheritance\|format-detector\|hierarchy-resolver\|status-aggregator\|template-copier\|template-version-parser\|workflow-control" .claude/commands/

# Check active scripts for invocations (exclude .git and implementation-guide)
grep -r "context-inheritance\|format-detector\|hierarchy-resolver\|status-aggregator\|template-copier\|template-version-parser\|workflow-control" .cig/scripts/ --exclude-dir=.git
```

Expected: Zero matches in active code (historical docs don't count)

### Post-removal test commands:
```bash
# Test status aggregation still works
.cig/scripts/command-helpers/workflow-manager status --workflow 43

# Test task creation still works
.cig/scripts/command-helpers/task-workflow create --task-type=bugfix --destination="test-task" --task-num="99" --description="Test"
rm -rf test-task  # Clean up

# Test security check passes
/cig-security-check verify
```

## File Changes

### Before (.cig/scripts/command-helpers/)
```
-rwx------ context-inheritance
-rwx------ format-detector
-rwx------ hierarchy-resolver
-rwx------ status-aggregator
-rwx------ template-copier
-rwx------ template-version-parser
-rwx------ workflow-control
```

### After (.cig/scripts/command-helpers/)
```
(7 files removed - only trampolines and modules remain)
```

### Before (.cig/security/script-hashes.json)
```json
{
  "scripts": {
    "context-inheritance": "sha256-hash...",
    "format-detector": "sha256-hash...",
    "hierarchy-resolver": "sha256-hash...",
    "status-aggregator": "sha256-hash...",
    "template-copier": "sha256-hash...",
    "template-version-parser": "sha256-hash...",
    "workflow-control": "sha256-hash...",
    ... other scripts ...
  }
}
```

### After (.cig/security/script-hashes.json)
```json
{
  "scripts": {
    ... only trampolines and modules remain ...
  }
}
```

## Test Coverage
Manual testing with CIG commands:
- Status aggregation (workflow-manager)
- Task creation (task-workflow)
- Security verification (script-hashes)

See e-testing-plan.md for detailed test cases.

## Validation Criteria

Before marking implementation complete:
- [ ] All 7 scripts deleted
- [ ] script-hashes.json updated (7 entries removed)
- [ ] Git status shows exactly 8 changes (7 deletions + 1 modification)
- [ ] `/cig-status 43` works
- [ ] Task creation test works
- [ ] `/cig-security-check verify` passes
- [ ] Commit created with clear "why" message

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: Move to implementation execution → `/cig-implementation-exec 43`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
