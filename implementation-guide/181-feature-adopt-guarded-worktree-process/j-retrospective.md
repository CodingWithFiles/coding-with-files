# Adopt guarded worktree enter/exit process - Retrospective
**Task**: 181 (feature)

## Task Reference
- **Task ID**: internal-181
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/181-adopt-guarded-worktree-process
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-06

## Executive Summary
- **Duration**: ~1 day (estimated: ~1 day; variance: ~0%).
- **Scope**: Delivered the planned guarded worktree process (doc + `worktree.baseRef: head`
  + cross-links + FR8 probe) **plus** one mid-stream operator-requested addition: the FR9
  two-touchpoint `git worktree` allowlist detector. Final scope > original, by request.
- **Outcome**: Success. All 10 gating ACs met; 11/11 test cases pass; both security
  reviews `no findings`; the C2 refusal and HEAD-base behaviour confirmed live.

## Variance Analysis
### Time and Effort
- **Estimated** (a-task-plan): ~1 day overall, doc-primary, Medium complexity.
- **Actual**: ~1 day. Planning a–e in a prior session (incl. an FR9 refinement round and
  a 4-agent design re-review); exec f–j in this session.
- **Variance**: ~0% on time. Effort skewed more to *review/verification* than authoring —
  the FR9 robustness analysis (must-not-abort) and the live data-loss-class probe took
  more care than the prose did.

### Scope Changes
- **Additions**:
  - **FR9 detector** (mid-stream, operator-requested): generalised the one-off
    `Bash(git worktree *)` removal into a recurring detect-and-warn at install/update
    (in `cwf-claude-settings-merge`) and at worktree usage (doc pre-flight). This turned
    the task from doc-only into doc + one hash-tracked helper edit.
  - **`Configuration` doc section** (impl-time): a dedicated home for the FR3
    `baseRef: head` mandate + user-global fallback wording (design folded it into prose).
- **Removals/Deferrals**: none descoped. FR7 MEMORY pointer (out-of-repo, non-gating) and
  the FR8 probe were always planned for rollout/g respectively, not deferrals.
- **Impact**: +1 hash-tracked artefact touched (disclosed at plan time); no schedule slip.

### Quality Metrics
- **Test Coverage**: 11/11 TCs PASS (AC1–AC10 fully covered). FR9 detector exercised via
  6 fixture sub-cases; FR8 C2 refusal observed live.
- **Defect Rate**: 0 defects found in testing or review.
- **Performance**: N/A by NFR1 (one doc + one settings key; two best-effort reads at
  install time).

## What Went Well
- **The live probe paid off twice.** Running TC-8 under the safety envelope not only
  confirmed the C2 refusal (AC8) but *resolved the design Decision-3 open question* —
  the worktree based on current HEAD, proving the harness honours `worktree.baseRef` from
  **project** `settings.json` (the committed key is effective, not dead config).
- **Surfacing the data-loss-class step to the operator** before the live `EnterWorktree`
  was the right call and mirrors the feature's own "operator-surfaced teardown" doctrine.
- **The must-not-abort robustness analysis** (raw substring, no JSON decode, best-effort
  symlink-guarded reads) made the FR9 scan both the simplest and the safest design — it
  literally cannot fail an install/update, verified by fixture (TC-11.3/11.4).
- **Hash discipline held**: the one hashed helper was refreshed in-commit and restored to
  0500; `cwf-manage validate` stayed OK throughout; the helper's pre-existing perms drift
  cleared as a side effect.

## What Could Be Improved
- **The FR9 requirement arrived mid-stream**, forcing a design re-review and re-commit of
  four planning docs. Earlier elicitation ("what's the *general* fix, not just this one
  entry?") at requirements time would have avoided the churn.
- **A stale `settings.local.json:127` citation** propagated across plans because the
  operator removed the entry mid-session; caught by the design re-reviewers, but it shows
  how fast a concrete line-number citation goes stale.
- **The probe required a protective interim commit** mid-g to satisfy the clean-tree
  pre-check — a small friction inherent to dogfooding a CWD-switching tool.

## Key Learnings
### Technical Insights
- `worktree.baseRef: head` **is** honoured from project-scope `settings.json` on this
  harness (Opus 4.8) — confirmed behaviourally, not assumed. Recorded in
  `reference_worktree_process`.
- For a warning-only scan that runs inside an abort-on-non-zero caller
  (`run_settings_merge`), *not parsing* the input (raw substring) is more robust than
  parsing it — a malformed user file can't throw if you never decode it.
- The `EnterWorktree` guard is genuinely `EnterWorktree`-scoped (C1) and `ExitWorktree`
  genuinely refuses on uncommitted changes (C2) — both now first-hand confirmed, closing
  the Task 177 runtime residual.

### Process Learnings
- Mid-stream scope additions are cheaper to absorb when caught at requirements than at
  design/impl — push for the generalised requirement early.
- Concrete file:line citations in plans are fragile across sessions where the operator
  edits user-owned files; prefer citing the *class* of thing over a line number.

### Risk Mitigation Strategies
- The safety envelope (clean pre-check, no `cd`, scratch-only, never `discard_changes`,
  abort/rollback path) made a data-loss-class probe safe to run. Reusable pattern for any
  future `EnterWorktree` dogfooding.

## Recommendations
### Process Improvements
- When a one-off fix is requested, ask "is there a recurring class here?" before closing
  requirements — would have surfaced FR9 pre-planning.

### Tool and Technique Recommendations
- Standardise the worktree-probe safety envelope as the template for any live worktree
  test (it is now captured in the g-phase probe log and the convention doc).

### Future Work
- **R2 — audit the 13 `--show-toplevel` call sites** for worktree-safety (separate
  backlog item; out of scope here).
- **`pretooluse-planning-write-guard` perms-drift recurrence** — a separate Medium
  backlog item; the working-tree drift was restored this session but the recurrence
  source is unaddressed.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-06
**Sign-off**: The maintainer (CWF dogfooding)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning + exec docs: `implementation-guide/181-feature-adopt-guarded-worktree-process/a..j`
- Deliverable: `.cwf/docs/conventions/worktree-process.md`; config `.claude/settings.json`
  (`worktree.baseRef: head`); FR9 detector in `.cwf/scripts/command-helpers/cwf-claude-settings-merge`
- Memories: `reference_worktree_process`, updated `feedback_worktree_cwd_dataloss`
- Lineage: Task 172 (incident) → Task 177 (C1–C6 facts) → Task 181 (this adoption)
