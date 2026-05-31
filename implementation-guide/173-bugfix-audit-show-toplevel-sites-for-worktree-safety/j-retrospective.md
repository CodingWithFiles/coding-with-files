# Audit show-toplevel sites for worktree-safety - Retrospective
**Task**: 173 (bugfix)

## Task Reference
- **Task ID**: internal-173
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/173-audit-show-toplevel-sites-for-worktree-safety
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-31

## Executive Summary
- **Duration**: ~1 day (estimate matched).
- **Scope**: Audit + fix the `git rev-parse --show-toplevel` "go to repo root" idiom for worktree-safety (backlog R2 from Task 172). Original framing was "13 sites"; the audit corrected this to a single repointed choke-point (`CWF::Common::find_git_root`) fixing 3 transitive callers for free, 5 routed sites, 1 dual-report diagnostic, 1 independent resolver (`cwf-manage`), 3 prose/shell sites, and 3 explicit no-change dispositions.
- **Outcome**: Success. The data-loss vector is closed at the canonical-state level; full suite (640 tests) green, `cwf-manage validate` clean, two security reviews `no findings`.

## Variance Analysis
### Time and Effort
- **Estimated** (a-task-plan): ~1 day, Medium complexity.
- **Actual**: ~1 day across a,c,d,e,f,g,j. Plan-review and security-review subagents front-loaded the cost into design/impl, which paid off (the largest corrections happened on paper, not in code).
- **Variance**: On estimate.

### Scope Changes
- **Additions**: `cwf-manage:86` (a 14th site — its own resolver, found by reviewers) routed (OQ-4); `location` made a dual reporter (OQ-2); `Versioning.pm`/`Backlog.pm`/`backlog-manager` recognised as transitive callers (the design's "no callers" claim was false).
- **Removals / no-change**: `task-stack` (OQ-1, error-message-only), `checkpoints-branch-manager` (reclassified at exec — error-message-only, not canonical-state), `delete` Class C guard, `install.bash`, a test helper.
- **Impact**: Net fewer code edits than the literal "13 rewrites" the backlog implied; one tested choke-point instead of 13 inline incantations.

### Quality Metrics
- **Test Coverage**: New `t/find-git-root-worktree.t` (TC-1..4) covers worktree/main/outside-repo/derivation; TC-1 was a genuine TDD anchor (failed pre-fix). Residual: TC-5 fallback branch not automated (submodule fixture disproportionate); TC-8 cwf-manage resolver covered by equivalence + smoke. Both documented in g.
- **Defect Rate**: Zero post-fix test failures. Two defects caught *before* commit: the `File::Spec` invariant violation (existing test TC-8) and a latent subtest `plan`-ordering bug (security reviewer's out-of-scope note).
- **Performance**: N/A (one extra `git rev-parse` per root resolution; negligible).

## What Went Well
- **Plan-review subagents earned their keep.** They caught the false "find_git_root has no callers" claim (3 of 4 reviewers), the wrong `.cwf/lib/` path prefix, the `task-stack` misclassification, the 14th site, and the verified flag-ordering — all on paper, before any code.
- **TDD anchor.** Writing the failing worktree test first made the fix self-evidently correct and guards against regression.
- **Empirical verification over citation.** Confirmed git's `--git-common-dir` behaviour with a real worktree probe rather than trusting docs (per the no-fabricated-citations rule).
- **Exec-phase catches.** The `checkpoints-branch-manager` reclassification and the `File::Spec`-invariant collision were both caught by reading the actual code / running the suite, not assumed.

## What Could Be Improved
- **Design over-specified the mechanism.** The design mandated `File::Spec` derivation; an existing test forbade `File::Spec` in `cwf-manage`, forcing a deviation at exec. A design-time grep for "does any target file have an import-invariant test?" would have caught it. The `File::Spec->splitdir` sketch also carried a leading-`/` bug.
- **The "13 sites" framing in the backlog was a literal grep count, not a consumption analysis.** The real unit of work was "how is the resolved root consumed", which only emerged in design. Backlog items that quote a grep count should be treated as a starting hypothesis, not scope.

## Key Learnings
### Technical Insights
- `git rev-parse --show-toplevel` is worktree-local; `--path-format=absolute --git-common-dir` yields the main `.git` from anywhere, so its parent is the main worktree root. `--path-format` must precede the path-emitting flag.
- Classify root-resolution sites by **consumption pattern** (canonical-state write vs. path-anchoring read vs. error-message display vs. worktree-local-by-design), not by file type or grep count. Error-message-only captures (`task-stack`, `checkpoints-branch-manager`) must stay worktree-local — routing them to the main tree is actively wrong.
- A literal `/.git` suffix strip is a safe parent derivation *given* the `--path-format=absolute` guarantee — no `File::Spec` needed, which also kept the two resolvers identical and respected an existing import invariant.

### Process Learnings
- Front-loading review (plan-review ×3 phases + security ×2) converted what would have been exec rework into cheap paper corrections.
- When a design cites a "should" (e.g. "use File::Spec"), verify it against existing tests/invariants before encoding it as a plan step.

### Risk Mitigation Strategies
- The load-bearing `delete` Class C guard was identified early and explicitly excluded; the test plan called for confirming it unchanged, and it was verified absent from the changeset.
- `cwf-manage` (the validator itself) was recognised as a self-masking-validator risk; its resolver was kept on list-form `git_capture` with its `die` contract intact.

## Recommendations
### Process Improvements
- Add a design/plan-time check: "for each hashed/handled file, does an existing test assert an import or structural invariant?" (would have pre-empted the `File::Spec` deviation).
### Tool and Technique Recommendations
- Keep the "empirical probe before claiming tool behaviour" habit for any git-plumbing change.
### Future Work
- **R1 (backlog)**: guarded `EnterWorktree`/`ExitWorktree` flows — this task delivered the lower-level primitive; R1 is the higher-level ergonomic guard.
- Optional: a submodule-fixture test to exercise the `find_git_root` `--show-toplevel` fallback branch (TC-5) if future work touches it.
- Optional: an install-into-tempdir + worktree harness to assert `cwf-manage`'s resolver return value independently (TC-8).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-31
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Plan/exec docs: `a-task-plan.md`, `c-design-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`, `f-implementation-exec.md`, `g-testing-exec.md` (this directory).
- Checkpoint commits: `b5ff5b4` (a), `220c7f0` (c), `7afeda9` (d), `beae8f3` (e), `1f0b436` (f), `41ea0aa` (g).
- Test: `t/find-git-root-worktree.t`. Choke-point: `.cwf/lib/CWF/Common.pm` `find_git_root`.
