# cwf-init dead UserPromptSubmit hook matcher - Retrospective
**Task**: 195 (bugfix)

## Task Reference
- **Task ID**: internal-195
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/195-cwf-init-dead-userpromptsubmit-hook-matcher
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-12

## Executive Summary
- **Duration**: <1 day (estimated: <1 day — on target). All phases a→j completed 2026-06-12.
- **Scope**: As planned — fix `/cwf-init` registering the rules-inject re-injection hook
  as a dead `PreToolUse` group whose `matcher == "UserPromptSubmit"` (a matcher that can
  never fire), plus migrate the dead entry on existing installs. One design-time
  correction to the *target shape* (see Variance) and one design decision to keep the
  D4 event-allowlist widening in-task rather than defer it.
- **Outcome**: Success. Registration moved into the deterministic
  `cwf-claude-settings-merge` helper; the hook now emits the correct top-level
  `UserPromptSubmit` group-wrapper; the dead entry is migrated matcher-scoped and
  surfaced in stdout. 41 helper subtests pass; both exec-phase security reviews returned
  no findings.

## Variance Analysis
### Time and Effort
- **Estimated**: <1 day total (Low complexity, self-contained).
- **Actual**: <1 day, all phases same day.
  - Planning / Design / Impl-plan / Test-plan: light (single-concern bugfix).
  - Implementation + Testing exec: the bulk — 7 edits to the helper, TC-UPS1–8, two
    regression-test updates, hash refresh, output-level smoke test.
- **Variance**: None material. Effort landed where expected (exec phases).

### Scope Changes
- **Correction (not addition)** — *target hook shape*: The original a-task-plan SC1
  specified "a **flat** hook-object array — no nested `hooks` wrapper". That mirrored the
  BACKLOG's proposed shape, which was **wrong**. Design (c) established that Claude Code's
  `UserPromptSubmit` event uses the same three-level group-wrapper
  (`[{ hooks: [ {type, command} ] }]`) as every other event — it ignores `matcher` but
  still nests under `hooks`. The implementation followed the corrected shape. Net: the
  bug was slightly deeper than the backlog framing implied (the flat-array "fix" would
  itself have been malformed).
- **D5 — keep-and-fix the hook** (resolved with user, 2026-06-12): register the working
  hook rather than merely prune the dead one. Kept in scope.
- **D4 — keep the event-allowlist widening in-task** (resolved with user, 2026-06-12):
  widen `read_hook_directives` to admit `UserPromptSubmit` (+ TC-UPS8) rather than defer,
  so a future directive-driven hook is not silently downgraded to `Stop`.
- **Addition — TC-U1/TC-U4 count update (1→2)**: not separately itemised in the plan, but
  a direct, expected consequence of the always-on hook (the rules-inject hook now
  registers on every run, like `env.PERL5OPT`), so the stdout hook-entry count rises. Not
  scope creep; an inevitable test-fixture update.
- **Removals**: none.

### Quality Metrics
- **Test Coverage**: Critical paths (fresh registration, migration, empty-key drop,
  idempotency, defensive guards) 100%. Helper suite `t/cwf-claude-settings-merge.t`:
  41 subtests, all PASS. Full `t/`: 749 tests, 748 PASS at exec time — the single failure
  was the in-flight `security-review-changeset.t` TC-VALIDATE assertion 3 (`validate exits
  0`), an artefact of the task's then-non-terminal plan statuses; **resolved by this
  retrospective's status sweep**.
- **Defect Rate**: 0 new defects introduced; 0 post-implementation rework.
- **Security**: two exec-phase reviews (f, g) — both **no findings**. The executed-command
  and env write paths stay bound to compile-time constants (FR4(e) preserved).

## What Went Well
- **Moving registration into the deterministic helper** removed the prose-driven JSON
  surgery that was the bug's root cause — a structural fix, not a patch. Future shape
  drift is now prevented by code + tests, not by careful prose.
- **Matcher-scoped, fully defensive migration**: the prune targets exactly the dead
  `matcher == "UserPromptSubmit"` group and tolerates four malformed hand-edited shapes
  without dying (TC-UPS5). The high-priority "over-broad migration clobbers user hooks"
  risk was retired by design and covered by a sibling-preservation test.
- **Surface-don't-smooth honoured**: the migration count is printed to stdout (never a
  silent mutation), consistent with the project's integrity ethos.
