# Integrate Claude Code sandboxing into CWF - Testing Plan
**Task**: 178 (discovery)

## Task Reference
- **Task ID**: internal-178
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/178-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Define how the discovery's outputs are verified. There is no code to unit-test;
"testing" is an evidence-and-completeness audit of `f-implementation-exec.md` and the
seeded backlog item(s) against the FR acceptance criteria.

## Test Strategy
### Test Levels
- **Artefact audit**: the findings file is checked for completeness and that every
  mechanism + verdict is backed by a concrete citation (doc quote / live schema /
  first-hand grep), not memory.
- **Helper-output check**: the backlog seed is verified by re-reading live `BACKLOG.md`
  via the helper, not by trusting the write succeeded.
- No unit/integration/system tiers apply (discovery produces documents).

### Test Coverage Targets
- **Critical path (100%)**: R1/R2/R3 each have a cited mechanism row + a failure-wired,
  enforceability-labelled verdict; the recommendation exists; the backlog ends as
  exactly the expected number of live entries.
- **Edge cases**: "none found"/Unverifiable propagation; transient-fetch-vs-absence;
  R2 removal/canonicalisation; R3 no-violation-signal cap; backlog partial-failure.

## Test Cases
### Functional Test Cases
- **TC-1 (FR1 — mechanism inventory cited, not remembered)**
  - **Given**: the mechanism inventory table in `f-implementation-exec.md`.
  - **When**: each row is inspected.
  - **Then**: each (requirement, mechanism) row has a citation that is a quoted doc
    line, a live schema fragment, or a first-hand repo grep/read — never memory; and
    an "in `cwf-claude-settings-merge` today? (y/n)" + gap/extension-cost cell. A
    "none found" cell is present where applicable, not an omission.

- **TC-2 (FR2 — verdicts failure-wired + enforceability-labelled)**
  - **Given**: the feasibility verdict table.
  - **When**: each of R1/R2/R3 is inspected.
  - **Then**: each has verdict ∈ {Feasible, Feasible-with-caveats, Not-feasible-today,
    Unverifiable}; a **fail-open behaviour** note (advisory-off vs hard-fail under
    `failIfUnavailable`); and an **enforceable-vs-advisory** label keyed on
    `dangerouslyDisableSandbox`/unsandboxed-fallback agent-reachability. A "none
    found"/sole-Unverifiable mechanism resolves to Not-feasible-today (candidate
    named); R3 with no structured violation event is capped at
    Feasible-with-caveats-unreliable.

- **TC-3 (FR3 — substrate gaps priced against real code)**
  - **Given**: the substrate-gap notes.
  - **When**: compared against a fresh read of `cwf-claude-settings-merge`.
  - **Then**: the two gaps are stated as found this session — (i) helper writes
    `permissions.allow` only (no `sandbox.*`/`permissions.deny`); (ii) hook events
    restricted to `{Stop, SubagentStop}` — each with its same-commit
    `script-hashes.json` refresh cost; and the enforcement-ownership boundary (CWF
    advises, OS enforces, operator can override) is stated.

- **TC-4 (FR4 — knobs + defaults)**
  - **Given**: the findings.
  - **When**: read.
  - **Then**: R2's credential list is described as user-editable with a shipped default
    (≥ `~/.ssh`, `~/.aws`) and a named config surface; R3's logging is a named switch
    defaulting **OFF**; R1's phase-scoping is opt-in and explicitly conditional on its
    own verdict being ≥ Feasible-with-caveats.

- **TC-5 (FR5 — weaknesses carried, no smoothing)**
  - **Given**: the weakness carry-forward section.
  - **When**: read.
  - **Then**: the relevant documented weaknesses are listed (default-read-leaks-creds;
    non-TLS egress proxy; `excludedCommands` no managed lockdown; fail-open;
    agent-reachable escape hatch), and no recommendation turns R3 logging into a silent
    boundary-disable (`feedback_surface_security_dont_smooth`).

- **TC-6 (FR6 — recommendation + backlog seed, expected entry count)**
  - **Given**: the recommendation + the seed performed via `backlog-manager`.
  - **When**: `.cwf/scripts/command-helpers/backlog-manager validate --all` runs and
    `list --all-items` is grepped for each seeded title.
  - **Then**: validate exits 0 (format); the **count** of each live title == the
    expected number (no zero, no duplicate) — the count guard is the grep, not
    `validate`; the recommendation states build/don't-build/build-subset + the
    decompose decision; helper exit codes were reported.

- **TC-7 (negative — no production code touched)**
  - **Given**: `git diff` for the exec commit.
  - **When**: inspected.
  - **Then**: changes are limited to the task's wf files + `BACKLOG.md`; no
    `.claude/settings.json`, `cwf-claude-settings-merge`, `cwf-project.json`, hook, or
    other production file is modified.

### Non-Functional Test Cases
- **Security**: ingested doc/schema text appears only as quoted evidence, never acted
  on as instruction; the backlog mutation went through the helper with list-form/opaque
  args + `--body-file` (no inline body, no heredoc).
- **Reliability**: any mechanism not confirmable this session is marked Unverifiable
  (and, if sole candidate, Not-feasible-today), never upgraded to Feasible; a transient
  fetch failure is re-attempted, not recorded as a verdict.

## Test Environment
### Setup Requirements
- This session's `WebFetch`/`ToolSearch` for current docs/schemas; the repo working
  tree for the substrate greps and the exec-commit diff. No test database (no DB).
### Automation
- Manual checklist; the only scripted checks are `backlog-manager validate --all`, the
  title-count greps, and the substrate greps. No CI for a discovery.

## Validation Criteria
- [ ] TC-1..TC-7 pass.
- [ ] `backlog-manager validate --all` exits 0; expected live-entry count per title confirmed.
- [ ] No production code modified (TC-7).
- [ ] Security/reliability non-functional checks pass.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1..TC-7 all PASS (g-testing-exec.md). The two scripted checks ran green:
`backlog-manager validate --all` exit 0, and the title-count grep = 1. TC-7 (negative)
confirmed the exec commits touched only wf files + BACKLOG.md.

## Lessons Learned
Framing "testing" as an evidence-and-completeness audit (re-checkable artefact/helper
checks) fit a discovery cleanly — every FR AC mapped to a concrete TC with no
unit/integration tier to force-fit.
