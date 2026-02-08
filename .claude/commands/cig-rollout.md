---
description: Guide user through rollout phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/*:*), Bash(git rev-parse:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Scope & Boundaries

**This step**: Complete the rollout document (h-rollout.md) with deployment plan, rollback procedures, and rollout results.

**Not this step**: Implementation, testing (those are already done), or long-term maintenance (that's i-maintenance.md).

**If blocked or finished**: Call `workflow-manager control --current-step=h-rollout --task-path=<path>` to determine next action. See `.cig/docs/workflow/blocker-patterns.md` for detailed blocker handling guidance.

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: $ARGUMENTS

**Current task/workflow (if available)**: !/current-task-wf

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the rollout phase.

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
5. **Reference Workflow Documentation**: Read `.cig/docs/workflow/workflow-steps.md#rollout`
6. **Execute Rollout Workflow**:
   - Open f-rollout.md (v2.0) or rollout.md (v1.0)
   - **Focus on**: Deployment strategy, rollout plan, monitoring, rollback plan
   - **Avoid**: Implementation details, test cases, design decisions

   Key content:
   - Deployment Strategy: Release type (blue-green, rolling, canary), rationale, rollback plan
   - Pre-Deployment Checklist: Code review, tests, security, performance, documentation
   - Rollout Plan: Phased rollout (limited → gradual → full release)
   - Monitoring: Key metrics, alerting rules
   - Rollback Plan: Triggers and procedure

   Key questions:
   - What deployment strategy is appropriate (blue-green, rolling, canary)?
   - What pre-deployment checks must pass?
   - How will the rollout be phased (limited → gradual → full)?
   - What metrics will be monitored during rollout?
   - What are the rollback triggers and procedures?
   - What are the success criteria for each rollout phase?

   **Status Field**: Use valid status values only. See `.cig/docs/workflow/workflow-steps.md#status-values`.

7. **Check Decomposition Signals**: Review 5 universal signals
8. **Suggest Next Steps**:
   - **Primary**: Move to maintenance → `/cig-maintenance <task-path>`
   - **Alternative**: Execute rollback if issues detected
   - **Alternative**: Extend monitoring period if uncertainty remains

## Success Criteria
- [ ] Rollout file opened and updated
- [ ] Deployment strategy defined with rationale
- [ ] Pre-deployment checklist completed
- [ ] Phased rollout plan specified
- [ ] Monitoring and alerting configured
- [ ] Rollback plan documented and tested
- [ ] Next steps suggested
