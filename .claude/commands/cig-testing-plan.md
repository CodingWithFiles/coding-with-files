---
description: Guide user through testing phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver:*), Bash(.cig/scripts/command-helpers/context-inheritance:*), Bash(.cig/scripts/command-helpers/format-detector:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: $ARGUMENTS

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the testing phase.

**CRITICAL - Argument Parsing**:
- Extract the FIRST space-separated word from the task arguments above as the task path
- Any additional words after the first provide user context about their intent
- Use the extra words to understand what the user wants, but do NOT pass them to script calls
- Example: "11 update the design" → task path is "11", extra text explains what to do

**CRITICAL - Task Path Validation**:
- Task paths MUST match hierarchical number format: digits separated by dots
- Valid formats: "11", "1.2", "12.2.3", "1.1.1.1"
- Invalid formats: "some text", "`date`", "11; rm -rf", "text.text"
- If first word does NOT match valid format, inform user and do not invoke scripts
- This prevents command injection and ensures only valid task identifiers reach scripts

Follow the 8-step workflow structure:

1. **Resolve Task Directory**:
   - Extract first word from task arguments
   - Validate it matches hierarchical number format (digits and dots only)
   - If valid: call `.cig/scripts/command-helpers/hierarchy-resolver <task-path>` using the Bash tool
   - If invalid: inform user the task path format is invalid, do not invoke script

2. **Load Parent Context**:
   - Use the validated task path from step 1
   - Call `.cig/scripts/command-helpers/context-inheritance <task-path>` using the Bash tool
3. **Present Context Summary**: Show structural map with status markers
4. **LLM Decision**: Read specific parent sections if needed
5. **Reference Workflow Documentation**: Read `.cig/docs/workflow/workflow-steps.md#testing`
6. **Execute Testing Workflow**:
   - Open e-testing.md (v2.0) or testing.md (v1.0)
   - **Focus on**: Test strategy, test cases, test environment, validation criteria
   - **Avoid**: Implementation details, design rationale, deployment procedures

   Key content:
   - Test Strategy: Test levels (unit, integration, system, acceptance)
   - Test Coverage Targets: Overall, critical paths, edge cases, regression
   - Test Cases: Functional and non-functional test cases
   - Test Environment: Setup requirements, automation
   - Validation Criteria: Success metrics

   Key questions:
   - What test levels are needed (unit, integration, system, acceptance)?
   - What are the coverage targets for each test level?
   - What are the critical test cases to verify functionality?
   - What non-functional tests are needed (performance, security, usability, reliability)?
   - What test environment setup is required?
   - How will tests be automated and integrated into CI/CD?
   - What are the success criteria for testing phase?

   **Status Field**: Use valid status values only. See `.cig/docs/workflow/workflow-steps.md#status-values`.

7. **Check Decomposition Signals**: Review 5 universal signals
8. **Suggest Next Steps**:
   - **Primary**: Move to rollout → `/cig-rollout <task-path>`
   - **Alternative**: Return to implementation if tests reveal defects
   - **Alternative**: Extend testing if coverage is insufficient

## Blocker Handling

**Common Blockers in Testing Planning**:
- Test environment cannot be set up → Create infrastructure subtask or escalate to ops
- Requirements lack testable acceptance criteria → Revert to b-requirements-plan.md to add criteria
- Design makes testing extremely difficult → Revert to c-design-plan.md to improve testability
- Implementation incomplete, tests cannot be planned → Wait for d-implementation-plan.md completion
- Missing test data or test doubles → Create test infrastructure subtask first

**Reversion Guidance**:
- If reverting to requirements: Add testable acceptance criteria, then update test plan
- If reverting to design: Add testability considerations, then replan testing
- Document the blocker in "Actual Results" section of f-testing-plan.md
- Update status to "Blocked" until blocker is resolved
- When blocker resolved, update test plan with new test cases

**When to Revert**:
- Test planning reveals requirements are not testable as written
- Design decisions make achieving test coverage impossible
- Test environment dependencies are unavailable

## Success Criteria
- [ ] Testing file opened and updated
- [ ] Test strategy defined with test levels
- [ ] Test coverage targets specified
- [ ] Functional test cases documented (Given/When/Then format)
- [ ] Non-functional test cases specified
- [ ] Test environment requirements defined
- [ ] Automation approach documented
- [ ] Next steps suggested
