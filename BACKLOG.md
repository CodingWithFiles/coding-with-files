# CIG System Backlog

Future tasks and improvements for the Code Implementation Guide system.

---

## Task: Rollout Task 11 - Secure Argument Parsing

**Task-Type**: chore
**Priority**: High

Deploy the updated CIG command files with secure argument parsing pattern. All 8 workflow commands (cig-plan, cig-requirements, cig-design, cig-implementation, cig-testing, cig-rollout, cig-maintenance, cig-retrospective) have been updated with LLM-level format validation to prevent command injection. Changes are currently on local branch `bugfix/11-only-pass-needed-args-to-scripts`. Rollout involves creating PR, merging to main, and monitoring for any issues in production usage.

---

## Task: Security Review and Hardening of CIG Bash Invocations

**Task-Type**: discovery
**Priority**: Medium

Comprehensive security review and hardening of all bash invocations in the CIG system to prevent command injection vulnerabilities. Task 11 revealed that LLM-level validation is critical for security.

**Scope**:
1. **Systematic review**: Audit all command files (`.claude/commands/cig-*.md`), helper scripts, and workflow documentation for places where user input reaches bash
2. **Fix vulnerabilities**: Apply secure argument parsing pattern to any vulnerable commands (known candidates: cig-subtask.md, cig-status.md)
3. **Complete testing**: Run TC-8 testing coverage for all commands (8 workflow commands + cig-subtask + cig-status) with special character patterns (quotes, backticks, shell metacharacters)
4. **Document threat model**: Create comprehensive threat model with attack scenarios, existing defenses, and mitigation strategies

**Related to**: Task 11 (secure argument parsing pattern implementation)

---

## Task: Extract CIG Argument Validation Pattern to Documentation

**Task-Type**: feature
**Priority**: Needs-Triage

Create reusable documentation for the secure argument parsing pattern developed in Task 11. This pattern (LLM validates format → extracts arguments → invokes bash with literals) prevents command injection and handles arbitrary user input safely. Should be documented in `.cig/docs/` for use in future CIG commands or similar systems. Include: (1) Security model explanation, (2) Format validation regex patterns, (3) Example implementation, (4) Test scenarios.

---

## Task: Standardize Exit Codes to errno-Style Values

**Task-Type**: chore
**Priority**: Low

Consolidate exit codes across all CIG helper scripts to use errno-compatible values for better semantic meaning and consistency. Currently, exit codes are inconsistent across scripts (e.g., exit 3 means "Missing required argument" in hierarchy-resolver.pl but "No parent tasks" in context-inheritance.pl). Proposed standard:
- 0 = Success
- 2 = ENOENT (No such file or directory) - for "not found" errors
- 13 = EACCES (Permission denied) - for permission errors
- 22 = EINVAL (Invalid argument) - for validation errors

Scripts to update: hierarchy-resolver.pl, context-inheritance.pl, status-aggregator.pl, format-detector.pl, template-version-parser.sh, and any future helper scripts. Update documentation in script headers and `.cig/docs/` to reflect standard.

---

## Task: Improve status-aggregator.pl Error Message Clarity

**Task-Type**: chore
**Priority**: Low

Improve error message in `status-aggregator.pl` to clarify that it expects a task number (e.g., "17", "1.2.3"), not a full file path. Current error "Invalid task path format: 17-feature-new-helper-script-to-setup-templates-for-new-task" is confusing because users might provide the directory name or full path. Updated error should say something like "Error: Invalid task number format. Expected decimal notation (e.g., '17', '1.2', '1.2.3'), not a file path or directory name." This improves usability by helping users understand the correct input format immediately.

---

## Task: Fix d-implementation.md Template to Reference e-testing.md

**Task-Type**: chore
**Priority**: Low

Remove duplicate "Test Coverage" and "Validation Criteria" sections from d-implementation.md template and replace with static reference to e-testing.md. Currently the d-implementation.md template (`.cig/templates/pool/d-implementation.md.template`) contains:
1. **Line 67-70**: "Test Coverage" section with placeholder test cases
2. **Line 72-76**: "Validation Criteria" section with test-related checkboxes

**Problem**: This creates confusion about where tests belong and duplicates content between d-implementation.md and e-testing.md. The testing phase (e-testing.md) should be the single source of truth for test strategy, test cases, and validation criteria.

**Solution**:
1. Verify all 5 task types (feature, bugfix, hotfix, chore, discovery) use e-testing.md.template (VERIFIED: all include it)
2. Replace "Test Coverage" section with: "**See e-testing.md for complete test plan**"
3. Replace "Validation Criteria" with: "**See e-testing.md for validation criteria and test results**"
4. Keep "Implementation Steps" as-is (includes Step 3: Testing and Step 5: Validation which reference executing the tests defined in e-testing.md)
5. Update any existing tasks using the old template pattern (consider migration script or manual update)

