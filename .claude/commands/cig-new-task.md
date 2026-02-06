---
description: Create categorised implementation guide (v2.0 - hierarchical)
argument-hint: <num> <type> "description"
allowed-tools: Write, Read, Bash(ln:*), Bash(cp:*), Bash(git:*), Bash(.cig/scripts/command-helpers/hierarchy-resolver:*), Bash(.cig/scripts/command-helpers/template-copier:*), Bash(.cig/scripts/command-helpers/cig-load-project-config), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
- Project config: !`.cig/scripts/command-helpers/cig-load-project-config`

## Your task
Create new hierarchical implementation guide for: **$ARGUMENTS**

**Implementation**: First ensure we're in git repository root:

!{bash}
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository. CIG commands must be run from within a git repository."
    exit 1
fi

cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"

**Helper scripts location**: `.cig/scripts/command-helpers/`

⚠️  **BREAKING CHANGE from v1.0**: New signature `<num> <type> "description"`

**Parse arguments**: `<num> <type> "description"`
- num: Task number in decimal notation (1, 1.1, 1.1.1, etc.)
- type: feature|bugfix|hotfix|chore|discovery
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
  - Use hierarchy-resolver to find parent if it exists

### 4. Create Directory
- Create directory: `<num>-<type>-<slug>/`
- Verify directory doesn't already exist

### 5. Copy and Populate Template Files
**Key change**: Use template-copier helper script

Call template-copier to copy templates and substitute variables:

```bash
.cig/scripts/command-helpers/template-copier \
  --task-type="$TYPE" \
  --destination="$TASK_DIR" \
  --task-num="$NUM" \
  --description="$DESCRIPTION"

# Check exit code
if [ $? -ne 0 ]; then
    echo "Error: Template copying failed"
    exit 1
fi
```

This automatically:
- Discovers templates via symlinks in `.cig/templates/<type>/`
- Copies correct template subset per task type:
  - **feature**: 8 files (a-h)
  - **bugfix**: 5 files (a, c, d, e, h)
  - **hotfix**: 5 files (a, d, e, f, h)
  - **chore**: 4 files (a, d, e, h)
  - **discovery**: 6 files (a, b, c, d, e, h)
- Substitutes template variables:
  - `{{description}}` → task description
  - `{{taskId}}` → "internal-{num}"
  - `{{taskUrl}}` → "N/A (internal task)"
  - `{{parentTask}}` → parent task number or "N/A"
  - `{{branchName}}` → from `branch-naming-convention` pattern
- Sets file permissions to 0600

### 6. Suggest Git Branch
Generate branch name using `branch-naming-convention` from config:
- Default pattern: `<type>/<num>-<slug>`
- Example: `feature/1-add-user-authentication`

Suggest: `git checkout -b <branch-name>`

### 7. Provide Next Steps
Inform user:
- Directory created: `<full-path>`
- Files created: List of workflow files (a-plan.md, b-requirements.md, etc.)
- Next action: `/cig-task-plan <num>` to begin planning phase
- Git branch: Suggested checkout command

**Success**: Ready-to-use v2.0 implementation guide with hierarchical support and symlink-based templates
