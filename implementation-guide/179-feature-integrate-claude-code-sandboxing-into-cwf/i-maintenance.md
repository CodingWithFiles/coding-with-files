# Integrate Claude Code sandboxing into CWF - Maintenance
**Task**: 179 (feature)

## Task Reference
- **Task ID**: internal-179
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/179-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Ongoing maintenance for CWF-managed sandboxing. CWF is a documentation/tooling
system — there is no runtime fleet, SLA, or scaling concern. Maintenance here
means integrity, the coupling to Claude Code's sandbox/permission API, the R3
log, and the 179.1 follow-up.

## Monitoring Requirements
- **Integrity (standing)**: `cwf-manage validate` must stay clean. The new hook
  (`pretooluse-sandbox-logging`) and the edited helper/`Config.pm`/
  `install-manifest` are hash-tracked; any future edit refreshes its `sha256`
  **in the same commit** (`.cwf/docs/conventions/hash-updates.md`). The R3 log
  is deliberately **not** hash-tracked (runtime state, like `.cwf/task-stack`).
- **R3 violation log**: `.cwf/sandbox-violations.log` (opt-in). Operator-facing,
  best-effort proxy — **never** an audit trail, **never** re-fed into an LLM.
- **No service metrics**: no uptime/throughput/error-rate monitoring applies.

## Maintenance Tasks
- **On every Claude Code release** (the key external coupling): re-confirm the
  load-bearing behaviours this feature assumes still hold —
  1. `~` expands to `$HOME` in `Read(...)` permission rules and in
     `sandbox.filesystem.denyRead` (the residual item; if it ever stops, the
     deny goes hollow — re-open as a bugfix);
  2. the sandbox stays **Bash-only** (Read/Edit/Write still bypass it — the
     premise of the *paired* rule design);
  3. `failIfUnavailable` / `dangerouslyDisableSandbox` / `allowUnsandboxedCommands`
     keys keep their names and semantics;
  4. no new structured sandbox-violation event appears (if one does, R3 should
     graduate from the `dangerouslyDisableSandbox` proxy to the real event).
- **Log growth**: `.cwf/sandbox-violations.log` is append-only and unbounded. It
  is gitignored and low-volume (only `dangerouslyDisableSandbox` bypasses), but
  if an adopter reports growth, document truncation/rotation as a follow-up — do
  **not** add a rotation subsystem speculatively (AC5b: reuse, don't build one).
- **Dep drift (Linux)**: `bubblewrap`/`socat` availability is the adopter's
  responsibility; the advisory guard surfaces absence at merge time.
- **Dead-code audit**: include the new helper subs + hook in the periodic sweep
  (`.cwf/docs/dead-code-audit.md`).

## Incident Response — common issues
- **"Claude Code won't start" after enabling** — on Linux without
  `bubblewrap`+`socat`, or on native Windows/WSL1, with `fail-if-unavailable:
  true` the sandbox can't initialise. *Resolution*: install the deps (the merge
  helper names them), or set `sandbox.fail-if-unavailable: false`, or use WSL2 /
  macOS. Expected, documented in `.cwf/docs/sandboxing.md`.
- **"A credential file is still readable by a Bash command"** — check both
  halves landed: `sandbox.filesystem.denyRead` AND the `Read(...)` denies. If the
  agent used `dangerouslyDisableSandbox`, that is the agent-reachable escape
  hatch — set `permissions.allowUnsandboxedCommands: false` to harden (CWF does
  not set it for you). Env-resident secrets need `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`.
- **"My hand-edited `failIfUnavailable` keeps reverting"** — by design: the knob
  is authoritative (single source of truth). Change
  `cwf-project.json` → `sandbox.fail-if-unavailable`, not the generated
  `settings.json`; put non-CWF overrides in `settings.local.json`.
- **"My `Read(...)` deny disappeared after toggling off"** — by design
  (ownership-by-shape, c-design D2): the generated `settings.json` `Read(...)`
  region is CWF-owned. Put personal Read denies in `settings.local.json`.
- **`cwf-manage validate` flags a `sandbox` hash/schema issue** — fix in the
  task that edited the file, in-diff; never recompute a hash at retrospective to
  silence the signal.

## Follow-up Work
- **Subtask 179.1 (seeded, BACKLOG)**: R1 phase-scoped planning-write PreToolUse
  guard — needs the matcher regex widened to `Edit|Write` and a
  fail-closed-without-bricking design reusing `task-context-inference`. This task
  deliberately widened only the **event** allowlist (the clean seam R1 reuses).

## Success Criteria
- [x] Integrity model documented (hash-tracked vs runtime-state boundary).
- [x] External-coupling watch-list defined (re-check per Claude Code release).
- [x] Common adopter issues + resolutions documented.
- [x] Follow-up (179.1) recorded and linked.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
