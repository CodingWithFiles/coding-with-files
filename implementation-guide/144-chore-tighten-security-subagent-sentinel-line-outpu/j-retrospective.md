# Tighten security-subagent sentinel-line output - Retrospective
**Task**: 144 (chore)

## Task Reference
- **Task ID**: internal-144
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/144-tighten-security-subagent-sentinel-line-output
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-16

## Executive Summary
- **Duration**: 1 session, well under the <0.5-day estimate. No
  variance worth quoting at this granularity.
- **Scope**: Original scope was a single paragraph edit in
  `.claude/agents/cwf-security-reviewer-changeset.md`. Final scope
  added (1) a hash-ledger update in
  `.cwf/security/script-hashes.json` to track the new bytes, and
  (2) status-field corrections in three of this task's own wf step
  files (a/d/e) where the planning skill suggested the non-canonical
  value "Planning" — both consequences of the edit, not scope creep
  on the task's purpose.
- **Outcome**: Success. Tightened wording landed, sentinel-token
  contract preserved, classifier untouched, and the dogfood
  invocation against this task's own changeset classified `no
  findings` via the **primary** rule (n=2: once at f-phase, once at
  g-phase). This is the single positive observation called for in
  e-testing-plan TC-7. A larger n is the subject of a separate
  backlog item, not this task.

## Variance Analysis
### Time and Effort
- **Estimated**: <0.5 days total (a/d/e/f/g/j).
- **Actual**: 1 session, well under that budget. Phase split
  roughly: planning (~30 min for a+d+e), implementation (<5 min for
  f's one edit), testing (~20 min including remediation), retro
  (this file).
- **Variance**: Negligible. The task was deliberately scoped small
  and stayed small.

### Scope Changes
- **Additions**:
  - `chmod 0444 + sha256sum + ledger update` on the edited agent
    file. Mandatory as a consequence of the intentional content
    change — surfaced by `cwf-manage validate`, not by the plan.
  - `chmod 0444` on 6 pre-existing files (4 plan-reviewer agents +
    1 shared-rules doc) — flagged by the same validate run but as
    pre-existing install-time damage, not caused by this task.
    User-approved local-mode fix; root cause stays open as the
    pre-existing backlog item "Install-time chmod 0444 on
    data/agents files".
  - Status-field corrections in a/d/e from `Planning` → `Finished`.
    "Planning" isn't a value in `cwf-project.json` ‐ it was
    suggested by my own first pass during the planning skills.
- **Removals**: None.
- **Impact**: All three additions are bookkeeping. The actual
  edit-of-intent is still a single paragraph in a single file.

### Quality Metrics
- **Test Coverage**: 7/7 test cases PASS. No executable code; no
  line-coverage metric applicable. Static-grep checks cover every
  behavioural surface of the agent file.
- **Defect Rate**: 0 defects introduced. The validate-run findings
  are *integrity-ledger drift* (expected when content changes
  intentionally) and *pre-existing install-time perms* (out of
  scope), not defects in the task's diff.
- **Performance**: N/A.

## What Went Well

- **Plan-then-edit discipline paid off.** The d-plan paragraph
  draft was used almost verbatim in f-exec; no last-minute
  rewrites. Worth keeping for prompt-tightening tasks where the
  whole task *is* the wording.
- **Primary-rule classification confirmed on first attempt.** The
  agent returned `no findings` as the literal first line on both
  the f-phase and g-phase security-review invocations. This is the
  exact failure mode Task 123's retrospective and the backlog entry
  named — the tightened prompt fixed it for n=2/2. (Caveat: same
  task's own diff, same subagent instance, low statistical weight.)
- **"Surface, don't smooth" feedback rule applied cleanly when
  validate fired.** Rather than auto-running `cwf-manage
  fix-security` (which would have hidden both the legitimate hash
  bump and the pre-existing perm violations under a single
  remediation), each item was triaged separately and the user
  approved each remediation explicitly. Pre-existing perms went to
  local chmod; SHA bump went to a targeted ledger edit; status
  values got corrected at the source.

## What Could Be Improved

- **Stale "Planning" status crept in three times.** I used
  `**Status**: Planning` in a-, d-, and e- before remembering that
  the canonical set in `cwf-project.json` is
  `Backlog/Blocked/Cancelled/Finished/In Progress/Skipped/Testing/To-Do`.
  Validate caught it, but the rework was unnecessary — the
  planning skills should not have suggested "Planning". Worth a
  backlog item to either (i) name "Planning" as a canonical value
  in `cwf-project.json` or (ii) tighten the skill prompts so they
  default to a canonical value.
- **Agent-registry session-restart drag.** Both the d-plan
  reviewers and the f-phase security-review were initially blocked
  by "Agent type … not found" — the `.claude/agents/` files exist
  on disk (Task 143 added them) but weren't registered in the
  pre-restart session. Required a manual session restart between
  the d-plan-review attempt (skipped per failure-handling rule) and
  the f-phase security review. The pre-existing backlog item
  "Session-restart smoke-test helper for newly installed agents"
  already names this; nothing to add.
- **Local chmod 0444 on pre-existing files is plaster, not a cure.**
  The 6 perm violations on `.claude/agents/cwf-plan-reviewer-*.md`
  and `cwf-agent-shared-rules.md` came back as 0600 because the
  install path doesn't set 0444. The local chmod made `validate`
  pass; the next install / subtree-pull will re-strip the modes.
  Backlog item "Install-time chmod 0444 on data/agents files
  (avoid post-install fix-security)" exists; mention reinforced
  here.

## Key Learnings

### Technical Insights
- The `cwf-security-reviewer-changeset` agent did comply with a
  tightened sentinel instruction once strengthened with **explicit
  failure-mode framing** ("a preface causes the SKILL to fall
  through to its conservative fallback and label a clean review as
  `findings`"). The old wording said *what to do*; the new wording
  says *what to do and why doing otherwise breaks the calling
  SKILL*. Worth carrying forward: subagent prompts comply better
  when they're told what they break by deviating, not just what
  they should emit.
- The Edit tool re-writes files with default umask, which on this
  machine yields 0600. Any read-only file in
  `.cwf/security/script-hashes.json` that gets edited via the Edit
  tool will trigger a permission-mismatch in validate until the
  user explicitly re-chmods.

### Process Learnings
- "Surface, don't smooth" is easier to honour when there's a
  per-issue triage step instead of a single yes/no on the whole
  validate result. The `AskUserQuestion` two-question split (SHA
  vs perms) was the right shape — neither was conflated with the
  other.
- For wording-only tasks, the test plan reasonably stops at static
  greps + one dogfood. Adding test-framework scaffolding would have
  been pure cost. The 6 static checks + 1 behavioural observation
  cover the whole behavioural surface.

### Risk Mitigation Strategies
- The d-plan named the worst-case mitigation ("Treat the
  conservative-default classifier as the durable guarantee; do not
  weaken it") explicitly before the edit. Even if the wording
  hadn't worked, the worst case was identical to the pre-task
  baseline. Pre-naming the worst case made the small-step risk
  decision easy.

## Recommendations

### Process Improvements
- Add `Planning` (or whatever the canonical name is) to the
  `cwf-project.json` `status-values` map, **or** patch the
  planning-phase skills (`cwf-task-plan`, `cwf-implementation-plan`,
  `cwf-testing-plan`) to default their suggested
  intermediate-status value to one already in the canonical set
  (e.g. `In Progress`). Either fixes the recurring micro-rework.
- Captured as a new backlog item below.

### Tool and Technique Recommendations
- For future subagent-prompt tasks: name the failure mode the
  wording is meant to suppress, not just the desired output. Both
  this task's wording and the Task 141 attempted prompt ("Your
  VERY FIRST CHARACTER…" + unacceptable-opener list) follow this
  shape, and this one worked at n=2.

### Future Work
- Backlog: `Planning` is not a canonical status value but is
  suggested by planning-phase skill templates — fix one or the
  other.
- Existing backlog (no new entry): "Install-time chmod 0444 on
  data/agents files" continues to bite at validate time. Mention
  in this retrospective as a recurring tax that's already tracked.
- Existing backlog (no new entry): "Session-restart smoke-test
  helper for newly installed agents" — hit again here.
- Existing backlog (no new entry): "Enforce sentinel-first output
  in security-review subagent prompt" — separate, broader-scope
  follow-up to this task (single-token sentinels). Not retired by
  this task; the wording-only fix is the lesser of the two
  follow-ups.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-16
**Sign-off**: the maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`
- Execution: `f-implementation-exec.md`, `g-testing-exec.md`
- Commits on this branch (pre-squash): `dd18144` (a), `72d84e2` (d), `ed0eed3` (e), `5655144` (f), `d726060` (g)
- Subagent dogfood evidence: § "Security Review" in `f-implementation-exec.md` and `g-testing-exec.md`
