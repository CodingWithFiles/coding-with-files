# Always review docs regardless of line cap - Maintenance
**Task**: 223 (feature)

## Task Reference
- **Task ID**: internal-223
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/223-always-review-docs-regardless-of-line-cap
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for Always review docs regardless of line cap.

CWF has no runtime service to monitor — maintenance here is the ongoing-signal
surface of the new behaviour and the follow-ups it leaves. SaaS ops scaffolding
(uptime SLAs, alerting tiers, scaling, DR) removed as not-applicable.

## Ongoing signals
- **`cwf-manage validate`** remains the health check: a helper sha256/permission
  regression surfaces here. Run it after any edit to `security-review-changeset`.
- **Cap-value calibration is observational** (FR3/AC3b decision): real-world
  over-cap frequency across CWF-using projects — not a synthetic study — informs
  whether the `1000` default moves. No dashboard; the signal is lived usage. A repo
  finding the default wrong tunes `security.review.max-lines` locally first.

## Common issues (troubleshooting the new behaviour)
- **Task-doc markdown unexpectedly counts toward the cap.** Diagnosis: run the
  helper with `--verbose`; check `directory-structure.base-path` in
  `cwf-project.json`. A malformed/adversarial value fails safe toward *counting* and
  emits a one-line `directory-structure.base-path '<v>' … ` diagnostic on stderr.
  Resolution: set base-path to a clean relative dir (no `..`, no trailing `/`, not
  `.cwf`).
- **Over-cap breach but no docs reviewed.** Expected when base-path is unconfigured
  (the `wrote <D> doc lines` line is absent → the skill records "docs not
  separable"). Resolution: configure `directory-structure.base-path`.
- **Code slips under the cap by living in the doc tree.** Cannot happen — the
  discount is markdown-only (`<base-path>/**/*.md`); a `.pl`/`.js` under the doc tree
  still counts (TC-223-2 guards this). If observed, treat as a regression and revert.

## Follow-ups (tracked in BACKLOG)
- **template-copier snake_case `base_path`** (bugfix, Low): `template-copier-v2.1:194`
  reads the wrong key and silently defaults; unrelated to the cap path but will bite
  any feature that relies on a custom base-path through the copier.
- **Shared cached config read** (chore, Very Low): three `read_config()` sites in the
  helper; consolidate when next touching it.
- **Dead-code audit**: periodic sweep per `.cwf/docs/dead-code-audit.md` (unchanged).

## Success Criteria
- [x] Ongoing health check identified (`cwf-manage validate`).
- [x] Troubleshooting for the new base-path/deferred behaviour documented.
- [x] Follow-ups recorded in BACKLOG rather than left implicit.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 223
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Ongoing health check (`cwf-manage validate`) and troubleshooting for the new
base-path/deferred behaviour documented; two follow-ups recorded in BACKLOG.

## Lessons Learned
No runtime service ⇒ maintenance is the signal surface (`validate`, observational
cap calibration) plus tracked follow-ups, not SLAs/alerting tiers.
