# phase-scoped planning-write PreToolUse guard - Rollout
**Task**: 180 (feature)

## Task Reference
- **Task ID**: internal-180
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/180-phase-scoped-planning-write-pretooluse-guard
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for phase-scoped planning-write PreToolUse guard.

## Deployment Strategy
### Release Type
- **Strategy**: Ship-dark, opt-in via the `planning-write-guard` enum knob. CWF is
  distributed as in-repo tooling, so "deployment" is: merge to main → tag/release
  (human-only) → adopters pull via `cwf-manage update`. The feature is
  **off by default** (`sandbox.planning-write-guard: "off"`, and `sandbox.enabled:
  false`), so the merge itself changes **no** runtime behaviour for any install.
- **Rationale**: The fail-closed enforcing posture is the one higher-stakes path in
  the sandboxing feature (it can deny a write). Shipping it dark + opt-in lets the
  knob *be* the rollout dial — adopters move `off → observe → enforce` at their own
  pace. No code-level canary is needed because the knob already provides one.
- **Rollback Plan**: see *Rollback Plan* below — set the knob to `off` (or
  `sandbox.enabled: false`) and re-run `cwf-claude-settings-merge`, which
  deregisters the hook. No code revert required to disable.

### Pre-Deployment Checklist
- [x] Code review completed (4-reviewer plan reviews on b/c/d; 2 exec-phase
      `cwf-security-reviewer-changeset` passes — both **no findings**)
- [x] All tests passing — full `t/` suite 686 green; 77 task-specific
- [x] Security scan — exec security reviews (impl + testing) recorded, no findings
- [x] Performance validated — NFR1 measured (crown 36.9 ms/call, non-crown
      25.9 ms/call; both under the ~50 ms budget)
- [x] Documentation updated — `.cwf/docs/sandboxing.md` "Planning-write guard"
      section + knob in the config example
- [x] Monitoring configured — observe-mode log (`.cwf/sandbox-violations.log`,
      gitignored, shared with R3) is the dry-run signal; see *Monitoring*
- [x] Rollback tested — knob `off`/absent → hook not registered (TC-PG2a, TC-12)

## Rollout Plan (per adopting repo — the knob is the dial)
### Phase 1: `observe`
- **Scope**: enable `sandbox.enabled: true` + `planning-write-guard: "observe"`,
  re-run `cwf-claude-settings-merge`. Crown-jewel planning-writes are **permitted**
  but logged (fixed-key record, no raw path) to `.cwf/sandbox-violations.log`.
- **Success signal**: review the log over a few real planning sessions — every
  entry should be a genuine crown-jewel edit that *should* wait for exec, with no
  false positives on task-own / BACKLOG / scratch writes (which never log).

### Phase 2: `enforce`
- **Scope**: flip the knob to `"enforce"`. Crown-jewel writes outside an
  implementation-exec phase are now **denied** with a fixed-token reason.
- **Success signal**: planning proceeds without spurious denials; the only denials
  are real out-of-phase crown-jewel writes.

### Phase 3: steady state
- Keep at `enforce`, or drop to `observe`/`off` for ad-hoc `.cwf`/`.claude`
  maintenance done outside a CWF task (a known edge — see the doc).

## Monitoring
### Key Signals
- **Observe log** (`.cwf/sandbox-violations.log`): would-block / blocked crown-jewel
  writes. Operator-facing, untrusted — never re-fed to an LLM.
- **Per-call cost**: the hook spawns once per Edit/Write; crown writes pay the TCI
  cost (~37 ms), non-crown writes short-circuit (~26 ms). A gross regression past
  ~50 ms is the watch threshold.
- **Registration drift**: `cwf-manage validate` clean + a `--dry-run` of
  `cwf-claude-settings-merge` showing the guard under `PreToolUse` with matcher
  `Edit|Write` when the knob is on.

### Alerting
- No automated alerting (CWF has no telemetry service). The signals above are
  operator-inspected. A wrong-event/missing-matcher registration would surface in
  the dry-run; an integrity drift in `cwf-manage validate`.

## Rollback Plan
### Triggers
- The guard denies a legitimate planning-time write that cannot be reclassified.
- Per-call overhead regresses materially past the ~50 ms budget.
- Any integrity / registration anomaly from `cwf-manage validate`.

### Procedure (no code revert needed to disable)
1. **Immediate (operator)**: set `sandbox.planning-write-guard: "off"` (or
   `sandbox.enabled: false`) in `cwf-project.json`.
2. **Re-merge**: run `cwf-claude-settings-merge` — the gate (`$register_guard`)
   deregisters the hook; `.claude/settings.json` returns to its prior shape.
3. **Full revert (maintainer, if the code itself is at fault)**: `git revert` the
   Task-180 squash commit; note this also reverts the `read_hook_directives`
   directive-scan fix, so R3 would again misregister — prefer the knob route.
4. **Analysis**: capture the offending classify/decide inputs (the deny token names
   the phase) and add a regression case to `t/planning-guard.t`.

## Success Criteria
- [x] Feature merges dark — zero behaviour change for installs with the knob off
- [x] Opt-in path documented (`observe` → `enforce`) with a per-repo dial
- [x] Rollback is a knob flip + re-merge (no code revert to disable)
- [ ] (post-merge, human) main updated + version tagged/released

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