**Rationale**: Maintains single source of truth for testing, eliminates confusion about workflow phase responsibilities, and follows DRY principle.

---

## Task: Use Hierarchical Numbering for Sub-steps in Workflow Templates

**Task-Type**: chore
**Priority**: Medium

Update all workflow command files to use hierarchical numbering (e.g., 9.1, 9.2, 9.3) for sub-steps instead of restarting at 1 within each main step. This eliminates ambiguity when reading the workflow structure.

**Problem**: Current workflow templates use patterns like:
```markdown
9. **Update BACKLOG.md**:

1. **Check for completed BACKLOG items**:
2. **Check retrospective for new items**:
3. **Stage changes if BACKLOG.md modified**:
```

This creates ambiguity - when you see "1." it's unclear whether it's:
- A top-level workflow step
- A sub-step of step 9

**Solution**: Use hierarchical numbering:
```markdown
9. **Update BACKLOG.md**:

9.1. **Check for completed BACKLOG items**:
9.2. **Check retrospective for new items**:
9.3. **Stage changes if BACKLOG.md modified**:
```

**Scope**: Update all 8 workflow command files:
- `.claude/commands/cig-plan.md`
- `.claude/commands/cig-requirements.md`
- `.claude/commands/cig-design.md`
- `.claude/commands/cig-implementation.md`
- `.claude/commands/cig-testing.md`
- `.claude/commands/cig-rollout.md`
- `.claude/commands/cig-maintenance.md`
- `.claude/commands/cig-retrospective.md`

**Rationale**: Hierarchical numbering makes the document structure immediately clear and eliminates parsing ambiguity when scanning the workflow steps.

---

## Task: Add "Blocked" to Standard Status Values

**Task-Type**: feature
**Priority**: Medium

Add "Blocked" as a standard status value to the CIG workflow system to better represent tasks that are stopped due to dependencies, external factors, or other blockers.

**Problem**: Currently, there's no clear status to indicate when a task cannot proceed due to external factors. Users must choose between:
- "In Progress" (inaccurate - work has stopped)
- "Backlog" (inaccurate - work has started but is now blocked)
- Using "Blockers" field with another status (unclear in status reports)

**Solution**: Add "Blocked" as a valid status value alongside existing values (Backlog, In Progress, Finished, etc.).

**Scope**:
1. Update `.cig/docs/workflow/workflow-steps.md#status-values` to include "Blocked"
2. Update `status-aggregator.pl` to handle "Blocked" status in progress calculations
3. Update all workflow command files to mention "Blocked" as valid status
4. Define semantics: "Blocked" means work has started but cannot proceed until blocker is resolved
5. Update workflow templates to include guidance on when to use "Blocked"

**Rationale**: Explicit "Blocked" status improves task visibility and makes it clear when tasks need external intervention to proceed.

---

## Task: Update cig-status to Use --workflow Flag

**Task-Type**: feature
**Priority**: Medium

Update `.claude/commands/cig-status.md` to use `status-aggregator.pl --workflow <task-path>` for detailed workflow phase visibility when showing a specific task.

**Problem**: Currently, cig-status shows overall progress percentage but doesn't break down which workflow phases (a-plan, b-requirements, c-design, etc.) are completed vs pending. The status-aggregator.pl script already supports a `--workflow` flag that provides this detailed view, but cig-status doesn't use it.

**Solution**: Update cig-status command to:
1. Use `status-aggregator.pl <task-path>` for hierarchical tree view (current behavior)
2. Use `status-aggregator.pl --workflow <task-path>` for detailed workflow phase breakdown when showing a single task
3. Display both views for single-task queries to provide comprehensive status

**Example output**:
```
Task Progress:
+ 21 (feature): retrospective-structure-and-flow-improvments - 25%

Workflow Status:
  ✓ a-plan.md: Finished
  ○ b-requirements.md: Backlog
  ○ c-design.md: Backlog
  ○ d-implementation.md: Backlog
  ...
```

**Scope**:
- Update `.claude/commands/cig-status.md` to call status-aggregator.pl with --workflow flag
- Add workflow status display to output format
- Update documentation and examples

**Rationale**: Provides better visibility into which specific workflow phases are complete, making it easier to understand task progress and identify next steps.

---

## Task: Implement Current Task Tracking

**Task-Type**: feature
**Priority**: High

Implement a system to track the "current task" being worked on, allowing CIG commands and scripts to default to this task when no task number is explicitly provided.

**Problem**: Currently, all cig-* workflow commands require explicit task numbers (e.g., `/cig-implementation 21`). This becomes repetitive when working on the same task through multiple workflow phases. Users must remember and re-type the task number for each command.

