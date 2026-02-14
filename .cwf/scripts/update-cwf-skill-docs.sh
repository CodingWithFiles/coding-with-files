#!/bin/bash
# Script to update CWF command documentation to use new trampoline names
# Part of Task 40: Complete helper script migration to trampoline architecture
#
# This updates documentation/prose references from old script names to new trampoline calls
# Note: Actual executable calls were already updated in commit f91f1f3

set -e

cd "$(git rev-parse --show-toplevel)"

echo "Updating CWF command documentation to use trampoline names..."

# Update workflow-control references
sed -i 's/Call `workflow-control/Call `workflow-manager control/g' .claude/commands/cwf-*.md

# Update hierarchy-resolver references
sed -i 's/resolve using hierarchy-resolver/resolve using context-manager hierarchy/g' .claude/commands/cwf-*.md
sed -i 's/Use hierarchy-resolver/Use context-manager hierarchy/g' .claude/commands/cwf-*.md

# Update status-aggregator references
sed -i 's/### 2\. Calculate Progress with status-aggregator/### 2. Calculate Progress with workflow-manager status/g' .claude/commands/cwf-*.md
sed -i 's/Calls `status-aggregator/Calls `workflow-manager status/g' .claude/commands/cwf-*.md
sed -i 's/Format output from status-aggregator/Format output from workflow-manager status/g' .claude/commands/cwf-*.md

echo "Documentation updates complete!"
echo ""
echo "Summary of changes:"
echo "  - workflow-control → workflow-manager control"
echo "  - hierarchy-resolver → context-manager hierarchy"
echo "  - status-aggregator → workflow-manager status"
