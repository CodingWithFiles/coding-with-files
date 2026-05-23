# Converge cwf-manage update onto install.bash - Retrospective
**Task**: 155 (feature)

## Task Reference
- **Task ID**: internal-155
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/155-converge-cwf-manage-update-onto-install-bash
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-23

## Executive Summary
- **Duration**: ~1 working session across 2026-05-22→23 (estimated 1–2 weeks; consolidated 3 prior backlog entries).
- **Scope**: Delivered as **subtree-only convergence** — the subtree update path now delegates laydown to the target ref's `install.bash`; the copy path deliberately retains `update_copy`. Narrower than the original "single shared laydown for both methods", by design.
- **Outcome**: Success. The chicken-and-egg / squash-conflict / staging-dir-drift failure modes are structurally fixed for the subtree path (the dominant install method). Copy-method convergence filed as a Low backlog follow-up.

## Variance Analysis
### Time and Effort
- **Estimated**: 1–2 weeks, High complexity, 3 milestones.
- **Actual**: One session. Phase split was harness-first (Milestone 1), then convergence+chmod (Milestones 2–3), matching the plan's sequencing.
- **Variance**: Large under-run vs the calendar estimate. The estimate was framed for human effort consolidating three backlog items; the realised work was a focused single-surface change once the harness made it testable. The complexity rating (High) was accurate — the risk was real, the wall-clock was not.

### Scope Changes
- **Reductions**: (1) Convergence scoped to the subtree path only — the copy path keeps `update_copy` + `create_*_symlinks` because re-implementing the `_escapes_src` symlink-escape guard in bash was judged worse than two laydown implementations. (2) `cwf-apply-artefacts` left un-narrowed (narrowing would strip rule delivery from the copy path).
- **Additions**: None beyond plan. The end-to-end harness was built in-test (programmatic upstream) rather than as a checked-in `t/fixtures/` tree — simpler, one source of CWF content.
- **Impact**: One success criterion ("install and update share *one* laydown") is only **partially** met — single ownership exists for the subtree path, not the copy path. The remaining four criteria are fully met. The gap is tracked, not silent.

### Quality Metrics
- **Test Coverage**: Full suite 46 files / 505 tests green; new `t/cwf-manage-update-end-to-end.t` 5/5 (FR2/FR3/FR5/FR6/FR9/FR10). `cwf-manage validate` clean.
- **Defect Rate**: Zero product defects. Two fixture-shaped bring-up issues (uncommitted install state; non-TTY apply-artefacts), both test-harness shaping, not product bugs.
- **Security**: Implementation-phase changeset review — no findings. Testing-phase changeset exceeded the 500-line auto-review cap; manual review of the test-only addition recorded as clean.

## What Went Well
- **Harness-first sequencing paid off**: building the end-to-end fixture before touching the updater meant the high-risk convergence had a green/red signal at every step. The plan's Milestone 1 ordering was the right call.
- **Delegation cleanly dissolved the chicken-and-egg**: having the subtree update shell out to the *target* ref's `install.bash` (via `CWF_FORCE` remove-then-add, list-form `system`, pinned resolved SHA) means future cross-version jumps run the new laydown, not the installed-old one.
- **Authoritative version write** resolved the feared double-write: `cmd_update` overwriting install.bash's base version file (restoring real `cwf_source`, pinning manifest SHA once) was cleaner than re-read-and-augment.
- **Security posture held**: backtick→list-form conversion of `resolve_ref`/`resolve_sha` removed the real injection vector; the exact-perms guard stays fatal-on-mismatch ("surface, never smooth").

## What Could Be Improved
- **The implementation plan over-scoped the deletion list**: d-implementation-plan.md listed deleting `create_skill_symlinks`/`create_agent_symlinks` and narrowing `cwf-apply-artefacts` — both unsafe once the copy path is retained. The plan reasoned as if convergence were total; the copy-path dependency surfaced only in exec. A sharper design-phase question ("does the copy path go through install.bash? no → what still needs the old helpers?") would have caught this at c, not f.
- **The 500-line security-review cap** was tripped in the testing phase purely because the changeset re-includes the already-reviewed implementation diff plus one test file. The cap is coarse for a phase whose net-new content is small; manual review was sound but the friction is worth noting.

## Key Learnings
### Technical Insights
- **Convergence is bounded by primitive parity**: two laydown paths can only merge as far as the lower-level language can express the higher one's safety guards. The copy path's `_escapes_src` symlink-escape check has no cheap bash equivalent, so full single-ownership is gated on porting that primitive — not on the convergence logic itself.
- **Updater fixes are structurally forward-only**: because the *installed* (old) `cwf-manage` runs the update, no shipped fix repairs installs already on a pre-fix updater. The right response is to document the one-time bootstrap recovery, not to attempt an impossible self-repair.

### Process Learnings
- **Design-phase path enumeration**: when collapsing two code paths, explicitly list which call sites each shared helper serves *before* writing the deletion list. The over-scoped plan was a reasoning gap at design time, recoverable only because exec re-checks the plan.
- **Estimation framing**: "weeks" estimates inherited from backlog consolidation don't translate to agent wall-clock; the complexity/risk ratings were the useful signal, the duration was not.

### Risk Mitigation Strategies
- Building the test substrate first (the plan's top-listed high-risk mitigation) was the single most effective decision — it converted a scary delivery-path change into an incrementally-verified one.

## Recommendations
### Process Improvements
- Add a design-phase checklist item for convergence/refactor tasks: "for each helper being deleted or narrowed, list its remaining callers" — would have caught the over-scoped deletion list at c.

### Tool and Technique Recommendations
- Consider whether the exec-phase security-review changeset should diff against the *previous phase's* anchor rather than the task baseline, so a small testing-phase delta isn't dominated by the already-reviewed implementation diff (would avoid the 500-line cap trip). Noted, not actioned.

### Future Work
- **Copy-method convergence** (BACKLOG, Low): port the symlink-escape guard so the copy update path can also delegate to `install.bash`, retiring `update_copy` and achieving full single-ownership.
- **Manifest-schema-bump coverage**: the end-to-end harness pins `cwf_install_manifest_sha` but does not exercise a schema version bump; add a case when the schema next changes.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-23
**Sign-off**: Task maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, b-requirements-plan.md, c-design-plan.md
- Implementation: d-implementation-plan.md, f-implementation-exec.md (3 documented deviations)
- Testing: e-testing-plan.md, g-testing-exec.md, `t/cwf-manage-update-end-to-end.t`
- Delivery: h-rollout.md, i-maintenance.md, INSTALL.md § "Recovering an install stuck on an old cwf-manage"
- Commits: 08adaae(a) ccba15b(b) 7b39182(c) b9c93b5(d) a917a02(e) d9af333(f) 8985cd5(g) a8d5469(h) 77a2989(i)
