# CIG Command Permissions Issue - Implementation

## Task Reference
- **Task ID**: CIG-BUGFIX-001
- **Task URL**: Internal bugfix task
- **Parent Task**: Core CIG System
- **Branch**: bugfix/CIG-BUGFIX-001-cig-command-permissions
- **Template Version**: 2.0
- **Migration**: v1.0 (git:migration-backup-20251213-233514) → v2.0

## Goal
Implement fix for CIG Command Permissions Issue with minimal risk and maximum reliability.

## Files to Modify
### Primary Changes
- `.claude/commands/cig-status.md` - Replace compound bash patterns and update allowed-tools
- `.claude/commands/cig-new-task.md` - Replace compound bash patterns and update allowed-tools
- `.claude/commands/cig-extract.md` - Replace compound bash patterns and update allowed-tools
- `.claude/commands/cig-subtask.md` - Replace compound bash patterns and update allowed-tools
- `.claude/commands/cig-retrospective.md` - Replace compound bash patterns and update allowed-tools
- `.claude/commands/cig-config.md` - Replace compound bash patterns and update allowed-tools

### Supporting Changes
- Update frontmatter `allowed-tools` in all command files to include required permissions

## Implementation Steps
### Step 1: Prepare Environment
- [ ] Checkout feature branch: `bugfix/CIG-BUGFIX-001-cig-command-permissions`
- [ ] Verify bug reproduction in development
- [ ] Set up debugging environment

### Step 2: Implement Fix
- [ ] Replace `rg -t md ... | cat || echo` with `egrep -rn ... --include="*.md" || echo`
- [ ] Update frontmatter allowed-tools to include `Bash(egrep:*)` and `Bash(echo:*)`
- [ ] Remove `Bash(rg:*)` and `Bash(cat:*)` permissions (no longer needed)
- [ ] Preserve fallback functionality and context loading

### Step 3: Add Prevention
- [ ] Test each command individually
- [ ] Verify context loading still works
- [ ] Test fallback scenarios

### Step 4: Validation
- [ ] Verify fix resolves original issue
- [ ] Test all CIG commands execute successfully
- [ ] Test edge cases and boundary conditions

## Code Changes
### Before (Current Behaviour)
```markdown
## Context
- Existing tasks: !`rg -t md '^#+ ' implementation-guide/ | cat || echo "No existing tasks"`
- Directory numbering: !`find implementation-guide -maxdepth 5 -type d -name '[0-9]*' | cat || echo "Starting at 1"`
```

### After (Fixed Implementation)
**Preferred Solution: Use egrep -rn**
```markdown
## Context
- Existing tasks: !`egrep -rn '^#+ ' implementation-guide/ --include="*.md" 2>/dev/null || echo "No existing tasks"`
- Directory numbering: !`find implementation-guide -maxdepth 5 -type d -name '[0-9]*' 2>/dev/null || echo "Starting at 1"`
- Current status sections: !`egrep -rn '^## Current Status' implementation-guide/ --include="*.md" 2>/dev/null || echo "No status sections found"`
```

**Benefits of egrep -rn approach:**
- No pipe operations = no permission issues
- Consistent output format regardless of TTY
- Includes line numbers and filenames for context
- Standard tool available everywhere
- Clean fallback handling with 2>/dev/null
- Supports `-A`, `-B`, `-C` context flags like rg

**Required allowed-tools updates:**
```yaml
# Before
allowed-tools: Write, Read, LS, Bash(git:*), Bash(rg:*), Bash(cat:*), Bash(find:*)

# After  
allowed-tools: Write, Read, LS, Bash(git:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
```

## Test Coverage
### Regression Tests
- Execute each CIG command to ensure no permission errors
- Verify context loading provides expected information
- Test fallback behaviour when files don't exist

### Integration Tests
- Test full workflow: cig-init → cig-new-task → cig-status
- Verify all commands work in sequence
- Test error conditions and edge cases

## Validation Criteria
- [ ] Original bug scenario no longer occurs
- [ ] All CIG commands execute without permission errors
- [ ] Context loading functionality preserved
- [ ] Fallback error messages still appear when appropriate

## Current Status
**Status**: Finished
**Next Action**: N/A - Implementation finished
**Blockers**: None

## Actual Results
**Implementation Successful**: All 5 CIG command files updated and tested

**Files Modified**:
1. `.claude/commands/cig-status.md` - Context loading patterns updated
2. `.claude/commands/cig-new-task.md` - Context loading patterns and permissions updated
3. `.claude/commands/cig-extract.md` - Context loading patterns updated
4. `.claude/commands/cig-subtask.md` - Context loading patterns updated
5. `.claude/commands/cig-retrospective.md` - Context loading patterns updated
6. `.claude/commands/cig-init.md` - Missing permissions added
7. `.claude/commands/cig-config.md` - Missing permissions added

**Pattern Transformations Applied**:
- `rg -t md '^#+ ' implementation-guide/ | cat || echo "..."` → `egrep -rn '^#+ ' implementation-guide/ --include="*.md" 2>/dev/null || echo "..."`
- `find ... | cat || echo "..."` → `find ... 2>/dev/null || echo "..."`
- Updated allowed-tools frontmatter in all files

**Additional Permission Fixes**:
- Added missing `Bash(cat:*)` to cig-new-task.md for config file reading
- Added `Bash(pwd:*)`, `Bash(ls:*)`, `Bash(echo:*)` to cig-init.md
- Added `Bash(ls:*)`, `Bash(echo:*)` to cig-config.md
- Ensured all bash executables used in context sections have explicit permissions

**Validation Results**:
- Manual command testing confirmed patterns work correctly
- Fallback behaviour preserved and functioning
- /cig-status command demonstrated successful execution
- All permission gaps identified and resolved
- Complete alignment between commands used and allowed-tools frontmatter

## Lessons Learned
**Security Model Understanding**: Claude Code requires explicit approval for compound bash operations

**Technical Approach**: 
- `egrep -rn` superior to `rg | cat` for consistent output
- `2>/dev/null` cleaner than pipe-based error suppression
- Explicit tool permissions essential in frontmatter

**Testing Strategy**:
- Manual pattern validation before deployment
- Backup creation critical for safe implementation
- Progressive testing approach (patterns → commands → integration)
