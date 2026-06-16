# Simplify best-practice review to doc pointers - Retrospective
**Task**: 207 (chore)

## Task Reference
- **Task ID**: internal-207
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/207-simplify-best-practice-review-to-pointers
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-16

## Executive Summary
- **Duration**: ~0.5 day actual vs ~0.5 day estimated (≈0% variance), but with a
  mid-task re-scope that roughly doubled the implementation cut.
- **Scope**: Planned to slim the resolver to a tag-matched **path list** (keeping
  realpath confinement). Final scope went further — the resolver hands the
  reviewer the `documentation` path **verbatim**, with confinement, existence
  checks, dedup and the file-vs-dir distinction all removed.
- **Outcome**: Success. Resolver 612 → ~290 lines; URL/SSRF/inlining/sentinel/
  byte-cap/dir-walk surface gone; suite green (866/72); `cwf-manage validate: OK`.
  One advisory security finding (confinement removal) surfaced and accepted.

## Variance Analysis
### Time and Effort
- **Estimated** (chore phases only):
  - Planning (a): minor
  - Implementation plan (d): minor
  - Testing plan (e): minor
  - Implementation (f): bulk of effort
  - Testing (g): minor
- **Actual**: As estimated in total, but f absorbed two implementation passes —
  the planned path-list rewrite, then a second verbatim-path rewrite driven by
  exec review. The second pass was net deletion, so it cost less than the first.
- **Variance**: Total effort ≈ on estimate. The re-scope did not blow the budget
  because each iteration removed more than it added.

### Scope Changes
- **Additions**: None.
- **Removals** (beyond the plan):
  - Realpath confinement of project-config paths — the one security property
    a-task-plan explicitly flagged to **retain** was deliberately dropped after
    the maintainer judged it unnecessary for a read-only advisory feature.
  - Per-path existence check, `%SEEN_PATH` dedup, the file-vs-dir distinction,
    and the `### DOCS`/`### SKIPPED` catalog — all cut in the verbatim revision.
- **Impact**: Smaller, simpler resolver; the project-vs-user trust distinction
  collapsed (documented). The consumer contract (exit code + count line + `.out`)
  was held stable throughout, so no SKILL/`plan-review.md` churn.

### Quality Metrics
- **Test Coverage**: `t/best-practice-resolve.t` rewritten to 13 verbatim-emission
  subtests; full suite 866 tests / 72 files green; `skill-anchor-drift.t` green.
- **Defect Rate**: 0 defects found in testing; 0 regressions.
- **Integrity**: `cwf-manage validate: OK` after same-commit hash refresh for the
  3 tracked files (resolver + 2 agent defs).

## What Went Well
- **Stable consumer contract.** Holding the exit-code / count-line / `.out`
  interface fixed meant a large internal rewrite (twice) touched no SKILLs and
  no `plan-review.md` — the blast radius stayed inside the resolver and tests.
- **Net-deletion task.** Almost every change removed code; the security posture
  *improved* on the dimensions that mattered (SSRF, content inlining, WebFetch).
- **"Surface, don't smooth" held.** The changeset cap fired (552 then 650 > 500);
  the security reviewer was still run on the full changeset rather than recording
  a bare `error`, and the confinement-removal finding was surfaced, not buried.

## What Could Be Improved
- **The barest design should have been the first design.** The plan retained a
  path list with confinement; exec review cut it to verbatim paths. That second
  cut was foreseeable at design time — the goal was already "smallest moving
  part" (a-task-plan Constraints). One review round was spent discovering it.
- **A "retain this property" plan note got overturned mid-task.** Confinement was
  a named high-priority risk mitigation, then deliberately removed. That is a
  legitimate outcome (the maintainer owns the call), but it shows a plan-time
  security assumption that hadn't been pressure-tested against "who is the
  attacker, and what can a read-only reviewer actually do with a bad path?".

## Key Learnings
### Technical Insights
- Once the helper stopped *transforming* the path, the tests got simpler and more
  robust — verbatim `^- <tags>: <path>$` assertions have no realpath/platform
  sensitivity, unlike the earlier path-presence checks.
- Removing the directory walk also removed the only place that could observe an
  empty directory — "empty dir" stopped being a resolver concern and became a
  reviewer/Glob concern. Deleting a code path can delete a whole class of edge
  case with it.
- Confinement removal is safe **only** under a load-bearing invariant: the
  reviewer agents are `Read, Grep, Glob, LSP` only. If any best-practice reviewer
  ever gains a write/exec/network tool — or the `.out` feeds a different consumer,
  or the feature gates the workflow — an unconfined project `best-practices.json`
  (arrivable via a PR) becomes an arbitrary-read/exfiltration primitive, and
  confinement must be restored. Recorded in `best-practice-review.md` § Limitations.

### Process Learnings
- For a removal-heavy task, bias the **design** phase toward the most aggressive
  cut and justify anything kept, rather than carrying a moderate cut into exec
  and discovering the aggressive one there.
- Agent-definition edits are session-cached: the reviewer behaviour change (no
  WebFetch, read docs directly) could not be live-verified this session.
  **Fresh-session verification of both reviewer agents is the one open item.**

### Risk Mitigation Strategies
- Same-commit hash refresh + `cwf-manage validate` before finishing exec caught
  no drift — the discipline worked as a guard, not a fix.
- Surfacing the cap and the confinement finding (rather than smoothing either)
  kept the security decision with the human who owned the simplification.

## Recommendations
### Process Improvements
- When a task is "simplify X", have the design phase state the *minimal* end
  state explicitly and require justification for each retained mechanism — this
  would have collapsed the two implementation passes into one.
- Treat any plan note of the form "retain security property P" as a prompt to
  write down P's threat model in the plan, so a later decision to drop P is made
  against the same model rather than ad hoc.

### Tool and Technique Recommendations
- The verbatim-line `.out` format (`- <tags>: <path>`) is a good template for
  future "hand the agent a pointer, let it do the rest" helpers — minimal helper,
  maximal agent agency.

### Future Work
- **Fresh-session verification of the two reviewer agents** (changeset + plan):
  confirm they have no WebFetch, Read the listed paths directly, and emit the
  fail-closed `error` on an unreadable source. Session-cached defs prevented this
  here. Low effort; verification only.
- If a best-practice reviewer ever needs a non-read capability, **restore
  project-path confinement** in the resolver first (see § Key Learnings).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-16
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`
- Implementation: `d-implementation-plan.md`, `f-implementation-exec.md`
  (incl. § Revision — verbatim-path cut)
- Testing: `e-testing-plan.md`, `g-testing-exec.md`
- Commits (task branch): `a5c533f` (f), `e1e0e54` (g), `c9e2ea2` (verbatim revision)
- Changed surface: `.cwf/scripts/command-helpers/best-practice-resolve`,
  `.claude/agents/cwf-best-practice-reviewer-changeset.md`,
  `.claude/agents/cwf-plan-reviewer-best-practice.md`,
  `.cwf/docs/skills/best-practice-review.md`, `t/best-practice-resolve.t`,
  `.cwf/security/script-hashes.json`, `CHANGELOG.md`
