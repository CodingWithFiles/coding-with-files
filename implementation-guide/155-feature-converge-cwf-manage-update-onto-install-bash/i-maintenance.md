# Converge cwf-manage update onto install.bash - Maintenance
**Task**: 155 (feature)

## Task Reference
- **Task ID**: internal-155
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/155-converge-cwf-manage-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Define what keeps the converged updater healthy over time. CWF is a per-repo tooling system with no server, uptime, or telemetry — "maintenance" here means the integrity gates, the regression sentinel, and the documented follow-up that prevent the convergence from silently drifting.

## Monitoring Requirements
No runtime metrics exist or are added. Health is verified on demand by deterministic gates run inside the consumer's repo:
- **Integrity gate**: `cwf-manage validate` (SHA256 over `script-hashes.json` + recorded perms). The authoritative signal that an install/update laid down the expected files at the expected modes.
- **Regression sentinel**: `t/cwf-manage-update-end-to-end.t` — the only coverage that exercises a real install→update across version tags. Any future change to `cmd_update`, `install.bash`, or the shared laydown contract must keep this green.
- **No alerting pipeline**: there is nothing to page on. The sole external signal is consumer-filed issues.

## Maintenance Tasks
### Recurring obligations
- **On any edit to `cwf-manage` or `install.bash`**: re-run the full `t/` suite *and* the end-to-end harness, then refresh the `cwf-manage` sha256 in `script-hashes.json` in the same commit (per `.cwf/docs/conventions/hash-updates.md`). The convergence means a change to the shared laydown logic now affects both install and update paths — verify both.
- **On manifest-schema changes**: the end-to-end harness pins `cwf_install_manifest_sha`. A schema bump (deferred — see Knowledge Base) needs a matching harness update; treat a harness failure here as expected churn, not a regression to suppress.
- **Dead-code audit**: the deleted `update_subtree` leaves no caller; a periodic sweep (`.cwf/docs/dead-code-audit.md`) should confirm no doc or test still references it.

### Follow-up filed (not maintenance debt — scoped work)
- **Copy-method convergence** (BACKLOG, Low): the `copy` update path still uses `update_copy` + `create_*_symlinks` rather than delegating to `install.bash`. This is intentional (avoids re-implementing the `_escapes_src` symlink-escape guard in bash) but leaves two laydown implementations. Single-ownership is the eventual goal.

## Incident Response
### Common Issues
- **`cwf-manage update` fails on an install predating this fix**: expected — the updater is run by the *old* installed script. Resolution: one-time bootstrap recovery per INSTALL.md § "Recovering an install stuck on an old cwf-manage" (`CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<url> bash install.bash`). Subsequent updates use the fixed updater.
- **`validate` fails immediately after an update**: the exact-perms guard is fatal-on-mismatch by design (it does not silently repair — "surface, never smooth"). Diagnosis: incomplete laydown or a tampered file. Resolution: re-run the bootstrap installer for the target tag; do not reach for a hash-recompute tool.
- **apply-artefacts conflict on a rules-inject during update**: in a non-TTY context the merge needs `CWF_UPGRADE_RESOLVE` set; interactive resolution is the normal path. Out of scope for the automated harness (documented in e-testing-plan).

### Troubleshooting Guide
- **Symptom**: cross-version update aborts mid-laydown. **Diagnosis**: check the spawn/signal/exit branch that fired in `cmd_update` (each `die_msg`s distinctly). **Resolution**: the tree is left for inspection; re-run bootstrap recovery for a clean remove-then-add.
- **Symptom**: `CWF_REF=''` reaching install.bash. **Diagnosis**: a future caller passed a ref to `resolve_sha` not first `--verify`'d against the same clone (noted in the f-phase security review). **Resolution**: ensure ref validation precedes resolution; the current call site is safe.

## Performance Optimisation
Not applicable. The update path runs once per consumer upgrade; the end-to-end suite completes in ~5s. No hot path, no scaling dimension, no caching.

## Documentation
### Runbooks
- Recovery from a stuck old updater: INSTALL.md § "Recovering an install stuck on an old cwf-manage".
- Hash refresh discipline: `.cwf/docs/conventions/hash-updates.md`.
- Manual subtree/copy update (fallback if `cwf-manage` is unusable): INSTALL.md Methods 1–2 § Update.

### Knowledge Base
- **Design rationale**: c-design-plan.md (subtree-only convergence; why copy is retained).
- **Deferred scenarios**: copy-method convergence and manifest-schema-bump coverage (BACKLOG / e-testing-plan).
- **Decision record**: f-implementation-exec.md captures the three execution deviations and their rationale.

## Success Criteria
- [x] Integrity + regression gates identified as the standing health signal
- [x] Recurring obligations tied to edits of the shared laydown surface
- [x] Common failure modes documented with non-smoothing resolutions
- [x] Deferred follow-up recorded (copy-method convergence) — not silent debt
- [x] Runbooks/KB cross-referenced (no new docs duplicated)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 155
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance is gate-based, not metric-based: `cwf-manage validate` for integrity and `t/cwf-manage-update-end-to-end.t` as the regression sentinel for the shared laydown contract. The forward-only reach limit, the fatal exact-perms guard, and the retained copy path are the three things a future maintainer must keep in mind; each is cross-referenced rather than re-documented.

## Lessons Learned
Maintenance for this change is gate-based (`validate` + the end-to-end harness as regression sentinel), not metric-based — there is no runtime to monitor. The retained copy path is the standing item a future maintainer must keep in view, and the fatal exact-perms guard must never be softened into a silent repair. See j-retrospective.md.
