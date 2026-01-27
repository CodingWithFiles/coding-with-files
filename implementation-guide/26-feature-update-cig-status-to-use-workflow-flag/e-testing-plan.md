# Update cig-status to Use --workflow Flag - Testing

## Task Reference
- **Task ID**: internal-26
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/26-update-cig-status-to-use-workflow-flag
- **Template Version**: 2.1

## Goal
Validate that status-aggregator script correctly implements intelligent defaults (automatic workflow mode for task queries, automatic 5-task limit for overview) and that explicit flags (--workflow, --no-workflow, --limit=N) override defaults as expected.

## Test Strategy
### Test Levels
- **Manual System Tests**: End-to-end command and script invocation testing (primary approach)
- **Acceptance Tests**: Validate all acceptance criteria from requirements (FR1-FR4, NFR1-NFR5)
- **Script Integration Tests**: Verify status-aggregator trampoline routes correctly
- **Regression Tests**: Verify existing cig-status behavior preserved
- **Performance Tests**: Verify <500ms response time requirement

**Note**: No unit tests required - this is script-based logic with manual/integration testing. Testing focuses on command invocation, script argument parsing, intelligent defaults, and explicit flag overrides.

### Test Coverage Targets
- **Intelligent Defaults**: 100% coverage (both scenarios: task path vs no arguments)
- **Explicit Flag Overrides**: 100% coverage (--workflow, --no-workflow, --limit=N)
- **Output Formats**: 100% coverage (tree view, workflow breakdown, limited output)
- **Limiting Logic**: 100% coverage (--limit applies to tasks only, not subtasks/workflows)
- **Version Detection**: 100% coverage (v2.0 and v2.1 tasks)
- **Edge Cases**: Comprehensive coverage (non-existent tasks, nested tasks, empty arguments, boundary conditions)
- **Regression**: All existing functionality validated (task-specific queries unchanged)

## Test Cases

### Functional Test Cases

#### TC-F1: No Argument - Show 5 Most Recent Tasks
- **Given**: Project has more than 5 tasks with varying modification times
- **When**: User runs `/cig-status` (no argument)
- **Then**:
  - Output shows maximum 5 tasks
  - Tasks sorted by modification time (most recent first)
  - NO workflow file breakdown shown
  - Tree view format preserved (✓, ⚙️, ○ indicators)
  - Output fits within 80-120 character terminal width

**Acceptance Criteria Validated**: AC1.2, AC2.4, AC2.5, AC2.6

---

#### TC-F2: With Task Argument - Show Workflow Breakdown
- **Given**: Task 26 exists with v2.1 format (10 workflow files)
- **When**: User runs `/cig-status 26`
- **Then**:
  - Tree view shows task 26 hierarchy
  - Workflow file breakdown displayed (10 files: a-task-plan through j-retrospective)
  - Status indicators correct (*, +, - symbols)
  - Each file shows completion percentage and status
  - Output is additive (both tree view AND workflow breakdown)

**Acceptance Criteria Validated**: AC1.1, AC1.3, AC1.4, AC2.1, AC2.2, AC2.3

---

#### TC-F3: Version Detection - v2.1 Task (10 Files)
- **Given**: Task 26 is v2.1 format with 10 workflow files
- **When**: User runs `/cig-status 26`
- **Then**:
  - Workflow breakdown shows all 10 files (a, b, c, d, e, f, g, h, i, j)
  - Files named: a-task-plan.md, b-requirements-plan.md, c-design-plan.md, d-implementation-plan.md, e-implementation-exec.md, f-testing-plan.md, g-testing-exec.md, h-rollout.md, i-maintenance.md, j-retrospective.md

**Acceptance Criteria Validated**: AC3.2

---

#### TC-F4: Version Detection - v2.0 Task (8 Files)
- **Given**: A v2.0 format task exists (e.g., Task 1-24)
- **When**: User runs `/cig-status <v2.0-task-number>`
- **Then**:
  - Workflow breakdown shows 8 files only
  - Skips e-implementation-exec.md and g-testing-exec.md
  - Shows: a-plan, b-requirements, c-design, d-implementation, f-testing, h-rollout, i-maintenance, j-retrospective

