# Seed exclude-path defaults, raise review cap 1000 - Retrospective
**Task**: 221 (feature)

## Task Reference
- **Task ID**: internal-221
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/221-seed-exclude-path-defaults-raise-review-cap-1000
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-08

## Executive Summary
- **Duration**: single working session across all ten phases (estimated: Low complexity).
- **Scope**: unchanged from plan — seed a generic `security.review.max-lines-exclude-paths`
  default into the config template + raise the built-in cap 500→1000. No additions,
  no descopes. Delivers backlog item **R1** plus the user-requested cap bump.
- **Outcome**: Success. All five success criteria met; 979 tests pass; `cwf-manage
  validate` OK; 7 reviewer runs across f/g with one best-practice finding raised and
  resolved in-phase.

## Variance Analysis
### Time and Effort
- **Estimated**: Low complexity — "one config seed + one constant" (a-task-plan
  decomposition check: 0/5 signals).
- **Actual**: matched the estimate. No new runtime code (reused Task 218's
  `max_lines_exclude_paths()` git engine), so the effort was almost entirely in
  test coverage and the three-way `500`-literal triage, not implementation.
- **Variance**: none material.

### Scope Changes
- **Additions**: none beyond plan. The three Open Decisions (a-task-plan) resolved as
  anticipated — template seeding surface (D-decisions), conservative glob set, and
  dog-fooding this repo's own config by dropping its now-redundant explicit
  `max-lines: 1000`.
- **Removals**: none.
- **Impact**: none.

### Quality Metrics
- **Test Coverage**: AC1–AC9 each covered by ≥1 named test case; new
  TC-SEED-VALID/EXCLUDE/DOC/GUARDRAIL + TC-CAPBOUNDARY + re-baselined TC-DEFAULTCAP.
  Full suite: 75 files, 979 tests, 0 failures.
- **Defect Rate**: one defect, caught in review, fixed before merge — TC-SEED-GUARDRAIL's
  git pipe `close` was unchecked, which would have let a non-zero git exit read as zero
  hits → a **false-PASS** on the FR3 security guardrail. Zero escaped defects.
- **Performance**: pathspec pass-through + one integer compare; no measurable cost.

## What Went Well
- **Mechanism reuse paid off exactly as R1 predicted**: Task 218 already shipped the
  exclude engine and the resolved-cap precedence, so this task added *no* new runtime
  code — just a seed block, a constant, and tests. The Improvements reviewer confirmed
  it (no findings).
- **The `500`-literal triage held under pressure**: 32 mentions in one test file, split
  change/keep/string-only exactly as planned. TC-CONFIGCAP4 (explicit-flag test),
  TC-DOCS (negative guard), and the `[500]` ref-type literal were correctly *kept*; a
  blanket sweep would have broken all three.
- **Adversarial review earned its keep**: the best-practice reviewer found a genuine
  false-PASS in the *security guardrail test itself* — the highest-value place to catch
  a defect. Fixed in-phase; testing-exec reviewers then confirmed the fix in-diff.
- **Fail-open tradeoffs surfaced, never smoothed**: both the cap loosening and the
  markdown discount are documented in the template note, the spec, and the rollout
  disclosure — consistent with the standing "surface, never smooth" principle.

## What Could Be Improved
- **Two hand-synced literals remain a standing drift risk**: `$DEFAULT_MAX_LINES` is the
  one live constant, but the banner, a comment, and two prose mentions had to be synced
  by hand. The boundary tests catch the *constant* drifting, not the prose. Mitigated by
  rewording the self-note to drop its hardcoded number, but the banner/comment/doc copies
  are still manual (documented in i-maintenance as a re-sync rule).
- **Seed reach asymmetry is a UX sharp edge**: the cap bump reaches every updating
  install; the seeded excludes reach new inits only. Correct (never rewrite a user's
  security config), but a maintainer could misremember it. Called out in rollout +
  maintenance, but there's no tooling that surfaces "you're on an old exclude set."

## Key Learnings
### Technical Insights
- Discounting markdown from the cap is the *safe* direction precisely because the cap
  gates review **invocation**, not content — a large adversarial-markdown changeset
  stays under the cap and is therefore still fully auto-reviewed. The instinct to "count
  prose so it doesn't escape" is backwards here.
- Loading the seeded globs from the shipped template (`seeded_exclude_globs()`) rather
  than hardcoding them in the test guards against template/test drift — a small pattern
  worth reaching for whenever a test asserts something the shipped artefact also states.

### Process Learnings
- When a change touches a security guardrail *test*, treat the test with the same
  scrutiny as production security code — a false-PASS there is worse than a normal test
  bug because it silently disarms the guarantee. The reviewer's catch validated running
  the full five-lens exec MAP even on a "Low complexity" task.

### Risk Mitigation Strategies
- The a-task-plan's top risk ("over-broad excludes weaken the cap") was mitigated exactly
  as planned: conservative glob set + a re-runnable live-tree guardrail (TC-SEED-GUARDRAIL)
  that keeps proving no seeded glob discounts a `.cwf/{scripts,hooks,security,docs}` or
  `cwf-project.json` path as the repo grows.

## Recommendations
### Process Improvements
- Keep running the full exec review MAP on low-complexity tasks. The one defect this task
  produced was in a "trivial" test helper and was caught only because the MAP ran.

### Tool and Technique Recommendations
- Prefer deriving test expectations from the shipped artefact over hardcoding — done here
  via `seeded_exclude_globs()`; worth standardising for template-vs-test assertions.

### Future Work
- No follow-up task required. A possible future nicety (not raised to the backlog): a
  lint that flags the hand-synced cap literals if they diverge from `$DEFAULT_MAX_LINES`,
  removing the last manual drift point. Low value for now — the maintenance re-sync rule
  covers it.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-07-08
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md` … `e-testing-plan.md` (this task directory)
- Execution: `f-implementation-exec.md`, `g-testing-exec.md`
- Rollout/maintenance: `h-rollout.md`, `i-maintenance.md`
- Baseline commit: `aa0573d`; exec commits `4efdf55` (f), `aae2c86` (g);
  rollout `17edd3d` (h), maintenance `e3dd55b` (i)
