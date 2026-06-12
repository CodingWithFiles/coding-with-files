# Reconcile cwf-project.json with validator schema - Retrospective
**Task**: 196 (chore)

## Task Reference
- **Task ID**: internal-196
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/196-reconcile-cwf-project-json-with-validator-schema
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-12

## Executive Summary
- **Duration**: ~0.5 day actual, against a ~0.5 day estimate (variance ≈ 0%).
- **Scope**: Delivered exactly the planned three-artefact change — template rewrite, `cwf-init` step-2 prose sync, guard-test extension — with the live config and version-field retirement held strictly out of scope as planned.
- **Outcome**: Success. A fresh `/cwf-init` now produces a `cwf-project.json` whose *shape* matches `CWF-PROJECT-SPEC.md` and the dog-fooded live config, not just one that happens to validate. All five success criteria met; full suite green (63 files / 759 tests).

## Variance Analysis
### Time and Effort
This is a chore: only phases a, d, e, f, g, j apply (no requirements/design/rollout/maintenance).
- **Estimated**: ~0.5 day total, dominated by the mechanical template rewrite; the two shape decisions (omit optional blocks, adopt `task-tracking`) were settled with the user at plan time.
- **Actual**: ~0.5 day. No phase overran. The single unplanned detour (a pre-existing permission drift surfacing as two test failures) was diagnosed and cleared inside the implementation phase without moving the estimate.
- **Variance**: Negligible. The settled-at-plan-time decisions removed the usual mid-implementation deliberation that inflates "Low" chores.

### Scope Changes
- **Additions**: None to the deliverable. One follow-up *candidate* was identified during the f-phase verification sweep (stale `.cwf/utils/*.md` spec docs describing the pre-Task-189 shape) and logged, not actioned.
- **Removals**: None. The Scope Fence held — live config, `cwf-version`/`security.version-tracking` retirement, and install migration all stayed out, as planned.
- **Impact**: None on timeline or quality. Holding the fence avoided overlap with the sibling "Prune vestigial blocks" backlog item.

### Quality Metrics
- **Test Coverage**: Every key-shape claim in the d-plan success criteria has a mechanical assertion — validator-clean (TC-3), six vestigial keys absent (TC-4), two documented names present + corrected placeholder (TC-5). 13 focused assertions, all PASS.
- **Defect Rate**: Zero defects in the changeset. The two transient full-suite failures were proven pre-existing and unrelated via a stash-test, not regressions.
- **Security**: Both exec-phase reviews returned `no findings`; the retained `sandbox` block keeps fail-closed defaults verbatim.

## What Went Well
- **Settling the two shape decisions at plan time** (omit `versioning`/`wf_step_config`; adopt the documented `task-tracking` shape) meant implementation was genuinely mechanical — no rework, no mid-flight user round-trips.
- **The pre-deletion reference sweep paid off.** Grepping every removed/renamed key across `.cwf`, `.claude`, and `docs` before deleting confirmed no first-run code path read the vestigial keys, and surfaced the inert `.cwf/utils/*.md` docs as a clean, scoped follow-up rather than a surprise.
- **Stash-testing isolated the transient failures fast.** Re-running the suite without the changeset proved the two failures pre-existed, preventing a false regression hunt against this task's diff.
- **Fix-on-sight on the permission drift.** The drift on `cwf-claude-settings-merge` (0700 vs recorded 0500, sha256 intact) was clamped immediately via `cwf-manage fix-security` rather than deferred, restoring a green suite in the same phase.

## What Could Be Improved
- **The transient drift cost diagnosis time that a clean working tree would have saved.** The drift was ambient (not introduced by this task), but it landed mid-implementation and briefly masqueraded as a regression. A `cwf-manage validate` at the *start* of the implementation phase — before the first full `prove t/` — would have surfaced and cleared it up front.
- **Stale spec docs went unnoticed until a deliberate sweep.** The `.cwf/utils/*.md` files have been out of step with the config shape since Task 189; only an explicit reference sweep found them. They are inert, so impact is low, but the lag shows doc drift isn't caught by any gate.

## Key Learnings
### Technical Insights
- **"Validates" and "matches the documented shape" are independent properties.** A template-derived config already passed `cwf-manage validate` because the validator ignores unknown keys; the real defect was that the *shape* misled fresh users about what CWF reads. Schema conformance tests must assert presence/absence of specific keys, not just zero violations — TC-4/TC-5 exist precisely because TC-3 alone would have passed against the old, wrong shape.
- **`validate_config_hash` returns a list of violation hashrefs** (`Config.pm:134`), so `my @violations = …` + `scalar @violations` is the correct call form for a count assertion. Confirmed against the contract before relying on it.

### Process Learnings
- **A symbol-deletion reference sweep belongs in any "remove vestigial keys" chore**, and its by-product (finding adjacent stale references) is as valuable as its primary safety check.
- **Run `cwf-manage validate` before the first full-suite run** in a phase, so ambient permission/integrity drift is attributed correctly instead of being mistaken for a regression in the current diff.

### Risk Mitigation Strategies
- The plan's "a helper silently reads a vestigial key" Low risk was retired by the reference sweep — the mitigation was cheap and conclusive.
- The "edited artefact is hash-tracked" Low risk resolved to no-op: neither the template nor `cwf-init/SKILL.md` is in `script-hashes.json`, so no sha256 refresh applied. Confirming hash-tracking status at d-plan time (not at commit time) kept the commit honest.

## Recommendations
### Process Improvements
- Add a `cwf-manage validate` checkpoint at the top of the implementation phase for any task that will run the full suite, so ambient drift is cleared (or at least attributed) before test results are interpreted.
- For schema/shape reconciliation work, make presence/absence assertions mandatory alongside validator-clean assertions — "it validates" is not evidence the shape is right.

### Tool and Technique Recommendations
- The reference-sweep-before-deletion technique is worth standardising for any vestigial-removal chore; record its results in the implementation plan.

### Future Work
- **Reconcile or retire the stale `.cwf/utils/{config-loader,template-engine,task-validator}.md` spec docs** against `CWF-PROJECT-SPEC.md` (they describe `project.name`, `source-management.type/url`, `task-management.type/url`, `branch-name-max-length` — the pre-Task-189 shape). Inert today; sibling to the existing "Prune vestigial blocks from the live config" item.
- The pre-existing sibling items remain open: prune vestigial blocks from the *live* config, and retire the remaining live `cwf-version` / `security.version-tracking` fields.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-12
**Sign-off**: The maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`
- Implementation: `d-implementation-plan.md`, `f-implementation-exec.md`
- Testing: `e-testing-plan.md`, `g-testing-exec.md`
- Commits: `a9d1cdb` (implementation), `a5dac88` (testing-exec checkpoint)
- Guard test: `t/cwf-project-template.t` — 13 assertions, all PASS
