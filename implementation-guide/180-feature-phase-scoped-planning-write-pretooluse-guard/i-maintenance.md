# phase-scoped planning-write PreToolUse guard - Maintenance
**Task**: 180 (feature)

## Task Reference
- **Task ID**: internal-180
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/180-phase-scoped-planning-write-pretooluse-guard
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for phase-scoped planning-write PreToolUse guard.

## Monitoring Requirements
No service to monitor — this is a per-tool-call hook + a pure lib. The signals an
operator/maintainer watches:
- **Observe log** (`.cwf/sandbox-violations.log`, gitignored, shared with R3):
  during `observe`, would-block crown-jewel writes. Operator-facing, **untrusted**
  — never re-feed into an LLM.
- **`cwf-manage validate`**: integrity of the hook (`0500`) + `CWF::PlanningGuard`
  (no perms key) + the helper/`Config.pm` hashes. Run after any edit to these.
- **Registration**: `cwf-claude-settings-merge --dry-run` should show the guard
  under `PreToolUse` with matcher `Edit|Write` when the knob is on.
- **Per-call cost**: ~37 ms crown / ~26 ms non-crown (baseline). Watch for gross
  regression past ~50 ms (e.g. if TCI's git fan-out grows).

## Maintenance Tasks
### Coupling points to keep in sync (the real maintenance burden)
- **Workflow phase names** ↔ `CWF::PlanningGuard` `%EXEC_PHASES` (currently
  `implementation-exec` only) and `%KNOWN_PHASES`. If phases are renamed/added/
  re-lettered (a v2.x change), update both sets — `is_exec_phase` strips the
  `^[a-j]-` prefix, so a letter swap alone is safe, but a *name* change is not.
- **TCI contract**: the hook depends on `infer_task_context` returning
  `confidence` ∈ {correlated,…} and a scalar `workflow_step` only when correlated.
  If `CWF::TaskContextInference` changes that shape, update the hook's mapping.
- **Claude Code PreToolUse schema**: the deny envelope
  (`hookSpecificOutput.permissionDecision`/`permissionDecisionReason`) and the
  input shape (`tool_name`, `tool_input.file_path`) track Claude Code. On a Claude
  Code upgrade, re-confirm against the hooks doc; `t/pretooluse-planning-write-guard.t`
  TC-9's real-payload fixture is the binding check — if it still parses, the
  envelope is current.
- **Enum single-source**: `PLANNING_GUARD_VALUES` lives once in `CWF::PlanningGuard`
  and is consumed by both validators + the registration gate. Never re-hand-type
  `{off,observe,enforce}` elsewhere.
- **Hash-update discipline**: any edit to the hook / lib / helper / `Config.pm`
  refreshes `script-hashes.json` in the **same commit** (`hash-updates.md`), with
  working perms restored to recorded (0500 hook, 0600 libs).
- **Dead-code audit**: see `.cwf/docs/dead-code-audit.md` — periodic sweep.

### Log hygiene
`.cwf/sandbox-violations.log` is append-only and shared with R3; it is the
operator's responsibility to truncate/rotate. CWF does not manage retention.

## Incident Response
### Common Issues
- **Guard denies a legitimate planning-time write.** *Symptom*: a crown-jewel
  Edit/Write is blocked with `crown-jewel:.cwf|.claude phase:<x>`. *Diagnosis*: the
  phase token names the inferred phase — if it is a planning phase, that is the
  guard working as designed; if `phase:unknown`, TCI could not resolve (ambiguous
  context). *Resolution*: do the edit inside an implementation-exec phase, or set
  the knob to `observe`/`off` for ad-hoc maintenance; re-run the merge.
- **Guard not firing when expected.** *Diagnosis*: check `sandbox.enabled: true`
  AND `planning-write-guard != off`, then `cwf-claude-settings-merge --dry-run` for
  the `PreToolUse`/`Edit|Write` group. A directive that drifted out of the hook's
  **leading comment block** would not register (by design) — keep the
  `cwf-hook-event`/`cwf-hook-matcher` lines in the header.
- **Every Edit/Write denied (total brick).** Should be impossible — the tool-gate
  passes non-Edit/Write through and non-crown writes short-circuit. If seen,
  suspect `find_git_root` returning the wrong root (everything misclassified) or a
  corrupt knob read; fastest mitigation is the knob → `off` rollback.

### Escalation
Single-maintainer project: triage via the deny token + `cwf-manage validate` +
the dry-run; if the code is at fault, the knob-`off` rollback disables it without a
code revert (see h-rollout).

## Documentation
- **User-facing**: `.cwf/docs/sandboxing.md` § "Planning-write guard".
- **Design/decision record**: this task's a–j workflow files (crown-jewel
  deny-list, fail-closed posture, lib/hook split, the R3 directive-scan fix).

## Success Criteria
- [x] Monitoring signals defined (observe log, validate, dry-run, per-call cost)
- [x] Coupling points + hash-update discipline documented for future maintainers
- [x] Common-issue runbook with the knob-off rollback path
- [x] Performance baseline recorded (g-testing-exec)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
