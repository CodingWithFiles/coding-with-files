---
name: cig-status
description: Show progress across implementation guide hierarchy (v2.0)
user-invocable: true
allowed-tools:
  - Read
  - Bash
---

## Scope & Boundaries

**This step**: Display task progress and workflow status.
**Not this step**: Modifying tasks or advancing workflow phases.

## Context

**Task arguments**: {arguments}

**First**: Run `.cig/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

**Mandatory context** (run before analysis):
- Run `.cig/scripts/command-helpers/workflow-manager status {arguments}` using the Bash tool. This is the primary output — display and analyse the results.

## Workflow

**Arguments**: task-path (optional) — specific task number to show (e.g., "1", "1.1")

### 1. Resolve Task Path (if provided)
- Use `context-manager hierarchy <task-path>` to verify task exists
- If no path: show all tasks from implementation-guide/ root

### 2. Calculate Progress
- **With argument**: `workflow-manager status [task-path]` (auto-enables --workflow)
- **Without argument**: `workflow-manager status` (auto-enables --sort=modified --limit=5)
- Override defaults with explicit flags (--workflow, --no-workflow, --limit=N)

### 3. Display Visual Tree
Format with indicators: check Finished (100%), gear In Progress (1-99%), circle Not Started (0%)

### 4. Provide Context
For tasks in progress: current workflow step, next recommended action, blockers

### 5. Summary Statistics (optional)
If showing all tasks: total by type, overall completion, tasks by status

## Success Criteria
- [ ] Status output retrieved and displayed
- [ ] Progress indicators shown
- [ ] Context provided for in-progress tasks
