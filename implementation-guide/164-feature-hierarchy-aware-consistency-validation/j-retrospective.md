# hierarchy-aware consistency validation - Retrospective
**Task**: 164 (feature)

## Task Reference
- **Task ID**: internal-164
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/164-hierarchy-aware-consistency-validation
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-27

## Executive Summary
- **Duration**: ~1 day of focused work across two sessions (estimated: 1–2 days). Within estimate,
  low end.
- **Scope**: Delivered exactly the three behaviours scoped in planning — full-depth traversal,
  hierarchy-directional branch rule, parent/child completeness invariant — in one module
  (`CWF::Validate::Consistency`), no decomposition, no scope creep.
- **Outcome**: Success. The originating downstream bug (a decomposed parent flagged as
  branch-inconsistent while the adopter worked a subtask) is fixed; two latent gaps (unvalidated
  subtask dirs; missing completeness check) closed in the same pass. Both exec-phase security
  reviews returned `no findings`; full suite 600/600.

## Variance Analysis
### Time and Effort
- **Estimated**: 1–2 days, Medium complexity, no hard dependencies (a-task-plan.md).
- **Actual**: planning phases (a–e) in one session; exec + finish (f–j) in a second. No phase
  overran; the only rework was a self-caught file-mode correction (below).
- **Variance**: on estimate. The single-mechanism design (one traversal serving all three FRs)
  kept implementation small, as the decomposition check predicted.

### Scope Changes
- **Additions**: none beyond plan.
- **Removals**: none.
- **Tightenings** (stricter than the written plan, no scope change):
  - `_build_node` gained a third arg (directory basename) so the `**Task**` fix message stays
    **byte-identical** to pre-change output — strengthens FR5/AC5 versus the plan's draft text.
  - FR1 / FR4 / symlink / no-warning test cases were made **git-independent** (run against plain
    `tempdir`s), widening coverage in minimal environments; only the directional branch cases
    stayed Tier-C git-gated.

### Quality Metrics
- **Test Coverage**: every FR (FR1–FR5) and both security NFRs (NFR4 symlink, NFR5 no-warnings)
  asserted; branch and completeness decision points covered at all polarities. 20/20 in
  `t/validate-consistency.t`; full suite 600/600 (was 585).
- **Defect Rate**: zero post-implementation defects. The only in-flight failures were the two
  expected hash-drift test failures, cleared by the in-commit `script-hashes.json` refresh.
- **Performance**: single linear pass, no per-node rescan (NFR1); no perceptible delta on the
  live repo's `cwf-manage validate`.

## What Went Well
- **Plan review earned its keep.** All four design reviewers independently flagged that the
  `build_tree` traversal I had cited as precedent uses `glob`+`-d`, which stat-follows symlinks —
  the wrong model for a security-sensitive recursive descent. Switching to an explicit
  `-l`-before-`-d` skip became a load-bearing, tested defence (TC-S1).
- **One mechanism, three behaviours.** The decomposition check (no signals) held: a single
  hierarchy-aware traversal served the directional branch rule and the completeness invariant
  without three separate reworks.
- **Reuse over re-derivation.** Ancestry came entirely from `CWF::TaskPath` string primitives
  (`get_parent`/`get_depth`/`parse_dirname`/`version_compare`); the `eq`-walk structurally
  rejects numeric near-misses (1 vs 11, 1.1 vs 1.10), proven by TC-2c, with no new dependency.
- **Fail-closed where ambiguous.** The 0-or-≥2-leaf-match case disables suppression rather than
  silencing, so a duplicated `**Branch**` record can't hide a real off-chain violation (TC-3b).

## What Could Be Improved
- **Mis-scoped a convention and caught it late.** I applied the `feedback_hashed_script_working_perms`
  "chmod 0700" rule to `Consistency.pm`, committing it `100755`. That rule is scoped to
  *executable scripts with a recorded `permissions` field*; this is a `use`d library module whose
  `script-hashes.json` entry has no `permissions` key (validate never checks its mode), and every
  sibling `CWF::Validate::*` module is `100644`. Caught on the post-commit mode-change line and
  corrected to `0600` via amend (content unchanged → recorded sha256 still valid). Better would
  have been to check the sibling modules' modes *before* chmod'ing.

## Key Learnings
### Technical Insights
- **Leaf identification keys off the recorded `**Branch**` field, not a parsed branch name.**
  This keeps the rule independent of branch-naming convention, at the cost that if the on-branch
  task's own `**Branch**` is wrong/absent, the leaf isn't found and the rule fails closed
  (ancestors flagged). That degradation is safe and documented in i-maintenance.md.
- **The two-pass structure is forced, not stylistic.** The directional rule must know the unique
  leaf before it can judge any single node, so the branch pass cannot run inside collection. A
  consequence is that violations group by category (Task, then Branch, then Status) rather than
  interleaving per directory — byte-identical for flat repos and for branch-only findings.
- **`-l` before `-d` is the whole symlink defence**, because `-d` stat-follows. Ordering is the
  correctness property.

### Process Learnings
- **The hashed-file perms convention is script-scoped, not blanket.** Library `.pm` modules under
  `.cwf/lib/CWF/` have no `permissions` entry and should match their siblings (`100644`); the
  0700 rule is for executable scripts/agents that carry a recorded permission. Worth recording so
  the mistake isn't repeated.
- **Git-free fixtures beat git-gated ones where the behaviour doesn't need a current branch.** By
  letting `_current_branch` return undef on a plain tempdir, completeness/FR1/symlink/warning
  cases run everywhere; only branch-directional cases need Tier C.

### Risk Mitigation Strategies
- The a-task-plan risk "leaf mis-identified under non-default branch naming" was mitigated exactly
  as planned (match recorded `**Branch**`, not the branch string) and pinned by tests.
- The "recursion surfaces latent inconsistencies" risk was accepted as correct output and verified
  against the live repo (`cwf-manage validate: OK`).

## Recommendations
### Process Improvements
- Before chmod'ing any hash-tracked file, check whether its `script-hashes.json` entry records a
  `permissions` field and what the sibling files in the same directory use — don't apply the
  script 0700 rule reflexively to library modules.

### Tool and Technique Recommendations
- Keep citing a concrete in-repo precedent for any traversal/security idiom in the design phase —
  it's exactly what let the reviewers catch the wrong (`build_tree`) precedent.

### Future Work
- No new backlog items. The two known limitations (inter-category ordering; no explicit recursion
  depth cap) are documented in i-maintenance.md with their invariants and are non-issues for CWF's
  use (advisory unordered output; trusted local trees). Revisit only if a consumer reports a need.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-27
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning + exec docs: this task directory (`a-` through `i-`).
- Implementation: `.cwf/lib/CWF/Validate/Consistency.pm` (+ in-commit `script-hashes.json` refresh).
- Tests: `t/validate-consistency.t` (20 subtests).
- Per-phase checkpoint commits preserved on the checkpoints branch (see Step 10).
