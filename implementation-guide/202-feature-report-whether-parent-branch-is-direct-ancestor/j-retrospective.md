# report whether parent branch is direct ancestor - Retrospective
**Task**: 202 (feature)

## Task Reference
- **Task ID**: internal-202
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/202-report-whether-parent-branch-is-direct-ancestor
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-14

## Executive Summary
- **Duration**: ~1 working day across one workflow run (estimated <1 day, Low; on estimate).
- **Scope**: Delivered exactly as planned — a tri-state parent-branch-ancestry signal
  surfaced additively by `context-manager hierarchy`, backed by one new library function
  (`CWF::TaskPath::parent_branch_ancestry`) and a shared list-form git runner hoisted into
  `CWF::Common` (`run_quiet`). One in-scope refactor rode along (de-duplicating `delete`'s
  local runner). Nothing was added or descoped.
- **Outcome**: Success. All five a-task-plan success criteria and AC1–AC5 met; TC-1…TC-9 +
  regression (67 files, 807 tests) green; `cwf-manage validate` OK; both exec-phase security
  reviews returned **no findings**.

## Variance Analysis
### Time and Effort
- **Estimated**: <1 day, Low complexity (one helper + its test, additive output).
- **Actual**: Single continuous workflow run. The two-step git shape (existence guard +
  list-form `--is-ancestor`) already existed at `task-workflow.d/delete`, so the design was
  a known pattern lifted into a testable library function rather than invented.
- **Variance**: On estimate. The only unplanned effort was integrity handling (below), which
  was process friction rather than design work.

### Scope Changes
- **Additions**: None to requirements. The `run_quiet` **hoist** (vs cloning the runner) was
  a design-time decision under "reuse over duplication", disclosed in c-design, and brought
  the `delete` refactor in as planned supporting work — not scope creep.
- **Removals**: None. Broader `run_quiet` adoption by *other* existing call sites was
  out of scope from the implementation plan and remains so.
- **Impact**: Touching the integrity-tracked, security-sensitive `delete` was the accepted
  cost of genuine de-duplication; a relocate-but-leave-the-copy half-measure was explicitly
  rejected in design.

### Quality Metrics
- **Test Coverage**: 100% of the tri-state branches (`1`/`0`/`undef`); every row of the
  c-design edge-case table has a case (TC-1…TC-9). TC-8 parses JSON with a real parser
  (`JSON::PP`) — guarding the hand-rolled serialiser's trailing-comma edit, not a regex.
- **Defect Rate**: Zero functional defects. One test-authoring miscount (TC-8 `plan tests`
  11-vs-10) caught and fixed during g; no production defect escaped any phase.
- **Performance**: Two extra local `git` calls on a *parented*-task `hierarchy` invocation
  only; negligible, gated behind the existing `parent_path` resolution.

## What Went Well
- **Precedent reuse over invention**: the `delete` two-step git shape gave a tested model for
  the existence-guard + `--is-ancestor` pair, so design collapsed to "lift it into a library
  function and harden it." Correctness-over-novelty again the strongest estimate lever.
- **The tri-state contract earned its keep**: returning `undef` distinct from `0` (Perl's
  natural defined-but-false) lets a consumer separate *diverged* from *undecidable* with no
  sentinel string — the property AC3 and the whole feature hinge on.
- **Security-critical decision held under review**: the deliberate refusal to reuse the
  backtick `branch_exists` for the existence guard — for both shell-safety and to avoid the
  `--list` glob's prefix-collision false-positive — was endorsed by both exec security reviews
  and proven by TC-6 (a `feature/1-foo` decoy does not match an absent `feature/1-foobar`).
- **`POSIX::_exit` in the shared runner**: hoisting forced the Task-159 convention into a
  broadly-imported module, which is *more* correct than the original local copy — `delete`
  imports `File::Path`, so a plain `exit` in the forked child could have run an inherited
  cleanup END block against parent state.

## What Could Be Improved
- **Integrity-refresh friction on hash-tracked edits**: the four-file sha256 refresh was the
  fiddliest part of an otherwise small task. `cwf-manage fix-security` (correctly) refuses to
  rewrite content hashes — "surface, never smooth" — so the refresh was a manual
  `sha256sum`-into-`script-hashes.json` edit, during which a transient `PLACEHOLDER_REMOVE`
  mis-edit was made and immediately reverted. This is the expected, by-design workflow, but it
  is error-prone by hand. (Not a new backlog item — it is the deliberate friction.)
