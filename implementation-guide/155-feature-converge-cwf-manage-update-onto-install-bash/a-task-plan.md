# Converge cwf-manage update onto install.bash - Plan
**Task**: 155 (feature)

## Task Reference
- **Task ID**: internal-155
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/155-converge-cwf-manage-update-onto-install-bash
- **Baseline Commit**: 084837ad3a48741bcf5f85679a95a89514f1d30f
- **Template Version**: 2.1

## Goal
Replace the duplicated subtree/copy/symlink laydown logic in `scripts/install.bash` and `cwf-manage`'s update path with a single shared install-lifecycle implementation, so install and update cannot drift and a cross-version update runs the *target* version's laydown.

## Success Criteria
- [ ] Install and update share one laydown implementation; adding a staging dir requires editing one place, not symmetric edits in two scripts (verified structurally).
- [ ] `cwf-manage update` across a multi-version gap completes without `git subtree pull --squash` add/add conflicts (verified by end-to-end fixture test).
- [ ] Update runs the target version's laydown logic, structurally breaking the chicken-and-egg for future cross-version jumps.
- [ ] Post-update chmod end-state matches `fix-security`'s exact recorded perms (no blanket `0755` divergence); `cwf-manage validate` passes post-update.
- [ ] Accreted update-only steps — `cwf-apply-artefacts`, `cwf-claude-settings-merge`, manifest-SHA pin (D12), update lock — are preserved, not regressed.

## Original Estimate
**Effort**: ~1-2 weeks (consolidates 3 prior backlog entries)
**Complexity**: High
**Dependencies**: `scripts/install.bash`, `.cwf/scripts/cwf-manage`, helpers `cwf-apply-artefacts` / `cwf-claude-settings-merge` / `fix-security`

## Major Milestones
1. **Testable substrate**: end-to-end fixture harness (bare upstream remote + scripted multi-version history) so the convergence is verifiable.
2. **Shared laydown**: single install-lifecycle implementation extracted; both install and update consume it.
3. **Convergence + chmod**: update delegates to the target version's laydown via the `CWF_FORCE` remove-then-add path; blanket `chmod 0755` replaced with `fix-security` per-entry perms.
4. **Recovery documented**: one-time `CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<src> bash install.bash` path for installs stuck on a pre-fix `cwf-manage`.

## Risk Assessment
### High Priority Risks
- **Breaking the delivery mechanism**: this path is how CWF installs/updates itself; a regression breaks all consumers.
  - **Mitigation**: build the end-to-end harness first; isolate the risky convergence in its own subtask with independent validation.
- **Chicken-and-egg is forward-only**: nothing shippable repairs installs already on a pre-fix `cwf-manage`, since the *old* updater performs the update.
  - **Mitigation**: accept the structural fix is forward-only; document the one-time `CWF_FORCE` recovery path.

### Medium Priority Risks
- **Regressing accreted update-only steps** (apply-artefacts, settings-merge, manifest-SHA pin, lock) when collapsing the two paths.
  - **Mitigation**: enumerate each in a shared post-install step and assert each in the end-to-end test.
- **Approach choice** (bash lib under `scripts/lib/` vs single Perl helper vs update shelling out to the cloned `install.bash`) has long-term maintenance implications.
  - **Mitigation**: decide in the design phase (c); the backlog favours shell-out-to-install.bash.

## Dependencies
- No external/team dependencies (solo, internal tooling task).
- Builds on Task 115 (`CWF_SOURCE` fix already landed), Task 143 (`.cwf-agents` work), Task 120/127 follow-ups.

## Constraints
- POSIX-only, core-Perl-only, Bash 4+ (existing install.bash constraint).
- `cmd_update` must not regress its accreted steps; `install.bash`'s `.cwf/version` write must not double-write against `cmd_update`'s manifest-SHA logic.
- Hash refreshes to `script-hashes.json` happen in the same commit as the `cwf-manage` modification.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? Likely yes — consolidates 3 prior entries.
- [ ] **People**: Does this need >2 people? No (solo).
- [x] **Complexity**: 3+ distinct concerns — (1) shared-laydown convergence, (2) chmod reconciliation, (3) end-to-end fixture harness. **Triggered.**
- [x] **Risk**: High-risk install/update path benefits from isolation with its own validation. **Triggered.**
- [x] **Independence**: The fixture harness and chmod reconciliation are separable from the core convergence. **Triggered.**

**3 signals triggered (Complexity, Risk, Independence) → decomposition strongly recommended.** Decision: **keep monolithic** (user, 2026-05-22). The three concerns will be planned together but kept as separable milestones within one task; the fixture harness is sequenced first so the convergence is testable.

## Decomposition Recommendation (not adopted — see decision above)
Subtasks were considered but the user chose to keep the work monolithic. The concerns map to internal milestones instead:
- **Milestone 1 (harness)** — `t/fixtures/upstream-server/` + `t/cwf-manage-update-end-to-end.t`. Sequenced first to make the convergence testable.
- **Milestone 2-3 (convergence + chmod)** — extract single laydown, update delegates to target's `install.bash` via `CWF_FORCE` remove-then-add, fold in chmod reconciliation, preserve accreted steps.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 155
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Kept monolithic as decided. Delivered in one session as **subtree-only** convergence (copy path retained). 4 of 5 success criteria fully met; criterion 1 ("install and update share one laydown") partially met — single ownership for the subtree path only.

## Lessons Learned
Harness-first sequencing (the top-listed high-risk mitigation) was the decisive call — it turned a delivery-path change into an incrementally-verified one. The "1–2 weeks" estimate didn't translate to agent wall-clock; the High complexity/risk ratings were the useful signal, the duration was not. See j-retrospective.md.
