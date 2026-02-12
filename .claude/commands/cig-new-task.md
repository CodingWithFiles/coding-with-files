---
description: Create categorised implementation guide (v2.0 - hierarchical)
argument-hint: {num} {type} "description"
allowed-tools: Write, Read, Bash(git rev-parse:*), Bash(git checkout:*), Bash(.cig/scripts/command-helpers/*:*)
---

## Context
- Project config: !`.cig/scripts/command-helpers/cig-load-project-config`

## Your task
Create new hierarchical implementation guide for: **{arguments}**

!{bash}
.cig/scripts/command-helpers/context-manager location

**Parse arguments**: `<num> <type> "description"`
- num: Task number in decimal notation (1, 1.1, 1.1.1, etc.)
- type: feature|bugfix|hotfix|chore|discovery
- description: Brief task description (will be slugified)

**Examples**:
- `/cig-new-task 1 feature "Add user authentication"`
- `/cig-new-task 1.1 chore "Setup database schema"`

**Steps**:

### 1. Validate Arguments
- Verify `num` is valid decimal notation (numbers and dots only)
- Verify `type` is in supported-task-types from `cig-project.json`
- Verify `description` is provided

### 2. Generate Slug and Directory Path
- Slug: lowercase, spaces→hyphens, remove special chars, truncate 50 chars
- Top-level: `implementation-guide/<num>-<type>-<slug>/`
- Subtask: Use `context-manager hierarchy` to find parent, create subdirectory

### 3. Copy Template Files
```bash
.cig/scripts/command-helpers/task-workflow create \
  --task-type="{type}" --destination="{task-dir}" \
  --task-num="{num}" --description="{description}"
```
Creates directory automatically, copies templates, substitutes variables, sets permissions.

### 4. Create Git Branch
```bash
git checkout -b "<type>/<num>-<slug>"
```

### 5. Provide Next Steps
- Directory created, files listed, branch checked out
- Next action: `/cig-task-plan <num>`
