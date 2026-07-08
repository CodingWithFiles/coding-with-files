# Seed exclude-path defaults, raise review cap 1000 - Maintenance
**Task**: 221 (feature)

## Task Reference
- **Task ID**: internal-221
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/221-seed-exclude-path-defaults-raise-review-cap-1000
- **Template Version**: 2.1

## Goal
Ongoing maintenance for the seeded `security.review.max-lines-exclude-paths` template
default and the built-in cap (now 1000). No service, no telemetry — maintenance here
means keeping the hand-synced literals, the FR3 guardrail, and the seeded glob set
correct as the codebase and CWF users' ecosystems evolve.

## Monitoring Requirements
File-based system; nothing runs continuously. The standing signals are:
- **Integrity**: `cwf-manage validate` → OK. The `security-review-changeset` helper is
  hash-tracked; any future edit must refresh its sha256 in the same commit, or
  `validate` trips (by design — surface, never smooth).
- **Regression**: `prove -l t/` green, in particular the cap and seed cases below.
- **Guardrail (FR3)**: `TC-SEED-GUARDRAIL` re-runs against the **live** tree, so it
  keeps proving no seeded glob discounts a `.cwf/{scripts,hooks,security,docs}` or
  `cwf-project.json` path as the repo grows. Failure = a seeded glob is over-broad.

## Maintenance Tasks
### The two hand-synced literals (highest-churn risk)
- **`$DEFAULT_MAX_LINES = 1000`** (`security-review-changeset:101`) is the single live
  constant. Three human-readable literals were synced to it: the banner (`:32`),
  the `(default 1000)` comment (`:316`), and the two prose mentions in
  `security-review.md`. The self-note at `:100` was deliberately reworded to drop its
  hardcoded number so it can never drift again.
- **Rule**: if the default ever changes again, grep the helper and `security-review.md`
  for the old number and re-sync all human-readable copies in the same task. There is
  no build step that enforces this — `TC-DEFAULTCAP` / `TC-CAPBOUNDARY` catch the
  *constant* drifting, not the prose.

### Seeded glob set (`cwf-project.json.template`)
- 18 generic globs + `*.md` / `docs/**/*.md`, chosen to be cross-ecosystem. Adding a
  new common test/generated/vendored layout is a config-only change to the template.
- Any new seeded glob MUST pass through `TC-SEED-VALID` (valid pathspec via git's real
  engine) and MUST NOT breach `TC-SEED-GUARDRAIL` (no security-sensitive discount).
- The reach asymmetry is permanent and intentional: template edits only affect **new**
  `cwf-init` runs; existing installs opt in by hand. Do not add config-rewriting to
  "propagate" seed changes — that would silently mutate a user's security config.

### Preventive Maintenance
- Dead-code audit (see `.cwf/docs/dead-code-audit.md`) — no new runtime code was added
  (reuses Task 218's `max_lines_exclude_paths()` engine), so nothing new to sweep here.

## Incident Response
### Common Issues
- **`cwf-manage validate` reports a hash mismatch on `security-review-changeset`**:
  the helper was edited without a same-commit hash refresh. Fix: refresh the sha256 in
  `.cwf/security/script-hashes.json` in the same commit as the edit (per
  `hash-updates.md`); never silence the check.
- **A long-baseline changeset unexpectedly trips exit 2 (cap exceeded)** even after the
  bump: the install pins its own `security.review.max-lines` below 1000, or has real
  production churn > 1000 lines. Diagnosis: the helper prints the effective cap and the
  breaching count. Resolution: raise/clear the pin, or split the changeset — the exit 2
  is the intended "too big to review in one pass" signal, not a bug.
- **A seeded exclude appears to hide a sensitive path**: run `TC-SEED-GUARDRAIL`; if it
  fails, the glob is over-broad. Tighten or remove it and add the offending path to the
  guardrail's live-tree assertion.

### Troubleshooting Guide
- **Symptom**: a markdown-heavy changeset is under the cap and a maintainer worries it
  "escaped" review. **Diagnosis**: the cap gates *invocation*, not content — excluded
  paths are still emitted in full to the reviewer. **Resolution**: confirm the review
  subagent ran; if prose volume should count, drop `*.md` / `docs/**/*.md` from the
  install's config (documented in `_security-review-note`).

## Documentation
- `_security-review-note` in the template is the user-facing runbook for the seed
  (what's discounted, why, how to change it).
- `CWF-PROJECT-SPEC.md` records that the exclude default ships seeded and `max-lines`
  is a helper default (not a template key).
- `security-review.md` documents the built-in default (1000) and degrade behaviour.

## Success Criteria
- [x] Standing integrity/regression/guardrail signals identified
- [x] Hand-synced-literal drift risk documented with the re-sync rule
- [x] Seeded-glob maintenance rules documented (validity + guardrail gates)
- [x] Common issues documented with resolutions
- [x] Next steps suggested

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance plan documented. No follow-up tasks required — the change reuses existing
runtime code and adds no new operational surface. The only recurring obligations are
the standing CWF ones (same-commit hash refresh on any future helper edit; keep the
hand-synced literals in step with the constant).

## Lessons Learned
*To be captured during retrospective*
