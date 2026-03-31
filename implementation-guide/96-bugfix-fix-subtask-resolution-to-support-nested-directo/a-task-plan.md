# Fix subtask resolution to support nested directory hierarchy — Plan
**Task**: 96 (bugfix)

## Task Reference
- **Task ID**: internal-96
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/96-fix-subtask-resolution-nested-hierarchy
- **Template Version**: 2.1

## Goal
Make CWF's task resolution, creation, and status scripts support nested subtask directories (e.g. `implementation-guide/48-feature-parent/48.1-bugfix-child/`) so that hierarchical task nesting — a founding design goal — actually works end-to-end.

## Problem Statement
Currently all Perl scripts (`TaskPath.pm`, status aggregators, context-inheritance, template-copier) assume a flat directory structure where every task lives directly in `implementation-guide/`. The skill instructions are ambiguous, and `hierarchy-manager.md` explicitly prescribes nesting — but nothing in the code supports it. Users creating subtasks via `/cwf-subtask` hit "Task not found" errors because the resolution code never looks inside parent directories.

## Success Criteria
- [ ] `context-manager hierarchy 48.1` resolves when `48.1-*` is nested inside `48-*/`
- [ ] `context-manager inheritance 48.1` returns parent context for nested subtasks
- [ ] `/cwf-subtask` creates subtask directories nested inside their parent
- [ ] `/cwf-status` aggregates status correctly across nested hierarchies
- [ ] Existing flat top-level tasks continue to resolve (no regression)
- [ ] Test suite covers 2-level and 3-level nesting (e.g. `1`, `1.1`, `1.1.1`)

## Original Estimate
**Effort**: 1–2 sessions
**Complexity**: High
**Dependencies**: None — all affected code is in this repo

## Major Milestones
1. **Core resolution**: `TaskPath::resolve_num()` and `build_glob()` search nested directories
2. **Task creation**: `template-copier-v2.1` places subtasks inside parent directories
3. **Status & inheritance**: Status aggregators and context-inheritance traverse nested trees
4. **Skill docs**: `cwf-new-task` and `cwf-subtask` give explicit nested path examples

## Risk Assessment
### High Priority Risks
- **Regression on existing top-level tasks**: Changing `resolve_num()` could break resolution for the ~95 existing flat tasks in this repo
  - **Mitigation**: Flat top-level tasks are the base case (no dots in number) — search starts at `implementation-guide/` which is unchanged. Test against existing tasks before/after.
- **Performance on deep nesting**: Recursive directory search could be slow on large task trees
  - **Mitigation**: Build path deterministically from task number (48.1 → look inside 48-*/), don't do a full filesystem walk. Max realistic depth is 3–4 levels.

### Medium Priority Risks
- **Mixed flat/nested state during migration**: Some users may already have subtasks created flat
  - **Mitigation**: Resolution should try nested first (correct), fall back to flat (legacy). Document migration path for existing flat subtasks.
- **glob pattern complexity**: Dots in task numbers interact with shell globbing
  - **Mitigation**: Perl's `glob()` treats dots literally — not a wildcard. Verified.

## Dependencies
- None

## Constraints
- Must not break resolution of existing top-level tasks (backward compatibility)
- Must work with both v2.0 and v2.1 format tasks
- Git branch names remain flat (git limitation) — only directory structure changes

## Decomposition Check
- [x] **Complexity**: Yes — 3 distinct concerns: resolution, creation, aggregation
- [ ] **Time**: Borderline — achievable in 1–2 sessions but dense
- [ ] **People**: No
- [ ] **Risk**: Moderate — core resolution is high-risk, other changes follow from it
- [ ] **Independence**: Partially — creation depends on resolution working first

One signal triggered (complexity). Given that resolution/creation/aggregation share the same module (`TaskPath.pm`) and must be consistent, keeping this as a single task is appropriate. Subtask decomposition would create coordination overhead without benefit.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 96
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
