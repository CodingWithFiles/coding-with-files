---
description: Guide user through testing phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.sh), Bash(.cig/scripts/command-helpers/context-inheritance.pl), Bash(.cig/scripts/command-helpers/format-detector.sh), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

- Task resolution: !`.cig/scripts/command-helpers/hierarchy-resolver.sh $ARGUMENTS 2>/dev/null || echo "Task path required"`
- Parent context: !`.cig/scripts/command-helpers/context-inheritance.pl $ARGUMENTS 2>/dev/null || echo "No parent context (top-level task or invalid path)"`

## Your task
Guide the user through the testing phase for task: **$ARGUMENTS**

Follow the 8-step workflow structure:

1. **Resolve Task Directory**: Use hierarchy-resolver.sh
2. **Load Parent Context**: Use context-inheritance.pl for subtasks
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

7. **Check Decomposition Signals**: Review 5 universal signals
8. **Suggest Next Steps**:
   - **Primary**: Move to rollout → `/cig-rollout <task-path>`
   - **Alternative**: Return to implementation if tests reveal defects
   - **Alternative**: Extend testing if coverage is insufficient

## Success Criteria
- [ ] Testing file opened and updated
- [ ] Test strategy defined with test levels
- [ ] Test coverage targets specified
- [ ] Functional test cases documented (Given/When/Then format)
- [ ] Non-functional test cases specified
- [ ] Test environment requirements defined
- [ ] Automation approach documented
- [ ] Next steps suggested
