# Integrate Claude Code sandboxing into CWF - Rollout
**Task**: 179 (feature)

## Task Reference
- **Task ID**: internal-179
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/179-integrate-claude-code-sandboxing-into-cwf
- **Template Version**: 2.1

## Goal
Ship Task 179 (CWF-managed Claude Code sandboxing) safely. CWF is a
documentation/tooling system, not a running service — "rollout" is delivery to
adopters via the release boundary, and the change is **default-OFF**, so it
alters no adopter's behaviour until they opt in.

## Deployment Strategy
### Release Type
- **Strategy**: Single linear release on `main`, delivered to adopters at the
  next CWF release via `cwf-manage update` (no phased/canary infrastructure —
  CWF has no runtime fleet). The feature is **off by default**.
- **Rationale**: `sandbox.enabled` defaults OFF and `cwf-claude-settings-merge`
  writes **zero** sandbox/`permissions.deny` keys while off (TC-1). Merging is
  therefore behaviour-preserving for every existing adopter — the risky surface
  only activates on a deliberate opt-in. This makes a graduated rollout
  unnecessary; the toggle itself is the safety mechanism.
- **Rollback Plan**: see § Rollback — the toggle is the primary, per-adopter
  rollback; a full revert is the maintainer fallback.

### Pre-Deployment Checklist
- [x] Code review completed — plan reviews (b/c/d, 4 reviewers each) + two
      exec-phase security reviews (implementation + testing): **no findings**.
- [x] All tests passing — full suite **665 PASS**; TC-1..TC-13 mapped and green.
- [x] Security scan — `cwf-manage validate: OK`; R3 log not hash-tracked;
      same-commit hash refresh for helper + `Config.pm` + `install-manifest` +
      new hook (f-commit `16c1356`).
- [x] Performance — R3 hook recorded at ~15 ms/call, spawn-dominated, no git /
      no `task-context-inference` (g-exec NFR1).
- [x] Documentation — `.cwf/docs/sandboxing.md` shipped (advises-not-enforces,
      Bash-only, env-scrub caveat); template carries a `_sandbox-note` pointer.
- [x] Rollback plan documented (below) and inherently exercised — TC-6 proves
      toggle-OFF removes the whole CWF-owned region with no orphan.
- [ ] **Residual live confirmation** — see § Adopter enablement step 4.

## Rollout Plan
Delivery is a single release, not a percentage ramp. The phases below are the
adopter's opt-in journey, not a fleet rollout.

### Phase 1 — Merge + release (maintainer, default-OFF)
- Squash `feature/179-…` to `main` (human-only; see retrospective Suggest-Merge).
- Tag `v1.1.179` (human-only). The shipped `cwf-project.json` carries
  `sandbox.enabled: false` — adopters who `cwf-manage update` get the feature
  dormant.

### Phase 2 — Adopter opt-in (per adopter, when they choose)
See § Adopter enablement. Until an adopter sets `sandbox.enabled: true` and
re-runs the merge helper, nothing changes for them.

### Phase 3 — Steady state
Sandboxing on for adopters who opted in; R1 (phase-scoped planning writes)
arrives later via subtask **179.1**.

## Adopter enablement (the opt-in runbook)
1. Edit `implementation-guide/cwf-project.json` → `sandbox.enabled: true`
   (optionally adjust `credential-deny-list`, `fail-if-unavailable`,
   `violation-logging`). `cwf-manage validate` checks the block.
2. Run `.cwf/scripts/command-helpers/cwf-claude-settings-merge` to regenerate
   `.claude/settings.json` (paired `denyRead` + `Read(...)` denies appear).
3. **Linux**: install `bubblewrap` + `socat` (the helper warns, advisory, if
   absent while on). **macOS**: Seatbelt, nothing to install. Native Windows /
   WSL1: no sandbox — with `fail-if-unavailable: true` Claude Code will refuse
   to start (expected; flip the knob or use WSL2).
4. **Residual verification (carried from g-exec):** confirm once, live, that
   Claude Code expands `~` in the generated `Read(~/…)` permission rules to
   `$HOME` (the Perl suite tests the string form; runtime matcher expansion is a
   Claude Code property asserted from Task 178's first-hand finding). Quick
   check: with sandboxing on, confirm a Read of `~/.ssh/…` is denied. If a
   future Claude Code release ever stopped expanding `~` in `Read(...)`, the
   deny would be hollow — re-open as a bugfix.
5. Read `.cwf/docs/sandboxing.md` for the limitations (Bash-only; agent-reachable
   `dangerouslyDisableSandbox`; env-resident creds need
   `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`).

## Monitoring
- **R3 violation log** (opt-in): `.cwf/sandbox-violations.log` records
  `dangerouslyDisableSandbox` bypass attempts (presence flag only). Operator-
  facing, best-effort proxy — **not** an audit trail, never re-fed into an LLM.
- **`cwf-manage validate`**: the standing integrity check; a malformed `sandbox`
  block surfaces here and at merge time (never silent-OFF).
- No service metrics/alerting apply (no runtime fleet).

## Rollback Plan
### Triggers
- A merge-helper defect mis-writes `.claude/settings.json` or weakens the
  boundary; a malformed-config path that fails to surface; an adopter report of
  bricked startup not explained by missing deps.
### Procedure
1. **Per-adopter (primary, instant):** set `sandbox.enabled: false` and re-run
   `cwf-claude-settings-merge`. Reconcile-by-shape removes the entire CWF-owned
   `sandbox.*` + `Read(...)` region (TC-6) — no residue, user keys untouched.
2. **Maintainer (fallback):** revert the Task 179 commit on `main` and cut a
   patch release. Because the feature is default-OFF, no adopter who never opted
   in is affected either way.
3. **Communication / analysis:** note in CHANGELOG; root-cause as a new bugfix
   task (hash-refresh + security review apply as normal).

## Success Criteria
- [x] Change is behaviour-preserving while OFF (TC-1) — safe to merge.
- [x] Reversible via the toggle (TC-6) — rollback path proven.
- [x] Docs + enablement runbook shipped.
- [ ] Merged + tagged (human-only; deferred to retrospective Suggest-Merge).
- [ ] Residual live `~`-expansion confirmation at first real opt-in.

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
