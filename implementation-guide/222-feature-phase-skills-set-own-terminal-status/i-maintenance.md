# Phase skills set own terminal status at checkpoint - Maintenance
**Task**: 222 (feature)

## Task Reference
- **Task ID**: internal-222
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/222-phase-skills-set-own-terminal-status
- **Template Version**: 2.1

## Goal
Define the ongoing maintenance surface for the Task 222 change. This is offline
documentation/config/hook content, not a running service — there is no uptime, traffic,
or scaling dimension. The live maintenance concerns are integrity of the changed hook,
correctness of its flagging decision, and the health of the retained defence-in-depth
status sweep.

## Monitoring Requirements
### Integrity
- **Hook sha256**: `cwf-manage validate` must stay green — it checks
  `stop-stale-status-detector` against `script-hashes.json`. Any future edit to the hook
  requires an in-commit hash refresh (see `.cwf/docs/conventions/hash-updates.md`).
- **Recorded permissions**: the hook is recorded 0500 (a ceiling). After any edit, chmod
  back to 0500 — a bumped 0700 now fails validate.

### Behaviour
- **Terminal-status stamping**: each phase checkpoint should leave its wf file at a
  canonical terminal status (`Finished`/`Skipped`/`Cancelled`). The retrospective
  Step-7 sweep (kept as belt-and-braces) is the visible health check: a clean sweep =
  phases stamped correctly.
- **Hook signal quality**: `is_flaggable` flags `Backlog` and any non-canonical status.
  Watch for false positives on legitimate in-flight files — `In Progress` and `Testing`
  are valid and must stay unflagged.

### Alerting
- No automated alerting (offline dev tool). Operator-visible signals only: the Stop-hook
  system message and a non-zero `cwf-manage validate` exit.

## Maintenance Tasks
### On every future hook/template edit
- Refresh the hook sha256 in the same commit; restore 0500 perms; run `validate`.
- If a new status token is ever added to the enum, update `CWF::TaskState` (single
  source of truth) — the hook and `t/status-terminality.t` reuse it, so no second edit
  is needed in the flagging path.

### Periodic
- **Template hygiene**: `t/status-terminality.t` Part 1 already asserts every pool
  template's status-context tokens are canonical — it fails CI the moment a new
  non-canonical hint (like the deleted `Implemented`) is reintroduced. No manual sweep
  needed; the guard is the maintenance.
- **Dead-code audit**: none introduced (reuse-only change), but the standard sweep
  (`.cwf/docs/dead-code-audit.md`) still applies repo-wide.

## Incident Response
### Common Issues
- **Hook fires on a valid in-flight file**: symptom — Stop message names a file that is
  legitimately `In Progress`/`Testing`. Diagnosis — check `status_is_valid` against the
  canonical enum in `CWF::TaskState`. Resolution — if the token is genuinely canonical,
  the enum is the bug, not the hook; fix the enum + `t/status-terminality.t`.
- **`validate` fails after a hook edit**: symptom — sha256 mismatch. Diagnosis — hash
  not refreshed in-commit, or perms bumped above 0500. Resolution — refresh sha256 /
  `cwf-manage fix-security` for perms; never smooth a genuine tampering signal.
- **Retrospective commit blocked**: symptom — the `&&`-chained `j` stamp aborts the
  commit. Diagnosis — `cwf-set-status` exited non-zero (missing/invalid target). This is
  the fail-closed design working; fix the target file's Status field, then re-run.

### Escalation
- N/A (single-maintainer offline tool). Follow-up work goes to BACKLOG.

## Documentation
- Operator-facing behaviour documented in `.cwf/docs/skills/retrospective-extras.md`
  (the chained-stamp precondition and sweep-as-backstop rationale).
- Convention references: `hash-updates.md` (in-commit refresh, perms ceiling),
  `workflow-steps.md#status-values` (the canonical enum).

## Success Criteria
- [x] Maintenance surface scoped to the real concerns (integrity, flagging, sweep)
- [x] Common issues documented with diagnosis + resolution
- [x] No new monitoring infrastructure required (offline tool) — stated, not invented
- [x] Next steps suggested (retrospective)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance plan documented. No ongoing operational burden beyond the existing
`cwf-manage validate` integrity gate and the CI test guard (`t/status-terminality.t`),
both of which are automated. The retrospective status sweep is retained deliberately as
defence-in-depth per the task constraint.

## Lessons Learned
The maintenance burden is near-zero by design: the CI guard (`t/status-terminality.t`)
and the `validate` integrity gate are both automated, so the leak cannot silently return
without a red test — maintenance is best when the guards are the maintenance.
