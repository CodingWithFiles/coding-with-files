---
description: Guide user through rollout phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.pl:*), Bash(.cig/scripts/command-helpers/context-inheritance.pl:*), Bash(.cig/scripts/command-helpers/format-detector.pl:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: $ARGUMENTS

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the rollout phase.

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
   - If valid: call `.cig/scripts/command-helpers/hierarchy-resolver.pl <task-path>` using the Bash tool
   - If invalid: inform user the task path format is invalid, do not invoke script

2. **Load Parent Context**:
   - Use the validated task path from step 1
   - Call `.cig/scripts/command-helpers/context-inheritance.pl <task-path>` using the Bash tool
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

## Blocker Handling

**Common Blockers in Rollout**:
- Production environment not ready → Create infrastructure preparation subtask
- Rollback procedure untested → Execute rollback dry run before proceeding
- Monitoring infrastructure missing → Set up monitoring before rollout
- Stakeholders not ready for rollout → Schedule alignment meeting, document concerns
- Critical production issue discovered → Execute rollback, create hotfix task

**Reversion Guidance**:
- If rollback needed: Document rollback in h-rollout.md, create hotfix task for issues
- If environment not ready: Update status to "Blocked", document infrastructure gaps
- If monitoring gaps found: Create monitoring subtask, complete before rollout
- Document the blocker in "Actual Results" section of h-rollout.md
- Update status to "Blocked" until blocker is resolved

**When to Revert**:
- Rollout reveals critical defects that escaped testing
- Production environment incompatibilities discovered
- Stakeholder concerns indicate premature rollout

## Success Criteria
- [ ] Rollout file opened and updated
- [ ] Deployment strategy defined with rationale
- [ ] Pre-deployment checklist completed
- [ ] Phased rollout plan specified
- [ ] Monitoring and alerting configured
- [ ] Rollback plan documented and tested
- [ ] Next steps suggested
