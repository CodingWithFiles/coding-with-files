# Configurable changeset-review max-lines cap - Rollout
**Task**: 218 (feature)

## Task Reference
- **Task ID**: internal-218
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/218-configurable-changeset-review-max-lines-cap
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for the configurable changeset-review
max-lines cap (`security.review.max-lines`).

## Deployment Strategy
### Release Type
- **Strategy**: Merge the task branch to `main` (human action), then the change
  reaches CWF-using projects on their next `cwf-manage update`. No runtime service,
  no phased user rollout — the artefacts are one hashed helper edit
  (`security-review-changeset`) + its refreshed `sha256`, a new opt-in config key,
  a raised cap in this repo's own `cwf-project.json`, and doc/test updates.
- **Rationale**: Standard CWF self-development flow. The new key is inert until a
  changeset review next runs; the resolver degrades to the built-in 500 when the key
  is absent, so existing consumers are unaffected until they opt in.
- **Effect on consumers**: projects gain a `security.review.max-lines` knob to raise
  (or lower) their changeset-review cap without editing the vendored helper.
  Fail-safe: a missing/null key or a malformed value resolves to the stricter 500;
  precedence is `--max-lines` (CLI, fatal on invalid) > config key > 500.

### Pre-Deployment Checklist
- [x] Changeset reviews completed (5 at f-exec, 2 at g-exec) — all no findings
- [x] All test cases pass (g-testing-exec: TC-CONFIGCAP1..10 + full suite 947 tests)
- [x] Security review: no findings across FR4(a-e); no-value-echo warning verified
- [x] `cwf-manage validate` clean (sha256 + permissions)
- [x] Docs updated (`.cwf/docs/skills/security-review.md` cap paragraph); CHANGELOG
      entry at retrospective
- [ ] Merge to `main` — **human action** (suggested command in retrospective)

## Rollout Plan
Single step: fast-forward `main` to the task tip, then tag `v1.1.218` (both human
actions). No staged percentage rollout applies to a config/helper edit.

## Rollback Plan
### Triggers
- The resolver is found to mis-parse a config value, the fail-safe degrade regresses
  to fail-open, or the hash refresh is later shown wrong.

### Procedure
1. `git revert` the task's squashed commit (or drop it before the FF if not yet
   merged) — restores the prior helper source, the `max_lines => 500` default, and
   the sha256 entry together.
2. `cwf-manage validate` to confirm the manifest matches the reverted files.
3. No consumer coordination needed — next `cwf-manage update` distributes the revert.
   A consumer that had set `security.review.max-lines` keeps the key harmlessly
   (the reverted helper ignores it).

## Success Criteria
- [x] All gates green (reviews, tests, validate)
- [ ] Merge + tag performed by the human maintainer
- [ ] No revert required

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All pre-deployment gates green. Merge + tag pending human action.

## Lessons Learned
Rollback for a hashed-helper edit is a single `git revert` — it restores the helper
source and its sha256 entry together, keeping `validate` consistent. The opt-in key
degrades safely, so a revert leaves any consumer-set key inert rather than broken.
