---
description: Initialise CIG system with project configuration
allowed-tools: Write, Read, LS, Bash(git:*), Bash(git rev-parse:*), Bash(pwd:*), Bash(ls:*), Bash(echo:*)
---

## Context
- Current directory: !`pwd`
- Git root: !`git rev-parse --show-toplevel`
- Existing structure: !`ls -la implementation-guide/ 2>/dev/null || echo "No implementation-guide found"`

## Your task
Initialise CIG system for this project by:

**Implementation**: First ensure we're in git repository root:

!{bash}
.cig/scripts/command-helpers/context-manager location

1. **Create directory structure**: 
   - `implementation-guide/` at git root
   - Category subdirectories: `feature/`, `bugfix/`, `hotfix/`, `chore/`

2. **Generate project configuration**:
   - Create `implementation-guide/cig-project.json` from template
   - Use project name from git remote or directory name
   - Set default task management (github) and branch conventions

3. **Create navigation**:
   - Generate `implementation-guide/README.md` with navigation index
   - Include command reference and project overview

4. **Update CLAUDE.md**:
   - Add CIG system integration hints
   - Include section extraction commands
   - Add standard section names reference

5. **Configure .gitignore**:
   - Ensure `.gitignore` exists at git root
   - Add `.cig/task-stack` entry if not present (user-specific workspace state)
   - Use idempotent check: `grep -q '^\\.cig/task-stack$' .gitignore || echo '.cig/task-stack' >> .gitignore`

6. **Configure Claude Code settings** (user action required):
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

**Success**: Complete CIG system ready for `/cig-new-task` usage