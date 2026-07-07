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

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

**Mandatory context** (run before proceeding):
- Run `ls -la ~/.cwf/ .cwf/ 2>/dev/null || echo "No configs found"` using the Bash tool to check existing config directories.
- Run `cat .cwf/autoload.yaml 2>/dev/null || echo "No autoload config found"` using the Bash tool to load current autoload configuration.

## Workflow

**Parse arguments**: `[init|list|reset|tool-check <on|off|seed>]`
- init: Initialise global CIG configuration at `~/.cwf/`
- list: Show current configuration locations and content
- reset: Reset configurations to defaults
- tool-check: Manage the Bash tool-check opt-in surface (see below)

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

### Steps for 'tool-check <on|off|seed>'

The Bash tool-check framework ships **inert** (no rules). This surface is the
single writer for enabling it. Dispatch the verb straight to the helper — it
performs the symlink-safe, atomic writes and echoes the resulting state:

```bash
.cwf/scripts/command-helpers/tool-check-seed <on|off|seed>
```

- `seed` — merge the regex-only starter rules into the **checked-in** layer
  (`{root}/.cwf/tool-check/bash/settings.json`) and clear a project-local off.
  The checked-in file is a normal tracked file; **committing it is the user's
  decision** — surface the helper's note, do not commit it automatically.
- `on` / `off` — flip the **project-local** kill-switch
  (`settings.local.json`, gitignored); an ephemeral, per-checkout toggle that
  never dirties tracked state.
- Any other verb: relay the helper's usage error; do not guess.

Relay the helper's stdout verbatim. To inspect the effective state afterwards,
run `.cwf/scripts/hooks/pretooluse-bash-tool-check --check` (human terminal
only — never pipe its output back into agent context). See
`.cwf/docs/tool-check-rules.md` for the layer/precedence model.

**Configuration Priority**: Project `.cwf/autoload.yaml` > Global `~/.cwf/autoload.yaml` > Built-in defaults

**Error Handling**: If config directory creation fails, check permissions and disk space. If user intent unclear, show current config status and ask for clarification.

## Success Criteria
- [ ] Git root confirmed and configs loaded
- [ ] Requested operation (init/list/reset/tool-check) completed
- [ ] Configuration state displayed to user
