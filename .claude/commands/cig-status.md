---
description: Show progress across implementation guide hierarchy (v2.0)
argument-hint: [{task-path}]
allowed-tools: Read, Bash(.cig/scripts/command-helpers/*:*), Bash(git rev-parse:*)
---

## Context
- Task hierarchy with progress: !`.cig/scripts/command-helpers/workflow-manager status {arguments} 2>/dev/null || echo "Unable to load status"`

## Your task
Analyse completion status for: **{arguments}** (or all tasks if no path specified)

!{bash}
.cig/scripts/command-helpers/context-manager location

**Arguments**: task-path (optional) — specific task number to show (e.g., "1", "1.1")

**Steps**:

### 1. Resolve Task Path (if provided)
- Use `context-manager hierarchy <task-path>` to verify task exists
- If no path: show all tasks from implementation-guide/ root

### 2. Calculate Progress
- **With argument**: `workflow-manager status [task-path]` (auto-enables --workflow)
- **Without argument**: `workflow-manager status` (auto-enables --sort=modified --limit=5)
- Override defaults with explicit flags (--workflow, --no-workflow, --limit=N)

### 3. Display Visual Tree
Format with indicators: ✓ Finished (100%), ⚙️ In Progress (1-99%), ○ Not Started (0%)

### 4. Provide Context
For tasks in progress: current workflow step, next recommended action, blockers

### 5. Summary Statistics (optional)
If showing all tasks: total by type, overall completion, tasks by status
