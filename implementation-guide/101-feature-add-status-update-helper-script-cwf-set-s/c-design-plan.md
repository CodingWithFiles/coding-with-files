# Add Status Update Helper Script (cwf-set-status) - Design
**Task**: 101 (feature)

## Task Reference
- **Task ID**: internal-101
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/101-add-status-update-helper-script-cwf-set-s
- **Template Version**: 2.1

## Goal
Define architecture and design decisions for Add Status Update Helper Script (cwf-set-status).

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Standalone Script
- **Decision**: Single script in `.cwf/scripts/command-helpers/cwf-set-status`, no new `.pm` module
- **Rationale**: Self-contained (~45 lines). Future `cwf-checkpoint-commit` can shell out to it.

### Config via Relative Path + JSON::PP
- **Decision**: Read `implementation-guide/cwf-project.json` relative to cwd (matching `cwf-load-project-config` convention), parse with core `JSON::PP`
- **Rationale**: Skills always run from repo root. No git root resolution needed. Config shape: `{"workflow": {"status-values": {"Backlog": 0, "Finished": 100, ...}}}` — script uses `keys %$status_values`.

## System Design

### Data Flow
1. Parse arguments: exactly 2 positional args `(file-path, new-status)`
2. Read `implementation-guide/cwf-project.json`, extract valid status names
3. Validate `new-status` against valid set (case-sensitive)
4. Slurp target file, find first line matching `^\*\*Status\*\*:\s*(.+)$`
5. If current == new → exit 0 (idempotent no-op)
6. Replace value on matched line, write file back
7. Exit 0

### Interface

```
Usage: cwf-set-status <file-path> <new-status>

Exit codes:
  0  Success (updated or already at target value)
  1  Any failure (stderr explains)
```

### Error Messages
```
cwf-set-status: error: file not found: path/to/file.md
cwf-set-status: error: invalid status "Done" — valid: Backlog, Blocked, To-Do, In Progress, Testing, Finished, Cancelled, Skipped
cwf-set-status: error: no **Status**: field found in path/to/file.md
```

## Validation
- [ ] Design review completed
- [ ] Conventions match existing helper scripts

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 101
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
