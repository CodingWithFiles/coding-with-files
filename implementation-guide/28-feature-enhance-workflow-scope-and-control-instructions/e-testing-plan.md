# Enhance workflow scope and control instructions - Testing

## Task Reference
- **Task ID**: internal-28
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/28-enhance-workflow-scope-and-control-instructions
- **Template Version**: 2.0

## Goal
Define test strategy and validation approach for consolidated workflow instructions and workflow-control helper script.

## Test Strategy
### Test Levels
- **Unit Tests**: workflow-control script isolated testing with mock inputs
- **Integration Tests**: workflow-control reading actual workflow files
- **System Tests**: End-to-end workflow command execution (create task, run through phases)
- **Acceptance Tests**: Verify all 7 acceptance criteria from b-requirements-plan.md

### Test Coverage Targets
- **Overall Coverage**: 100% (all components testable via manual validation)
- **Critical Paths**: 100% coverage required
  - workflow-control script: All 3 status branches (Finished, Blocked, Other)
  - All 10 workflow commands: "Scope & Boundaries" section present and correct
- **Edge Cases**: Invalid arguments, missing files, malformed status fields
- **Regression**: Existing tasks (e.g., task 27) still work correctly

## Test Cases
### Functional Test Cases

**workflow-control Script Tests**:

- **TC-1**: workflow-control with Finished status
  - **Given**: Task 29 exists with c-design-plan.md status "Finished"
  - **When**: Run `workflow-control --current-step c-design-plan --task-path 29`
  - **Then**: Output is "ask-user\nSuggest next workflow step"

- **TC-2**: workflow-control with Blocked status
  - **Given**: Task 29 exists with c-design-plan.md status "Blocked"
  - **When**: Run `workflow-control --current-step c-design-plan --task-path 29`
  - **Then**: Output is "ask-user\nNeed user feedback on blocker"

- **TC-3**: workflow-control with In Progress status
  - **Given**: Task 29 exists with c-design-plan.md status "In Progress"
  - **When**: Run `workflow-control --current-step c-design-plan --task-path 29`
  - **Then**: Output starts with "continue\nIf workflow step complete..."

- **TC-4**: workflow-control with invalid task path
  - **Given**: Task path contains special characters (e.g., "29; rm -rf")
  - **When**: Run `workflow-control --current-step c-design-plan --task-path "29; rm -rf"`
  - **Then**: Script exits with error, validates hierarchical format

- **TC-5**: workflow-control with non-existent task
  - **Given**: Task 999 does not exist
  - **When**: Run `workflow-control --current-step c-design-plan --task-path 999`
  - **Then**: Script exits with "Task not found" error

**Workflow Command Tests**:

- **TC-6**: "Scope & Boundaries" section present in all commands
  - **Given**: All 10 workflow commands (.claude/commands/cig-*.md)
  - **When**: Check for "## Scope & Boundaries" section
  - **Then**: Section present in all 10 commands after frontmatter, before "## Context"

- **TC-7**: "Scope & Boundaries" section line count
  - **Given**: All 10 workflow commands
  - **When**: Count lines in "Scope & Boundaries" section
  - **Then**: Each section is 5-6 lines (including header)

- **TC-8**: blocker-patterns.md exists with content
  - **Given**: Implementation complete
  - **When**: Read `.cig/docs/workflow/blocker-patterns.md`
  - **Then**: File exists with blocker patterns from all 10 phases

**Integration Tests**:

- **TC-9**: End-to-end workflow test
  - **Given**: Fresh repository state
  - **When**: Create task 29, run `/cig-task-plan 29` through `/cig-retrospective 29`
  - **Then**: All commands execute successfully, "Scope & Boundaries" visible, workflow-control callable

- **TC-10**: Regression test with existing task
  - **Given**: Existing task 27 on bugfix/27 branch
  - **When**: Run `/cig-task-plan 27` (should still work)
  - **Then**: Command executes without errors, task 27 files unchanged

- **TC-11**: workflow-control uses CIG common modules (AC8)
  - **Given**: workflow-control script implemented
  - **When**: Read script source code and check imports
  - **Then**: Script contains `use CIG::Options`, `use CIG::TaskPath`, `use CIG::MarkdownParser` and calls their functions (not manual parsing or external script calls)

### Non-Functional Test Cases

- **Performance Tests**:
  - workflow-control execution time < 100ms (measure with `time` command)
  - No noticeable delay in workflow command execution

- **Security Tests**:
  - workflow-control validates task-path format (hierarchical numbers only)
  - workflow-control has 0500 permissions (user execute only)
  - SHA256 hash verified in `.cig/security/script-hashes.json`

- **Usability Tests**:
  - "Scope & Boundaries" section readable in < 30 seconds
  - workflow-control output messages are clear and actionable
  - Error messages provide helpful guidance

- **Reliability Tests**:
  - workflow-control handles missing workflow files gracefully
  - workflow-control handles malformed status fields gracefully
  - Backward compatible (existing tasks unaffected)

## Test Environment
### Setup Requirements
- **Test Task**: Create task 29 as test fixture (feature type)
- **Test Data**: Workflow files with various status values (Finished, Blocked, In Progress)
- **Environment**: Development repository with all workflow commands present
- **Tools**: Bash, Perl (for running workflow-control), grep/sed (for validation)

### Automation
- **Test Framework**: Manual validation (no automated test framework needed for documentation changes)
- **Validation Scripts**: Bash scripts to check "Scope & Boundaries" presence and line count
- **CI/CD Integration**: Not applicable (manual testing sufficient)
- **Test Execution**: Run tests after each implementation step (Step 1 → test workflow-control, Step 3 → test pilot command, Step 4 → test all commands)

## Validation Criteria
- [ ] All 11 functional test cases (TC-1 through TC-11) passing
- [ ] All 4 non-functional test categories validated (Performance, Security, Usability, Reliability)
- [ ] Coverage targets met: 100% of critical paths tested
- [ ] Performance benchmark achieved: workflow-control < 100ms
- [ ] Security validation completed: permissions 0500, hash verified, task-path validated
- [ ] Regression test passing: existing task 27 works correctly
- [ ] All 8 acceptance criteria from b-requirements-plan.md met:
  - [ ] AC1: All 10 commands have "Scope & Boundaries" section
  - [ ] AC2: workflow-control script exists with 0500 permissions
  - [ ] AC3: workflow-control returns correct output for all 3 status categories
  - [ ] AC4: blocker-patterns.md exists with content
  - [ ] AC5: Commands reference blocker-patterns.md
  - [ ] AC6: Existing workflow command works (tested with task 29)
  - [ ] AC7: All sections ≤6 lines
  - [ ] AC8: workflow-control uses CIG::Options, CIG::TaskPath, and CIG::MarkdownParser modules

## Status
**Status**: Finished
**Next Action**: Move to rollout phase (or implementation execution if using v2.1 workflow)
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
