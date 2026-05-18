# Retrospective Extra Steps

Additional steps specific to the retrospective phase, beyond the standard workflow preamble.

## Verify Git Branch (before Step 1)

Before proceeding, verify you're on the correct task branch:

1. Check current branch: `git branch --show-current`
2. Expected format: `{type}/{task-num}-{slug}` (e.g., `feature/44-refactor-template-generation-system`)
3. If on wrong branch: STOP and suggest `git checkout {task-branch}`

**Rationale**: Retrospective must run on task branch so git operations apply to correct branch before merge.

## Verify Task Status (Step 7)

Before documenting retrospective:

1. Ensure all wf step files reflect reality — every step must be in a terminal status
   (Finished, Skipped, Cancelled). Update any that don't.
2. Run `.cwf/scripts/command-helpers/workflow-manager status {task_num} --workflow`
   to confirm the overall task is at 100%.
3. **100% is the norm.** If below 100%: identify and resolve missing work or create
   follow-up tasks. The user must be explicitly informed if the task cannot reach 100%
   before the retrospective proceeds.

## Retrospective Checkpoint Commit

After completing j-retrospective.md, stage the **entire task directory** and commit.
This overrides the single-file staging in `checkpoint-commit.md` (which applies to all
other phases) — status corrections from Step 7 must be included in this commit:

```bash
git add implementation-guide/{task-dir}/
git commit -m "Task {N}: Complete retrospective — {one-line summary}

<Why — what this task accomplished>

Co-developed-by: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

Then validate:

```bash
.cwf/scripts/cwf-manage validate
```

## CHANGELOG.md and BACKLOG.md Update (Step 8)

### 8.1 Update CHANGELOG.md

- Read CHANGELOG.md (first ~100 lines) to understand format pattern
- Create new entry at top for current task:
  - Task number and title
  - Completion date, duration vs estimate
  - Problems addressed, key changes
  - BACKLOG items completed (if any)
- Follow existing entry style

### 8.2 Remove Completed BACKLOG Items

- Use Grep to find all task headers: `^## Task:`
- Use Read with offset/limit to confirm completion
- Use Edit to remove completed items
- Note in CHANGELOG which items were addressed

### 8.3 Add New BACKLOG Items

- Read j-retrospective.md Recommendations/Future Work sections
- Add items with standard format:
  - `## Task: {descriptive-name}`
  - `**Task-Type**: bugfix|chore|feature|hotfix|discovery`
  - `**Priority**: High|Medium|Low`
  - `**Status**: Follow-up from Task X`
  - Description, scope, rationale
  - `**Identified in**: Task X retrospective (j-retrospective.md)`

### 8.4 Stage Changes

```bash
git add CHANGELOG.md BACKLOG.md
```

## Checkpoints Branch and Squash (Step 10)

(Step 9 — `cwf-version-bump` — runs before this; see SKILL.md)

### 10.1 Create Checkpoints Branch

```bash
checkpoints-branch-manager create
```

Preserves all checkpoint commits for future reference.

### 10.2 Squash Commits

```bash
checkpoints-branch-manager show-history  # Find base commit
git reset --soft {base-commit-hash}      # Soft reset to base
git commit -m "Task {N}: {brief title}     # New squashed commit

{Why this change was needed}

Co-developed-by: Claude Opus 4.6 <noreply@anthropic.com>"
```

### 10.3 Verify

```bash
checkpoints-branch-manager verify
```

Confirm all checkpoint commits preserved on checkpoints branch.

## Suggest Merge (Step 12)

(Step 11 — `cwf-version-tag` — runs after the squash; see SKILL.md)

Derive the merge target from the current task's position in the hierarchy:

1. Run `context-manager hierarchy <task-path> --format=json`. Read `parent_path` and (for the current task's branch name) `task_type`, `task_num`, `task_slug`. The current task branch is `<task_type>/<task_num>-<task_slug>`.
2. If `parent_path` is empty, the task is top-level. Target is `main`. Suggest:
   ```bash
   sleep 1 && git checkout main && git merge --ff-only <current-task-branch>
   ```
3. If `parent_path` is non-empty, the task is a subtask. Run `context-manager hierarchy <parent_path> --format=json`; read the parent's `task_type`, `task_num`, `task_slug`. Parent branch is `<type>/<num>-<slug>`. Suggest:
   ```bash
   sleep 1 && git checkout <parent-branch> && git merge --ff-only <current-task-branch>
   ```
4. If the step-3 helper call exits non-zero, print the helper's stderr and the raw `parent_path` value; do **not** emit a `git checkout` line. The user investigates (renamed/missing parent directory) before retrying.

The `sleep 1 && git` prefix is required because Claude Code spawns a background `git` process that briefly holds `.git/index.lock`; the prefix lets users paste the suggestion directly into Claude Code's Bash tool without the lock race. Scope: Bash-tool git calls and user-facing suggested git ff merge commands only.

*Maintainer note: output is for human paste only. If this is ever lifted into a helper that executes the command, switch to list-form `system()` to keep slug interpolation safe.*
