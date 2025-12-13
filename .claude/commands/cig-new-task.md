---
description: Create categorised implementation guide (v2.0 - hierarchical)
argument-hint: <num> <type> "description"
allowed-tools: Write, Read, Bash(ln:*), Bash(cp:*), Bash(git:*), Bash(.cig/scripts/command-helpers/hierarchy-resolver.sh:*), Bash(.cig/scripts/command-helpers/cig-load-project-config), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
- Project config: !`.cig/scripts/command-helpers/cig-load-project-config`

## Your task
Create new hierarchical implementation guide for: **$ARGUMENTS**

⚠️  **BREAKING CHANGE from v1.0**: New signature `<num> <type> "description"`

**Parse arguments**: `<num> <type> "description"`
- num: Task number in decimal notation (1, 1.1, 1.1.1, etc.)
- type: feature|bugfix|hotfix|chore
- description: Brief task description (will be slugified)

**Examples**:
- `/cig-new-task 1 feature "Add user authentication"`
- `/cig-new-task 1.1 chore "Setup database schema"`
- `/cig-new-task 2.3.1 bugfix "Fix login validation"`

**Steps**:

### 1. Validate Arguments
- Verify `num` is valid decimal notation (numbers and dots only)
- Verify `type` is in supported-task-types from `cig-project.json`
- Verify `description` is provided

### 2. Generate Slug
Apply slug generation algorithm:
- Convert description to lowercase
- Replace spaces with hyphens
- Remove special characters (keep only alphanumeric and hyphens)
- Truncate to 50 characters maximum
- Example: "Add User Authentication" → "add-user-authentication"

### 3. Determine Directory Path
- If top-level (e.g., "1"): `implementation-guide/1-{type}-{slug}/`
- If subtask (e.g., "1.1"): Find parent directory, create subdirectory
  - Parent "1" → `implementation-guide/1-{parent-type}-{parent-slug}/1.1-{type}-{slug}/`
  - Use hierarchy-resolver.sh to find parent if it exists

### 4. Create Directory
- Create directory: `<num>-<type>-<slug>/`
- Verify directory doesn't already exist

### 5. Copy Template Files via Symlinks
**Key change**: Copy files based on symlinks in `.cig/templates/<type>/`
- List symlinks in `.cig/templates/<type>/` directory
- For each symlink (e.g., `a-plan.md.template`):
  - Read the target file from pool
  - Copy to task directory with .md extension (remove .template)
  - Example: `a-plan.md.template` → `a-plan.md`

This automatically ensures correct template subset per task type:
- **feature**: 8 files (a-h)
- **bugfix**: 5 files (a, c, d, e, h)
- **hotfix**: 5 files (a, d, e, f, h)
- **chore**: 4 files (a, d, e, h)

### 6. Populate Task Reference in All Files
For each created workflow file, replace template placeholders:
- `{{description}}` → task description
- `{{taskId}}` → from tracking integration or "internal-{num}"
- `{{taskUrl}}` → from tracking integration or "N/A (internal task)"
- `{{parentTask}}` → parent task number or "N/A"
- `{{branchName}}` → suggested branch name using `branch-naming-convention`

**Template Version**: All files should already have `- **Template Version**: 2.0` from pool templates

### 7. Suggest Git Branch
Generate branch name using `branch-naming-convention` from config:
- Default pattern: `<type>/<num>-<slug>`
- Example: `feature/1-add-user-authentication`

Suggest: `git checkout -b <branch-name>`

### 8. Provide Next Steps
Inform user:
- Directory created: `<full-path>`
- Files created: List of workflow files (a-plan.md, b-requirements.md, etc.)
- Next action: `/cig-plan <num>` to begin planning phase
- Git branch: Suggested checkout command

**Success**: Ready-to-use v2.0 implementation guide with hierarchical support and symlink-based templates
