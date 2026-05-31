#!/bin/bash
# Script to update CWF command documentation to use new trampoline names
# Part of Task 40: Complete helper script migration to trampoline architecture
#
# This updates documentation/prose references from old script names to new trampoline calls
# Note: Actual executable calls were already updated in commit f91f1f3

set -e

# Worktree-safe repo root (main tree, even inside a linked worktree) — Task 173.
# Do NOT `cd "$(git rev-parse --show-toplevel)"`: inside a linked worktree that
# anchors the shell to a disposable tree. Resolve the main tree and reference it
# explicitly instead of moving the shell's CWD.
_common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 1
repo_root=$(CDPATH= cd -- "$(dirname "$_common")" && pwd) || exit 1
[ -n "$repo_root" ] || { echo "not inside a git repository" >&2; exit 1; }

# Array preserves globbing while tolerating spaces in the resolved root.
cmd_docs=( "$repo_root"/.claude/commands/cwf-*.md )

echo "Updating CWF command documentation to use trampoline names..."

# Update workflow-control references
sed -i 's/Call `workflow-control/Call `workflow-manager control/g' "${cmd_docs[@]}"

# Update hierarchy-resolver references
sed -i 's/resolve using hierarchy-resolver/resolve using context-manager hierarchy/g' "${cmd_docs[@]}"
sed -i 's/Use hierarchy-resolver/Use context-manager hierarchy/g' "${cmd_docs[@]}"

# Update status-aggregator references
sed -i 's/### 2\. Calculate Progress with status-aggregator/### 2. Calculate Progress with workflow-manager status/g' "${cmd_docs[@]}"
sed -i 's/Calls `status-aggregator/Calls `workflow-manager status/g' "${cmd_docs[@]}"
sed -i 's/Format output from status-aggregator/Format output from workflow-manager status/g' "${cmd_docs[@]}"

echo "Documentation updates complete!"
echo ""
echo "Summary of changes:"
echo "  - workflow-control → workflow-manager control"
echo "  - hierarchy-resolver → context-manager hierarchy"
echo "  - status-aggregator → workflow-manager status"
