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
- Run `ls -la implementation-guide/ 2>/dev/null || echo "No implementation-guide found"` using the Bash tool to check if CWF is already initialised.

## Workflow

### 1. Create Directory Structure
- `implementation-guide/` at git root

### 2. Generate Project Configuration
- Create `implementation-guide/cwf-project.json` from template
- Use project name from git remote or directory name
- Set default task management (github) and branch conventions

### 3. Create Navigation
- Generate `implementation-guide/README.md` with navigation index
- Include command reference and project overview

### 4. Update CLAUDE.md
- Check for existing preamble (idempotency):
  `grep -q "CWF.*is installed" CLAUDE.md 2>/dev/null`
- **If preamble already present**: Skip — do not re-add
- **If absent**: Prepend the following block to CLAUDE.md (create file if it doesn't exist), preserving all existing content after it:
  ```markdown
  > **CWF (Coding with Files) is installed in this project.**
  > - Invoke CWF workflow steps using the `Skill` tool (e.g. `Skill("cwf-task-plan")`). Do not manually read or follow SKILL.md instructions directly.
  > - All workflow steps are mandatory. If a step is genuinely inapplicable, mark it `Skipped` via the workflow process — do not silently omit it.

  ```
- Add CWF system integration hints, section extraction commands, and standard section names reference

### 5. Configure .gitignore
- Ensure `.gitignore` exists at git root
- Add `.cwf/task-stack` entry if not present (user-specific workspace state)
- Use idempotent check: `grep -q '^\\.cwf/task-stack$' .gitignore || echo '.cwf/task-stack' >> .gitignore`

### 6. Register Skill Permissions
- List available CWF skills: `ls .claude/skills/cwf-*/`
- Show the user the list of `Skill(cwf-<name>)` entries that will be added to `.claude/settings.json`
- **Ask user to confirm** before writing any file
- Read existing `.claude/settings.json` if present; use `{"permissions":{"allow":[]}}` if absent
- Add each missing `Skill(cwf-<name>)` entry to `permissions.allow` — skip any already present
- Write back valid JSON to `.claude/settings.json`
- **Note**: This is the project-level `.claude/settings.json` (at git root), not the global `~/.claude/settings.json` used for PERL5OPT in step 7

### 7. Configure Claude Code Settings (user action required)
- First, check if PERL5OPT is already configured:
  `grep -q 'PERL5OPT' ~/.claude/settings.json 2>/dev/null`
- **If already configured**: Inform user "PERL5OPT is already configured — no action needed" and skip to next step
- **If not configured**: Inform user to add PERL5OPT to `~/.claude/settings.json`:
  ```json
  {
    "env": {
      "PERL5OPT": "-CDSL"
    }
  }
  ```
- This enables Unicode handling in Perl helper scripts
- Without this, scripts will issue warnings but continue to work

### 8. Commit Init Output
- Stage all files created or modified by init:
  ```bash
  git add implementation-guide/ .gitignore CLAUDE.md .claude/settings.json
  ```
- Create the init commit now:
  ```bash
  git commit -m "Initialise CWF project configuration"
  ```
- Follow the project's commit conventions (see `docs/conventions/commit-messages.md` if present)
- **Do not begin task work until this commit is made**

**Success**: Complete CWF system ready for `/cwf-new-task` usage

## Success Criteria
- [ ] Git root confirmed
- [ ] Directory structure created
- [ ] Project configuration generated
- [ ] Navigation index created
- [ ] .gitignore updated
- [ ] Skill permissions registered in `.claude/settings.json` (with user confirmation)
- [ ] PERL5OPT checked and user informed only if not already configured
- [ ] Init commit created (mandatory — do not begin task work without it)
