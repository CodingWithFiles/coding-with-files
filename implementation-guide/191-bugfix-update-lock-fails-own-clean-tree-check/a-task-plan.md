# update lock fails own clean-tree check - Plan
**Task**: 191 (bugfix)

## Task Reference
- **Task ID**: internal-191
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/191-update-lock-fails-own-clean-tree-check
- **Baseline Commit**: fbf8adf15cbb3dad8b5acc7ad788ce3f52d39caa
- **Template Version**: 2.1

## Goal
Make `cwf-manage update` resilient to its own ephemeral `.cwf/.update.lock` so an
install whose `.gitignore` lacks the lock entry can still pass the clean-tree gate
and update successfully.

## Success Criteria
- [ ] `cwf-manage update` succeeds on an otherwise-clean install even when
      `.gitignore` does not list `.cwf/.update.lock` (the self-blocking cycle is broken)
- [ ] The D8 concurrency property is preserved: the lock is still acquired before
      the clean-tree check, so two concurrent updates cannot both pass the gate
- [ ] `check_clean_tree` still reports every genuine uncommitted change under
      `.cwf`/`.cwf-skills`/`.cwf-rules`/`.cwf-agents` (no regression in dirty-tree
      detection for any path other than the lock)
- [ ] A regression test fails on the current code and passes after the fix:
      marker-less `.gitignore` + lock present → clean-tree passes
- [ ] `cwf-manage validate` and `script-hashes.json` stay consistent (hash refresh
      in the same commit as the `cwf-manage` edit, per hash-updates convention)

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None (single-file change in `cwf-manage` plus a test)

## Major Milestones
1. **Root-cause confirmed & approach chosen**: design fixes the lock-exclusion
   approach (git pathspec exclude vs. post-`split` record filter) with rationale
2. **Fix applied**: `check_clean_tree` no longer counts `.cwf/.update.lock`;
   script hash refreshed in the same commit
3. **Regression test green**: a test reproduces the self-block and verifies the fix,
   plus a guard that a *real* dirty `.cwf` path is still reported

## Risk Assessment
### High Priority Risks
- **Over-broad exclusion masks real changes**: a sloppy filter could also hide
  genuine uncommitted changes (e.g. anything matching `.update*`), weakening the
  safety gate.
  - **Mitigation**: exclude only the exact path `.cwf/.update.lock`; add a
    positive test that an unrelated dirty `.cwf` file is still reported.

### Medium Priority Risks
- **Lock created before the check is itself the smell**: re-ordering to acquire
  the lock *after* clean-tree would also "fix" the symptom but would break the D8
  concurrency invariant.
  - **Mitigation**: design phase explicitly rejects re-ordering; keep
    acquire-before-check and instead make the check lock-aware.

## Dependencies
- None external. Touches `.cwf/scripts/cwf-manage` and its test harness only.

## Constraints
- Perl core-modules only; POSIX-portable (macOS system Perl).
- Hashed-file edit: refresh `.cwf/security/script-hashes.json` in the same commit;
  restore working perms to the recorded value after editing.
- Fix must not alter the D8 lock-before-check ordering.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — single-file fix plus a test.
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one concern (lock-aware clean-tree).
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Can parts be worked on separately? No — fix and its test are one unit.

**Conclusion**: 0 signals triggered. No decomposition; proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met. `cwf-manage update` no longer self-blocks on its own
`.cwf/.update.lock`; D8 lock-before-check ordering preserved; every other dirty path
still reported (TC-5); regression test fails pre-fix and passes post-fix (TC-4);
`validate: OK` with same-commit hash refresh. Delivered in ~1 day, on estimate.

## Lessons Learned
0 decomposition signals was correct — single-file fix plus a test stayed one unit.
The High "over-broad exclusion" risk was the one that mattered and was retired by an
exact-literal exclude pinned by TC-5. See j-retrospective.md.
