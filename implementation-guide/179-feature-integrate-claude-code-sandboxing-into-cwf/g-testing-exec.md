# Integrate Claude Code sandboxing into CWF - Testing Execution
**Task**: 179 (feature)

## Task Reference
- **Task ID**: internal-179
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/179-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Execute the e-testing-plan TC-1..TC-13 against the f-exec build (TDD — cases were
written failing-first during implementation), record results, and gate on the
full suite + `cwf-manage validate`.

## Test Execution Summary
- **Suites**: `t/validate-config.t`, `t/cwf-claude-settings-merge.t`,
  `t/pretooluse-sandbox-logging.t` (new), plus the full `prove -l t/` regression.
- **Result**: all green. Full suite **665 tests PASS**; `cwf-manage validate: OK`.

## Test Cases (e-testing-plan mapping)

| TC | Maps to | Where | Result |
|----|---------|-------|--------|
| TC-1 | FR1/AC1a-b — OFF default + no regression | `cwf-claude-settings-merge.t` "TC-1" + real-repo OFF dry-run | **PASS** — file-absent & block-absent ⇒ zero sandbox/deny keys; allow/hooks/env intact |
| TC-2 | FR1/AC1d — absent vs malformed | `cwf-claude-settings-merge.t` "TC-2" | **PASS** — unparseable / non-bool switch / non-array list all surface `[CWF] ERROR:`, non-zero exit |
| TC-3 | FR1/AC1e — schema validation | `validate-config.t` TC-S1..S7 | **PASS** — non-bool switches, non-array/non-string-entry list flagged; absent block & absent-list+enabled valid |
| TC-4 | FR2/AC2a-b — paired rules | `cwf-claude-settings-merge.t` "TC-4/5" | **PASS** — denyRead == list AND `Read(P)`+`Read(P/**)` per entry |
| TC-5 | FR2/AC2c — rule form | `cwf-claude-settings-merge.t` "TC-4/5" | **PASS (string-form)** — emitted strings equal `Read(~/.ssh)` etc.; runtime `~` expansion is a Claude Code property (see Residual note) |
| TC-6 | FR1/FR2/AC1c — ownership-by-shape reconcile | `cwf-claude-settings-merge.t` "TC-6" | **PASS** — OFF removes whole `sandbox.*` + all CWF-shaped `Read(...)`; `Bash(curl *)` preserved; AC1c identical-collision removed; changed-list no-orphan |
| TC-6b | reconcile idempotency | `cwf-claude-settings-merge.t` "TC-6b" | **PASS** — ON re-run byte-identical |
| TC-7 | FR3/AC3a — failIfUnavailable | `cwf-claude-settings-merge.t` "TC-7" | **PASS (authoritative)** — default true; knob false reflected; hand-set settings.json value overwritten by knob (see Deviation 1) |
| TC-8 | FR3/AC3b — dep probe + guard | `cwf-claude-settings-merge.t` "TC-8" | **PASS** — missing dep ⇒ fixed-token message naming package + knob; empty/`.` PATH segment not resolved to cwd; never blocks |
| TC-9 | FR5/AC5a-c — R3 hook | `cwf-claude-settings-merge.t` "TC-9" (gating) + `pretooluse-sandbox-logging.t` (behaviour) | **PASS** — registers under PreToolUse only when violation-logging true; record carries presence flag + tool, no raw command; malformed stdin & log-write failure fail-open |
| TC-10 | FR6/AC6a-d — substrate | `cwf-claude-settings-merge.t` "TC-10" + TC-U* regression | **PASS** — PreToolUse event accepted; matcher regex unchanged (`Edit\|Write` rejected); writes only to `.claude/settings.json`; user keys preserved |
| TC-11 | FR7 — limitations doc | grep `.cwf/docs/sandboxing.md` | **PASS** — advises-not-enforces, Bash-only, agent-reachable escape hatch, no-reliable-event, fail-closed-while-true, `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` env caveat all present |
| TC-12 | FR4/AC4d — R1 split | `grep -c` BACKLOG + `backlog-manager validate --all` | **PASS** — exactly 1 live 179.1 entry; validate exit 0; body names matcher-widening + fail-closed |
| TC-13 | integrity | `cwf-manage validate` + hash-table grep | **PASS** — R3 log not hash-tracked (0 entries) but gitignored (manifest + `.gitignore`); validate clean; helper/Config/install-manifest hashes refreshed + new hook entry in the f-exec commit |

