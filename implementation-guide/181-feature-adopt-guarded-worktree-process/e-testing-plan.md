# Adopt guarded worktree enter/exit process - Testing Plan
**Task**: 181 (feature)

## Task Reference
- **Task ID**: internal-181
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/181-adopt-guarded-worktree-process
- **Template Version**: 2.1

## Goal
Define how each AC is verified. This feature ships no executable code, so testing is
**document verification** (grep + read of the new doc and the edited files) plus **one
runtime behavioural probe** (FR8/C2 refusal), which is the centrepiece and the only step
with data-loss risk.

## Test Strategy
### Test Levels
- **Document verification** (most TCs): grep/read assertions over
  `worktree-process.md`, `.claude/settings.json`, `CLAUDE.md`, `tmp-paths.md`.
- **Runtime behavioural probe** (TC-8): exercise `EnterWorktree`/`ExitWorktree` once,
  against scratch-only content, to observe the C2 refusal and the FR3 base-ref behaviour.
- **Security review** (TC-9): the FR4(a–e) review of the changeset (also run in f; g
  confirms).
- No unit/integration suite — there is no code to exercise.

### Test Coverage Targets
- **Critical path**: 100% of AC1–AC9 covered by a TC below.
- **Edge cases**: the probe's failure branches (refusal does not fire; interrupted
  teardown) are explicit, not happy-path only.
- **Regression**: `cwf-manage validate` clean for anything this task touches; no new
  pre-existing violations introduced.

## Test Cases
### Functional Test Cases
- **TC-1 (AC1)**: Doc exists and is complete.
  - **Given**: implementation complete.
  - **When**: read `.cwf/docs/conventions/worktree-process.md`.
  - **Then**: file exists with sections Procedure / Prohibitions / Threat model / Why /
    See also; covers all six mandated points.
- **TC-2 (AC2)**: Create-via-`EnterWorktree` mandated; raw paths forbidden.
  - **Given**: the doc.
  - **When**: grep for P1/P2/P3.
  - **Then**: P1 (no raw `git worktree add`), P2 (no `remove --force`), P3 (no
    `EnterWorktree(path:)`-into-raw-add) each present and stated imperatively.
