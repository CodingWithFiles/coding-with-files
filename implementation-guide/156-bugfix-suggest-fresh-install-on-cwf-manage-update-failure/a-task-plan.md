# suggest fresh install on cwf-manage update failure - Plan
**Task**: 156 (bugfix)

## Task Reference
- **Task ID**: internal-156
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/156-suggest-fresh-install-on-cwf-manage-update-failure
- **Baseline Commit**: cfe1a6e9ccb5258d31aac8d05abdbf22ca9e82ac
- **Template Version**: 2.1

## Goal
When `cwf-manage update` fails, its error output should suggest the user/agent
*might* consider a fresh install (re-running the bootstrap installer) as a
recovery path, mirroring the documented procedure in `INSTALL.md`.

## Success Criteria
- [ ] An `update`/upgrade failure prints a non-prescriptive suggestion to consider a fresh install as a possible recovery, in addition to the existing failure diagnostic.
- [ ] The suggestion points at the documented bootstrap-reinstall recovery (`INSTALL.md` "Recovering an install stuck on an old `cwf-manage`").
- [ ] Wording is a suggestion ("you might want to consider…"), not a directive, and does not imply data loss is required.
- [ ] No change to exit codes or control flow — only added guidance text on the failure path(s).
- [ ] The suggestion is scoped to update/upgrade failures, not unrelated `die_msg` paths (e.g. integrity-fix recovery hints already exist and stay as-is).

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Identify failure surfaces**: Confirm which `die_msg` paths in `cwf-manage` represent an update/upgrade failure that should carry the hint (candidates: remote-tag query `:296`, install.bash delegation `:431-433`, settings-merge `:266`, apply-artefacts `:253`).
2. **Emit suggestion**: Add the fresh-install suggestion text to those failure path(s), referencing the `INSTALL.md` recovery section.
3. **Verify**: Force each targeted failure and confirm the suggestion appears with the diagnostic.

## Risk Assessment
### High Priority Risks
- None.

### Medium Priority Risks
- **Hashed-file edit**: `cwf-manage` is a security-hashed script; editing it requires a same-task hash refresh to `.cwf/security/script-hashes.json` (per hash-updates convention).
  - **Mitigation**: Disclose in the implementation plan; refresh the hash in the same commit as the edit.
- **Scope creep into other `die_msg` paths**: over-broad application could attach an irrelevant hint to non-update failures.
  - **Mitigation**: Enumerate exact target lines in design; leave integrity-recovery hints (`FIX_SECURITY_RECOVERY`) untouched.

## Dependencies
- Recovery procedure already documented at `INSTALL.md` "Recovering an install stuck on an old `cwf-manage`" — the hint should stay consistent with it (single source of truth).

## Constraints
- POSIX/core-Perl only; no new modules.
- Text-only change to a hashed script — must travel with a hash refresh in the same commit.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? If yes, consider decomposition
- [ ] **People**: Does this need >2 people working on different parts? If yes, consider decomposition
- [ ] **Complexity**: Does this involve 3+ distinct concerns? If yes, consider decomposition
- [ ] **Risk**: Are there high-risk components that need isolation? If yes, consider decomposition
- [ ] **Independence**: Can parts be worked on separately? If yes, consider decomposition

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**Decomposition check**: No signals triggered (single-file text edit + hash refresh, <1 day, one concern). No subtasks.

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All success criteria met; delivered in one sub-day session with no scope change. See j-retrospective.md.

## Lessons Learned
See j-retrospective.md.
