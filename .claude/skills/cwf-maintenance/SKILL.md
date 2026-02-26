---
name: cwf-maintenance
description: Guide user through maintenance phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

## Scope & Boundaries

**This step**: Complete i-maintenance.md with monitoring plan, support procedures, and ongoing maintenance results.
**Not this step**: Implementation, testing, or initial deployment (complete). Final reflection in j-retrospective.md.
**If blocked or finished**: Call `.cwf/scripts/command-helpers/workflow-manager control --current-step=i-maintenance --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cwf/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cwf/docs/skills/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `.cwf/docs/workflow/workflow-steps.md#maintenance` for detailed maintenance phase guidance.

**Step 6 (Execute)**:
- Open i-maintenance.md (v2.1) or g-maintenance.md (v2.0) or maintenance.md (v1.0)
- **Focus on**: Monitoring requirements, maintenance tasks, incident response, performance optimisation
- **Avoid**: Initial implementation details, design decisions, testing procedures
- Key content: monitoring, alerting, maintenance schedule, common issues, runbooks

**Step 7**: Checkpoint commit. See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `i-maintenance.md`

**Step 8 (Next Steps)**:
- **Primary**: Task complete, ready for retrospective → `/cwf-retrospective <task-path>`
- **Alt**: Create follow-up tasks for identified improvements

## Success Criteria
- [ ] Maintenance file opened and updated
- [ ] Monitoring and alerting configured
- [ ] Maintenance schedule defined
- [ ] Common issues documented with resolutions
- [ ] Next steps suggested
