#!/usr/bin/env bash
# PostToolUse hook test
# Logs tool completion after it executes

echo "[Hook Test] PostToolUse completed"

# Log to observations file
echo "- PostToolUse: Completed at $(date)" >> "${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md"
