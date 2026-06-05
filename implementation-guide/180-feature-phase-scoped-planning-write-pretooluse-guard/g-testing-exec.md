# phase-scoped planning-write PreToolUse guard - Testing Execution
**Task**: 180 (feature)

## Task Reference
- **Task ID**: internal-180
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/180-phase-scoped-planning-write-pretooluse-guard
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready (`prove`, git available)
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps (none)
- [x] Status → Finished (all pass)

## Test Results

**Suite**: `prove -j4 t/` → **686 tests, all pass** (58 files). The four touched
suites: `planning-guard.t`, `pretooluse-planning-write-guard.t`,
`cwf-claude-settings-merge.t`, `validate-config.t` → **77 tests, all pass**.

### Functional Tests (e-testing-plan TC-1..TC-16)

| Test ID | Where | Expected | Status |
|---------|-------|----------|--------|
| TC-1 classify_path crown/non-crown/traversal/symlink | `planning-guard.t` | crown for .cwf/.claude (+traversal/symlink); not-crown for task file/BACKLOG/README | PASS |
| TC-2 two-root (worktree) rule | `planning-guard.t` | .cwf under 2nd root → crown | PASS |
| TC-3 decide matrix | `planning-guard.t` | non-Edit/Write & non-crown → allow; crown+correlated+impl-exec → allow; planning/uncorrelated/no_signals/error → deny | PASS |
| TC-4 ordering regression | `planning-guard.t` | uncorrelated + exec-looking step → deny (confidence gates first) | PASS |
| TC-5 fixed deny token | `planning-guard.t` | `crown-jewel:.cwf\|.claude` + `phase:<x>\|unknown`; never a path/slug | PASS |
| TC-6 matcher widening (TC-10 rewrite) | `cwf-claude-settings-merge.t` | `Edit\|Write` registers; `Edit\|`/`\|Write`/`\|\|`/`Edit\|;rm` fall back; single-token unchanged | PASS |
| TC-7 gated registration | `cwf-claude-settings-merge.t` (TC-PG2) | off→not registered; observe/enforce→PreToolUse `Edit\|Write`; sandbox-off gate; R3 independence | PASS |
| TC-8 dual-validator enum | `validate-config.t` (TC-S8..S10) + helper (TC-PG1) | off/observe/enforce valid; unknown/empty/non-string → violation; absent → none; merge-time die `[CWF] ERROR:` | PASS |
| TC-9 enforce deny, real payload, no path echo | `pretooluse-planning-write-guard.t` | deny JSON envelope (`hookSpecificOutput.permissionDecision=deny`), fixed token, target path NOT echoed | PASS |
| TC-10 hook tool-gate / target:unresolved | `pretooluse-planning-write-guard.t` | non-Edit/Write → allow (exit 0); missing file_path / malformed stdin → deny `target:unresolved` | PASS |
| TC-11 observe logs + permits | `pretooluse-planning-write-guard.t` | FindBin-anchored fixed-key record (`event:planning-guard-observe`, no raw path) + permit; write failure swallowed | PASS |
| TC-12 knob off/absent/invalid | `pretooluse-planning-write-guard.t` | off/absent/config-absent → allow; invalid → enforce (fail-closed) | PASS |
| TC-13 no STDERR/TCI leak | `pretooluse-planning-write-guard.t` | stdout is clean decision JSON; no TCI/git stderr text | PASS |
| TC-15 testing-exec conservatism | `planning-guard.t` (TC-3) | crown + correlated + `g-testing-exec` → deny (exec set = implementation-exec only) | PASS |
| TC-16 integrity | `cwf-manage validate` | new lib (no perms key) + hook (`0500`) + refreshed helper/Config.pm hashes; observe log NOT hash-tracked; clean | PASS |

### Non-Functional Tests

**TC-14 (NFR1 — per-call cost, budget ≤~50 ms/call).** Measured the real
per-tool-call cost (a fresh hook process per call) over 50 iterations in a
hermetic enforce repo:

