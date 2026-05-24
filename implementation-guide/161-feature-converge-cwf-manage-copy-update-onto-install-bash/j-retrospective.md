# converge cwf-manage copy update onto install.bash - Retrospective
**Task**: 161 (feature)

## Task Reference
- **Task ID**: internal-161
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/161-converge-cwf-manage-copy-update-onto-install-bash
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-24

## Executive Summary
- **Duration**: ~1 working session on 2026-05-24 (estimated 1–2 days, Medium complexity). Implements FR3 deferred at Task 159's design gate.
- **Scope**: Delivered all five success criteria — copy update converged onto `install.bash` (single laydown path), the symlink-escape guard extracted into one integrity-covered helper (`cwf-check-tree-symlinks`), the previously-unguarded fresh copy-install path now guarded, the `CWF_FORCE`/`.cwf-rules` preconditions reconciled, and the dead laydown code removed after caller enumeration.
- **Outcome**: Success. The headline security win (fresh copy install was unguarded; now fails closed before any mutation) shipped alongside the convergence that removed 340 lines of divergent laydown code. No consumer-visible regressions.

## Variance Analysis
### Time and Effort
- **Estimated**: 1–2 days, Medium complexity, 5 milestones. The plan explicitly de-risked the estimate by noting Task 159's design phase had already mapped the options and preconditions.
- **Actual**: One session, milestones executed in plan order: guard relocated + integrity-covered → fresh-install gap closed → copy update converged → preconditions reconciled → verified.
- **Variance**: On-estimate. The one sensitive piece (relocating an audited security check without weakening it) was handled by moving `_escapes_src`/`_collapse_dotdot` verbatim rather than rewriting — the explicit plan mitigation, which held.

### Scope Changes
- **Additions** (beyond the plan's illustrative snippets, both justified in f-exec):
  - **`[[ -x "$guard" ]] || die` precheck in `install_copy`**: the d-plan's snippet didn't show it, but FR2/NFR5 require the guard to run before any copy — a silent skip when the helper is absent would be a fail-open. Trade-off: fresh-copy-installing a *pre-guard* ref with the new installer is refused (marginal, documented in h-rollout).
  - **Five orphaned imports removed, not three**: deleting `_escapes_src` (used `File::Spec`) and the symlink subs (used `File::Basename`) orphaned two more imports than the plan named. Verified against HEAD they had no other callers before removal.
- **Removals**: None.
- **Impact**: All five success criteria met. The two additions are net-positive (stronger fail-closed posture, cleaner removal); neither changed the AC set.

### Quality Metrics
- **Test Coverage**: Full suite 49 files / 533 tests green (up from 527; +6 subtests). New `t/cwf-check-tree-symlinks.t` (unit + CLI + TC-7 integrity); TC-3/TC-4/TC-6 in `t/install-bash-reinstall.t`; TC-5 in `t/cwf-manage-update-end-to-end.t`; TC-8 in `t/cwf-manage-update.t`. `cwf-manage validate` clean at every checkpoint.
- **Defect Rate**: Zero product defects. Two in-flight test-authoring fixes: a TC-7 tamper step appended to a 0500 (read-only) fixture → "Permission denied" (fixed with `chmod 0700` before the append); an `exec(...)` "statement unlikely to be reached" warning (collapsed to `exec(...) or POSIX::_exit(127)`).
- **Security**: Implementation- and testing-phase changeset reviews — both **no findings**. The change centralises the guard into one integrity-covered helper and closes the previously-unguarded fresh copy path (net hardening). One advisory pattern-note on a test helper (`taint_upstream`), accepted as test-harness convention.

## What Went Well
- **The deferral pre-seeded the work cleanly**: Task 159's D3 analysis had already mapped the options and preconditions, so this task started with the design space scoped. The "deferring at the design gate is a first-class outcome" lesson from 159 paid off — the follow-up was tractable precisely because the deferral was informed, not a punt.
- **Move-don't-rewrite kept the security check intact**: porting `_escapes_src`/`_collapse_dotdot` verbatim into the standalone helper avoided reintroducing the path-canonicalisation bug class the guard exists to prevent. The guard's behaviour is identical; only its call site and integrity coverage changed.
- **Convergence was a net deletion**: removing the parallel laydown collapsed two implementations into one and deleted 340 lines (six subs + five imports). TC-8 now guards against the dead code creeping back.
- **Smoke-testing the untested glue before committing**: two scratch-dir smoke scripts (clean install + escaping-refusal; copy install → copy update delegation with `.cwf-rules`/symlink parity) confirmed the `install.bash`/`cwf-manage` wiring end-to-end before the work was committed.

## What Could Be Improved
- **The plan under-counted the orphaned imports**: it named three (`File::Find`, `File::Copy`, `File::Path`) but five were actually orphaned. A requirements/implementation-plan step that greps each candidate import's symbols against HEAD — rather than eyeballing the `use` list — would have caught the extra two up front. (Echoes Task 159's "verify backlog claims against source" lesson, now generalised to import lists.)
- **The 500-line security-review cap fired twice on a deletion-heavy change**: both phase changesets exceeded the cap (741 impl / 953 testing) largely because of the 340-line dead-code deletion and re-included reviewed source. The "split the change" remedy worked (review the genuinely-new source/test surface), but the cap counts deleted lines as review burden when they carry little new attack surface — worth noting for future convergence/deletion tasks.

