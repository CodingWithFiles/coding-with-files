# Replace git-subtree with read-tree laydown - Retrospective
**Task**: 185 (feature)

## Task Reference
- **Task ID**: internal-185
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/185-replace-git-subtree-with-read-tree-laydown
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-07

## Executive Summary
- **Duration**: ~1 day single-session (estimated: 2–3 days) — under estimate, helped by an
  early spike retiring the top risk and by the change concentrating in two files plus one
  new helper.
- **Scope**: Delivered as planned — read-tree default + copy fallback + subtree
  refused/migrated + advisory `cwf-detect-merges`. No scope cut; one finding surfaced for a
  possible follow-up (fresh-install perms clamp).
- **Outcome**: Success. The merge-commit bug (subtree forcing merges into consumer history)
  is fixed; `prove t/` 706 tests green; two security reviews `no findings`; `validate` clean
  throughout.

## Variance Analysis
### Time and Effort
- **Estimated**: 2–3 days (medium complexity).
- **Actual**: One focused session across all ten phases.
- **Variance**: Faster than estimated. The design-phase spike (read-tree mechanics) removed
  the biggest unknown before any production code, so implementation had no false starts.

### Scope Changes
- **Additions**: none beyond plan. The migration tests required crafting a `cwf_method=subtree`
  fixture *without* `install.bash` (which now refuses subtree) — anticipated in e-testing-plan.
- **Removals**: none. The three "item 1" subtests in `t/install-bash-reinstall.t` were
  removed (not descoped work — they tested `install_subtree`'s now-deleted force-commit
  logic); their intent moved to the new read-tree determinism tests.
- **Impact**: neutral on timeline; net simplification (one fewer laydown method, copy's
  `chmod u+rx` fix-up no longer needed by read-tree).

### Quality Metrics
- **Test Coverage**: AC1–AC10 each ≥1 automated test; +3 new test files (TC-1..TC-13);
  suite grew 58→61 files, 706 tests, all green.
- **Defect Rate**: zero post-implementation product defects. Two test-harness bugs caught
  and fixed during g (backtick shell-split; `.cwf/version`-timestamp tree confound).
- **Security**: implementation-exec and testing-exec reviews both `no findings`.

## What Went Well
- **Spike-first on the top risk.** Proving read-tree's tree-identity, merge-freeness, mode
  preservation, and reinstall-collision behaviour in a throwaway repo *before* committing
  the approach meant the design rested on evidence, not assumption.
- **Empirical fingerprint check.** Probing a real `git subtree add --squash` merge revealed
  it carries **no** `git-subtree-dir` trailer — the squash second-parent subject is the
  signal that fires. Guessing here would have shipped a detector that never matched.
- **Refuse-new / migrate-existing split** kept the deprecation from bricking existing
  installs, exactly as the risk register intended.
- **Data-safety caught in review.** The plan-review flag on `checkout-index -a` (could
  clobber unrelated dirty files on the precondition-free fresh path) led to the scoped,
  NUL-safe materialise — verified by the smoke test preserving an unrelated dirty file.

## What Could Be Improved
- **AC1 was written stricter than reality.** "Fresh install … validate clean" is not met by
  *either* method (umask-vs-ceiling), which only surfaced at exec via the smoke test. A
  requirements-phase check against the existing copy behaviour would have caught the
  mismatch earlier and let AC1 be phrased against the update/migration path.
- **Untracked new test files escaped the auto-changeset.** The testing-exec security review
  noted the three new `t/*.t` files were untracked, so `git diff baseline..worktree` omitted
  them (the reviewer read them from disk). Staging new files before the changeset build, or
  the helper including untracked files, would close that gap.

## Key Learnings
### Technical Insights
- `git read-tree --prefix` refuses to overlay an existing prefix — reinstall **must** clear
  the index+worktree first; this is the property that makes laydown deterministic.
- Fetch the clone's `HEAD` (post-checkout), not `$ref` by name: a raw SHA is not fetchable
  on the local transport unless advertised.
- `git checkout-index`/`cp` set perms from umask, **not** the recorded ceiling — so neither
  fresh-install method is `validate`-clean until a `fix-security`/update clamp. The design's
  "read-tree sheds copy's perm fix-ups" claim is true only for the `chmod u+rx` step, not the
  ceiling.

### Process Learnings
- The four-agent plan review earned its keep: it caught the `checkout-index -a` data-safety
  hazard and the unquoted command-substitution before any code existed.
- Phase separation held under tension: existing subtree-fixture tests broke at f (intended
  behaviour change), and g owned bringing them green — the `validate`-gated f checkpoint
  let that sequence work without a knowingly-red product commit.

### Risk Mitigation Strategies
- Pre-committing the risky mechanic to a spike (design phase) is the highest-leverage move
  for a "the primitive might not behave as I think" risk.
- For fingerprinting external artefacts, **probe the real artefact** rather than trusting a
  remembered format.

## Recommendations
### Process Improvements
- When an AC asserts a post-condition (`validate` clean), sanity-check it against the
  nearest existing behaviour during requirements, not exec.
- Stage newly-created test files before running the exec-phase security changeset so they
  are reviewed in-diff (or extend the changeset helper to include untracked files).

### Tool and Technique Recommendations
- Keep the spike-in-throwaway-repo pattern for any git-plumbing change.
- The `write-tree` + `rev-parse <tree>:<sub>` idiom is the clean way to compare a *staged*
  subtree without committing — useful for any laydown/idempotence assertion.

### Future Work
- **Fresh-install perms clamp (candidate follow-up).** Decide whether `install.bash`
  `post_install` should run `cwf-manage fix-security` so a raw `curl|bash` fresh install is
  `validate`-clean. It would fix the pre-existing `copy` gap too, at the cost of an
  installer→cwf-manage coupling at bootstrap. Deferred to the user's call; not required by
  this task (the migration/update path already clamps).
- **Tidy `seed_tracked_dirs`** (now-unused helper in `t/install-bash-reinstall.t`) in a
  future dead-code sweep.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-07
**Sign-off**: The maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning/exec docs: `implementation-guide/185-feature-replace-git-subtree-with-read-tree-laydown/` (a–j)
- Key commits on the task branch: `8329964` (NUL-safe design fix), `29b1f79` (implementation
  exec), `c9d3728` (testing exec), `b8d67a2` (rollout), `fb69a07` (maintenance)
- Test results: `prove t/` → 61 files, 706 tests green
- Security reviews: `no findings` (implementation-exec, testing-exec) — recorded in f/g
