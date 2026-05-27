# Template Reference Linter for Pre-Commit Hook - Retrospective
**Task**: 165 (chore)

## Task Reference
- **Task ID**: internal-165
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/165-template-reference-linter-for-pre-commit-hook
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-27

## Executive Summary
- **Duration**: single session (estimated 0.5–1 day, Medium complexity). On estimate.
- **Scope**: Delivered the linter as a `CWF::Validate::TemplateRefs` sibling wired into `cwf-manage validate`, not a standalone `.cwf/scripts/` helper (backlog wording). Check semantics deliberately narrowed from the backlog's "flag v2.0 names in v2.1 context" to "flag names known to no version".
- **Outcome**: Success. Catches genuine orphaned/typo template references at near-zero false-positive cost; surfaced and fixed 3 real stale references on its first run.

## Variance Analysis
### Time and Effort
- **Estimated**: 0.5–1 day total (chore: a, d, e, f, g, j).
- **Actual**: single session, within estimate. Planning/design folded into the d-plan (chore has no separate design phase); most thinking went into the investigation that reshaped the approach.
- **Variance**: ~0. The investigation cost was front-loaded into planning rather than appearing as exec overrun.

### Scope Changes
- **Narrowed (D1)**: The backlog's "distinguish v2.0 refs in v2.1 context" goal proved infeasible — current skills/lib legitimately reference old names for backward-compat, so the same token is both a valid mention and a potential orphan. Replaced with the reliable invariant "every template-shaped reference names a real template in some version".
- **Re-homed (D5)**: From "add a script to `.cwf/scripts/`" to a `CWF::Validate::*` lib module + thin `t/` test wired into `cwf-manage validate` — matching the 6 existing sibling validators and reusing the gate `cwf-checkpoint-commit` already runs.
- **Added**: Excluded `BACKLOG.md`/`CHANGELOG.md` from scope (cross-doc-references exemption) — added during plan review. Fixed 3 surfaced stale references (`V21.pm` POD, `workflow-steps.md` ×2) to reach a clean baseline.
- **Impact**: No timeline impact; the narrowing reduced complexity and false-positive risk.

### Quality Metrics
- **Test Coverage**: TC-1…TC-7 + implementation-guide exclusion + fail-closed minimum — 10 subtests, all pass. Full suite 610 tests pass.
- **Defect Rate**: Zero defects post-implementation. The linter itself surfaced 3 genuine pre-existing doc bugs (now fixed).
- **Security**: Both exec-phase reviews returned `no findings`.

## What Went Well
- **Grounding before designing.** The investigation (37 referencing files, anchored-vs-naive grammar, back-compat reality) turned a vaguely-specified backlog item into a precise, defensible design, and exposed that the backlog's original goal was infeasible.
- **Plan review earned its keep.** Reviewers independently caught (a) the `BACKLOG.md`/`CHANGELOG.md` false positives (12 baseline hits vs the 4 real ones), citing the existing cross-doc-references exemption, and (b) two correctness bugs in the illustrative snippet (`workflow_file_mappings()` arrayref deref; `glob` directory-prefix). All fixed before exec — zero exec rework on those.
- **Dogfooding paid off immediately.** First real-repo run found genuine inaccuracies in `V21.pm` POD and `workflow-steps.md` (v2.0 testing mislabelled `f-testing-plan.md`; it was `e-testing.md`).
- **Convention reuse over new code.** Adopting the `CWF::Validate::*` sibling contract avoided bespoke scaffolding and gave a ready-made enforcement point.

## What Could Be Improved
- **Initial draft under-scoped the baseline.** My first plan claimed only 2 baseline hits; the real count (with naive scope) was 12. Running the proposed algorithm against HEAD *before* writing the plan would have caught this without relying on review.
- **The self-scan trap is subtle.** Because the module scans `.pm` files, its own comments can trip it (a bare `e-extras.md` in prose would match). Required care; worth a one-line caution for anyone extending the grammar or scope.

## Key Learnings
### Technical Insights
- **The same token is both a valid back-compat mention and a potential orphan** — version-context enforcement is undecidable for a linter here; the "known to any version" invariant is the strongest reliably-checkable one.
- **Authoritative name sets are derivable, not guessable** — pool + `V21`/`V20::get_workflow_files` + `workflow_file_mappings()` give the full union at runtime; no hardcoded lists.
- **Boundary anchoring is load-bearing** — a left look-behind (`(?<![A-Za-z0-9-])`) is what separates real references from substrings of longer hyphenated filenames.
- **`cwf-manage fix-security` repairs permissions only, never hashes** — a sha256 edit is a deliberate, reviewed JSON change (surface, don't smooth); there is intentionally no recompute tool.

### Process Learnings
- **Run the proposed check against HEAD during planning**, not just at exec — it both validates feasibility and sizes the baseline-fix work accurately.
- **A new `CWF::Validate::*` module registers in two places only** (`script-hashes.json` entry + `cwf-manage` use/list); lib modules are copied wholesale on install, so no `install-manifest.json` edit is needed.

### Risk Mitigation Strategies
- **Fail-closed gate**: the `die`-on-under-populated-KNOWN guard converts a derivation regression into a loud failure rather than a silent pass-everything — the right posture for an enforcement check.
- **`.t` files out of scope** keeps test fixtures (which contain deliberate orphan tokens) from self-tripping the real-repo integration assertion.

## Recommendations
### Process Improvements
- Add "execute the proposed check/algorithm against HEAD" to chore/linter planning checklists — feasibility + baseline sizing in one step.

### Tool and Technique Recommendations
- The `CWF::Validate::*` sibling + thin `t/` pattern is the right home for any future source-consistency check; prefer it over standalone scripts.

### Future Work
- None filed. A standalone CLI or wider file-type coverage (`.t`, etc.) was considered and deliberately deferred (no current need; rule of three). Revisit only if a manual-run or coverage gap is reported.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-27
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Links to planning documents and artefacts
- Links to implementation PRs and commits
- Links to test results and quality reports
- Links to deployment and monitoring dashboards
