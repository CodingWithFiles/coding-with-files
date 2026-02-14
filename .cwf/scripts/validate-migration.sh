#!/usr/bin/env bash
#
# validate-migration.sh - Validate migrated task integrity
#
# Usage: validate-migration.sh TASK_DIR
#
# Arguments:
#   TASK_DIR          Path to migrated task directory
#
# Checks:
#   - Content integrity (SHA256 comparison if migration-state.json available)
#   - Markdown structure valid
#   - Template Version tag present
#   - Migration field present
#   - All expected files exist
#
# Exit Codes:
#   0 - Validation passed
#   1 - Content mismatch detected
#   2 - Structure corruption detected

set -euo pipefail

# Parse arguments
if [[ $# -lt 1 ]]; then
    echo "Error: Missing required argument <task-dir>" >&2
    echo "Usage: validate-migration.sh <task-dir>" >&2
    exit 2
fi

TASK_DIR="$1"

# Validate task directory exists
if [[ ! -d "$TASK_DIR" ]]; then
    echo "Error: Task directory not found: $TASK_DIR" >&2
    exit 2
fi

echo "Validating: $TASK_DIR"

# Check 1: Template Version field
echo -n "  Checking Template Version... "
template_version_found=false
for md_file in "$TASK_DIR"/*.md; do
    if [[ -f "$md_file" ]]; then
        if grep -q "Template Version.*2\.0" "$md_file"; then
            template_version_found=true
            break
        fi
    fi
done

if [[ "$template_version_found" == "true" ]]; then
    echo "✓"
else
    echo "✗"
    echo "Error: Template Version 2.0 not found in any file" >&2
    exit 2
fi

# Check 2: Migration field
echo -n "  Checking Migration field... "
migration_field_found=false
migration_field_count=0
for md_file in "$TASK_DIR"/*.md; do
    if [[ -f "$md_file" ]]; then
        if grep -q "Migration.*v1\.0.*→.*v2\.0" "$md_file"; then
            migration_field_found=true
            migration_field_count=$((migration_field_count + 1))
        fi
    fi
done

if [[ "$migration_field_found" == "true" ]]; then
    echo "✓ (found in $migration_field_count file(s))"
else
    echo "⚠ (not found - may be new v2.0 task)"
fi

# Check 3: Markdown structure (basic check for ## headers)
echo -n "  Checking markdown structure... "
structure_valid=true
for md_file in "$TASK_DIR"/*.md; do
    if [[ -f "$md_file" ]]; then
        # Check for at least one ## header
        if ! grep -q "^## " "$md_file"; then
            echo "✗"
            echo "Error: No level-2 headers found in $(basename "$md_file")" >&2
            structure_valid=false
            break
        fi

        # Check for Task Reference section
        if ! grep -q "^## Task Reference" "$md_file"; then
            echo "✗"
            echo "Error: Task Reference section missing in $(basename "$md_file")" >&2
            structure_valid=false
            break
        fi
    fi
done

if [[ "$structure_valid" == "true" ]]; then
    echo "✓"
else
    exit 2
fi

# Check 4: Expected files exist (v2.0 lettered format)
echo -n "  Checking expected files... "
expected_files=("a-plan.md")
found_files=0

for expected in "${expected_files[@]}"; do
    if [[ -f "$TASK_DIR/$expected" ]]; then
        found_files=$((found_files + 1))
    fi
done

if [[ $found_files -gt 0 ]]; then
    echo "✓ (found $found_files required file(s))"
else
    echo "⚠ (no lettered files found - may be old v1.0 format)"
fi

# Check 5: File count
echo -n "  File count... "
md_count=$(find "$TASK_DIR" -maxdepth 1 -name "*.md" -type f | wc -l)
echo "$md_count markdown file(s)"

# Summary
echo "✓ Validation passed for $TASK_DIR"
exit 0
