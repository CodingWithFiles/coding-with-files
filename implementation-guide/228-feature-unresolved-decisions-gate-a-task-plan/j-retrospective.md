# unresolved-decisions gate for a-task-plan - Retrospective
**Task**: 228 (feature)

## Task Reference
- **Task ID**: internal-228
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/228-unresolved-decisions-gate-a-task-plan
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-12

## Executive Summary
- **Duration**: feature phases a–j in one session; ~1-day estimate, on target (calendar
  estimate treated as noise per Task 219 S7).
- **Scope**: Delivered exactly as planned — backlog item **R4** (Task 219): the unresolved-
  decisions gate for `a-task-plan` plus the mechanism-named-AC ban. Zero scope change.
- **Outcome**: Success. Guidance-only change to three surfaces; all six functional tests pass;
  all changeset reviews clean bar one in-phase fix; `cwf-manage validate` OK throughout.

## Variance Analysis
### Time and Effort
- **Estimated**: ~1 day-equivalent (docs + template + skill edits), Low complexity.
- **Actual**: On target — single session, no rework beyond one in-phase backtick fix. The
  design decision to ship guidance-only (D1, no deterministic check) kept effort at the low end.
- **Variance**: None material. The estimate explicitly hedged "a deterministic check would add
  a little"; design retired that possibility, so actual landed at the lower bound.

### Scope Changes
- **Additions**: None.
- **Removals**: The deterministic `plan-mechanical-check` enforcement path floated in planning
  (Risk 1, an open decision) was deliberately **not** built — design decision D1 chose guidance
  over a check because (a) `plan-mechanical-check` never scans `a-task-plan`, (b) the a-phase has
  no review MAP to host a check, and (c) "mechanism-named" is too fuzzy to flag without the
  false positives NFR5 forbids. This is a resolved open decision, not a descope.
- **Impact**: Kept the change additive, guidance-only, and clear of R13's scope.

### Quality Metrics
- **Test Coverage**: TC-1..TC-6 all PASS. No code shipped (D1), so no line/branch coverage —
  the additive claim (AC3/AC4) is proven by structural-reader regression (TC-3), not asserted.
- **Defect Rate**: One minor misalignment finding (two bare `planning.md` cross-references vs
  the intra-repo backtick convention), caught by the f-phase misalignment reviewer and fixed
  before the checkpoint commit. Zero defects post-completion.
- **Performance**: N/A — no runtime path.

## What Went Well
- **The feature dogfooded itself during its own planning.** `a-task-plan.md` carried an
  `### Open Decisions` subsection (gate location, enforcement altitude, definition, R6/R13
  boundary) and kept its own success criteria outcome-shaped — exercising R4 on the very plan
  that proposed it, before the template was even edited.
- **Additivity proven, not asserted.** TC-3 showed the structural readers parse the pre/post
  template byte-identically because they key off `**Status**:` markers and named headers, not
  document position — so a new mid-document H2 is invisible to them by construction.
- **Zero hash friction, confirmed early.** All three target files are untracked by
  `script-hashes.json`; verified in the f-phase smoke check, so no `script-hashes.json` refresh
  and no drift risk — a clean fit for a docs-only change.
- **The reviewer MAP earned its keep.** The one real issue (backtick divergence) was surfaced
  by the misalignment reviewer and fixed in-phase — exactly the human-shaped judgement call a
  mechanical check could not make.

## What Could Be Improved
- **Rollout and maintenance scaffolds are heavyweight for a guidance-only docs change.** Most of
  h/i (phased rollout, monitoring, alerting, scaling, incident tiers) reduced to "N/A — no
  runtime". This is a known recurring shape, not a defect; a lighter internal/developer-tool
  rollout+maintenance template already sits in the backlog ("Lightweight Rollout/Maintenance
  Templates for Internal/Developer-Tool Tasks") — this task is another data point for it.
- **Cosmetic aggregate quirk.** `workflow-manager status --workflow` shows the task at "25%" on
  the top line while every phase reads Finished (100%) — the aggregate MINs a `state_done`
  field. Per-phase status is correct; the top-line number misleads at a glance. Also a known,
  backlogged reader quirk.

## Key Learnings
### Technical Insights
- Content-keyed (marker-based) structural readers make additive template edits safe by
  construction — the safest way to extend a parsed template is to add a named section a
  position-independent reader will simply skip.
- "Guidance vs deterministic check" is an altitude decision, not a strength decision. For a
  fuzzy rule ("mechanism-named"), a low-false-positive mechanical check may not exist; guidance
  backed by a skill-checklist gate plus an advisory reviewer is the correct altitude, and NFR5
  (no false positives) is what forces that call.

### Process Learnings
- Front-loading a task's own open decisions at plan time (dogfooding R4) sharpened the design
  phase: the four named decisions mapped almost 1:1 onto design decisions D1–D5, so design was
  resolution rather than discovery — the exact benefit R4 exists to produce.
- The estimate held because design closed the one open cost driver (check vs no-check) early;
  naming that as an open decision up front is why it was resolved deliberately rather than
  discovered mid-exec.

### Risk Mitigation Strategies
- Risk 1 (fuzzy-definition false positives) was mitigated by requiring a crisp testable
  definition in requirements and then declining the check in design — the mitigation named in
  planning was followed exactly.
- Risk 2 (overlap with `Constraints`, R6, R13) was mitigated by D3 (new distinct H2, not folded
  into `Constraints`) and an explicit scope boundary leaving `plan-mechanical-check` to R13.

## Recommendations
### Process Improvements
- Continue dogfooding new planning-phase features on their own plan — it was the strongest
  validation signal here and cost nothing.

### Tool and Technique Recommendations
- The "add a named section a marker-based reader ignores" pattern is the standard safe way to
  extend `a-task-plan` — worth reaching for in R6/R13 when they touch the same file.

### Future Work
- **R6** (complexity tier + risk register) and **R13** (extend `plan-mechanical-check`) both
  still touch `a-task-plan`; this task deliberately scoped clear of them. Whoever picks them up
  should reuse the `## Open Decisions` H2 placement precedent so the three additions don't
  collide. No new backlog item created by this task — the coordination note lives in R6/R13's
  own scope. R4 is delivered; the Task 219 umbrella item retains its remaining follow-ups.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-07-12
**Sign-off**: CwF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning through testing: `a-task-plan.md` … `g-testing-exec.md` in this task directory.
- Rollout and maintenance: `h-rollout.md`, `i-maintenance.md`.
- Commit chain (checkpoints): a=b447932, b=b55715d, c=7f04068, d=f725bb1, e=d881f22,
  f=fd349d3, g=46b267e, h=7ccadc0, i=eb39367.
