---
description: Configure CIG system paths and settings
argument-hint: [init|list|reset]
allowed-tools: Write, Read, LS, Bash(git:*), Bash(.cig/scripts/command-helpers/cig-load-autoload-config), Bash(ls:*), Bash(echo:*)
---

## Context
- Git root: !`git rev-parse --show-toplevel`
- Existing configs: !`ls -la ~/.cig/ .cig/ 2>/dev/null || echo "No configs found"`
- Current autoload: !`.cig/scripts/command-helpers/cig-load-autoload-config`

## Your task
Configure CIG system: **$ARGUMENTS**

**Helper scripts location**: `.cig/scripts/command-helpers/`

**Parse arguments**: `[init|list|reset]`
- init: Initialise global CIG configuration at `~/.cig/`
- list: Show current configuration locations and content
- reset: Reset configurations to defaults

**Built-in Paths** (hardcoded for broken config recovery):
- User config: `~/.cig/autoload.yaml`
- Project config: `<git-root>/.cig/autoload.yaml`

**Steps for 'init'**:
1. **Create global directory**: `~/.cig/` with subdirectories
2. **Generate global autoload.yaml**:
   ```yaml
   # Global CIG Configuration
   utils:
     config-loader: utils/config-loader.md
     template-engine: utils/template-engine.md
     hierarchy-manager: utils/hierarchy-manager.md
     task-validator: utils/task-validator.md
   
   templates:
     feature: templates/feature/
     bugfix: templates/bugfix/
     hotfix: templates/hotfix/
     chore: templates/chore/
   ```
3. **Create global utility templates** (simplified versions of project utilities)
4. **Create global template directories** with basic templates

**Steps for 'list'**:
1. **Show configuration hierarchy**:
   - Global config location and status
   - Project config location and status  
   - Effective configuration (merged result)
2. **Display autoload mappings** currently in use
3. **Show template locations** and availability

**Steps for 'reset'**:
1. **Backup existing configs** (rename with .backup suffix)
2. **Regenerate default configurations**
3. **Restore directory structure** to defaults
4. **Confirm reset completed** and show new configuration

**Configuration Priority**:
1. Project `.cig/autoload.yaml` (highest priority)
2. Global `~/.cig/autoload.yaml` (fallback)
3. Built-in defaults (emergency fallback)

**Error Handling**:
- **Error**: Cannot create global configuration directory
- **Cause**: Permission issues or disk space problems
- **Solution**: Check file permissions and available disk space
- **Example**: `mkdir -p ~/.cig/utils ~/.cig/templates/{feature,bugfix,hotfix,chore}`
- **Uncertainty**: If user's intent unclear, show current config status and ask for clarification

**Success**: CIG system configured and ready for use across all projects