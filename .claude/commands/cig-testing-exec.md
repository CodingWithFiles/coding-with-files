---
description: Guide user through testing execution phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver:*), Bash(.cig/scripts/command-helpers/context-inheritance:*), Bash(.cig/scripts/command-helpers/format-detector:*), Bash(egrep:*), Bash(echo:*), Bash(find:*), Bash(npm:*), Bash(pytest:*), Bash(cargo:*), Bash(go:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: $ARGUMENTS

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the testing execution phase.

**CRITICAL - Argument Parsing**:
- Extract the FIRST space-separated word from the task arguments above as the task path
- Any additional words after the first provide user context about their intent
- Use the extra words to understand what the user wants, but do NOT pass them to script calls
- Example: "11 run the tests" → task path is "11", extra text explains what to do

**CRITICAL - Task Path Validation**:
- Task paths MUST match hierarchical number format: digits separated by dots
- Valid formats: "11", "1.2", "12.2.3", "1.1.1.1"
- Invalid formats: "some text", "`date`", "11; rm -rf", "text.text"
- If first word does NOT match valid format, inform user and do not invoke scripts
- This prevents command injection and ensures only valid task identifiers reach scripts

1. **Resolve Task Directory**:

Parse the task path argument and resolve to full directory:
- Extract first word from task arguments
- Validate it matches hierarchical number format (digits and dots only)
- If valid: call `.cig/scripts/command-helpers/hierarchy-resolver <task-path>` using the Bash tool
- If invalid: inform user the task path format is invalid, do not invoke script
- If task not found, provide clear error with available tasks
- Extract task number, type, and slug from resolution

2. **Load Parent Context**:

If this is a subtask (not top-level), load parent context for inherited context:
- Use the validated task path from Step 1
- Call `.cig/scripts/command-helpers/context-inheritance <task-path>` using the Bash tool
- Parent context includes: file paths, status markers, section headers, line ranges
- This provides ~50-100 tokens per parent instead of 500-1000 for full files

3. **Present Context Summary**:

Present the parent context structural map to help inform execution:
- Show navigable links with file paths and line ranges
- Display status markers to indicate reliability of parent context
- Highlight key parent decisions that may influence this task's testing

4. **LLM Decision Point - Read Parent Details**:

Based on the structural map, decide if you need to read specific parent sections:
- Use Read tool with offset/limit parameters from structural map
- Only read sections that directly inform this task's testing execution
- Skip irrelevant parent context to conserve tokens

5. **Reference Test Plan**:

Read the test plan to understand what tests need to be executed:
- Read `f-testing-plan.md` for test strategy, test cases, and success criteria
- Understand the planned test approach, test levels, and coverage targets
- Review functional and non-functional test specifications

6. **Execute Testing Workflow**:

Open and work with the testing execution file (g-testing-exec.md):
- Use `format-detector <task-dir> <workflow-file>` to check version
- **Focus on**: Executing planned tests, recording results, documenting failures
- **Avoid**: Changing the test plan (update f-testing-plan.md if plan needs adjustment)
- Capture: Test results (PASS/FAIL), failure details, coverage metrics

Key questions to address:
- What tests from the plan have been executed?
- What were the actual test results (PASS/FAIL)?
- Were any test failures encountered? What are the reproduction steps?
- What is the test coverage achieved?
- What remains to be tested?

**Status Field**: Use valid status values only. See `.cig/docs/workflow/workflow-steps.md#status-values`.
- Update to "Testing" when starting test execution
- Update to "Finished" when all tests pass and coverage is sufficient
- Update to "Blocked" if test failures or environment issues prevent progress

7. **Execute Test Cases**:

Work through the test plan systematically:
- Set up test environment as specified in f-testing-plan.md
- Execute functional test cases sequentially
- Execute non-functional tests (performance, security, usability, reliability)
- Record PASS/FAIL status for each test case in results table
- Document failure details with reproduction steps
- Measure and record test coverage

8. **Suggest Next Steps with Reasoning**:

Analyze the testing outcome and suggest the next step:

**Primary Next Step** (if all tests pass):
- Move to rollout: `/cig-rollout <task-path>`
- Rationale: Testing complete with all tests passing, ready for deployment

**Alternative Paths**:
- If test failures found → Return to `/cig-implementation-exec <task-path>` to fix bugs
- If test plan proves insufficient → Return to `/cig-testing-plan <task-path>` to add tests
- If tests reveal design issues → Return to `/cig-design-plan <task-path>` to address flaws
- If coverage is insufficient → Add more tests, continue execution
- If environment issues block testing → Document blocker, update status to "Blocked"

Provide clear reasoning for the suggested path based on testing outcome.

## Blocker Handling

**Common Blockers in Testing Execution**:
- Test failures reveal implementation bugs → Return to e-implementation-exec.md to fix
- Test environment setup fails → Document environment issues, may need infrastructure subtask
- Tests reveal design flaws → Revert to c-design-plan.md to address fundamental issues
- Missing test data or test doubles → Create test infrastructure subtask
- Coverage targets cannot be met → Revert to f-testing-plan.md to adjust strategy

**Reversion Guidance**:
- If reverting to implementation: Document bugs in e-implementation-exec.md, fix and retest
- If reverting to test planning: Update f-testing-plan.md with new test cases, then re-execute
- If reverting to design: Update c-design-plan.md with testability improvements
- Document the blocker in "Test Failures" section of g-testing-exec.md
- Update status to "Blocked" until blocker is resolved
- When blocker resolved, resume testing with fixes applied

**When to Revert**:
- Test failures indicate fundamental implementation or design issues
- Test environment is not viable (missing infrastructure, incompatible dependencies)
- Tests cannot achieve required coverage due to design limitations

## Success Criteria
- [ ] Task directory resolved successfully
- [ ] Parent context loaded (if applicable) and relevant sections reviewed
- [ ] Test plan (f-testing-plan.md) reviewed
- [ ] Execution file (g-testing-exec.md) opened and updated
- [ ] Test environment set up successfully
- [ ] All functional test cases executed and results recorded
- [ ] Non-functional tests executed (if applicable)
- [ ] Test failures documented with reproduction steps
- [ ] Test coverage metrics recorded
- [ ] Next steps suggested with clear reasoning
