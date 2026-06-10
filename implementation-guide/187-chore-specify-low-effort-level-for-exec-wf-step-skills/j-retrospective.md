# Specify low effort level for exec wf step skills - Retrospective
**Task**: 187 (chore)

## Task Reference
- **Task ID**: internal-187
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/187-specify-low-effort-level-for-exec-wf-step-skills
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-10

## Executive Summary
- **Duration**: ~1 session (estimated <0.5 day; on estimate)
- **Scope**: Add `effort: low` to the two exec-phase skills (`cwf-implementation-exec`,
  `cwf-testing-exec`) and `effort: high` to the `cwf-security-reviewer-changeset` agent they
  spawn. Final scope matched plan exactly — no additions, no removals.
- **Outcome**: Success. All six test cases PASS, both exec-phase security reviews returned
  no findings, `cwf-manage validate: OK`.

## Variance Analysis
### Time and Effort
- **Estimated**: <0.5 day total (chore: a, d, e, f, g, j).
- **Actual**: One session, no phase materially over-ran. The d-phase plan-review surfaced the
  bulk of the thinking (vacuous grep, harness-honours-effort limitation); execution was three
  one-line edits plus a hash refresh.
- **Variance**: ~0%. A docs/config chore with a single hashed-file touch is well-suited to the
  estimate.

### Scope Changes
- **Additions**: None.
- **Removals**: None. The "open question" from a-plan (does a subagent inherit a skill's
  lowered effort?) was resolved by user decision to pin the reviewer at `high` regardless,
  making the inheritance question moot for safety.
- **Impact**: None on timeline; the pin added one hashed-file edit + same-commit refresh.

### Quality Metrics
- **Test Coverage**: TC-1…TC-6 all PASS (frontmatter presence/values, no `model:` key, YAML
  well-formedness, hash consistency, same-commit discipline, skill/subagent regression).
- **Defect Rate**: 0 defects found in testing; 0 security findings across both exec reviews.
- **Integrity**: `validate: OK`; one pre-existing permission-drift set (6 files) clamped
  on sight during the a-phase checkpoint per fix-on-sight rule.

## What Went Well
- **Verify-before-building.** The pasted prior-session claim that SKILL.md supports `effort`
  was checked against the live Claude Code docs (via claude-code-guide) before any work — the
  prior session had already made a factual error (cost arithmetic), so the frontmatter claim
  earned scrutiny. It held up; the task rested on a verified mechanism, not a hand-me-down assertion.
- **The reviewer-pin decision insulated the security gate.** Pinning `effort: high` on the
  FR4 reviewer means the exec-skill downgrade can never silently weaken the security review,
  independent of whatever the harness's skill→subagent inheritance turns out to be.
- **Plan review earned its keep.** Two reviewers independently confirmed the effort split is
  sound; robustness/improvements caught that Step 4's grep was vacuous and that `validate`
  proves integrity but not that the harness honours `effort` — both folded into the plan.
- **Hash discipline clean.** Pre-refresh `git log` verification, same-commit refresh, and
  perms restored to the recorded `0444` ceiling — TC-4/TC-5 confirm.

## What Could Be Improved
- **The knob is not provably honoured in-repo.** `cwf-manage validate` checks integrity, not
  whether the harness acts on `effort`. We accepted behavioural evidence (exec ran cleanly under
  the new frontmatter) rather than a strict proof. This is inherent to a harness-level feature
  with no in-repo precedent, and is recorded as a Known Limitation in the plan.

## Key Learnings
### Technical Insights
- `effort` is a documented SKILL.md/agent frontmatter key (`low|medium|high|xhigh|max`); set
  without a `model:` key it applies to the session-pinned model — here `claude-opus-4-8` from
  `settings.json`, i.e. "Opus 4.8 at low" on exec, "Opus 4.8 at high" on the reviewer.
- Frontmatter **value** on a hash-tracked guard agent carries security weight that the integrity
  manifest does not police: `validate` would happily bless `effort: low` on the reviewer. The
  sha256 signs the bytes; it does not judge whether the value is safe.

### Process Learnings
- A "decision the user owns" (the reviewer pin) cleanly collapsed an open design question —
  worth surfacing such forks early rather than hedging through to exec.

### Risk Mitigation Strategies
- Defensive pinning (rather than relying on inheritance behaviour) was the right call for a
  security-relevant component: correctness over fewer file edits.

## Recommendations
### Process Improvements
- When lowering effort on orchestration skills, always check whether they spawn a
  judgement-critical subagent and pin that subagent's effort explicitly.

### Tool and Technique Recommendations
- Replace vacuous "grep for a sentence that was never written" verification steps with checks
  that target the actual artefact (here: whether any doc enumerates permitted frontmatter keys).

### Future Work
- **Optional convention note**: capture that `effort` (and `model`) values on hash-tracked
  reviewer/guard agents carry security weight the sha256 manifest does not police — a future
  `effort: low` on a guard agent would pass `validate` while degrading the gate. Candidate home:
  a sentence in `hash-updates.md` or `design-alignment.md`. Low priority; recorded as a watch-item.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-10
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Checkpoint commits: a `0f65754`, d `f86d750`, e `3fef760`, f `d003439`, g `dd6ab2b`
- Security reviews: f-implementation-exec.md and g-testing-exec.md `## Security Review` sections
  (both `no findings`)
