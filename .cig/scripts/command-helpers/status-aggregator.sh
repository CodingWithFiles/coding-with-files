#!/usr/bin/env bash
#
# status-aggregator.sh - Calculate task progress from status markers
#
# Usage: status-aggregator.sh [task-path] [--format=json]
#
# Examples:
#   status-aggregator.sh                    # All tasks
#   status-aggregator.sh 1                  # Task 1 and descendants
#   status-aggregator.sh 1.1 --format=json  # Task 1.1 in JSON format
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - Task not found

set -euo pipefail

# Status to percentage mapping
declare -A STATUS_MAP=(
    ["Backlog"]="0"
    ["backlog"]="0"
    ["To-Do"]="0"
    ["to-do"]="0"
    ["In Progress"]="25"
    ["in progress"]="25"
    ["Implemented"]="50"
    ["implemented"]="50"
    ["Testing"]="75"
    ["testing"]="75"
    ["Finished"]="100"
    ["finished"]="100"
)

# Parse arguments
TASK_PATH="${1:-}"
FORMAT="markdown"

if [[ $# -gt 1 && "$2" == "--format=json" ]]; then
    FORMAT="json"
elif [[ $# -eq 1 && "$1" == "--format=json" ]]; then
    FORMAT="json"
    TASK_PATH=""
fi

# Function to extract status from file
extract_status() {
    local file="$1"
    local status=""

    if [[ ! -f "$file" ]]; then
        echo "Unknown"
        return
    fi

    # Try pattern 1: ## Status: <status>
    status=$(grep -m 1 -i '^## Status:' "$file" 2>/dev/null | sed -E 's/^## Status: *//i' | tr -d '\r\n' || echo "")

    # Try pattern 2: **Status**: <status>
    if [[ -z "$status" ]]; then
        status=$(grep -m 1 -i '\*\*Status\*\*:' "$file" 2>/dev/null | sed -E 's/.*\*\*Status\*\*: *//i' | tr -d '\r\n' || echo "")
    fi

    # Default to Unknown if not found
    if [[ -z "$status" ]]; then
        echo "Unknown"
    else
        echo "$status"
    fi
}

# Function to calculate progress percentage
calculate_progress() {
    local dir="$1"
    local statuses=()
    local percentages=()

    # Find all workflow files in directory (both old and new format)
    local workflow_files=()
    for file in "$dir"/{plan,requirements,design,implementation,testing,rollout,maintenance}.md \
                "$dir"/{a-plan,b-requirements,c-design,d-implementation,e-testing,f-rollout,g-maintenance,h-retrospective}.md; do
        if [[ -f "$file" ]]; then
            workflow_files+=("$file")
        fi
    done

    # Extract statuses from all workflow files
    for file in "${workflow_files[@]}"; do
        local status=$(extract_status "$file")
        statuses+=("$status")

        # Convert status to percentage
        local pct="${STATUS_MAP[$status]:-0}"
        percentages+=("$pct")
    done

    # Calculate progress using formula: MAX(IF(MAX(all) >= 25%) THEN 25% ELSE 0%, MIN(all status))
    local max_pct=0
    local min_pct=100

    for pct in "${percentages[@]}"; do
        if [[ $pct -gt $max_pct ]]; then
            max_pct=$pct
        fi
        if [[ $pct -lt $min_pct ]]; then
            min_pct=$pct
        fi
    done

    # Apply formula
    local base_pct=0
    if [[ $max_pct -ge 25 ]]; then
        base_pct=25
    fi

    local progress=$base_pct
    if [[ $min_pct -gt $progress ]]; then
        progress=$min_pct
    fi

    echo "$progress"
}

# Function to build task tree
build_tree() {
    local base_path="${1:-implementation-guide}"
    local indent="${2:-}"
    local task_num="${3:-}"

    # Find all task directories
    local pattern="$base_path"
    if [[ -n "$task_num" ]]; then
        pattern="$base_path/${task_num}-*-*"
    else
        pattern="$base_path/[0-9]*-*-*"
    fi

    for dir in $pattern; do
        if [[ ! -d "$dir" ]]; then
            continue
        fi

        # Extract task info from directory name
        local dir_name=$(basename "$dir")
        if [[ "$dir_name" =~ ^([0-9.]+)-([a-z]+)-(.+)$ ]]; then
            local num="${BASH_REMATCH[1]}"
            local type="${BASH_REMATCH[2]}"
            local slug="${BASH_REMATCH[3]}"

            # Calculate progress
            local progress=$(calculate_progress "$dir")

            # Determine status indicator
            local indicator="○"  # Not started
            if [[ $progress -ge 100 ]]; then
                indicator="✓"  # Finished
            elif [[ $progress -gt 0 ]]; then
                indicator="⚙️"  # In progress
            fi

            # Output tree line
            if [[ "$FORMAT" == "json" ]]; then
                # JSON format handled separately
                :
            else
                echo "${indent}${indicator} ${num} (${type}): ${slug} - ${progress}%"
            fi

            # Recursively process subtasks
            build_tree "$dir" "${indent}  " "$num"
        fi
    done
}

# Main execution
if [[ "$FORMAT" == "json" ]]; then
    # JSON output (simplified for now, can be enhanced)
    echo '{"tasks": ['

    first=true
    if [[ -n "$TASK_PATH" ]]; then
        # Find specific task
        task_dir=$(find implementation-guide -maxdepth 10 -type d -name "${TASK_PATH}-*-*" | head -n 1)
        if [[ -n "$task_dir" ]]; then
            progress=$(calculate_progress "$task_dir")
            dir_name=$(basename "$task_dir")
            echo "  {\"task\": \"$dir_name\", \"progress\": $progress}"
        fi
    else
        # All tasks
        for dir in implementation-guide/[0-9]*-*-*; do
            if [[ -d "$dir" ]]; then
                if [[ "$first" == false ]]; then
                    echo ","
                fi
                first=false

                progress=$(calculate_progress "$dir")
                dir_name=$(basename "$dir")
                echo -n "  {\"task\": \"$dir_name\", \"progress\": $progress}"
            fi
        done
        echo ""
    fi

    echo ']}'
else
    # Markdown output
    echo "Task Progress:"
    echo ""
    build_tree "implementation-guide" "" "$TASK_PATH"
fi

exit 0
