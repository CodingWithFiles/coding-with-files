# CIG System Backlog

Future tasks and improvements for the Code Implementation Guide system.

---

## Task: Separate Planning from Execution Phases with Explicit Execution Commands

**Task-Type**: feature
**Priority**: High

Add explicit execution workflow commands (`cig-implementation-exec` and `cig-testing-exec`) to separate planning phases from execution phases, and formalize blocker-driven workflow reversion.

**Problem**: Current workflow conflates planning and execution within single phases:
- `cig-implementation` mixes implementation planning with actual code writing
- `cig-testing` mixes test strategy definition with actual test execution
- No explicit workflow guidance for handling blockers that require reverting to earlier phases
- Unclear when to actually execute implementation vs when to plan it

**Solution**: Introduce execution-specific workflow commands and formalize iterative workflow with blocker handling.

### New Workflow Order (10 phases):
1. **cig-plan** - High-level planning (goals, milestones, risks)
2. **cig-requirements** - Define functional/non-functional requirements
3. **cig-design** - Architecture and design decisions
4. **cig-implementation** - Implementation planning (files to modify, steps, approach)
5. **cig-testing** - Test strategy and test case definition
6. **cig-implementation-exec** - **NEW**: Execute actual implementation (write code, make changes)
7. **cig-testing-exec** - **NEW**: Execute actual tests (run tests, validate results)
8. **cig-rollout** - Deployment strategy and execution
9. **cig-maintenance** - Ongoing support planning
10. **cig-retrospective** - Capture learnings and commit

### Blocker-Driven Workflow Reversion

**Key Principle**: When any workflow step encounters a blocker, it may need to revert to an earlier workflow step and restart the order to resolve the blocker.

**Examples**:
- **cig-implementation-exec discovers design gap** → Revert to `cig-design`, update design, proceed through cig-implementation → cig-testing → cig-implementation-exec
- **cig-testing-exec reveals missing requirements** → Revert to `cig-requirements`, add requirements, proceed through cig-design → cig-implementation → cig-testing → cig-implementation-exec → cig-testing-exec
- **cig-implementation-exec hits technical blocker** → Revert to `cig-plan`, re-evaluate approach, proceed through full workflow

**Workflow State Machine**:
- **Forward progress**: Each phase can proceed to next phase when complete
- **Backward reversion**: Any phase can revert to earlier phase when blocker encountered
- **Restart from reversion point**: After updating earlier phase, restart workflow from that point (not from current phase)

### New Commands to Create

**cig-implementation-exec**:
- **Purpose**: Execute the implementation following the plan in d-implementation.md
- **Focus**: Writing actual code, making actual file changes, executing implementation steps
- **Workflow**: Read d-implementation.md → Execute each step → Check off implementation steps → Update actual results
- **Blocker handling**: If blocked, identify which earlier phase needs updating (design, requirements, plan)
- **Output**: Working implementation with all implementation steps checked off

**cig-testing-exec**:
- **Purpose**: Execute the tests defined in e-testing.md test strategy
- **Focus**: Running actual tests, validating actual results, capturing test outcomes
- **Workflow**: Read e-testing.md → Execute each test case → Record pass/fail → Update actual results
- **Blocker handling**: If tests fail, determine if implementation needs fixes (→ cig-implementation-exec) or design needs revision (→ cig-design)
- **Output**: Test results with all test cases executed and results recorded

### Changes Required

**1. Command Files** (2 new):
- Create `.claude/commands/cig-implementation-exec.md`
- Create `.claude/commands/cig-testing-exec.md`

**2. Template Files** (2 new):
- Create `.cig/templates/pool/d2-implementation-exec.md.template` (or similar naming)
- Create `.cig/templates/pool/e2-testing-exec.md.template` (or similar naming)
- **Alternative**: Reuse d-implementation.md and e-testing.md but add execution-specific sections

**3. Documentation Updates**:
- Update `.cig/docs/workflow/workflow-steps.md` with:
  - New 10-phase workflow order
  - Implementation vs Implementation-Exec distinction
  - Testing vs Testing-Exec distinction
  - Blocker-driven workflow reversion guidance
  - State machine diagram (forward/backward transitions)

**4. Status Aggregator**:
- Update `status-aggregator.pl` to recognize new workflow files (if separate files used)
- Handle 10-phase workflow instead of 8-phase

**5. Template Symlinks**:
- Update task-type-specific symlinks to include execution phase files
- Feature: 10 files (a-h + d2-implementation-exec + e2-testing-exec)
- Bugfix: 7 files (a, c, d, d2, e, e2, h)
- Hotfix: 7 files (a, d, d2, e, e2, f, h)
- Chore: 6 files (a, d, d2, e, e2, h)

**6. Helper Scripts**:
- Update `template-copier.pl` to handle new file count per task type
- Update workflow step references in all command files

### Design Considerations

**Naming Convention**:
- Option A: `d-implementation.md` (planning) + `d2-implementation-exec.md` (execution)
- Option B: `d-implementation.md` (planning) + `d-implementation-results.md` (execution)
- Option C: Keep single `d-implementation.md` with clear separation of planning vs execution sections
- **Recommendation**: Option A for clear file-level separation

**Backward Compatibility**:
- Existing tasks use 8-phase workflow (a-h)
- New tasks use 10-phase workflow (a-h + d2 + e2)
- `format-detector.pl` can detect which workflow version based on file presence
- Migration path: Existing tasks can stay on 8-phase, new tasks use 10-phase

**Blocker Documentation**:
- Each workflow command file should have "Blocker Handling" section
- Guidance on when to revert to earlier phases
- Examples of common blocker scenarios and appropriate reversion points

