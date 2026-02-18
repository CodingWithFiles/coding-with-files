# fix var use in commands to avoid bash issues - Design
**Task**: 47 (bugfix)

## Task Reference
- **Task ID**: internal-47
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/47-fix-var-use-in-commands-to-avoid-bash-issues
- **Template Version**: 2.1

## Goal
Define systematic replacement strategy to standardize all placeholder syntax to `{placeholder}` style across 17 CIG command files, eliminating patterns that encourage LLM bash wrapper generation.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Replacement Strategy
- **Decision**: Systematic file-by-file replacement using Edit tool with explicit old_string/new_string pairs
- **Rationale**: Edit tool ensures exact replacements with verification, safer than sed/awk for critical command files
- **Trade-offs**:
  - **Benefit**: Explicit, reviewable changes with clear before/after
  - **Benefit**: No risk of regex overmatch destroying valid syntax
  - **Drawback**: More verbose than bulk find-replace, but correctness prioritized

### Placeholder Syntax Standard
- **Decision**: Adopt `{placeholder}` style as the single consistent pattern
- **Rationale**:
  - Curly braces clearly indicate substitution point to LLMs
  - Not valid bash syntax (prevents LLM from treating as shell variables)
  - Distinct from HTML `<tags>` and shell `$variables`
- **Trade-offs**:
  - **Benefit**: Unambiguous, LLM-friendly, doesn't trigger bash expansion instincts
  - **Benefit**: Consistent with common templating conventions (Jinja, Mustache patterns)
  - **Drawback**: None identified

## Replacement Mappings
### Pattern Type 1: `$VARIABLE` → `{variable}`
Common `$VARIABLE` patterns found across command files:
- `$ARGUMENTS` → `{arguments}` (command arguments/input)
- `$TYPE` → `{type}` (task type: feature/bugfix/hotfix/chore)
- `$TASK_DIR` → `{task-dir}` (task directory path)
- `$NUM` → `{num}` (task number)
- `$DESCRIPTION` → `{description}` (task description)
- `$BRANCH_NAME` → `{branch-name}` (git branch name)
- `$TASK_PATH` → `{task-path}` (hierarchical task identifier)

### Pattern Type 2: `<placeholder>` → `{placeholder}`
Found primarily in frontmatter `argument-hint` fields:
- `<task-path>` → `{task-path}`
- `<num>` → `{num}`
- `<type>` → `{type}`
- `<description>` → `{description}`
- `<parent-path>` → `{parent-path}`
- `<section-name>` → `{section-name}`

### Pattern Type 3: Prose in Bash Blocks
**Identification**: Markdown formatting (`**Note**:`, `*italics*`, list markers) inside ```bash blocks
**Strategy**: Move explanatory prose outside code block, keep only executable bash
**Example**:
```
Before:
```bash
git checkout -b "$BRANCH_NAME"
**Note**: This creates the branch
```

After:
```bash
git checkout -b "{branch-name}"
```
**Note**: This creates the branch
```

### Execution Flow
1. **Audit phase**: Use Grep to find ALL `$VAR` and `<placeholder>` patterns, catalog occurrences
2. **Replacement phase**: Process each file using Edit tool with explicit mappings
3. **Verification phase**: Re-run Grep searches, confirm zero matches for old patterns
4. **Validation phase**: Manually execute 3-5 commands to verify no permission prompts

## File Processing Order
### Priority 1: High-Traffic Commands (Process First)
Files most frequently invoked by users/agents:
1. `cig-new-task.md` - Task creation (uses `$ARGUMENTS`, `$TYPE`, `$TASK_DIR`, `$NUM`, `$DESCRIPTION`, `$BRANCH_NAME`)
2. `cig-task-plan.md` - Planning phase
3. `cig-implementation-exec.md` - Implementation execution
4. `cig-testing-exec.md` - Testing execution
5. `cig-retrospective.md` - Retrospective phase

### Priority 2: Workflow Commands
Remaining workflow step commands:
6. `cig-design-plan.md`
7. `cig-implementation-plan.md`
8. `cig-testing-plan.md`
9. `cig-requirements-plan.md`
10. `cig-rollout.md`
11. `cig-maintenance.md`

### Priority 3: Utility Commands
Supporting/utility commands:
12. `cig-status.md`
13. `cig-subtask.md`
14. `cig-extract.md`
15. `cig-config.md`
16. `cig-security-check.md`

Total: 16 files (not 17 - recount confirms 16 cig-*.md files)

## Edge Cases & Special Handling
### Legitimate Bash Examples
**Pattern**: Bash code blocks demonstrating actual shell variable usage (teaching examples)
**Strategy**: Preserve if clearly marked as educational examples, otherwise replace
**Example**: Documentation showing "bash uses `$HOME` for home directory" should remain unchanged

### Quoted vs Unquoted Placeholders
**Pattern**: Some placeholders appear in quotes (`"$TYPE"`), others unquoted (`$TYPE`)
**Strategy**: Replace quoted placeholders with quoted braces (`"{type}"`), preserve quoting context

### Command Substitution Context
**Pattern**: Placeholders in command substitution like `git branch "$(git rev-parse ...)"`
**Strategy**: These are actual bash, not placeholders - DO NOT CHANGE

## Constraints
### Backward Compatibility
- **Constraint**: Must preserve exact command functionality
- **Impact**: Placeholder changes are cosmetic only, no behavior modification
- **Validation**: Commands must execute identically before/after changes

### Safety Requirements
- **Constraint**: Zero tolerance for breaking command files
- **Impact**: Use Edit tool (explicit old_string/new_string) rather than risky regex replacements
- **Validation**: Each replacement verified before moving to next file

### Scope Limitation
- **Constraint**: Only change placeholder syntax, no refactoring or feature additions
- **Impact**: Do not "improve" command structure, logic, or documentation while making changes
- **Validation**: Git diff should show only placeholder pattern changes

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** - Estimated 2-3 hours
- [ ] **People**: Does this need >2 people working on different parts? **NO** - Single-person mechanical task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **NO** - Single concern: placeholder standardization
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** - Low risk with Edit tool safety
- [ ] **Independence**: Can parts be worked on separately? **NO** - Better done atomically for consistency

**Decision**: No decomposition needed (0/5 signals triggered) - proceed as single implementation task

## Validation Strategy
### Pre-Implementation Validation
- [ ] Audit complete: All `$VARIABLE` and `<placeholder>` patterns cataloged
- [ ] Replacement mappings verified against actual usage in command files
- [ ] Edge cases identified (legitimate bash examples, command substitution)

### Post-Implementation Validation
- [ ] Grep verification: Zero `$VARIABLE` patterns remaining (except legitimate bash examples)
- [ ] Grep verification: Zero `<placeholder>` patterns remaining in argument-hint fields
- [ ] Manual execution: Test 3-5 representative commands:
  - `/cig-new-task 99 feature "test feature"` - Verify task creation works
  - `/cig-task-plan 99` - Verify workflow command works
  - `/cig-status` - Verify utility command works
- [ ] Git diff review: Only placeholder syntax changed, no logic modifications

## Status
**Status**: Finished
**Next Action**: /cig-implementation-plan 47 (bugfix workflow: design → implementation-plan → implementation-exec)
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
