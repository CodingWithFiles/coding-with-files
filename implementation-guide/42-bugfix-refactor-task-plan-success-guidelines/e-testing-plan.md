# Refactor task plan success guidelines - Testing

## Task Reference
- **Task ID**: internal-42
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/42-refactor-task-plan-success-guidelines
- **Template Version**: 2.1

## Goal
Validate that "Simplicity Principles" guidance prevents future planning scope gaps.

## Test Strategy

### Test Levels
- **Manual Validation**: Retrospective analysis with Tasks 39/40/41
- **Content Validation**: Markdown rendering and formatting verification
- **Integration Tests**: Verify guidance doesn't break existing workflow

### Test Coverage Targets
- **Critical Path**: 100% - New guidance catches scope gaps that Tasks 39/40/41 missed
- **Regression**: 100% - Existing planning workflow sections unaffected
- **Content**: 100% - All 2 principles + 3 questions present and readable

## Test Cases

### Functional Test Cases

#### TC-F1: Retrospective Validation - Task 39 Pattern
- **Given**: Task 39 planning phase (trampoline architecture implementation)
- **When**: Planning with new "Simplicity Principles" guidance
- **Then**: Question "What existing code/files/artifacts does this make obsolete?" prompts identifying old monolithic scripts for removal

#### TC-F2: Retrospective Validation - Task 40 Pattern
- **Given**: Task 40 planning phase (COMPLETE helper migration with incomplete scope)
- **When**: Planning with new guidance emphasising "The best part is no part"
- **Then**: Success criteria include "Remove old standalone scripts" not just "Add new modules"

#### TC-F3: Retrospective Validation - Task 41 Pattern
- **Given**: Task 41 planning phase (refactor to clean architecture)
- **When**: Planning with "What's the minimal solution?" prompt
- **Then**: Recognise clean architecture means OLD architecture removed, not side-by-side existence

#### TC-F4: Markdown Rendering Validation
- **Given**: Modified workflow-steps.md with new subsection
- **When**: Reading the Planning section
- **Then**:
  - Bold formatting renders correctly (`**Simplicity Principles**:`)
  - Two bullet points display properly
  - Three sub-bullets under "When planning" render correctly
  - Blank lines preserve spacing
  - Content flows naturally (Purpose → Principles → Focus)

#### TC-F5: Content Completeness
- **Given**: workflow-steps.md Planning section
- **When**: Reading "Simplicity Principles" subsection
- **Then**: Contains all required elements:
  - Opening paragraph about simplicity as core goal
  - "The best part is no part" principle with explanation
  - "Reduce, reuse, recycle" principle with explanation
  - Three explicit questions (remove, obsolete, minimal)

### Non-Functional Test Cases

#### TC-NF1: Usability - Reading Comprehension
- **Test**: Can a developer understand the guidance without additional context?
- **Validation**: Principles are self-explanatory with clear examples
- **Success**: No ambiguity about when to remove vs add code

#### TC-NF2: Maintainability - Future Proof
- **Test**: Is the guidance universally applicable or specific to Tasks 39/40/41?
- **Validation**: Principles apply to any planning phase (code, docs, infrastructure)
- **Success**: Not tied to specific technologies or patterns

#### TC-NF3: Consistency - Workflow Integration
- **Test**: Does new subsection fit naturally into existing Planning phase structure?
- **Validation**: Reading flow: Purpose → Principles → Focus → Avoid → Questions → Structure → Transitions
- **Success**: No jarring transitions, maintains existing pattern

#### TC-NF4: Simplicity - Not Adding Complexity
- **Test**: Does the guidance follow its own principle (simple, not bloated)?
- **Validation**: 13 lines added, 2 principles, 3 questions - minimal addition
- **Success**: Adds value without creating checklist fatigue

## Test Environment

### Setup Requirements
- Git repository with Task 42 changes committed
- Access to workflow-steps.md
- Access to Tasks 39/40/41 planning documents (for retrospective validation)

### Automation
- **Framework**: Manual validation (documentation testing)
- **CI/CD**: N/A - one-time documentation change
- **Regression**: Future tasks using `/cig-task-plan` should benefit from guidance

## Validation Criteria
- [x] TC-F1: Task 39 pattern caught by guidance ✅ (conceptual validation passed)
- [x] TC-F2: Task 40 pattern caught by guidance ✅ (conceptual validation passed)
- [x] TC-F3: Task 41 pattern caught by guidance ✅ (conceptual validation passed)
- [x] TC-F4: Markdown renders correctly ✅ (verified during implementation)
- [ ] TC-F5: Content completeness (to be verified in testing execution)
- [ ] TC-NF1: Usability validation (to be tested with real usage)
- [ ] TC-NF2: Maintainability validation (principles are universal)
- [ ] TC-NF3: Consistency validation (reading flow natural)
- [ ] TC-NF4: Simplicity validation (minimal addition, no bloat)

## Status
**Status**: Finished
**Next Action**: Testing planning complete, moved to execution
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
