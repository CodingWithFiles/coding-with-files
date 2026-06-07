# Permission-drift repair and agent guidance - Rollout
**Task**: 183 (feature)

## Task Reference
- **Task ID**: internal-183
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/183-permission-drift-repair-and-agent-guidance
- **Template Version**: 2.1

## Goal
Define how this docs-only convention change reaches the CWF dev repo and downstream consumers.

## Deployment Strategy
### Release Type
- **Strategy**: Single-step documentation release — no phased/canary rollout. The change is three
  edits to non-executable, non-hash-tracked Markdown (`hash-updates.md`, `checkpoint-commit.md`,
  `CLAUDE.md`). There is no runtime component, no schema, no data migration, and no behavioural
  code path: the repair tool (`cwf-manage fix-security`) already exists and is unchanged.
- **Rationale**: A convention/guidance change carries no service risk. Its effect is on agent
  behaviour at the next read of the doc, not on any executing process. Phasing would add ceremony
  without reducing risk.
- **Rollback Plan**: `git revert` the f-phase commit (`6f05c0d`) — or drop the squashed task commit
  from main. Because the files are not hash-tracked and not executable, a revert is a pure text
  change with no `script-hashes.json` or permission follow-up. No state to unwind.

### Delivery path
- **CWF dev repo (this repo)**: lands on `main` when the task branch is merged (human-only;
  suggested at retrospective, not executed by the model).
- **Downstream consumer repos**: receive it through `.cwf/scripts/cwf-manage update`, which lays
  down the updated `.cwf/docs/conventions/hash-updates.md` and `.cwf/docs/skills/checkpoint-commit.md`.
  The project-root `CLAUDE.md` edit is specific to *this* repo (CWF's own dev instructions) and is
  not installed into consumers — consumers reach the rule through the installed convention/skill docs.

### Pre-Deployment Checklist
- [x] Code review completed — plan-review panel (b/c/d) + two exec-phase security reviews, all clean
- [x] All tests passing — TC-SWEEP/RULE/BOUNDARY/POINTERS/XREF/NOSURFACE/REPRO/VALIDATE all PASS (g)
- [x] Security scan completed — `cwf-security-reviewer-changeset` "no findings" at f and g
- [x] Performance testing — N/A (docs; the repair is an on-demand `chmod` already in `fix-security`)
- [x] Documentation updated — this change *is* the documentation
- [x] Monitoring configured — existing `cwf-manage validate` at every checkpoint is the monitor (see i)
- [x] Rollback plan ready — `git revert 6f05c0d`; no hash/perm follow-up

## Rollout Plan
### Phase 1: CWF dev repo
- **Scope**: this repo's `main` after human-approved merge.
- **Duration**: immediate; no soak period needed for a docs change.
- **Success Metrics**: `cwf-manage validate` stays `OK`; the new section renders with a resolving
  `#fix-permission-drift-on-sight` anchor.

### Phase 2: Consumer repos
- **Scope**: any repo that runs `cwf-manage update` after the next release tag.
- **Duration**: at each consumer's update cadence (pull-based, not pushed).
- **Success Metrics**: updated convention/skill docs land; consumer `cwf-manage validate` unaffected
  (the docs are not hash-tracked, so no consumer-side hash churn).

### Phase 3: Full release
- **Scope**: effectively complete once Phase 1 lands — Phase 2 is consumer-paced pull.

## Monitoring
### Key Metrics
- **Behavioural (the real signal)**: future tasks clamp permission drift on sight instead of
  deferring it. Observable as the *absence* of recurring "deferred as a separate backlog item"
  permission entries in BACKLOG/CHANGELOG.
- **Integrity**: `cwf-manage validate` exit status at each checkpoint (already runs in the helper).

### Alerting
- No new alerting infrastructure. `cwf-manage validate` is the existing, sufficient tripwire: a
  permission violation surfaces non-fatally at checkpoint time, which is exactly where the new
  fix-on-sight note now tells the agent to act.

## Rollback Plan
### Triggers
- The guidance is found to be wrong or harmful (e.g. it is read as licence to recompute hashes —
  explicitly guarded against in the text, but the trigger is named for completeness).
- A consumer reports the cross-reference anchor does not resolve.

### Procedure
1. **Immediate**: identify the offending edit (one of three files).
2. **Rollback**: `git revert 6f05c0d` on the dev repo; consumers pick up the revert on next update.
3. **Communication**: note in CHANGELOG; no user-facing service impact to announce.
4. **Analysis**: capture the misread in a follow-up task; the doc text is the unit of change.

## Success Criteria
- [x] Deployment path defined (dev `main` + consumer `cwf-manage update`)
- [x] Rollback is a single `git revert` with no hash/perm follow-up
- [x] Monitoring reuses existing `cwf-manage validate`; no new infrastructure
- [x] No runtime/service risk (docs-only, non-executable, non-hash-tracked)

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout is documentation-only; lands on dev `main` at human-approved merge, reaches consumers via
`cwf-manage update`. No phased soak required. Rollback = `git revert 6f05c0d`.

## Lessons Learned
*To be captured during retrospective*
