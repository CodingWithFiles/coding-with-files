---
description: Create sub-implementation task within existing task (v2.0)
argument-hint: {parent-path} {num} {type} "description"
allowed-tools: Write, Read, Bash(git rev-parse:*), Bash(.cig/scripts/command-helpers/*:*)
---

## Context

- Parent resolution: !`.cig/scripts/command-helpers/context-manager hierarchy ${ARGUMENTS%% *} 2>/dev/null || echo "Parent task required"`
- Parent context: !`.cig/scripts/command-helpers/context-manager inheritance ${ARGUMENTS%% *} 2>/dev/null || echo "Unable to load parent context"`
- Project config: !`.cig/scripts/command-helpers/cig-load-project-config`

## Your task
Create subtask within parent: **{arguments}**

!{bash}
.cig/scripts/command-helpers/context-manager location

**Parse arguments**: `<parent-path> <num> <type> "description"`
- parent-path: Parent task number (e.g., "1", "1.1")
- num: Subtask number (e.g., "1.1", "1.1.1")
- type: feature|bugfix|hotfix|chore
- description: Brief subtask description

**Steps**:

### 1. Resolve Parent Directory
- Use `context-manager hierarchy <parent-path>` to find parent
- Verify parent exists, extract metadata

### 2. Load Parent Context
- Use `context-manager inheritance <parent-path>` for structural map
- Review parent goals, requirements, design to inform subtask

### 3. Validate and Create Subtask
- Verify `num` follows hierarchical pattern from parent
- Check subtask doesn't already exist
- Generate slug (same algorithm as `/cig-new-task`)
- Copy templates via `task-workflow create` (same as `/cig-new-task` Step 3)
- Set `{{parentTask}}` to parent task number

### 4. Provide Next Steps
- Subtask directory, parent link, structural map shown
- Next action: `/cig-task-plan <num>`
