---
name: cig-rollout
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
**If blocked or finished**: Call `workflow-manager control --current-step=h-rollout --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cig/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cig/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cig/docs/skills/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `.cig/docs/workflow/workflow-steps.md#rollout` for detailed rollout phase guidance.

**Step 6 (Execute)**:
- Open h-rollout.md (v2.1) or f-rollout.md (v2.0) or rollout.md (v1.0)
- **Focus on**: Deployment strategy, rollout plan, monitoring, rollback plan
- **Avoid**: Implementation details, test cases, design decisions
- Key content: deployment strategy, pre-deployment checklist, phased rollout, monitoring, rollback triggers

**Step 7**: Check decomposition signals. See `.cig/docs/workflow/decomposition-guide.md`.

**Step 8**: Checkpoint commit. See `.cig/docs/skills/checkpoint-commit.md`. Stage: `h-rollout.md`

**Step 9 (Next Steps)**:
- **Primary**: Move to maintenance → `/cig-maintenance <task-path>`
- **Alt**: Execute rollback if issues detected
- **Alt**: Extend monitoring if uncertainty remains

## Success Criteria
- [ ] Rollout file opened and updated
- [ ] Deployment strategy defined with rationale
- [ ] Pre-deployment checklist completed
- [ ] Phased rollout plan specified
- [ ] Rollback plan documented
- [ ] Next steps suggested