## Key Learnings
### Technical Insights
- **A relocated security check needs its integrity coverage relocated with it**: extracting the guard to a standalone helper only delivers the "verified guard" benefit because the success criteria made ledger membership (`script-hashes.json`) *and* auto-review membership (`@CWF_INTERNAL_PREFIXES`) non-optional. Co-locating it with `install.bash` at repo-root `scripts/` (out of ledger, like `install.bash` itself) would have left the benefit only partly real. Placement inside `.cwf/scripts/command-helpers/` got both for free.
- **The guard runs from the target-version clone, not the installed copy (D4)**: `install.bash` invokes `$clone_dir/.../cwf-check-tree-symlinks`, so the tree about to be copied is validated by *that tree's own* guard. The `[[ -x ]]` precheck fails closed if a pre-guard ref lacks the helper — the correct posture, but a trust-model shift worth stating explicitly.
- **Fresh-install and update paths have different reach**: the `install.bash` copy guard protects new installs immediately; the copy-*update* convergence is forward-only (run by the consumer's old `cwf-manage`, effective from the next update). Same forward-only intrinsic as Task 159's updater fixes.

### Process Learnings
- **Enumerate callers AND imports before a deletion**: caller enumeration (the plan's stated mitigation) caught the dead subs cleanly, but imports are a second orphan surface that the plan's count missed. Both need the same grep-against-HEAD discipline.
- **Intra-phase commits use plain `git commit`, not the checkpoint helper**: `cwf-checkpoint-commit` marks the phase Finished and stages only the wf file — wrong for mid-phase code commits. The phase-end checkpoint stages code files first, then runs the helper so the commit carries both.

### Risk Mitigation Strategies
- **Move-don't-rewrite for audited logic**: the single most effective mitigation for "weakening a security check during relocation" was to treat the existing lexical logic as immovable text — copy it byte-for-byte, change only the harness around it, and assert equivalence with the same fixtures on both paths.

## Recommendations
### Process Improvements
- For deletion/convergence tasks, add an implementation-plan step that greps each removed symbol *and each import it used* against HEAD, so the orphan set is complete before exec. (Generalises Task 159's source-verification lesson to import lists.)

### Tool and Technique Recommendations
- The single-laydown-path invariant is now the standing rule (recorded in i-maintenance.md): all install/copy-update laydown changes go in `install.bash`; `cwf-manage`'s copy branch stays a thin delegation. TC-6 (parity) and TC-8 (no dead code) are the sentinels.

### Future Work
- None filed. This task **retired** the BACKLOG item "Converge cwf-manage copy-method update onto install.bash" (the FR3 deferral from Tasks 155/159). No new follow-up identified.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-24
**Sign-off**: Task maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, b-requirements-plan.md, c-design-plan.md
- Implementation: d-implementation-plan.md, f-implementation-exec.md (5-not-3 import removal; `[[ -x ]]` precheck deviation)
- Testing: e-testing-plan.md, g-testing-exec.md, `t/cwf-check-tree-symlinks.t`
- Delivery: h-rollout.md, i-maintenance.md
- Commits: c09c0e6(a) 3e03bd2(b) bfb6294(c) 0364f5d(d) ca82990(e) a5d1079+233a26d+10adbc0+ea67ba3(f) fda99c8(g) 6fa0a28(h) 695ec25(i)
