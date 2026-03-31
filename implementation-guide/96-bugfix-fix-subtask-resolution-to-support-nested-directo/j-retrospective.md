# Fix subtask resolution to support nested directory hierarchy — Retrospective
**Task**: 96 (bugfix)

## Task Reference
- **Task ID**: internal-96
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/96-fix-subtask-resolution-nested-hierarchy
- **Template Version**: 2.1
- **Retrospective Date**: 2026-03-31

## Executive Summary
- **Duration**: 1 session (estimated: 1–2 sessions — on target)
- **Scope**: As planned — 2 Perl files modified, 2 skill docs updated, 5 scripts verified unchanged
- **Outcome**: Complete. Nested subtask directories now work end-to-end: resolution, inheritance, status, and creation. All 13 test cases pass.

## Variance Analysis
### Scope Changes
- **Additions**: Security hash update (script-hashes.json) — expected but not listed in plan
- **Removals**: None

### Quality Metrics
- **Test Coverage**: 13/13 test cases passing (resolution, inheritance, status, creation, find_children, skill docs)
- **Defect Rate**: 0 — all tests passed first run
- **Regression**: Top-level tasks verified working

## What Went Well
- The iterative ancestor walk algorithm was clean and minimal — 8 lines of Perl replaced the single flat glob, and it naturally handles any nesting depth
- Status aggregator and context-inheritance scripts required **zero code changes** — they already delegated to `resolve()` or had recursive traversal built in. The design correctly predicted which files were "verify only"
- Test fixtures (task 900+) provided clear isolation without touching real data

## What Could Be Improved
- This bug existed since the project's inception — the hierarchical nesting was documented as a founding goal in `hierarchy-manager.md` but never implemented in the code. Earlier integration testing with actual subtask creation would have caught it
- The `cwf-new-task` skill's "create subdirectory" wording was ambiguous for months. Skill docs that reference filesystem operations should always include a concrete path example

## Key Learnings
### Technical Insights
- Perl's `glob()` treats dots literally — no escaping needed for dotted task numbers like `48.1`
- The iterative approach (walk ancestors) is cleaner than recursive search (scan filesystem) because it's deterministic: the path is derived from the task number, not discovered by scanning

### Process Learnings
- When a design doc prescribes a behaviour (`hierarchy-manager.md` → nested dirs) and the code doesn't implement it, that's a bug not a future feature. Should have been caught during the task that created `hierarchy-manager.md`

## Recommendations
### Future Work
- Consider adding a `cwf-manage validate` check that verifies subtask directories are nested inside their parents (structural integrity check)
- Existing flat subtasks in other users' repos will not be found by the new resolution. Document migration guidance: move `implementation-guide/X.Y-*` into `implementation-guide/X-*/`

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge to main
**Blockers**: None
**Completion Date**: 2026-03-31

## Archived Materials
- `implementation-guide/96-bugfix-fix-subtask-resolution-to-support-nested-directo/`
