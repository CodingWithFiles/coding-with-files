---
name: cwf-subtask
description: Create sub-implementation task within existing task (v2.0)
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash
---

## Scope & Boundaries

**This step**: Create a subtask within an existing parent task.
**Not this step**: Planning, design, or implementation of the subtask.

## Context

**Task arguments**: {arguments}

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

**Mandatory context** (run these before proceeding):
- Run `.cwf/scripts/command-helpers/context-manager hierarchy <parent-path>` using the Bash tool to resolve parent task directory and verify it exists.
- Run `.cwf/scripts/command-helpers/context-manager inheritance <parent-path>` using the Bash tool to load parent context (structural map for scope constraints).

## Workflow

**Parse arguments**: `<parent-path> <num> <type> "description"`
- parent-path: Parent task number (e.g., "1", "1.1")
- num: Subtask number (e.g., "1.1", "1.1.1")
- type: feature|bugfix|hotfix|chore
- description: Brief subtask description

### 1. Resolve Parent Directory
- Use `context-manager hierarchy <parent-path>` output to find parent
- Verify parent exists, extract metadata

### 2. Load Parent Context
- Use `context-manager inheritance <parent-path>` output for structural map
- Review parent goals, requirements, design to inform subtask

### 3. Validate and Create Subtask
- Verify `num` follows hierarchical pattern from parent
- Check subtask doesn't already exist
- Generate slug (same algorithm as `/cwf-new-task`)
- Copy templates via `task-workflow create` (same as `/cwf-new-task` Step 3)
- Set `{{parentTask}}` to parent task number

### 4. Provide Next Steps
- Subtask directory, parent link, structural map shown
- Next action: `/cwf-task-plan <num>`

## Success Criteria
- [ ] Parent task resolved and context loaded
- [ ] Arguments parsed and validated
- [ ] Subtask directory created with template files
- [ ] Next steps suggested
