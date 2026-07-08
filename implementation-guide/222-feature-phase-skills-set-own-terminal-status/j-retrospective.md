# Phase skills set own terminal status at checkpoint - Retrospective
**Task**: 222 (feature)

## Task Reference
- **Task ID**: internal-222
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/222-phase-skills-set-own-terminal-status
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-08

## Executive Summary
- **Duration**: single working session across all 10 phases (estimate: Low–Medium; on target).
- **Scope**: delivered as planned, plus one folded-in addition — strengthening the
  `stop-stale-status-detector` hook (D6) to flag non-canonical statuses, not just
  `Backlog`. No scope removed.
- **Outcome**: success. The status-leak cause is fixed at the shipped-template and
  operator-doc level; the retrospective sweep is retained as defence-in-depth per the
  explicit user constraint. Production footprint: 6 files, +137/−29, exactly one
  hashed-file edit (the hook). Full suite 998 tests green; `cwf-manage validate` OK.

## Variance Analysis
### Time and Effort
- **Estimated**: Low–Medium complexity, Low risk (template/skill/doc edits + one hook
  touch + tests; no new subsystem).
- **Actual**: matched the estimate. The reuse-first design (no new helper, no new public
  API, reuse of exported `status_is_valid`) kept implementation small.
- **Variance**: negligible. The only unplanned effort was the D6 hook strengthening,
  accepted by the user at pre-exec review and absorbed without slippage.

### Scope Changes
- **Additions**:
  - **D6 — hook strengthening**: `is_flaggable` now flags `Backlog` **and** any
    non-canonical status. Rationale: the corpus evidence (phase-name-as-status:
    `Design`, `Requirements`, `Planning`) showed `Backlog`-only detection was too narrow.
- **Removals**: none. (Considered and rejected: automating `Skipped` in the checkpoint
  helper — documented out in design as low-value under the symlink model, "best part is
  no part".)
- **Impact**: the addition widened the safety net without touching a runtime path;
  net-neutral on timeline.

### Quality Metrics
- **Test Coverage**: critical path (the leak) fully covered — template hygiene (TC-1/3),
  terminal predicate (TC-4), hook decision (TC-9), red-on-seed proof (TC-2), fail-closed
  precondition (TC-6). 998 tests / 76 files green.
- **Defect Rate**: zero. All 7 changeset reviewers (f: 5, g: 2) returned `no findings`.
- **Performance**: no runtime path modified (NFR1); checkpoint/validate timings unchanged.

## What Went Well
- **Reuse-first paid off**: reusing the already-exported `status_is_valid` meant the fix
  needed no change to `CWF::TaskState` and no new public API — the single-source enum
  now backs the hook, the test, and the sweep.
- **Test-first discipline was real, not ceremonial**: TC-2 proved red-on-seed
  deterministically (reintroduce `"Implemented"` → RED naming the token → revert →
  GREEN → clean diff), so the guard genuinely fails when the leak returns.
- **Exactly one hashed-file edit**, hash refreshed in-commit — the hashed-file discipline
  held with no drift at any checkpoint.
- **The `&&`-chained j-stamp works end-to-end**: this very retrospective checkpoint is
  its first live exercise, closing the TC-5 "mechanism only" caveat.

## What Could Be Improved
- **Corpus premise was partly stale**: the a-plan Evidence section noted the original
  "skills stamp the next file, not their own" premise was already half-fixed by
  `cwf-checkpoint-commit` (Task 102). Confirming that up front avoided building a
  redundant mechanism — but it took explicit investigation to catch. Earlier grep of the
  helper path would have surfaced it sooner.
- **`workflow-manager status` percentage display**: with a–i Finished the aggregate read
  "25%" until j completed. Not a defect for this task, but the weighting is unintuitive
  and could mislead a status sweep — candidate for a future look.

## Key Learnings
### Technical Insights
- Non-canonical statuses leak as **phase names used as status** (`Design`,
  `Requirements`), not just as non-terminal enum values — the detector must validate
  against the canonical enum, not merely blocklist `Backlog`.
- A caller-guarded Perl modulino (`unless (caller) { … } 1;`) lets a Stop-hook expose a
  testable predicate (`is_flaggable`) without a test `do`-load executing its git-diff
  main body — clean separation of logic from side-effect.

### Process Learnings
- Folding a reviewer-suggested strengthening (D6) in at pre-exec review, rather than
  deferring to a follow-up task, kept the safety net coherent and avoided a second
  hashed-file churn.
- Making the retrospective's own terminal stamp a **hard `&&`-chained precondition**
  (fail-closed) is the right shape: a failed stamp aborts the commit rather than being
  papered over by a green commit — surface, never smooth.

### Risk Mitigation Strategies
- Constraining only the *committed completion* state to terminal (leaving transient
  `In Progress`/`Testing` untouched) neutralised the "legit transient status" risk
  without special-casing.

## Recommendations
### Process Improvements
- When a task's premise cites a leak, grep the shared helper path first — a mechanism may
  already exist and only need to be relied upon, not rebuilt.

### Tool and Technique Recommendations
- The caller-guarded modulino pattern is worth reusing for any future hook that carries
  non-trivial decision logic — it makes hooks unit-testable.

### Future Work
- **`workflow-manager status` aggregate-percentage weighting**: investigate why 9/10
  terminal phases reads as 25%; low priority, correctness-of-display only.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-07-08
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md` (baseline `0999aa1`) through `e-testing-plan.md`.
- Implementation/testing: `f-implementation-exec.md`, `g-testing-exec.md`.
- Rollout/maintenance: `h-rollout.md`, `i-maintenance.md`.
- Commits: `715d446`(a) … `ce91f47`(i); production footprint 6 files (+137/−29), one
  hashed edit (`stop-stale-status-detector` + its sha256).
