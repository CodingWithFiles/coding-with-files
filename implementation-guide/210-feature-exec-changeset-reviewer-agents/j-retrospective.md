# exec-changeset reviewer agents - Retrospective
**Task**: 210 (feature)

## Task Reference
- **Task ID**: internal-210
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/210-exec-changeset-reviewer-agents
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-22

## Executive Summary
- **Duration**: a–j across ~4 calendar days (2026-06-18 → 2026-06-22), a few
  working sessions; estimate 1–2 days, active effort well under estimate.
- **Scope**: Delivered exactly as planned — three exec-only changeset reviewers
  (improvements/robustness/misalignment) + a 2→5 Step-8 rewrite + a test. No
  scope additions; no descopes.
- **Outcome**: Success. All five success criteria met; the report that prompted
  the task ("reuse/reliability/alignment don't run after implementation-exec") is
  resolved.

## Variance Analysis
### Time and Effort
- **Estimated**: 1–2 days (Medium complexity).
- **Actual**: Plan phases a–e in one session; exec f–g in a second; h–j in a
  third (after a session boundary that conveniently provided a fresh agent load).
  Active work was hours, not days.
- **Variance**: Under estimate. The "clone the established `-changeset` pattern,
  port only the lens" approach kept each agent near-mechanical.

### Scope Changes
- **Additions**: None.
- **Removals/Deferrals**:
  - Verdict-block de-dup into `cwf-agent-shared-rules.md` — deliberately deferred
    (logged BACKLOG candidate in f; re-surfaced live by the improvements reviewer
    in h). Keeps "add three reviewers" scoped; avoids re-hashing two shipped agents.
  - CHANGELOG entry + `cwf-project.json` version bump moved from the d-plan's
    Step 4 (implementation) to retrospective, matching the established per-task
    pattern (`wf_step_config.retrospective.bump_version`).
- **Impact**: None negative — both are pattern-conformance, not cut corners.

### Quality Metrics
- **Test Coverage**: `t/exec-changeset-reviewers.t` 11 subtests (TC-1…TC-10);
  full suite 882 green (was 871). `cwf-manage validate` OK.
- **Defect Rate**: Zero defects. All four exec changeset reviews (f + g, security
  + best-practice) returned no findings; the live five-reviewer MAP in h returned
  no findings on four lenses and one **advisory** `findings` (the already-logged
  de-dup) that correctly did not block.
- **Performance**: N/A (markdown/skill change; reviewers run inside the existing
  parallel MAP — bounded by the slowest single reviewer).

## What Went Well
- Cloning the Bash-free `cwf-best-practice-reviewer-changeset` (not the
  Bash-granting plan reviewer) gave a strictly narrower tool grant for free; the
  security reviewer confirmed the new agents *reduce* the prompt-injection surface.
- Reuse held: one changeset run, one classifier, one shared-rules doc, one wiring
  point. No forked helpers, no new doc, no new classifier (NFR3 honoured).
- The degradation paths (on-main, empty changeset, helper error) were hardened in
  design and converted to deterministic test gates (TC-6/TC-7), not left to manual
  smoke.
- Risk mitigations all landed: R1 (diff mis-read) via lens-only port; R2 (guard)
  stayed unguarded and verified live FR5; R4 (testing-exec exclusion) as a
  positive invariant (TC-4 asserts exactly two and none of the three).

## What Could Be Improved
- The deferred live smoke (TC-11/12) could not run in the authoring session
  because agent definitions are session-cached. It closed cleanly in the next
  session (h), but this is a recurring friction for agent/skill tasks.
- The best-practice resolver kept matching off-domain corpora (golang/postgres)
  for a docs/agent task across every review phase — noise, already logged as a
  Task 209 backlog item; not re-opened here.

## Key Learnings
### Technical Insights
- Agent `.md` files have no include mechanism, so a shared contract (verdict
  block, withheld-Bash paragraph) is necessarily duplicated. The right de-dup home
  is `cwf-agent-shared-rules.md`, but hoisting touches hash-tracked shipped agents
  — a separate, scoped task.
- A 2→5 fan-out is safe only if every section is emitted unconditionally; the
  explicit "all five always emitted" invariant in Step 8 + per-section independent
  classify is what preserves FR7 (one error ≠ suppressed peers).

### Process Learnings
- Session-cache: a task that adds agents/skills cannot live-exercise them in the
  same session it authors them. Plan the live verification for the next session
  (already captured in memory `feedback_agent_def_session_cache`).
- CHANGELOG/version bookkeeping belongs at retrospective for this repo; a plan that
  places it in implementation should be read as "per the established pattern,"
  i.e. defer to j.

### Risk Mitigation Strategies
- Deciding guard scope explicitly in design (advisory → unguarded) meant FR5 was a
  one-line verification (TC-5 + the live h run), not a debugging exercise.

## Recommendations
### Process Improvements
- For agent/skill-adding tasks, schedule the live output smoke as an explicit
  next-session step rather than a same-session deferral.

### Tool and Technique Recommendations
- The "clone the `-changeset` precedent, port only the lens" recipe is now proven
  twice (security/best-practice → these three). Worth treating as the standard way
  to add a changeset reviewer.

### Future Work
- BACKLOG (carried): hoist the shared `cwf-review` verdict block + Bash-withheld
  paragraph into `cwf-agent-shared-rules.md` and de-dup the five changeset
  reviewers.
- BACKLOG (carried, Task 209): align `best-practice-resolve` relevance so it stops
  matching off-domain corpora for non-matching tasks.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-22
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Plans + execution: `implementation-guide/210-feature-exec-changeset-reviewer-agents/` (a–j)
- Checkpoint commits: f `8e97216`, g `b9070c0`, h `21628d9`, i `7e3a3aa`
- Tests: `t/exec-changeset-reviewers.t`; full suite 882 green
- Baseline commit: `9972522` (Task 209)
