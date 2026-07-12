# unresolved-decisions gate for a-task-plan - Maintenance
**Task**: 228 (feature)

## Task Reference
- **Task ID**: internal-228
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/228-unresolved-decisions-gate-a-task-plan
- **Template Version**: 2.1

## Goal
Define ongoing maintenance for the unresolved-decisions gate. This is a guidance-only change to
three documentation surfaces — there is no runtime service to monitor, so maintenance reduces to
keeping the three surfaces in sync and periodically confirming the gate changes planning behaviour.

## Monitoring Requirements
No runtime monitoring applies — nothing is deployed, no process runs, no metrics are emitted. The
only observable is qualitative: whether newly generated `a-task-plan` files carry a populated
`## Open Decisions` section and keep success criteria outcome-shaped rather than mechanism-named.

- **System Health / Uptime / Resource Usage**: N/A — no runtime component.
- **Error Rates**: N/A — no executable surface. The single structural failure mode (a reader
  mis-parsing the inserted H2) was proven impossible in TC-3 (marker-based parsing, not positional).
- **Effectiveness signal (qualitative)**: presence of a real `## Open Decisions` list and the
  absence of mechanism-named criteria in subsequent in-repo planning phases.

## Maintenance Tasks
### Three-surface sync (the one durable obligation)
The gate lives in three files that must stay mutually consistent:
- `.cwf/docs/workflow/workflow-steps/planning.md` — **authority** (definition, litmus, examples).
- `.cwf/templates/pool/a-task-plan.md.template` — **prompt** (`## Open Decisions` + criteria note).
- `.claude/skills/cwf-task-plan/SKILL.md` — **gate** (two `## Success Criteria` checklist items).

Maintenance rule: any change to the mechanism-named definition or the Open-Decisions contract is
made in `planning.md` first; the template and skill reference it and must not restate the
definition (single source of truth — enforced by convention, re-checked by the misalignment
reviewer on any future exec touching these files).

### Regular schedule
- **Per planning phase (continuous)**: the skill's two checklist items are the live gate — no
  scheduled task needed; the check runs every `/cwf-task-plan`.
- **Opportunistic**: when a future task edits any of the three files, verify the other two still
  agree and cross-references stay backticked (`docs/conventions/cross-doc-references.md`).
- **None of daily/weekly/quarterly ops apply** — no dependencies, no DB, no logs, no backups.

## Incident Response
### Common Issues
- **Cross-reference drift**: a future edit renames the `## Open Decisions` heading or the
  planning.md anchor, leaving the template/skill pointing at a stale target. *Resolution*: keep
  the heading name and anchor stable; if renamed, update all three surfaces in the same task.
- **Definition divergence**: someone restates the mechanism-named definition in the template or
  skill and the two copies drift. *Resolution*: delete the restatement, reference `planning.md`.
- **Structural-reader regression**: hypothetical future reader keys off document position rather
  than markers and trips on the mid-document H2. *Resolution*: keep readers marker-based
  (`CWF::TaskState::status_get`); TC-3 is the regression guard.

### Troubleshooting Guide
- **Symptom**: a generated `a-task-plan` lacks `## Open Decisions`. **Diagnosis**: the per-type
  symlink no longer resolves to the edited pool file, or the pool edit was reverted. **Resolution**:
  `readlink -f` the per-type template symlinks against the pool file; re-apply the pool edit.
- **Symptom**: `cwf-manage validate` flags one of the three files. **Diagnosis**: a file became
  hash-tracked (it should not be). **Resolution**: surface, do not smooth — investigate why it
  entered `script-hashes.json` before refreshing anything.

### Escalation
N/A — single-maintainer documentation change; no on-call tiers.

## Performance Optimisation
N/A — no runtime path, no queries, no caching, no scaling surface. The change adds one static
section to a template; token cost at generation time is negligible and fixed.

## Documentation
### Runbooks
- The maintenance rule above (edit `planning.md` first; template/skill reference it) is the whole
  runbook. No emergency procedure — the change is trivially revertible (see h-rollout.md).

### Knowledge Base
- Rationale, definition, and worked examples live in `planning.md` — the durable record.
- Design decisions D1–D5 (why guidance-only, why a new H2, why additive) are in c-design-plan.md.

## Success Criteria
- [x] Monitoring assessed — none applicable (guidance-only, no runtime); qualitative signal named.
- [x] Maintenance obligation documented — the three-surface sync rule, authority-first.
- [x] Common issues documented with resolutions (drift, divergence, reader regression).
- [x] Effectiveness check defined (populated Open Decisions + outcome-shaped criteria in future plans).
- [x] Next steps suggested.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance for this change is the standing three-surface sync obligation plus a qualitative
effectiveness check; no runtime monitoring, alerting, scaling, or scheduled ops apply. Common
failure modes (cross-reference drift, definition divergence, structural-reader regression) are
documented with resolutions, each defended by an existing convention or the TC-3 regression guard.

## Lessons Learned
Maintenance of a multi-surface guidance change reduces to one durable rule: edit the authority
doc (`planning.md`) first, keep the template and skill referencing it, never restating it.
