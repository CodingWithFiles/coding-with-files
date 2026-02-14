# Migration Guide: v1.0 to v2.0

## Why Migrate?

**v1.0 Limitations**: The original CWF structure organised tasks by type first, then number (`implementation-guide/feature/1-task-name/`). This flat hierarchy prevented task decomposition—you couldn't break a complex task into subtasks without losing the structural relationship.

**v2.0 Hierarchical Structure**: The new structure uses decimal numbering (`implementation-guide/1-feature-task/`, `implementation-guide/1.1-feature-subtask/`) enabling infinite task nesting. Parent-child relationships are encoded directly in the directory structure and task numbers.

**What You Gain**:
- **Infinite task nesting**: Break complex tasks into subtasks (1, 1.1, 1.1.2, etc.) with full workflow support at every level
- **Context inheritance**: Subtasks automatically receive parent context via structural maps, reducing redundant documentation
- **Lettered workflow files**: Clear alphabetical ordering (a-plan.md, b-requirements.md, ..., h-retrospective.md) instead of relying on naming conventions
- **Template versioning**: Files are tagged with `Template Version: 2.0`, enabling future format detection and automated upgrades

**When to Migrate**: Migration is **optional** for most projects. Old v1.0 tasks continue to function, but cannot leverage hierarchical decomposition or context inheritance. Migrate when:
- You need to break existing tasks into subtasks
- You want to use the new 8-step lettered workflow consistently
- You're starting a new phase and want all tasks using the same structure

## How Migration Works

### Prerequisites

**Required**: Clean git working directory (commit or stash changes first)

**Recommended**: Read the script help for current options and exit codes:
```bash
.cwf/scripts/migrate-v1-to-v2.sh --help
```

### Migration Process

Migration follows a six-step process:

1. **Discovery**: Identifies all v1.0 tasks (checks for `Template Version: 2.0` to avoid re-migrating)
2. **Pre-flight Checks**: Validates git status and counts tasks to migrate
3. **Backup Creation**: Creates git tag (`migration-backup-{timestamp}`) or manual backup if not in git repo
4. **Migration**: Moves directories to new structure, renames workflow files, inserts template version metadata
5. **Validation**: Verifies template version fields exist in migrated files
6. **Report**: Summarises results and provides rollback command

### Backup Strategy

**Git-First Approach**: If you're in a git repository, migration creates a lightweight git tag before making changes. Rollback is instant via `git reset --hard {tag}`.

**Manual Fallback**: Without git, migration creates a backup directory (`.cwf/migration-backup/{timestamp}/`) containing copies of all implementation-guide files.

**Migration State**: After completion, migration metadata is stored in `.cwf/migration-backup/{timestamp}/migration-state.json` for future reference.

### Common Scenarios

**Preview changes without applying**:
```bash
.cwf/scripts/migrate-v1-to-v2.sh --dry-run all
```

**Migrate all v1.0 tasks**:
```bash
.cwf/scripts/migrate-v1-to-v2.sh all
```

**Migrate single task**:
```bash
.cwf/scripts/migrate-v1-to-v2.sh 1
```

**Rollback migration** (printed by migration script after completion):
```bash
.cwf/scripts/rollback-migration.sh {backup-ref}
```

### What Gets Changed

**Directory Structure**:
- `implementation-guide/feature/1-task/` → `implementation-guide/1-feature-task/`
- `implementation-guide/bugfix/2-fix/` → `implementation-guide/2-bugfix-fix/`

**Workflow Files**:
- `plan.md` → `a-plan.md`
- `requirements.md` → `b-requirements.md`
- `design.md` → `c-design.md`
- `implementation.md` → `d-implementation.md`
- `testing.md` → `e-testing.md`
- `rollout.md` → `f-rollout.md`
- `maintenance.md` → `g-maintenance.md`

**Metadata Insertion**: Each workflow file receives two new metadata fields:
- `Template Version: 2.0`
- `Migration: v1.0 ({backup-ref}) → v2.0`

**Content Preservation**: File contents are unchanged except for metadata insertion. SHA256 validation occurs pre- and post-migration to verify content integrity (metadata changes are expected and validated separately).

## Safety Features

**Idempotent**: Safe to run multiple times—already-migrated tasks are skipped automatically

**Validation**: Template version fields are verified in all migrated files

**Rollback**: Instant rollback via git tag or manual backup directory

**Pre-flight Checks**: Migration refuses to run if git working directory has uncommitted changes

## Troubleshooting

**"Uncommitted changes detected"**: Commit or stash your changes before migrating—migration modifies file structure and must start from a clean state.

**"No v1.0 tasks found to migrate"**: All tasks are either already migrated (have `Template Version: 2.0`) or don't match v1.0 structure. Check `--help` for task filtering options.

**Migration validation failed**: Check error output for specific file issues. Use rollback command to revert, then investigate. Report persistent issues to project maintainers.
