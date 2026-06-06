# Adopt guarded worktree enter/exit process - Rollout
**Task**: 181 (feature)

## Task Reference
- **Task ID**: internal-181
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/181-adopt-guarded-worktree-process
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for Adopt guarded worktree enter/exit process.

## Deployment Strategy
### Release Type
- **Strategy**: In-repo merge to `main` (no user-facing service). CWF "deploys" by
  landing the change on `main`; installed CWF repos pick it up on their next
  `cwf-manage update` (the docs tree is copied wholesale and the edited helper +
  refreshed hash propagate together).
- **Rationale**: This is a documentation + single-config + one-helper change to the CWF
  system itself; there is no runtime service, no users to ramp, no telemetry surface.
  Phased/canary rollout does not apply.
- **Rollback Plan**: `git revert` of the squashed merge commit on `main` (the change is
  additive and self-contained: one new doc, one settings key, two cross-links, one
  read-only/warn-only helper sub + its hash). See Rollback Plan below.

### Pre-Deployment Checklist
- [x] Code review completed — implementation- and testing-phase security reviews both
      `no findings`.
- [x] All tests passing — 11/11 TCs (TC-11 FR9 detector against a fixture; TC-8 FR8 C2
      probe live, refusal observed, `discard_changes` never used).
- [x] Security scan — FR4(a–e) review clean both phases; `cwf-manage validate` OK
      (hash + perms current for the edited helper).
- [x] Performance — N/A by NFR1 (one doc + one settings key; the scan is two best-effort
      file reads at install time).
- [x] Documentation updated — the deliverable *is* documentation
      (`worktree-process.md`); CLAUDE.md + `tmp-paths.md` cross-links added.
- [x] MEMORY pointer added (FR7 non-gating, this phase): `reference_worktree_process`
      memory + MEMORY.md line; related `feedback_worktree_cwd_dataloss` memory updated
      (R1 done).
- [x] Monitoring/alerting — N/A (no runtime service). The FR9 install/update warning is
      the standing detector for the one residual (a dangerous allowlist entry).
- [x] Rollback plan documented (below).

## Rollout Plan
- **Single step**: land Task 181 on `main` via the project's archaeological-main flow
  (squash on the task branch → `git branch -f main <sha>`), then push. **Merging to
  `main`, tagging, and releasing are human-only actions** — this doc only *suggests* the
  merge; the maintainer performs it (see Retrospective "Suggest Merge").
- **Downstream propagation**: installed repos receive the doc + `baseRef: head` guidance
  + the FR9 detector on their next `cwf-manage update`. On that update the detector
  immediately scans their settings and warns if a `git worktree` allowlist entry exists —
  this is the intended rollout-time surfacing of the residual.
- **No phased/percentage ramp** — not applicable to a docs/config change.

## Monitoring
- **N/A — no runtime service.** The closest analogue is the FR9 install/update warning,
  which is the ongoing "is a dangerous allowlist entry present?" signal. It is
  warning-only and cannot abort an install/update.

## Rollback Plan
### Triggers
- A defect found in the helper edit (e.g. the scan misbehaving on some settings file).
- The committed `worktree.baseRef: head` causing an unexpected harness interaction.

### Procedure
1. **Assess**: the change is additive and warning-only; a defect is unlikely to be urgent.
2. **Revert**: `git revert` the merge commit on `main` (restores the pre-181 helper, its
   prior hash, and drops the doc/settings key together — they are one squashed commit).
3. **Re-validate**: `cwf-manage validate` after revert (hash must match the reverted
   helper).
4. **Analysis**: capture the cause in a follow-up task; the doc-level mandate
   (`baseRef: head`, guarded-tools-only) stands regardless of the committed key.

## Success Criteria
- [x] All gating ACs (AC1–AC10) met and recorded in `g-testing-exec.md`.
- [x] `cwf-manage validate` OK; no new violations attributable to this task.
- [x] MEMORY pointer added (FR7 non-gating).
- [ ] Merge to `main` — **human-only**; suggested at retrospective, not performed here.

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout is in-repo merge-to-main (human-only, suggested at retrospective). FR7 MEMORY
pointer added this phase (out-of-repo). All gating ACs met; pre-deployment checklist
complete; rollback = `git revert` of the squashed commit.

## Lessons Learned
For a CWF docs/config feature there is no runtime rollout surface; the FR9 install/update
warning is the closest thing to "monitoring" and surfaces the one residual at update time.
