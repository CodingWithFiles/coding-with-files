---
name: cwf-init
description: Initialise CWF system with project configuration
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash
---

## Scope & Boundaries

**This step**: Initialise the CWF system for a project — create directories, configuration, and documentation.
**Not this step**: Creating tasks (use `/cwf-new-task`), configuring settings (use `/cwf-config`).

## Context

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

**Mandatory context** (run before proceeding):
- Run `ls -la implementation-guide/ 2>/dev/null || echo "No implementation-guide found"` using the Bash tool to check if CIG is already initialised.

## Workflow

### 1. Create Directory Structure
- `implementation-guide/` at git root
- Category subdirectories: `feature/`, `bugfix/`, `hotfix/`, `chore/`

### 2. Generate Project Configuration
- Create `implementation-guide/cwf-project.json` from template
- Use project name from git remote or directory name
- Set default task management (github) and branch conventions

### 3. Create Navigation
- Generate `implementation-guide/README.md` with navigation index
- Include command reference and project overview

### 4. Update CLAUDE.md
- Add CWF system integration hints
- Include section extraction commands
- Add standard section names reference

### 5. Configure .gitignore
- Ensure `.gitignore` exists at git root
- Add `.cwf/task-stack` entry if not present (user-specific workspace state)
- Use idempotent check: `grep -q '^\\.cwf/task-stack$' .gitignore || echo '.cwf/task-stack' >> .gitignore`

### 6. Configure Claude Code Settings (user action required)
- Inform user to add PERL5OPT to `~/.claude/settings.json`:
  ```json
  {
    "env": {
      "PERL5OPT": "-CDSL"
    }
  }
  ```
- This enables Unicode handling in Perl helper scripts
- Without this, scripts will issue warnings but continue to work

**Success**: Complete CWF system ready for `/cwf-new-task` usage

## Success Criteria
- [ ] Git root confirmed
- [ ] Directory structure created
- [ ] Project configuration generated
- [ ] Navigation index created
- [ ] .gitignore updated
- [ ] User informed about PERL5OPT setting
