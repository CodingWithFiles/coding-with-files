# R3 shell-hygiene convention and allowlist seed - Rollout
**Task**: 227 (feature)

## Task Reference
- **Task ID**: internal-227
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/227-r3-shell-hygiene-convention-and-allowlist-seed
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for R3 shell-hygiene convention and allowlist seed.

## Deployment Strategy
### Release Type
- **Strategy**: Trunk merge + git-tagged release, consumed downstream via `cwf-manage update`.
  CWF ships as a documentation/helper system, not a running service — there is no
  blue-green/canary axis. "Deploy" = the change lands on `main` behind a `v1.1.227` tag;
  installed repos pick it up on their next `cwf-manage update`.
- **Rationale**: Matches CWF's actual delivery model (archaeological squashed main; per-phase
  checkpoints preserved off-main). The seed rides the existing `cwf-claude-settings-merge`
  path, so it reaches a repo the next time that helper runs (init or update) — no separate
  rollout mechanism.
- **Rollback Plan**: `cwf-manage rollback` on the downstream side; on the source side, revert
  the merge commit. Additive-only change (5 read-only allow entries + a new doc) with an
  idempotent merge, so rollback is low-risk and non-destructive — see below.

### Pre-Deployment Checklist
- [x] Code review completed — 5-reviewer exec MAP (f) + 2-reviewer MAP (g), all clean save one
      misalignment finding fixed in-phase (markdown-link → inline-backtick cross-refs)
- [x] All tests passing — `prove -r t/` PASS (Files=78, Tests=1078); settings-merge 51 subtests
- [x] Security scan — `cwf-manage validate` OK; both edited hash-tracked files' sha256 refreshed
      and independently verified (`sha256sum`)
- [x] Performance — N/A (compile-time constant + one extra `push`; no runtime cost path)
- [x] Documentation updated — `shell-hygiene.md` (new), FR3 anchor in `cwf-agent-shared-rules.md`,
      `CLAUDE.md` conventions entry
- [x] Monitoring/alerting — N/A for a docs/helper system; the fail-closed test gate is the
      standing regression guard
- [x] Rollback plan tested and ready — additive + idempotent; revert-merge / `cwf-manage rollback`

## Rollout Plan
Single-step for a documentation/helper release; no phased user cohorts apply.

### Phase 1: Merge + tag (human-only)
- **Scope**: Squash the phase branch onto `main`; maintainer tags `v1.1.227`. Per CWF policy,
  tagging, pushing tags, creating releases, and merging to main are **human-only** — this phase
  suggests the command; it does not execute it.
- **Success Metric**: `main` HEAD carries the seed + doc; `cwf-manage validate` OK on `main`.

### Phase 2: Downstream adoption
- **Scope**: Installed repos receive the change on their next `cwf-manage update`. The 5 read-only
  entries are merged into `.claude/settings.json` via the idempotent `merge_allow` path.
- **Success Metric**: Post-update, the corpus is present in `permissions.allow`; opt-out is a
  user/`.local`-layer `deny`/`ask` rule (documented in `shell-hygiene.md`), which wins by
  precedence.

### Phase 3: Full release
- **Scope**: Tagged release is the full release — no percentage gating.

## Monitoring
### Key Metrics
- **Integrity**: `cwf-manage validate` remains OK on `main` (the two refreshed hashes hold).
- **Regression**: `prove -r t/` stays green (the fail-closed `is_read_only_safe` gate).
- **Adoption correctness**: after a downstream `cwf-manage update`, the 5 entries appear and no
  broader prefix (e.g. `git branch:*`) leaked in.

### Alerting
- No live alerting surface (offline docs/helper system). A failing `validate` or a red `t/` run
  is the signal; the redirection/substitution residual is tracked as a Medium backlog discovery
  item, not an alert.

## Rollback Plan
### Triggers
- `cwf-manage validate` fails post-merge (hash/permission drift)
- Downstream `merge_allow` mis-seeds (wrong entry, broadened prefix, duplication)
- A corpus entry is discovered not to be read-only for its whole glob space

### Procedure
1. **Immediate**: Stop further tagging/announcement; assess scope (source vs downstream).
2. **Rollback**: Source side — revert the merge commit on `main`. Downstream — `cwf-manage
   rollback` to the prior release; the additive+idempotent merge means removing the 5 entries
   restores the prior `permissions.allow` with no side effects.
3. **Communication**: Note in BACKLOG/retrospective; no external stakeholders for an internal task.
4. **Analysis**: Root-cause in the retrospective (j); if the residual probe is implicated, fold
   into the seeded backlog item.

## Success Criteria
- [x] Deployment strategy defined with rationale (trunk merge + `cwf-manage update`)
- [x] Pre-deployment checklist completed (all green / N/A justified)
- [x] Phased rollout plan specified (merge+tag → downstream adoption → full)
- [x] Rollback plan documented (revert-merge / `cwf-manage rollback`; additive+idempotent)
- [ ] Merge to main + tag — **human-only**, pending maintainer action

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout is planned, not yet executed: the merge-to-main + `v1.1.227` tag is a human-only action
(CWF policy). Everything upstream of that gate is complete — the change is committed on the phase
branch, all tests pass, `validate` is OK, and both edited hash-tracked files carry refreshed
sha256 entries. The change is additive (5 read-only allow entries) and idempotent through the
existing `merge_allow` path, so downstream adoption via `cwf-manage update` needs no bespoke
rollout step.

### Suggested merge (human-only — do not auto-execute)
```
git checkout main && git merge --ff-only feature/227-r3-shell-hygiene-convention-and-allowlist-seed
```
(Or the project's squash-onto-main flow, followed by the maintainer's `v1.1.227` tag.)

## Lessons Learned
- For a docs/helper release the generic blue-green/canary rollout template collapses to a single
  meaningful gate — the human-only trunk merge + tag. The value of the phase is the rollback
  characterisation (additive + idempotent + revert-merge), not a phased-cohort plan.
