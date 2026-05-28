# install manifest baselines disagree with subtree - Plan
**Task**: 167 (bugfix)

## Task Reference
- **Task ID**: internal-167
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/167-install-manifest-baselines-disagree-with-subtree
- **Baseline Commit**: 4c084418a05b3a95f6f176a1a30d5913719bbd52
- **Template Version**: 2.1

## Goal
Sync `.cwf/install-manifest.json` baseline SHAs with the content actually shipped by the `.cwf` subtree so non-interactive `cwf-manage update` runs no longer abort on phantom drift conflicts.

## Background
A downstream consumer running `cwf-manage update v1.1.155 → v1.1.163` under a Claude Code agent reported the update aborting at `cwf-apply-artefacts` on a `rules-inject` conflict. Investigation showed:

- The `.cwf` subtree at v1.1.155 and v1.1.163 ships `.cwf/rules-inject.txt` as **331 bytes** (SHA `8c5efa38…`) — identical at both versions.
- `install-manifest.json` records the `rules-inject` baseline as `sha256: e3b0c442…` (the SHA of an **empty file**), pointing at `source: .cwf/templates/install/rules-inject.txt` (0 bytes).
- `cwf-apply-artefacts:392-407` compares on-disk (`8c5efa38…`) to the prior installed manifest's baseline (also `e3b0c442…` because the manifest never changed), sees on-disk ≠ baseline, and reports the file as drifted. With no TTY available the conflict prompt aborts.

The defect has existed since **Task 127** (`215cbf7`, when `cwf-apply-artefacts` was first introduced — 38 tasks ago). The defect was flagged in Task 158's retrospective as an out-of-scope "latent oddity" but never filed for follow-up. Every consumer who runs a non-interactive `cwf-manage update` across this range hits this conflict, *regardless of whether they customised the file*.

## Success Criteria
- [ ] **AC1**: Every artefact entry in `install-manifest.json` has a `sha256` (or per-file SHA for tree entries) that matches the SHA of the file/blob actually laid down by the `.cwf` subtree at the current version. Verified by a new audit helper or test.
- [ ] **AC2**: A regression check makes manifest-vs-subtree drift visible at development time, not at consumer-update time. Concrete shape (helper / test / pre-commit) decided in design; the outcome is: a developer cannot land a manifest whose recorded SHAs disagree with the shipped content.
- [ ] **AC3**: A `cwf-manage update` invocation from v1.1.155 (or v1.1.163) to the post-fix tip, with `CWF_UPGRADE_RESOLVE` unset and no TTY, completes without an `apply-artefacts` rules-inject conflict prompt.
- [ ] **AC4**: `cwf-manage validate` is clean post-fix (any hash-tracked file edits refresh `script-hashes.json` in the same commit, per `[[hash-updates]]`).
- [ ] **AC5**: Existing consumer-shipped content survives the update — `.cwf/rules-inject.txt` post-update is still 331 bytes (the populated form), not emptied. Guards against the rejected Task-158 Option A regression.

## Original Estimate
**Effort**: 0.5-1 day
**Complexity**: Low (one focused defect; the audit is mechanical; the fix is a manifest/SHA edit plus a regression check)
**Dependencies**: None upstream. Two consumer-side touchpoints: the medium-priority chore in BACKLOG (*Reclassify rules-inject.txt as consumer-owned*) depends on this landing first.

## Major Milestones
1. **Audit**: Iterate every `install-manifest.json` artefact entry. For each, compute the subtree-actual SHA (the blob in `.cwf/` at the source path) and compare to the manifest-recorded value. Produce the drift list.
2. **Fix**: For each drift entry, either (a) update the manifest SHA to match the shipped content, or (b) point the `source` at the actually-shipped file and update SHA accordingly. Decide between (a) and (b) per entry during design.
3. **Regression check**: Add an automated check that prevents this class of drift from recurring. Shape (test in `t/`, helper invoked by `cwf-manage validate`, or pre-commit hook) chosen in design.
4. **Verify**: Reproduce the original bug locally (non-interactive `cwf-manage update` from v1.1.155); confirm the post-fix update succeeds with `rules-inject.txt` content preserved.

