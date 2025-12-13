---
description: Guide user through implementation phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.sh), Bash(.cig/scripts/command-helpers/context-inheritance.pl), Bash(.cig/scripts/command-helpers/format-detector.sh), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

- Task resolution: !`.cig/scripts/command-helpers/hierarchy-resolver.sh $ARGUMENTS 2>/dev/null || echo "Task path required"`
- Parent context: !`.cig/scripts/command-helpers/context-inheritance.pl $ARGUMENTS 2>/dev/null || echo "No parent context (top-level task or invalid path)"`

## Your task
Guide the user through the implementation phase for task: **$ARGUMENTS**

Follow the 8-step workflow structure:

1. **Resolve Task Directory**: Use hierarchy-resolver.sh
2. **Load Parent Context**: Use context-inheritance.pl for subtasks
3. **Present Context Summary**: Show structural map with status markers
4. **LLM Decision**: Read specific parent sections if needed
5. **Reference Workflow Documentation**: Read `.cig/docs/workflow/workflow-steps.md#implementation`
6. **Execute Implementation Workflow**:
   - Open d-implementation.md (v2.0) or implementation.md (v1.0)
   - **Focus on**: Files to modify, implementation steps, code changes, test coverage, validation criteria
   - **Avoid**: Design rationale, business requirements, deployment strategies
   - Follow workflow: Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

   Key content:
   - Files to Modify: Primary and supporting changes
   - Implementation Steps: Numbered, actionable steps with checkboxes
   - Code Changes: Before/after snippets showing approach
   - Test Coverage: Unit, integration, regression tests
   - Validation Criteria: How to verify success

   Key questions:
   - What files need to be created or modified?
   - What is the step-by-step implementation approach?
   - What tests are needed to verify functionality?
   - How will we validate that requirements are met?
   - What are the validation criteria before marking complete?

7. **Check Decomposition Signals**: Review 5 universal signals
8. **Suggest Next Steps**:
   - **Primary**: Move to testing → `/cig-testing <task-path>`
   - **Alternative**: Return to design if implementation reveals design gaps
   - **Alternative**: Create subtasks if implementation is too complex

## Success Criteria
- [ ] Implementation file opened and updated
- [ ] Files to modify identified and documented
- [ ] Implementation steps defined as actionable checklist
- [ ] Code changes illustrated with before/after examples
- [ ] Test coverage specified
- [ ] Validation criteria defined
- [ ] Next steps suggested
