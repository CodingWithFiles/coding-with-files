# verify task git branch at each workflow step - Implementation

## Task Reference
- **Task ID**: internal-13
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/13-verify-task-git-branch-at-each-workflow-step
- **Template Version**: 2.0

## Goal
Add git branch verification as "Step 1.5" to all 8 CIG workflow commands, providing early warning when users work on wrong branch.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
All 8 workflow command files in `.claude/commands/`:

1. `.claude/commands/cig-plan.md` - Add branch verification to planning workflow
2. `.claude/commands/cig-requirements.md` - Add branch verification to requirements workflow
3. `.claude/commands/cig-design.md` - Add branch verification to design workflow
4. `.claude/commands/cig-implementation.md` - Add branch verification to implementation workflow
5. `.claude/commands/cig-testing.md` - Add branch verification to testing workflow
6. `.claude/commands/cig-rollout.md` - Add branch verification to rollout workflow
7. `.claude/commands/cig-maintenance.md` - Add branch verification to maintenance workflow
8. `.claude/commands/cig-retrospective.md` - Add branch verification to retrospective workflow

Each file requires:
- **Modification 1**: Add `Bash(git:*)` to allowed-tools in frontmatter
- **Modification 2**: Insert Step 1.5 section after "Step 1: Resolve Task Directory"

### Supporting Changes
None required - this is a self-contained change to workflow commands.

## Implementation Steps

### Step 1: Prepare Branch Verification Template
- [x] Review design documentation for Step 1.5 specification
- [x] Prepare Step 1.5 markdown text to insert into all 8 files
- [x] Verify bash commands follow allowed-tools constraints

### Step 2: Update allowed-tools for All 8 Commands
- [ ] Add `Bash(git:*)` to allowed-tools in cig-plan.md
- [ ] Add `Bash(git:*)` to allowed-tools in cig-requirements.md
- [ ] Add `Bash(git:*)` to allowed-tools in cig-design.md
- [ ] Add `Bash(git:*)` to allowed-tools in cig-implementation.md
- [ ] Add `Bash(git:*)` to allowed-tools in cig-testing.md
- [ ] Add `Bash(git:*)` to allowed-tools in cig-rollout.md
- [ ] Add `Bash(git:*)` to allowed-tools in cig-maintenance.md
- [ ] Add `Bash(git:*)` to allowed-tools in cig-retrospective.md

### Step 3: Insert Step 1.5 for All 8 Commands
- [ ] Insert Step 1.5 in cig-plan.md (after "Step 1: Resolve Task Directory")
- [ ] Insert Step 1.5 in cig-requirements.md (after "Step 1: Resolve Task Directory")
- [ ] Insert Step 1.5 in cig-design.md (after "Step 1: Resolve Task Directory")
- [ ] Insert Step 1.5 in cig-implementation.md (after "Step 1: Resolve Task Directory")
- [ ] Insert Step 1.5 in cig-testing.md (after "Step 1: Resolve Task Directory")
- [ ] Insert Step 1.5 in cig-rollout.md (after "Step 1: Resolve Task Directory")
- [ ] Insert Step 1.5 in cig-maintenance.md (after "Step 1: Resolve Task Directory")
- [ ] Insert Step 1.5 in cig-retrospective.md (after "Step 1: Resolve Task Directory")

### Step 4: Verify Consistency
- [ ] Check all 8 files have identical Step 1.5 implementation
- [ ] Verify no step numbering conflicts (Step 2 remains Step 2, etc.)
- [ ] Check bash commands follow security constraints (no command injection)

### Step 5: Testing
- [ ] Test branch verification with correct branch (should continue silently)
- [ ] Test branch verification with wrong branch (should show warning)
- [ ] Test branch verification with non-git directory (should skip gracefully)
- [ ] Test branch verification with detached HEAD (should warn appropriately)
- [ ] Measure performance overhead (should be <100ms)

## Code Changes

### Change 1: Update allowed-tools in Frontmatter

**Before** (example from cig-plan.md:3):
```yaml
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.pl:*), Bash(.cig/scripts/command-helpers/context-inheritance.pl:*), Bash(.cig/scripts/command-helpers/format-detector.pl:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
```