| Path | Cost | Notes |
|------|------|-------|
| crown-jewel Edit (full: classify + knob + TCI + decide + deny) | **36.9 ms/call** | within budget |
| non-crown Edit (short-circuit, no TCI) | **25.9 ms/call** | crown-jewel-first skip of TCI saves ~11 ms |

Both well under the ~50 ms budget. The non-crown floor (~26 ms) is perl startup +
module load + the two `derive_roots` git shell-outs; the crown path adds ~11 ms
for the TCI inference. Recorded, not asserted as an SLA (per e-plan TC-14); no
gross regression.

**Security** (path-class no-leak, no validate-silencing, matcher metachar): see
the `## Security Review` section below — reviewer found no findings; deny token
and observe record carry no attacker-controlled string.

## Test Failures

None. All 686 suite tests pass; `cwf-manage validate: OK`.

## Coverage Report

Critical path (the `decide` matrix, `classify_path` traversal/symlink/worktree,
matcher accept+reject, dual-validator enum, gated registration, enforce-deny /
observe-permit, fail-closed defaults, deny envelope) is covered by the 77
task-specific tests. No system/E2E tier — Claude Code's runtime matcher and
actual deny enforcement are owned by Claude Code + the OS (enforcement-ownership
boundary); the deny **output** envelope is bound by the real-payload fixture in
TC-9 + the doc-confirmed schema.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*

## Security Review

**State**: no findings

## Security review — Task 180 testing phase

**Scope reviewed.** The production code (`CWF::PlanningGuard`, the `pretooluse-planning-write-guard` hook, `cwf-claude-settings-merge` matcher widening, `CWF::Validate::Config` enum check) is byte-for-byte unchanged from the implementation-phase review (no findings). The production diff was re-confirmed against the leak/boundary criteria; the review focused on the four test files now surfaced.

Files reviewed: `t/cwf-claude-settings-merge.t` (TC-M6, rewritten TC-10, TC-PG1/TC-PG2), `t/planning-guard.t` (new), `t/pretooluse-planning-write-guard.t` (new), `t/validate-config.t` (TC-S8/S9/S10).

**(a) Bash injection.** Test `system()` calls interpolate only `File::Temp::tempdir` paths (`[A-Za-z0-9]` randomness under `$TMPDIR`, single-quoted) — never attacker-controlled. Safe here; audit any future copy where the interpolated path becomes user/branch/slug-derived. Not a finding.

**(b) Git/user output.** Only production `derive_roots` (`chomp` one `--show-toplevel` line) — already reviewed. Tests decode only their own JSON under `eval`. Clean.

**(c) Prompt injection.** No test feeds strings into LLM context; the tests positively *guard* the no-leak contract (TC-5 closed-charset deny token; hook test asserts target path never echoed into reason/observe-log; TC-13 no STDERR contamination).

**(d) Env-var handling.** `PERL5LIB` set `local` to the real in-repo `.cwf/lib` for the subprocess only; validate-config tests are pure (no filesystem touch).

**(e) Test-masking.** No security-load-bearing function is stubbed in a masking way. The hook test runs a real copy of the hook with the real lib, exercising the fail-closed paths against real code (not mocks); TC-4 pins the confidence-before-`is_exec_phase` ordering. `stub_guard_directives` stubs only carry the real `PreToolUse`/`Edit|Write` directives — nothing weakened.

**Test-database / no-production-touch.** Every test writes only under `tempdir(CLEANUP => 1)`; the hook is copied + chmodded in the tempdir (real source untouched); the FindBin-anchored observe log lands in the tempdir; the run-from-subdir setup proves FindBin-anchoring (not cwd-relative). The only real-repo config change is the production default `planning-write-guard: "off"` with `enabled: false` — enables no boundary.

No actionable security concerns in the testing-phase changeset.

```cwf-review
state: no findings
summary: Test files write only to tempdirs, bake in no real secrets, shell out solely on process-generated temp paths, and exercise (not mask) the production fail-closed and no-path-leak guarantees; production diff unchanged and confirmed leak-free.
```
