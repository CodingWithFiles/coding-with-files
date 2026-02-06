# fix-deferred-docs-and-avoid-future-deferrals - Implementation

## Task Reference
- **Task ID**: internal-38
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/38-fix-deferred-docs-and-avoid-future-deferrals
- **Template Version**: 2.1

## Goal
Implement fix-deferred-docs-and-avoid-future-deferrals following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cig/docs/context/state-tracking.md` - Refactor from 655 lines to ~200 lines, add Task 37's new output format
- `.cig/templates/pool/d-implementation-plan.md.template` - Add "Scope Completion" section warning against deferrals
- `.cig/templates/pool/f-implementation-exec.md.template` - Add "Deferral Check" section before status

### Supporting Changes
- None - documentation-only task

## Implementation Steps
### Step 1: Setup
- [ ] Review c-design-plan.md for refactor strategy and template additions
- [ ] Read current `.cig/docs/context/state-tracking.md` to understand structure
- [ ] Read current template files to understand insertion points

### Step 2: Refactor state-tracking.md
- [ ] Create backup of current file (for reference)
- [ ] Restructure to compact format (~200 lines target):
  - [ ] Section 1: Quick Reference - Output format examples (conclusive, inconclusive, no_signals)
  - [ ] Section 2: Signal Overview - Table with brief descriptions
  - [ ] Section 3: Correlation Logic - Compact explanation
  - [ ] Section 4: Exit Codes - Simple mapping table
- [ ] Add Task 37's new output format prominently
- [ ] Remove verbose explanations, keep essential technical details
- [ ] Add links to detailed docs for deep dives

### Step 3: Update d-implementation-plan.md.template
- [ ] Add "Scope Completion" section after "Implementation Steps"
- [ ] Include Task 37 example as cautionary tale
- [ ] Add guidance: Get user approval if deferral required
- [ ] Add requirement: Create follow-up task for deferred work

### Step 4: Update f-implementation-exec.md.template
- [ ] Add "Deferral Check" section before "Status"
- [ ] Add checklist verifying:
  - [ ] All implementation steps executed
  - [ ] All success criteria met
  - [ ] All requirements addressed
  - [ ] All design guidance followed
  - [ ] No work deferred without approval
- [ ] Add guidance for legitimate deferrals

### Step 5: Validation
- [ ] Verify state-tracking.md is significantly shorter (~70% reduction)
- [ ] Verify Task 37's output format is clearly documented
- [ ] Verify templates include deferral warnings
- [ ] Test template-copier still works with modified templates
- [ ] Verify line count reduction achieved (655 → ~200 lines)

## Code Changes
### Change 1: state-tracking.md Structure

#### Before (verbose, 655 lines)
```markdown
# Task Context Tracking

## Introduction
[Long conceptual explanation...]

## Signal System
[Detailed explanations of each signal...]

## Output Format
[Buried specification...]
```

#### After (compact, ~200 lines)
```markdown
# Task Context Tracking

## Quick Reference - Output Formats

### Conclusive (Exit 0)
```
current: conclusive
confidence: correlated
task_num: 37
...
```

### Inconclusive - Uncorrelated (Exit 1)
```
current: inconclusive
task_nums: 14,32,37
...
```

## Signal Overview
| Signal | Purpose | Weight |
|--------|---------|--------|
| branch | Git branch | 100 |
...

## Correlation Logic
Brief explanation...

## Exit Codes
| Code | Meaning |
|------|---------|
| 0 | Conclusive |
...
```

### Change 2: Template Additions

#### d-implementation-plan.md.template
```markdown
## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Task 37 deferred documentation, marked complete anyway, created Task 38 to fix it.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results
```

#### f-implementation-exec.md.template
```markdown
## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements.md addressed
- [ ] All design guidance in c-design.md followed
- [ ] No work deferred without user approval
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

### Validation Tests
- **VT-1**: Verify state-tracking.md line count reduced to ~200 lines (70% reduction)
- **VT-2**: Verify Task 37's output format documented in Quick Reference section
- **VT-3**: Verify templates include deferral warnings
- **VT-4**: Verify template-copier works with modified templates

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

### Implementation Complete When:
- [ ] state-tracking.md refactored to ~200 lines with Task 37's format
- [ ] d-implementation-plan.md.template includes "Scope Completion" section
- [ ] f-implementation-exec.md.template includes "Deferral Check" section
- [ ] All 5 success criteria from a-task-plan.md met
- [ ] Templates tested with template-copier

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - Estimated 2-3 hours
- [ ] **People**: Does this need >2 people? **No** - Single person documentation task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - 2 concerns (docs, templates)
- [ ] **Risk**: Are there high-risk components? **No** - Low risk documentation changes
- [ ] **Independence**: Can parts be worked separately? **No** - Closely related, small scope

**Analysis**: 0/5 signals triggered. Appropriately scoped as single bugfix task.

## Status
**Status**: Finished
**Next Action**: Move to testing planning → `/cig-testing-plan 38`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
