# Assess harness worktree tools vs CWF code - Retrospective
**Task**: 177 (discovery)

## Task Reference
- **Task ID**: internal-177
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/177-assess-harness-worktree-tools-vs-cwf-code
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-03

## Executive Summary
- **Duration**: <1 day (estimated: <1 day; on estimate).
- **Scope**: Original scope — verify the harness worktree-tool claims behind the
  "Adopt guarded EnterWorktree/ExitWorktree" backlog item against current schemas
  and CWF code, then rewrite the item. Final scope added claim **C6** (the actual
  worktree-usage surface) mid-planning after an operator clarification. Deliverable
  scope unchanged: cited findings + one rewritten backlog entry, no production code.
- **Outcome**: Success. C1–C4 Confirmed against live schemas, C5 Refuted, C6
  Confirmed; backlog item reframed (not retired) around the real gap. Both exec
  security reviews `no findings`; TC-1…TC-6 all PASS.

## Variance Analysis
### Time and Effort
- **Estimated**: <1 day total (Low complexity; read/verify/document, no code).
- **Actual**: <1 day. Planning a–e and exec f/g all completed in one working
  session, plus one mid-planning revision pass (commit `b07e787`).
- **Variance**: On estimate. The one unplanned cost was re-deriving the plans after
  the scope clarification — absorbed within the day.

### Scope Changes
- **Additions**:
  - **Claim C6 (usage surface)** — added after the operator clarified that
    worktrees *are* used with CWF (knowingly and via the model self-initiating raw
    `git worktree add`), even though no scripted flow exists. This converted a
    Refuted-C5 "nothing to do" reading into "define a guarded process", and
    promoted C1 from moot to the crux. Drove a b/c/d/e revision (`b07e787`).
- **Removals**: None. The conditional C2 removal probe (design Decision 4) was
  planned as skip-by-default and was correctly skipped — not a descope.
- **Impact**: The addition changed the *framing* of the deliverable, not its size;
  no timeline impact beyond the revision pass.

### Quality Metrics
- **Test Coverage**: 100% of the e-testing-plan critical path — every claim C1–C6
  cited; single live backlog entry confirmed. TC-1…TC-6 + non-functional PASS.
- **Defect Rate**: No defects (no production code). One pre-existing false claim in
  the *old* backlog body (the `task-workflow.d/delete` "raw flow" example) was the
  discovery's main finding and is corrected.
- **Performance**: N/A (documentation task).

## What Went Well
- **Schema-as-evidence discipline.** Resolving C1–C4 from verbatim `ToolSearch`
  schema fragments (rather than Task-172 memory) replaced inference with citation
  and directly satisfied `feedback_no_fabricated_citations`.
- **Refusing the unsafe probe.** Design Decision 4 correctly identified that the
  only C2-exercising path (`EnterWorktree`) switches CWD and is gated, so no probe
  was run; the residual was logged as Unverifiable-by-safe-probe rather than
  smoothed into a false Confirmed. Honoured `feedback_worktree_cwd_dataloss` and
  `feedback_surface_security_dont_smooth`.
- **The plan-review caught the framing error early.** The C5-Refuted "retire?"
  reading was corrected into "reframe" before exec, so the backlog rewrite landed
  right the first time.
- **Re-derived inventory beat the remembered figure.** A fresh grep showed 6 actual
  `--show-toplevel` sites, not the stale "13" — exactly the rebrand/output-level
  verification habit the memory bank warns about.

## What Could Be Improved
- **The scope clarification should have surfaced in planning, not after.** The C6
  insight (worktrees used via model self-initiation) is the whole justification for
  the feature; it only emerged when the operator corrected a "nothing to guard"
  framing. A sharper a/b-phase question ("how are worktrees used with CWF *today*,
  not just in its scripts?") would have produced C6 without the revision pass.
- **Discovery percentage display oddity.** `workflow-manager status` showed the task
  at 25% with 7/8 phases Finished; the aggregate figure is confusing for the
  discovery step set. Cosmetic, but worth a glance.

## Key Learnings
### Technical Insights
- **The guard is `EnterWorktree`-scoped, and that is the design constraint.**
  `ExitWorktree` is a no-op on raw-`add` worktrees, so the only way CWF gets the
  uncommitted-changes refusal is to *create* via `EnterWorktree`. Any future process
  that wants the guard cannot bolt it onto existing raw git.
- **`worktree.baseRef` defaults to `fresh` (origin/default)** — directly conflicts
  with CWF's branch-off-HEAD rule; the feature must set `head`.
- **The deferred+gated status is a feature, not a blocker.** The gate is satisfiable
  by "project instructions (CLAUDE.md/memory)", so a documented CWF worktree process
  *is* the authorisation that legitimises automated use.

### Process Learnings
- **"Refuted ≠ nothing to do."** A falsified premise (C5) can still leave a real
  gap (C6). Separating the harness-behaviour verdict from the relevance-to-CWF axis
  (design Decision 2) is what kept a dead premise from killing a live feature.
- **Operator clarification is a first-class planning input.** The single most
  valuable steer (C6) came from a one-line correction; building the AskUserQuestion
  checkpoint into planning paid for itself.

### Risk Mitigation Strategies
- Scratch-file-first + `--body-file` + single-live-entry assertion made the only
  durable mutation (the backlog rewrite) safe and reversible; the delete+add
  partial-failure path was planned for even though it didn't fire.

## Recommendations
### Process Improvements
- In discovery/requirements phases that assess "does CWF do X", explicitly ask "and
  how is X done *with* CWF today by the operator or the model?" — code inventory
  alone misses model/operator-initiated usage (the C5-vs-C6 gap here).

### Tool and Technique Recommendations
- Keep using verbatim `ToolSearch` schema fragments as the citation of record for
  harness-behaviour claims; they proved more reliable than carried-over inference.

### Future Work
- The reframed backlog item **"Adopt guarded EnterWorktree/ExitWorktree as CWF's
  defined worktree process"** is ready to plan as a feature. Two carry-forward notes
  for that task:
  1. Confirm the C2 removal-refusal behaviour the first time `EnterWorktree` is
     wired in (against scratch-only content) — the runtime residual this discovery
     left Unverifiable-by-safe-probe.
  2. Both security reviews flagged a forward-looking (e) pattern: the feature's own
     security review must confirm a skill does not treat a standing process document
     as blanket pre-authorisation to auto-remove worktrees — keep the
     `discard_changes` refusal gate intact.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None
**Completion Date**: 2026-06-03
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`, `b-requirements-plan.md`, `c-design-plan.md`,
  `d-implementation-plan.md`, `e-testing-plan.md`.
- Findings: `f-implementation-exec.md` (claims table, inventory, C6 surface, FR5,
  both security reviews).
- Verification: `g-testing-exec.md` (TC-1…TC-6).
- Key commits: `b07e787` (scope-clarification revision), `d792665` (f-exec +
  backlog rewrite), `9edf6fe` (g-testing-exec).
- Deliverable: rewritten `BACKLOG.md` entry "Adopt guarded EnterWorktree/ExitWorktree
  as CWF's defined worktree process".