- **Output-level smoke test caught nothing wrong but proved the end-to-end shape** — the
  belt-and-braces check the memory bank mandates after structural changes.
- **Design caught the backlog's wrong shape** before any code was written — the design
  phase paid for itself on a "Low complexity" task.

## What Could Be Improved
- **The BACKLOG entry encoded an incorrect fix** (flat array). A backlog item that
  prescribes a shape should be treated as a hypothesis, not a spec — design validated it
  and found it wrong. Worth a habit: verify externally-proposed shapes against the actual
  tool contract before adopting them as success criteria.
- **a-task-plan SC1 was written to the wrong shape** and never amended after design
  corrected it. The success criterion read as "flat array" through to retrospective even
  though the implementation (correctly) did the opposite. Plan SCs that design overturns
  should be amended in-place, not just contradicted downstream.
- **Running the full suite mid-task surfaced a self-inflicted red** (TC-VALIDATE) that is
  purely a function of in-flight workflow status. It is correctly understood and
  self-resolving, but it costs a paragraph of explanation in every exec file. No action —
  documented as a known in-flight artefact.

## Key Learnings
### Technical Insights
- **Claude Code's `UserPromptSubmit` uses the group-wrapper too.** It ignores the
  `matcher` key but still nests hooks under `{ hooks: [...] }`. "Top-level event ⇒ flat
  array" is a false intuition; the three-level wrapper is universal.
- **`PreToolUse` matchers filter tool names, not events.** A `matcher: "UserPromptSubmit"`
  under `PreToolUse` is structurally dead — it can never match a tool name. This is the
  precise mechanism of the original bug.
- **Compile-time-constant discipline scales.** Injecting the synthetic `UserPromptSubmit`
  entry *after* `partition_manifest` (bypassing `read_hook_directives`) is safe only
  because the command is a fixed constant — the same pattern as `$CANONICAL_PERL5OPT`. The
  security review flagged this as a forward-audit guardrail: keep post-partition
  injections constant-bound.

### Process Learnings
- **Deterministic helpers beat prose for anything shape-sensitive.** This bug existed
  because a model executed JSON construction from prose. The durable fix was to delete the
  prose and let code emit the structure. Prefer this conversion wherever a SKILL.md asks
  the model to hand-build structured config.
- **Pre-retrospective status sweep matters.** Four plan files sat at non-terminal working
  statuses; the sweep (Gotcha #1) cleared both the `/cwf-status` display and the
  TC-VALIDATE red in one move. This is the most recurring workflow error and it recurred
  here — the sweep caught it.

### Risk Mitigation Strategies
- The planned mitigation for the top risk (over-broad migration) — *scope the prune to the
  exact dead group + regression-test sibling preservation* — worked exactly as designed
  (TC-UPS2). Naming the mitigation as a concrete test in planning made it un-skippable.

## Recommendations
### Process Improvements
- **Treat backlog-prescribed shapes/snippets as hypotheses.** Add a design-phase check:
  "does the externally-proposed shape match the actual tool/API contract?" before lifting
  it into success criteria.
- **Amend plan SCs in place when design overturns them.** Avoid the situation where a
  success criterion contradicts the shipped implementation.

### Tool and Technique Recommendations
- The **output-level smoke test on a scratch repo** remains the right final gate for any
  change that emits structured config — keep mandating it after structural edits.
- Consider a brief reference note (where hook shapes are documented) recording the
  universal group-wrapper + the `PreToolUse`-matcher-is-a-tool-name fact, so the next
  editor doesn't re-derive it.

### Future Work
- None required by this task. The (e) security note — *audit any future reuse of the
  post-partition injection that carries non-constant `command`/`event` data* — is a
  guardrail for the next editor, not a follow-up task.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge to main (human-only action)
**Blockers**: None identified
**Completion Date**: 2026-06-12
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`, `c-design-plan.md`, `d-implementation-plan.md`,
  `e-testing-plan.md`
- Implementation: commit `6d1730b` (helper + tests + SKILL.md + hash refresh)
- Testing: commit `f317a54` (TC-UPS1–8 + regression results) — see `g-testing-exec.md`
- Security reviews: `## Security Review` sections in `f-implementation-exec.md` and
  `g-testing-exec.md` (both: no findings)
