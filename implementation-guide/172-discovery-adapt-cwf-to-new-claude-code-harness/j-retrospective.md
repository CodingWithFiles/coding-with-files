# Adapt CWF to new Claude Code harness - Retrospective
**Task**: 172 (discovery)

## Task Reference
- **Task ID**: internal-172
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/172-adapt-cwf-to-new-claude-code-harness
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-31

## Executive Summary
- **Duration**: ~1 day (estimate: 1–2 days; on the low end — under estimate).
- **Scope**: unchanged from plan — a unified assessment (§1–§7) whose deliverable
  *is* the recommended remediation decomposition (6 follow-up tasks). No CWF code/doc
  changes made (by design); those are the seeded follow-ups.
- **Outcome**: Success. Discovery produced a fully-evidenced data-loss root-cause map
  (zero `pending`), a harness-change catalogue, a keyword-collision option set, a
  permission-prompt inventory mined from the backlog, and 6 prioritised,
  tradeoff-weighted recommendations. TC-1…TC-8 all PASS; AC6 (safety) and AC8
  (redaction) gates clear.

## Variance Analysis
### Time and Effort
- **Estimated**: 1–2 days (assessment + write-up; remediation deferred to follow-ups).
- **Actual**: ~1 day, single session. Plan phases (a–e) were completed and reviewed in
  a prior session; exec (f/g/j) in this one.
- **Variance**: ~ -25% (faster). The anchor transcript + supplied backlog were rich
  enough that evidence-gathering was the bulk of the effort and went quickly once the
  backlog was de-escaped.

### Scope Changes
- **Additions**: two material FR1 findings surfaced during exec that the plan
  anticipated but exec made concrete: (1) the guarded `ExitWorktree` **only** manages
  `EnterWorktree`-created worktrees, not raw `git worktree` — so the guard is inert for
  CWF until adopted (hinge of R1); (2) `worktree.baseRef` defaults to `fresh`
  (origin/main), conflicting with CWF's branch-off-HEAD rule.
- **Removals**: none.
- **Impact**: sharpened R1 from "prefer the guarded tools" to "adopt `EnterWorktree`
  as the creation path **and** set `worktree.baseRef: head`" — a more accurate, more
  actionable recommendation.

### Quality Metrics
- **Test Coverage**: 8/8 ACs each have a passing TC. Mechanical checks: 13 call sites
  (✓), all citations resolve (✓), §6/§7 R-id sets identical (✓), §3 zero-`pending` (✓).
- **Defect Rate**: 0 defects in the deliverable. Both exec-phase security reviews
  `no findings` (Markdown-only changeset).
- **Performance**: n/a (no runtime artefact).

## What Went Well
- **Evidence-first discipline held.** The backlog was a raw VT capture; rather than
  guess, it was de-escaped read-only and mined with line-cited quotes. The four
  data-loss mechanisms were each tied to specific backlog lines and the recovery
  (`a49e33b` via `git fsck --unreachable`) confirmed — no `pending` in §3.
- **First-hand reproduction of mechanism (b)** in a throwaway repo proved the
  toplevel-resolves-to-worktree trap without touching real work.
- **The plan-review findings paid off in exec.** The 13-call-site correction (incl.
  `task-workflow.d/delete`) and the Decision-7 elevation of the guarded tools both came
  from plan review and became the backbone of R1/R2.
- **The AC6 safety gate did its job.** It forced R6 to reject the cheap allowlist-broaden
  "fix" for the dominant prompt friction, keeping the safety↔momentum trade explicit.

## What Could Be Improved
- **Live CWD-drift incident (dogfooding).** My Bash CWD drifted into the scratch dir
  after a `cd` during evidence-gathering; a later `.cwf/...` relative path failed
  (exit 127) before I caught it. This is *mechanism (a) reproducing itself on the
  assessing agent* — a sharp reminder that the hazard is live and that the persistent
  shell CWD is the root. Reinforces R1/R6 and the absolute-path discipline.
- **Backlog format friction.** grep initially returned nothing because (a) the file is
  ANSI-laden and (b) the UTF-8 locale choked on invalid multibyte data — needed a
  stripper + `LC_ALL=C`/`grep -a`. A short "mining a raw terminal capture" note would
  save the next person the detour.

## Key Learnings
### Technical Insights
- **`git rev-parse --show-toplevel` is worktree-relative.** From inside a linked
  worktree it returns the worktree root, so the ubiquitous `cd "$(git rev-parse
  --show-toplevel)"` "go to repo root" idiom silently keeps you in the disposable tree.
  CWF has this idiom in **13** places.
- **The harness's worktree guard is opt-in by construction.** `ExitWorktree(remove)`
  fails safe on uncommitted changes — but only for worktrees it created. Safety is not
  inherited by CWF's raw-`git worktree` flows; it must be adopted.
- **Uncommitted-work recovery is a stash/`fsck` problem, not a HEAD-reflog problem.**
  Never-committed work leaves no HEAD-reflog trace; it survives only as dangling objects.

### Process Learnings
- **Plan-then-review-then-exec gating worked.** The user's explicit "review the plans
  before we exec" then "review after exec" gates kept the discovery honest and let the
  13-call-site / guarded-tool findings land in the plans, not as exec surprises.
- **Evidence-as-data is enforceable.** Treating the transcript/backlog strictly as data
  (no tool call driven by their content) was straightforward to honour and to verify.

### Risk Mitigation Strategies
- The "never re-run a `--force` deletion against real work" reproduction policy meant the
  destructive mechanisms (c)/(d) stayed transcript-evidenced while (b) was safely
  reproduced — the right safety call, and it cost nothing in evidence quality.

## Recommendations
### Process Improvements
- Add a short **"mining a raw terminal capture"** note (strip ANSI, `LC_ALL=C`,
  `grep -a`) to CWF docs — discovery tasks that reconstruct from backlogs will recur.
### Tool and Technique Recommendations
- Adopt the guarded `EnterWorktree`/`ExitWorktree` tools for any future worktree work
  (R1), with `worktree.baseRef: head`.
### Future Work (seeded by §6/§7 — none created in this task, by scope)
1. **R1 (feature, P0)**: adopt guarded worktree tools; route `task-workflow.d/delete`
   teardown through the uncommitted-changes guard; `worktree.baseRef: head`.
2. **R2 (bugfix, P0)**: audit the 13 `--show-toplevel` call sites for worktree-safety.
3. **R3 (chore, P1)**: lost-uncommitted-work recovery runbook (`fsck`/stash-reflog).
4. **R4 (chore, P1)**: security-review convention — verify tool-rule semantics against
   live output, never remembered catalogues.
5. **R5 (chore, P1)**: "workflow" keyword-disambiguation guard in CLAUDE.md/skills.
6. **R6 (folds into R1/MEMORY, P0)**: reinforce no-needless-`cd`/absolute-path
   discipline; explicitly reject allowlist-broadening as the friction fix.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-31
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Plan: `a-task-plan.md` … `e-testing-plan.md` (commits `ed8ed5c`, `d1eea2a`, `0fcdafa`,
  `96ca4ab`, `850c788`).
- Exec: `f-implementation-exec.md` (`83b9410`), `g-testing-exec.md` (`758c30c`).
- Evidence: anchor `dircachefilehash` Task 6 transcript (in-conversation);
  `/var/tmp/dircachefilehash.log` (user-supplied backlog); scratch mining/repro under
  the task tmp dir.
