# Best-practice reviewer for plan and exec steps - Rollout
**Task**: 205 (feature)

## Task Reference
- **Task ID**: internal-205
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/205-best-practice-reviewer
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for Best-practice reviewer for plan and exec steps.

## Deployment Strategy
### Release Type
- **Strategy**: Versioned release of a file-based tool — no runtime deployment.
  The feature ships as new tracked files (`best-practice-resolve`, two agents,
  the shared doc) plus edits to existing skills/docs. It reaches users when the
  change lands on `main`, a `v1.1.205` tag is cut (human-only), and consuming
  repos pull it via `.cwf/scripts/cwf-manage update`.
- **Rationale**: There is no service, process, or user traffic to phase. The
  unit of rollout is the installed `.cwf/` tree; `cwf-manage` already provides
  staged update + rollback with SHA256 verification, so no bespoke mechanism is
  warranted (the best part is no part).
- **Rollback Plan**: `cwf-manage rollback` restores the prior release on a
  consuming repo; in-repo, `git revert` of the squashed task commit. The feature
  is also self-disabling: with no `best-practices.json` present it is a no-op
  (the 0-match branch dog-fooded in f/g), so a faulty rollout degrades to "does
  nothing", never to a broken workflow.

### Pre-Deployment Checklist
- [x] Plan reviewed (parallel plan-review MAP, phases a–e)
- [x] All tests passing — `t/best-practice-resolve.t` 21/21, full `prove t/` 881/881
- [x] Security review completed — changeset reviewer verdict `no findings` (f); cap breach surfaced, not smoothed
- [x] Best-practice review completed — `no findings` (0 matches, unconfigured repo)
- [x] Documentation updated — `.cwf/docs/skills/best-practice-review.md` (single normative source); CLAUDE.md unchanged (no new convention)
- [x] Integrity intact — three new hash entries authored same-commit; `cwf-manage validate` OK
- [ ] Released — tag + GitHub release (human-only; out of scope for this phase)

## Rollout Plan
Single-step. There are no user cohorts to ramp.
1. **Land on main** (human): fast-forward / squash-merge the task branch.
2. **Tag `v1.1.205` + GitHub release** (human-only).
3. **Consuming repos adopt** at their own cadence via `cwf-manage update`;
   `cwf-manage validate` confirms the new hashes post-update.

This repo already runs the feature (it was dog-fooded in f/g), so for CWF
itself the rollout is complete on merge.

## Monitoring
No telemetry — a CLI helper and two agent definitions emit no metrics. Health
signals after adoption:
- `cwf-manage validate` clean on consuming repos (integrity).
- Exec/planning review sections render `no findings` / `findings` / `error`
  correctly — surfaced inline in wf step files, the user is the monitor.
- A `best-practices.json` config that fails to load surfaces as `error` in the
  review section (fail-open never reads as clean) — the designed alarm.

## Rollback Plan
### Triggers
- `cwf-manage validate` reports a hash mismatch on the shipped files.
- The reviewer aborts or corrupts a workflow run (it must only ever add a review
  section; any harder failure is a rollback trigger).
- A security defect found in `best-practice-resolve` path/URL handling.

### Procedure
1. **In-repo**: `git revert` the task's squash commit on a branch; re-run `prove t/` + `cwf-manage validate`.
2. **Consuming repo**: `.cwf/scripts/cwf-manage rollback` to the prior release.
3. **Interim mitigation**: remove `best-practices.json` — the reviewer goes
   silent (0-match no-op) without touching the rest of the workflow.

## Success Criteria
- [x] Rollout vehicle identified (`cwf-manage update` post-release); no bespoke mechanism built
- [x] Pre-deployment checks green (tests, security, integrity)
- [x] Rollback path documented and cheap (revert / `cwf-manage rollback` / delete config)
- [x] Feature is fail-safe by design (unconfigured = no-op)
- [ ] Tag + release cut (human-only, deferred)

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout vehicle is `cwf-manage update` post-release; no bespoke mechanism built.
For CWF itself the feature is already live (dog-fooded in f/g). Tag + release
deferred to the human-only step.

## Lessons Learned
The SaaS-shaped rollout template (canary %, telemetry, alerting) does not map to
a file-based tool; the honest content is "ships via `cwf-manage update`,
integrity via `cwf-manage validate`, fail-open is the steady state". See
`j-retrospective.md`.
