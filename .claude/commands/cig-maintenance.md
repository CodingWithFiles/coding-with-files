---
description: Guide user through maintenance phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.sh), Bash(.cig/scripts/command-helpers/context-inheritance.pl), Bash(.cig/scripts/command-helpers/format-detector.sh), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

- Task resolution: !`.cig/scripts/command-helpers/hierarchy-resolver.sh $ARGUMENTS 2>/dev/null || echo "Task path required"`
- Parent context: !`.cig/scripts/command-helpers/context-inheritance.pl $ARGUMENTS 2>/dev/null || echo "No parent context (top-level task or invalid path)"`

## Your task
Guide the user through the maintenance phase for task: **$ARGUMENTS**

Follow the 8-step workflow structure:

1. **Resolve Task Directory**: Use hierarchy-resolver.sh
2. **Load Parent Context**: Use context-inheritance.pl for subtasks
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