- **Diagnosing my own integrity drift**: after the edits, five test files failed and four
  validate violations appeared. Initial reading mistook them for pre-existing repo issues; the
  true cause was Edit-tool perm bumps (0500→0700) plus stale hashes, which `git stash` cannot
  revert (git tracks only the executable bit). Lesson recorded below.
- **Stale planning-phase statuses**: a–e were left at "In Progress" through the exec phases
  and only corrected at retrospective. The pre-retrospective status sweep caught it (as
  designed), but writing `Finished` at each phase's own checkpoint would keep `cwf-status`
  honest mid-task.

## Key Learnings
### Technical Insights
- **`git stash` is content-only**: it reverts file *content* but not fine-grained
  `0700`↔`0500` permission bits (git records only the exec bit). When cross-checking for
  pre-existing failures on a "clean" tree, residual perm drift will persist and can be
  misread as a repo problem — it is your own Edit-induced drift.
- **A hand-rolled JSON serialiser must be regression-tested with a real parser.** The new
  field required adding a trailing comma to the prior last line; a missed comma yields silently
  malformed JSON. TC-8's `JSON::PP` parse (not a regex) is the guard that makes the additive
  edit safe.
- **Detached HEAD is not undecidable.** `merge-base --is-ancestor <parent> HEAD` resolves
  `HEAD` to the current commit even detached, giving a correct true/false; only a genuinely
  unborn HEAD errors (rc ∉ {0,1}) ⇒ `null`. The rc-only runner can't capture a branch name, so
  the commit-level answer is both simpler and more useful — a design refinement of FR4's
  original wording.

### Process Learnings
- The CWF phase split correctly placed *all* new-test authoring in g-testing-exec even though
  the implementation plan listed "tests" under Step 5 of f — recording it as a phase boundary,
  not a deferral, kept the deferral check honest.
- When two adjacent exec phases share byte-identical production code, the second security
  review adds no signal beyond the test harness — here g's review correctly scoped to the new
  test file only and pointed at f's clean production review.

### Risk Mitigation Strategies
- Both a-task-plan risks were retired by design, not hope: Risk 1 (implicit parent-branch
  derivation, possibly renamed/deleted) maps to the planned `undef` fallback, verified by TC-5;
  Risk 2/3 (ancestry semantics, git edge cases) settled in requirements/design and verified by
  TC-3/TC-7.

## Recommendations
### Process Improvements
- Set `**Status**: Finished` at each phase's own checkpoint commit rather than batch-correcting
  planning-phase statuses at retrospective — keeps `cwf-status` accurate throughout and avoids
  leaning on the pre-retrospective sweep as the only safety net.

### Tool and Technique Recommendations
- `CWF::Common::run_quiet` is now the canonical list-form, injection-safe, `POSIX::_exit`-hardened
  git/command runner. Future helpers that shell out to `git` with a data-derived argument should
  use it rather than backticks or a local fork/exec copy — and keep call sites list-form.
- When refreshing hash-tracked files, restore working perms to the **recorded** value (0500),
  not a bumped 0700; recorded perms are a ceiling, so an over-bump now fails `validate`.

### Future Work
- **`branch_exists` shell-form audit** (noted by both security reviews, not new to this task):
  `CWF::TaskPath::branch_exists` still uses backtick `git branch --list '$branch'` (shell
  interpolation + `--list` glob). Safe at its current callsites because branch names are
  constrained, but the riskier pattern. Any future caller feeding it a less-trusted name should
  migrate to the list-form `run_quiet` + `rev-parse --verify` shape this task established.
  Carried as a watch-item rather than a forced rewrite.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-14
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md … e-testing-plan.md (this task directory)
- Implementation/Testing results: f-implementation-exec.md, g-testing-exec.md
- Rollout/Maintenance: h-rollout.md, i-maintenance.md
- Code: `.cwf/lib/CWF/Common.pm` (`run_quiet`), `.cwf/lib/CWF/TaskPath.pm`
  (`parent_branch_ancestry`), `.cwf/scripts/command-helpers/context-manager.d/hierarchy`,
  `.cwf/scripts/command-helpers/task-workflow.d/delete`
- Tests: `t/taskpath-parent-branch-ancestry.t`
