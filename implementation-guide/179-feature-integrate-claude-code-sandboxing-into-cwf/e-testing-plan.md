# Integrate Claude Code sandboxing into CWF - Testing Plan
**Task**: 179 (feature)

## Task Reference
- **Task ID**: internal-179
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/179-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Define how the build is verified against b-requirements FR1–FR7 and the c-design validation
rows, using the existing Perl harness (`t/cwf-claude-settings-merge.t`, `t/validate-config.t`)
plus `cwf-manage validate`. TDD — these cases are written failing first (d-plan order).

## Test Strategy
### Test Levels
- **Unit (Perl `t/`)**: validator block; helper config-read/type-recheck; paired-rule
  emission; ownership-by-shape reconcile; dep-probe; hook registration.
- **String-form (Perl `t/`)**: emitted rule strings equal the doc-specified forms. The suite
  **cannot** exercise Claude Code's runtime matcher — `~`-expansion / `allowRead`-narrowing
  are re-verified against current docs at exec and **cited** (d-Step 3), with a fail-closed
  fallback if no form expands.
- **Regression**: sandbox-OFF golden file (byte/semantic identical to current output); full
  `t/` suite green; `cwf-manage validate` clean.
- **No system/E2E tier** for runtime sandbox enforcement (owned by Claude Code + the OS — the
  enforcement-ownership boundary; FR7).

### Coverage Targets
- **Critical path (100%)**: master toggle OFF default + no-regression; R2 paired emission +
  reconcile removal; `failIfUnavailable` authoritative; malformed-surfaces; R3 registration +
  fail-open. Every FR AC maps to ≥1 TC below.
- **Edge cases**: absent file vs absent block vs unparseable vs malformed-block; AC1c
  identical-collision; changed-list-then-OFF orphan; empty PATH segment; log-write failure.

## Test Cases
### Functional
- **TC-1 (FR1/AC1a-b — toggle OFF default + no regression)**: Given a config with no
  `sandbox` block (and separately, file absent), When `cwf-claude-settings-merge --dry-run`,
  Then zero `sandbox.*` / `permissions.deny` keys and `allow`/`hooks`/`PERL5OPT` match a
  golden file from the current helper. Exit 0.
- **TC-2 (FR1/AC1d — absent vs malformed)**: Given (a) absent file, (b) absent block,
  (c) unparseable JSON, (d) wrong-typed switch / non-array list; Then (a)(b) ⇒ silent OFF
  exit 0; (c)(d) ⇒ surfaced `[CWF] ERROR:` (never silent-OFF).
- **TC-3 (FR1/AC1e — schema validation)**: `_validate_sandbox_block` flags non-bool switches
  and non-array/non-string list; absent block ⇒ no violation; absent list + `enabled:true` ⇒
  no violation. Via `t/validate-config.t`.
- **TC-4 (FR2/AC2a-b — paired rules)**: Given `enabled:true`, list `[~/.ssh, ~/.aws]`, Then
  `sandbox.filesystem.denyRead` = the list AND `permissions.deny` = `Read(P)`+`Read(P/**)`
  per entry.
- **TC-5 (FR2/AC2c — rule form + behaviour)**: emitted strings equal the doc-specified forms;
  exec re-verifies (cited) that `Read(~/…)` expands to `$HOME` and `allowRead` narrows a
  `denyRead` default; if no form expands ⇒ merge surfaces+refuses (fail-closed), asserted.
- **TC-6 (FR1/FR2/AC1c — ownership-by-shape reconcile)**: ON ⇒ managed set present; OFF/absent
  ⇒ whole `sandbox.*` + all CWF-shaped `Read(...)` removed; **non-CWF deny (`Bash(curl *)`)
  preserved**; **AC1c collision: user-authored `Read(~/.ssh)` identical to a CWF default IS
  removed on OFF** (documented intended); changed-list-then-OFF ⇒ no orphan; idempotent re-run
  no-op; `allow`/`hooks`/`PERL5OPT` untouched.
- **TC-7 (FR3/AC3a — `failIfUnavailable` authoritative)**: ON ⇒ `true` default; knob `false` ⇒
  reflected; hand-set differing value ⇒ warn-not-overwrite, **warning fires under `--dry-run`
  and on repeat** (mirror `merge_env`); value re-checked as JSON bool before write.
- **TC-8 (FR3/AC3b — dep probe + guard)**: missing `bwrap`/`socat` (simulated PATH) ⇒
  fixed-token message naming the package + knob; **empty/`.` PATH segment not resolved to
  cwd**; probe never blocks generation; no probe-output interpolation in the message.
- **TC-9 (FR5/AC5a-c — R3 hook)**: with a manifest fixture, `PreToolUse`+`Bash` registers
  under PreToolUse (not Stop-fallback); a `|` matcher still rejected; `violation-logging:false`
  ⇒ no registration; `dangerouslyDisableSandbox` present ⇒ one fixed-key JSON record
  (timestamp + presence-flag, **no raw command**); malformed stdin ⇒ fail-open (eval);
  log-write failure ⇒ swallowed, never blocks.
- **TC-10 (FR6/AC6a-d — substrate)**: event allowlist = `{Stop, SubagentStop, PreToolUse}`;
  matcher regex unchanged; writes only to `.claude/settings.json` (self-protected target);
  user-authored non-CWF keys preserved across merges.
- **TC-11 (FR7 — limitations doc)**: the `.cwf/docs/` page states advises-not-enforces,
  Bash-only, agent-reachable escape hatch, no-reliable-violation-event, fail-closed-while-true,
  **and the env-inheritance / `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` caveat**; reachable from the
  `sandbox` config docs.
- **TC-12 (FR4/AC4d — R1 split)**: a single live backlog entry for 179.1 (grep count == 1);
  `backlog-manager validate --all` exit 0; body names the matcher-regex-widening + fail-closed
  requirements.

### Non-Functional
- **Security**: no path silences `cwf-manage validate` (the log write leaves `validate`
  clean — TC-13); R3 record carries no attacker-controlled string; dep names are compile-time
  literals; fixed-token guard message.
- **Performance (NFR1)**: bounded per-call cost note for the R3 hook (lighter than R1 — no
  `task-context-inference`); spawn-dominated, recorded not asserted as an SLA.
- **Reliability**: idempotent merge; absent ⇒ OFF, malformed ⇒ surface; never corrupts an
  existing `.claude/settings.json` (round-trip preserves unknown user keys).
- **TC-13 (integrity)**: the gitignored R3 log path is **not** hash-tracked and a runtime
  write to it leaves `cwf-manage validate` clean; `script-hashes.json` refreshed in the same
  commit for helper + `Config.pm` + new hook.

## Test Environment
### Setup
- Perl harness under `t/`; fixtures for `cwf-project.json` variants (absent/absent-block/
  unparseable/malformed/ON/OFF) and a **manifest fixture** for hook-registration tests (TC-9 —
  decoupled from the live `script-hashes.json` so Steps 5/7 aren't circular). Simulated `PATH`
  for TC-8. No production `.claude/settings.json` mutated by tests (write to temp).
### Automation
- `prove t/`; the golden-file comparison (TC-1); `cwf-manage validate` (TC-13). No external CI.

## Validation Criteria
- [ ] TC-1..TC-13 pass.
- [ ] Full `t/` suite green; `cwf-manage validate` clean.
- [ ] `--dry-run` ON and OFF both correct; sandbox-OFF golden file matches.
- [ ] Single live 179.1 backlog entry; same-commit hash refresh confirmed.
- [ ] Security/reliability non-functional checks pass.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
