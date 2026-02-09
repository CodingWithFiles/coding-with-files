---
description: Guide user through design phase
argument-hint: {task-path}
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/*:*), Bash(git rev-parse:*), Bash(git add:*), Bash(git commit:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Scope & Boundaries

**This step**: Complete the design planning document (c-design-plan.md) with architecture decisions, component design, and interface specifications.

**Not this step**: Implementation (that's d-implementation-plan + f-implementation-exec), testing, or deployment.

**If blocked or finished**: Call `workflow-manager control --current-step=c-design-plan --task-path=<path>` to determine next action. See `.cig/docs/workflow/blocker-patterns.md` for detailed blocker handling guidance.

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: {arguments}

**Current task/workflow (if available)**: !/current-task-wf

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the design phase.

**Implementation**: First ensure we're in git repository root:

!{bash}
.cig/scripts/command-helpers/context-manager location

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
   - If valid: call `.cig/scripts/command-helpers/context-manager hierarchy <task-path>` using the Bash tool
   - If invalid: inform user the task path format is invalid, do not invoke script

2. **Load Parent Context**:
   - Use the validated task path from step 1
   - Call `.cig/scripts/command-helpers/context-manager inheritance <task-path>` using the Bash tool
3. **Present Context Summary**: Show structural map with status markers
4. **LLM Decision**: Read specific parent sections if needed
5. **Reference Workflow Documentation**: Read `.cig/docs/workflow/workflow-steps.md#design`
6. **Execute Design Workflow**:
   - Open c-design.md (v2.0) or design.md (v1.0)
   - **Focus on**: Architecture decisions, component design, API contracts, data models, interface design
   - **Avoid**: Detailed implementation code, specific test cases, deployment procedures
   - Apply design priorities: Testability → Readability → Consistency → Simplicity → Reversibility
   - Follow architecture preferences: Composition over inheritance, interfaces over singletons, explicit over implicit

   Key questions:
   - What architecture pattern best fits the requirements?
   - What are the key components and their responsibilities?
   - How do components interact (data flow)?
   - What are the critical interfaces (API endpoints, data models)?
   - What constraints influenced the design?
   - What are the trade-offs of this approach?

   **Status Field**: Use valid status values only. See `.cig/docs/workflow/workflow-steps.md#status-values`.

7. **Check Decomposition Signals**: Review 5 universal signals
8. **Create Checkpoint Commit**:

After completing the design phase, create a checkpoint commit to preserve progress:

```bash
git add implementation-guide/<task-dir>/c-design-plan.md
git commit -m "Task N: Complete design phase

<Brief explanation of why - what problem does this solve>

Co-developed-by: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Rationale**: Checkpoint commits preserve incremental progress and enable retrospective squashing workflow (Step 10 in cig-retrospective).

See `.cig/docs/workflow/workflow-steps.md#design` for detailed checkpoint commit guidance.

9. **Suggest Next Steps**:
   - **Primary**: Move to implementation → `/cig-implementation <task-path>`
   - **Alternative**: Return to requirements if design reveals missing requirements
   - **Alternative**: Create spike/prototype task if design uncertainty is high

## Success Criteria
- [ ] Design file opened and updated
- [ ] Architecture choice documented with rationale and trade-offs
- [ ] Component overview defined with clear responsibilities
- [ ] Data flow documented
- [ ] Interface design specified (API endpoints, data models)
- [ ] Design validated and approved
- [ ] Next steps suggested