**After**:
```yaml
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.pl:*), Bash(.cig/scripts/command-helpers/context-inheritance.pl:*), Bash(.cig/scripts/command-helpers/format-detector.pl:*), Bash(git:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
```

**Applied to**: All 8 workflow command files (cig-plan.md, cig-requirements.md, cig-design.md, cig-implementation.md, cig-testing.md, cig-rollout.md, cig-maintenance.md, cig-retrospective.md)

### Change 2: Insert Step 1.5 After Step 1

**Location**: After "### Step 1: Resolve Task Directory" section in each workflow command

**Text to Insert**:
```markdown
### Step 1.5: Verify Git Branch
Check if user is on the correct git branch for this task:
- Extract expected branch name from task's a-plan.md Task Reference section
- Get current branch using `git rev-parse --abbrev-ref HEAD`
- Compare expected vs current branch (case-sensitive)
- If mismatch detected, display warning with suggested checkout command
- Continue execution (non-blocking warning)

**Branch verification logic**:
1. Read expected branch from task file:
   ```bash
   expected_branch=$(grep -E '^\- \*\*Branch\*\*:' "${task_dir}/a-plan.md" | sed 's/^- \*\*Branch\*\*: //' | sed 's/`//g' | xargs)
   ```

2. Get current branch:
   ```bash
   current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
   ```

3. Compare and warn if mismatch:
   - If `expected_branch` is empty or `current_branch` is empty, skip verification (graceful degradation)
   - If branches don't match, display warning but continue execution
   - Warning format:
     ```
     ⚠️  Branch Mismatch Warning
     Expected: bugfix/13-verify-task-git-branch-at-each-workflow-step
     Current:  main

     Suggested: git checkout bugfix/13-verify-task-git-branch-at-each-workflow-step

     Continuing with workflow on current branch...
     ```
```

**Applied to**: All 8 workflow command files after their respective Step 1 sections

## Test Coverage

### Unit Tests (Manual Verification)
- **TC-1**: Correct branch → No warning displayed, workflow continues
- **TC-2**: Wrong branch → Warning displayed with correct expected/current branches, workflow continues
- **TC-3**: Non-git directory → No warning, workflow continues (graceful degradation)
- **TC-4**: Detached HEAD → Warning displayed showing "HEAD" as current, workflow continues
- **TC-5**: Missing Branch field in a-plan.md → No warning, workflow continues (graceful degradation)

### Integration Tests
- **TC-6**: Test all 8 workflow commands show consistent warnings
- **TC-7**: Verify warning doesn't block workflow execution
- **TC-8**: Test with task 13 (this task) on correct branch
- **TC-9**: Test with task 13 on main branch (wrong branch)

### Regression Tests
- **TC-10**: Verify all existing workflow command functionality unchanged
- **TC-11**: Verify Step 2+ execute correctly after Step 1.5
- **TC-12**: Verify workflow commands work for tasks without Branch field (backward compatibility)

### Performance Tests
- **TC-13**: Measure Step 1.5 overhead (target: <100ms)

## Validation Criteria
- [ ] All 8 files have `Bash(git:*)` in allowed-tools
- [ ] All 8 files have identical Step 1.5 implementation
- [ ] Branch verification logic tested with correct branch (TC-1)
- [ ] Branch verification logic tested with wrong branch (TC-2)
- [ ] Branch verification logic tested with non-git directory (TC-3)
- [ ] Branch verification logic tested with detached HEAD (TC-4)
- [ ] All 8 workflow commands tested for consistency (TC-6)
- [ ] Performance overhead measured and acceptable (TC-13)
- [ ] No regressions in existing workflow functionality (TC-10, TC-11)
- [ ] Backward compatibility verified (TC-12)

## Status
**Status**: Finished
**Next Action**: Implementation plan complete - moved to testing planning
**Blockers**: None identified

## Recommended Workflow
Following the pattern from c-design.md:
1. ✅ Define implementation plan (this document)
2. ⏳ Define testing regime (`/cig-testing 13`)
3. ⏳ Create checkpoint commit (save planning work before implementation)
4. ⏳ Execute implementation (make code changes to 8 workflow files)
5. ⏳ Execute testing (validate implementation against test cases)

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
