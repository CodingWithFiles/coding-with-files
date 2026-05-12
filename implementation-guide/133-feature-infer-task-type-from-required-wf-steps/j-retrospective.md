# Infer task type from required wf steps - Retrospective
**Task**: 133 (feature)

## Task Reference
- **Task ID**: internal-133
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/133-infer-task-type-from-required-wf-steps
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-12

## Variance Analysis

| Dimension | Planned (a-task-plan) | Actual | Variance |
|---|---|---|---|
| Effort | 1–2 days | ~1 session | Inside band, low end |
| Complexity | Medium | Medium | On target |
| Files changed | rubric doc + 2 SKILL.md edits + test | 1 rubric + 1 test + 2 SKILL.md edits | On target |
| Helper scripts added | 0 (per NFR3) | 0 | On target |
| New env vars | 0 (per NFR4) | 0 | On target |
| Tests added | "fixture-driven, one per type + ≥2 ambiguous" | 1 Perl drift test (29 assertions) + manual smoke matrix walked inline | Method-deviation, see below |
| BACKLOG retirement | AC7 | Executed in h-rollout | On target |

The plan's testing pitch (fixture-driven, one description per type)
implied automated runtime assertions per type. Actual: the smoke matrix
was walked through inline in g-testing-exec by applying the rubric to
each candidate description — because the runtime inference is the
LLM's job, the only automatable surface is the static drift test
between rubric and templates. Method deviation noted in
e-testing-plan.md and g-testing-exec.md; the spirit of AC1–AC8 was
exercised, just not with executable Perl fixtures.

## What Went Well

- **Reframing the requirement up front saved rework.** The user's
  recast — "infer required wf steps first, then map to closest-fit
  task type" — landed in a-task-plan §Background as a table and drove
  the entire downstream design. By the time c-design-plan was being
  reviewed, the symmetric-difference rule and `(b,c,h,i)` quartile
  were obvious in hindsight. If we had stuck with the original
  framing ("infer the task type from the description") the rubric
  would have been a label-keyword bag, brittle and worse than LLM
  reasoning.

- **Static drift test is the right shape for the right surface.** All
  the runtime behaviour is LLM judgement; the only deterministically
  testable thing is "the rubric's claims about each type match the
  actual template files". One Perl test, 29 assertions, three
  invariants (existence + headings + table-vs-templates) — strong
  signal for low surface area.

- **Plan-review subagents earned their pay on c-design-plan.** Three
  reviewers (Improvements / Misalignment / Robustness / Security)
  converged on the same point from different angles: runtime FS
  enumeration of `.cwf/templates/*/` is both a security smell and a
  duplicate source-of-truth with the rubric. That joint signal made
  the FR6-relaxation easy to commit to without second-guessing.

## What Could Be Improved

- **Test plan's expected ambiguity case was wrong.** TC-3
  ("Investigate why X is slow and fix it") was advertised as
  triggering the ambiguity prompt, but honest rubric application
  resolves it to `discovery` at distance 0 — silent pick. The plan
  drafter (me) hadn't walked through the rubric to verify the
  expectation; if I had, this would have been caught in e-testing-plan
  rather than during g-testing-exec. **Lesson**: when the test plan
  predicts a specific code-path being exercised, simulate it once
  before signing off the phase.

- **Security-review subagent failed sentinel-first protocol twice.**
  Both f and g invocations started with preamble ("Now I'll analyse…")
  before the `findings:` / `no findings` / `error:` sentinel,
  forcing classification to fall through to the numbered-list
  fallback. Bodies were clean. **Lesson** for future tasks: the
  prompt template in `.cwf/docs/skills/security-review.md` could
  benefit from a stronger sentinel-first imperative, or the
  classification logic could be more forgiving. Not changing now —
  one task's signal is anecdote, not pattern.

- **Two-commit phase-f pattern is awkward.** Because
  `security-review-changeset` diffs `<anchor>..HEAD` (committed only),
  running the review pre-commit always sees an empty changeset on
  phase f. The pragmatic flow was: commit the impl files (`663ff46`),
  then run the review, then commit the wf-step file (`dc0a56a`). The
  SKILL spec implies one commit per phase. **Lesson**: this isn't a
  task-133 defect; it's a workflow design choice worth a future
  BACKLOG item — either "make security-review work on staged
  changes" or "make the two-commit phase-f flow explicit in the
  SKILL".

- **`Discovery` was missing from cwf-new-subtask's argument list.**
  Spotted only mid-implementation: the SKILL.md said
  `feature|bugfix|hotfix|chore` while `cwf-project.json` had
  `discovery` in `supported-task-types`. Fixed in passing, recorded as
  a deviation in f-implementation-exec.md. **Lesson**: when a task
  touches both skill files for a parallel reason, do a side-by-side
  read first to catch latent drift.

## Key Learnings

1. **Two-stage decoupling (infer-steps then map-to-type) is more
   robust than label-inference.** It localises the fuzzy judgement
   (signal extraction from prose) at one stage and the deterministic
   resolution (set-distance vs canonical table) at the other.
   Misclassification is bounded by which signal the LLM mis-marks,
   not by which label it pattern-matches.

2. **Some "failure modes" are mathematically unreachable.** FM-3
   (distance ≥ 3) is dead code under the current 5-type taxonomy
   because the four-bit `(b,c,h,i)` quartile's maximum nearest-
   neighbour distance from any of the 11 uncovered points to the
   five canonical points is 2. Worth keeping the safety net for
   future taxonomy growth, but don't write tests against a branch
   the algebra forbids.

3. **Rubric-as-doc serves both runtime and humans.** The same
   markdown file the SKILL reads at invocation time is the
   human-readable explanation of "why these task types exist". One
   source of truth, dual consumers, no duplication.

## Recommendations

- **For the next task that touches CWF skills**: read both
  `cwf-new-task/SKILL.md` and `cwf-new-subtask/SKILL.md` side by side
  before editing either. They've drifted at least once (this task's
  `discovery` gap); they will drift again.
- **For the rubric content**: leave it alone until a real
  misinference shows up in normal use. Tuning the discriminating
  questions speculatively is busywork; tuning them in response to a
  concrete miscue is fast (rubric is markdown, no code change).
- **For the FM-3 dead code**: a follow-up task could trim the
  Resolution Algorithm step 6 to a footnote, but it's not urgent —
  the dead code is defensive and would become live if the canonical
  taxonomy grows.

## Final Status

- [x] All wf step files Finished (a–i, this file j)
- [x] BACKLOG entry retired into CHANGELOG (h-rollout § Phase 1)
- [x] `t/task-type-inference-rubric.t` passing (29/29 assertions)
- [x] `prove t/` clean (441/441)
- [x] `cwf-manage validate` clean
- [x] No production system to monitor; no rollback executed

## Status
**Status**: Finished
**Next Action**: Suggest squash + merge to main (user-only)
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned

Recorded inline above under "What Went Well", "What Could Be
Improved", and "Key Learnings".
