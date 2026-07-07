# opt-in tool-check hook seed and toggle - Rollout
**Task**: 220 (feature)

## Task Reference
- **Task ID**: internal-220
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/220-opt-in-tool-check-hook-seed-and-toggle
- **Template Version**: 2.1

## Goal
Release the opt-in tool-check enablement surface (kill-switch, seed helper,
`/cwf-config tool-check` + `/cwf-init` opt-in) and settle the one rollout decision
this task carries: whether CWF's own repo commits a checked-in starter ruleset.

## Deployment Strategy
### Release Type
- **Strategy**: Ship-inert-until-opted-in (no phased traffic rollout). CWF is a
  documentation/tooling system installed into user repos, not a running service;
  "deployment" is a version-tagged merge to `main` (human-only) picked up by
  `cwf-manage update`.
- **Rationale**: The feature is safe-by-construction — with zero rules present the
  hook is a strict no-op, and the `active` kill-switch defaults true only *once rules
  exist*. Nothing changes behaviour for any existing install until an operator runs
  `/cwf-config tool-check seed` or accepts the `/cwf-init` opt-in. This makes the
  usual canary/percentage rollout unnecessary: the opt-in gate *is* the rollout
  control.
- **Rollback Plan**: `cwf-manage rollback` to the prior release (standard CWF
  mechanism); or, for an install that opted in, `/cwf-config tool-check off` (project
  scope) to disable without uninstalling. Both are covered under Rollback Plan below.

### Rollout Decision — does THIS repo commit a checked-in starter set?
**Decision: NO — this repo does not commit a `.cwf/tool-check/bash/settings.json`
starter set in this task.**

- This task delivers the *mechanism*; adopting it for CWF's own development is a
  separate, deliberate choice that would change every maintainer's Bash behaviour on
  the next pull. Keeping the two apart preserves the ship-inert guarantee and lets the
  adoption decision be reviewed on its own merits.
- The standalone BACKLOG entry ("Seed CWF's own bash tool-check rules") already
  records the remaining work as a rollout/adoption decision now that the mechanism
  exists; it stays in the backlog rather than riding in on this task.
- A downstream project (or CWF itself, later) enables it exactly as documented:
  `/cwf-config tool-check seed` to lay down the regex-only starter set, then commit
  the generated checked-in file.

### Pre-Deployment Checklist
- [x] Code review completed (7 reviewer passes across f/g; robustness bug fixed, all
      adopted/accepted with rationale recorded)
- [x] All tests passing — full `prove t/`: Files=75, Tests=970, Result: PASS
- [x] Security scan — `cwf-manage validate`: OK; security changeset reviewer: no findings
- [x] Performance validated — kill-switch short-circuits before compile (TC-H7); no
      extra read/stat on the hot path (NFR1)
- [x] Documentation updated — `tool-check-rules.md` (active flag, precedence,
      gitignore-as-control), `cwf-config`/`cwf-init` skills, BACKLOG corrected
- [x] Monitoring/alerting — N/A for a docs/tooling system (no runtime service)
- [x] Rollback path confirmed — `cwf-manage rollback` + `/cwf-config tool-check off`

## Rollout Plan
Not a phased-traffic release. The single gate is operator opt-in per install:

- **Ship**: merged to `main` and tagged (human-only) → available via `cwf-manage update`.
- **Adopt (per install, operator-driven)**: `/cwf-init` opt-in (default decline) or
  `/cwf-config tool-check seed`. Until then the install is unchanged.
- **This repo**: mechanism only; no checked-in starter set committed (see decision above).

## Monitoring
No runtime service to monitor. Post-release health is verified structurally:
- `cwf-manage validate` stays OK for downstream installs after `update` (hashes for the
  two edited files + new helper are recorded in this task's commit).
- Dogfooding signal: the real user-global tool-check rule already denied a stray `head`
  command during exec — the hook path is exercised in normal maintainer use.

## Rollback Plan
### Triggers
- `cwf-manage validate` failure after update (hash/permission drift)
- An opted-in install reports the hook denying legitimate commands (false positive in a
  seeded rule)
- Any regression in the Task-201 tool-check framework surfaced by `prove t/`

### Procedure
1. **Per-install disable (no uninstall)**: `/cwf-config tool-check off` — flips the
   project-local `active` switch; hook becomes a no-op immediately, no restart.
2. **Version rollback**: `cwf-manage rollback` to the prior release.
3. **Rule-level fix**: edit or remove the offending starter rule in
   `.cwf/tool-check/bash/settings.json` (or override in the gitignored
   `settings.local.json`); re-run `prove t/tool-check-seed.t`.
4. **Analysis**: capture the denied command + matched rule id for the retrospective.

## Success Criteria
- [x] Release model documented (ship-inert; opt-in gate is the rollout control)
- [x] Rollout decision settled and recorded (no checked-in starter set in this repo)
- [x] Pre-deployment checklist complete
- [x] Rollback plan documented (per-install disable + version rollback + rule fix)
- [x] Next steps suggested

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Feature is ready for a version-tagged merge to `main` (human-only). No checked-in
starter set committed for CWF's own repo; adoption remains a backlog decision now that
the mechanism exists. No rollback required; per-install disable path verified by
TC-S4/TC-S5/TC-S8.

## Lessons Learned
For a ship-inert feature the opt-in gate *is* the rollout control — no canary or
percentage rollout is needed when zero-rules is a strict no-op. Keeping "adopt for this
repo" as a separate backlog decision preserves that guarantee.
