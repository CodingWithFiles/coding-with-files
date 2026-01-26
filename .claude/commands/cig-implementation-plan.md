---
description: Guide user through implementation phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver:*), Bash(.cig/scripts/command-helpers/context-inheritance:*), Bash(.cig/scripts/command-helpers/format-detector:*), Bash(.cig/scripts/command-helpers/workflow-control:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Scope & Boundaries

**This step**: Complete the implementation planning document (d-implementation-plan.md) with files to modify, implementation steps, and validation criteria.

**Not this step**: Writing code (that's f-implementation-exec), testing, or deployment.

**If blocked or finished**: Call `workflow-control --current-step=d-implementation-plan --task-path=<path>` to determine next action. See `.cig/docs/workflow/blocker-patterns.md` for detailed blocker handling guidance.

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: $ARGUMENTS

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the implementation phase.

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

   **Status Field**: Use valid status values only. See `.cig/docs/workflow/workflow-steps.md#status-values`.

7. **Check Decomposition Signals**: Review 5 universal signals
8. **Suggest Next Steps**:
   - **Primary**: Move to testing planning → `/cig-testing-plan <task-path>`
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
