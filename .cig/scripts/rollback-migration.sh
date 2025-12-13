#!/usr/bin/env bash
#
# rollback-migration.sh - Rollback v1.0 to v2.0 migration
#
# Usage: rollback-migration.sh [BACKUP_REF]
#
# Arguments:
#   BACKUP_REF        Backup reference (git tag or directory path)
#                     Examples: "migration-backup-20250113-143022" (git tag)
#                               ".cig/migration-backup/20250113-143022/" (manual)
#                     Default: most recent backup from migration-state.json
#
# Rollback Strategy:
#   IF backup is git tag:
#     - git reset --hard <tag>
#     - Remove migration-state.json
#
#   ELSE IF backup is directory:
#     - Remove implementation-guide/
#     - Restore from .cig/migration-backup/{timestamp}/
#     - Remove migration-state.json
#
# Exit Codes:
#   0 - Rollback successful
#   1 - Rollback failed (manual intervention needed)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIGRATION_STATE_FILE="$PROJECT_ROOT/.cig/migration-state.json"

# Parse arguments
BACKUP_REF=""
if [[ $# -ge 1 ]]; then
    BACKUP_REF="$1"
else
    # Try to read from migration-state.json
    if [[ -f "$MIGRATION_STATE_FILE" ]]; then
        BACKUP_REF=$(grep '"backup_ref"' "$MIGRATION_STATE_FILE" | sed 's/.*"backup_ref": "\(.*\)".*/\1/')
        echo "Using backup reference from migration state: $BACKUP_REF" >&2
    else
        echo "Error: No backup reference provided and no migration-state.json found" >&2
        echo "Usage: rollback-migration.sh [BACKUP_REF]" >&2
        exit 1
    fi
fi

if [[ -z "$BACKUP_REF" ]]; then
    echo "Error: Backup reference is empty" >&2
    exit 1
fi

# Rollback function
rollback_migration() {
    local backup_ref="$1"

    cd "$PROJECT_ROOT"

    echo "=== CIG Migration Rollback ===" >&2
    echo "Backup reference: $backup_ref" >&2
    echo "" >&2

    # Check if this is a git-based backup
    if [[ "$backup_ref" == git:* ]]; then
        # Git-based rollback
        local tag="${backup_ref#git:}"

        echo "Detected git tag backup: $tag" >&2

        # Check if git repo exists
        if ! git rev-parse --git-dir > /dev/null 2>&1; then
            echo "Error: Not a git repository, but backup reference is a git tag" >&2
            exit 1
        fi

        # Check if tag exists
        if ! git tag | grep -q "^$tag$"; then
            echo "Error: Git tag not found: $tag" >&2
            echo "Available tags:" >&2
            git tag | grep "migration-backup" || echo "  (no migration backup tags found)" >&2
            exit 1
        fi

        # Confirm rollback
        echo "⚠  WARNING: This will reset your repository to the backup point." >&2
        echo "   All changes after the backup will be lost." >&2
        read -p "Continue? (y/N): " -n 1 -r
        echo >&2
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Rollback cancelled." >&2
            exit 0
        fi

        # Perform rollback
        echo "Rolling back to git tag: $tag" >&2
        git reset --hard "$tag"

        # Remove the backup tag
        git tag -d "$tag"
        echo "✓ Git tag removed: $tag" >&2

        # Remove migration state file
        if [[ -f "$MIGRATION_STATE_FILE" ]]; then
            rm -f "$MIGRATION_STATE_FILE"
            echo "✓ Migration state file removed" >&2
        fi

        echo "" >&2
        echo "✓ Rollback successful!" >&2
        return 0

    else
        # Directory-based rollback
        echo "Detected manual backup directory: $backup_ref" >&2

        # Check if backup directory exists
        if [[ ! -d "$backup_ref" ]]; then
            echo "Error: Backup directory not found: $backup_ref" >&2
            echo "Looking for backups in .cig/migration-backup/:" >&2
            if [[ -d ".cig/migration-backup" ]]; then
                ls -la ".cig/migration-backup/" >&2
            else
                echo "  (no migration-backup directory found)" >&2
            fi
            exit 1
        fi

        # Check if backup contains implementation-guide
        if [[ ! -d "$backup_ref/implementation-guide" ]]; then
            echo "Error: Backup directory doesn't contain implementation-guide: $backup_ref" >&2
            exit 1
        fi

        # Confirm rollback
        echo "⚠  WARNING: This will delete implementation-guide/ and restore from backup." >&2
        echo "   All changes will be lost." >&2
        read -p "Continue? (y/N): " -n 1 -r
        echo >&2
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Rollback cancelled." >&2
            exit 0
        fi

        # Perform rollback
        echo "Removing current implementation-guide/..." >&2
        rm -rf implementation-guide/

        echo "Restoring from backup..." >&2
        cp -r "$backup_ref/implementation-guide" .

        echo "✓ Implementation guide restored from backup" >&2

        # Remove migration state file
        if [[ -f "$MIGRATION_STATE_FILE" ]]; then
            rm -f "$MIGRATION_STATE_FILE"
            echo "✓ Migration state file removed" >&2
        fi

        echo "" >&2
        echo "✓ Rollback successful!" >&2
        return 0
    fi
}

# Main execution
rollback_migration "$BACKUP_REF"
