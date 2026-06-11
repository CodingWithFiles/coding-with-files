# Fresh-session reviewer grant acceptance (TC-8/9/10) - Implementation Plan
**Task**: 192 (chore)

## Task Reference
- **Task ID**: internal-192
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/192-fresh-session-reviewer-grant-acceptance-tc-8910
- **Template Version**: 2.1

## Goal
Execute Task 186's three deferred acceptance checks and record the evidence, treating the
verification itself as the work. No production code changes unless a check surfaces a defect.

## Workflow
Observe (registry/on-disk) → Exercise (invoke agents) → Assert (g-phase) → Retire backlog.

## Nature of this task
This is a **verification-only** chore. There is no source code to write. The
"implementation" (f-phase) is gathering the three pieces of evidence; the "testing"
(g-phase) is asserting each against its expected result and retiring the backlog item.
The exec changeset is therefore the wf-step docs plus the BACKLOG→CHANGELOG move.

## Files to Modify
### Primary Changes
- `implementation-guide/192-.../f-implementation-exec.md` — record raw TC-8/9/10 evidence
  (registry grant lines, plan-reviewer transcript summary, changeset-reviewer raw output +
  classify token).
- `implementation-guide/192-.../g-testing-exec.md` — TC-8/9/10 pass/fail matrix, security
  review, coverage.

### Supporting Changes
- `BACKLOG.md` / `CHANGELOG.md` — retire the "Fresh-session acceptance of the Task 186
  reviewer grant change (TC-8/9/10)" item against Task 192 (only if all three pass), via
  `backlog-manager retire`. If any check fails, the item stays and a follow-up is scoped.
- No production code, no hashed scripts touched (verification-only).

## Implementation Steps
### Step 1: Establish session freshness (precondition for a valid TC-8 read)
- [ ] Read the live agent registry (the Agent-tool listing) for all five reviewers.
- [ ] Cross-check it against on-disk frontmatter `tools:` lines in `.claude/agents/cwf-*.md`.
- [ ] Apply the discriminating test, not just equality: the *pre-change* state was
      `allowed-tools:` (silently ignored → **all-tools inheritance**). So a stale-cache session
      would surface the reviewers with the full inherited tool set (incl. Edit/Write/Agent),
      **not** the restricted `Read, Grep, Glob, LSP, Bash`. The registry showing the *restricted*
      set is therefore positive evidence of freshness — that set only exists post-change.
- [ ] Caveat (per robustness review): `registry == on-disk` is necessary-but-not-sufficient on
      its own; the only full guarantee is a genuinely new session (the backlog item says
      "observable only after a `/clear` or fresh session"). Record the residual. If the registry
      shows the *old* all-tools inheritance, STOP and defer to a new session — do not record a
      false pass.

### Step 2: TC-8 — registry shows exact grant
- [ ] For each of the five reviewers, confirm the live grant is *exactly*
      `Read, Grep, Glob, LSP, Bash`, that `Edit`/`Write` are absent, and that `LSP` loaded
      with no error (its presence in the registry token list is the no-error signal).

### Step 3: TC-9 — a plan reviewer runs to completion under the new grant
- [ ] **Primary (observable) signal**: a `cwf-plan-reviewer-*` agent runs against an existing
      plan file and returns well-formed findings with **no tool-permission/denied error**. This
      is the criterion that is actually observable from the parent (the parent sees the
      subagent's final text, not its internal tool-call trace), and it is what TC-9 is really
      asserting — that the reviewers still function under the tightened grant.
- [ ] **Evidence source**: this task's own d-phase Step 8 plan-review already invoked all four
      `cwf-plan-reviewer-*` agents; they completed and returned findings with no tool-denied
      error. Capture that transcript as the TC-9 evidence rather than performing a second
      isolated invocation.
- [ ] **Best-effort corroboration (not a gate)**: markdown-reader is a *preference* in
      `cwf-agent-shared-rules.md`, not invoked by name by the reviewer procedure, so a normal
      run satisfies itself with the Read built-in and need not reach it — do not fail TC-9 on
      markdown-reader non-reachability. If a reviewer transcript happens to show a
      markdown-reader/Bash-script use, note it; otherwise the `skills:`-field fallback remains
      the documented path and the core grant (TC-8) still stands.

### Step 4: TC-10 — changeset reviewer verdict parses
- [ ] Invoke `cwf-security-reviewer-changeset` (via Agent) against this task's exec changeset.
- [ ] Pipe its raw output through `.cwf/scripts/command-helpers/security-review-classify`;
      confirm exactly one well-formed `cwf-review` block yielding a single canonical token
      (`no findings` | `findings` | `error`), i.e. not the `error` that zero/many blocks give.

### Step 5: Record and retire
- [ ] Write the pass/fail matrix to g-testing-exec.md.
- [ ] If all pass: `backlog-manager retire --id=<slug> --task=192`. Commit BACKLOG/CHANGELOG.
- [ ] If any fail: surface as a finding, leave the backlog item, scope a corrective follow-up.

## Test Coverage
**See e-testing-plan.md for complete test plan** (TC-8/9/10 mapping + the freshness gate).

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Steps 1–4 executed in f-implementation-exec.md (evidence) and Step 5 in g-testing-exec.md
(record + retire). All TCs PASS. TC-9 evidence sourced from the d-phase Step 8 plan review.

## Lessons Learned
A subagent's tool trace is not caller-observable; acceptance criteria must use observable
outcomes. See j-retrospective.md.
