# Anti-fragile concept in robustness reviewer - Retrospective
**Task**: 217 (hotfix)

## Task Reference
- **Task ID**: internal-217
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/217-anti-fragile-concept-in-robustness-reviewer
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-05

## Executive Summary
- **Duration**: <1 day (estimated: <0.5 day). Slightly over on wall-clock because
  plan review surfaced a factual error that expanded exec scope (hash refresh).
- **Scope**: Add the anti-fragile concept to the robustness reviewer(s). Final
  scope grew from one file to two (user chose both-file scope) plus a mandatory
  same-commit hash refresh that the initial plan wrongly excluded.
- **Outcome**: Success. Both robustness reviewers now name the
  fragile → robust → anti-fragile spectrum; all gates green (7 reviewer passes
  across two exec phases, TC-1..TC-7 + regression, `validate` clean).

## Variance Analysis
### Time and Effort
- **Estimated**: sub-day, single-file prose edit, "no hash refresh".
- **Actual**: sub-day, two-file edit + same-commit hash refresh + a status-value
  correction caught by `validate`.
- **Variance**: the estimate's "no hash refresh" assumption was wrong. The agent
  def files ARE hash-tracked at `0444`. Caught at plan-review (security reviewer),
  not at exec — cheap to absorb because it surfaced before any code was written.

### Scope Changes
- **Additions**:
  1. Second file (`cwf-plan-reviewer-robustness.md` design bullet) — user chose
     both-file scope over the minimal changeset-only default.
  2. `script-hashes.json` refresh for both entries — corrected from a wrong
     "untracked" claim.
  3. Advisory verdict-semantics sentence in the changeset reviewer — added on the
     plan-robustness reviewer's finding to prevent false-positive `findings`.
- **Removals**: runtime-only criteria (`load`, `partial failure`, `self-hardening`)
  dropped from the wording — the changeset reviewer sees only a static diff.
- **Impact**: net wording stayed compact; scope growth was correctness-driven, not
  gold-plating.

### Quality Metrics
- **Test Coverage**: all 7 functional cases + regression pass; every success
  criterion mapped to ≥1 case.
- **Defect Rate**: 0 post-implementation. One planning-stage defect (the hash
  claim) caught and corrected before exec.
- **Performance**: N/A (prose edit).

## What Went Well
- **Plan review earned its keep.** The security plan-reviewer caught a false
  "not hash-tracked" claim that I had asserted and that two other reviewers
  (robustness, misalignment) had echoed. Verifying directly against
  `script-hashes.json` — rather than trusting the majority — turned a would-be
  exec-time `validate` failure into a plan correction.
- **Robustness reviewer improved its own instructions.** Its finding that the
  draft named runtime-only properties the static-diff reviewer cannot judge
  tightened the wording and added the advisory guard — a fitting outcome for a
  task about that very reviewer.
- **All 7 changeset reviews (5 at f, 2 at g) returned no findings**, confirming a
  clean, minimal, convention-aligned change.

## What Could Be Improved
- **I asserted an unverified integrity claim in the plan.** "Agent defs are not
  hashed" was stated in both a-task-plan and d-plan without checking
  `script-hashes.json`. The plan-time disclosure rule in `hash-updates.md` exists
  precisely to force that one grep at d-plan — I should have run it proactively,
  not relied on the reviewer to catch it.
- **`**Status**: Ready` is not a valid status value.** I introduced it in three
  plan files; `validate` rejected it at exec. Minor, but avoidable — the template
  ships `Backlog` and the valid set is small.

## Key Learnings
### Technical Insights
- `.claude/agents/*.md` reviewer definitions ARE hash-tracked at `0444` in
  `script-hashes.json`; editing one is a hashed-file edit with a same-commit
  refresh, exactly like a `.cwf/scripts/` change.
- `cwf-manage fix-security` clamps permissions only — it will NOT recompute a
  changed `sha256` (by design: "surface, never smooth"). The refresh is manual:
  `sha256sum` → hand-edit the manifest entry → `validate`.
- The Bash tool's sandbox mounts `.claude/` read-only (EROFS); `chmod` on those
  files needs `dangerouslyDisableSandbox`. The Edit tool itself was unaffected once
  the working perms allowed writes.

### Process Learnings
- Run the `hash-updates.md` plan-time disclosure grep during d-plan for ANY file
  under a hash-tracked tree, including `.claude/agents/`, `.claude/hooks/`,
  `.claude/rules/` — not just `.cwf/`.
- When multiple reviewers agree with the author, that is not corroboration if they
  all inherited the same unchecked premise. Verify integrity claims against the
  manifest, not against reviewer consensus.

### Risk Mitigation Strategies
- The a-task-plan Risk 1 (scope creep / bloat) held: the final wording is one
  clause + one advisory sentence per file, no new sections.

## Recommendations
### Process Improvements
- Consider a `plan-mechanical-check` extension: flag any Files-to-Modify path that
  matches a `script-hashes.json` entry but where the plan omits `script-hashes.json`
  from Supporting Changes. This would catch the exact class of error this task hit,
  deterministically, at plan time. (See Future Work.)

### Tool and Technique Recommendations
- Keep verifying reviewer-flagged factual claims directly at the source; the
  pattern paid off here.

### Future Work
- **Backlog candidate**: extend `plan-mechanical-check` to cross-reference
  Files-to-Modify against `script-hashes.json` and warn when a hashed path lacks a
  matching `script-hashes.json` Supporting-Change disclosure.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge to human
**Blockers**: None identified
**Completion Date**: 2026-07-05
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, d-implementation-plan.md, e-testing-plan.md
- Execution: f-implementation-exec.md (5 changeset reviews), g-testing-exec.md
  (TC-1..TC-7 + regression, 2 changeset reviews)
- Rollout: h-rollout.md
- Changed artefacts: `.claude/agents/cwf-robustness-reviewer-changeset.md`,
  `.claude/agents/cwf-plan-reviewer-robustness.md`,
  `.cwf/security/script-hashes.json`
