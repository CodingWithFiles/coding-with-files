#!/usr/bin/env bash
# PreToolUse hook test
# Logs tool execution before it happens

echo "[Hook Test] PreToolUse triggered"
echo "Tool: $1, Args: $2"

# Log to observations file
echo "- PreToolUse: Tool=$1 at $(date)" >> "${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md"