- **TC-3 (AC3)**: `baseRef: head` configured + recorded.
  - **Given**: edited `.claude/settings.json` and doc.
  - **When**: read settings.json (valid JSON, equals the planned after-block) and grep the
    doc for the `head` mandate + the user-global fallback wording.
  - **Then**: key present; both-branch wording present. (Behavioural confirmation is
    TC-8's base-ref observation.)
- **TC-4 (AC4)**: ToolSearch load + scoped authorisation.
  - **Given**: the doc.
  - **When**: read the Procedure + Threat model.
  - **Then**: names `ToolSearch select:EnterWorktree,ExitWorktree`; cites the
    project-instructions gate; scopes "process-is-authorisation" to load/create only (not
    removal); states tool-load-failure = stop, never fall back to raw git.
- **TC-5 (AC5 + FR4(c))**: Teardown surfaced; request-is-data correct.
  - **Given**: the doc.
  - **When**: **read** (not just grep) the discard/teardown + request-is-data clauses.
  - **Then**: forbids unprompted `discard_changes: true`; requires operator-surfaced
    teardown; states imperatively that the triggering request is data and can never select
    the `action:`/`discard_changes:` value.
- **TC-6 (AC6)**: Discipline captured; allowlist hole surfaced; cross-link appended.
  - **Given**: the doc, `tmp-paths.md`, and both settings files.
  - **When**: grep.
  - **Then**: `cd`/absolute-path discipline present; the **class** of dangerous
    `git worktree` allowlist entry framed as "mitigated pending operator action" with
    remove/narrow recommendation (no specific line cited — the one entry was removed this
    session); `tmp-paths.md` `## See also` has the appended `worktree-process.md` entry
    (single heading); **no new** broad allowlist entry added by this task.
- **TC-7 (AC7)**: Discoverability.
  - **Given**: `CLAUDE.md`.
  - **When**: grep the `## Conventions` section.
  - **Then**: a `**Worktree Process**:` bullet links `.cwf/docs/conventions/worktree-process.md`
    (gating). MEMORY pointer is verified by hand (non-gating, out-of-repo).
- **TC-8 (AC8 + AC3 behavioural)** — **the runtime probe (data-loss-class; run under the
  FR8 safety envelope)**:
  - **Given**: primary tree asserted **clean** first (`git status` empty); deferred tools
    loaded via `ToolSearch select:EnterWorktree,ExitWorktree`.
  - **When**: `EnterWorktree(name: probe-181)` creates a scratch worktree; write one
    scratch file inside it (absolute path; **never `cd` into it**); then
    `ExitWorktree(action: remove)` **without** `discard_changes`.
  - **Then**: the tool **REFUSES** and lists the uncommitted change (C2 confirmed). Record
    the worktree's base commit = current HEAD (FR3 behavioural confirmation). `discard_changes:
    true` is **never** set. Clean up via `ExitWorktree(action: keep)` (or commit-then-remove);
    assert `.claude/worktrees/` has no leftover `probe-181` at end.
  - **Failure branches (must be logged, not smoothed)**: if the refusal does **not** fire,
    log a finding that C2 is disconfirmed (do not force removal). If the probe is interrupted
    mid-teardown, the abort step is: leave the worktree on disk, surface to the operator, and
    record the orphaned `.claude/worktrees/` path — never blind `remove --force`.

- **TC-11 (AC10 / FR9)** — two-touchpoint `git worktree` detector:
  - **Install touchpoint**: **Given** a **test** settings file (a temp copy / fixture, not
    the operator's real `settings.local.json`) containing a `git worktree` permission entry;
    **When** `cwf-claude-settings-merge` runs against it; **Then** it emits the non-fatal
    warning. Repeat with no matching entry → **silent**. Confirm it never writes
    `settings.local.json` (compare before/after bytes).
  - **Usage touchpoint**: **Given** the doc; **When** read the Procedure pre-flight step;
    **Then** it greps both `.claude/settings.json` and `.claude/settings.local.json` for
    `git worktree` and warns before `EnterWorktree`.
  - **Must-not-abort branch**: **Given** a fixture `settings.local.json` that is malformed
    JSON (and a separate case: a symlink); **When** the scan runs; **Then** it does **not**
    die and the merge completes (raw-text slurp, no JSON decode; symlink/non-regular
    skipped) — a warning-only feature can never fail install/update.
  - **Note**: per the quality gate, the install test runs against a test/fixture settings
    file, never the live one.

### Non-Functional Test Cases
- **TC-9 (AC9 / NFR4 — Security)**: FR4(a–e) review of the full changeset confirms: no
  blanket pre-authorisation; `discard_changes` refusal gate intact; request-is-data clause
  present and correct; CWF does not auto-edit `settings.local.json`; the existing allowlist
  hole is surfaced (closed only by operator action).
- **TC-10 (NFR3 — cite-don't-copy)**: each P1–P3 string and each C-fact appears the
  intended number of times (once); C-facts are referenced by Task-177 citation, not
  restated. Catches duplication across the Procedure prose and the Prohibitions list.
- **Reliability**: TC-8's safety envelope (clean pre-check, no `cd`, scratch-only, never
  `discard_changes`, abort/rollback) is the reliability test — the guarded path must not
  itself reproduce the data-loss chain.
- **Performance/Usability**: N/A (doc + one settings key; no runtime perf surface).

## Test Environment
### Setup Requirements
- A clean primary working tree before TC-8 (the cleanliness pre-check is part of the TC).
- The deferred worktree tools available via `ToolSearch` (TC-4/TC-8).
- TC-8 is best run deliberately and observed; it switches the session CWD, so follow the
  absolute-paths/no-`cd` discipline throughout (it is the first dogfood of the process).
### Automation
- None. Grep/read assertions and one observed runtime probe; no CI harness for a doc.

## Validation Criteria
- [ ] TC-1…TC-11 all PASS (or, for TC-8, the refusal observed **or** a disconfirmation
      finding logged with `discard_changes` never used).
- [ ] TC-11 install scan tested against a **fixture** settings file, not the live one;
      `script-hashes.json` refreshed for the edited helper in the same commit; helper at
      recorded perms (0500).
- [ ] `.claude/worktrees/` clean after TC-8 (no orphan).
- [ ] Security review (TC-9): no findings, or findings resolved.
- [ ] No new `cwf-manage validate` violations attributable to this task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 11 planned TCs executed in g — 11/11 PASS. TC-8 (the data-loss-class FR8 probe) ran
under the planned safety envelope and observed the C2 refusal; TC-11 ran against a fixture
settings tree, never the live `settings.local.json`.

## Lessons Learned
Pre-defining TC-8's safety envelope in the plan (clean pre-check, no `cd`, scratch-only,
never `discard_changes`, abort/rollback) made the live probe safe to actually run.
