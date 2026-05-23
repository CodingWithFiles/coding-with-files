# Converge cwf-manage update onto install.bash - Rollout
**Task**: 155 (feature)

## Task Reference
- **Task ID**: internal-155
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/155-converge-cwf-manage-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Define how the convergence change reaches CWF consumers and how to revert if a consumer update regresses.

## Deployment Strategy
### Release Type
- **Strategy**: Tag-based release. CWF is a documentation/tooling system distributed by git tag, not a running service — there is no live deployment surface, traffic split, or user cohort. The change ships when the maintainer squash-merges the task branch to `main` and cuts the next `v{major}.{minor}.155` tag (both human-only per CLAUDE.md Versioning).
- **Rationale**: Consumers pull a specific tag via `cwf-manage update <tag>` (subtree) or `install.bash` (CWF_REF). Phased exposure is the consumer's choice of which tag to pin, not something this repo orchestrates.
- **Forward-only caveat**: `cwf-manage update` is run by the consumer's *installed* (old) updater, so this fix only reaches installs made after the tag carrying it. Installs predating the fix recover via the bootstrap path documented in INSTALL.md § "Recovering an install stuck on an old cwf-manage" (`CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<url> bash install.bash`). This is the rollout's known reach limit, not a defect.

### Pre-Deployment Checklist
- [x] Code review completed (plan-review subagents on b/c/d; exec-phase security review — no findings)
- [x] All tests passing (full suite 46 files / 505 tests; new end-to-end 5/5)
- [x] Security scan completed (implementation-phase changeset review: no findings; testing-phase: manual review of test-only file, clean)
- [x] Performance validated (NFR1: end-to-end suite ~5s, no multi-minute hang)
- [x] Documentation updated (INSTALL.md recovery section; BACKLOG copy-method follow-up)
- [x] Integrity refreshed (`script-hashes.json` cwf-manage sha256 same-commit; `cwf-manage validate` clean)
- [ ] Squash-merge to `main` + version tag (human-only — out of model scope)

## Rollout Plan
Tag-based, so the "phases" are the order in which consumers receive the change, not a percentage ramp this repo controls.

### Phase 1: This repo (dogfood)
- **Scope**: CWF's own repo, on squash-merge to `main`.
- **Validation**: `prove -l t/` green and `cwf-manage validate` clean on `main` post-merge.

### Phase 2: New installs
- **Scope**: Any consumer running `install.bash` at the new tag gets the converged updater immediately (clean remove-then-add laydown).
- **Success signal**: `cwf-manage status` reports the new version; `validate` clean.

### Phase 3: Existing subtree installs
- **Scope**: Consumers on a prior tag running `cwf-manage update <new-tag>`. The converged subtree path delegates laydown to the target ref's `install.bash`, clearing the chicken-and-egg / squash-conflict / staging-dir-drift failure modes (FR2/FR3/FR5).
- **Success signal**: cross-version-gap update succeeds and `validate` is clean (covered by end-to-end TC-FR2/FR3/FR5).
- **Limit**: installs predating *this* fix use the INSTALL.md bootstrap recovery once; subsequent updates use the fixed updater.

## Monitoring
No telemetry exists or is added — CWF runs entirely in the consumer's repo. Health is observed through deterministic gates, not metrics:
- **Integrity**: `cwf-manage validate` (SHA256 + recorded perms) after any update.
- **Update correctness**: the end-to-end harness (`t/cwf-manage-update-end-to-end.t`) is the regression sentinel for future updater changes.
- **Consumer signal**: bug reports / issues are the only external feedback channel; there is no dashboard or alert pipeline to wire up.

## Rollback Plan
### Triggers
- A consumer update leaves `validate` failing, or laydown is incomplete (exact-perms guard fires fatally rather than silently repairing).
- Cross-version update regresses on a path the end-to-end suite does not cover.

### Procedure
1. **Consumer-side**: `cwf-manage rollback <prior-tag>` returns to the last-good version (downgrade path verified by TC-FR6b). If the installed updater itself is implicated, use the INSTALL.md bootstrap recovery against the prior tag.
2. **Repo-side**: revert the squash commit on a new task branch and re-tag — the change is a normal git revert; nothing external to undo.
3. **Communication**: note the regression on the issue tracker; no users to notify directly.
4. **Analysis**: extend the end-to-end harness to cover the missed path before re-attempting (captured in retrospective if it occurs).

## Success Criteria
- [x] Deployment model documented and matched to CWF's tag-based distribution
- [x] Pre-deployment gates green (tests, validate, security review)
- [x] Forward-only reach limit and its recovery path documented
- [x] Rollback procedure defined (consumer `rollback` + repo revert), downgrade tested
- [ ] Tag/merge to main — deferred to the maintainer (human-only)

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance 155
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout is documentation-only this phase: the change is staged on the task branch awaiting human squash-merge and tag. All consumer-facing delivery paths (new install, subtree update, downgrade) are exercised by the end-to-end harness; the forward-only reach limit and its bootstrap recovery are documented in INSTALL.md.

## Lessons Learned
Tag-based distribution has no live rollout surface, so the generic phased-ramp template doesn't apply. The meaningful rollout risk is the forward-only reach of an updater fix (the *old* installed updater runs the update); the mitigation is the documented one-time bootstrap recovery, not a self-repair attempt. See j-retrospective.md.
