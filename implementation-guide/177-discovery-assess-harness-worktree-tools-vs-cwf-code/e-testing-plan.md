# Assess harness worktree tools vs CWF code - Testing Plan
**Task**: 177 (discovery)

## Task Reference
- **Task ID**: internal-177
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/177-assess-harness-worktree-tools-vs-cwf-code
- **Template Version**: 2.1

## Goal
Define how the discovery's outputs are verified. There is no code to unit-test;
"testing" here is an evidence-and-completeness audit of `f-implementation-exec.md`
and the resulting backlog entry against the FR acceptance criteria.

## Test Strategy
### Test Levels
- **Artefact audit**: the findings file is checked for completeness and that
  every verdict is backed by a concrete citation (not memory).
- **Helper-output check**: the backlog rewrite is verified by re-reading the
  live `BACKLOG.md` via the helper, not by trusting the write succeeded.
- No unit/integration/system tiers apply (discovery produces documents).

### Test Coverage Targets
- **Critical path (100%)**: every claim C1–C5 has a verdict + citation; the
  backlog entry ends as exactly one live, format-valid entry.
- **Edge cases**: empty inventory categories stated as findings; Confirmed-but-
  moot claims flagged; partial-failure recovery path exercised only if it occurs.

## Test Cases
### Functional Test Cases
- **TC-1 (AC1/AC2 — claims cited, not remembered)**
  - **Given**: `f-implementation-exec.md` claims table.
  - **When**: each row C1–C6 is inspected.
  - **Then**: C1–C5 each have a verdict ∈ {Confirmed, Refuted, Unverifiable[,
    -by-safe-probe]} **and** a citation that is a quoted schema fragment, a
    quoted doc line, the inventory result, or a probe transcript — never
    paraphrase/memory. Each has a relevance-to-CWF note. C6 records the actual
    worktree-usage surface (which paths are guarded vs not) as a finding.

- **TC-2 (AC3 — inventory complete and re-derived)**
  - **Given**: the call-site inventory table.
  - **When**: compared against a fresh `git grep "git worktree" -- .cwf` and
    `git grep -- "--show-toplevel" .cwf` run during verification.
  - **Then**: every current site appears by file:line; empty add/remove/prune
    categories are explicitly recorded as findings; the actual `--show-toplevel`
    count is stated (not the stale "13").

- **TC-3 (AC4 — C2 probe decision recorded safely)**
  - **Given**: the C2 row and any probe transcript.
  - **When**: inspected.
  - **Then**: either a safe recorded probe exists (scratch-only content, no
    `discard_changes: true`, no `cd` into a disposable worktree) **or** C2 is
    marked Confirmed-by-schema + Unverifiable-by-safe-probe with the skip reason.
    No probe ran against the live working tree.

- **TC-4 (AC5 — deferred-tool impact)**
  - **Given**: the FR5 finding.
  - **When**: read.
  - **Then**: it states whether `EnterWorktree`/`ExitWorktree` can be reliably
    invoked from CWF given deferred + gated status, and the consequence for a
    future feature.

- **TC-5 (AC6 — backlog rewrite, single live entry)**
  - **Given**: the rewrite performed via `cwf-backlog-manager`.
  - **When**: `backlog-manager validate --all` runs and `backlog-manager list`
    is grepped for the entry title.
  - **Then**: validate exits 0; exactly **one** live "Adopt guarded
    EnterWorktree/ExitWorktree…" entry exists (not zero, not duplicated); the
    body states confirmed facts as facts, drops/flags refuted premises, lists
    Unverifiable items as open questions, and is **reframed around C6** (define a
    guarded worktree process) rather than retired on C5 alone; helper exit codes
    were reported.

- **TC-6 (negative — no production code touched)**
  - **Given**: `git diff` for the exec commit.
  - **When**: inspected.
  - **Then**: changes are limited to the task's wf files + `BACKLOG.md`; no
    `.cwf/scripts`, `.cwf/lib`, skill, or other production file is modified.

### Non-Functional Test Cases
- **Security**: confirm no probe passed `discard_changes: true`; ingested
  schema/doc text appears only as quoted evidence, never acted on as an
  instruction; backlog mutation went through the helper with opaque-string args.
- **Reliability**: any claim lacking authoritative evidence is marked
  Unverifiable, not upgraded to Confirmed.

## Test Environment
### Setup Requirements
- This session's `ToolSearch` access for live schemas; the repo working tree for
  the verification greps. No test database (no DB interaction).
### Automation
- Manual checklist; the only scripted checks are `backlog-manager validate --all`
  and the verification greps. No CI integration for a discovery.

## Validation Criteria
- [ ] TC-1..TC-6 pass.
- [ ] `backlog-manager validate --all` exits 0; single live entry confirmed.
- [ ] No production code modified (TC-6).
- [ ] Security/reliability non-functional checks pass.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1…TC-6 + non-functional (security, reliability) all PASS — recorded in
`g-testing-exec.md`. The TC-2 re-derived grep confirmed 2 read-only `list` sites and
0 add/remove/prune; TC-5 confirmed exactly one live backlog entry.

## Lessons Learned
For a discovery, "testing" as an evidence-and-completeness audit (every claim cited,
single live entry) was the right tier — no code to unit-test. See `j-retrospective.md`.