## Risk Assessment

### High Priority Risks
- **Risk 1**: Fixing one entry's SHA could break `/cwf-init`'s `--bootstrap-init` path, which uses the same manifest. `apply_replace` in bootstrap mode silently overwrites; if we change the manifest source from the empty template to the populated file, fresh installs need to still land the populated content (currently they get it via subtree, not via apply-artefacts — verify this stays true).
  - **Mitigation**: Re-read `cwf-apply-artefacts:apply_replace` and the bootstrap-init branch; trace `/cwf-init` to confirm the seed path. Add a TC that runs `/cwf-init` on a clean tree and asserts `.cwf/rules-inject.txt` ends up populated.

- **Risk 2**: The defect may not be limited to `rules-inject`. CLAUDE.md preamble (`c72927c7…`) and `cwf-workflow-files.md` (`05d3e1e7…`) have non-empty SHAs in the manifest — but those SHAs need to be verified against what the subtree actually ships, not assumed correct.
  - **Mitigation**: The Milestone-1 audit is a complete sweep, not just `rules-inject`. Find all drift before deciding the fix shape.

### Medium Priority Risks
- **Risk 3**: The conflict-prompt code path (`cwf-apply-artefacts:prompt_resolve`) is fragile under agentic invocation regardless of this fix — even with the manifest correct, a *real* consumer customisation would still hit the same dead-end. Hardening that is out of scope here but worth noting for follow-up.
  - **Mitigation**: Note as a maintenance item in `i-maintenance.md` (if we add one) or as a separate Low-priority backlog entry from the retrospective.

- **Risk 4**: `script-hashes.json` tracks the manifest itself. Any manifest edit must refresh that entry in the same commit.
  - **Mitigation**: Standard `[[hash-updates]]` discipline — disclose hashed-file edits in the implementation plan, verify with `git log` of the manifest's prior-commit history, refresh in-commit.

- **Risk 5**: The unused `.cwf/templates/install/rules-inject.txt` (empty placeholder) is hash-tracked as `rules-inject-template` in `script-hashes.json` and validated by `cwf-manage validate`. If we keep it for backward compat, it stays. If we delete it (cleaner), we must remove its hash entry and any references.
  - **Mitigation**: Decide in design whether to keep or delete; surface the choice and rationale in c-design-plan.

## Dependencies
- **External**: None.
- **Internal**: `cwf-apply-artefacts`, `cwf-manage update`, `cwf-manage validate`, `install.bash` subtree-add path, `/cwf-init` bootstrap path. All read-only references for this task — we do not refactor any of them, only update the manifest they read.

## Constraints
- **Hash discipline**: per `[[hash-updates]]`, every hash-tracked file edit (the manifest is hashed) lands its `script-hashes.json` refresh in the same commit. No "follow-up to clean up hashes" — surface drift, never smooth.
- **Surface, never smooth** ([[feedback-surface-security-dont-smooth]]): if the audit finds drift on entries other than `rules-inject`, that drift is a signal worth surfacing, not patching over. The regression check (AC2) is the institutional mechanism for keeping it surfaced.
- **POSIX-portable**: any new audit / regression-check helper uses core Perl + standard POSIX tools only ([[feedback-perl-core-only]]).
- **No fabricated citations** ([[feedback-no-fabricated-citations]]): claims about `apply_replace`'s behaviour, the manifest schema, or `/cwf-init`'s seed path are verified by reading the source this task — not retrofitted from earlier conversation memory.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: <1 day estimated → **no**.
- [x] **People**: solo → **no**.
- [x] **Complexity**: one defect surface (manifest accuracy) + one regression-check artefact → 2 concerns, both small → **no**.
- [x] **Risk**: contained to a single config file edit + one hash refresh; the audit may reveal additional drift but that does not multiply concerns → **no**.
- [x] **Independence**: Milestones 1-4 are sequential, not parallelisable → **no**.

**Verdict**: 0/5 signals triggered. **No subtasks**.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 167
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
