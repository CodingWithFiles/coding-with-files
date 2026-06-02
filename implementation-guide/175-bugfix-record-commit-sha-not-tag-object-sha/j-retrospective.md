# record commit sha not tag-object sha - Retrospective
**Task**: 175 (bugfix)

## Task Reference
- **Task ID**: internal-175
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/175-record-commit-sha-not-tag-object-sha
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-02

## Executive Summary
- **Duration**: ~part of one session (estimate <0.5 day, Low). On estimate.
- **Scope**: As planned — peel the resolved ref to its commit (`<ref>^{commit}`) at the two `cwf_sha`-recording sites (`install.bash`, `cwf-manage` `resolve_sha`), plus an annotated-tag regression test and the same-commit hash refresh. No scope additions to the code; one out-of-band working-tree perm repair surfaced and was resolved during testing (see below).
- **Outcome**: Success. A tagged install/update now records the tag's **commit** SHA in `.cwf/version` instead of the annotated-tag object SHA, so the recorded SHA matches `git log`. The defect was display-only but it manufactured a phantom "subtree can't pin a tag" conclusion in a real upgrade session — the friction was the cost.

## Variance Analysis
### Time and Effort
- **Estimated**: <0.5 day total (Low complexity); no per-phase breakdown planned.
- **Actual**: Planning a/c/d/e in a prior session; f/g exec in this session. Net effort matched the estimate — the fix is two one-token edits.
- **Variance**: None material. The only unplanned effort was diagnosing the `fix-security` TC-8 fallout (below), ~minutes.

### Scope Changes
- **Additions**: None to production code. The annotated-tag test (`t/version-records-commit-sha.t`) was planned. One unplanned working-tree action: `chmod 0444` on `.claude/agents/cwf-security-reviewer-changeset.md` to restore it to its recorded perms after an earlier `fix-security` clamp left it at `0400`.
- **Removals**: None.
- **Impact**: Negligible on timeline; net-positive on correctness of the local working tree.

### Quality Metrics
- **Test Coverage**: Both changed sites covered by the annotated-tag discriminator (TC-1 install.bash, TC-2 cwf-manage update). Non-annotated ref forms covered transitively by the existing lightweight-tag E2E suites. 100% of changed lines exercised.
- **Defect Rate**: 0 defects in the fix. 1 transient full-suite failure (pre-existing perm drift, not in this task's diff) found and resolved during g.
- **Performance**: N/A.

## What Went Well
- **Test-first proved the bug and the fix.** The new test was red against current code (recording the tag-object SHA) and green after — and the `cwf_version` regression guard was green throughout, directly evidencing the blast-radius claim that `git_describe_version` is unaffected.
- **The annotated-vs-lightweight insight, surfaced at plan review, was decisive.** The shared `build_upstream` fixtures use lightweight tags where `^{commit}` is a no-op, so the bug *cannot reproduce* there. The test creating its own annotated tag (`git tag -a`) is the entire reason the test has discriminating power.
- **Idiom reuse over new abstraction.** Peeling with `^{commit}` matches two existing call sites (`security-review-changeset:285`, `task-workflow.d/delete:209`); no shared helper introduced for two one-token edits (Rule of Three not met).
- **Same-commit hash refresh held the integrity invariant** — `validate` clean at every checkpoint.

## What Could Be Improved
- **The earlier `fix-security` "fix" was only half a fix.** Asked to repair pre-existing perm drifts, the instinct was `cwf-manage fix-security`. But `fix-security` *clamps* (`actual & recorded`) — it can only remove bits, never restore missing ones. For `.claude/agents/cwf-security-reviewer-changeset.md` (drift `0600`, recorded `0444`) it produced `0400`, which satisfied `validate`'s **ceiling** but fell below `t/cwf-manage-fix-security.t` TC-8's **floor**. The drift wasn't *more* permissive, it was *differently-shaped* permissive (write bit present, read bits missing), and clamping can't fix that. The right tool was `chmod` to the recorded value.
- **`validate` passing is not the same as perms being correct.** `validate` is a one-sided (ceiling) check; TC-8 is the complementary floor check. A green `validate` after `fix-security` gave false confidence that the drift was fully resolved.

## Key Learnings
### Technical Insights
- **`git rev-parse <ref>` returns the *object* a ref names; only `<ref>^{commit}` guarantees the commit.** For annotated tags these differ (tag object vs commit). The peel is a no-op for branches, lightweight tags, raw SHAs, and `HEAD`, so it is always safe to apply when you want a commit.
- **Recorded perms are simultaneously a `validate` ceiling and a TC-8 floor** → the only value satisfying both is *exactly* the recorded one. `fix-security` (clamp-down) can reach that only when the drift is purely more-permissive; when read bits are missing, `chmod <recorded>` is required.

### Process Learnings
- **A display-only field can still cause real harm** by misleading a human/agent reader. "Nothing verifies against it" was true and still the bug was worth fixing — the cost was a rabbit hole in a real upgrade session.
- **Run the full suite, not just the named regressions, before declaring testing done.** The named regression suites (`install-bash-reinstall`, `cwf-manage-update*`) all passed; only `prove t/` surfaced the unrelated TC-8 perm failure.

### Risk Mitigation Strategies
- Plan-review's catch (lightweight vs annotated tags) was the early-warning sign that the obvious fixture would have produced a vacuously-passing test. Worth more than the fix itself.

## Recommendations
### Process Improvements
- When repairing a perm drift, **diagnose the drift's shape first**: more-permissive-than-recorded → `fix-security` clamps it; missing-recorded-bits → `chmod` to recorded. Don't reach for `fix-security` reflexively.
- After any `fix-security` run, run `prove t/cwf-manage-fix-security.t` (the floor check), not just `validate` (the ceiling check).

### Tool and Technique Recommendations
- The annotated-tag discriminator pattern (`rev-parse <tag>` ≠ `rev-parse <tag>^{commit}` as a precondition) is reusable for any future test that must distinguish tag objects from commits.

### Future Work
- The pre-existing backlog item "Restore Task-173 permission drift on three helper scripts" remains open; this task touched a *different* drifted file (the agent `.md`) opportunistically. A consolidated perm-drift housekeeping pass could verify all recorded-vs-on-disk perms in one go and use the right tool per drift shape.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-02
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`, `c-design-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`
- Execution: `f-implementation-exec.md`, `g-testing-exec.md`
- Commits (pre-squash): `4e06a40` (a), `0916561` (c), `a829fe3` (d), `8c0cf5c` (e), `d37ed6f` (f), `104b4d5` (g)
- Test: `t/version-records-commit-sha.t`
