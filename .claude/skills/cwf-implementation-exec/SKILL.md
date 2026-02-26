---
name: cwf-implementation-exec
description: Guide user through implementation execution phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

## Scope & Boundaries

**This step**: Now you write code. Execute the implementation steps from d-implementation-plan.md and document actual results in f-implementation-exec.md.
**Not this step**: Planning what to implement (that's d-implementation-plan), testing (that's e-testing-plan + g-testing-exec), or deployment.
**If blocked or finished**: Call `.cwf/scripts/command-helpers/workflow-manager control --current-step=f-implementation-exec --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cwf/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cwf/docs/skills/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `d-implementation-plan.md` for detailed implementation steps, files to modify, and expected changes.

**Re-execution check**: If `f-implementation-exec.md` already has results from a prior run, read `.cwf/docs/skills/re-execution.md` before proceeding.

**Step 6 (Execute)**:
- Open f-implementation-exec.md and update as you work
- **Focus on**: Executing planned steps, recording actual results, documenting deviations
- **Avoid**: Changing the plan (update d-implementation-plan.md if plan needs adjustment)
- Status: "In Progress" when starting, "Finished" when complete, "Blocked" if stuck

**Step 7**: Execute implementation steps systematically per d-implementation-plan.md. Test locally, document results, note deviations.

**Step 8**: Checkpoint commit. See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `f-implementation-exec.md` (and any changed files)

**Step 9 (Next Steps)**:
- **Primary**: Move to testing → `/cwf-testing-exec <task-path>`
- **Alt**: Document blockers, update status to "Blocked"
- **Alt**: Return to `/cwf-implementation-plan` to revise plan
- **Alt**: Return to `/cwf-design-plan` if execution reveals design issues

## Success Criteria
- [ ] Task directory resolved, plan reviewed
- [ ] Implementation steps executed according to plan
- [ ] Actual results documented for each step
- [ ] Deviations documented with rationale
- [ ] Next steps suggested with reasoning
