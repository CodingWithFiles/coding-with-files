# Enhance workflow scope and control instructions - Implementation

## Task Reference
- **Task ID**: internal-28
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/28-enhance-workflow-scope-and-control-instructions
- **Template Version**: 2.0

## Goal
Implement consolidated "Scope & Boundaries" sections in all workflow commands and create workflow-control helper script following approved design.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cig/scripts/command-helpers/workflow-control` - **NEW** helper script to centralize continuation logic
- `.cig/docs/workflow/blocker-patterns.md` - **NEW** centralized blocker handling documentation
- `.claude/commands/cig-task-plan.md` - Add "Scope & Boundaries" section, remove verbose "Blocker Handling"
- `.claude/commands/cig-requirements-plan.md` - Add "Scope & Boundaries" section, remove verbose "Blocker Handling"
- `.claude/commands/cig-design-plan.md` - Add "Scope & Boundaries" section, remove verbose "Blocker Handling"
- `.claude/commands/cig-implementation-plan.md` - Add "Scope & Boundaries" section, remove verbose "Blocker Handling"
- `.claude/commands/cig-implementation-exec.md` - Add "Scope & Boundaries" section, remove verbose "Blocker Handling"
- `.claude/commands/cig-testing-plan.md` - Add "Scope & Boundaries" section, remove verbose "Blocker Handling"
- `.claude/commands/cig-testing-exec.md` - Add "Scope & Boundaries" section, remove verbose "Blocker Handling"
- `.claude/commands/cig-rollout.md` - Add "Scope & Boundaries" section, remove verbose "Blocker Handling"
- `.claude/commands/cig-maintenance.md` - Add "Scope & Boundaries" section, remove verbose "Blocker Handling"
- `.claude/commands/cig-retrospective.md` - Add "Scope & Boundaries" section, remove verbose "Blocker Handling"

### Supporting Changes
- `.cig/security/script-hashes.json` - Add SHA256 hash for new workflow-control script

## Implementation Steps

### Step 1: Create workflow-control Helper Script
- [ ] Create `.cig/scripts/command-helpers/workflow-control` (Perl script)
- [ ] Import CIG common modules: `use CIG::Options`, `use CIG::TaskPath`, `use CIG::MarkdownParser`
- [ ] Implement argument parsing using `CIG::Options::parse` (not manual parsing)
- [ ] Validate task-path format using `CIG::TaskPath::validate` (not manual regex)
- [ ] Resolve task directory using `CIG::TaskPath::resolve` (not external hierarchy-resolver call)
- [ ] Read workflow file and extract status using `CIG::MarkdownParser::extract_status` (not inline grep/regex)
- [ ] Implement status-based logic:
  - [ ] "Finished" → output "ask-user\nSuggest next workflow step"
  - [ ] "Blocked" → output "ask-user\nNeed user feedback on blocker"
  - [ ] Other → output "continue\nIf workflow step complete: update status to 'Finished' and re-run workflow-control. Otherwise: continue this workflow step."
- [ ] Add error handling (task not found, invalid step name, file not readable)
- [ ] Set permissions to 0500 (chmod u+rx)
- [ ] Test script with various status values
- [ ] Verify script imports and uses all 3 CIG modules (AC8)

### Step 2: Create blocker-patterns.md Documentation
- [ ] Create `.cig/docs/workflow/blocker-patterns.md`
- [ ] Extract "Common Blockers" sections from all 10 existing workflow commands
- [ ] Organize by phase (Planning, Requirements, Design, Implementation Planning, Implementation Exec, Testing Planning, Testing Exec, Rollout, Maintenance, Retrospective)
- [ ] Add general reversion guidance section
- [ ] Add decomposition signals section (when blockers indicate task splitting needed)
- [ ] Review for completeness and clarity

### Step 3: Update cig-task-plan.md (Pilot)
- [ ] Read existing `.claude/commands/cig-task-plan.md`
- [ ] Identify location to insert "Scope & Boundaries" (after frontmatter, before "## Context")
- [ ] Add "Scope & Boundaries" section (6 lines max):
  - [ ] "This step": Complete task planning document
  - [ ] "Not this step": Requirements, design, implementation
  - [ ] "If blocked or finished": Reference workflow-control
- [ ] Remove existing verbose "Blocker Handling" section (if present)
- [ ] Update blocker references to point to blocker-patterns.md
- [ ] Verify section is 5-6 lines total
- [ ] Test command: `/cig-task-plan 29` (create test task to validate)

### Step 4: Update Remaining 9 Workflow Commands
- [ ] Update `.claude/commands/cig-requirements-plan.md` (same pattern as Step 3)
- [ ] Update `.claude/commands/cig-design-plan.md` (same pattern as Step 3)
- [ ] Update `.claude/commands/cig-implementation-plan.md` (same pattern as Step 3)
- [ ] Update `.claude/commands/cig-implementation-exec.md` (adjust wording: "Now you write code")
- [ ] Update `.claude/commands/cig-testing-plan.md` (same pattern as Step 3)
- [ ] Update `.claude/commands/cig-testing-exec.md` (adjust wording: "Now you run tests")
- [ ] Update `.claude/commands/cig-rollout.md` (same pattern as Step 3)
- [ ] Update `.claude/commands/cig-maintenance.md` (same pattern as Step 3)
- [ ] Update `.claude/commands/cig-retrospective.md` (same pattern as Step 3)

### Step 5: Update Security Hashes
- [ ] Generate SHA256 hash for workflow-control script: `sha256sum .cig/scripts/command-helpers/workflow-control`
- [ ] Add entry to `.cig/security/script-hashes.json` following existing format

### Step 6: Validation
- [ ] Run workflow-control with test cases (Finished, Blocked, In Progress statuses)
- [ ] Verify all 10 commands have "Scope & Boundaries" in correct location
- [ ] Verify all sections are ≤6 lines
- [ ] Test one complete workflow: create task 29, run through all phases
- [ ] Verify no regressions (existing tasks still work)

## Code Changes

### Before: Verbose Blocker Handling Section (21 lines)
Current state in `.claude/commands/cig-design-plan.md`:
```markdown
## Blocker Handling

