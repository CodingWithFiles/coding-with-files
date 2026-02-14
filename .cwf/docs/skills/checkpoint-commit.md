# Checkpoint Commit

After completing a workflow phase, create a checkpoint commit to preserve progress.

## Procedure

1. **Stage** the workflow file for the current phase:
   ```bash
   git add implementation-guide/<task-dir>/<workflow-file>.md
   ```

2. **Commit** with a "why"-focused message:
   ```bash
   git commit -m "Task N: Complete <phase> phase

   <Brief explanation of why — what problem does this solve>

   Co-developed-by: Claude Opus 4.6 <noreply@anthropic.com>"
   ```

3. **Rationale**: Checkpoint commits preserve incremental progress and enable retrospective squashing workflow (Step 10 in cig-retrospective).

See `.cwf/docs/workflow/workflow-steps.md` for phase-specific commit guidance.
