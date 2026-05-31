# Audit show-toplevel sites for worktree-safety - Plan
**Task**: 173 (bugfix)

## Task Reference
- **Task ID**: internal-173
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/173-audit-show-toplevel-sites-for-worktree-safety
- **Baseline Commit**: 728fe6609aa9834e17a9631b1da2ef870d837975
- **Template Version**: 2.1

## Goal
Make CWF's "go to repo root" resolution worktree-safe so the `cd "$(git rev-parse --show-toplevel)"` idiom can no longer silently anchor work inside a disposable linked worktree (data-loss mechanism reproduced in Task 172).

## Success Criteria
- [ ] All 13 known `git rev-parse --show-toplevel` sites are enumerated, each with a recorded disposition (fix / no-change-with-rationale); no site left unclassified.
- [ ] Every site whose intent is "main repo root" resolves the main working tree even when run inside a linked worktree, demonstrated by a reproduction test executed inside a real `git worktree`.
- [ ] Sites whose intent is genuinely worktree-local (notably the self-worktree guard in `task-workflow.d/delete`) are preserved unchanged with an explicit rationale — no semantic regression.
- [ ] Every edited hashed helper has its hash refreshed in the same commit; `cwf-manage validate` passes clean.
- [ ] Full existing test suite passes (no regression).

## Original Estimate
**Effort**: ~1 day
**Complexity**: Medium (uniform fix pattern, but per-site intent analysis and a load-bearing guard raise the care level)
**Dependencies**: Conceptually paired with backlog item R1 (guarded EnterWorktree/ExitWorktree); R2 is the lower-level primitive and should land first.

## Major Milestones
1. **Inventory & classify**: Triage all 13 sites into "wants main root" vs "genuinely worktree-local"; identify how many funnel through `CWF::Common::find_git_root` (single-point fix candidate).
2. **Decide resolution pattern**: Choose the worktree-safe root primitive (e.g. `--git-common-dir`-derived main toplevel) — design phase.
3. **Apply fixes + hash refresh**: Edit sites, refresh hashes in-commit, update `cwf-init`/`tmp-paths.md` prose.
4. **Reproduction test + validate**: Add an in-worktree regression test; run suite and `cwf-manage validate`.

## Risk Assessment
### High Priority Risks
- **Over-remediation breaks worktree-local semantics**: A blanket "resolve to main tree" change could break sites that legitimately need the current worktree — the self-worktree guard inside `task-workflow.d/delete` must keep detecting that it is *in* a worktree, or deletion safety is lost.
  - **Mitigation**: Per-site intent analysis before any edit; treat `delete`'s guard as explicitly worktree-local and exclude it from the root-resolution change.

### Medium Priority Risks
- **Resolution primitive subtlety**: `git rev-parse --git-common-dir` yields a `.git`-relative path that needs normalising to the main toplevel; naive substitution gives wrong paths.
  - **Mitigation**: Prototype a single resolution helper; unit-test it from both the main tree and a linked worktree before rolling out.
- **Hash drift / validate failure**: Editing hashed helpers without an in-commit hash refresh trips `cwf-manage validate`.
  - **Mitigation**: Follow the hash-updates convention — refresh `.cwf/security/script-hashes.json` in the same commit as each helper edit.
- **Under-remediation**: Fixing only the `cwf-init` prose would leave the 12 code sites unsafe.
  - **Mitigation**: Success criterion requires every site dispositioned; prose-only is insufficient.

## Dependencies
- Builds on Task 172 discovery (data-loss mechanism + worktree-CWD feedback memory).
- Pairs with backlog R1 (EnterWorktree/ExitWorktree); R2 lands first as the primitive.

## Constraints
- POSIX shell + core-Perl only; macOS system-perl portability (no non-core modules).
- Hashed-helper edits bound by the hash-updates convention (same task, same commit).
- Recorded permissions are an upper bound (Task 170) — restore edited scripts to their recorded perms, not bumped.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — ~1 day.
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? Borderline — one shared fix pattern applied across file types; not 3+ independent concerns.
- [ ] **Risk**: Are there high-risk components that need isolation? The `delete` guard is delicate but handled by exclusion, not a subtask.
- [x] **Independence**: Can parts be worked on separately? Sites are individually editable — but the remediation is a single shared pattern, so splitting would fragment one coherent fix.

**Verdict**: 1 signal (Independence) triggered. Keep as a single task — the fix is one uniform pattern (likely centralised in `find_git_root`), and decomposition would fragment it without benefit.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 173
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 success criteria met. Repointed `CWF::Common::find_git_root` to derive the main worktree root (fixing 3 transitive callers for free), routed 5 inline sites, made `cwf-manage`'s resolver and `context-manager location` worktree-safe, fixed 3 prose/shell sites, and recorded explicit no-change dispositions for the Class C `delete` guard and the two error-message-only captures. New `t/find-git-root-worktree.t` (TDD anchor); full suite 640 green; `cwf-manage validate` clean; two security reviews `no findings`. ~1 day, on estimate. Full analysis in `j-retrospective.md`.

## Lessons Learned
Classify root-resolution sites by *consumption pattern*, not grep count — the backlog's "13 sites" framing dissolved into one repointed choke-point + transitive callers. See `j-retrospective.md` for the full set.
