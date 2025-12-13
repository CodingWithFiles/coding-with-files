# Migration Tools to Migrate v1.0 to v2.0 - Design

## Task Reference
- **Task ID**: internal-4
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/4-migration-tools
- **Template Version**: 2.0

## Goal
Define architecture and design decisions for safe, automated migration from v1.0 to v2.0 task structure.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Architecture Choice
- **Decision**: Pipeline architecture with discrete, composable stages
- **Rationale**:
  - Each migration concern (backup, validate, migrate directory, rename files, tag version, rollback) is isolated
  - Stages can be tested independently
  - Easy to add dry-run mode by stopping before mutation stages
  - Clear failure points for error reporting
  - Supports reversibility (rollback inverts the pipeline)
- **Trade-offs**:
  - **Benefits**: Testability, clarity, easy rollback, dry-run support
  - **Drawbacks**: More files than monolithic script, requires careful state management between stages

### Technology Stack
- **Migration Script**: Bash (`.cig/scripts/migrate-v1-to-v2.sh`)
  - Rationale: Consistent with existing helper scripts, excellent for file operations
  - Leverages existing helper scripts (hierarchy-resolver.sh, format-detector.sh)
- **Validation Script**: Bash (`.cig/scripts/validate-migration.sh`)
  - Rationale: Markdown parsing, SHA256 hashing, file comparisons
- **Rollback Script**: Bash (`.cig/scripts/rollback-migration.sh`)
  - Rationale: Git operations, directory moves

## System Design
### Component Overview
- **migrate-v1-to-v2.sh** (Main Migration Pipeline)
  - Purpose: Orchestrate migration from v1.0 to v2.0 format
  - Responsibility: Execute pipeline stages, handle dry-run mode, report progress
  - Interface: `migrate-v1-to-v2.sh [--dry-run] [task-num|all]`
  - Exit codes: 0=success, 1=validation failed, 2=migration failed, 3=rollback needed

- **validate-migration.sh** (Validation Component)
  - Purpose: Verify migration preserved content integrity
  - Responsibility: Compare pre/post migration hashes, check markdown structure, verify Template Version tag
  - Interface: `validate-migration.sh <task-dir>`
  - Exit codes: 0=valid, 1=content mismatch, 2=structure corrupt

- **rollback-migration.sh** (Rollback Component)
  - Purpose: Restore pre-migration state from backup
  - Responsibility: Restore directory structure, restore file names, remove Template Version tags
  - Interface: `rollback-migration.sh <backup-id>`
  - Exit codes: 0=rollback successful, 1=rollback failed

- **Migration State File** (.cig/migration-state.json)
  - Purpose: Track migration progress and backup locations
  - Responsibility: Record which tasks migrated, backup paths, timestamps
  - Format: JSON with task array, backup directory, migration timestamp

### Data Flow
```
1. User invokes: migrate-v1-to-v2.sh [--dry-run] [task-num|all]
   ↓
2. Discovery Phase
   - Find v1.0 tasks (implementation-guide/{type}/{num}-{desc}/)
   - Filter by task-num if specified, otherwise all tasks
   - Output: List of tasks to migrate
   ↓
3. Pre-Flight Checks and Backup Strategy
   - Check if git repository exists and is clean

   IF git repo with clean state:
     - Create git commit: "Pre-migration snapshot before v1.0 → v2.0"
     - Tag commit: git tag migration-backup-{timestamp}
     - Backup reference: "git:migration-backup-{timestamp}"

   ELSE IF git repo with uncommitted changes:
     - Error: "Uncommitted changes detected. Commit or stash first."
     - Exit with code 1

   ELSE (no git repo):
     - Create manual backup: .cig/migration-backup/{timestamp}/
     - Copy implementation-guide/ → .cig/migration-backup/{timestamp}/
     - Backup reference: ".cig/migration-backup/{timestamp}/"

   - Record state in .cig/migration-state.json
   ↓
4. Migration Pipeline (per task)
   a. Compute pre-migration hashes (SHA256 of all .md files)
   b. Determine v2.0 target path (extract type from v1.0 path)
   c. Execute git mv for directory structure (or mv if no git)
      - v1.0: implementation-guide/{type}/{num}-{desc}/
      - v2.0: implementation-guide/{num}-{type}-{desc}/
   d. Rename workflow files using git mv (or mv if no git)
      - plan.md → a-plan.md
      - requirements.md → b-requirements.md
      - design.md → c-design.md
      - implementation.md → d-implementation.md
      - testing.md → e-testing.md
      - rollout.md → f-rollout.md (if exists)
      - maintenance.md → g-maintenance.md (if exists)
   e. Insert migration metadata in Task Reference section
      - Find "## Task Reference" section
      - Insert "- **Template Version**: 2.0" after Branch line
      - Insert "- **Migration**: v1.0 ({backup-ref}) → v2.0" after Template Version
   f. Compute post-migration hashes
   g. Validate content integrity (hashes match)
   h. Update migration-state.json
   ↓
5. Validation Phase
   - Run validate-migration.sh on all migrated tasks
   - Verify Template Version: 2.0 in all files
   - Verify Migration field present in all files
   - Check markdown structure valid
   ↓
6. Report Results
   - Dry-run: Show what would change, exit without mutation
   - Success: Report migrated tasks, backup reference
   - Failure: Report error, suggest rollback command with backup reference
```

