---
description: Guide user through requirements phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver:*), Bash(.cig/scripts/command-helpers/context-inheritance:*), Bash(.cig/scripts/command-helpers/format-detector:*), Bash(.cig/scripts/command-helpers/workflow-control:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Scope & Boundaries

**This step**: Complete the requirements planning document (b-requirements-plan.md) with functional requirements, non-functional requirements, and acceptance criteria.

**Not this step**: Design decisions, implementation planning, code writing, or testing.

**If blocked or finished**: Call `workflow-control --current-step=b-requirements-plan --task-path=<path>` to determine next action. See `.cig/docs/workflow/blocker-patterns.md` for detailed blocker handling guidance.

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: $ARGUMENTS

**Current task/workflow (if available)**: !/current-task-wf

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the requirements phase.

**CRITICAL - Argument Parsing**:
- If task arguments provided: Extract the FIRST space-separated word as the task path
- If NO task arguments: Use task_num from "Current task/workflow" context above
- Any additional words after the first provide user context about their intent
- Use the extra words to understand what the user wants, but do NOT pass them to script calls
- Example: "11 update the design" → task path is "11", extra text explains what to do
- If neither arguments nor inference available: Error "Cannot determine task. Specify task number or ensure context is inferrable."

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
5. **Reference Workflow Documentation**: Read `.cig/docs/workflow/workflow-steps.md#requirements`
6. **Execute Requirements Workflow**:
   - Open b-requirements.md (v2.0) or requirements.md (v1.0)
   - **Focus on**: Functional requirements (FR), non-functional requirements (NFR), acceptance criteria
   - **Avoid**: Implementation approaches, code structure, deployment details
   - Define: User stories, performance requirements, security requirements, constraints

   Key questions:
   - What must the system do? (Functional requirements)
   - How well must it do it? (Non-functional requirements: performance, usability, maintainability, security, reliability)
   - How do we verify success? (Acceptance criteria)
   - What are the hard constraints?

   **Status Field**: Use valid status values only. See `.cig/docs/workflow/workflow-steps.md#status-values`.

7. **Check Decomposition Signals**: Review 5 universal signals
8. **Suggest Next Steps**:
   - **Primary**: Move to design → `/cig-design <task-path>`
   - **Alternative**: Return to planning if requirements reveal scope issues
   - **Alternative**: Create subtasks if complexity signals triggered

## Success Criteria
- [ ] Requirements file opened and updated
- [ ] Functional requirements (FR1-FRn) defined with clear acceptance criteria
- [ ] Non-functional requirements (NFR1-NFR5) specified measurably
- [ ] Acceptance criteria defined as testable checkpoints
- [ ] Constraints documented
- [ ] Next steps suggested
