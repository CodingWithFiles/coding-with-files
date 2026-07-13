# unify sandbox and non-sandbox scratch path - Rollout
**Task**: 229 (feature)

## Task Reference
- **Task ID**: internal-229
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/229-unify-sandbox-non-sandbox-scratch-path
- **Template Version**: 2.1

## Goal
Define how the EUID-derived scratch-base change ships and how it is rolled back.

## Deployment Strategy
### Release Type
- **Strategy**: In-place library update, shipped in the next `v1.1.x` tag and pulled by
  users via `cwf-manage update`. There is no runtime service and no user cohort, so
  blue-green / canary / phased-percentage rollout does not apply — the change is a single
  atomic commit set (`CWF::Common.pm` + three callers + `tmp-paths.md` + refreshed
  `script-hashes.json`) that is either present or absent after an update.
- **Rationale**: The only behavioural change users observe is that the per-task scratch
  parent is now `/tmp/claude-<euid>/cwf<slug>/` in every context (sandboxed, unsandboxed,
  hook). It is mode-invariant by construction, so there is nothing to stage or dark-launch.
- **Rollback Plan**: `cwf-manage rollback` to the prior release, or `git revert` of the two
  task commits (f + g) on main. No data migration is involved — scratch dirs are ephemeral
  and re-created on demand, so a rollback simply restores the old `$TMPDIR`-honouring
  derivation with no cleanup step.

### Pre-Deployment Checklist
- [x] Code review completed — 5 changeset reviewers (f) + 2 (g), all `no findings` bar one
      low-severity style note, fixed in-phase
- [x] All tests passing — `prove -r t/`: 78 files, 1077 tests pass (incl. regression guards
      TC-10 poison-`$TMPDIR` invariance, TC-11 intermediate-symlink)
- [x] Security scan — security reviewer: net attack-surface reduction (`$TMPDIR`-injection
      class removed); `cwf-manage validate`: OK after same-commit hash refresh
- [x] Performance — pure string derivation, one fewer `lstat` in the hook path; no measurement needed
- [x] Documentation updated — `tmp-paths.md` rewritten for the EUID base + macOS limitation
- [ ] Monitoring/alerting — N/A (no runtime service; see Monitoring)
- [x] Rollback plan ready — `cwf-manage rollback` / revert; ephemeral scratch, no migration

### Reconciliations completed this phase
- **Superseded BACKLOG item retired**: "Extract a shared `CWF::Common::tmp_base()` helper"
  (Task-215 follow-up) moved to CHANGELOG under Task 229. Its premise — deduplicating the
  four `${TMPDIR:-/tmp}` ternaries and the `$SANDBOX_TMP_PROBE` branch — no longer exists:
  Task 229 removed the `$TMPDIR` read outright, leaving one `$SCRATCH_BASE` scalar, so the
  dedup goal is met by elimination.
- **c-design D3 / Interface wording is superseded, not amended**: c-design-plan.md D3 and
  Interface Design still describe an abandoned contract extension (`scratch_dir` returning
  the *attempted path* in slot 1 alongside `$kind`). Implementation planning (d) refined
  this to a cleaner design — a separate exported `scratch_fail_hint($kind)` helper, with
  `scratch_dir`'s existing `(undef, $kind)` contract left intact. That refinement is
  recorded in d-implementation-plan.md and f-implementation-exec.md. Per the archaeological
  per-phase-checkpoint model, the earlier design record is left as-written (later phases
  supersede it); this is a normal phase-to-phase refinement, not a defect. Flagged for the
  retrospective's Lessons Learned.

## Rollout Plan
Phased user rollout is **not applicable** (see Release Type). The effective rollout is:
1. Merge task branch to main (maintainer, human-only) and tag the next `v1.1.x`.
2. Users adopt on their next `cwf-manage update`; `cwf-manage validate` confirms integrity.
3. First scratch use after update lands under `/tmp/claude-<euid>/cwf<slug>/` — verified by
   the g-phase smoke test (hook-advertised parent == writer `.out` path).

## Monitoring
No runtime metrics exist for a dev-tooling library. The observable signals are:
- **Integrity**: `cwf-manage validate` must stay `OK` post-update.
- **Fail-closed diagnostic**: a user on a platform where `/tmp/claude-<euid>` is not
  writable (notably macOS Seatbelt, whose writable temp is under `/var/folders`) will see
  the `scratch_fail_hint` line naming the base as the cause. That is the intended
  surface-not-smooth signal, not a silent failure.
- **Follow-up trigger**: repeated macOS `mkdir_failed` reports promote the Medium backlog
  item "Platform-specific scratch base (Linux/macOS/…)" (added this task).

## Rollback Plan
### Triggers
- `cwf-manage validate` fails post-update on an unmodified install.
- A regression in scratch resolution on Linux/WSL2 (the supported platform) — e.g. the
  hook and a writer disagree on the parent again.
- The macOS fail-closed behaviour proves more disruptive than the accepted limitation
  assumed, before the platform-specific follow-up lands.

### Procedure
1. **Immediate**: `cwf-manage rollback` to the prior release (or `git revert` f + g on main).
2. **Verify**: `cwf-manage validate` OK; `prove -r t/` green on the reverted tree.
3. **Communication**: note the revert in CHANGELOG; re-open the retired backlog context if needed.
4. **Analysis**: capture the failing platform/context and fold into the platform-specific
   scratch-base follow-up.

## Success Criteria
- [x] Deployment strategy defined and matched to a dev-tooling library change
- [x] Pre-deployment checklist worked through (N/A items justified)
- [x] Rollout path specified (update-driven, no user cohort)
- [x] Rollback plan documented (rollback/revert, ephemeral scratch, no migration)
- [x] Deferred reconciliations (BACKLOG retire, c-design supersession) closed out

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Ships in the next `v1.1.x` via `cwf-manage update`; validate OK; rollback is
`cwf-manage rollback`/revert with no migration. Both deferred reconciliations closed.

## Lessons Learned
The SLA/phased-rollout template does not fit an internal library change; recording sections
as N/A-with-justification is more honest than forcing boilerplate. Rollout was the right place
to close the two deferred reconciliations (backlog retire, c-design supersession).
