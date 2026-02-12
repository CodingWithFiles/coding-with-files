---
description: Configure CIG system paths and settings
argument-hint: [init|list|reset]
allowed-tools: Write, Read, LS, Bash(git:*), Bash(git rev-parse:*), Bash(.cig/scripts/command-helpers/cig-load-autoload-config), Bash(ls:*), Bash(echo:*)
---

## Context
- Git root: !`git rev-parse --show-toplevel`
- Existing configs: !`ls -la ~/.cig/ .cig/ 2>/dev/null || echo "No configs found"`
- Current autoload: !`.cig/scripts/command-helpers/cig-load-autoload-config`

## Your task
Configure CIG system: **{arguments}**

!{bash}
.cig/scripts/command-helpers/context-manager location

**Parse arguments**: `[init|list|reset]`
- init: Initialise global CIG configuration at `~/.cig/`
- list: Show current configuration locations and content
- reset: Reset configurations to defaults

**Built-in Paths** (hardcoded for broken config recovery):
- User config: `~/.cig/autoload.yaml`
- Project config: `<git-root>/.cig/autoload.yaml`

**Steps for 'init'**:
1. Create `~/.cig/` with subdirectories (utils, templates)
2. Generate `~/.cig/autoload.yaml` with utils and template mappings
3. Create global utility templates and template directories

**Steps for 'list'**:
1. Show configuration hierarchy (global → project → effective merged result)
2. Display autoload mappings and template locations

**Steps for 'reset'**:
1. Backup existing configs (.backup suffix), regenerate defaults
2. Confirm reset completed and show new configuration

**Configuration Priority**: Project `.cig/autoload.yaml` > Global `~/.cig/autoload.yaml` > Built-in defaults

**Error Handling**: If config directory creation fails, check permissions and disk space. If user intent unclear, show current config status and ask for clarification.