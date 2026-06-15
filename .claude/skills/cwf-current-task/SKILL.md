---
name: cwf-current-task
description: Manage the current task stack for context tracking
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

This skill manages the task stack in `.cwf/task-stack` which tracks the current working context.

Parse user arguments and delegate to the task-stack script:

- **No args**: Show current stack → call `task-stack list`
- **push <num>**: Push task onto stack → call `task-stack push <num>`
- **pop**: Pop task from stack → call `task-stack pop`
- **peek**: Show current task → call `task-stack peek`
- **clear**: Clear entire stack → call `task-stack clear`
- **size**: Show stack size → call `task-stack size`

Use the Bash tool to call:
```bash
.cwf/scripts/command-helpers/task-stack {operation} [args]
```

Display the output to the user.

## Examples

**Show current stack:**
```
User: /cwf-current-task
→ Displays last 5 tasks from stack
```

**Push a task:**
```
User: /cwf-current-task push 34
→ Pushes task 34 onto stack
```

**Pop a task:**
```
User: /cwf-current-task pop
→ Removes and displays top task from stack
```

**Clear stack:**
```
User: /cwf-current-task clear
→ Empties the entire stack
```

## Notes

- The stack file `.cwf/task-stack` is automatically created on first push
- Stack is stored in dirname format (e.g., `34-feature-add-task-stack-script`)
- Task 32 inference system reads this stack for context-aware task detection
- DO NOT directly edit `.cwf/task-stack` - always use this skill
- File is gitignored (user-specific workspace state)
