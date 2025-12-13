#!/usr/bin/env bash
#
# format-detector.sh - Detect template version and compare against expected version
#
# Usage: format-detector.sh <task-directory> <workflow-file> [--format=json]
#
# Examples:
#   format-detector.sh implementation-guide/1-feature-auth a-plan.md
#   format-detector.sh implementation-guide/1-feature-auth d-implementation.md --format=json
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - File not found
#   3 - Version mismatch detected

set -euo pipefail

# Embedded versions
CIG_SOFTWARE_VERSION="2.0"
EXPECTED_TEMPLATE_VERSION="2.0"

# Parse arguments
if [[ $# -lt 2 ]]; then
    echo "Error: Missing required arguments" >&2
    echo "Usage: format-detector.sh <task-directory> <workflow-file> [--format=json]" >&2
    exit 1
fi

TASK_DIR="$1"
WORKFLOW_FILE="$2"
FORMAT="markdown"

# Check for --format flag
if [[ $# -gt 2 && "$3" == "--format=json" ]]; then
    FORMAT="json"
fi

# Build full file path
FULL_PATH="${TASK_DIR}/${WORKFLOW_FILE}"

# Verify file exists
if [[ ! -f "$FULL_PATH" ]]; then
    echo "Error: File not found: $FULL_PATH" >&2
    exit 2
fi

# Parse Template Version from workflow file
TEMPLATE_VERSION=$(grep -m 1 '^\- \*\*Template Version\*\*:' "$FULL_PATH" 2>/dev/null | sed -E 's/^.*: *([0-9.]+).*/\1/' || echo "1.0")

# Default to 1.0 if not found (backward compatibility)
if [[ -z "$TEMPLATE_VERSION" ]] || [[ "$TEMPLATE_VERSION" == "- **Template Version**:" ]]; then
    TEMPLATE_VERSION="1.0"
fi

# Check for required fields based on version
MISSING_FIELDS=()
VERSION_MISMATCH=false
DISCREPANCIES=()

# Check if template version matches CIG software version expectation
if [[ "$TEMPLATE_VERSION" != "$CIG_SOFTWARE_VERSION" ]]; then
    VERSION_MISMATCH=true
    DISCREPANCIES+=("Template version ($TEMPLATE_VERSION) does not match CIG software expectation ($CIG_SOFTWARE_VERSION)")
fi

# Check for required fields in v2.0 files
if [[ "$TEMPLATE_VERSION" == "2.0" ]]; then
    if ! grep -q '^\- \*\*Template Version\*\*:' "$FULL_PATH" 2>/dev/null; then
        MISSING_FIELDS+=("Template Version")
    fi
    if ! grep -q '^## Task Reference' "$FULL_PATH" 2>/dev/null; then
        MISSING_FIELDS+=("Task Reference section")
    fi
    if ! grep -q '^## Status' "$FULL_PATH" 2>/dev/null && ! grep -q '^\*\*Status\*\*:' "$FULL_PATH" 2>/dev/null; then
        MISSING_FIELDS+=("Status marker")
    fi
fi

# Determine exit code
EXIT_CODE=0
if [[ "$VERSION_MISMATCH" == true ]] || [[ ${#MISSING_FIELDS[@]} -gt 0 ]]; then
    EXIT_CODE=3
fi

# Output result
if [[ "$FORMAT" == "json" ]]; then
    # Build JSON for missing fields
    MISSING_JSON="[]"
    if [[ ${#MISSING_FIELDS[@]} -gt 0 ]]; then
        MISSING_JSON="["
        for i in "${!MISSING_FIELDS[@]}"; do
            MISSING_JSON+="\"${MISSING_FIELDS[$i]}\""
            if [[ $i -lt $((${#MISSING_FIELDS[@]} - 1)) ]]; then
                MISSING_JSON+=","
            fi
        done
        MISSING_JSON+="]"
    fi

    # Build JSON for discrepancies
    DISCREPANCIES_JSON="[]"
    if [[ ${#DISCREPANCIES[@]} -gt 0 ]]; then
        DISCREPANCIES_JSON="["
        for i in "${!DISCREPANCIES[@]}"; do
            DISCREPANCIES_JSON+="\"${DISCREPANCIES[$i]}\""
            if [[ $i -lt $((${#DISCREPANCIES[@]} - 1)) ]]; then
                DISCREPANCIES_JSON+=","
            fi
        done
        DISCREPANCIES_JSON+="]"
    fi

    cat <<EOF
{
  "file": "$FULL_PATH",
  "template_version": "$TEMPLATE_VERSION",
  "cig_software_version": "$CIG_SOFTWARE_VERSION",
  "expected_version": "$EXPECTED_TEMPLATE_VERSION",
  "version_match": $([ "$VERSION_MISMATCH" == false ] && echo "true" || echo "false"),
  "missing_fields": $MISSING_JSON,
  "discrepancies": $DISCREPANCIES_JSON,
  "upgrade_recommended": $([ "$TEMPLATE_VERSION" != "$EXPECTED_TEMPLATE_VERSION" ] && echo "true" || echo "false")
}
EOF
else
    echo "File: $WORKFLOW_FILE"
    echo "Template Version: $TEMPLATE_VERSION"
    echo "CIG Software Version: $CIG_SOFTWARE_VERSION"
    echo ""

    if [[ "$VERSION_MISMATCH" == true ]]; then
        echo "⚠️  Version Discrepancies:"
        for discrepancy in "${DISCREPANCIES[@]}"; do
            echo "  - $discrepancy"
        done
        echo ""
    fi

    if [[ ${#MISSING_FIELDS[@]} -gt 0 ]]; then
        echo "⚠️  Missing Required Fields:"
        for field in "${MISSING_FIELDS[@]}"; do
            echo "  - $field"
        done
        echo ""
    fi

    if [[ "$TEMPLATE_VERSION" != "$EXPECTED_TEMPLATE_VERSION" ]]; then
        echo "💡 Upgrade Recommended:"
        echo "  This workflow file uses template version $TEMPLATE_VERSION."
        echo "  Consider upgrading to version $EXPECTED_TEMPLATE_VERSION for latest features."
        echo ""
        echo "  Would you like to:"
        echo "  1. Continue with current version (backward compatible)"
        echo "  2. Upgrade to version $EXPECTED_TEMPLATE_VERSION"
        echo "  3. Learn more about version differences"
    else
        echo "✓ Template version is up to date"
    fi
fi

exit $EXIT_CODE
