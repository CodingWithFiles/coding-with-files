# Skip non-regular files in untracked sweep - Plan
**Task**: 209 (bugfix)

## Task Reference
- **Task ID**: internal-209
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/209-skip-non-regular-files-in-untracked-sweep
- **Baseline Commit**: d6ce5a1f48deebc5480e9362aa99c161cab51e58
- **Template Version**: 2.1

## Goal
Stop the changeset security reviewer aborting when the untracked-file sweep
encounters non-regular files (e.g. sandbox `/dev/null` bind-mount masks at the
repo root) that `git add -N` cannot index.

## Success Criteria
- [ ] `list_untracked_files()` in `security-review-changeset` returns only paths
      `git add -N` can index (regular files and symlinks); char/block devices,
      fifos and sockets are dropped.
- [ ] A repo whose only untracked entries are non-regular files (device mask)
      no longer aborts the helper; it reports a clean/empty untracked set.
- [ ] Genuine untracked regular files and symlinks are still swept in (no
      regression to the Task 194 untracked-inclusion behaviour).
- [ ] A test exercises the non-regular-file case against a real char device
      (e.g. `/dev/null` bind/symlink) and passes.

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None — single-helper, single-function change.

## Major Milestones
1. **Reproduce/confirm**: Establish that a non-regular untracked entry causes
   `git add -N` (and thus the helper) to abort.
2. **Filter**: Restrict `list_untracked_files()` to git-indexable types.
3. **Test + hash**: Add coverage in `t/`, refresh `script-hashes.json`.

## Risk Assessment
### High Priority Risks
- **Risk 1**: Over-filtering drops genuine untracked source files, silently
  shrinking the review surface.
  - **Mitigation**: Keep both regular files (`-f`) and symlinks (`-l`); only
    exotic types are excluded. Test asserts a normal untracked file survives.

### Medium Priority Risks
- **Risk 2**: Silent drop hides that a path was excluded, masking a real issue.
  - **Mitigation**: Decide in design whether to warn on dropped entries
    (surface-don't-smooth) vs. drop quietly; the masks are harness noise, not
    review content.

## Dependencies
- None external. Touches one helper script and its test.

## Constraints
- POSIX core-Perl only (no non-core modules); `-f`/`-l` filetests suffice.
- Hash refresh for the edited script must land in this task/commit.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — hours.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one filter.
- [ ] **Risk**: Are there high-risk components that need isolation? No.
- [ ] **Independence**: Can parts be worked on separately? No.

No signals triggered — single-function bugfix, no decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
