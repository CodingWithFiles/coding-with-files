---
description: Show progress across implementation guide hierarchy (v2.0)
argument-hint: [{task-path}]
allowed-tools: Read, Bash(.cig/scripts/command-helpers/*:*), Bash(git rev-parse:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
- Task hierarchy with progress: !`.cig/scripts/command-helpers/workflow-manager status {arguments} 2>/dev/null || echo "Unable to load status"`

## Your task
Analyze completion status for: **{arguments}** (or all tasks if no path specified)

**Implementation**: First ensure we're in git repository root:

!{bash}
.cig/scripts/command-helpers/context-manager location

**Helper scripts location**: `.cig/scripts/command-helpers/`

**Arguments**:
- task-path (optional): Specific task number to show (e.g., "1", "1.1") - shows task and all descendants
- No argument: Show all tasks in hierarchy

**Examples**:
- `/cig-status` - Show all tasks
- `/cig-status 1` - Show task 1 and all subtasks
- `/cig-status 1.1` - Show task 1.1 and all its subtasks

**Steps**:

### 1. Resolve Task Path (if provided)
- If task-path provided: Use `context-manager hierarchy <task-path>` to verify task exists
- If no path: Show all tasks starting from implementation-guide/ root

### 2. Calculate Progress with workflow-manager status
- **With task argument**: Calls `workflow-manager status [task-path]` (auto-enables --workflow)
  - Shows tree view + workflow file breakdown for the task
- **Without task argument**: Calls `workflow-manager status` (auto-enables --sort=modified --limit=5)
  - Shows 5 most recent tasks, sorted by modification time
- **Override defaults**: Use explicit flags (--workflow, --no-workflow, --limit=N) to customize
- Returns: Task tree with progress percentages and status indicators
- Progress calculated using status markers from workflow files
- Formula: `MAX(IF(MAX(all) >= 25%) THEN 25% ELSE 0%, MIN(all status))`

### 3. Display Visual Tree
Format output from workflow-manager status with visual indicators:
- ✓ : Finished (100% progress)
- ⚙️ : In Progress (1-99% progress)
- ○ : Not Started (0% progress)

Example tree:
```
Task Progress:

✓ 1 (feature): user-authentication - 100%
  ⚙️ 1.1 (chore): database-schema - 50%
    ✓ 1.1.1 (feature): user-model - 100%
    ○ 1.1.2 (feature): auth-tokens - 0%
  ○ 1.2 (feature): password-reset - 0%
○ 2 (bugfix): login-validation - 0%
```

### 4. Provide Context
For tasks in progress, optionally show:
- Current workflow step (based on file status markers)
- Next recommended action based on workflow progression
- Blockers if mentioned in status sections

### 5. Summary Statistics (optional)
If showing all tasks, provide summary:
- Total tasks by type (feature/bugfix/hotfix/chore)
- Overall completion percentage
- Tasks by status (Finished, In Progress, Not Started)

**Success**: Clear hierarchical visibility into project progress with accurate progress calculations