### Success Criteria
- [ ] `cig-implementation-exec` command created with execution focus
- [ ] `cig-testing-exec` command created with execution focus
- [ ] 10-phase workflow documented in workflow-steps.md
- [ ] Blocker-driven reversion guidance documented
- [ ] Template files created for execution phases
- [ ] Status aggregator supports 10-phase workflow
- [ ] All 10 workflow commands include blocker handling guidance
- [ ] Backward compatibility maintained for existing 8-phase tasks

**Rationale**: Separating planning from execution provides clearer workflow phases and makes it explicit when to plan vs when to execute. Formalizing blocker-driven reversion acknowledges that software development is iterative and blockers often require revisiting earlier decisions.

---

## Task: Add Active Maintenance Cost Analysis to g-maintenance Template

**Task-Type**: chore
**Priority**: Medium

Update the g-maintenance.md template to require explicit analysis of active maintenance costs versus passive benefits, preventing open-ended future commitments.

**Problem**: Current g-maintenance.md template doesn't distinguish between:
- **Active scheduled tasks**: Work that MUST be done on a regular schedule (maintenance, noun form)
- **Reactive support**: Work that MIGHT be needed IF issues arise
- **Passive benefits**: Value delivered without ongoing work

This leads to proposals for "quarterly reviews" or "monthly checks" without justifying the time commitment. Maintenance is an ongoing cost that needs explicit justification.

**Solution**: Add required section to g-maintenance.md template:

```markdown
## Active Maintenance Requirements

### Scheduled Maintenance Tasks
List tasks that MUST be done on a regular schedule:
- [Task description] - [Frequency] - [Estimated time]

**Total scheduled cost**: [Hours per year]

If NONE: Explicitly state "NONE - no scheduled maintenance required"

### Reactive Maintenance Only
List scenarios where action MIGHT be required (IF/THEN format):
- **IF** [trigger condition] → **THEN** [action] ([estimated time])

**Estimated reactive burden**: [Hours per year, may be zero]

### Cost/Benefit Analysis
**Active costs**: [Scheduled + reactive estimates]
**Benefits**: [Concrete value delivered, if feature used]
**Justification**: [Why ongoing cost is worth it, or why zero cost makes it low-risk]
**Deprecation trigger**: [When would we remove this feature?]
```

**Scope**:
1. Update `.cig/templates/pool/g-maintenance.md.template` with new section
2. Position after "Monitoring Requirements" section, before "Status"
3. Include examples for both scenarios:
   - Example A: Feature with scheduled maintenance (database cleanup, log rotation)
   - Example B: Feature with zero scheduled maintenance (configuration/documentation changes)
4. Update documentation to explain distinction between active/reactive/passive

**Rationale**: Prevents open-ended future commitments by requiring explicit justification of ongoing work. Makes maintenance costs visible upfront, enabling better decisions about feature complexity.

---

## Task: Research and Consolidate Cross-Document Reference Patterns

**Task-Type**: discovery
**Priority**: Medium

Analyse and standardise cross-document reference patterns used throughout CIG system documentation, templates, and command files.

**Problem**: Currently inconsistent patterns for referencing other documents:
- Templates use bold text: `**See e-testing.md for complete test plan**`
- Some locations may use markdown links: `[text](path)`
- Some locations may use HTML comments
- No clear guidelines on when to use which pattern

**Scope**:
1. **Audit existing patterns**: Survey all templates, command files, and documentation for cross-reference patterns
2. **Categorise use cases**: Different contexts may need different patterns (intra-task vs external, LLM-facing vs human-facing)
3. **Define standard patterns**: Establish clear guidelines for each use case
4. **Document rationale**: Explain why each pattern is used (progressive disclosure, readability, tooling support)
5. **Update style guide**: Document patterns in `.cig/docs/` for future reference
6. **Migration plan**: Optionally create plan to standardise existing references

**Examples to analyse**:
- Intra-task references: `d-implementation.md` → `e-testing.md`
- External doc references: Templates → `workflow-steps.md`
- Config references: Command files → `cig-project.json`

**Outcome**: Clear, documented standard for cross-document references that follows DRY and progressive disclosure principles.

---

## Task: Remove Decomposition Checks from Non-Planning Workflow Steps

**Task-Type**: chore
**Priority**: Medium

Remove decomposition check steps from all workflow command files except cig-plan.md, as decomposition decisions should only be made during the planning phase.

**Problem**: Currently, all workflow command files (cig-requirements, cig-design, cig-implementation, cig-testing, cig-rollout, cig-maintenance, cig-retrospective) include "Step 7: Check Decomposition Signals" which:
- Creates confusion about when to decompose tasks
- Adds unnecessary cognitive load during execution phases
- Violates single-responsibility principle (planning decisions during execution)
- Decomposition decisions should be made once during planning, not reconsidered at every workflow step

**Solution**: Remove "Check Decomposition Signals" step from all workflow commands except cig-plan.md

**Scope**:
1. **Audit**: Verify which command files currently include decomposition checks
2. **Update commands**: Remove Step 7 (decomposition checks) from:
   - `.claude/commands/cig-requirements.md`
   - `.claude/commands/cig-design.md`
   - `.claude/commands/cig-implementation.md`
   - `.claude/commands/cig-testing.md`
   - `.claude/commands/cig-rollout.md`
   - `.claude/commands/cig-maintenance.md`
   - `.claude/commands/cig-retrospective.md`
3. **Keep in planning**: Retain decomposition checks in `.claude/commands/cig-plan.md` (where they belong)
4. **Update step numbers**: Renumber subsequent steps after removing Step 7
5. **Update documentation**: Clarify in workflow-steps.md that decomposition is a planning-phase decision

**Rationale**: Decomposition is a planning decision that should be made once upfront, not reconsidered during each workflow phase. This simplifies workflow steps and makes the planning phase the clear decision point for task breakdown.

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
