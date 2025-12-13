---
description: Create sub-implementation task within existing task (v2.0)
argument-hint: <parent-path> <num> <type> "description"
allowed-tools: Write, Read, Bash(ln:*), Bash(cp:*), Bash(.cig/scripts/command-helpers/hierarchy-resolver.sh), Bash(.cig/scripts/command-helpers/context-inheritance.pl), Bash(.cig/scripts/command-helpers/cig-load-project-config), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

- Parent resolution: !`.cig/scripts/command-helpers/hierarchy-resolver.sh ${ARGUMENTS%% *} 2>/dev/null || echo "Parent task required"`
- Parent context: !`.cig/scripts/command-helpers/context-inheritance.pl ${ARGUMENTS%% *} 2>/dev/null || echo "Unable to load parent context"`
- Project config: !`.cig/scripts/command-helpers/cig-load-project-config`

## Your task
Create subtask within parent: **$ARGUMENTS**

**Parse arguments**: `<parent-path> <num> <type> "description"`
- parent-path: Parent task number (e.g., "1", "1.1", "1.1.1")
- num: Subtask number component (e.g., for parent "1", use "1.1"; for parent "1.1", use "1.1.1")
- type: feature|bugfix|hotfix|chore
- description: Brief subtask description (will be slugified)

**Examples**:
- `/cig-subtask 1 1.1 chore "Setup database schema"`
- `/cig-subtask 1.1 1.1.1 feature "User model"`
- `/cig-subtask 1.1.1 1.1.1.1 bugfix "Fix validation"`

**Steps**:

### 1. Resolve Parent Directory
- Use `hierarchy-resolver.sh <parent-path>` to find parent directory
- Verify parent task exists
- Extract parent task metadata (num, type, slug)

### 2. Load Parent Context via context-inheritance.pl
**Important**: Use context-inheritance.pl, not manual file reading
- Call `context-inheritance.pl <parent-path>` to get structural map
- Review structural map to understand parent goals, requirements, and design
- Decide which specific parent sections to read in detail using Read tool
- This provides token-efficient context loading (~50-100 tokens vs 500-1000)

### 3. Validate Subtask Number
- Verify `num` follows hierarchical pattern from parent
- Parent "1" → Next subtask should be "1.1", "1.2", etc.
- Parent "1.1" → Next subtask should be "1.1.1", "1.1.2", etc.
- Check that subtask number doesn't already exist

### 4. Generate Slug and Directory
- Apply slug generation algorithm (same as /cig-new-task):
  - Convert description to lowercase
  - Replace spaces with hyphens
  - Remove special characters
  - Truncate to 50 characters
- Create directory: `<parent-dir>/<num>-<type>-<slug>/`

### 5. Copy Template Files via Symlinks
- Same process as `/cig-new-task`
- List symlinks in `.cig/templates/<type>/`
- Copy files based on task type subset
- See `/cig-new-task` documentation for full process

### 6. Populate Task Reference with Parent Link
- Replace template placeholders (same as /cig-new-task)
- **Important**: Set `{{parentTask}}` to parent task number
- This creates explicit parent-child relationship

### 7. Provide Next Steps
Inform user:
- Subtask directory created: `<full-path>`
- Parent task: `<parent-num>` (`<parent-type>`: `<parent-slug>`)
- Parent context loaded via structural map
- Next action: `/cig-plan <num>` to begin planning phase
- Note: Progressive disclosure pattern applied - parent context available but not forced

**Progressive Disclosure**: Commands reference `/cig-new-task` documentation rather than duplicating instructions

**Success**: Ready-to-use subtask with hierarchical integration and token-efficient parent context loading
