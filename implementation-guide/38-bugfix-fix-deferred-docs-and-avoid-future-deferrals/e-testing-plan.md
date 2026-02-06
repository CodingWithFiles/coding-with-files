# fix-deferred-docs-and-avoid-future-deferrals - Testing

## Task Reference
- **Task ID**: internal-38
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/38-fix-deferred-docs-and-avoid-future-deferrals
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for fix-deferred-docs-and-avoid-future-deferrals.

## Test Strategy
### Test Levels
- **Validation Tests**: Manual verification of documentation and template changes
- **Integration Tests**: Verify template-copier works with modified templates
- **Regression Tests**: Verify existing tasks' templates unaffected

### Test Coverage Targets
- **Documentation Coverage**: 100% of success criteria validated
- **Critical Paths**: All 3 modified files tested
- **Template Compatibility**: template-copier works with all task types
- **Regression**: No existing templates broken

## Test Cases
### Functional Test Cases

#### TC-1: state-tracking.md Line Count Reduction
- **Given**: Original state-tracking.md is 655 lines
- **When**: File is refactored per design
- **Then**:
  - Line count reduced to ~200 lines (70% reduction achieved)
  - File is significantly more compact
  - Essential information preserved

#### TC-2: Task 37 Output Format Documented
- **Given**: Task 37 implemented new structured output format
- **When**: state-tracking.md Quick Reference section is reviewed
- **Then**:
  - Conclusive format example present
  - Inconclusive uncorrelated format example present
  - Inconclusive no_signals format example present
  - All examples include correct field names (task_nums, reasons, etc.)

#### TC-3: state-tracking.md Structure
- **Given**: Refactored state-tracking.md
- **When**: File structure is examined
- **Then**:
  - Section 1: Quick Reference (output formats)
  - Section 2: Signal Overview (table format)
  - Section 3: Correlation Logic (compact)
  - Section 4: Exit Codes (table format)
  - Structure is scannable and easy to navigate

#### TC-4: d-implementation-plan.md.template Updated
- **Given**: Original template without deferral warnings
- **When**: Template is examined after updates
- **Then**:
  - "Scope Completion" section present after "Implementation Steps"
  - Section includes Task 37 example
  - Guidance for getting user approval present
  - Requirement to create follow-up task present

#### TC-5: f-implementation-exec.md.template Updated
- **Given**: Original template without deferral check
- **When**: Template is examined after updates
- **Then**:
  - "Deferral Check" section present before "Status"
  - Checklist includes verification of:
    - All implementation steps executed
    - All success criteria met
    - All requirements addressed
    - All design guidance followed
    - No work deferred without approval

#### TC-6: Template Variable Substitution
- **Given**: Modified templates with new sections
- **When**: template-copier processes templates
- **Then**:
  - All {{variables}} correctly substituted
  - New sections rendered in output files
  - No syntax errors or broken formatting

#### TC-7: template-copier Compatibility
- **Given**: Modified d-implementation-plan.md.template and f-implementation-exec.md.template
- **When**: template-copier run for each task type (feature, bugfix, hotfix, chore)
- **Then**:
  - Bugfix tasks get both modified templates
  - Feature/hotfix/chore tasks get d-implementation-plan.md.template
  - All task types get f-implementation-exec.md.template
  - No errors during template copying

### Non-Functional Test Cases

#### TC-U1: Usability - state-tracking.md Readability
- **Given**: Refactored state-tracking.md
- **When**: User needs to quickly look up output format
- **Then**:
  - Output format examples are at top (Quick Reference)
  - Examples are clear and complete
  - User can find information in <30 seconds

#### TC-U2: Usability - Template Guidance Clarity
- **Given**: Updated templates with deferral warnings
- **When**: Developer reads template during implementation
- **Then**:
  - Warning is prominent and clear
  - Task 37 example provides concrete context
  - Guidance actionable (specific steps to follow)

#### TC-R1: Reliability - Template-copier Backwards Compatibility
- **Given**: Existing tasks created before template updates
- **When**: New tasks created after template updates
- **Then**:
  - Old tasks continue working (no breaking changes)
  - New tasks include updated guidance
  - template-copier handles both gracefully

## Test Environment
### Setup Requirements
- **CIG repository**: Current working repository with .cig/ structure
- **Text editor**: For reading documentation files
- **Terminal**: For running template-copier and checking line counts
- **No special dependencies**: Documentation-only task

### Test Execution Method
- **Manual validation**: Read files and verify content
- **Line count check**: `wc -l .cig/docs/context/state-tracking.md`
- **Template test**: Create test task with template-copier
- **Diff comparison**: Compare before/after for templates

### Automation
- **Not applicable**: Manual verification appropriate for documentation changes
- **Future improvement**: Could add automated tests that verify doc structure

## Validation Criteria
- [ ] **TC-1 through TC-7**: All functional test cases pass (7 tests)
- [ ] **TC-U1, TC-U2**: Usability tests pass (readability, clarity)
- [ ] **TC-R1**: Reliability test passes (backwards compatibility)
- [ ] **Success Criteria**: All 5 from a-task-plan.md verified
  - [ ] state-tracking.md updated with Task 37 format
  - [ ] state-tracking.md refactored to be compact
  - [ ] d-implementation-plan.md.template updated
  - [ ] f-implementation-exec.md.template updated
  - [ ] Templates emphasize completing all planned work
- [ ] **Line Count**: state-tracking.md reduced to ~200 lines (70% reduction)
- [ ] **Template Copier**: Works with modified templates for all task types

## Decomposition Check
Review these signals to determine if testing should be broken into subtasks:
- [ ] **Time**: Will testing take >1 week? **No** - Estimated 30 minutes for validation
- [ ] **People**: Does testing need >2 people? **No** - Single person can validate docs
- [ ] **Complexity**: Does testing involve 3+ distinct concerns? **No** - Simple validation
- [ ] **Risk**: Are there high-risk tests? **No** - Low risk documentation verification
- [ ] **Independence**: Can test groups run separately? **No** - Quick sequential validation

**Analysis**: 0/5 signals triggered. Testing appropriately scoped as single phase.

## Status
**Status**: Finished
**Next Action**: Move to implementation execution → `/cig-implementation-exec 38`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
