---
name: cwf-delete-task
description: Delete the most-recent task (reverse of /cwf-new-task). Refuses non-most-recent, already-merged, or non-leaf tasks. Use --force to bypass the unmerged-work check only.
user-invocable: true
allowed-tools:
  - Bash
---

## Your task

**Before anything else — anchor the shell to the repo root** so the relative `.cwf/...` commands below resolve from any working directory (run this Bash block first):

```bash
# Anchor to the MAIN repo root so relative .cwf/ paths resolve from any cwd
# (worktree-safe via --git-common-dir; tolerant when not yet in a git repo).
gcd=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
if [ -n "$gcd" ]; then r=$(cd "$(dirname "$gcd")" && pwd); [ "$PWD" = "$r" ] || cd "$r"; fi
```

This skill deletes a task — the reverse of `/cwf-new-task`. It only deletes the
**most-recent** task at its level of the hierarchy. There is no "re-stacking"
of tasks: gaps in numbering are not permitted, so any non-most-recent task is
refused.

Parse user arguments:

- `<task-path>` (required): hierarchical task number (e.g. `136`, `48.1`)
- `--force` (optional): permit deletion when the task branch carries
  non-checkpoint commits. **Does NOT override** the most-recent, leaf,
  already-merged, atomic-refusal, or topmost-stack checks.

Then call the helper via the Bash tool and display the output verbatim:

```bash
.cwf/scripts/command-helpers/task-workflow delete <task-path> [--force]
```

## Refusal cases (all enforced by the helper)

The helper refuses (exit 1) and prints `[CWF] ERROR: <reason>` on STDERR for
any of:

- **invalid task path**
- **task not found**
- **not most-recent** — a higher-numbered sibling exists; deletion would leave
  a renumbering gap
- **has surviving subtasks** — the task is not a leaf
- **branch name fails `git check-ref-format`** — defence-in-depth before any
  destructive ref operation
- **branch is checked out in a worktree** — refuses to delete a branch that
  another worktree holds
- **already merged to main** — the task's squash commit is on main and
  archaeological main is immutable; `--force` does not override this
- **unmerged work on the task branch** — commits whose subjects do not match
  `Task <num>: Complete <phase> phase`; `--force` overrides this case **only**
- **on the task stack but not topmost** — the topmost stack entry must
  match (or the target must be absent from the stack)
- **baseline commit missing/malformed/unreachable** in `a-task-plan.md` —
  required as the FR6 anchor

## Exit codes

| Code | Meaning                                                           |
|------|-------------------------------------------------------------------|
| 0    | Deleted successfully                                              |
| 1    | Refusal check failed; specific reason on STDERR                   |
| 2    | Cleanup hit a partial state; re-run the same command to complete  |

Exit 2 is recoverable: the cleanup sequence is idempotent. Re-running the same
`delete` invocation completes any leftover work (e.g. directory still present
after a failed `remove_tree`).

## Examples

**Delete the most-recent task:**
```
User: /cwf-delete-task 136
→ Removes implementation-guide/136-*/, the feature branch,
  the checkpoints branch if present, and the stack entry if topmost.
```

**Attempt to delete a not-most-recent task:**
```
User: /cwf-delete-task 135
→ [CWF] ERROR: task 135 is not most-recent; task 136 exists
```

**Force-delete a branch with hand-crafted commits:**
```
User: /cwf-delete-task 136 --force
→ [CWF] WARNING: --force: 2 non-checkpoint commit(s) will be lost:
    - wip: experiment
    - hack: try alternative
  [CWF] deleted task 136 (task branch, directory)
```

## Notes

- See `c-design-plan.md` of Task 136 for the full design rationale and the
  full refusal-check pipeline.
- See `.cwf/docs/glossary.md#archaeological-main` for why merged tasks cannot
  be deleted.
- Stack manipulation routes exclusively through the `task-stack` helper
  (flock-protected); this skill never edits `.cwf/task-stack` directly.
