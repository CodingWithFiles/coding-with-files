# Checkpoint Commit

After completing a workflow phase, create a checkpoint commit to preserve progress.

## Script (primary method)

Run `git status --untracked-files=all` first to see every untracked or unstaged
path — `git diff` alone misses untracked files and tracked-but-unstaged changes
that the commit will silently exclude. Stage any non-wf files changed in this
phase, then run:

```bash
.cwf/scripts/command-helpers/cwf-checkpoint-commit {task-path} {phase-letter} "{why-message}"
```

The script handles: status update → stage wf file → formatted commit → `cwf-manage validate`.

Example:
```bash
git add .cwf/scripts/command-helpers/new-script   # stage non-wf files first
.cwf/scripts/command-helpers/cwf-checkpoint-commit 102 f "Implement the checkpoint commit helper script"
```

## Manual Procedure (reference)

If the script is unavailable or you need finer control:

1. **Update status** in the current phase's workflow file:
   Set `**Status**: Finished` (and update `**Next Action**` if needed) before staging —
   this keeps `cwf-status` accurate throughout the task.

2. **Stage** the workflow file for the current phase:
   ```bash
   git add implementation-guide/{task-dir}/{workflow-file}.md
   ```

3. **Commit** with a "why"-focused message:
   ```bash
   git commit -m "Task {N}: Complete {phase} phase

   <Brief explanation of why — what problem does this solve>

   Co-developed-by: Claude Opus 4.6 <noreply@anthropic.com>"
   ```

4. **Validate** (post-commit guard):
   ```bash
   .cwf/scripts/cwf-manage validate
   ```
   If violations are reported, fix them before proceeding to the next skill.

## Rationale

Checkpoint commits preserve incremental progress and enable retrospective squashing workflow (Step 10 in retrospective).

See `.cwf/docs/workflow/workflow-steps.md` for phase-specific commit guidance.
