# Always review docs regardless of line cap - Rollout
**Task**: 223 (feature)

## Task Reference
- **Task ID**: internal-223
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/223-always-review-docs-regardless-of-line-cap
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for Always review docs regardless of line cap.

## Deployment Strategy

CWF ships as a vendored system, not a running service. Delivery is: land the task
branch on `main` (squash, human-only), tag, and downstream projects pick it up via
`.cwf/scripts/cwf-manage update`. There is no user cohort, traffic split, or live
monitoring surface — the SaaS-style phased/canary scaffolding does not apply and is
removed deliberately (brevity).

### Change footprint
- **Behavioural delta**: the security-review cap now gates code only; task-doc
  markdown under `directory-structure.base-path` is discounted always-on and, on an
  over-cap breach, reviewed on its own while code review is recorded `deferred`.
- **Surface**: 1 helper (`security-review-changeset`, hash-tracked), 2 exec skills,
  `security-review.md`, the config template note, the hash manifest, 2 test files.

### Pre-Deployment Checklist
- [x] Changeset reviews complete — f: security/best-practice/robustness/misalignment
      no findings, improvements advisory (backlogged, accepted); g: both no findings.
- [x] All tests passing — `prove t/` 1008 tests; two task suites 85 subtests.
- [x] `cwf-manage validate` clean (same-commit sha256 refresh for the helper).
- [x] Docs updated — `security-review.md` (shared deferred contract, counting basis,
      cap rationale), template `_security-review-note`.
- [x] Backward-compatibility verified (see below).

## Compatibility & Delivery

- **Old skill + new helper** (adopter updates the helper first): the new second
  confirmation line is an unknown extra stdout line an old skill ignores; exit 2 still
  reads as today's cap error. Degrades safely — no exit-code renumber.
- **New skill + old helper** (skill updated first): the old helper never prints a doc
  line, so the skill's exit-2 branch takes the "doc line ABSENT → docs not separable"
  path — no crash, code review still recorded. Degrades safely.
- **Config**: `directory-structure.base-path` already exists in every `cwf-project.json`
  (default `implementation-guide`); no migration. Absent/adversarial values fail-safe
  toward counting.
- **Delivery step (human-only)**: merge to `main`, tag, `cwf-manage update` downstream.

## Rollback Plan
### Triggers
- A repo's legitimate over-cap changeset is wrongly blocked, or task-doc markdown is
  wrongly counted/discounted, in a way config cannot correct.
- `cwf-manage validate` reports a hash/permission regression traceable to this change.

### Procedure
1. Revert the task's squash commit on `main` (single commit) and re-tag.
2. Downstream `cwf-manage update` (or `rollback`) restores the prior helper + skills.
3. No data migration to undo — the change is behavioural, config-compatible.

## Success Criteria
- [x] Change lands with reviews + tests green and validate clean.
- [x] Backward-compatibility confirmed in both update orders.
- [ ] Merge to `main` + tag (human-only — command suggested at retrospective).

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance 223
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Backward-compatibility verified in both update orders; no config migration. Delivery
is squash-to-main + downstream `cwf-manage update` — the human-only merge is pending.

## Lessons Learned
For a vendored system, "rollout" is compatibility analysis + delivery mechanics, not
phased traffic — the generic SaaS template was actively misleading and was replaced.
