# update lock fails own clean-tree check - Retrospective
**Task**: 191 (bugfix)

## Task Reference
- **Task ID**: internal-191
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/191-update-lock-fails-own-clean-tree-check
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-11

## Executive Summary
- **Duration**: ~1 day (estimated: <1 day; on estimate). All seven phases
  (a,c,d,e,f,g,j) completed 2026-06-11.
- **Scope**: Unchanged from plan. Single-file behavioural fix to `cwf-manage`
  plus two regression subtests; no additions, no descoping.
- **Outcome**: Success. `cwf-manage update` no longer self-blocks on its own
  `.cwf/.update.lock` when the manifest-mandated `.gitignore` line is absent.
  Surfaced by a downstream v1.1.189 upgrade (issue 1 of 2).

## Variance Analysis
### Time and Effort
- **Estimated**: <1 day total (bugfix: a,c,d,e,f,g,j — no b/h/i).
- **Actual**: ~1 day, single session (2026-06-11). No phase materially over-ran;
  the bulk of effort was design (choosing the git exclude-pathspec approach over
  re-order / post-split-filter alternatives) and the red→green evidence step.
- **Variance**: ~0%. Low-complexity, well-scoped fix; estimate held.

### Scope Changes
- **Additions**: None to the planned changeset. One unplanned **on-sight repair**
  occurred during testing: pre-existing local perm drift on `.claude/agents/*.md`
  (`0400` vs recorded floor `0444`) was restored to `0444` so the suite was green.
  Not a tracked change (git stores these `100644`), so it added nothing to the
  commit — recorded per the fix-on-sight convention, not descoped.
- **Removals**: None.
- **Impact**: None on timeline or quality.

### Quality Metrics
- **Test Coverage**: Critical path 100% — TC-4 (lock-only → clean) and TC-5
  (lock + real dirty path → dies, lists real path only) cover both the fix and the
  exclusion-is-exact guard. Full suite: 62 files / 726 tests green.
- **Defect Rate**: 0 defects introduced. Red→green demonstrated explicitly
  (TC-4 + TC-5's `unlike` fail pre-fix). Both exec-phase security reviews:
  `no findings`.
- **Performance**: N/A — one added git pathspec argument.

## What Went Well
- **Design caught the trap early**: the "do not absolutise the pathspec" note in
  c-design-plan meant the bare-vs-absolute distinction (`acquire_update_lock` joins
  to `$git_root`; `check_clean_tree` passes bare) was implemented correctly first
  time, with no re-open of the bug.
- **Single source of truth**: introducing `$UPDATE_LOCK_REL` removed the latent
  drift site between the two consumers of the lock path — the exact failure mode
  that made the bug subtle.
- **Red→green proof via stash**: stashing only the `cwf-manage` edit (leaving the
  new tests in place) gave clean, unambiguous evidence the tests fail pre-fix.
- **Plan-review panels paid off**: the d-phase robustness reviewer caught a stale
  `0500` perms value carried into the design doc before it could mislead exec.

## What Could Be Improved
- **Tests-first ordering was inverted in practice**: core edits were applied before
  the red run (edit-then-stash rather than write-test-first). The evidence was
  equivalent, but strict TDD ordering would have produced red without the stash
  dance. Minor.
- **Pre-existing agent-perm drift is a recurring papercut**: the harness
  materialises `.claude/agents/*.md` at `0400`, which trips
  `t/cwf-manage-fix-security.t` test 10 in any working tree, unrelated to the task
  in flight. This is the second time agent-perm drift has surfaced mid-task — it
  belongs in a durable fix, not repeated on-sight repair (see Future Work).

## Key Learnings
### Technical Insights
- A git `:(exclude)<path>` magic pathspec is the clean way to make a `git status`
  scan ignore exactly one file without parsing porcelain output in Perl — it keeps
  the NUL-`-z`-opaque-record contract intact and sidesteps rename-pair edge cases.
- `cwf-manage validate` treats recorded `permissions` as a **ceiling**, so
  `fix-security` will not *raise* a file that drifted *below* its recorded value
  (e.g. `0400` under a `0444` record). Floor-style test assertions and the
  ceiling-style validator can therefore disagree; `fix-security` repairing "0 files"
  is not proof a floor violation is absent.

### Process Learnings
- Demonstrating red by stashing a single tracked file (not the whole change) is a
  reliable, low-friction way to evidence a regression test against unfixed code
  mid-exec — worth reaching for whenever core and tests land together.
- Estimation for a well-scoped single-file `cwf-manage` fix was accurate; the
  design-phase alternatives analysis was the right place to spend the time.

### Risk Mitigation Strategies
- The High-priority "over-broad exclusion" risk from a-task-plan was retired by
  making the exclude an **exact literal** and pinning it with TC-5's
  `unlike(... .update.lock ...)` + `like(... notes.md ...)` pair — the risk became
  an enforced regression check rather than a hope.
- The Medium "re-order would break D8" risk was retired by explicitly rejecting the
  re-order in design and keeping acquire-before-check; the security review
  confirmed the symlink/TOCTOU guard still runs first.

## Recommendations
### Process Improvements
- When core and tests are authored together, prefer authoring the test first and
  running it red before the core edit — or, if not, stash-the-core to evidence red
  (as done here) and record it. Either satisfies the red→green gate.

### Tool and Technique Recommendations
- Reuse the single-file-stash red-demonstration technique for future bugfixes where
  the test harness can call the changed function directly.

### Future Work
- **Agent-perm drift durable fix**: the existing Medium backlog item "Make
  `.claude/agents/cwf-plan-reviewer-misalignment.md` enforced-permission survive git
  checkout" is the right home for the recurring `0400`-vs-`0444` drift that trips
  `t/cwf-manage-fix-security.t` test 10. No new item raised — fold this recurrence
  into that one.
- **Downstream issue 2 (preamble first-insert)** remains a separate backlog item
  (Low): `apply_embedded_block` treats a marker-less container as a conflict
  requiring `CWF_UPGRADE_RESOLVE=new` rather than a clean first-time insert. Not in
  scope here.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-11
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, c-design-plan.md, d-implementation-plan.md, e-testing-plan.md
- Execution: f-implementation-exec.md, g-testing-exec.md
- Commits (task branch): a=b1315c8, c=710821e, d=bad8d22, e=1c236cb, f=996d340, g=cfe2c35 (baseline fbf8adf)
- Tests: t/cwf-manage-check-clean-tree.t (TC-4, TC-5); full suite 726 tests green
- Security: both exec-phase `cwf-security-reviewer-changeset` runs returned `no findings`
