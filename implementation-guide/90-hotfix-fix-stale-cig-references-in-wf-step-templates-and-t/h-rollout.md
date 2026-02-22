# Fix stale CIG references in wf step templates and template-copier - Rollout
**Task**: 90 (hotfix)

## Task Reference
- **Task ID**: internal-90
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/90-fix-stale-cig-references-in-wf-step-templates-and-t
- **Template Version**: 2.1

## Goal
Merge hotfix to main. No external deployment — internal dev tooling only.

## Deployment Strategy
Single ff-merge to main by human. No staged rollout needed.

## Pre-Deployment Checklist
- [x] `prove t/` — 18 files, 173 tests pass
- [x] `cwf-manage validate` — OK
- [x] TC-5 broad sweep — no `.cig/` or `/cig-` anywhere in `.cwf/`
- [x] All workflow files at Finished status

## Rollout Plan
1. Human merges `hotfix/90-...` → `main` via `git merge --ff-only`
2. Human applies `v0.1.90` tag post-merge (human-only action per Task 89 convention)

## Rollback Plan
**Trigger**: `cwf-manage validate` fails or new task generates wrong paths on main.
**Procedure**: `git revert` the merge commit; validate; file follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 90
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Branch ready for human ff-merge. All pre-deployment checks passed.

## Lessons Learned
Hotfix rollout is correctly a single ff-merge — no staging needed for a
string-replacement fix with full test coverage.
