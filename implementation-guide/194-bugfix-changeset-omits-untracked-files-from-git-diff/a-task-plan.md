# changeset omits untracked files from git diff - Plan
**Task**: 194 (bugfix)

## Task Reference
- **Task ID**: internal-194
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/194-changeset-omits-untracked-files-from-git-diff
- **Baseline Commit**: a4b71dfba9764e39de12e3aed3c7f4f1e2d08856
- **Template Version**: 2.1

## Goal
Make `security-review-changeset` include untracked, non-ignored files in both the
reviewed changeset body and the `--max-lines` production count, so a new source file
created before the exec checkpoint commit is no longer shipped to the security reviewer
unreviewed and uncounted.

## Success Criteria
- [ ] An untracked, non-`.gitignore`d file present in the working tree appears in the
      `.out` changeset body with its full (all-added) content.
- [ ] The same file's added lines are included in the production line count that gates
      `--max-lines` (so it can trigger exit 2).
- [ ] Ignored files (`--exclude-standard`) and the existing tracked staged+unstaged
      behaviour are unchanged; consumer exclude-globs still discount their matches.
- [ ] The helper remains side-effect-free on the index/working tree (no residual
      `intent-to-add` entries) and exits cleanly on a tree with zero untracked files.
- [ ] A regression test in `t/` asserts an untracked file lands in both the body and
      the production count; existing helper tests still pass.

## Original Estimate
**Effort**: ~0.5 day
**Complexity**: Medium (small surface, but a non-trivial git-mechanics decision and
exit-code handling around `git diff --no-index`)
**Dependencies**: None — self-contained in `security-review-changeset` + its test.

## Major Milestones
1. **Design decision locked**: choose the untracked-file mechanism (`git diff
   --no-index` vs. transient `git add -N` + reset) and how exclude-globs apply to
   untracked paths.
2. **Implementation**: untracked paths enumerated, body rendered, production count
   updated; hash refreshed in the same commit.
3. **Regression test green**: new test proves coverage; full helper test suite passes.

## Risk Assessment
### High Priority Risks
- **Risk 1 — "git owns path-matching" invariant erosion**: the helper deliberately does
  NO Perl path classification; exclude discounting is delegated to git's
  `:(glob,exclude)` magic pathspecs. `git diff --no-index` operates outside the repo and
  does not honour those pathspecs, so untracked-file exclusion would have to be
  re-implemented in Perl — a design regression.
  - **Mitigation**: prefer a mechanism that keeps git as the matcher (e.g. `git add -N`
    so untracked files become diff-visible to the existing pathspec logic), OR explicitly
    accept and document a narrow Perl-side exclude match for untracked files only.
    Resolve in the design phase before any code.
- **Risk 2 — index side-effects / `--no-index` exit codes**: `git add -N` mutates the
  index and must be reliably reset even on mid-run failure; `git diff --no-index` returns
  exit 1 to signal "differences found", which the helper's `capture_git` currently treats
  as fatal.
  - **Mitigation**: whichever path is chosen, add explicit exit-code handling (1 is
    expected, not fatal) and, if `-N` is used, guarantee restore via cleanup on all exit
    paths. Cover both in the test plan.

### Medium Priority Risks
- **Risk 3 — anchor semantics for untracked files**: untracked files have no anchor-side
  blob, so they are wholly new (all-added). Mixing them into an `<anchor>`-based diff must
  not misreport deletions or break rename detection on the tracked set.
  - **Mitigation**: render/count untracked files via a separate, clearly-scoped step and
    union the results; keep the tracked-path diff untouched.

## Dependencies
- None external. Touches `security-review-changeset` and `.cwf/security/script-hashes.json`
  (hash refresh in the same commit, per hash-updates convention).

## Constraints
- Read-only contract: the helper must not leave the index or working tree mutated.
- Core-Perl only; NUL-separated git path parsing (`-z`, `git-path-output` convention).
- Hash refresh for the edited script happens in this task's exec commit.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — ~half a day.
- [ ] **People**: Does this need >2 people? No — single helper.
- [ ] **Complexity**: 3+ distinct concerns? No — one concern (changeset completeness),
      touching body-render and count in the same file.
- [ ] **Risk**: High-risk components needing isolation? No — risks are git-mechanics
      decisions resolved in design, not separable work.
- [ ] **Independence**: Can parts be worked on separately? No — body and count share the
      same untracked-enumeration step.

**Verdict**: 0 signals triggered. No decomposition — proceed as a single bugfix task.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective (complete)
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All success criteria met. The fix was scoped exactly as planned — a single
helper plus its test. Risk 1 (invariant erosion) was resolved in design by
choosing `git add -N` over `git diff --no-index`, keeping git as the sole path
matcher. Risk 2 (index side-effects / exit codes) was handled by a PID-guarded,
`$?`-preserving END block; `git add -N`/diff/numstat all return rc 0, so
`capture_git` needed no exit-code special-casing. Effort matched the ~0.5-day
estimate. 0 decomposition signals held.

## Lessons Learned
The empirical probe (run before the design phase) was the highest-leverage
step: it turned the central mechanism choice from speculation into a decision
backed by observed git behaviour, and every later phase inherited that
certainty.
