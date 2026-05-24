# converge cwf-manage copy update onto install.bash - Rollout
**Task**: 161 (feature)

## Task Reference
- **Task ID**: internal-161
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/161-converge-cwf-manage-copy-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Define how the copy-method convergence and the extracted symlink-escape guard reach CWF consumers, and how to revert if a consumer update regresses.

## Deployment Strategy
### Release Type
- **Strategy**: Tag-based release. CWF is a documentation/tooling system distributed by git tag, not a running service — no live deployment surface, traffic split, or user cohort. The change ships when the maintainer squash-merges the task branch to `main` and cuts the next `v{major}.{minor}.161` tag (both human-only per CLAUDE.md Versioning).
- **Rationale**: Consumers pull a specific tag via `cwf-manage update <tag>` or `install.bash` (`CWF_REF`). Phased exposure is the consumer's choice of which tag to pin, not something this repo orchestrates.
- **Forward-only caveat**: the copy-method delegation lives in the installed copy of `.cwf/scripts/cwf-manage`. A consumer on a pre-161 tag who runs `cwf-manage update <161-tag>` executes their *old* `update_copy`/`copy_tree` path to lay down the new tree — so the convergence (and the guard on the copy-update path) only takes effect from the *next* update onward, or immediately via an `install.bash` bootstrap reinstall. The fresh-install guard (`install.bash` copy path) is live for anyone installing at the 161 tag immediately. This is the rollout's known reach limit, not a defect.
- **Trust-model note (design D4)**: when the new path does run, the guard executes from the *target-version* clone (`$clone_dir/.cwf/scripts/command-helpers/cwf-check-tree-symlinks`), not the installed copy — so it validates the tree it is about to copy with that tree's own guard. The `[[ -x "$guard" ]] || die` precheck fails closed if a (pre-guard) target ref lacks the helper.

### Pre-Deployment Checklist
- [x] Code review completed (plan-review subagents on b/c/d; exec-phase security review — no findings on both f and g)
- [x] All tests passing (full suite 49 files / 533 tests; +6 new subtests TC-3..TC-8; new `cwf-check-tree-symlinks.t`)
- [x] Security scan completed (implementation- and testing-phase changeset reviews: no findings; guard centralised into one integrity-covered helper, net hardening — the previously-unguarded fresh copy path is now covered)
- [x] Performance validated (NFR1: one lexical `File::Find` walk over the source roots, no disk-following; same order of cost as the inline guard it replaces)
- [x] Documentation: no consumer-facing doc surface changed (internal laydown convergence); `cwf-manage` help text unaffected
- [x] Integrity refreshed (`script-hashes.json`: new `cwf-check-tree-symlinks` entry + refreshed `cwf-manage` sha256, same commits; `cwf-manage validate` clean)
- [ ] Squash-merge to `main` + version tag (human-only — out of model scope)

## Rollout Plan
Tag-based, so the "phases" are the order in which consumers receive the change, not a percentage ramp this repo controls.

### Phase 1: This repo (dogfood)
- **Scope**: CWF's own repo, on squash-merge to `main`.
- **Validation**: `prove -lr t/` green and `cwf-manage validate` clean on `main` post-merge.

### Phase 2: New installs
- **Scope**: Any consumer running `install.bash` at the 161 tag. The copy path now runs the symlink-escape guard *before* any `rm -rf`/`cp`, so a tampered source tree is refused with no partial laydown — coverage the fresh copy path previously lacked.
- **Success signal**: a clean source installs identically to the subtree path (`.cwf-rules` once, matching `.claude/rules` symlinks); a source containing an out-of-tree symlink is refused with `refusing to install: source tree contains an out-of-tree symlink` and leaves any existing install intact.

### Phase 3: Existing copy-method installs
- **Scope**: Consumers on a prior tag running `cwf-manage update <161-tag>` with `cwf_method=copy`. After this update lands, *subsequent* copy updates delegate to `install.bash` (single laydown path, guarded).
- **Limit**: the update that *delivers* this convergence is still run by the old updater's `update_copy`, so that one transition uses the pre-161 (unguarded, divergent) laydown; it is converged from the next update onward, or immediately via the INSTALL.md bootstrap reinstall.

## Monitoring
No telemetry exists or is added — CWF runs entirely in the consumer's repo. Health is observed through deterministic gates, not metrics:
- **Integrity**: `cwf-manage validate` (SHA256 + recorded perms) after any update — now also covers `cwf-check-tree-symlinks`.
- **Laydown correctness**: a copy install/update produces the same tree as a subtree install (`t/install-bash-reinstall.t` TC-6 parity is the regression sentinel).
- **Guard correctness**: `t/cwf-check-tree-symlinks.t` (unit + CLI) and the `install.bash` guard-before-`rm -rf` ordering (`t/install-bash-reinstall.t` TC-3/TC-4) are the regression sentinels for any future change to the guard or the copy path.
- **Consumer signal**: bug reports / issues are the only external feedback channel; there is no dashboard or alert pipeline.

## Rollback Plan
### Triggers
- A consumer copy update leaves `validate` failing, or lays down a tree that diverges from the subtree path (convergence regression).
- The guard fails open: a fresh copy install proceeds past an out-of-tree symlink, or `install.bash` copies before running the guard (ordering regression).
- The guard fails closed incorrectly: a clean source tree is refused (false positive in `cwf-check-tree-symlinks`).

### Procedure
1. **Consumer-side**: `cwf-manage rollback <prior-tag>` returns to the last-good version. If the installed updater itself is implicated, use the INSTALL.md bootstrap recovery against the prior tag.
2. **Repo-side**: revert the squash commit on a new task branch and re-tag — a normal git revert; nothing external to undo.
3. **Communication**: note the regression on the issue tracker; no users to notify directly.
4. **Analysis**: extend the relevant `t/` harness to cover the missed path before re-attempting (captured in retrospective if it occurs).

## Success Criteria
- [x] Deployment model documented and matched to CWF's tag-based distribution
- [x] Pre-deployment gates green (533 tests, validate, security review)
- [x] Forward-only reach limit (copy convergence runs from the installed updater) and its bootstrap recovery documented
- [x] Rollback procedure defined (consumer `rollback` + repo revert)
- [ ] Tag/merge to main — deferred to the maintainer (human-only)

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance 161
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout is documentation-only this phase: the change is staged on the task branch awaiting human squash-merge and tag. The fresh-install guard (`install.bash` copy path) is live immediately for anyone installing at the 161 tag; the copy-method *update* convergence is forward-only (delivered by the consumer's old updater, effective from the next update or via bootstrap reinstall). The guard runs from the target-version clone (design D4) and fails closed via the `[[ -x ]]` precheck if a pre-guard ref lacks the helper.

## Lessons Learned
The fresh-install path and the update path have different reach: the `install.bash` copy guard protects new installs immediately, but the copy-*update* convergence is forward-only because it is run by the consumer's old `cwf-manage`. Documenting that asymmetry — rather than engineering a self-repair — was the rollout's job. See j-retrospective.md.
