# phase-scoped planning-write PreToolUse guard - Retrospective
**Task**: 180 (feature)

## Task Reference
- **Task ID**: internal-180
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/180-phase-scoped-planning-write-pretooluse-guard
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-05

## Executive Summary
- **Duration**: ~1 working day (estimated: 2–4 days). Under estimate — the
  179 substrate (event allowlist, R3 hook model, sandbox config block + dual
  validators, merge helper) did most of the structural heavy lifting; this task
  was mostly the policy core + one hook + wiring.
- **Scope**: Delivered as planned (R1: matcher widening, fail-closed guard hook,
  pure-logic lib, enum knob, gated registration, doc). One unplanned addition —
  a latent Task-179 defect fix (see Scope Changes).
- **Outcome**: Success. SC1–SC5 met, FR1–FR7 satisfied (NFR1 measured in g), both
  exec-phase security reviews **no findings**, full suite 686 green,
  `cwf-manage validate` clean. Ships off-by-default.

## Variance Analysis
### Time and Effort
- **Estimated** (a-plan): 2–4 days, Medium–High complexity.
- **Actual**: ~1 day across all phases (planning was already complete on entry to
  this session; exec + finish executed in one sitting).
- **Variance**: Under. The fail-closed/bricking balance — flagged as the central
  risk — proved tractable because the design (crown-jewel deny-list, Option A) had
  already collapsed the policy to "deny crown jewel unless positively exec", and
  the lib/hook split made the matrix unit-testable without git.

### Scope Changes
- **Addition — `read_hook_directives` directive-scan fix**: the directive scan was
  capped at the first 15 lines, but the canonical hook header places directives at
  ~line 18, so **both** R3 (shipped in 179) **and** the new guard silently fell
  back to `Stop`/no-matcher instead of `PreToolUse`. Found via dry-run while
  wiring registration. Fixed by scanning the leading comment block (stop at the
  first code line) — repairs R3 as a tested consequence (TC-M6). A second pass
  (review feedback) removed the interim 50-line backstop: the comment-block end is
  the natural bound, no magic number.
- **Removals**: none. NFR1 cost was recorded in g (as planned), not asserted.
- **Impact**: small positive — a real latent bug fixed; no timeline cost.

### Quality Metrics
- **Test Coverage**: 77 task-specific tests across 4 suites; full suite 686 green.
  Critical path (decide matrix, classify canonicalisation, matcher accept/reject,
  dual-validator enum, gated registration, fail-closed defaults, deny envelope)
  covered.
- **Defect Rate**: one latent pre-existing defect found + fixed; zero new defects
  surfaced in testing or the two security reviews.
- **Performance**: crown 36.9 ms/call, non-crown 25.9 ms/call — both under the
  ~50 ms NFR1 budget.

## What Went Well
- The **lib/hook split** (`CWF::PlanningGuard` pure functions vs the thin I/O hook)
  paid off exactly as the design intended: the whole policy matrix is unit-tested
  deterministically without git/TCI, and the hook test only had to bind I/O wiring.
- **Modelling on R3** (FindBin-anchored log, eval-contained body, directive-driven
  registration) made the new hook fast to write and consistent with the substrate.
- The **dry-run as a verification step** caught the directive-scan misregistration
  immediately — a source-grep alone would have missed it (the registration is an
  emergent property of the merge helper + hook header).
- **Fail-closed reframing** ("deny crown jewel unless positively exec") meant the
  no-brick guarantee came from *scope* (only crown jewels denied), not leniency.

## What Could Be Improved
- The directive-scan limit was an **arbitrary magic number** that nobody caught in
  179 because its test used stubs with directives at the top — the real hook's
  line placement was never exercised end-to-end. A test that runs the *real* hook
  header through the merge helper would have caught it at 179 time.
- I initially "fixed" the cap by **enlarging it (15→50)** rather than removing the
  arbitrariness — the reviewer correctly pushed back. First instinct on an
  arbitrary limit should be "what's the natural bound?", not "pick a bigger number".

## Key Learnings
### Technical Insights
- Hook **registration is emergent** (merge helper ∘ hook header), so it must be
  verified by generating the artefact (dry-run), not by reading source — the same
  "rebrands need output-level smoke-test" lesson, applied to registration.
- `workflow_step` is **letter-prefixed**; name-matching must strip `^[a-j]-` so it
  survives v2.0/v2.1 letter reassignments (caught in plan review, held in exec).
- Arbitrary line/scan caps on structured files are a smell — prefer a **structural
  bound** (here: the leading comment block ends at the first code line).

### Process Learnings
- Stopping at the **f/g review gate** (as the user asked) was valuable: the cap
  removal came out of that review and was cheaper to fix pre-merge.
- TDD per d-plan step (failing test → impl → green) kept each of the 8 steps
  honest and made the security reviews fast (the reviewers leant on the tests).

### Risk Mitigation Strategies
- The a-plan's "observe-only first mode" de-risking lever shipped as the `observe`
  knob value — it is both the de-risk mechanism and the rollout dial.

## Recommendations
### Process Improvements
- When touching a shared parser/limit, **exercise the real artefact** (not just a
  stub) in at least one test — would have caught the 179 directive-scan miss.

### Tool and Technique Recommendations
- The lib/hook (pure-core + thin-IO) split is worth standardising for any future
  CWF hook that needs git/TCI — it is the difference between a deterministic unit
  suite and a slow, flaky integration-only one.

### Future Work
- **Consider widening the exec set** beyond `implementation-exec` (e.g. allow
  `testing-exec` crown-jewel writes) if real `observe`-mode logs show frequent
  legitimate denials there. Deferred deliberately — start conservative, widen on
  evidence. No backlog item raised yet (evidence-gated).
- Optional: a 179-era follow-up note that the directive-scan fix changes R3's
  registration on adopters' next merge (already documented in f/h).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-05
**Sign-off**: The maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning + exec: this task's `a`–`i` workflow files.
- Key commits (task branch): `bb5df28` (f-impl), `6a2c90e` (g-test), `b69edd2`
  (cap-removal review fix), `a542df3` (h-rollout), `c1b50fe` (i-maintenance).
- New artefacts: `.cwf/lib/CWF/PlanningGuard.pm`,
  `.cwf/scripts/hooks/pretooluse-planning-write-guard`,
  `t/planning-guard.t`, `t/pretooluse-planning-write-guard.t`.
- Docs: `.cwf/docs/sandboxing.md` § "Planning-write guard".
