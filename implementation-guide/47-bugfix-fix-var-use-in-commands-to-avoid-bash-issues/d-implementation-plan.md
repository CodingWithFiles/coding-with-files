# fix var use in commands to avoid bash issues - Implementation Plan
**Task**: 47 (bugfix)

## Task Reference
- **Task ID**: internal-47
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/47-fix-var-use-in-commands-to-avoid-bash-issues
- **Template Version**: 2.1

## Goal
Execute systematic replacement of `$VARIABLE` and `<placeholder>` patterns with `{placeholder}` style across all 17 CIG command files using Edit tool for safety and precision.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### All 17 CIG Command Files (Priority Order)
**High-Traffic Commands (Priority 1)**:
1. `.claude/commands/cig-new-task.md` - Replace `$ARGUMENTS`, `$TYPE`, `$TASK_DIR`, `$NUM`, `$DESCRIPTION`, `$BRANCH_NAME` + frontmatter `<num>`, `<type>`, `<description>`
2. `.claude/commands/cig-task-plan.md` - Replace `$ARGUMENTS` + frontmatter `<task-path>`
3. `.claude/commands/cig-implementation-exec.md` - Replace `$ARGUMENTS` + frontmatter `<task-path>`
4. `.claude/commands/cig-testing-exec.md` - Replace `$ARGUMENTS` + frontmatter `<task-path>`
5. `.claude/commands/cig-retrospective.md` - Replace `$ARGUMENTS` + frontmatter `<task-path>`

**Workflow Commands (Priority 2)**:
6. `.claude/commands/cig-design-plan.md` - Replace `$ARGUMENTS` + frontmatter `<task-path>`
7. `.claude/commands/cig-implementation-plan.md` - Replace `$ARGUMENTS` + frontmatter `<task-path>`
8. `.claude/commands/cig-testing-plan.md` - Replace `$ARGUMENTS` + frontmatter `<task-path>`
9. `.claude/commands/cig-requirements-plan.md` - Replace `$ARGUMENTS` + frontmatter `<task-path>`
10. `.claude/commands/cig-rollout.md` - Replace `$ARGUMENTS` + frontmatter `<task-path>`
11. `.claude/commands/cig-maintenance.md` - Replace `$ARGUMENTS` + frontmatter `<task-path>`

**Utility Commands (Priority 3)**:
12. `.claude/commands/cig-status.md` - Replace `$ARGUMENTS` + frontmatter patterns
13. `.claude/commands/cig-subtask.md` - Replace `$ARGUMENTS` + frontmatter `<parent-path>`, `<num>`, `<type>`, `<description>`
14. `.claude/commands/cig-extract.md` - Replace `$ARGUMENTS` + frontmatter `<task-path>`, `<section-name>`
15. `.claude/commands/cig-config.md` - Replace `$ARGUMENTS` + frontmatter patterns
16. `.claude/commands/cig-security-check.md` - Replace `$ARGUMENTS` + frontmatter patterns
17. `.claude/commands/cig-init.md` - Replace any placeholder patterns found

### Documentation (if needed)
- `.cig/docs/conventions/placeholder-syntax.md` - Create if standardization needs documentation

## Implementation Steps
### Step 1: Pre-Implementation Audit
- [ ] Run Grep to catalog all `$VARIABLE` patterns: `grep -n '\$[A-Z_]*' .claude/commands/cig-*.md`
- [ ] Run Grep to catalog all `<placeholder>` patterns: `grep -n '<[a-z-]*>' .claude/commands/cig-*.md`
- [ ] Document baseline counts for verification (expect ~50-100 total occurrences)
- [ ] Review edge cases: Check for legitimate bash variable examples that should be preserved

### Step 2: Replace High-Traffic Commands (Priority 1)
Process files 1-5 using Edit tool with explicit old_string/new_string pairs:

**File 1: cig-new-task.md**
- [ ] Frontmatter: `argument-hint: <num> <type> "description"` → `argument-hint: {num} {type} "description"`
- [ ] Body: `$ARGUMENTS` → `{arguments}` (appears in "Your task" section)
- [ ] Body: `$TYPE` → `{type}` (in task-workflow create example)
- [ ] Body: `$TASK_DIR` → `{task-dir}` (in task-workflow create example)
- [ ] Body: `$NUM` → `{num}` (in task-workflow create example)
- [ ] Body: `$DESCRIPTION` → `{description}` (in task-workflow create example)
- [ ] Body: `"$BRANCH_NAME"` → `"{branch-name}"` (preserve quotes)

**Files 2-5: Workflow commands (task-plan, implementation-exec, testing-exec, retrospective)**
- [ ] Each file: Frontmatter `<task-path>` → `{task-path}`
- [ ] Each file: Body `$ARGUMENTS` → `{arguments}`
- [ ] Verify no prose inside bash blocks, move if found

