# fix outstanding cwf-manage issues - Retrospective
**Task**: 159 (feature)

## Task Reference
- **Task ID**: internal-159
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/159-fix-outstanding-cwf-manage-issues
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-24

## Executive Summary
- **Duration**: ~1 working session on 2026-05-24 (estimated 1–2 days; bundled 4 prior backlog entries into one flat task).
- **Scope**: Delivered **3 of 4** bundled items — FR1 (version/ref semver-resolution bug), FR2 (`fix-security --dry-run`), FR4 (backtick→list-form `git_capture`). FR3 (copy-method convergence) was **deferred at the design gate** and remains on the backlog.
- **Outcome**: Success. The Very-High-priority version bug is fixed and the perlcritic backtick surface is closed; both ship with no consumer-visible regressions. The deferral was an informed design decision, not a shortfall.

## Variance Analysis
### Time and Effort
- **Estimated**: 1–2 days, Medium complexity, 4 milestones.
- **Actual**: One session. Phase order followed the plan: FR4 (helper extraction) → FR1 (version write atop the new helper) → FR2 (dry-run).
- **Variance**: Under-run on wall-clock; the Medium rating was accurate for the three surgical edits once FR3 (the only High-risk milestone) was removed. The estimate's complexity driver was explicitly FR3's symlink-escape porting — deferring it took the risk out with it.

### Scope Changes
- **Removals**: (1) **FR3 copy-method convergence deferred** — all four plan-review reviewers leaned defer: a new copy-laydown guard script would sit outside the hash ledger and the changeset auto-review set, and carries CWF_FORCE/.cwf-rules preconditions; porting `_escapes_src` into bash `cp -r` was judged worse than the status quo. Stays on the backlog (Low).
- **Additions**: None.
- **Design substitution (not a scope change)**: FR4 was planned as `IPC::Open3` (c-design D4) but switched to a list-form `open '-|'` fork at the implementation-plan review — reviewers flagged IPC::Open3's deadlock/stderr-merge traps and NFR3's preference for the lighter primitive. Same AC (no backticks, behaviour-equivalent), simpler mechanism.
- **Impact**: 4 of 5 success criteria fully met; the copy-convergence criterion is explicitly deferred and tracked, not silently dropped.

### Quality Metrics
- **Test Coverage**: Full suite 48 files / 527 tests green. New `t/cwf-manage-git-capture.t` (6 subtests, FR1+FR4); `t/cwf-manage-fix-security.t` +3 (FR2); `t/cwf-manage-update-end-to-end.t` +2 (FR1 integration). `cwf-manage validate` clean; `perlcritic` backtick policy `source OK`.
- **Defect Rate**: Zero product defects. One in-flight authoring fix: a bare `POSIX::_exit(127)` after `exec` tripped perl's "Statement unlikely to be reached" warning; collapsed to `exec(...) or POSIX::_exit(127)`.
- **Security**: Implementation- and testing-phase changeset reviews — both **no findings**. FR4 removes a `$source` shell-string interpolation (net hardening). One pattern note on a backtick in a *test* helper (`git_in`), accepted as test-harness convention.

## What Went Well
- **Bundling was the right call**: four items sharing one file (`cwf-manage`), one hash refresh, and one review pass. Subtasks would have added 4× workflow ceremony for surgical edits; the flat-task decision (recorded in a-task-plan's decomposition check) held up.
- **Helper-first ordering**: extracting `git_capture` (FR4) before the FR1 version write meant `git_describe_version` was built on an already-unit-tested primitive, and the version-write change was a one-line wiring delta.
- **Plan review caught a real design trap**: the IPC::Open3→`open '-|'` switch came directly from the implementation-plan reviewers, before any code was written — the gate did its job.
- **Tag-as-release model made FR1 tractable**: framing "latest = highest semver tag" (the maintainer's steer) gave `git describe --tags --always` a clean spec — exact tag, long form, or abbreviated SHA, never a bare ref in `cwf_version`.

## What Could Be Improved
- **The backlog item for FR4 was stale**: it claimed "5 backtick usages" but only 2 remained — `resolve_ref`/`resolve_sha` were already converted in Task 155. Verifying the claim against source at requirements time (rather than trusting the backlog text) avoided over-scoping, but the stale count should have been corrected on the backlog entry sooner.
- **A Windows-idiom habit leaked twice**: smoke-testing via `perl -I.cwf/lib <script>` instead of `chmod`+shebang execution drew a correction. The chmod-and-execute convention is in memory; the reflex still surfaced.

## Key Learnings
### Technical Insights
- **`open '-|'` fork beats IPC::Open3 for capture-only git calls**: when you only need stdout + exit status and want stderr discarded, the fork-and-reopen-STDERR pattern avoids IPC::Open3's select-loop/deadlock surface entirely. IPC::Open3 earns its keep only when you must read stderr separately.
- **Forward-only reach is intrinsic to updater fixes**: FR1/FR2 live in `cwf-manage`, which the consumer runs from their *installed* (old) copy — so the fix only lands in installs made at/after the carrying tag. The right response is to document the bootstrap-reinstall recovery, not to attempt self-repair (same lesson as Task 155).
- **`POSIX::_exit` in a forked child** (not `exit()`): bypasses inherited END blocks so File::Temp CLEANUP can't rmtree the parent's tempdir. Captured as a reusable memory.

### Process Learnings
- **Verify backlog claims against source before scoping**: the "5 backticks" figure was two releases stale. Backlog text is a pointer, not ground truth; the requirements phase should re-derive counts from the current tree.
- **Design substitutions are cheaper at the plan-review gate than in exec**: the IPC::Open3→`open '-|'` change cost nothing because it landed before implementation. The review step is where mechanism choices should be stress-tested.

### Risk Mitigation Strategies
- **Deferring at the design gate is a first-class outcome**: FR3 carried the task's only real risk; the convergent reviewer signal to defer (rather than force a weaker bash symlink guard) removed it cleanly and kept the item tracked.

## Recommendations
### Process Improvements
- For backlog items that cite specific counts or line numbers, add a requirements-phase step to re-confirm them against `HEAD` — stale citations from prior tasks accrue silently.

### Tool and Technique Recommendations
- Standardise `git_capture` as the canonical in-`cwf-manage` git invocation primitive; new git calls should route through it rather than reintroducing backticks (recorded in i-maintenance.md).

### Future Work
- **Copy-method convergence** (BACKLOG, Low): unchanged from Task 155's filing — port the symlink-escape guard so the copy update path can also delegate to `install.bash`. FR3 here confirmed the deferral rather than retiring it.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-24
**Sign-off**: Task maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, b-requirements-plan.md, c-design-plan.md
- Implementation: d-implementation-plan.md, f-implementation-exec.md (in-flight POSIX::_exit fix)
- Testing: e-testing-plan.md, g-testing-exec.md, `t/cwf-manage-git-capture.t`
- Delivery: h-rollout.md, i-maintenance.md
- Commits: 1fc2a2c(a) 8cfab05(b) 66017ad(c) e5861b9(d) 7625074(e) 76a0c80(f) 9e03673(g) 08599a3(h) 84deed7(i)
