---
name: cwf-config
description: Configure CWF system paths and settings
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash
---

## Scope & Boundaries

**This step**: Configure CWF system settings (init, list, or reset).
**Not this step**: Initialising CIG (use `/cwf-init`), creating tasks, or running workflows.

## Context

**Task arguments**: {arguments}

**Before anything else — anchor the shell to the repo root** so the relative `.cwf/...` commands below resolve from any working directory (run this Bash block first):

```bash
# Anchor to the MAIN repo root so relative .cwf/ paths resolve from any cwd
# (worktree-safe via --git-common-dir; tolerant when not yet in a git repo).
gcd=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
if [ -n "$gcd" ]; then r=$(cd "$(dirname "$gcd")" && pwd); [ "$PWD" = "$r" ] || cd "$r"; fi
```

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

**Mandatory context** (run before proceeding):
- Run `ls -la ~/.cwf/ .cwf/ 2>/dev/null || echo "No configs found"` using the Bash tool to check existing config directories.
- Run `cat .cwf/autoload.yaml 2>/dev/null || echo "No autoload config found"` using the Bash tool to load current autoload configuration.

## Workflow

**Parse arguments**: `[init|list|reset]`
- init: Initialise global CIG configuration at `~/.cwf/`
- list: Show current configuration locations and content
- reset: Reset configurations to defaults

**Built-in Paths** (hardcoded for broken config recovery):
- User config: `~/.cwf/autoload.yaml`
- Project config: `<git-root>/.cwf/autoload.yaml`

### Steps for 'init'
1. Create `~/.cwf/` with subdirectories (utils, templates)
2. Generate `~/.cwf/autoload.yaml` with utils and template mappings
3. Create global utility templates and template directories

### Steps for 'list'
1. Show configuration hierarchy (global -> project -> effective merged result)
2. Display autoload mappings and template locations

### Steps for 'reset'
1. Backup existing configs (.backup suffix), regenerate defaults
2. Confirm reset completed and show new configuration

**Configuration Priority**: Project `.cwf/autoload.yaml` > Global `~/.cwf/autoload.yaml` > Built-in defaults

**Error Handling**: If config directory creation fails, check permissions and disk space. If user intent unclear, show current config status and ask for clarification.

## Success Criteria
- [ ] Git root confirmed and configs loaded
- [ ] Requested operation (init/list/reset) completed
- [ ] Configuration state displayed to user