**Acceptance Criteria Validated**: AC3.1, AC3.3

---

#### TC-F5: Nested Task - Workflow Breakdown
- **Given**: A nested task exists (e.g., 1.1)
- **When**: User runs `/cig-status 1.1`
- **Then**:
  - Tree view shows task 1.1 and descendants
  - Workflow breakdown shown for task 1.1
  - Correct version detection (v2.0 or v2.1)
  - Format matches task-specific query behavior

**Acceptance Criteria Validated**: AC1.1, AC2.1, AC2.2

---

#### TC-F6: Non-Existent Task - Error Handling
- **Given**: Task 999 does not exist
- **When**: User runs `/cig-status 999`
- **Then**:
  - Graceful error message displayed: "Unable to load status" OR status-aggregator error
  - No crash or unexpected behavior
  - Error handling matches original cig-status behavior

**Acceptance Criteria Validated**: NFR5 (Reliability - graceful degradation)

---

#### TC-F7: Empty Project - No Tasks
- **Given**: implementation-guide/ directory has no tasks
- **When**: User runs `/cig-status`
- **Then**:
  - Empty output or "No tasks found" message
  - No errors or crashes
  - Graceful handling of edge case

**Acceptance Criteria Validated**: NFR5 (Reliability)

---

#### TC-F8: Exactly 5 Tasks - Boundary Condition
- **Given**: Project has exactly 5 tasks
- **When**: User runs `/cig-status`
- **Then**:
  - All 5 tasks shown
  - No truncation occurs
  - Sorted by modification time

**Acceptance Criteria Validated**: AC2.4

---

