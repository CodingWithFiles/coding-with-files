---
description: Guide user through implementation execution phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(git rev-parse:*), Bash(egrep:*), Bash(echo:*), Bash(find:*), Bash(.cig/scripts/command-helpers/*:*), Bash(git:*)
---

## Scope & Boundaries

**This step**: Now you write code. Execute the implementation steps from d-implementation-plan.md and document actual results in f-implementation-exec.md.

**Not this step**: Planning what to implement (that's d-implementation-plan), testing (that's e-testing-plan + g-testing-exec), or deployment.

**If blocked or finished**: Call `workflow-manager control --current-step=f-implementation-exec --task-path=<path>` to determine next action. See `.cig/docs/workflow/blocker-patterns.md` for detailed blocker handling guidance.

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: $ARGUMENTS

**Current task/workflow (if available)**: !/current-task-wf

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the implementation execution phase.

**Implementation**: First ensure we're in git repository root:

!{bash}
.cig/scripts/command-helpers/context-manager location

**CRITICAL - Argument Parsing**:
- If task arguments provided: Extract the FIRST space-separated word as the task path
- If NO task arguments: Use task_num from "Current task/workflow" context above
- Any additional words after the first provide user context about their intent
- Use the extra words to understand what the user wants, but do NOT pass them to script calls
- Example: "11 implement the feature" → task path is "11", extra text explains what to do
- If neither arguments nor inference available: Error "Cannot determine task. Specify task number or ensure context is inferrable."

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
- If valid: call `.cig/scripts/command-helpers/context-manager hierarchy <task-path>` using the Bash tool
- If invalid: inform user the task path format is invalid, do not invoke script
- If task not found, provide clear error with available tasks
- Extract task number, type, and slug from resolution

2. **Load Parent Context**:

If this is a subtask (not top-level), load parent context for inherited context:
- Use the validated task path from Step 1
- Call `.cig/scripts/command-helpers/context-manager inheritance <task-path>` using the Bash tool
- Parent context includes: file paths, status markers, section headers, line ranges
- This provides ~50-100 tokens per parent instead of 500-1000 for full files

3. **Present Context Summary**:

Present the parent context structural map to help inform execution:
- Show navigable links with file paths and line ranges
- Display status markers to indicate reliability of parent context
- Highlight key parent decisions that may influence this task's execution

4. **LLM Decision Point - Read Parent Details**:

Based on the structural map, decide if you need to read specific parent sections:
- Use Read tool with offset/limit parameters from structural map
- Only read sections that directly inform this task's execution
- Skip irrelevant parent context to conserve tokens

5. **Reference Planning File**:

Read the implementation plan to understand what needs to be executed:
- Read `d-implementation-plan.md` for detailed implementation steps
- Understand the planned approach, files to modify, and expected changes
- Review any design references or constraints

6. **Execute Implementation Workflow**:

Open and work with the execution file (f-implementation-exec.md):
- Use `context-manager version <task-dir> <workflow-file>` to check version
- **Focus on**: Executing planned steps, recording actual results, documenting deviations
- **Avoid**: Changing the plan (update d-implementation-plan.md if plan needs adjustment)
- Capture: What was actually done, what deviations occurred, what blockers were encountered

Key questions to address:
- What steps from the plan have been executed?
- What were the actual results for each step?
- Did any steps deviate from the plan? Why?
- Were any blockers encountered during execution?
- What remains to be done?

**Status Field**: Use valid status values only. See `.cig/docs/workflow/workflow-steps.md#status-values`.
- Update to "In Progress" when starting execution
- Update to "Implemented" when all implementation steps are complete
- Update to "Blocked" if blockers prevent progress

7. **Execute Implementation Steps**:

Work through the implementation plan systematically:
- Execute steps sequentially as planned in d-implementation-plan.md
- Make code changes according to the design
- Test changes locally to verify they work
- Document actual results in f-implementation-exec.md
- Note any deviations from the plan with rationale

8. **Suggest Next Steps with Reasoning**:

Analyze the execution outcome and suggest the next step:

**Primary Next Step** (if implementation is complete):
- Move to testing plan: `/cig-testing-plan <task-path>`
- Rationale: Implementation complete, now plan testing approach

**Alternative Paths**:
- If blockers encountered → Document in blocker section, update status to "Blocked"
- If plan proves insufficient → Return to `/cig-implementation-plan <task-path>` to revise plan
- If execution reveals design issues → Return to `/cig-design-plan <task-path>` to address gaps
- If execution is incomplete → Continue with remaining steps, update status

Provide clear reasoning for the suggested path based on execution outcome.

## Success Criteria
- [ ] Task directory resolved successfully
- [ ] Parent context loaded (if applicable) and relevant sections reviewed
- [ ] Implementation plan (d-implementation-plan.md) reviewed
- [ ] Execution file (f-implementation-exec.md) opened and updated
- [ ] Implementation steps executed according to plan
- [ ] Actual results documented for each step
- [ ] Deviations from plan documented with rationale
- [ ] Blockers documented (if encountered)
- [ ] Next steps suggested with clear reasoning
