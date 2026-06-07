# Permission-drift repair and agent guidance - Maintenance
**Task**: 183 (feature)

## Task Reference
- **Task ID**: internal-183
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/183-permission-drift-repair-and-agent-guidance
- **Template Version**: 2.1

## Goal
Define ongoing upkeep for the fix-on-sight permission-drift guidance: how it stays correct, how
its effectiveness is observed, and what to do if the deferral failure mode recurs.

## Monitoring Requirements
### What is monitored
- **Integrity tripwire (existing)**: `cwf-manage validate` runs at every checkpoint commit and on
  demand. A permission violation it reports is the exact event the new fix-on-sight note now tells
  the agent to clamp immediately via `cwf-manage fix-security`. No new monitor was added — the
  guidance attaches behaviour to an existing signal.
- **Effectiveness (behavioural)**: the rule is working when permission drift is cleared in-task
  rather than parked. The negative indicator is a *new* BACKLOG/CHANGELOG entry of the form
  "restore permission drift on <files>" / "deferred as a separate backlog item" — i.e. the very
  pattern Task 173/174/182 produced and this task exists to stop.

### Alerting Rules
- **Critical**: none — there is no service.
- **Warning**: `cwf-manage validate` reporting a permission violation that is *not* clamped in the
  same task. Investigation = read the new `hash-updates.md#fix-permission-drift-on-sight` section.
- **Info**: recurrence of a defer-permission-drift backlog item → revisit the D8 forward option below.

## Maintenance Tasks
### Regular upkeep
- **On every task touching a hashed/executable file**: confirm `cwf-manage validate` is `OK` at
  checkpoint; clamp any permission drift on sight (this is now the documented norm).
- **On `cwf-manage` repair-logic changes**: if `fix-security`'s clamp semantics ever change, update
  the `hash-updates.md` section so the quoted command and the "clamp can only clear bits" claim stay
  accurate. The command string is asserted byte-identical to `CWF/Validate/Security.pm`'s `Fix:`
  line — a rename of the subcommand must update all three docs and that test (TC-RULE/TC-XREF).
- **On heading edits**: if the `## Fix permission drift on sight` heading is renamed, update the two
  `checkpoint-commit.md` cross-references and the GitHub anchor slug together (TC-XREF guards this).

### Preventive Maintenance
- Cross-reference integrity: the repo's existing doc conventions apply; the anchor
  `#fix-permission-drift-on-sight` must keep resolving.
- Dead-code audit: N/A (no code added).

## Incident Response
### Common Issues
- **Drift recurs after checkout**: permission bits live in the working tree, not in git
  (`100755`/`100644`). A fresh clone/checkout that materialises a more-permissive umask can re-create
  drift. Resolution: `cwf-manage fix-security` (idempotent). This is expected, not a defect — the
  doc states the working-tree-only nature explicitly.
- **Agent proposes recomputing a hash to clear `validate`**: this is the forbidden smoothing path.
  Resolution: the file's bytes changed; surface it and fix in the originating task per
  `hash-updates.md` "What NOT to build" — never recompute to silence.
- **`validate` flags a sha256 violation**: NOT fix-on-sight. Do not clamp/recompute; surface it.

### Escalation
- There is no on-call. Escalation = open a follow-up CWF task if the guidance is found ambiguous
  or if a structural change (e.g. preamble expansion) is warranted.

## Performance Optimisation
N/A — the repair is an on-demand `chmod` over the recorded set, already part of `fix-security`.

## Documentation
### Runbook (permission drift)
1. `cwf-manage validate` reports a **permission** violation.
2. Run `cwf-manage fix-security` (clamps `actual & recorded`; never raises).
3. `cwf-manage validate` → `OK`; `git status` stays clean (no committable diff).
4. If instead the violation is **sha256/content**: stop — surface it, do not smooth it.

### Forward option (from design D8)
- This task deliberately did **not** expand the hash-tracked, installed `claude-md-preamble.md`
  (kept minimal/reversible). If the deferral failure mode recurs in *consumer* repos — where the
  dev-repo `CLAUDE.md` pointer is not installed and only the convention/skill docs carry the rule —
  the recorded next step is to add a one-line fix-on-sight pointer to `claude-md-preamble.md`,
  accepting the hash refresh that entails. Trigger: a consumer-repo recurrence of deferred
  permission drift. Not actioned now (no evidence it is needed).

## Success Criteria
- [x] Monitoring reuses existing `cwf-manage validate`; effectiveness indicator named
- [x] Upkeep triggers documented (command rename, heading rename, clamp-semantics change)
- [x] Common issues + runbook documented (drift recurrence, sha256-is-not-fix-on-sight)
- [x] D8 forward option recorded with its trigger condition

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Upkeep is doc-correctness maintenance only: keep the quoted command and heading anchor in sync
across the three files if `fix-security` is renamed. Monitoring is the existing `cwf-manage
validate`. D8 preamble-expansion recorded as a triggered-not-actioned forward option.

## Lessons Learned
*To be captured during retrospective*
