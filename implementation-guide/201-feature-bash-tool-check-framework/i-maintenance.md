# Bash tool-check framework - Maintenance
**Task**: 201 (feature)

## Task Reference
- **Task ID**: internal-201
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/201-bash-tool-check-framework
- **Template Version**: 2.1

## Goal
Define ongoing maintenance and support for the Bash tool-check framework. This is a
local, file-based, fail-open hook — there is no running service, no uptime SLA, and no
fleet to monitor. Maintenance is the operator's interaction with the rule files plus
the standard CWF integrity machinery.

## Monitoring Requirements
### System Health
- **No service to monitor.** The hook runs synchronously inside each `Bash` PreToolUse
  invocation and exits. Health is observed through CWF's existing integrity tooling, not
  through uptime/latency metrics.
- **Integrity**: `cwf-manage validate` confirms the hook (`0500`) and lib hashes match
  `script-hashes.json`. A mismatch is the primary health signal — surface it, never smooth.
- **Latency**: Per-match work is bounded by the in-process 2s `Time::HiRes::alarm`, the
  64 KB command cap, and ultimately the harness `timeout`. No external monitoring needed.

### Operator-facing signals
- **`--check` diagnostic**: the operator's window into effective behaviour — lists dropped
  checked-in `perl` rules, overridden ids, and the final active set. Human-terminal only;
  never piped back into agent context.
- **Denials**: each carries the matched rule's verbatim guidance, so a misfiring rule is
  self-identifying.

## Maintenance Tasks
### Routine
- **On rule change**: run `--check` to preview the merged ruleset before relying on it.
- **On hook/lib edit**: refresh the matching `script-hashes.json` sha256 in the same
  commit (per `.cwf/docs/conventions/hash-updates.md`); deferring defeats the integrity check.
- **Per release**: `cwf-manage validate` after `update` confirms the hook installed intact
  and the gitignore line for `settings.local.json` is present.
- **Dead-code audit**: include `ToolCheck.pm` and the hook in periodic sweeps
  (see `.cwf/docs/dead-code-audit.md`).

### Rule-set hygiene (operator)
- Prune stale rules: the offending-command set drifts per model and per Claude Code
  version, so rules that once helped can become noise. Disable via `enabled:false` or
  remove the rule entirely.
- Keep `perl` rules only in the two non-cloned layers (user-global, project-local); a
  checked-in `perl` rule is dropped before compilation by design.

## Incident Response
### Common Issues
- **Hook denies a command it should not**: the rule is too broad. Operator disables it
  (`enabled:false`) or removes the rule file; no release required. Repeat-bypass also
  releases an identical second attempt to the native permission prompt automatically.
- **`cwf-manage validate` reports a hash mismatch on the hook/lib**: integrity signal.
  Investigate the diff; if legitimate, refresh the hash in the editing commit; if not,
  treat as tampering. Never add tooling that silences this without surfacing first.
- **A rule never fires**: likely an over-cap command (>64 KB → refuse-to-match) or a
  `perl` rule in the checked-in layer (dropped at load). `--check` shows the dropped set.

### Troubleshooting Guide
- **Symptom**: unexpected allow/deny. **Diagnosis**: run `--check` to see the effective
  ruleset and which layer won each id. **Resolution**: adjust the owning layer; re-run `--check`.
- **Symptom**: `Bash` behaviour unchanged after adding rules. **Diagnosis**: confirm the
  rule file path matches a recognised layer and the JSON parses (`--check` reports parse
  failure non-zero). **Resolution**: fix the path/JSON.

### Escalation
- Local tool, single operator. No on-call tiers. A latent fail-open defect (hook aborts
  `Bash` rather than degrading to no-op) is the only condition warranting a project-level
  fix and follow-up release — back out per h-rollout's rollback procedure.

## Documentation
- **Operator reference**: `.cwf/docs/tool-check-rules.md` (schema, trust table, merge
  semantics, repeat-bypass, `--check`, safety posture).
- **Conventions touched**: `hash-updates.md` (in-task hash refresh), `tmp-paths.md`
  (state dir derivation).

## Success Criteria
- [x] Health/integrity signals identified (`cwf-manage validate`, `--check`)
- [x] Routine maintenance tasks documented (rule change, hook edit, per-release check)
- [x] Common issues documented with operator-level resolutions
- [x] Escalation scoped to the single fail-open defect class

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance model recorded: no service monitoring; integrity via `cwf-manage validate`,
behaviour via `--check`, and operator-owned rule-set hygiene. The only project-level
incident class is a fail-open defect, handled by the h-rollout rollback path.

## Lessons Learned
*To be captured during retrospective*
