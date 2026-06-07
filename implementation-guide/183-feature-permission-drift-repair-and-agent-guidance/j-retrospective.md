# Permission-drift repair and agent guidance - Retrospective
**Task**: 183 (feature)

## Task Reference
- **Task ID**: internal-183
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/183-permission-drift-repair-and-agent-guidance
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-07

## Executive Summary
- **Duration**: ~1 day across two sessions — planning a–e in a prior session (with the full
  4-agent plan-review panel at b/c/d), exec f–j in this session after a user plan review.
  On estimate (Low–Medium).
- **Scope**: Delivered as planned, and narrower in code than a naive reading of the title implies:
  the repair engine (`cwf-manage fix-security`) already existed, so the task became a docs-only
  guidance change plus a behavioural demonstration — no new code, no `cwf-manage` surface, no hash
  refresh.
- **Outcome**: Success. A standing fix-on-sight rule now lives in `hash-updates.md`, reinforced at
  the checkpoint friction point and indexed from `CLAUDE.md`, with the perm-vs-sha256 boundary
  drawn explicitly. The Task-173 backlog item is retired as superseded.

## Variance Analysis
### Time and Effort
- **Estimated**: ~1 day total (Low–Medium); care concentrated in the guidance boundary, not volume.
- **Actual**: roughly on estimate. Planning carried most of the thinking (three plan-review gates,
  two requirement re-specifications); exec was fast because it was three Markdown edits plus
  verification.
- **Variance**: negligible. The plan-phase investment (confirming `fix-security` is clamp-only and
  that all three target docs are non-hash-tracked) made exec almost mechanical.

### Scope Changes
- **Additions**: none during exec.
- **Removals/Deferrals**: the FR1 "repair sweep" was effectively a **no-op** at exec time — drift
  had already been cleared (Task-174 clamped the original three scripts; the planning-phase clamp
  cleared two residual Task-182 files). The mechanism was therefore demonstrated via FR6/TC-REPRO
  (induce-then-fix) rather than by a live sweep. The Task-173 backlog retire was deliberately
  deferred from f to j by design (D7), executed in this phase.
- **Impact**: net simpler and lower-risk than first framed — the title says "repair", but the
  durable deliverable is guidance + boundary.

### Quality Metrics
- **Test Coverage**: every now-verifiable AC has a passing deterministic check — TC-SWEEP, TC-RULE,
  TC-BOUNDARY, TC-POINTERS, TC-XREF, TC-NOSURFACE, TC-REPRO, TC-VALIDATE all PASS; TC-RETIRE
  executed at j.
- **Defect Rate**: zero defects in exec. Three planning-phase corrections (caught by reviewers):
  FR2 originally named a non-existent `CLAUDE.md ## Critical Rules` landing site; the cross-ref form
  was wrong (`../` vs repo-rooted backtick); the "byte-identical command" target was underspecified.
- **Security**: both exec-phase reviews (`cwf-security-reviewer-changeset`) returned `no findings`.

## What Went Well
- **The rule proved itself before it was written.** During phase a, `cwf-manage validate` surfaced
  live permission drift on two Task-182 files; rather than defer it, the drift was clamped on sight
  — a real instance of the exact behaviour this task codifies.
- **Measure-twice paid off.** Confirming `fix-security` is clamp-only and that the three docs are
  non-hash-tracked, *before* committing to the plan, meant the whole task touched zero hash-tracked
  files and needed no `script-hashes.json` refresh.
- **TC-REPRO grounded an abstract claim.** The induce-drift→fix run produced the validate `Fix:`
  line live, which turned out byte-identical to the command quoted in all three docs — verifying
  AC2 against real tool output, not just source inspection.
- **Boundary held under adversarial review.** Both security reviews specifically checked for a new
  validate-silencing surface and confirmed none was added; the sha256 "surface, never smooth"
  guarantee is intact.

## What Could Be Improved
- **Title vs deliverable mismatch.** "Permission-drift repair" implied code; the real work was
  guidance. Naming the task for its durable artefact (the rule + boundary) would have set
  expectations better up front.
- **The FR1 sweep was a no-op risk not flagged at task creation.** It only became clear during
  planning that the drift was already cleared. A quick `fix-security --dry-run` at task-creation
  time would have reframed the task as "guidance + demonstration" from the start.

## Key Learnings
### Technical Insights
- The permission-clamp vs content-hash distinction is the security spine: clamping is monotone
  (can only clear bits), so it is uniquely safe to auto-apply; content drift is never auto-absorbed.
  Encoding that asymmetry as the explicit boundary is what makes "fix permissions promptly" safe
  to say without inviting "recompute hashes to quiet validate".
- Permission state is a working-tree property git does not record (`100755`/`100644`), so a clamp
  is not a committable diff — the guidance must promise a working-tree action, not a git-persisted
  fix, or it would be making a false promise.

### Process Learnings
- A no-op mechanical step plus a behavioural demonstration can be a complete, valuable task. The
  signal of success here is the *absence* of future deferred-drift backlog items, not lines changed.
- Plan-review caught a landing-site that did not exist (`## Critical Rules` is user-global, not in
  the repo). Verifying that a named anchor actually exists in a committed/installed file belongs in
  requirements, not exec.

### Risk Mitigation Strategies
- Scoping auto-repair strictly to clamping (R1, the one sharp risk) was handled as a wording
  boundary in the doc, reaffirmed by cross-reference to the existing "what NOT to build" section —
  no new mechanism, so no new attack surface.

## Recommendations
### Process Improvements
- At `/cwf-new-task` for a "repair X" task, run the relevant dry-run first to learn whether the
  repair is still needed; reframe to "guidance + demonstration" if the state is already clean.

### Tool and Technique Recommendations
- Continue using a live induce-then-fix demonstration (TC-REPRO style) when a feature's mechanical
  step is already a no-op — it exercises the real tool path and double-checks documented command
  strings against actual output.

### Future Work
- **D8 forward option (recorded in i-maintenance, not a new backlog item yet)**: if the deferral
  failure mode recurs in *consumer* repos — where the dev-repo `CLAUDE.md` pointer is not installed
  — add a one-line fix-on-sight pointer to the hash-tracked `claude-md-preamble.md`, accepting the
  hash refresh. Trigger: an observed consumer-repo recurrence. Not actioned now (no evidence needed).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-07
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, b-requirements-plan.md, c-design-plan.md, d-implementation-plan.md, e-testing-plan.md
- Execution: f-implementation-exec.md (commit 6f05c0d), g-testing-exec.md (commit c753026)
- Rollout/Maintenance: h-rollout.md (ac60080), i-maintenance.md (853af31)
- Deliverable edits: `.cwf/docs/conventions/hash-updates.md`, `.cwf/docs/skills/checkpoint-commit.md`, `CLAUDE.md`