### Step 3: Replace Workflow Commands (Priority 2)
Process files 6-11 (design-plan, implementation-plan, testing-plan, requirements-plan, rollout, maintenance):
- [ ] Each file: Frontmatter `<task-path>` → `{task-path}`
- [ ] Each file: Body `$ARGUMENTS` → `{arguments}`
- [ ] Scan for any additional `$VARIABLE` patterns unique to these files

### Step 4: Replace Utility Commands (Priority 3)
Process files 12-17 (status, subtask, extract, config, security-check, init):
- [ ] cig-subtask.md: Frontmatter `<parent-path> <num> <type> "description"` → `{parent-path} {num} {type} "description"`
- [ ] cig-extract.md: Frontmatter `<task-path> <section-name>` → `{task-path} {section-name}`
- [ ] All files: Replace `$ARGUMENTS` → `{arguments}`
- [ ] All files: Replace any other `$VARIABLE` or `<placeholder>` patterns found

### Step 5: Post-Implementation Verification
- [ ] Run Grep for `$VARIABLE` patterns: Verify zero matches (except legitimate bash examples if any)
- [ ] Run Grep for `<placeholder>` patterns in argument-hint: Verify zero matches
- [ ] Count files modified: Should be 17 files
- [ ] Git diff review: Verify only placeholder syntax changed, no logic modifications

### Step 6: Manual Validation
- [ ] Test `/cig-new-task 99 feature "test validation"` - Should create task without permission prompts
- [ ] Test `/cig-task-plan 99` - Should open planning without permission prompts
- [ ] Test `/cig-status` - Should show status without errors
- [ ] Delete test task 99: `rm -rf implementation-guide/99-feature-test-validation && git checkout bugfix/47-fix-var-use-in-commands-to-avoid-bash-issues`

## Code Changes
### Example 1: Frontmatter argument-hint Replacement
**Before** (cig-new-task.md):
```markdown
---
description: Create new hierarchical implementation guide
argument-hint: <num> <type> "description"
allowed-tools: Read, Write, Bash(*)
---
```

**After**:
```markdown
---
description: Create new hierarchical implementation guide
argument-hint: {num} {type} "description"
allowed-tools: Read, Write, Bash(*)
---
```

### Example 2: $VARIABLE Replacement in Body
**Before** (cig-new-task.md):
```markdown
Create new hierarchical implementation guide for: **$ARGUMENTS**

...

.cig/scripts/command-helpers/task-workflow create \
  --task-type="$TYPE" \
  --destination="$TASK_DIR" \
  --task-num="$NUM" \
  --description="$DESCRIPTION"
```

**After**:
```markdown
Create new hierarchical implementation guide for: **{arguments}**

...

.cig/scripts/command-helpers/task-workflow create \
  --task-type="{type}" \
  --destination="{task-dir}" \
  --task-num="{num}" \
  --description="{description}"
```

### Example 3: Preserve Quoting Context
**Before**:
```bash
git checkout -b "$BRANCH_NAME"
```

**After**:
```bash
git checkout -b "{branch-name}"
```

**Note**: Quotes preserved around placeholder for proper bash string handling

## Test Coverage
**Testing Strategy**: Manual validation of command execution (no automated test infrastructure needed for documentation changes)

**Test Cases** (see e-testing-plan.md for details):
1. **TC-1**: Grep verification - Zero `$VARIABLE` patterns remaining (except legitimate bash examples)
2. **TC-2**: Grep verification - Zero `<placeholder>` patterns in argument-hint fields
3. **TC-3**: Manual execution - `/cig-new-task 99 feature "test"` creates task without prompts
4. **TC-4**: Manual execution - `/cig-task-plan 99` opens planning without prompts
5. **TC-5**: Manual execution - `/cig-status` shows status without errors
6. **TC-6**: Git diff review - Only placeholder syntax changed, no logic modifications
7. **TC-7**: File count - All 17 command files modified

## Validation Criteria
**Functional Requirements**:
- [ ] All 17 command files use `{placeholder}` style exclusively
- [ ] Commands execute without triggering permission prompts for helper script calls
- [ ] No behavioral changes to command functionality

**Quality Requirements**:
- [ ] Zero `$VARIABLE` patterns remaining (grep verification)
- [ ] Zero `<placeholder>` patterns in argument-hint (grep verification)
- [ ] Git diff shows only placeholder syntax changes
- [ ] Manual test execution: 3 commands tested successfully

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
**Status**: In Progress
**Next Action**: /cig-testing-plan 47 (bugfix workflow: implementation-plan → testing-plan → implementation-exec)
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
