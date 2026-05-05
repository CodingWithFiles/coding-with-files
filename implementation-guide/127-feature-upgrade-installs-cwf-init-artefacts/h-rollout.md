# upgrade installs cwf-init artefacts - Rollout
**Task**: 127 (feature)

## Task Reference
- **Task ID**: internal-127
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/127-upgrade-installs-cwf-init-artefacts
- **Template Version**: 2.1

## Goal
Land Task 127 on `main` and make it available to downstream installs via the standard CWF tag-on-main release flow.

## Deployment Strategy

### Release Type
- **Strategy**: Squash + fast-forward to `main`, then maintainer tags `v1.1.127` (minor bump — new schema-versioned `install-manifest.json`, new helper `cwf-apply-artefacts`, new shared `CWF::ArtefactHelpers` module). Last release was `v1.0.114`; previous CWF tasks (115-126) accumulated under `v1.0` until a minor-warranting change shipped — Task 127 is that change.
- **Distribution model**: Downstream projects pick up the change by running `.cwf/scripts/cwf-manage update`. There is no live-service rollout — every install upgrades on its own schedule.
- **Rollback Plan**: `.cwf/scripts/cwf-manage rollback` (existing facility) restores the prior pinned version on a per-install basis. Upstream rollback would be `git revert <merge sha>` on `main` followed by a new patch tag.

### Pre-Deployment Checklist
- [x] Code review completed (manual approval recorded in f-implementation-exec.md § Security Review; changeset 2166 lines exceeded 500-line subagent cap)
- [x] All tests passing — 325/325 across 33 files (`prove t/`)
- [x] Security review documented in both f and g (manual review against threat categories a-e)
- [x] Performance: helper completes in <100ms per test; well within NFR1 (~50ms subprocess overhead)
- [x] CHANGELOG.md updated with Task 127 entry
- [x] BACKLOG.md cleaned (superseded "Refresh .claude/settings.json on cwf-manage update" entry)
- [x] `.cwf/scripts/cwf-manage validate` green (script-hashes + install-manifest)
- [x] `.gitignore` updated (`.cwf/.update.lock` added)
- [ ] Maintainer reviews and approves the squash commit message before pushing to `main`
- [ ] Maintainer tags `v1.1.127` after merge

## Rollout Plan

### Phase 1: Land on `main`
- **Action (maintainer)**: squash the 8 task-branch commits into a single commit on `main`, with the squash commit body summarising the changeset breakdown recorded in f-implementation-exec.md.
- **Verification**: re-run `prove t/` and `cwf-manage validate` on `main` post-merge.
- **Per project memory**: model never executes the merge; output the commands for the maintainer to run.

### Phase 2: Tag `v1.1.127`
- **Action (maintainer-only)**: `git tag -a v1.1.127 -m "Task 127: cwf-manage update installs cwf-init artefacts"` then `git push origin v1.1.127`.
- **Per CLAUDE.md**: tagging, pushing tags, and creating GitHub releases are human-only actions. Model must not run these.

### Phase 3: Downstream uptake
- **Mechanism**: Each downstream project's maintainer runs `.cwf/scripts/cwf-manage update` when ready. Update is fully backwards-compatible:
  - Projects with no `.cwf/install-manifest.json` (pre-D12 installs): bootstrap path runs, on-disk treated as baseline, dpkg-style prompt fires only on genuine three-way conflicts.
  - Projects on `v1.0.x`: receive new helper, manifest, sentinel-wrapped CLAUDE.md preamble, regenerated `.cwf-rules/` symlinks. `.cwf/version` gains a `cwf_install_manifest_sha` pin.
- **No phased rollout, no canary**: this is a developer-tool repo, not a service. Each install is independent.

## Monitoring

### Indicators to watch (in this repo, post-merge)
- **Issue tracker / BACKLOG.md**: any reports of `cwf-manage update` failures (lock contention, settings.json malformed, sentinel migration), conflict-resolution UX confusion (K/I/D/A prompt wording), or unexpected manifest schema rejections.
- **Test suite stability**: subsequent CWF tasks should keep `prove t/` green. A regression in `t/cwf-apply-artefacts.t` or `t/cwf-manage-update.t` is a signal.
- **CWF dogfood usage**: every subsequent CWF task in this repo exercises `cwf-manage` indirectly via skill invocations and integrity checks; catch issues organically.

### Signals that warrant a follow-up task
- Repeated user reports of bootstrap-from-no-manifest mis-behaviour (e.g. unexpected K/I prompts on first upgrade).
- Confusion around the secret-redaction rule for `.claude/settings.json` and `.env*`.
- Any pre-D12 install (no `cwf_install_manifest_sha`) misreporting tampering.

## Rollback Plan

### Triggers
- A downstream user reports that `cwf-manage update` corrupts their tracked files (anything beyond the dpkg-style three-way merge contract).
- Symlink-TOCTOU or path-allowlist bypass discovered.
- Pre-D12 install hits a manifest-SHA validation false-positive.
- Critical regression in `cwf-claude-settings-merge` after the shared-module refactor.

### Procedure
1. **Triage**: confirm reproduction; check whether the issue affects bootstrap-from-no-manifest or post-D12 installs (or both).
2. **Per-install rollback**: affected user runs `cwf-manage rollback` (restores prior pinned version, including pre-D12 state). This is the primary rollback lever — no upstream action required.
3. **Upstream rollback (if widespread)**: maintainer runs `git revert <merge sha>` on `main`, tags a patch (e.g. `v1.1.<next-task-num>`), and notes the revert in CHANGELOG.md.
4. **Post-incident**: open a follow-up CWF task to re-attempt the change with the failure mode covered by a regression test.

## Success Criteria
- [ ] Squash commit lands on `main` cleanly (fast-forward, no merge commit)
- [ ] Maintainer tags `v1.1.127`
- [ ] `prove t/` and `cwf-manage validate` green on `main` post-merge
- [ ] No downstream `cwf-manage update` regressions reported within first 5 subsequent CWF tasks

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective (model should auto-proceed; maintenance phase skipped — see Lessons Learned)
**Blockers**: Pending: maintainer must execute the squash-and-tag manually.

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- Rollout plan committed; awaiting maintainer to land on `main` and tag.
- Suggested squash command (to be run by maintainer, not the model):
  - `git checkout feature/127-upgrade-installs-cwf-init-artefacts`
  - `git reset --soft $(git merge-base HEAD main)`
  - `git commit -F /tmp/127-squash-msg.txt`
  - `git checkout main && git merge --ff-only feature/127-upgrade-installs-cwf-init-artefacts`
  - `git tag -a v1.1.127 -m "Task 127: cwf-manage update installs cwf-init artefacts"`
- Model deliberately does not execute these (per project memory: "Never execute merge to main").

## Lessons Learned
- For developer-tool repos with per-install upgrade semantics, the "deployment" template's phased-rollout / monitoring sections are largely vestigial. Captured the substance (uptake mechanism, signals to watch, rollback) but the template's structure is service-shaped rather than tool-shaped.
- Maintenance phase (i-maintenance.md) is N/A for this task — there is no live deployment to maintain. Will mark `i-maintenance.md` Skipped before retrospective so the status sweep passes.
