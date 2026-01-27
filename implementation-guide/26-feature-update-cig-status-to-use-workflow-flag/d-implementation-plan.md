# Update cig-status to Use --workflow Flag - Implementation

## Task Reference
- **Task ID**: internal-26
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/26-update-cig-status-to-use-workflow-flag
- **Template Version**: 2.1

## Goal
Implement intelligent default behavior in status-aggregator script: automatically enable workflow mode for task queries, automatically limit to 5 tasks for overview, with explicit flag controls to override defaults.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cig/scripts/command-helpers/status-aggregator` - Add intelligent defaults and flag parsing logic
- `.cig/scripts/command-helpers/status-aggregator-v2.0` - Add --limit and --no-workflow flag support
- `.cig/scripts/command-helpers/status-aggregator-v2.1` - Add --limit and --no-workflow flag support

### Supporting Changes
- `.claude/commands/cig-status.md` - Simple invocation update (no conditionals)

## Implementation Steps

### Step 1: Study Existing status-aggregator Architecture
- [ ] Read `.cig/scripts/command-helpers/status-aggregator` to understand current trampoline logic
- [ ] Read `.cig/scripts/command-helpers/status-aggregator-v2.0` to understand version-specific implementation
- [ ] Read `.cig/scripts/command-helpers/status-aggregator-v2.1` to understand version-specific implementation
- [ ] Identify existing argument parsing patterns
- [ ] Document baseline behavior for comparison

### Step 2: Implement Argument Parsing in status-aggregator Trampoline
- [ ] Open `.cig/scripts/command-helpers/status-aggregator` for editing
- [ ] Add argument parsing logic to separate flags from task paths
- [ ] Detect --workflow, --no-workflow, --limit=N, --sort=modified flags
- [ ] Extract task path from non-flag arguments
- [ ] Preserve existing version detection logic

### Step 3: Implement Intelligent Defaults in status-aggregator Trampoline
- [ ] Add default behavior detection logic
- [ ] If task path provided AND no explicit --workflow/--no-workflow → Apply --workflow default
- [ ] If no arguments AND no explicit flags → Apply --sort=modified --limit=5 defaults
- [ ] If explicit flags provided → Use them (override defaults)
- [ ] Pass final flags to version-specific script

### Step 4: Implement --limit Flag in status-aggregator-v2.0
- [ ] Open `.cig/scripts/command-helpers/status-aggregator-v2.0` for editing
- [ ] Add --limit=N flag parsing
- [ ] Implement limiting logic (count top-level tasks only, not subtasks or workflow files)
- [ ] Apply limit after sorting, before output
- [ ] Test with various values (--limit=5, --limit=10, --limit=1)

### Step 5: Implement --limit Flag in status-aggregator-v2.1
- [ ] Open `.cig/scripts/command-helpers/status-aggregator-v2.1` for editing
- [ ] Add --limit=N flag parsing
- [ ] Implement limiting logic (count top-level tasks only, not subtasks or workflow files)
- [ ] Apply limit after sorting, before output
- [ ] Test with various values (--limit=5, --limit=10, --limit=1)

### Step 6: Implement --no-workflow Flag in status-aggregator-v2.0
- [ ] Add --no-workflow flag parsing in status-aggregator-v2.0
- [ ] Suppress workflow breakdown when flag present
- [ ] Test with task path + --no-workflow (should show tree only)

### Step 7: Implement --no-workflow Flag in status-aggregator-v2.1
- [ ] Add --no-workflow flag parsing in status-aggregator-v2.1
- [ ] Suppress workflow breakdown when flag present
- [ ] Test with task path + --no-workflow (should show tree only)

### Step 8: Update cig-status.md Command File
- [ ] Open `.claude/commands/cig-status.md` for editing
- [ ] Line 4: Change `status-aggregator.pl` to `status-aggregator`
- [ ] Line 8: Replace with simple `status-aggregator $ARGUMENTS` (no conditionals)
- [ ] Lines 30-32: Update documentation to explain intelligent defaults
- [ ] Verify no conditional logic in command file

### Step 9: Integration Testing - Default Behavior
- [ ] Test `/cig-status` (no argument) - should show 5 recent tasks, no workflow
- [ ] Test `/cig-status 26` (task path) - should show tree + workflow breakdown
- [ ] Test `/cig-status 1.1` (nested task) - should show tree + workflow breakdown
- [ ] Verify defaults applied correctly

### Step 10: Integration Testing - Explicit Flags
- [ ] Test `status-aggregator --no-workflow 26` - should show tree only
- [ ] Test `status-aggregator --workflow` - should show all tasks with workflow
- [ ] Test `status-aggregator --limit=10` - should show 10 recent tasks
- [ ] Test `status-aggregator --limit=10 --workflow` - should show 10 tasks with workflow
- [ ] Verify explicit flags override defaults

### Step 11: Edge Case Testing
- [ ] Test with non-existent task: `/cig-status 999` - graceful error
- [ ] Test with v2.0 task - should show 8 workflow files
- [ ] Test with empty project - graceful handling
- [ ] Test with exactly 5 tasks - all shown, no truncation

### Step 12: Performance Validation
- [ ] Time execution: `/cig-status` (should be <500ms for 24 tasks)
- [ ] Time execution: `/cig-status 26` (should be <500ms)
- [ ] Verify no performance degradation from baseline

### Step 13: Documentation and Cleanup
- [ ] Update this implementation plan status to "Finished"
- [ ] Document any deviations from design in "Actual Results"
- [ ] Note any edge cases discovered during testing
- [ ] Prepare for testing phase transition

## Code Changes

### Change 1: cig-status.md - allowed-tools (Line 4)
**Before:**
```markdown
allowed-tools: Read, Bash(.cig/scripts/command-helpers/hierarchy-resolver.pl:*), Bash(.cig/scripts/command-helpers/status-aggregator.pl:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
```

**After:**
```markdown
allowed-tools: Read, Bash(.cig/scripts/command-helpers/hierarchy-resolver.pl:*), Bash(.cig/scripts/command-helpers/status-aggregator:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
```

**Changes:**
- `status-aggregator.pl` → `status-aggregator` (use trampoline entry point)
- No `Bash(head:*)` needed (no command-side filtering)

---

### Change 2: cig-status.md - Context Call (Line 8)
**Before:**
```markdown
- Task hierarchy with progress: !`.cig/scripts/command-helpers/status-aggregator.pl 2>/dev/null || echo "Unable to load status"`
```

**After:**
```markdown
- Task hierarchy with progress: !`.cig/scripts/command-helpers/status-aggregator $ARGUMENTS 2>/dev/null || echo "Unable to load status"`
```

**Changes:**
- `status-aggregator.pl` → `status-aggregator` (use trampoline)
- Add `$ARGUMENTS` (forward user arguments to script)
- **NO conditionals** - script handles defaults
- Preserved error fallback: `|| echo "Unable to load status"`

**Rationale:**
- All conditional logic moved to status-aggregator script
- Avoids Claude Code permission issues with complex bash conditionals
- Simple, maintainable command file

---

### Change 3: cig-status.md - Documentation (Lines 30-32)
**Before:**
```markdown
### 2. Calculate Progress with status-aggregator.pl
- Call `status-aggregator.pl [task-path]` to get progress calculations
```

**After:**
```markdown
### 2. Calculate Progress with status-aggregator
- **With task argument**: Calls `status-aggregator [task-path]` (auto-enables --workflow)
- **Without task argument**: Calls `status-aggregator` (auto-enables --sort=modified --limit=5)
- Use explicit flags (--workflow, --no-workflow, --limit=N) to override defaults
```

**Changes:**
- Updated script name: `status-aggregator.pl` → `status-aggregator`
- Documented intelligent default behavior
- Documented explicit flag controls for overriding defaults

---

### Change 4: status-aggregator - Argument Parsing and Intelligent Defaults
**File:** `.cig/scripts/command-helpers/status-aggregator`

**New Logic to Add:**
```perl
# Argument parsing (pseudo-code)
Parse @ARGV → Separate flags from task paths
Extract: --workflow, --no-workflow, --limit=N, --sort=modified, task_path

# Intelligent defaults (pseudo-code)
if (task_path AND NOT explicit --workflow/--no-workflow) {
    Apply --workflow default
}
elsif (NOT task_path AND NOT explicit flags) {
    Apply --sort=modified --limit=5 defaults
}
# If explicit flags provided, use them (override defaults)

# Version detection (existing logic preserved)
Detect version → Exec status-aggregator-v2.x with final flags
```

**Rationale:**
- Centralizes all conditional logic in one place
- Provides intelligent defaults based on context
- Explicit flags always override defaults ("tools, not philosophies")

---

### Change 5: status-aggregator-v2.0 and v2.1 - --limit Flag
**Files:** `.cig/scripts/command-helpers/status-aggregator-v2.0`, `status-aggregator-v2.1`

**New Logic to Add:**
```perl
# Flag parsing (pseudo-code)
if (--limit=N flag present) {
    limit = N
}

# Limiting logic (pseudo-code)
Count top-level tasks only (not subtasks, not workflow files)
After sorting, output only first N top-level tasks
Within each top-level task:
  - Still show all subtasks (1.1, 1.1.1, etc.)
  - Still show all workflow files if --workflow enabled
```

**Rationale:**
- --limit applies to tasks only (Task 1, Task 26), not subtasks or workflow files
- More efficient than piping to head (internal logic)

---

### Change 6: status-aggregator-v2.0 and v2.1 - --no-workflow Flag
**Files:** `.cig/scripts/command-helpers/status-aggregator-v2.0`, `status-aggregator-v2.1`

**New Logic to Add:**
```perl
# Flag parsing (pseudo-code)
if (--no-workflow flag present) {
    suppress_workflow = true
}

# Workflow suppression (pseudo-code)
if (suppress_workflow OR NOT --workflow) {
    Skip workflow file breakdown
    Output tree view only
}
```

**Rationale:**
- Provides explicit control to disable workflow breakdown
- Overrides intelligent defaults when needed

## Test Coverage
**See f-testing-plan.md for complete test plan**

Key test areas covered in testing phase:
1. **Intelligent Defaults**: Verify automatic --workflow for task paths, automatic --limit=5 for no args
2. **Explicit Flags**: Verify --workflow, --no-workflow, --limit=N flags override defaults
3. **Output Limiting**: Verify --limit applies to tasks only (not subtasks or workflow files)
4. **Sorting**: Verify --sort=modified produces recent-first ordering
5. **Version Detection**: Verify v2.0 (8 files) and v2.1 (10 files) workflow display
6. **Error Handling**: Verify graceful degradation on script failure
7. **Performance**: Verify <500ms response time for 24 tasks

## Validation Criteria
**See f-testing-plan.md for detailed validation criteria and test results**

Pre-execution validation (during implementation):
- [ ] All 6 code changes match design specification
- [ ] Command file has NO conditional logic (simple invocation only)
- [ ] status-aggregator implements argument parsing correctly
- [ ] status-aggregator implements intelligent defaults correctly
- [ ] Version-specific scripts implement --limit flag correctly
- [ ] Version-specific scripts implement --no-workflow flag correctly
- [ ] Error handling preserved from original implementation
- [ ] No regressions introduced (existing behavior preserved)

Post-execution validation (manual testing):
- [ ] `/cig-status` shows maximum 5 tasks, no workflow breakdown (default behavior)
- [ ] `/cig-status 26` shows tree + workflow breakdown for task 26 (default behavior)
- [ ] `status-aggregator --no-workflow 26` shows tree only (explicit override)
- [ ] `status-aggregator --limit=10` shows 10 tasks (explicit override)
- [ ] Tasks sorted by modification time (most recent first)
- [ ] Performance <500ms for both invocation patterns
- [ ] v2.0 and v2.1 tasks display correct number of workflow files
- [ ] --limit counts top-level tasks only (not subtasks or workflow files)

## Status
**Status**: Finished
**Next Action**: Proceed to implementation execution → `/cig-implementation-exec 26`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
