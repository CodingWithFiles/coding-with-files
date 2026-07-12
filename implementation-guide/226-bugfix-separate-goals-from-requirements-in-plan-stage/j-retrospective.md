# Separate goals from requirements in plan stage - Retrospective
**Task**: 226 (bugfix)

## Task Reference
- **Task ID**: internal-226
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/226-separate-goals-from-requirements-in-plan-stage
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-12

## Executive Summary
- **Duration**: ~0.5 day actual vs ~0.5 day estimated (variance ≈ 0%).
- **Scope**: Delivered exactly as planned — no scope added or cut. All five owner
  deliverables (dual-capture goal, "best part is no part" kept first-class but fenced
  to means, owner-owned goals, loud scope-surfacing, reviewer binding) landed across
  the six planned files.
- **Outcome**: Success. TC-1…TC-10 (binding) all PASS, `cwf-manage validate` clean,
  all seven reviewer runs (5 in f, 2 in g) returned `no findings`. Two advisories were
  surfaced and deliberately not fixed (recorded for the owner).

## Variance Analysis
### Time and Effort
- **Estimated**: Planning + Design + Implementation-plan + Testing-plan + exec (f/g) ≈ 0.5 day.
- **Actual**: ≈ 0.5 day; no phase overran. Bugfix path is a,c,d,e,f,g,j — no requirements
  phase (b), consistent with the type.
- **Variance**: Negligible. The change was correctness-sensitive wording, not volume;
  effort went into precise phrasing and the no-orphan check, not breadth.

### Scope Changes
- **Additions**: None.
- **Removals**: None. The one thing this task was forbidden to cut — the "best part is
  no part" maxim — was preserved and merely fenced to the *means*; it remains universal
  in `planning.md` for all task types.
- **Impact**: None on timeline or quality; the KD2 "relocation not weakening" framing
  held through exec.

### Quality Metrics
- **Test Coverage**: 100% of KD1–KD6 covered by ≥1 binding assertion (TC-1…TC-10).
- **Defect Rate**: 0 findings across 7 reviewer runs; 0 test failures.
- **Advisories (surfaced, not fixed)**:
  1. **Robustness (f)** — `planning.md`'s means-fence points to "the requirements *and
     implementation* phases", but the fuller challenge-requirements discipline text lives
     only in `requirements.md` (feature/discovery). For bugfix/hotfix/chore that is a
     dangling cross-reference (the maxim itself is still inline in `planning.md` for all
     types, so no broken path). Candidate follow-up.
  2. **Security (g), category-e forward note** — the new `Explicit request` field captures
     user free-text verbatim; safe today (read as plan content, never drives a tool call),
     but any future consumer keying logic off it rather than the validated task number
     would create an injection vector. Audit-on-change note, no action now.

## What Went Well
- The plan's own risk register (High: "over-correction — weakening best part is no part")
  became the exec gate: KD2 was framed as relocation-plus-fence with an explicit non-goal,
  and TC-2 asserted the maxim survives in *both* docs. The risk never materialised.
- Single-source reviewer binding (KD4): the scope-surfacing rule landed in one file
  (`cwf-agent-shared-rules.md`), not 10 reviewer defs. The misalignment reviewer
  independently confirmed all 10 defs still link the shared doc and none were edited.
- Same-commit hash refresh (KD6) executed cleanly — pre-refresh `git log` verify, hand-edit,
  doc+manifest in one commit, `validate: OK`. No drift reached retrospective.
- The task dogfooded its own fix: the a-task-plan goal was itself written in the new
  dual-capture shape (Why + verbatim explicit deliverables), demonstrating the format.

## What Could Be Improved
- The robustness advisory (dangling cross-reference for no-requirements-phase types) is a
  real gap the plan's KD2 scoping foresaw but chose not to close in-task. Better would have
  been to note the cross-reference target explicitly in the design so exec didn't surface it
  as a late advisory — minor, but it is the one rough edge.
- Prose-instruction reliability (a Medium risk) remains inherently unverifiable by static
  assertion: TC-11 (live replay of the Task-31 scenario) is confirmatory/soft, not gated.
  The structural blocks are in place, but only field use will prove the behaviour sticks.

## Key Learnings
### Technical Insights
- A goal and a requirement are different object types even when the words look alike:
  the goal is owner-owned and near-inviolable, the requirement is the cuttable means.
  Encoding that distinction as a *phase boundary* (goals-step vs requirements-step docs)
  rather than a prose caveat is what makes it enforceable by an agent.
- "None stated" as an explicit allowance matters: without it, a dual-capture instruction
  pressures the agent to *invent* deliverables for genuine one-line requests. The fallback
  is what keeps the rule safe on the empty case.

### Process Learnings
- Writing the trigger incident (Task-31) into the plan's Why gave every downstream phase a
  concrete failure to test against, which is why TC-11 could be stated at all. Anchoring a
  behavioural fix to a real incident beats abstract "should not de-scope" wording.
- Surfacing advisories without fixing them is the correct KD2 discipline — the exec MAP
  found two, and expanding scope to fix them would have re-committed the very error (treating
  an in-scope boundary as infinitely stretchable) the task exists to prevent.

### Risk Mitigation Strategies
- The "bake into checklist, not prose" mitigation (KD5) paid off: the two new SKILL
  Success-Criteria items are statically assertable (TC-6), unlike narrative guidance.

## Recommendations
### Process Improvements
- When a fix relocates or fences a maxim, add a binding assertion that the maxim still
  exists in its *retained* location (the KD2 no-orphan check), not only that it left the
  origin. This caught the over-correction risk cleanly and is worth generalising.

### Tool and Technique Recommendations
- None new. Existing shared-rules link propagation, template symlink pool, and same-commit
  hash procedure were sufficient; no tooling was added, which is the desired outcome.

### Future Work
- **Candidate follow-up (robustness advisory)**: give bugfix/hotfix/chore a dedicated
  downstream home for the challenge-requirements discipline, or soften `planning.md`'s
  cross-reference so it does not point at a phase those types lack. Low priority.
- **Audit-on-change note (security advisory)**: if any future consumer begins keying logic
  off the `Explicit request` field, route that change through the security reviewer.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-07-12
**Sign-off**: Completed by the maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Plan: `a-task-plan.md`; Design: `c-design-plan.md`; Impl plan: `d-implementation-plan.md`;
  Test plan: `e-testing-plan.md`.
- Exec records: `f-implementation-exec.md` (commit `3eadeb2`), `g-testing-exec.md`
  (commit `2c35d27`).
- Reviewer outputs archived in the per-task scratch `.out` files.
