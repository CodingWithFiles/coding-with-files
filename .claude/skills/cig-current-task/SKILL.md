---
name: cig-current-task
description: Manage the current task stack for context tracking
user-invocable: true
allowed-tools:
  - Bash
---

## Your task

This skill manages the task stack in `.cig/task-stack` which tracks the current working context.

Parse user arguments and delegate to the task-stack script:

- **No args**: Show current stack → call `task-stack list`
- **push <num>**: Push task onto stack → call `task-stack push <num>`
- **pop**: Pop task from stack → call `task-stack pop`
- **peek**: Show current task → call `task-stack peek`
- **clear**: Clear entire stack → call `task-stack clear`
- **size**: Show stack size → call `task-stack size`

Use the Bash tool to call:
```bash
.cig/scripts/command-helpers/task-stack {operation} [args]
```

Display the output to the user.

## Examples

**Show current stack:**
```
User: /cig-current-task
→ Displays last 5 tasks from stack
```

**Push a task:**
```
User: /cig-current-task push 34
→ Pushes task 34 onto stack
```

**Pop a task:**
```
User: /cig-current-task pop
→ Removes and displays top task from stack
```

**Clear stack:**
```
User: /cig-current-task clear
→ Empties the entire stack
```

## Notes

- The stack file `.cig/task-stack` is automatically created on first push
- Stack is stored in dirname format (e.g., `34-feature-add-task-stack-script`)
- Task 32 inference system reads this stack for context-aware task detection
- DO NOT directly edit `.cig/task-stack` - always use this skill
- File is gitignored (user-specific workspace state)
