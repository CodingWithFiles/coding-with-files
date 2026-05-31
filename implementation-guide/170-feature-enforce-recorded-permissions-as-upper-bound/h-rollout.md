# Enforce recorded permissions as upper bound - Rollout
**Task**: 170 (feature)

## Task Reference
- **Task ID**: internal-170
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/170-enforce-recorded-permissions-as-upper-bound
- **Template Version**: 2.1

## Goal
Ship the ceiling-only permission model. CWF is a file-based tooling system
distributed via git, not a running service — "rollout" here means the
branch→main→tag→consumer-update path, not a phased traffic ramp.

## Deployment Strategy
### Release Type
- **Strategy**: Single squashed commit onto `main`, then a human-applied `v{major}.{minor}.170` tag (archaeological-main methodology). No phased/canary/blue-green — there is no live traffic; the unit of release is a commit + tag.
- **Rationale**: The change is one cohesive integrity-subsystem edit (validator predicate + repair mode + dev-tree perm flip + harness/docs). It cannot be partially shipped: the ceiling check and the `0500` flip must land together or this repo's own `validate` flags the tree (correctness-ordering constraint from c-design). Both already landed in commit `ace8d65`.
- **Rollback Plan**: `git revert` the squashed commit (or reset `main` to the prior tag). The change is self-contained — reverting `Security.pm` + `cwf-manage` + the manifest sha entries restores the floor behaviour; the on-disk `0500` working perms are cosmetic (git does not track `0700`↔`0500`) and re-laid-down by `install.bash`/`exact` mode regardless.

### Pre-Deployment Checklist
- [x] Code review completed (4-subagent plan reviews on b/c/d; two exec-phase security reviews — both `no findings`)
- [x] All tests passing — `prove t/`: 53 files, 634 tests green
- [x] Security scan completed with no critical issues (ceiling/clamp rated a hardening; catches setuid/setgid/sticky acquisition the old floor check ignored)
- [x] Performance validated — one extra bitwise op per already-`stat`-ed entry; no new filesystem reads
- [x] Documentation updated — `.cwf/docs/conventions/hash-updates.md` ceiling section; `Security.pm` header; working-perms memory + MEMORY.md index
- [x] Self-host `validate` clean — `.cwf/scripts/cwf-manage validate` → OK
- [x] Rollback is a single `git revert`

## Rollout Plan
The "phases" for a git-distributed tool are environments, not user percentages:

### Phase 1 — This repo (self-host)
- **Scope**: the CWF development tree itself (eats its own dog food).
- **State**: done — `validate: OK`; full suite green; output-level smoke confirms the ceiling message.

### Phase 2 — Merge to `main` + tag (human-only)
- **Scope**: squash the task branch onto `main`, apply the `v1.{minor}.170` tag, push.
- **Gate**: maintainer review of this task's a–j docs. **Tagging, pushing, and release creation are human-only** (per CLAUDE.md Versioning) — the model does not perform them.

### Phase 3 — Consumer projects (`cwf-manage update`)
- **Scope**: installed projects pull the new release via `cwf-manage update`.
- **Behaviour on update**: laydown runs `exact` mode (sets recorded perms); `exact ⊆ ceiling`, so an updated tree validates clean (covered by `cwf-manage-update-end-to-end.t` FR5).
- **Consumer-visible change**: a previously-installed file that is *more* permissive than recorded now fails `validate` (a new, intended signal); a *less* permissive file that previously failed now passes. `fix-security` clamps the former instead of raising the latter.

## Monitoring
### Key Signals (not a service — these are the checks a maintainer/consumer runs)
- `cwf-manage validate` exit status — the primary post-update health check.
- `cwf-manage fix-security --dry-run` — previews any clamp a consumer's tree would receive.
- CI/`prove t/` on the CWF repo for any follow-up edit touching the integrity subsystem.

### Alerting
- None automated (no service). The integrity check *is* the alert: a non-zero `validate` after update surfaces an over-permissive file, by design.

## Rollback Plan
### Triggers
- A consumer reports a false-positive ceiling violation on a legitimately-installed file (would indicate a recorded value mistakenly too tight).
- `fix-security` clamps a file a maintainer needed *more* permissive (would indicate a recorded ceiling set too low — a manifest data issue, not a code defect).
- Any regression in `prove t/` traced to this change.

### Procedure
1. **Assess**: reproduce with `cwf-manage validate` / `fix-security --dry-run` on the affected tree.
2. **Rollback**: `git revert <squash-sha>` on `main` (restores floor semantics + additive repair), or correct the offending recorded `permissions` value if the code is sound but a manifest value is wrong (the more likely fix).
3. **Re-tag**: human applies a new patch tag for the revert/fix.
4. **Analysis**: capture in a follow-up task's retrospective.

## Success Criteria
- [x] Change landed as one cohesive commit (`ace8d65`); self-host tree validates clean
- [x] All monitoring signals green (`validate: OK`, 634 tests pass)
- [x] Rollback path identified (single revert) and low-risk
- [ ] Merged to `main` + tagged — **pending human action** (out of model scope)

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Change implemented, tested, and security-reviewed on `feature/170-...`. Self-host
validate clean; suite green. Awaiting the human-only merge-to-main + tag to reach
Phase 2/3.

## Lessons Learned
For a git-distributed file tool, "rollout" is the branch→main→tag→`cwf-manage
update` path, and the riskiest property is that `exact`-mode laydown stays ⊆ the
new ceiling — already guarded by the update-e2e FR5 assertion. There is no traffic
to ramp; the integrity check *is* the post-deploy health signal.
