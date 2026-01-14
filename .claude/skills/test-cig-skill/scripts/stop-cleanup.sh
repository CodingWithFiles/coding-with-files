#!/usr/bin/env bash
# Stop hook test
# Logs session end and counts total hook executions

echo "[Hook Test] Stop hook triggered"

# Log session end
echo "" >> "${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md"
echo "## Session End: $(date)" >> "${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md"

# Count hook executions
HOOK_COUNT=$(grep -c "Hook Test" "${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md" || echo "0")
echo "Total hook executions: $HOOK_COUNT" >> "${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md"

echo "Hook observations logged to: ${CLAUDE_PLUGIN_ROOT}/references/hook-observations.md"
