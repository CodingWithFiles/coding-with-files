#!/usr/bin/env bash
#
# hierarchy-resolver.sh - Resolve task paths to full directory paths
#
# Usage: hierarchy-resolver.sh <task-path> [--format=json]
#
# Examples:
#   hierarchy-resolver.sh 1
#   hierarchy-resolver.sh 1.1
#   hierarchy-resolver.sh 1/1.1/1.1.1
#   hierarchy-resolver.sh 3.2 --format=json
#
# Exit codes:
#   0 - Success
#   1 - Invalid path format
#   2 - Task not found
#   3 - Missing required argument

set -euo pipefail

# Parse arguments
if [[ $# -lt 1 ]]; then
    echo "Error: Missing required argument <task-path>" >&2
    echo "Usage: hierarchy-resolver.sh <task-path> [--format=json]" >&2
    exit 3
fi

TASK_PATH="$1"
FORMAT="markdown"

# Check for --format flag
if [[ $# -gt 1 && "$2" == "--format=json" ]]; then
    FORMAT="json"
fi

# Normalize task path: replace slashes with dots
NORMALIZED_PATH="${TASK_PATH//\//.}"

# Validate task path format (must be numbers and dots)
if ! [[ "$NORMALIZED_PATH" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo "Error: Invalid task path format: $TASK_PATH" >&2
    echo "Expected format: <num> or <num>.<num> or <num>/<num>/<num>" >&2
    exit 1
fi

# Build directory search pattern
# For "1.1.1", we need to find directories like "1-*-*/1.1-*-*/1.1.1-*-*/"
IFS='.' read -ra PATH_PARTS <<< "$NORMALIZED_PATH"
SEARCH_PATTERN="implementation-guide"

for i in "${!PATH_PARTS[@]}"; do
    # Build the hierarchical path component
    if [[ $i -eq 0 ]]; then
        COMPONENT="${PATH_PARTS[0]}-*-*"
    else
        # Build dot notation for subdirectories (1.1, 1.1.1, etc.)
        DOT_PATH=""
        for j in $(seq 0 $i); do
            if [[ $j -eq 0 ]]; then
                DOT_PATH="${PATH_PARTS[$j]}"
            else
                DOT_PATH="${DOT_PATH}.${PATH_PARTS[$j]}"
            fi
        done
        COMPONENT="${DOT_PATH}-*-*"
    fi
    SEARCH_PATTERN="${SEARCH_PATTERN}/${COMPONENT}"
done

# Find matching directory
MATCHES=($(find implementation-guide -maxdepth $((${#PATH_PARTS[@]} * 2)) -type d -path "${SEARCH_PATTERN}" 2>/dev/null | head -n 1))

if [[ ${#MATCHES[@]} -eq 0 ]]; then
    echo "Error: Task not found: $TASK_PATH" >&2
    exit 2
fi

FULL_PATH="${MATCHES[0]}"

# Extract metadata from directory name
DIR_NAME=$(basename "$FULL_PATH")

# Parse task number, type, and slug from directory name pattern: <num>-<type>-<slug>
if [[ "$DIR_NAME" =~ ^([0-9.]+)-([a-z]+)-(.+)$ ]]; then
    TASK_NUM="${BASH_REMATCH[1]}"
    TASK_TYPE="${BASH_REMATCH[2]}"
    TASK_SLUG="${BASH_REMATCH[3]}"
else
    echo "Error: Invalid directory name format: $DIR_NAME" >&2
    exit 1
fi

# Detect format (v1.0 or v2.0) by checking for lettered workflow files
if [[ -f "$FULL_PATH/a-plan.md" ]] || [[ -f "$FULL_PATH/d-implementation.md" ]]; then
    TEMPLATE_FORMAT="2.0"
else
    TEMPLATE_FORMAT="1.0"
fi

# Calculate depth (number of dots + 1)
DEPTH=$(($(echo "$TASK_NUM" | tr -cd '.' | wc -c) + 1))

# Calculate parent path
if [[ "$TASK_NUM" =~ ^(.+)\.[0-9]+$ ]]; then
    PARENT_PATH="${BASH_REMATCH[1]}"
else
    PARENT_PATH=""
fi

# Output result
if [[ "$FORMAT" == "json" ]]; then
    cat <<EOF
{
  "full_path": "$FULL_PATH",
  "format": "$TEMPLATE_FORMAT",
  "task_num": "$TASK_NUM",
  "task_type": "$TASK_TYPE",
  "task_slug": "$TASK_SLUG",
  "parent_path": "$PARENT_PATH",
  "depth": $DEPTH
}
EOF
else
    echo "Task: $TASK_NUM ($TASK_TYPE)"
    echo "Path: $FULL_PATH"
    echo "Format: v$TEMPLATE_FORMAT"
    if [[ -n "$PARENT_PATH" ]]; then
        echo "Parent: $PARENT_PATH"
    fi
fi

exit 0
