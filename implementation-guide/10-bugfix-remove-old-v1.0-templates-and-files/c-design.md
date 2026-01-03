# Remove old v1.0 templates and files - Design

## Task Reference
- **Task ID**: internal-10
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/10-remove-old-v1.0-templates-and-files
- **Template Version**: 2.0

## Goal
Simple file deletion - no design required.

## Key Decisions
- **Decision**: Delete files by name pattern (no letter prefix = v1.0)
- **Rationale**: v1.0 files without a-h prefixes are superseded by v2.0 symlinks
- **Trade-offs**: None - straightforward cleanup

## Files Affected
Delete from `.cig/templates/<type>/`:
- feature: 7 files (design, implementation, maintenance, plan, requirements, rollout, testing)
- bugfix: 4 files (implementation, plan, rollout, testing)
- chore: 4 files (implementation, maintenance, plan, validation)
- hotfix: 3 files (implementation, plan, rollout)

## Validation
- [x] Identified files by absence of letter prefix
- [x] Verified v2.0 symlinks exist for each type
- [x] No code references to deleted files

## Status
**Status**: Finished
**Next Action**: N/A
**Blockers**: None

## Actual Results
Design phase minimal as expected - simple file deletion by pattern. Verified v2.0 symlinks exist before planning deletion.

## Lessons Learned
Even simple tasks benefit from explicit design phase to document decision rationale.