## Non-Functional Results
- **NFR1 (performance, recorded not asserted)**: R3 PreToolUse hook measured at
  **~15 ms/call** (50 invocations, 792 ms total) on this host — spawn-dominated
  (perl interpreter startup); it does **no** `task-context-inference` and **no**
  git, so it is materially lighter than the R1 gate 179.1 will add.
- **Security (NFR4)**: no path silences `cwf-manage validate` (the R3 log write
  leaves validate clean — TC-13); the R3 record carries no attacker-controlled
  string (presence flag only); dep names are compile-time literals; guard message
  is fixed-token. Confirmed by the exec-phase security review below (no findings).
- **Reliability (NFR5)**: merge idempotent (TC-6b); absent ⇒ OFF, malformed ⇒
  surfaced (TC-1/TC-2); unknown user keys round-trip preserved (TC-U regression).

## Deviations (carried from f-exec; see f-implementation-exec.md § Deviations)
1. **failIfUnavailable authoritative** (not warn-not-overwrite) — resolves a
   contradiction in D5/AC3a/TC-7; knob is the single source of truth. TC-7
   asserts the authoritative behaviour.
2. CWF-shape predicate pinned to any `Read(...)` deny (whole generated region
   CWF-owned). TC-6 asserts the AC1c collision as intended.
3. New test file `t/pretooluse-sandbox-logging.t` for R3 hook behaviour.
4. No `~`-expansion fail-closed fallback branch (contingency did not trigger).

## Residual verification (for rollout, h)
- **Runtime `~` expansion in the `Read()` permission matcher** is a Claude Code
  property the Perl suite cannot exercise; emitted string-forms are tested and
  the expansion is asserted from Task 178's first-hand discovery + the documented
  path-prefix rule. Recommend a one-off live confirmation at rollout.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*

## Security Review

**State**: no findings

Production code is unchanged from the implementation-phase review (confirmed
byte-identical against HEAD); this phase adds only test suites + the f/g exec
docs, so the focus was the test code — a test that weakens a boundary, plants an
unsafe fixture, or asserts insecure behaviour.

**(a) Bash injection** — One new shell call: `t/pretooluse-sandbox-logging.t`
`system("$hook <'$in' >'$so' 2>/dev/null")`. Every interpolated path derives
from `tempdir(CLEANUP=>1)` (File::Temp literal, no metacharacters) — safe here;
audit any future reuse where a path could carry a slug/branch name (move to
list-form then). TC-8's planted `bwrap` stub + `perl` symlink are inert fixtures.

**(b) git/`-z`** — No git porcelain consumed by any test; input is JSON /
structured fixtures; `split /\n/` runs on the hook's own JSON-line log output.
Clean.

**(c) Prompt injection** — Security-positive: `pretooluse-sandbox-logging.t`
plants `rm -rf /secret` + `dangerouslyDisableSandbox` and asserts
`unlike($log, qr{rm|secret})` — locks in "presence flag only, never the raw
command". No fixture content re-enters LLM context.

**(d) Env vars** — TC-8's `local $ENV{PATH}="$bin:.:"` asserts the planted cwd
`bwrap` is NOT resolved (confirms the probe skips `.`/empty). `local`-scoped; no
env var drives a write target. Clean.

**(e) Patterns** — (1) the File::Temp `system()` note above; (2) TC-6 pins the
AC1c documented removal contract (correct per D2), preserving the
"`^Read\(.+\)$` region is CWF-owned" invariant for 179.1.

**Fixture-safety** — Every fixture asserts the secure direction: OFF emits zero
sandbox/deny keys (TC-1); hand-set `failIfUnavailable:false` overwritten by the
knob's `true` (TC-7, fail-closed wins); malformed config surfaces `[CWF] ERROR:`
(TC-2).

```cwf-review
state: no findings
summary: Testing-phase diff is clean; production unchanged since impl review. Test suites pin the secure direction (no raw command in R3 log, fail-open observe-only, malformed config surfaces, knob-authoritative failIfUnavailable, PATH '.'-segment not resolved). One safe-here pattern note: t/pretooluse-sandbox-logging.t uses single-string system() with File::Temp-literal paths only — audit future reuse with partly-controlled paths.
```
