---
description: Guide user through implementation execution phase
argument-hint: {task-path}
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/*:*), Bash(git rev-parse:*), Bash(git add:*), Bash(git commit:*)
---

## Scope & Boundaries

**This step**: Now you write code. Execute the implementation steps from d-implementation-plan.md and document actual results in f-implementation-exec.md.
**Not this step**: Planning what to implement (that's d-implementation-plan), testing (that's e-testing-plan + g-testing-exec), or deployment.
**If blocked or finished**: Call `workflow-manager control --current-step=f-implementation-exec --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: !/current-task-wf

!{bash}
.cig/scripts/command-helpers/context-manager location

## Workflow

**Steps 1-4 (Preamble)**: Read `.cig/docs/commands/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `d-implementation-plan.md` for detailed implementation steps, files to modify, and expected changes.

**Step 6 (Execute)**:
- Open f-implementation-exec.md and update as you work
- **Focus on**: Executing planned steps, recording actual results, documenting deviations
- **Avoid**: Changing the plan (update d-implementation-plan.md if plan needs adjustment)
- Status: "In Progress" when starting, "Implemented" when complete, "Blocked" if stuck

**Step 7**: Execute implementation steps systematically per d-implementation-plan.md. Test locally, document results, note deviations.

**Step 8**: Checkpoint commit. See `.cig/docs/commands/checkpoint-commit.md`. Stage: `f-implementation-exec.md` (and any changed files)

**Step 9 (Next Steps)**:
- **Primary**: Move to testing → `/cig-testing-exec <task-path>`
- **Alt**: Document blockers, update status to "Blocked"
- **Alt**: Return to `/cig-implementation-plan` to revise plan
- **Alt**: Return to `/cig-design-plan` if execution reveals design issues

## Success Criteria
- [ ] Task directory resolved, plan reviewed
- [ ] Implementation steps executed according to plan
- [ ] Actual results documented for each step
- [ ] Deviations documented with rationale
- [ ] Next steps suggested with reasoning
