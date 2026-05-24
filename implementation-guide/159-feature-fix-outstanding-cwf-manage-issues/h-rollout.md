# fix outstanding cwf-manage issues - Rollout
**Task**: 159 (feature)

## Task Reference
- **Task ID**: internal-159
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/159-fix-outstanding-cwf-manage-issues
- **Template Version**: 2.1

## Goal
Define how the FR1/FR2/FR4 fixes reach CWF consumers and how to revert if a consumer update regresses.

## Deployment Strategy
### Release Type
- **Strategy**: Tag-based release. CWF is a documentation/tooling system distributed by git tag, not a running service — there is no live deployment surface, traffic split, or user cohort. The change ships when the maintainer squash-merges the task branch to `main` and cuts the next `v{major}.{minor}.159` tag (both human-only per CLAUDE.md Versioning).
- **Rationale**: Consumers pull a specific tag via `cwf-manage update <tag>` (subtree) or `install.bash` (CWF_REF). Phased exposure is the consumer's choice of which tag to pin, not something this repo orchestrates.
- **Forward-only caveat (FR1/FR2)**: both fixes live in `.cwf/scripts/cwf-manage`, which the consumer runs from their *installed* (old) copy. So the corrected `cwf_version`/`cwf_ref` write (FR1) and the `fix-security --dry-run` flag (FR2) only become available in installs that already carry the tag holding this task. Installs predating it record the old (buggy) version string until they next reinstall via the bootstrap path in INSTALL.md (`CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<url> bash install.bash`). This is the rollout's known reach limit, not a defect. FR4 is an internal hardening with no consumer-visible surface.

### Pre-Deployment Checklist
- [x] Code review completed (plan-review subagents on b/c/d; exec-phase security review — no findings on both f and g)
- [x] All tests passing (full suite 48 files / 527 tests; new `cwf-manage-git-capture.t` 6/6; fix-security +3; update-e2e +2)
- [x] Security scan completed (implementation- and testing-phase changeset reviews: no findings; FR4 removes a `$source` shell-string interpolation — net hardening)
- [x] Performance validated (NFR: no new multi-minute paths; `git_capture` is a single fork-exec per call, same cost as the backticks it replaces)
- [x] Documentation updated (`cmd_help` documents `fix-security [--dry-run]` + example)
- [x] Integrity refreshed (`script-hashes.json` cwf-manage sha256 same-commit; `cwf-manage validate` clean; `perlcritic` backtick policy clean)
- [ ] Squash-merge to `main` + version tag (human-only — out of model scope)

## Rollout Plan
Tag-based, so the "phases" are the order in which consumers receive the change, not a percentage ramp this repo controls.

### Phase 1: This repo (dogfood)
- **Scope**: CWF's own repo, on squash-merge to `main`.
- **Validation**: `prove -lr t/` green and `cwf-manage validate` clean on `main` post-merge.

### Phase 2: New installs
- **Scope**: Any consumer running `install.bash` at the new tag gets the corrected updater (FR1) and the `--dry-run` flag (FR2) immediately.
- **Success signal**: after an `update`, the version file records the tag-derived semver in `cwf_version` and the requested ref in `cwf_ref` (never a bare SHA in `cwf_version`); `fix-security --dry-run` previews without mutating; `validate` clean.

### Phase 3: Existing subtree installs
- **Scope**: Consumers on a prior tag running `cwf-manage update <new-tag>`. After this update lands, *subsequent* updates write the corrected `cwf_version`/`cwf_ref`.
- **Limit**: the update that *delivers* this fix is still run by the old updater, so the version string it writes for that one transition reflects the old behaviour; it is correct from the next update onward, or immediately via the INSTALL.md bootstrap reinstall.

## Monitoring
No telemetry exists or is added — CWF runs entirely in the consumer's repo. Health is observed through deterministic gates, not metrics:
- **Integrity**: `cwf-manage validate` (SHA256 + recorded perms) after any update.
- **Version correctness**: `cwf-manage status` should show a tag-derived `cwf_version` (e.g. `v1.1.159` or `v1.1.159-N-gHASH`), not a bare 40-char SHA — the FR1 regression sentinel.
- **Update correctness**: `t/cwf-manage-update-end-to-end.t` and `t/cwf-manage-git-capture.t` are the regression sentinels for future updater/helper changes.
- **Consumer signal**: bug reports / issues are the only external feedback channel; there is no dashboard or alert pipeline to wire up.

## Rollback Plan
### Triggers
- A consumer update leaves `validate` failing, or `cwf_version` is written as a bare SHA (FR1 regression).
- `fix-security --dry-run` mutates the tree (it must not) or fails to fail-closed on an unknown argument.
- `git_capture` leaks git stderr into captured stdout or mis-reports exit status (FR4 regression).

### Procedure
1. **Consumer-side**: `cwf-manage rollback <prior-tag>` returns to the last-good version. If the installed updater itself is implicated, use the INSTALL.md bootstrap recovery against the prior tag.
2. **Repo-side**: revert the squash commit on a new task branch and re-tag — a normal git revert; nothing external to undo.
3. **Communication**: note the regression on the issue tracker; no users to notify directly.
4. **Analysis**: extend the relevant `t/` harness to cover the missed path before re-attempting (captured in retrospective if it occurs).

## Success Criteria
- [x] Deployment model documented and matched to CWF's tag-based distribution
- [x] Pre-deployment gates green (tests, validate, perlcritic, security review)
- [x] Forward-only reach limit (FR1/FR2 run from the installed updater) and its recovery path documented
- [x] Rollback procedure defined (consumer `rollback` + repo revert)
- [ ] Tag/merge to main — deferred to the maintainer (human-only)

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance 159
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout is documentation-only this phase: the change is staged on the task branch awaiting human squash-merge and tag. The FR1/FR2 consumer-facing paths (version-write on update, `--dry-run` preview) are exercised by the end-to-end and fix-security harnesses; FR4 is internal hardening with no consumer surface. The forward-only reach limit (the fix is delivered by the consumer's *old* updater) and its bootstrap recovery are documented in INSTALL.md.

## Lessons Learned
FR1/FR2 are forward-only: the fix ships in `cwf-manage` but is run by the consumer's *old* installed updater, so it only lands in installs at/after the carrying tag. The rollout's job was to document that reach limit and the bootstrap-reinstall recovery, not to engineer a self-repair. See j-retrospective.md.
