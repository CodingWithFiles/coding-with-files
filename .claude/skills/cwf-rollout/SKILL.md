---
name: cwf-rollout
description: Guide user through rollout phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

## Scope & Boundaries

**This step**: Complete h-rollout.md with deployment plan, rollback procedures, and rollout results.
**Not this step**: Implementation, testing (already done), or long-term maintenance (that's i-maintenance.md).
**If blocked or finished**: Call `.cwf/scripts/command-helpers/workflow-manager control --current-step=h-rollout --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cwf/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cwf/docs/skills/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `.cwf/docs/workflow/workflow-steps.md#rollout` for detailed rollout phase guidance.

**Step 6 (Execute)**:
- Open h-rollout.md (v2.1) or f-rollout.md (v2.0) or rollout.md (v1.0)
- **Focus on**: Deployment strategy, rollout plan, monitoring, rollback plan
- **Avoid**: Implementation details, test cases, design decisions
- Key content: deployment strategy, pre-deployment checklist, phased rollout, monitoring, rollback triggers

**Step 7**: Checkpoint commit. See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `h-rollout.md`

**Step 8 (Next Steps)**:
- **Primary**: Move to maintenance → `/cwf-maintenance <task-path>`
- **Alt**: Execute rollback if issues detected
- **Alt**: Extend monitoring if uncertainty remains

## Success Criteria
- [ ] Rollout file opened and updated
- [ ] Deployment strategy defined with rationale
- [ ] Pre-deployment checklist completed
- [ ] Phased rollout plan specified
- [ ] Rollback plan documented
- [ ] Next steps suggested