#### TC-F9: Less Than 5 Tasks - No Filtering
- **Given**: Project has 3 tasks
- **When**: User runs `/cig-status`
- **Then**:
  - All 3 tasks shown
  - No filtering applied (head -n 7 doesn't truncate)
  - Sorted by modification time

**Acceptance Criteria Validated**: AC3.4

---

#### TC-F10: Explicit --no-workflow Flag - Disable Workflow for Task
- **Given**: Task 26 exists with v2.1 format
- **When**: User runs `status-aggregator --no-workflow 26` (explicit override)
- **Then**:
  - Tree view shows task 26 hierarchy
  - NO workflow file breakdown shown (overrides default --workflow)
  - Output is tree view only
  - Explicit flag overrides intelligent default

**Acceptance Criteria Validated**: AC2.2, AC2.5

---

#### TC-F11: Explicit --workflow Flag - Enable Workflow for All Tasks
- **Given**: Project has multiple tasks
- **When**: User runs `status-aggregator --workflow` (no task argument, explicit flag)
- **Then**:
  - Tree view shows all tasks
  - Workflow file breakdown shown for ALL tasks (overrides default no-workflow)
  - Each task shows its workflow files
  - Explicit flag overrides intelligent default

**Acceptance Criteria Validated**: AC2.1, AC2.5

---

#### TC-F12: Explicit --limit=10 Flag - Show 10 Tasks
- **Given**: Project has more than 10 tasks
- **When**: User runs `status-aggregator --limit=10` (explicit override)
- **Then**:
  - Output shows maximum 10 tasks (overrides default --limit=5)
  - Tasks sorted by modification time (most recent first)
  - NO workflow file breakdown shown (no --workflow flag)
  - Explicit flag overrides intelligent default

**Acceptance Criteria Validated**: AC2.4, AC2.5

---

#### TC-F13: Combined Flags - --limit=10 --workflow
- **Given**: Project has more than 10 tasks
- **When**: User runs `status-aggregator --limit=10 --workflow` (explicit flags)
- **Then**:
  - Output shows maximum 10 tasks
  - Workflow file breakdown shown for all 10 tasks
  - Tasks sorted by modification time (most recent first)
  - Both explicit flags applied

**Acceptance Criteria Validated**: AC2.1, AC2.4, AC2.5

---

#### TC-F14: --limit Applies to Tasks Only - Not Subtasks
- **Given**: Project has tasks with deep nesting (e.g., Task 1 with 1.1, 1.1.1, 1.1.1.1)
- **When**: User runs `status-aggregator --limit=1` (explicit limit of 1 task)
- **Then**:
  - Output shows 1 top-level task (e.g., Task 1)
  - ALL subtasks within that task shown (1.1, 1.1.1, 1.1.1.1, etc.)
  - --limit counts top-level tasks only, not subtasks
  - Subtask hierarchy fully preserved

**Acceptance Criteria Validated**: AC2.4 (limit applies to tasks only)

---

#### TC-F15: --limit Does Not Apply to Workflow Files
- **Given**: Task 26 exists with 10 workflow files (v2.1 format)
- **When**: User runs `status-aggregator --limit=1 --workflow 26`
- **Then**:
  - Output shows Task 26 only (limit=1 top-level task)
  - ALL 10 workflow files shown (a-task-plan through j-retrospective)
  - --limit does not truncate workflow file breakdown
  - Workflow files fully preserved

**Acceptance Criteria Validated**: AC2.4 (limit applies to tasks only, not workflow files)

---

### Non-Functional Test Cases

#### TC-NF1: Performance - No Argument (Default Behavior)
- **Given**: Project has 24 tasks
- **When**: User runs `/cig-status` and execution time is measured
- **Then**:
  - Response time < 500ms
  - No performance degradation from baseline
  - Script-based limiting (--limit=5) doesn't add significant overhead
  - Performance better than or equal to command-side piping approach

**Acceptance Criteria Validated**: NFR1 (Performance)

---

#### TC-NF2: Performance - With Argument
- **Given**: Task 26 exists
- **When**: User runs `/cig-status 26` and execution time is measured
- **Then**:
  - Response time < 500ms
  - Workflow breakdown generation doesn't exceed performance budget
  - Performance comparable to original cig-status for task-specific queries

**Acceptance Criteria Validated**: NFR1 (Performance)

---

#### TC-NF3: Usability - Output Width
- **Given**: Various tasks with different name lengths
- **When**: User runs `/cig-status` and `/cig-status 26` in 80-column terminal
- **Then**:
  - Output fits within 80-120 character terminal width
  - No line wrapping or truncation issues
  - Workflow breakdown properly formatted
  - Tree view indentation preserved

**Acceptance Criteria Validated**: NFR2 (Usability)

---

#### TC-NF4: Reliability - Script Failure Fallback
- **Given**: status-aggregator script fails or is not executable
- **When**: User runs `/cig-status`
- **Then**:
  - Fallback message displayed: "Unable to load status"
  - No crash or unhandled error
  - Error handling preserved from original implementation

**Acceptance Criteria Validated**: NFR5 (Reliability)

## Test Environment

### Setup Requirements
- **Repository**: Code Implementation Guide repository at `/home/matt/repo/code-implementation-guide`
- **Tasks Required**:
  - Task 26 (v2.1 format) - already exists
  - At least one v2.0 task (Tasks 1-24) - already exists
  - At least 5 tasks total for filtering tests - already exists (24 tasks)
- **Scripts**:
  - `status-aggregator` trampoline entry point - already exists
  - `status-aggregator-v2.0` and `status-aggregator-v2.1` - already exists
- **Terminal**: Standard bash terminal with 80+ column width
- **Permissions**: Read access to `.cig/` and `implementation-guide/` directories

### Test Data
No additional test data required - existing project structure provides sufficient test coverage:
- 24 existing tasks (1-24, v2.0 format)
- Task 26 (v2.1 format, in progress)
- Various completion states across tasks
- Nested tasks exist (if any exist in project)

### Automation
**Manual Testing Only**:
- No automated test framework required for this change
- Testing is manual command invocation and output inspection
- Future: Could be automated with shell script that captures output and validates patterns

**CI/CD Integration**:
- Not applicable for this change
- Manual testing before merge to main branch
- Post-merge validation: Run `/cig-status` and `/cig-status 26` to verify

## Validation Criteria

### Functional Validation - Intelligent Defaults
- [ ] TC-F1: No argument shows ≤5 tasks, sorted by modified time, no workflow breakdown (default)
- [ ] TC-F2: With task 26 shows tree + workflow breakdown (default --workflow applied)
- [ ] TC-F3: Task 26 shows v2.1 format (10 files: a-j)
- [ ] TC-F4: v2.0 task shows 8 files (skipping e, g)
- [ ] TC-F5: Nested task shows workflow breakdown correctly
- [ ] TC-F6: Non-existent task shows graceful error
- [ ] TC-F7: Empty project handles gracefully
- [ ] TC-F8: Exactly 5 tasks - all shown
- [ ] TC-F9: <5 tasks - all shown, no truncation

### Functional Validation - Explicit Flag Overrides
- [ ] TC-F10: --no-workflow 26 shows tree only (no workflow breakdown)
- [ ] TC-F11: --workflow shows workflow for all tasks
- [ ] TC-F12: --limit=10 shows 10 tasks (overrides default 5)
- [ ] TC-F13: --limit=10 --workflow shows 10 tasks with workflow
- [ ] TC-F14: --limit applies to tasks only, not subtasks
- [ ] TC-F15: --limit does not truncate workflow files

### Non-Functional Validation
- [ ] TC-NF1: Performance without argument <500ms (script-based limiting)
- [ ] TC-NF2: Performance with argument <500ms
- [ ] TC-NF3: Output fits 80-120 character width
- [ ] TC-NF4: Script failure shows fallback message

### Acceptance Criteria Coverage
**FR1: Intelligent Default Behavior**
- [ ] AC1.1: Task path provided → auto-enable --workflow
- [ ] AC1.2: No arguments → auto-enable --sort=modified --limit=5
- [ ] AC1.3: Workflow breakdown shows all phase files (a-j or a-h)
- [ ] AC1.4: Phase completion indicators shown (*, +, -)

**FR2: Explicit Flag Controls**
- [ ] AC2.1: --workflow flag explicitly enables workflow
- [ ] AC2.2: --no-workflow flag explicitly disables workflow
- [ ] AC2.3: --sort=modified flag explicitly sorts
- [ ] AC2.4: --limit=N flag explicitly limits (tasks only, not subtasks/workflows)
- [ ] AC2.5: Flags override defaults

**FR3: Output Behavior Based on Defaults**
- [ ] AC3.1: With task (default): Tree view with percentages
- [ ] AC3.2: With task (default): Workflow detail per file
- [ ] AC3.3: With task (default): Additive output (tree + workflow)
- [ ] AC3.4: Without task (default): 5 most recent tasks max
- [ ] AC3.5: Without task (default): No workflow detail
- [ ] AC3.6: Without task (default): Sorted by modification time

**FR4: Version Detection**
- [ ] AC4.1: v2.0 shows 8 phases (skipping e, g)
- [ ] AC4.2: v2.1 shows 10 phases (a-j)
- [ ] AC4.3: Version detection automatic (trampoline handles)

**Non-Functional Requirements**
- [ ] NFR1: Performance <500ms for 24 tasks
- [ ] NFR2: Output fits 80-120 char width
- [ ] NFR3: Maintainability - command file <5 lines, no conditionals

### Overall Success Criteria
- [ ] All 19 test cases passing (15 functional + 4 non-functional)
- [ ] All 24 acceptance criteria validated (FR1: 4, FR2: 5, FR3: 6, FR4: 3, NFR: 3)
- [ ] No regressions in existing cig-status behavior
- [ ] Performance requirements met
- [ ] Usability requirements met
- [ ] Intelligent defaults work correctly
- [ ] Explicit flags override defaults as expected

## Status
**Status**: Finished
**Next Action**: Proceed to testing execution → `/cig-testing-exec 26`
**Blockers**: None identified

**Note**: Testing plan is fully aligned with the NEW implementation (intelligent defaults in status-aggregator script). Preliminary testing during implementation execution confirmed test cases are appropriate.

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
