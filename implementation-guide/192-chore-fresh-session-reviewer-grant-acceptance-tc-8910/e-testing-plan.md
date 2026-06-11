# Fresh-session reviewer grant acceptance (TC-8/9/10) - Testing Plan
**Task**: 192 (chore)

## Task Reference
- **Task ID**: internal-192
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/192-fresh-session-reviewer-grant-acceptance-tc-8910
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for Fresh-session reviewer grant acceptance (TC-8/9/10).

## Test Strategy
### Test Levels
This is a **manual acceptance** task (the three checks Task 186 deferred). There is no new
code, so no unit/integration suite is authored. The levels exercised are:
- **Acceptance**: TC-8/9/10 are the acceptance criteria themselves — registry inspection,
  live agent invocation, and verdict-classifier parse.
- **Regression**: `prove t/` must stay green (no source changed, so this is a sanity guard
  that the verification activity touched nothing it should not).

### Precondition gate (PG) — session freshness
Before any TC may record a *pass*, the session must be demonstrably fresh with respect to the
agent-definition cache:
- **PG**: the live registry shows the five reviewers with the **restricted** grant
  (`Read, Grep, Glob, LSP, Bash`), not the pre-change all-tools inheritance. The restricted set
  only exists post-change, so its presence is positive freshness evidence. `registry == on-disk`
  is necessary-but-not-sufficient; if the registry instead shows all-tools inheritance, the
  whole run defers to a genuinely new session (no false pass).

### Test Coverage Targets
- **Critical path** (the grant fix is live across all five reviewers): TC-8 covers 100%.
- **Functional behaviour under the new grant**: TC-9 (plan reviewer), TC-10 (changeset reviewer).
- **Regression**: full `prove t/` green.

## Test Cases
### Functional Test Cases
- **TC-8**: Registry shows exact grant
  - **Given**: a fresh session (PG satisfied) on branch `chore/192-…`, baseline `d676e23`.
  - **When**: the live agent registry is read and compared to `.claude/agents/cwf-*.md`.
  - **Then**: each of the five reviewers shows *exactly* `Read, Grep, Glob, LSP, Bash`;
    `Edit`/`Write` absent; `LSP` present (its appearance in the token list = accepted, no
    load error).

- **TC-9**: A plan reviewer runs to completion under the new grant
  - **Given**: PG satisfied; an existing plan file (this task's `a-task-plan.md`) to review.
  - **When**: a `cwf-plan-reviewer-*` agent is invoked on it (the d-phase Step 8 plan-review
    run is the canonical evidence source).
  - **Then**: the agent returns well-formed findings with **no tool-permission/denied error**
    (the observable signal). markdown-reader reachability is best-effort corroboration only,
    never a fail condition; the documented `skills:`-field fallback covers non-reachability.

- **TC-10**: Changeset reviewer verdict parses
  - **Given**: PG satisfied; this task's exec changeset.
  - **When**: `cwf-security-reviewer-changeset` is invoked and its raw output is piped through
    `.cwf/scripts/command-helpers/security-review-classify`.
  - **Then**: the classifier emits exactly one canonical token (`no findings` | `findings`),
    proving exactly one well-formed `cwf-review` block was present — **not** the `error` token
    that zero or multiple blocks would yield.

- **TC-REG**: No regression
  - **Given**: the verification activity is complete (docs + BACKLOG/CHANGELOG only).
  - **When**: `prove t/` is run.
  - **Then**: all tests pass (no source was changed; this guards against accidental edits).

### Non-Functional Test Cases
- **Security**: TC-10 *is* the security check (the changeset reviewer over this task's diff).
  A doc/BACKLOG-only changeset is expected to yield `no findings`.
- **Reliability**: the classifier's fail-safe default (`error` on zero/many blocks) means a
  malformed verdict degrades safely rather than producing a false `no findings`.
- **Performance / Usability**: N/A (no runtime artefact).

## Test Environment
### Setup Requirements
- A session whose agent-def cache reflects the post-change reviewer defs (PG above).
- Working tree on branch `chore/192-…`; `security-review-classify` and `backlog-manager`
  helpers present under `.cwf/scripts/command-helpers/`.

### Automation
- No new automated tests. Existing `prove t/` suite is the regression harness.

## Validation Criteria
- [ ] **PG** satisfied (restricted grant visible in registry) or run deferred to a new session.
- [ ] **TC-8** pass: all five reviewers show exactly the granted set, no Edit/Write, LSP accepted.
- [ ] **TC-9** pass: a plan reviewer completed with no tool-denied error.
- [ ] **TC-10** pass: classifier returns a single canonical token (not `error`).
- [ ] **TC-REG** pass: `prove t/` green.
- [ ] On all-pass: backlog item retired to CHANGELOG against Task 192; any failure surfaced as
      a finding with a scoped follow-up (item not retired).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
PG + TC-8/9/10 + TC-REG all PASS (g-testing-exec.md). TC-REG caught an invalid `Planning`
status value in the plan files, fixed to `Finished` in-phase.

## Lessons Learned
A regression guard earns its place even on verification-only tasks. See j-retrospective.md.
