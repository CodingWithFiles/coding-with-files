# Always review docs regardless of line cap - Retrospective
**Task**: 223 (feature)

## Task Reference
- **Task ID**: internal-223
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/223-always-review-docs-regardless-of-line-cap
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-08

## Executive Summary
- **Duration**: ~1 day (estimated: 1–2 days). Within estimate; the surface shrank
  below plan.
- **Scope**: Delivered both halves — always-review-docs on over-cap (FR2) and the
  always-on base-path markdown cap discount (FR1) — plus the folded-in backlog cap
  item (FR3). Empirical cap-calibration study deferred to real-world usage by user
  decision (FR3/AC3b).
- **Outcome**: Success. All five a-plan success criteria met; all reviews clean or
  advisory-accepted; `prove t/` 1008 green; `cwf-manage validate` OK.

## Variance Analysis
### Scope Changes
- **Surface shrank (positive variance)**: the a-plan and its risk section assumed the
  **SubagentStop verdict guard** and the **exec templates (f/g)** were `exit 2`
  consumers needing update. Design (KD, "documented non-consumers") established they
  are **not**: the guard name-matches `cwf-security-reviewer-changeset` and simply
  doesn't fire when no agent runs; the templates carry no exit-2 wording. Net change
  set: 1 helper + 2 skills + 1 doc + 1 template note + 2 test files — smaller than the
  "helper + skills + templates + guard" the plan budgeted.
- **Folded in**: backlog "Revisit the security-review line cap" (FR3) — counting basis
  (numstat edit-lines, already true) documented; cap value calibrated observationally.
- **Deferred (user decision)**: the empirical finding-rate study. Rationale: real usage
  across CWF projects is better signal than a synthetic study, and the cap is a config
  knob. Not backlogged — superseded by usage.

### Quality Metrics
- **Test coverage**: every KD5 guard branch + all three doc-line outcomes
  (present>0 / present-0 / absent); `.cwf`-never-discounted is a hard assertion.
- **Defects**: none found in testing or review. One advisory (config-read
  triplication) — pre-existing pattern, backlogged, accepted.
- **Reviews**: f-phase 5-reviewer MAP (4 no-findings, 1 advisory); g-phase 2-reviewer
  MAP (both no-findings). 211 production lines (docs + tests correctly discounted —
  the feature dog-fooding itself).

## What Went Well
- **Plan-review caught a real security hole pre-code**: the `^…$`→`\A…\z` anchor fix
  (a `$`-matches-before-trailing-newline validator hole) was surfaced in design review
  and corrected before implementation — exactly the "adapt the doc before writing code"
  thesis this task is about.
- **Dog-fooding validated the feature live**: the f/g changeset had 211 production lines
  because the task's own a–j markdown was discounted by the very base-path mechanism
  being shipped.
- **Fail-safe-toward-counting** made the adversarial base-path surface tractable: every
  ambiguity degrades to the stricter direction, so the guard is a short allowlist +
  explicit rejections rather than an exhaustive threat enumeration.

## What Could Be Improved
- The a-plan's "every exit-2 consumer" list was speculative and partly wrong (guard/
  templates). Verifying consumer membership against source *during planning* (not
  design) would have sized the task more accurately up front.
- The helper now has three `read_config()` sites; the consolidation opportunity existed
  before this task but this task added the third. Backlogged rather than fixed to keep
  scope tight — a defensible call, but the debt is now one step larger.

## Key Learnings
### Technical Insights
- **`\A…\z` vs `^…$` is a security property, not style**, when the regex validates a
  value that becomes a git pathspec: `$` admits a trailing newline. Both the design and
  impl reviewers independently flagged/confirmed it.
- **Markdown-only, never tree-scoped**: discounting `<base-path>/**/*.md` (not
  `<base-path>/**`) is what stops a base-path from becoming a whole-tree cap-bypass —
  code under the doc tree still counts (TC-223-2 guards this permanently).
- **Present-0 ≠ absent**: encoding "configured but no docs" (a `wrote 0 doc lines` line)
  distinctly from "docs not separable" (no line) let the skill avoid mislabelling real
  markdown as "no docs".

### Process Learnings
- Deferring an empirical study in favour of observational real-world data is a
  legitimate calibration strategy for a config-knob default — documented as rationale,
  not left as a silent gap.
- Reviewer disposition discipline: a `findings` verdict that is a known, backlogged
  item is `accept-and-record`, not a blocker — recorded explicitly in f-exec.

## Recommendations
### Future Work
- **template-copier snake_case `base_path`** (BACKLOG, bugfix Low): `template-copier-v2.1:194`
  reads the wrong key; will bite any feature relying on a custom base-path via the copier.
- **Shared cached config read** (BACKLOG, chore Very Low): consolidate the helper's three
  `read_config()` sites.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge to main (human-only)
**Blockers**: None identified
**Completion Date**: 2026-07-08

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Plan/design/impl/test docs: `a-` through `i-` in this task directory.
- Checkpoint commits on `feature/223-always-review-docs-regardless-of-line-cap`
  (per-phase), squashed to a single commit on `main` at merge (archaeological-main).
- Test results: `prove t/` (1008 tests) + the two task suites (85 subtests).
