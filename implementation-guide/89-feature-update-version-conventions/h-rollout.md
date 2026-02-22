# Update version conventions - Rollout
**Task**: 89 (feature)

## Task Reference
- **Task ID**: internal-89
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/89-update-version-conventions
- **Template Version**: 2.1

## Goal
Merge task 89 changes to main: versioning section in `CLAUDE.md` and the
`cwf-manage list-releases` filtered view.

## Deployment Strategy

**Internal dev tooling** — no external users, no staged environments, no network
dependencies for the new code paths. Rollout is a single ff-merge to main by a human.

## Pre-Deployment Checklist
- [x] `prove t/` — 18 files, 173 tests, all pass
- [x] `cwf-manage validate` — OK
- [x] `grep -r "Versioning" .cwf/` — no matches (isolation verified)
- [x] `CLAUDE.md` versioning section complete and correct
- [x] `script-hashes.json` updated for modified `cwf-manage`
- [x] All workflow files at Finished status

## Rollout Plan

**Single phase** (no staged rollout needed — internal tooling, no external users):

1. Human merges `feature/89-update-version-conventions` → `main` via `git merge --ff-only`
2. Human applies `v0.1.89` tag to main post-merge (per task 89 convention; human-only action)

## Rollback Plan

**Trigger**: `cwf-manage validate` fails on main, or `list-releases` produces wrong output.

**Procedure**:
- `git revert` the merge commit on main, or `git branch -f main <prior-sha>`
- `cwf-manage validate` to confirm clean
- File bug task; fix on new branch

## Monitoring
- `cwf-manage validate` on main post-merge — single check, immediate feedback
- No ongoing monitoring needed (pure function logic, no state, no network path changes)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 89
**Blockers**: None — merge is a human action

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Branch ready for human ff-merge to main. All pre-deployment checks passed.

## Lessons Learned
Single ff-merge rollout is correct for internal dev tooling with no external users.
No staged rollout needed when all validation happens in the test suite.
