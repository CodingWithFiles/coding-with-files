# Phase skills set own terminal status at checkpoint - Rollout
**Task**: 222 (feature)

## Task Reference
- **Task ID**: internal-222
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/222-phase-skills-set-own-terminal-status
- **Template Version**: 2.1

## Goal
Define how the Task 222 change (phase skills stamp their own terminal status;
strengthened stale-status hook; template hygiene) reaches main and installed users.

## Deployment Strategy
### Release Type
- **Strategy**: Single-step release via the standard CWF mechanism — squash to a
  linear commit on `main`, then a `v1.1.222` version tag. No phased/canary model
  applies: CWF is a documentation-and-helper system, not a running service, and the
  change is idempotent config/doc/test/hook content with no runtime data path.
- **Rationale**: The blast radius is bounded — one hashed-file edit (the hook), one
  deleted template hint, one operator-facing doc edit, two test files. Installed users
  adopt on their own schedule via `.cwf/scripts/cwf-manage update`; there is no
  server-side flip to stage.
- **Rollback Plan**: `git revert` the squashed commit (or a follow-up rollback
  release); installed users run `cwf-manage rollback`. The hook sha256 in
  `script-hashes.json` reverts atomically with the hook in the same commit, so
  `cwf-manage validate` stays green on either side of a rollback.

### Pre-Deployment Checklist
- [x] Code review completed — all 7 changeset reviewers (f: 5, g: 2) returned `no findings`
- [x] All tests passing — full suite 998 tests / 76 files green (`prove -l t/`)
- [x] Security scan — `security-review-changeset` clean; one hashed edit, no new input surface
- [x] Performance validated — no runtime path modified (NFR1); checkpoint/validate timings unchanged
- [x] Documentation updated — `retrospective-extras.md` (operator-facing) revised
- [x] Integrity configured — hook sha256 refreshed in-commit; `cwf-manage validate` OK
- [ ] Merge to main + `v1.1.222` tag — **human-only action** (see Rollback Plan / Next Steps)

## Rollout Plan
Phased user rollout does not apply (no service, no traffic to split). The effective
"phases" are the release-mechanics gates:

### Phase 1: Merge to main
- **Scope**: Squash task branch to a single linear commit on `main` (archaeological
  main; per-phase checkpoints preserved off-main).
- **Gate**: `cwf-manage validate` OK on the squashed tree; working tree clean.

### Phase 2: Version tag
- **Scope**: `v1.1.222` tag on the squash commit (human-only).
- **Gate**: Tag describes cleanly; CHANGELOG/version reflect the task.

### Phase 3: User adoption
- **Scope**: Installed repos pull the change via `cwf-manage update` at their own pace.
- **Monitoring**: `cwf-manage validate` post-update confirms hook integrity for each user.

## Monitoring
### Key Metrics
- **Integrity**: `cwf-manage validate` green (hook sha256 matches) after update.
- **Behaviour**: New phase checkpoints stamp a canonical terminal status; the
  retrospective status sweep (kept as defence-in-depth) reports no non-terminal leaks.
- **Hook signal**: `stop-stale-status-detector` flags `Backlog` **and** any
  non-canonical status — watch for it firing on legitimate in-flight files (it should
  not: `In Progress`/`Testing` are valid and unflagged).

### Alerting
- No automated alerting (offline dev tool). The surfaced signals are the Stop-hook
  system message and a non-zero `cwf-manage validate` exit — both are operator-visible.

## Rollback Plan
### Triggers
- `cwf-manage validate` fails post-update (hook/hash mismatch).
- The strengthened hook produces false positives on valid in-flight statuses.
- The `&&`-chained retrospective stamp blocks a legitimate commit unexpectedly.

### Procedure
1. **Immediate**: Stop further adoption; capture the failing `validate`/hook output.
2. **Rollback**: `git revert` the squash commit (maintainer) / `cwf-manage rollback`
   (installed user) — hook and its sha256 revert together, no manual hash surgery.
3. **Communication**: Note the rollback in CHANGELOG at the next release.
4. **Analysis**: Root-cause in a follow-up task; the retrospective sweep remains as the
   backstop while the cause is fixed.

## Success Criteria
- [x] Deployment strategy defined with rationale (single-step release, no phased traffic)
- [x] Pre-deployment checklist completed (bar the human-only merge/tag)
- [x] Rollout mechanics specified (merge → tag → user adoption)
- [x] Rollback plan documented (revert / `cwf-manage rollback`, atomic hash revert)
- [ ] Merge + tag executed — deferred to the human operator

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout plan documented. No code deployed by this phase: the actual release (merge to
main + `v1.1.222` tag) is a human-only action performed after the retrospective. This
task's own j-retrospective checkpoint is the first genuine end-to-end exercise of the
new `&&`-chained terminal-status stamp.

## Lessons Learned
For an offline documentation/helper system the service-shaped rollout template (canary,
traffic phases, alerting) does not map — the honest "rollout" is merge + tag + `cwf-manage
update`, and the atomic hook/sha256 revert is what makes rollback safe.
