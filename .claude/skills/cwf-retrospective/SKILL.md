---
name: cwf-retrospective
description: Guide user through retrospective phase
effort: low
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

## Gotchas

1. **Stale status fields**: Before writing j-retrospective.md, run `workflow-manager status {task_num} --workflow` and fix any non-terminal statuses. The stop-stale-status-detector hook catches Backlog only; this manual sweep catches In Progress too. This is the most recurring workflow error.
2. **Never execute merge to main**: Step 12 suggests the merge — output the command for the user to run, never execute it yourself. Merges are a human decision.
3. **Don't skip the retrospective**: After testing-exec (g), complete all remaining workflow phases before starting new work. Jumping to new tasks or backfilling phases after the fact leaves the current task incomplete and workflow docs inaccurate.
4. **Do not absorb hash drift at retrospective time**: if `cwf-manage validate` reports `sha256` drift, the fix belongs in the task that originally modified the file, in-diff (see `.cwf/docs/conventions/hash-updates.md`). Recomputing a hash during retrospective to clear validate output silently signs whatever shape the file has now. Surface the drift instead; either re-open the originating task or schedule a dedicated follow-up task (the Task 149 pattern).

## Scope & Boundaries

**This step**: Complete j-retrospective.md with learnings, metrics analysis, and process improvements.
**Not this step**: Implementation, testing, or deployment (those are complete). This is reflection only.
**If blocked or finished**: Call `.cwf/scripts/command-helpers/workflow-manager control --current-step=j-retrospective --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cwf/scripts/command-helpers/task-context-inference` using the Bash tool.

**Before anything else — anchor the shell to the repo root** so the relative `.cwf/...` commands below resolve from any working directory (run this Bash block first):

```bash
# Anchor to the MAIN repo root so relative .cwf/ paths resolve from any cwd
# (worktree-safe via --git-common-dir; tolerant when not yet in a git repo).
gcd=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
if [ -n "$gcd" ]; then r=$(cd "$(dirname "$gcd")" && pwd); [ "$PWD" = "$r" ] || cd "$r"; fi
```

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Pre-Step**: Verify git branch. Read `.cwf/docs/skills/retrospective-extras.md#verify-git-branch` — must be on task branch before proceeding.

**Steps 1-4 (Preamble)**: Read `.cwf/docs/skills/workflow-preamble.md` and follow Steps 1-4. Also read all task workflow files for retrospective context.

**Step 5**: Read `.cwf/docs/workflow/workflow-steps/retrospective.md` for detailed retrospective guidance.

**Step 6**: Verify task status. Read `.cwf/docs/skills/retrospective-extras.md#verify-task-status`. All phases must be "Finished" (100%) before retrospective.

**Step 7 (Execute)**:
- Open j-retrospective.md
- **Focus on**: Variance analysis, what went well, what could be improved, key learnings, recommendations
- Extract planning data from a-task-plan.md, gather actual results, calculate variances
- Update Actual Results and Lessons Learned sections in ALL workflow files

**Step 8**: Update CHANGELOG.md and BACKLOG.md. Read `.cwf/docs/skills/retrospective-extras.md#changelogmd-and-backlogmd-update` for the full workflow.

**Step 9**: Bump version. Run `.cwf/scripts/command-helpers/cwf-version-bump --task-num={current_task_num}`. Honours `wf_step_config.retrospective.bump_version` in `cwf-project.json` (default: true). On `bumped: v{X}`, the resulting `cwf-project.json` change is staged together with `j-retrospective.md` for the j-phase checkpoint. On `skipped` or `already at v{X}`, nothing further to stage. For a subtask (decimal `current_task_num`) the helper is a deterministic no-op reporting `skipped: ...` — version actions apply to top-level tasks only. See `.cwf/docs/workflow/versioning-standard.md`.

**Step 10**: Create checkpoints branch and squash. Read `.cwf/docs/skills/retrospective-extras.md#checkpoints-branch-and-squash` for the full workflow.

**Step 11**: Tag version. Run `.cwf/scripts/command-helpers/cwf-version-tag --task-num={current_task_num} --message="Task {current_task_num}"` after the squash so any tag points at the final commit. Honours `wf_step_config.retrospective.tag_version` (default: false — CwF itself never tags from the script; tagging is human-only per `CLAUDE.md`). External adopters with `tag_version: true` get the annotated tag. For a subtask (decimal `current_task_num`) this is a deterministic no-op (`skipped: ...`) — only top-level tasks are tagged.

**Step 12 (Next Steps)**:
- **Primary**: Suggest merge to user (do not execute). Read `.cwf/docs/skills/retrospective-extras.md#suggest-merge-step-12` for the derivation rule (covers top-level and subtask cases).
- **Alt**: Create follow-up tasks, share learnings

## Success Criteria
- [ ] Retrospective file written with variance analysis, learnings, recommendations
- [ ] Actual Results and Lessons Learned updated in all workflow files
- [ ] All workflow file statuses "Finished"
- [ ] Task verified at 100% via `/cwf-status`
- [ ] CHANGELOG.md and BACKLOG.md updated
- [ ] `cwf-version-bump` invoked (Step 9); outcome reported
- [ ] Checkpoints branch created, commits squashed
- [ ] `cwf-version-tag` invoked (Step 11); outcome reported
