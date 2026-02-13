---
name: cig-config
description: Configure CIG system paths and settings
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash
---

## Scope & Boundaries

**This step**: Configure CIG system settings (init, list, or reset).
**Not this step**: Initialising CIG (use `/cig-init`), creating tasks, or running workflows.

## Context

**Task arguments**: {arguments}

**First**: Run `.cig/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

**Mandatory context** (run before proceeding):
- Run `ls -la ~/.cig/ .cig/ 2>/dev/null || echo "No configs found"` using the Bash tool to check existing config directories.
- Run `.cig/scripts/command-helpers/cig-load-autoload-config` using the Bash tool to load current autoload configuration.

## Workflow

**Parse arguments**: `[init|list|reset]`
- init: Initialise global CIG configuration at `~/.cig/`
- list: Show current configuration locations and content
- reset: Reset configurations to defaults

**Built-in Paths** (hardcoded for broken config recovery):
- User config: `~/.cig/autoload.yaml`
- Project config: `<git-root>/.cig/autoload.yaml`

### Steps for 'init'
1. Create `~/.cig/` with subdirectories (utils, templates)
2. Generate `~/.cig/autoload.yaml` with utils and template mappings
3. Create global utility templates and template directories

### Steps for 'list'
1. Show configuration hierarchy (global -> project -> effective merged result)
2. Display autoload mappings and template locations

### Steps for 'reset'
1. Backup existing configs (.backup suffix), regenerate defaults
2. Confirm reset completed and show new configuration

**Configuration Priority**: Project `.cig/autoload.yaml` > Global `~/.cig/autoload.yaml` > Built-in defaults

**Error Handling**: If config directory creation fails, check permissions and disk space. If user intent unclear, show current config status and ask for clarification.

## Success Criteria
- [ ] Git root confirmed and configs loaded
- [ ] Requested operation (init/list/reset) completed
- [ ] Configuration state displayed to user
