---
name: test-cig-skill
version: "0.1.0"
description: Test skill for validating CIG understanding of skills system
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash
hooks:
  SessionStart:
    - hooks:
        - type: command
          command: "echo '[test-cig-skill] SessionStart triggered' && ${CLAUDE_PLUGIN_ROOT}/scripts/session-init.sh"

  PreToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/pre-tool-check.sh"

  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/post-tool-notify.sh"

  Stop:
    - hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/stop-cleanup.sh"
---

# CIG Test Skill

This skill exists solely to test and validate CIG's understanding of the Claude Code skills system.

## Purpose

Test all 4 hook types (SessionStart, PreToolUse, PostToolUse, Stop) and document their execution behavior in `references/hook-observations.md`.

## Hook Testing

When invoked via `/test-cig-skill`:

1. **SessionStart** triggers immediately - creates references/ directory and logs session start
2. **PreToolUse** triggers before Write/Edit operations - logs tool name and timestamp
3. **PostToolUse** triggers after Write/Edit operations - logs completion timestamp
4. **Stop** triggers at session end - counts total hook executions

## Observations

All hook executions are logged to `${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md` for analysis.

## Usage

```bash
/test-cig-skill
```

Then perform Write or Edit operations to trigger PreToolUse/PostToolUse hooks.

Read `references/hook-observations.md` to see execution log.
