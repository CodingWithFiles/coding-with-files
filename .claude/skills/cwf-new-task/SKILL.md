---
name: cwf-new-task
description: Create categorised implementation guide (v2.0 - hierarchical)
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash
---

## Scope & Boundaries

**This step**: Create a new task directory with template files and git branch.
**Not this step**: Planning, design, or implementation — those are separate workflow phases.

## Context

**Task arguments**: {arguments}

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Parse arguments**: `<num> <type> "description"`
- num: Task number in decimal notation (1, 1.1, 1.1.1, etc.)
- type: feature|bugfix|hotfix|chore|discovery
- description: Brief task description (will be slugified)

**Examples**:
- `/cwf-new-task 1 feature "Add user authentication"`
- `/cwf-new-task 1.1 chore "Setup database schema"`

### 1. Validate Arguments
- Verify `num` is valid decimal notation (numbers and dots only)
- Verify `type` is in supported-task-types from `cwf-project.json`
- Verify `description` is provided

### 2. Generate Slug and Directory Path
- Slug: lowercase, spaces to hyphens, remove special chars, truncate 50 chars
- Top-level: `implementation-guide/<num>-<type>-<slug>/`
- Subtask: nested inside parent directory (e.g. task 48.1 → `implementation-guide/48-feature-parent/48.1-bugfix-slug/`)

### 3. Copy Template Files
```bash
.cwf/scripts/command-helpers/task-workflow create \
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
- Next action: `/cwf-task-plan <num>`

## Success Criteria
- [ ] Arguments parsed and validated
- [ ] Task directory created with template files
- [ ] Git branch created and checked out
- [ ] Next steps suggested
