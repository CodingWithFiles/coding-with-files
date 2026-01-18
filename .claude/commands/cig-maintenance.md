---
description: Guide user through maintenance phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.pl:*), Bash(.cig/scripts/command-helpers/context-inheritance.pl:*), Bash(.cig/scripts/command-helpers/format-detector.pl:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: $ARGUMENTS

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the maintenance phase.

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

## Blocker Handling

**Common Blockers in Maintenance**:
- Monitoring tools not available → Create infrastructure subtask for monitoring setup
- Performance issues discovered → Create optimization subtask
- Security vulnerabilities found → Create security fix hotfix task immediately
- Scaling issues emerging → Create scaling subtask or infrastructure task
- Documentation gaps prevent support → Create documentation subtask

**Reversion Guidance**:
- If critical issues found: Create hotfix task, document in i-maintenance.md
- If monitoring infrastructure missing: Update status to "Blocked", create setup task
- Document the blocker in "Actual Results" section of i-maintenance.md
- Update status to "Blocked" until monitoring infrastructure is ready
- When blocker resolved, complete maintenance planning

**When to Revert**:
- Maintenance phase reveals the rollout was premature
- Critical monitoring gaps indicate system is not production-ready
- Performance issues require redesign rather than optimization

## Success Criteria
- [ ] Maintenance file opened and updated
- [ ] Monitoring and alerting configured
- [ ] Maintenance schedule defined
- [ ] Common issues documented with resolutions
- [ ] Incident response procedures established
- [ ] Performance optimisation strategy defined
- [ ] Runbooks and documentation created
- [ ] Next steps suggested