**Solution**: Track the current task in a deterministic location that both LLM prompts and helper scripts can read.

**Design Considerations**:

1. **Storage Location**:
   - Option A: `.cig/current-task` (simple text file with task number)
   - Option B: Add to `cig-project.json` config
   - Recommendation: `.cig/current-task` for simplicity and determinism

2. **File Format**:
   ```
   21
   ```
   (Just the task number, one line, no formatting)

3. **Git Handling**:
   - Add `.cig/current-task` to `.gitignore` (user-specific workspace state)
   - Each developer can work on different tasks

4. **Commands Needed**:
   - Automatic: Set current task when running `/cig-new-task` or `/cig-subtask`
   - Manual: `/cig-current [task-path]` - set/view/clear current task
   - All workflow commands default to current task if no argument provided

5. **Workflow Command Updates**:
   All 8 workflow commands should:
   - Check if argument provided → use it (and set as current task)
   - If no argument → read `.cig/current-task`
   - If neither → error with helpful message
   - **Automatic current task setting**: When any workflow command is invoked with an explicit task number, set that as the current task
   - **Special case**: `/cig-retrospective` should clear current task after successful completion (task is finished)

6. **Script Integration**:
   Helper scripts can read `.cig/current-task` for deterministic current task value

**Scope**:
- Create `.cig/current-task` tracking mechanism
- Add `.cig/current-task` to `.gitignore`
- Create `/cig-current` command for manual set/view/clear
- Update `/cig-new-task` to set current task automatically
- Update `/cig-subtask` to set current task automatically
- Update all 8 workflow commands (cig-plan, cig-requirements, cig-design, cig-implementation, cig-testing, cig-rollout, cig-maintenance, cig-retrospective) to use current task as default
- Update `/cig-status` to highlight current task in output
- Document current task tracking in `.cig/docs/`

**Example Usage**:
```bash
# Create new task and it becomes current
/cig-new-task 22 feature "Add export functionality"

# Work through workflow without repeating task number
/cig-plan           # Uses task 22
/cig-requirements   # Uses task 22
/cig-design         # Uses task 22
/cig-implementation # Uses task 22
/cig-testing        # Uses task 22

# Check current task
/cig-current        # Shows: Current task: 22

# Switch to different task
/cig-current 21     # Now working on task 21

# Clear current task
/cig-current --clear
```

**Benefits**:
- Reduces repetition when working through workflow phases
- Improves UX by making commands more ergonomic
- Deterministic storage ensures scripts can reliably use current task
- Automatic tracking on task creation reduces manual steps

**Rationale**: Current task tracking significantly improves developer experience by eliminating repetitive task number arguments while maintaining deterministic behavior for scripts.

---

## Task: Fix CIG Commands to Work from Any Directory

**Task-Type**: bugfix
**Priority**: High

Fix CIG workflow commands to work regardless of current working directory. Currently, commands fail when executed from subdirectories because they use relative paths (`.cig/scripts/...`) that only work from repository root.

**Problem**: When working in a task subdirectory (e.g., `implementation-guide/21-feature-...`), running `/cig-new-task` or other commands fails with:
```
Error: .cig/scripts/command-helpers/cig-load-project-config: No such file or directory
```

This breaks the workflow when Claude is in a task directory after completing previous phases.

**Solution Options**:

**Option A: Dynamic Git Root Detection**
- Commands find git root dynamically using `git rev-parse --show-toplevel`
- Convert all relative paths to absolute paths based on git root
- Pros: Works from any directory, no directory changes needed
- Cons: Requires git, adds complexity to every command

**Option B: Explicit CD to Git Root**
- Commands explicitly `cd` to git root at start
- Echo new working directory so LLM maintains context
- Pros: Simple, matches existing relative path assumptions
- Cons: Changes working directory (must communicate to LLM)

**Recommended Approach**: Option B with clear communication
```bash
# At start of each CIG command
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository"
    exit 1
fi

cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"
```

**Scope**:
- Update all CIG workflow commands (cig-plan, cig-requirements, cig-design, cig-implementation, cig-testing, cig-rollout, cig-maintenance, cig-retrospective)
- Update utility commands (cig-new-task, cig-subtask, cig-status, cig-extract, cig-config, cig-init)
- Add git root detection to command templates
- Document working directory behavior in `.cig/docs/`

**Testing**:
- Run commands from repository root (should work as before)
- Run commands from task subdirectories (should work after fix)
- Run commands from outside repository (should fail with clear error)

**Rationale**: CIG commands should work reliably regardless of where Claude's current working directory is, preventing workflow interruptions and improving user experience.
