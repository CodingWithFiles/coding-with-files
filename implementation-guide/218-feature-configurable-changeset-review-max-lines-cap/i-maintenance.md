# Configurable changeset-review max-lines cap - Maintenance
**Task**: 218 (feature)

## Task Reference
- **Task ID**: internal-218
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/218-configurable-changeset-review-max-lines-cap
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for the
`security.review.max-lines` config knob.

No running service — the deliverables are one hash-tracked helper edit
(`security-review-changeset`), a new opt-in config key, and doc/test updates.
"Maintenance" is integrity, drift, and keeping the resolver's fail-safe posture
intact.

## Monitoring (integrity, not telemetry)
- `cwf-manage validate` is the health check: it re-verifies the refreshed
  `security-review-changeset` sha256 against the on-disk file. A failure surfaces as
  a tampering or permission-drift signal — **surface, never smooth** (do not
  auto-recompute).
- Behavioural coverage is the test gate: `t/security-review-changeset.t`
  (TC-CONFIGCAP1..10 for the precedence matrix and every invalid-config class, plus
  the pre-existing TC-CAP/TC-DEFAULTCAP suite). CI / `prove t/` is the regression
  watch.
- The observable runtime signal is the review-run line count: a project that sets
  `security.review.max-lines` should see its effective cap change (exit 2 boundary
  moves) with no `warning:` line on stderr. A `warning:` naming the key means the
  configured value is malformed and the helper has degraded to 500.

## Maintenance tasks
- **On any edit to `security-review-changeset`**: refresh its sha256 in
  `script-hashes.json` in the **same commit** (hash-updates convention); restore
  working perms to the recorded `0500`, not a bumped mode.
- **Keep the default single-sourced**: the built-in 500 lives in one constant
  (`$DEFAULT_MAX_LINES`) consumed by the resolver and interpolated into the POD.
  The plain-`#` header banner cannot interpolate and repeats `500` literally — if
  the default ever changes, update the banner by hand in the same edit.
- **Preserve the CLI-fatal / config-degrade asymmetry**: an invalid `--max-lines`
  CLI value must stay fatal (exit 1); a malformed config value must warn (key name
  only) and degrade to 500. TC-CONFIGCAP5 and TC-CONFIGCAP10 pin both halves.

## Common issues
- **A raised cap is silently ignored** → the config value is malformed (non-integer,
  boolean, array, zero, negative, leading-zero); the helper warns naming the key and
  falls back to 500. Fix the value to a bare positive integer. Missing key / JSON
  null degrade silently by design.
- **`validate` flags the helper after an edit** → sha256 not refreshed in the edit
  commit, or perms bumped above `0500`. Fix: refresh hash + `chmod 0500` in the same
  commit; `cwf-manage fix-security` clamps perms only when sha256 already matches and
  only strips excess bits (it never raises to a recorded floor).
- **A configured value leaks into output** → must not; the warning names the key
  only. If an offending value ever appears on stderr, check the warn string was not
  widened to interpolate `$v`.

## Known follow-up
- None. The key is deliberately read only from the in-repo, reviewed
  `cwf-project.json`. If a future task adds an out-of-tree source (env override,
  user-global config), the self-referential trust boundary flagged in b-requirements
  NFR4 / c-design D3 must be re-audited before merging.

## Success Criteria
- [x] Integrity check defined (`cwf-manage validate`) and passing
- [x] Regression gate defined (`t/security-review-changeset.t`, full suite)
- [x] Common issues + resolutions documented
- [x] Fail-safe / asymmetry invariants documented for future editors

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
No maintenance actions required at rollout. Integrity and regression gates green.

## Lessons Learned
The default 500 is single-sourced in code but the `#` header banner cannot
interpolate — a dual-write point to remember if the default ever moves.
