# Add retrospective version bump and tag settings with versioning helper script - Rollout
**Task**: 114 (feature)

## Task Reference
- **Task ID**: internal-114
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/114-add-retrospective-version-bump-and-tag-settings-w
- **Template Version**: 2.1

## Goal
Define the rollout for the versioning subsystem. CwF is a single-tenant developer tool, not a hosted service — "rollout" here means landing the change on `main` and verifying that the next retrospective uses the new helper scripts.

## Deployment Strategy

### Release Type
- **Strategy**: Single-step merge to `main` after this task's checkpoints branch is squashed and fast-forwarded by the user.
- **Rationale**: There are no users to migrate and no dual-write concerns. The schema additions in `cwf-project.json` are strictly additive (`versioning` and `wf_step_config` blocks); absent fields fall back to documented defaults (`bump_version: true`, `tag_version: false`). Repos that adopt CwF and inherit this change without configuring the new fields will fail closed at the field-name-and-path error, with a clear remediation message naming the field and file. No multi-phase release needed.
- **Rollback Plan**: Revert the squashed commit on `main`. The change is self-contained: removing the commit cleanly restores the previous behaviour. The only persistent side-effect — `versioning.last_released` written into `cwf-project.json` by the smoke test — would also be removed by the revert.

### Pre-Deployment Checklist
- [x] Code review completed (3-agent map/reduce reviews on requirements, design, implementation plans, plus `/simplify` cleanup pass)
- [x] All tests passing — `prove t/` 229/229 PASS (Files=23)
- [x] Security: `cwf-manage validate` clean; SHA256 + 0500 perms recorded for the three new scripts; no `git push`, no network calls
- [x] Performance: `cwf-version-next --task-num=114` runs in 27ms (NFR1 budget: <500ms)
- [x] Documentation: `.cwf/docs/workflow/versioning-standard.md` written; each helper's `--help` references it; `version.yml` rebranded
- [x] Monitoring: not applicable (developer-tool execution model)
- [x] Rollback: revert path verified by inspection — single squash commit, no migrations

## Rollout Plan

This is a single-step rollout — no phasing.

### Phase 1: Land on `main`
- **Scope**: This task's branch, after the j-retrospective checkpoints-and-squash workflow produces the final commit
- **Action**: User runs `git checkout main && git merge --ff-only <task-branch>` (CWF skill suggests; user executes per CLAUDE.md)
- **Success Metric**: `main` HEAD reaches the new commit; `prove t/` and `cwf-manage validate` clean against `main`

### Phase 2: Exercise on the next task
- **Scope**: The next task that runs `/cwf-retrospective`
- **Action**: The retrospective skill's new Step 9 invokes `cwf-version-bump --task-num={N}`, writes `versioning.last_released`, then Step 11 reports `skipped: tag_version=false` (CwF's configured behaviour)
- **Success Metric**: `cwf-project.json` shows `versioning.last_released: "v1.0.{N}"`; no errors during the retrospective

## Monitoring
Not applicable in the conventional sense (no service to monitor). The equivalent is:
- `cwf-manage validate` reports OK after each task's retrospective (already enforced by the post-commit guard)
- `cwf-project.json` schema remains valid (enforced by `CWF::Validate::Config`)

## Rollback Plan

### Triggers
- A retrospective fails because `cwf-version-bump` or `cwf-version-tag` errors unexpectedly
- `cwf-manage validate` regresses
- The schema change rejects a previously-valid `cwf-project.json` from a downstream adopter

### Procedure
1. Document the failure mode (transcript + `cwf-project.json` excerpt)
2. `git revert <squash-commit-sha>` on a hotfix branch
3. Land the revert via the CwF hotfix workflow (`/cwf-new-task <N> hotfix "..."` → through to retrospective)
4. Open a follow-up task to address the root cause

## Success Criteria
- [x] Branch ready to merge (squash will happen as part of j-retrospective)
- [x] No leftover work in scope
- [x] Rollback path documented and trivial (single commit revert)

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance 114
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout is gated on the retrospective squash + user merge. All gates ready.

## Lessons Learned
The full deployment template (blue-green, canary, monitoring, alerting, SLAs) doesn't fit developer-tool changes. A 2-phase plan (land on main → exercise on next task) plus an explicit "not applicable" note for monitoring is the right shape for this class of task. Worth a backlog item to provide a lighter-weight rollout template.
