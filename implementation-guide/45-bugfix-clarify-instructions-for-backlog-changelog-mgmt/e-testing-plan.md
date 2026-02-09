# clarify instructions for backlog changelog mgmt - Testing Plan
**Task**: 45 (bugfix)

## Task Reference
- **Task ID**: internal-45
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/45-clarify-instructions-for-backlog-changelog-mgmt
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for clarify instructions for backlog changelog mgmt.

## Test Strategy
### Test Levels
- **Manual Validation**: Verify documentation content is correct, clear, and complete
- **Integration Tests**: Test instructions by executing retrospective workflow with enhanced Step 9
- **Acceptance Tests**: Verify LLM agents follow new instructions without skipping CHANGELOG/BACKLOG updates

### Test Coverage Targets
- **Overall Coverage**: All 4 substeps (9.1-9.4) must be present and clear
- **Critical Paths**: CHANGELOG update (9.1), BACKLOG cleanup (9.2), git staging (9.4) - 100% coverage
- **Edge Cases**: Tool guidance clear for all scenarios (empty BACKLOG, multiple items, first-time CHANGELOG)
- **Regression**: Existing retrospective workflow steps (1-8, 10-11) remain unchanged

## Test Cases
### Functional Test Cases
- **TC-1**: Verify Step 9 structure is complete
  - **Given**: Modified `.claude/commands/cig-retrospective.md` file
  - **When**: Reading Step 9 content
  - **Then**:
    - Step 9 header includes both CHANGELOG.md and BACKLOG.md
    - 4 substeps present: 9.1, 9.2, 9.3, 9.4
    - Rationale paragraph explains why both files synchronized
    - Token-efficient approach paragraph present

- **TC-2**: Verify CHANGELOG update instructions (9.1)
  - **Given**: Step 9.1 content
  - **When**: Reviewing instruction clarity
  - **Then**:
    - Instructs to read CHANGELOG.md with limit parameter
    - Instructs to use Edit tool for adding entry at top
    - Specifies what to include in entry (task num, date, duration, problems, changes, BACKLOG items)
    - Example references Task 40

- **TC-3**: Verify BACKLOG cleanup instructions (9.2)
  - **Given**: Step 9.2 content
  - **When**: Reviewing instruction clarity
  - **Then**:
    - Instructs to use Grep tool with pattern `^## Task:`
    - Explains Grep returns line numbers for efficiency
    - Instructs to use Read with offset/limit if details needed
    - Instructs to use Edit tool for removals
    - Clarifies completed items now live in CHANGELOG
    - Example references Task 40

- **TC-4**: Verify BACKLOG additions instructions (9.3)
  - **Given**: Step 9.3 content
  - **When**: Reviewing instruction clarity
  - **Then**:
    - Instructs to read retrospective Recommendations/Future Work
    - Instructs to use Edit tool for additions
    - Specifies required BACKLOG format fields (Task-Type, Priority, Status, Description, Identified in)
    - Example references Task 44

- **TC-5**: Verify git staging instructions (9.4)
  - **Given**: Step 9.4 content
  - **When**: Reviewing instruction clarity
  - **Then**:
    - Explicitly stages both CHANGELOG.md and BACKLOG.md
    - Command is: `git add CHANGELOG.md BACKLOG.md`

- **TC-6**: Integration test with Task 45 retrospective
  - **Given**: Task 45 completed, ready for retrospective
  - **When**: Agent executes `/cig-retrospective 45` following enhanced Step 9
  - **Then**:
    - Agent reads CHANGELOG.md with limit parameter
    - Agent creates new CHANGELOG entry at top using Edit
    - Agent uses Grep to find BACKLOG tasks
    - Agent removes completed BACKLOG items using Edit
    - Agent adds new BACKLOG items from retrospective using Edit
    - Agent stages both CHANGELOG.md and BACKLOG.md
    - No steps skipped

### Non-Functional Test Cases
- **Clarity Tests**: Instructions clear enough that LLM follows without ambiguity
- **Token Efficiency Tests**: Tool guidance promotes efficient tool use (Grep > Read entire file, Edit > Write)
- **Maintainability Tests**: Examples reference specific tasks for easy verification
- **Regression Tests**: Other retrospective steps (1-8, 10-11) remain unchanged and functional

## Test Environment
### Setup Requirements
- Working git repository with CIG system installed
- Task 45 completed through implementation execution phase
- CHANGELOG.md and BACKLOG.md present in repository root
- Existing CHANGELOG entries for pattern reference (Task 40, 44)
- Existing BACKLOG items for testing removal/addition

### Automation
- Manual validation: Read modified file to verify structure
- Integration test: Execute `/cig-retrospective 45` and observe agent behavior
- Validation: Use git diff to confirm both CHANGELOG.md and BACKLOG.md modified
- No automated test framework required (documentation validation)

## Validation Criteria
- [ ] TC-1: Step 9 structure complete (4 substeps, rationale, token-efficient approach)
- [ ] TC-2: CHANGELOG update instructions clear (Read with limit, Edit tool, what to include)
- [ ] TC-3: BACKLOG cleanup instructions clear (Grep for search, Edit for removal, line numbers)
- [ ] TC-4: BACKLOG additions instructions clear (Edit tool, format spec, examples)
- [ ] TC-5: Git staging includes both files (CHANGELOG.md and BACKLOG.md)
- [ ] TC-6: Integration test successful (Task 45 retrospective follows all substeps without skipping)
- [ ] Clarity test: No ambiguous language in instructions
- [ ] Token efficiency test: Tool guidance promotes efficient patterns
- [ ] Regression test: Other retrospective steps unchanged

## Status
**Status**: Finished
**Next Action**: Move to implementation execution → `/cig-implementation-exec 45`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
