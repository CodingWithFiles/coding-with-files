---
name: cwf-retrospective
description: Guide user through retrospective phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

## Scope & Boundaries

**This step**: Complete j-retrospective.md with learnings, metrics analysis, and process improvements.
**Not this step**: Implementation, testing, or deployment (those are complete). This is reflection only.
**If blocked or finished**: Call `.cwf/scripts/command-helpers/workflow-manager control --current-step=j-retrospective --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cwf/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Pre-Step**: Verify git branch. Read `.cwf/docs/skills/retrospective-extras.md#verify-git-branch` — must be on task branch before proceeding.

**Steps 1-4 (Preamble)**: Read `.cwf/docs/skills/workflow-preamble.md` and follow Steps 1-4. Also read all task workflow files for retrospective context.

**Step 5**: Read `.cwf/docs/workflow/workflow-steps.md#retrospective` for detailed retrospective guidance.

**Step 6**: Verify task status. Read `.cwf/docs/skills/retrospective-extras.md#verify-task-status`. All phases must be "Finished" (100%) before retrospective.

**Step 7 (Execute)**:
- Open j-retrospective.md
- **Focus on**: Variance analysis, what went well, what could be improved, key learnings, recommendations
- Extract planning data from a-task-plan.md, gather actual results, calculate variances
- Update Actual Results and Lessons Learned sections in ALL workflow files

**Step 8**: Update CHANGELOG.md and BACKLOG.md. Read `.cwf/docs/skills/retrospective-extras.md#changelogmd-and-backlogmd-update` for the full workflow.

**Step 9**: Create checkpoints branch and squash. Read `.cwf/docs/skills/retrospective-extras.md#checkpoints-branch-and-squash` for the full workflow.

**Step 10 (Next Steps)**:
- **Primary**: Merge to main → `git checkout main && git merge --ff-only <task-branch>`
- **Alt**: Create follow-up tasks, share learnings

## Success Criteria
- [ ] Retrospective file written with variance analysis, learnings, recommendations
- [ ] Actual Results and Lessons Learned updated in all workflow files
- [ ] All workflow file statuses "Finished"
- [ ] Task verified at 100% via `/cwf-status`
- [ ] CHANGELOG.md and BACKLOG.md updated
- [ ] Checkpoints branch created, commits squashed
