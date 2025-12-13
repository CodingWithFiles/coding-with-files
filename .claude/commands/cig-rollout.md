---
description: Guide user through rollout phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.sh), Bash(.cig/scripts/command-helpers/context-inheritance.pl), Bash(.cig/scripts/command-helpers/format-detector.sh), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

- Task resolution: !`.cig/scripts/command-helpers/hierarchy-resolver.sh $ARGUMENTS 2>/dev/null || echo "Task path required"`
- Parent context: !`.cig/scripts/command-helpers/context-inheritance.pl $ARGUMENTS 2>/dev/null || echo "No parent context (top-level task or invalid path)"`

## Your task
Guide the user through the rollout phase for task: **$ARGUMENTS**

Follow the 8-step workflow structure:

1. **Resolve Task Directory**: Use hierarchy-resolver.sh
2. **Load Parent Context**: Use context-inheritance.pl for subtasks
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
