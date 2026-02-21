# fix install script latest tag resolution and local dev UX - Plan
**Task**: 80 (bugfix)

## Task Reference
- **Task ID**: internal-80
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/80-fix-install-latest-and-env-handling
- **Template Version**: 2.1

## Goal
Fix `install.bash` so that installing from a `file://` source defaults to `HEAD`
rather than the latest tag, and add a local dev install section to `INSTALL.md`.

## Background
When a user points `CWF_SOURCE` at a local `file://` clone, `CWF_REF` defaults to
`latest`, which resolves to the most recent git tag (e.g. `v0.2.1`). If HEAD is ahead
of that tag (e.g. after a major rename like `.cig` → `.cwf`), the install uses an
incompatible old version with no warning. Observed in a real install attempt:

```
[CWF] Resolved 'latest' to v0.2.1
fatal: '.cwf' does not exist; use 'git subtree add'
```

Two root causes:
1. `install.bash` `resolve_ref()`: no special-casing for `file://` sources —
   `latest` resolves to a tag regardless of source type
2. `INSTALL.md`: no documentation for the local dev / untagged-HEAD use case

## Success Criteria
- [ ] Installing from `file://` source with no `CWF_REF` set uses `HEAD` by default
- [ ] Installing from GitHub/remote source with no `CWF_REF` set still uses `latest` (no regression)
- [ ] `INSTALL.md` has a "Local clone" section documenting `file://` + `CWF_REF=HEAD`
- [ ] The change is covered by at least one new test or manual verification step

## Original Estimate
**Effort**: <1 session
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. Fix `resolve_ref()` in `install.bash` to detect `file://` source
2. Add `INSTALL.md` local dev install section
3. Verify with manual test using `file:///home/matt/repo/coding-with-files`

## Risk Assessment
### Medium Priority Risks
- **Changing default behaviour**: Any user currently passing `CWF_SOURCE=file://...`
  without `CWF_REF` will silently get HEAD instead of latest tag.
  - **Mitigation**: This is the correct behaviour for local sources — document it
    clearly in the log output (`[CWF] file:// source detected, defaulting CWF_REF to HEAD`)

## Dependencies
- `scripts/install.bash` — the only file with logic changes
- `INSTALL.md` — docs only

## Constraints
- Must not change the default for remote (http/https/ssh/git://) sources

## Decomposition Check
- [x] **Time**: <1 session — no decomposition needed
- [ ] **People**: Single-person task
- [x] **Complexity**: Two independent concerns (script fix + docs), but both tiny
- [ ] **Risk**: Low risk, no decomposition needed
- [ ] **Independence**: Could split, but the changes are so small it's not worth it

No decomposition — both changes are contained and ship together.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 80
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All success criteria met. file:// installs default to HEAD with a clear log message;
remote sources unchanged. INSTALL.md local clone section added. 5/5 TCs pass
including a live end-to-end install.

## Lessons Learned
The bug was a classic "smart default for one use case, wrong for another" problem.
Detecting source type at ref resolution time is the right scope for the fix.
