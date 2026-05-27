# hierarchy-aware consistency validation - Rollout
**Task**: 164 (feature)

## Task Reference
- **Task ID**: internal-164
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/164-hierarchy-aware-consistency-validation
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for hierarchy-aware consistency validation.

## Deployment Strategy
### Release Type
- **Strategy**: Standard CWF release. The change is a single hash-tracked library module
  (`.cwf/lib/CWF/Validate/Consistency.pm`) plus its in-commit `script-hashes.json` refresh and
  test. It ships the normal way: squash the task branch, fast-forward `main` (human-only), the
  maintainer tags a new `v{major}.{minor}.164` (human-only per CLAUDE.md), and adopters pull it
  via `.cwf/scripts/cwf-manage update`.
- **Rationale**: No phased/canary mechanism exists or is warranted — `validate` is an advisory,
  read-only, local check with no service, no network, no user data. Its exit-code contract for
  existing flat-repo cases is unchanged (FR5/AC5), so the update is non-breaking. The only
  behavioural delta an adopter sees is *more* accurate output: subtask dirs now validated,
  parent false-positives gone, and the new completeness violation.
- **Rollback Plan**: `.cwf/scripts/cwf-manage rollback` restores the prior installed release;
  for CWF's own repo, `git revert` of the squashed commit. Either is safe — no migration, no
  persisted state, no schema.

### Pre-Deployment Checklist
- [x] Code reviewed (plan-review on b/c/d; exec-phase security review on f/g — both `no findings`)
- [x] All tests passing (`prove t/` = 600/600; `t/validate-consistency.t` 20/20)
- [x] Security review completed, no findings (f and g changesets)
- [x] Performance: single linear pass, no per-node rescan (NFR1); no perceptible delta on the live repo
- [x] Integrity: `script-hashes.json` refreshed in the implementation commit; `cwf-manage validate` clean
- [x] Docs: module header rewritten to describe the three hierarchy checks; no user-facing doc references the internal behaviour
- [x] Rollback path confirmed (`cwf-manage rollback` / `git revert`), no state to unwind

## Rollout Plan
CWF distributes as a unit — there is no per-user fractional rollout. Effective sequence:
1. **Land on main**: maintainer fast-forwards `main` to the squashed task commit (human-only).
2. **Tag**: maintainer applies the `v{major}.{minor}.164` semver tag (human-only).
3. **Adopters update**: `cwf-manage update` pulls the release on each adopter's next update.

### Adopter-visible impact
- Decomposed-parent false positive (the originating bug report, subtask on `feature/N.M` vs
  parent `feature/N`) no longer fires.
- Subtask directories are now field-validated (previously silent) — a latent wrong
  `**Task**`/`**Branch**` in a subtask may surface as a *new, correct* violation on first run.
- New completeness violation: a terminal parent with an active descendant is now reported.

## Monitoring
No telemetry (local CLI tool). Post-update verification per adopter: run `cwf-manage validate`
and confirm output is the expected accurate set. The CWF repo's own CI (`prove t/`) is the
regression guard.

## Rollback Plan
### Triggers
- A regression in flat-repo validation output (would contradict FR5 — none observed).
- A crash/`die` on a malformed tree (NFR5 covers graceful degradation; TC-W/TC-S1 guard it).
- A false-positive class judged worse than the bug it fixed.

### Procedure
1. **Assess**: capture the offending `cwf-manage validate` output and the task tree shape.
2. **Rollback**: `cwf-manage rollback` (adopter) or `git revert <squash-sha>` (CWF repo).
3. **Re-open**: file a follow-up task with the reproducing fixture; no state to clean up.

## Success Criteria
- [x] Change is releasable via the standard squash → main → tag → `cwf-manage update` path
- [x] Existing flat-repo validation output unchanged (FR5)
- [x] Rollback procedure identified and state-free
- [ ] Maintainer lands + tags (human-only; out of this task's automated scope)

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout plan tailored to CWF's actual distribution (squash → main → human tag →
`cwf-manage update`); the generic SaaS canary/SLA template did not apply. Change confirmed
non-breaking for flat repos and state-free to roll back.

## Lessons Learned
For an advisory local CLI, "rollout" is release-mechanics + adopter-visible-delta, not
phased traffic — the meaningful content is the list of new/changed violations adopters see.
