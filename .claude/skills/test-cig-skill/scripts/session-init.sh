#!/usr/bin/env bash
# SessionStart hook test
# Logs session initialization to hook-observations.md

echo "[Hook Test] SessionStart executed at $(date)"
echo "CLAUDE_PLUGIN_ROOT: ${CLAUDE_PLUGIN_ROOT}"

# Create references directory if it doesn't exist
mkdir -p "${CLAUDE_PLUGIN_ROOT}/references"

# Log session start
echo "## Session Start: $(date)" >> "${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md"
echo "" >> "${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md"
