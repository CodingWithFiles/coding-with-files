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

## Gotchas

1. **Stale status fields**: Before writing j-retrospective.md, run `workflow-manager status {task_num} --workflow` and fix any non-terminal statuses. The stop-stale-status-detector hook catches Backlog only; this manual sweep catches In Progress too. (6+ occurrences: Tasks 65, 67, 81, 84, 98, 103.)
2. **Never execute merge to main**: Step 10 says "Suggest Merge" — output the merge command for the user to run, never execute it yourself. (Caused problems at Tasks 81, 84.)
3. **Don't skip the retrospective**: After testing-exec (g), complete all remaining workflow phases before starting new work. (Task 98 jumped to creating Task 99; Task 84 backfilled wf files retrospectively.)

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
- **Primary**: Suggest merge to user (do not execute): `git checkout main && git merge --ff-only <task-branch>`
- **Alt**: Create follow-up tasks, share learnings

## Success Criteria
- [ ] Retrospective file written with variance analysis, learnings, recommendations
- [ ] Actual Results and Lessons Learned updated in all workflow files
- [ ] All workflow file statuses "Finished"
- [ ] Task verified at 100% via `/cwf-status`
- [ ] CHANGELOG.md and BACKLOG.md updated
- [ ] Checkpoints branch created, commits squashed
