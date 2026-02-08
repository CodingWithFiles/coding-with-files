# Clean up missed items from 39/40/41 - Design

## Task Reference
- **Task ID**: internal-43
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/43-clean-up-missed-items-from-39-40-41
- **Template Version**: 2.1

## Goal
Design safe removal strategy for 7 obsolete standalone scripts superseded by trampoline/module architecture.

## Design Priorities
**Simplicity** → Reversibility → Testability

(Readability/Consistency less relevant for file removal)

## Architecture Preferences
Explicit verification. Safe deletion (verify before remove). Atomic commits.

## Key Decisions

### Removal Strategy
- **Decision**: Manual deletion with pre-verification, not automated script
- **Rationale**:
  - Only 7 files, manual is safer than automation risk
  - Allows visual verification of each file before removal
  - Grep verification catches references we might miss
- **Trade-offs**:
  - ✅ Benefit: Explicit, transparent, easy to review
  - ⚠️ Drawback: Not automated (but that's safer here)

### Verification Approach
- **Decision**: Three-phase verification (before, during, after)
- **Phases**:
  1. **Pre-removal**: Grep for all references in `.claude/commands/` and `.cig/scripts/`
  2. **During removal**: Delete one category at a time, check git status
  3. **Post-removal**: Test CIG commands, run `/cig-security-check`
- **Rationale**: Layered verification catches different classes of errors

## System Design

### Files to Remove (7 total)

**Category A: Helper Scripts (5 files)**
```
.cig/scripts/command-helpers/context-inheritance      → superseded by context-manager
.cig/scripts/command-helpers/format-detector          → superseded by context-manager hierarchy
.cig/scripts/command-helpers/hierarchy-resolver       → superseded by context-manager hierarchy
.cig/scripts/command-helpers/status-aggregator        → superseded by workflow-manager status
.cig/scripts/command-helpers/template-copier          → superseded by task-workflow create
.cig/scripts/command-helpers/template-version-parser  → superseded by context-manager version
.cig/scripts/command-helpers/workflow-control         → superseded by workflow-manager control
```

**Superseded by**: Trampoline pattern (Tasks 39/40) + shared libraries (Task 41)

### Security Configuration Updates

**File**: `.cig/security/script-hashes.json`

**Action**: Remove SHA256 hashes for 7 deleted scripts

**Before** (example):
```json
{
  "scripts": {
    "context-inheritance": "abc123...",
    "format-detector": "def456...",
    ...
  }
}
```

**After**:
```json
{
  "scripts": {
    // Only trampolines and modules remain
  }
}
```

### Verification Points

**Pre-removal checks**:
1. Grep `.claude/commands/` for script names
2. Grep `.cig/scripts/` for script invocations
3. Check `/cig-security-check` command for hardcoded references

**Post-removal checks**:
1. Test `/cig-status 43` (uses status-aggregator → workflow-manager)
2. Test `/cig-new-task` (uses template-copier → task-workflow)
3. Run `/cig-security-check verify`
4. Verify Tasks 35-40 references (historical docs should be unchanged)

## Implementation Flow

```
1. Pre-verification
   ├─ Grep active commands for references
   ├─ Grep active scripts for invocations
   └─ Expected: Zero references (all migrated in Tasks 39/40/41)

2. Remove files
   ├─ Delete 7 scripts with rm
   ├─ Verify git status shows 7 deletions
   └─ Update script-hashes.json (remove 7 entries)

3. Post-verification
   ├─ Test key CIG commands
   ├─ Run security check
   └─ Commit all changes atomically
```

## Constraints

- Must not break any active CIG commands
- Must maintain historical documentation (Tasks 35-40 can still reference old names)
- Must update security hashes in same commit
- Should be easily reversible (git revert)

## Validation

### Pre-removal Validation
- [ ] Zero references found in `.claude/commands/`
- [ ] Zero invocations found in `.cig/scripts/` (except historical docs)
- [ ] `/cig-security-check` command has no hardcoded references

### Post-removal Validation
- [ ] `/cig-status 43` works
- [ ] `/cig-new-task` creates tasks
- [ ] `/cig-security-check verify` passes
- [ ] Git shows exactly 8 changes (7 deletions + 1 modification to script-hashes.json)

### Rollback Plan
If anything breaks:
```bash
git revert HEAD  # Single commit, easy rollback
```

## Status
**Status**: Finished
**Next Action**: Move to implementation planning → `/cig-implementation-plan 43`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
