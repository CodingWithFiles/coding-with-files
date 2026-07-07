# opt-in tool-check hook seed and toggle - Maintenance
**Task**: 220 (feature)

## Task Reference
- **Task ID**: internal-220
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/220-opt-in-tool-check-hook-seed-and-toggle
- **Template Version**: 2.1

## Goal
Ongoing maintenance for the opt-in tool-check enablement surface (kill-switch, seed
helper, config/init opt-in). CWF is a docs/tooling system with no runtime service, so
this is a runbook, not a monitoring/SLA plan.

## Monitoring Requirements
No runtime service, uptime, or resource metrics apply. Health is verified structurally:
- `cwf-manage validate` must stay OK for any install after `cwf-manage update` — the
  hashes for `CWF::ToolCheck`, the hook, and the `tool-check-seed` helper are recorded.
- `prove t/tool-check.t t/pretooluse-bash-tool-check.t t/tool-check-seed.t` (39
  subtests) is the regression gate for any future change to this surface; run it plus
  the full `prove t/` before releasing edits to these files.

## Maintenance Tasks
- **On any edit to the three hashed files**: refresh the matching `sha256` in
  `.cwf/security/script-hashes.json` in the *same commit* (per `hash-updates.md`); a
  deferred refresh fails `validate`.
- **Starter-set drift**: if a starter rule id in `tool-check-seed`'s `starter_rules()`
  changes, note that re-seed is add-by-id — a renamed id lands as a *new* rule and the
  old one is left in place. Migrating an id is a manual edit, not a re-seed.
- **Dead-code audit**: include the three new files in periodic sweeps
  (`.cwf/docs/dead-code-audit.md`).

## Incident Response
### Common Issues
- **Hook denies a legitimate command**: a seeded regex is too broad. Diagnose with
  `pretooluse-bash-tool-check --check` (shows effective active + matched rule id).
  Resolve by narrowing/removing the rule in `.cwf/tool-check/bash/settings.json`, or
  override locally in the gitignored `settings.local.json`; re-run
  `prove t/tool-check-seed.t`.
- **Hook does nothing after seeding**: check `active`. Project-local `active:false`
  (from a prior `/cwf-config tool-check off`) wins over user-global; `seed` clears it
  (F3 ordering), or run `/cwf-config tool-check on`. A checked-in `active` is
  *ignored by design* (clone-suppression closed) — do not rely on it to disable.
- **`validate` fails after `update`**: sha256 or permission drift on one of the three
  files. Permission drift → `cwf-manage fix-security` (fix-on-sight). sha256 drift →
  surface it, never smooth it; investigate the content change before refreshing.

### Troubleshooting Guide
- **Symptom**: unexpected allow/deny. **Diagnosis**: `--check` output — "Effective
  active" line and per-layer `active=<v>` with `(active ignored)` on the checked-in
  layer. **Resolution**: adjust the winning trusted layer (project-local >
  user-global) or the offending rule; re-run the targeted `prove`.

## Documentation
- **Runbook**: `.cwf/docs/tool-check-rules.md` — `active` flag precedence, boolean-only
  coercion, checked-in-ignored rationale, gitignore-as-security-control, F2 degradation.
- **Enable/disable**: `/cwf-config tool-check seed|on|off`; `/cwf-init` opt-in
  (default decline).

## Success Criteria
- [x] Structural health checks documented (validate + targeted prove)
- [x] Maintenance rules for the three hashed files documented (same-commit hash refresh)
- [x] Common issues documented with concrete `--check`-based diagnosis + resolution
- [x] Next steps suggested

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
No maintenance incidents — feature not yet adopted in this repo (mechanism only).
Runbook entries derived from the failure modes exercised by the g-phase tests
(false-positive deny, active precedence, validate drift).

## Lessons Learned
The most useful runbook entries fall straight out of the tested failure modes
(false-positive deny, active precedence, validate drift) — `--check` is the single
diagnostic that resolves all three.
