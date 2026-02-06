---
description: Guide user through maintenance phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver:*), Bash(.cig/scripts/command-helpers/context-inheritance:*), Bash(.cig/scripts/command-helpers/format-detector:*), Bash(.cig/scripts/command-helpers/workflow-control:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Scope & Boundaries

**This step**: Complete the maintenance document (i-maintenance.md) with monitoring plan, support procedures, and ongoing maintenance results.

**Not this step**: Implementation, testing, or initial deployment (those are complete). Final reflection comes in j-retrospective.md.

**If blocked or finished**: Call `workflow-control --current-step=i-maintenance --task-path=<path>` to determine next action. See `.cig/docs/workflow/blocker-patterns.md` for detailed blocker handling guidance.

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: $ARGUMENTS

**Current task/workflow (if available)**: !/current-task-wf

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the maintenance phase.

**Implementation**: First ensure we're in git repository root:

!{bash}
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository. CIG commands must be run from within a git repository."
    exit 1
fi

cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"

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
5. **Reference Workflow Documentation**: Read `.cig/docs/workflow/workflow-steps.md#maintenance`
6. **Execute Maintenance Workflow**:
   - Open g-maintenance.md (v2.0) or maintenance.md (v1.0)
   - **Focus on**: Monitoring requirements, maintenance tasks, incident response, performance optimisation
   - **Avoid**: Initial implementation details, design decisions, testing procedures

   Key content:
   - Monitoring Requirements: System health, application metrics, alerting rules
   - Maintenance Tasks: Regular schedule (daily, weekly, monthly, quarterly)
   - Incident Response: Common issues, troubleshooting guide, escalation procedures
   - Performance Optimisation: Optimisation areas, scaling strategy
   - Documentation: Runbooks, knowledge base

   Key questions:
   - What monitoring is needed (uptime, performance, errors, business KPIs)?
   - What are the alerting rules and escalation procedures?
   - What regular maintenance tasks are required?
   - What are common issues and their resolutions?
   - What performance optimisation opportunities exist?
   - What scaling strategy is appropriate?
   - What runbooks and documentation are needed?

   **Status Field**: Use valid status values only. See `.cig/docs/workflow/workflow-steps.md#status-values`.

7. **Check Decomposition Signals**: Review 5 universal signals (if maintenance tasks are complex)
8. **Suggest Next Steps**:
   - **Primary**: Task is complete, ready for retrospective → `/cig-retrospective <task-path>`
   - **Alternative**: Create follow-up tasks for identified improvements
   - **Alternative**: Update monitoring if new issues discovered

## Success Criteria
- [ ] Maintenance file opened and updated
- [ ] Monitoring and alerting configured
- [ ] Maintenance schedule defined
- [ ] Common issues documented with resolutions
- [ ] Incident response procedures established
- [ ] Performance optimisation strategy defined
- [ ] Runbooks and documentation created
- [ ] Next steps suggested
