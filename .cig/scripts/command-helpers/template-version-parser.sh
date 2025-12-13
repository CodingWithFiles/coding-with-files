#!/usr/bin/env bash
#
# template-version-parser.sh - Parse Template Version field from workflow files
#
# Usage: template-version-parser.sh <workflow-file-path> [--format=json]
#
# Examples:
#   template-version-parser.sh implementation-guide/1-feature-auth/a-plan.md
#   template-version-parser.sh implementation-guide/1-feature-auth/d-implementation.md --format=json
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - File not found

set -euo pipefail

# Parse arguments
if [[ $# -lt 1 ]]; then
    echo "Error: Missing required argument <workflow-file-path>" >&2
    echo "Usage: template-version-parser.sh <workflow-file-path> [--format=json]" >&2
    exit 1
fi

WORKFLOW_FILE="$1"
FORMAT="markdown"

# Check for --format flag
if [[ $# -gt 1 && "$2" == "--format=json" ]]; then
    FORMAT="json"
fi

# Verify file exists
if [[ ! -f "$WORKFLOW_FILE" ]]; then
    echo "Error: File not found: $WORKFLOW_FILE" >&2
    exit 2
fi

# Parse Template Version using the standardized pattern
VERSION=$(grep -m 1 '^\- \*\*Template Version\*\*:' "$WORKFLOW_FILE" 2>/dev/null | sed -E 's/^.*: *([0-9.]+).*/\1/' || echo "")

# Default to "1.0" if field is missing (backward compatibility)
if [[ -z "$VERSION" ]] || [[ "$VERSION" == "- **Template Version**:" ]]; then
    VERSION="1.0"
fi

# Output result
if [[ "$FORMAT" == "json" ]]; then
    cat <<EOF
{
  "file": "$WORKFLOW_FILE",
  "template_version": "$VERSION",
  "is_legacy": $([ "$VERSION" == "1.0" ] && echo "true" || echo "false")
}
EOF
else
    echo "$VERSION"
fi

exit 0