## Interface Design
### Script Interface: migrate-v1-to-v2.sh
```bash
Usage: migrate-v1-to-v2.sh [OPTIONS] [TASK]

Arguments:
  TASK              Task number to migrate (e.g., "1", "2") or "all" for all tasks
                    Default: all

Options:
  --dry-run         Preview changes without applying them
  --help            Show this help message

Examples:
  migrate-v1-to-v2.sh --dry-run all    # Preview migration of all tasks
  migrate-v1-to-v2.sh 1                # Migrate task 1 only
  migrate-v1-to-v2.sh all              # Migrate all v1.0 tasks

Exit Codes:
  0 - Success
  1 - Pre-flight validation failed
  2 - Migration failed
  3 - Rollback needed (partial failure)
```

### Script Interface: validate-migration.sh
```bash
Usage: validate-migration.sh TASK_DIR

Arguments:
  TASK_DIR          Path to migrated task directory

Checks:
  - Content integrity (SHA256 comparison)
  - Markdown structure valid
  - Template Version tag present
  - All expected files exist

Exit Codes:
  0 - Validation passed
  1 - Content mismatch detected
  2 - Structure corruption detected
```

### Script Interface: rollback-migration.sh
```bash
Usage: rollback-migration.sh [BACKUP_REF]

Arguments:
  BACKUP_REF        Backup reference (git tag or directory path)
                    Examples: "migration-backup-20250113-143022" (git tag)
                              ".cig/migration-backup/20250113-143022/" (manual)
                    Default: most recent backup from migration-state.json

Rollback Strategy:
  IF backup is git tag:
    - git reset --hard <tag>
    - Remove migration-state.json

  ELSE IF backup is directory:
    - Remove implementation-guide/
    - Restore from .cig/migration-backup/{timestamp}/
    - Remove migration-state.json

Exit Codes:
  0 - Rollback successful
  1 - Rollback failed (manual intervention needed)
```

### Data Model: migration-state.json
```json
{
  "version": "1.0",
  "backup_id": "20250113-143022",
  "backup_type": "git|manual",
  "backup_ref": "git:migration-backup-20250113-143022",
  "started_at": "2025-01-13T14:30:22Z",
  "completed_at": "2025-01-13T14:31:15Z",
  "status": "completed|in-progress|failed|rolled-back",
  "tasks": [
    {
      "task_num": "1",
      "v1_path": "implementation-guide/feature/1-initial-implementation-guide/",
      "v2_path": "implementation-guide/1-feature-initial-implementation-guide/",
      "files_migrated": [
        {"old": "plan.md", "new": "a-plan.md", "sha256_pre": "abc123...", "sha256_post": "abc123..."},
        {"old": "requirements.md", "new": "b-requirements.md", "sha256_pre": "def456...", "sha256_post": "def456..."}
      ],
      "status": "completed",
      "migrated_at": "2025-01-13T14:30:45Z"
    }
  ],
  "errors": []
}
```

**Example backup_ref values**:
- Git backup: `"git:migration-backup-20250113-143022"` (git tag name)
- Manual backup: `".cig/migration-backup/20250113-143022/"` (directory path)

### Data Model: Migration Field in Task Files
After migration, all workflow files will have this added to Task Reference section:
```markdown
## Task Reference
- **Task ID**: internal-1
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/1-initial-implementation-guide
- **Template Version**: 2.0
- **Migration**: v1.0 (git:migration-backup-20250113-143022) → v2.0
```

**Format**: `v1.0 ({backup-ref}) → v2.0`
- For future migrations: `v1.0 ({ref1}) → v2.0 ({ref2}) → v2.2`
- Tracks complete migration history with rollback references

## Constraints
- **Git History Preservation**: All file moves must use `git mv` to maintain git log continuity (when git repo exists)
- **Idempotency**: Script must detect already-migrated tasks (check for Template Version: 2.0) and skip them
- **Git-First Backup**: Prefer git tag backup over manual copy (simpler, more reliable)
- **Clean Git State Required**: Migration requires clean working directory (no uncommitted changes)
- **No Breaking Changes**: Migration must not modify file contents except Template Version and Migration fields
- **Dry-Run Support**: Must support --dry-run mode that shows changes without applying them
- **Clear Error Messages**: Report which task/file failed and provide rollback command with backup reference
- **Performance**: Process tasks sequentially (not parallel) to maintain clear audit trail
- **Migration Tracking**: All migrated files must include Migration field with backup reference for rollback

## Validation
- [x] Design satisfies all 5 functional requirements (FR1-FR5)
- [x] Pipeline architecture supports testability priority
- [x] Component responsibilities clearly defined
- [x] Reversibility achieved through backup/rollback design
- [x] Simplicity maintained through discrete stages
- [x] Consistency with existing CIG helper script patterns
- [ ] Design review completed
- [ ] Architecture approved
- [ ] Integration points verified with existing commands

## Status
**Status**: In Progress
**Next Action**: Move to implementation phase (`/cig-implementation 4`)
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