**Common Blockers in Design**:
- Multiple design approaches with no clear winner → Create spike task to prototype alternatives
- Design reveals requirements are incomplete/incorrect → Revert to b-requirements-plan.md to clarify
- Technical constraints make all approaches infeasible → Revert to a-task-plan.md to reconsider scope
- Missing expertise to make design decisions → Consult expert or create research subtask
- Design shows task is too complex for one phase → Revert to planning, decompose into subtasks

**Reversion Guidance**:
- If reverting to requirements: Update b-requirements-plan.md with design insights, then redesign
- If reverting to planning: Update a-task-plan.md with new constraints, reconsider approach
- Document the blocker in "Actual Results" section of c-design-plan.md
- Update status to "Blocked" until blocker is resolved
- When blocker resolved, update design with new approach

**When to Revert**:
- Design exploration reveals fundamental requirement gaps
- All considered approaches violate stated constraints
- Design complexity indicates need for task decomposition
```

### After: Concise "Scope & Boundaries" Section (5 lines)
Target state in `.claude/commands/cig-design-plan.md`:
```markdown
## Scope & Boundaries

**This step**: Complete the design planning document (c-design-plan.md) with architecture decisions, component design, and interface specifications.

**Not this step**: Implementation (that's d-implementation-plan + e-implementation-exec), testing, or deployment.

**If blocked or finished**: Call `workflow-control --current-step c-design-plan --task-path <path>` to determine next action. See `.cig/docs/workflow/blocker-patterns.md` for detailed blocker handling guidance.
```

### workflow-control Script Structure (using CIG modules)
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";

use CIG::Options qw(parse);
use CIG::TaskPath qw(validate resolve);
use CIG::MarkdownParser qw(extract_status);

# Parse arguments using CIG::Options
my $opts = parse($spec, @ARGV);

# Validate task-path using CIG::TaskPath::validate
unless (validate($task_path)) { ... }

# Resolve task directory using CIG::TaskPath::resolve
my $task_info = resolve($task_path);

# Extract status using CIG::MarkdownParser::extract_status
my $status = extract_status($workflow_file);

# Return guidance based on status:
#   - Finished → "ask-user\nSuggest next workflow step"
#   - Blocked → "ask-user\nNeed user feedback on blocker"
#   - Other → "continue\n[instruction to update status or continue]"
```

## Test Coverage
**See f-testing-plan.md for complete test plan**

Summary:
- **workflow-control script**: Test with Finished, Blocked, In Progress statuses; test with invalid arguments
- **Workflow commands**: Verify "Scope & Boundaries" section present and ≤6 lines in all 10 commands
- **Integration test**: Run complete workflow (task 29 from planning through retrospective)
- **Regression test**: Verify existing tasks (e.g., task 27) still work correctly

## Validation Criteria
**See f-testing-plan.md for validation criteria and test results**

Summary validation before marking complete:
- [ ] All 8 acceptance criteria from b-requirements-plan.md met
- [ ] workflow-control script exists with 0500 permissions and returns correct output
- [ ] workflow-control uses CIG::Options, CIG::TaskPath, and CIG::MarkdownParser modules (AC8)
- [ ] blocker-patterns.md exists with content from all 10 phases
- [ ] All 10 workflow commands have "Scope & Boundaries" section (5-6 lines)
- [ ] Security hash added for workflow-control
- [ ] No regressions (test with existing task)

## Status
**Status**: Finished
**Next Action**: Move to testing planning phase
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
