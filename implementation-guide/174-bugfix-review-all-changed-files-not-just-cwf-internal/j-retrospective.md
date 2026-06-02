# review all changed files not just cwf-internal - Retrospective
**Task**: 174 (bugfix)

## Task Reference
- **Task ID**: internal-174
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/174-review-all-changed-files-not-just-cwf-internal
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-02

## Executive Summary
- **Duration**: ~1 day of work across 2 sessions (estimate: <1 day, Low complexity). Over the effort estimate; complexity landed closer to Medium.
- **Scope**: Original scope — delete the CWF-internal/shebang classifier so every changed file is reviewed, keep the `--max-lines` cap measuring non-test code only, sweep all docs of CWF-internal-only framing. Final scope added two user-directed/exec-discovered items: a config-key rename (`security.review.test-paths` → `max-lines-exclude-paths`) with backward-compat fallback, and reconciliation of two test files coupled to the deleted internal symbol.
- **Outcome**: Success. The shipped correctness defect is fixed — the gate now emits the full `git diff` over every changed file regardless of path or language; the cap discounts test/doc lines but reviews them. Net code change 10 files, +268/−267 (the helper is a net −156, predominantly deletion). Full suite 643 tests green; `cwf-manage validate: OK`; both exec-phase security reviews returned `no findings`.

## Variance Analysis
### Time and Effort
- **Estimated** (a-task-plan): <1 day total, Low complexity, predominantly deletion + doc correction.
  - Planning / Design: minimal
  - Implementation: ~half day (helper edit + doc sweep + tests + hash refresh)
  - Testing: minimal (extend one test file)
- **Actual**: ~1 day across 2 sessions (a context compaction fell mid-task).
  - Planning / Design / Impl-plan / Test-plan: on estimate; plan-review ran cleanly.
  - Implementation (f): over estimate — three unplanned expansions (below).
  - Testing (g): on estimate once f stabilised.
- **Variance**: Effort ran over the "predominantly deletion" estimate because (1) the cap fired on the task's *own* changeset (706 production lines > 500), which surfaced the config-key misnomer and triggered an in-task rename + back-compat path; (2) a deleted internal symbol (`@CWF_INTERNAL_PREFIXES`) was referenced by two test files outside the co-located test, not scoped by the plan; (3) pre-existing Task-173 permission drift produced 12 spurious full-suite failures that had to be diagnosed and excluded before the real result was visible.

### Scope Changes
- **Additions**:
  - **Config-key rename** `security.review.test-paths` → `max-lines-exclude-paths` (user-directed, mid-exec). The key never only excluded *test* paths — it excludes any non-counted path (this repo now lists `t/**` and `implementation-guide/**`). Includes a backward-compat fallback: the helper reads the new key, falls back to the legacy key with a stderr deprecation warning, so no adopter breaks on upgrade. Both exec SKILLs were updated to surface any helper `warning:` line verbatim regardless of exit code, so the deprecation nudge reaches users during normal runs. New TC-CAP9 asserts the legacy key still discounts and warns.
  - **Cross-file test reconciliation** (exec-discovered). `t/cwf-check-tree-symlinks.t` TC-7(b) and `t/install-bash-reinstall.t` TC-7 both asserted on the deleted `@CWF_INTERNAL_PREFIXES`; both reconciled in-task.
- **Removals**: None descoped. All a-plan success criteria met.
- **Impact**: The additions raised effort and touched two more test files than planned, but each is a net correctness/robustness improvement. The committed a/c/d/e plan docs still describe the original `test-paths` design — left as historical record per the "plans are immutable history" convention; the rename is documented as an exec deviation in f.

### Quality Metrics
- **Test Coverage**: 25 subtests in `t/security-review-changeset.t` (incl. TC-WIDEN1, TC-GUARD1a/b, TC-EMPTY1, TC-CAP8/CAP9). Every behavioural claim in c-design D1–D2 has an asserting subtest. Full suite Files=54, Tests=643, all green.
- **Defect Rate**: 9 in-exec failures, all resolved before g closed — 5 from the fixture's own a-task-plan.md entering the now-wider diff window (fixed by merge-base anchoring in `make_cap_repo`), 4 from the cross-file coupling + perm drift. Zero post-fix failures.
- **Security**: Both exec-phase reviews `no findings`. The reviewer confirmed the change strictly widens coverage and preserves every fail-safe (NUL rejection, exit-1 on malformed pattern, unconfigured-counts-as-production, empty-diff guard).

## What Went Well
- **The fix is mostly deletion.** Removing the classifier (`@CWF_INTERNAL_PREFIXES`, `%CWF_INTERNAL_FILES`, `$SCRIPT_INTERPRETER_RE`, `is_cwf_internal`, `looks_like_script`, the loop) and replacing it with `my @included = @changed;` is a −156-line net change. The simplest correct behaviour was the smallest one.
- **The empty-`@included` guard was preserved as the load-bearing invariant.** Widening the diff window made a whole-tree-leak guard (no pathspec → `git diff $anchor --` over everything) the highest-consequence safety property; it was kept and is now directly asserted by TC-EMPTY1.
- **"Surface, never smooth" held under pressure.** When the cap fired at 706 > 500 on the task's own changeset, the exec recorded `error` and did **not** hand-build a smaller changeset (the prior-session anti-pattern). The cap was resolved by a legitimate config change (excluding `implementation-guide/**` from the *count*, never from review), not by silencing the signal.
- **Back-compat without scaffolding.** The deprecated key is honoured at read time but never written by any template, so new users only ever see the new name while existing configs keep working with a visible nudge.
- **The reviewer earned its keep on a widening change.** It correctly identified that increasing the volume/variety of content into the subagent context (now arbitrary consumer source) does not change the trust boundary (read-only subagent + deterministic classifier), and flagged the deprecation-fallback re-validation path as the one thing worth auditing — which the shared validation loop already covers.

## What Could Be Improved
- **Deleting an internal symbol needs a repo-wide reference sweep at plan time.** The d/e plans scoped test reconciliation to the co-located `t/security-review-changeset.t`. Two other test files asserted on `@CWF_INTERNAL_PREFIXES`; the plan-review subagents and the author treated "the test" as the single co-located file, so the cross-file coupling surfaced only at exec. A mechanical "grep the repo for every symbol being deleted" gate at plan time would have caught it.
- **A config key was misnamed at birth and the misnomer shipped.** `test-paths` always excluded non-test paths too; nobody flagged it until the cap fired on a changeset full of non-test docs. Naming a config key after one of its use cases (tests) rather than its function (lines excluded from the cap count) cost a rename + back-compat path later.
- **Pre-existing perm drift masked the real test signal.** Three Task-173 scripts at on-disk `0700` against recorded `0500` produced 12 full-suite failures unrelated to this task. They had to be clamped in the working tree before the genuine result was visible. This is Task-173 debt, not 174's — flagged below — but it cost diagnosis time here.

## Key Learnings
### Technical Insights
- **A gate that silently passes is more dangerous than one that errors.** The classifier emitted `reviewed 0 files` for any non-script/non-CWF project and the workflow read that as a clean pass — a default-allow gate masquerading as a default-deny one. The lesson generalises: a security/quality gate whose "nothing matched" path is indistinguishable from "nothing wrong" is a latent correctness defect, not a documented limitation.
- **Dogfooding caught the defect on the tool itself.** The cap fired at 706 because this task's own wf docs counted as production lines — the helper's own changeset exercised the exact volume problem the feature exists to manage. CWF-develops-CWF turned an abstract risk (a-plan Risk 1) into a concrete forcing function.
- **The fail-safe direction survived a feature widening.** Every preserved invariant fails *toward* more review, never less: unconfigured/unmatched paths count as production (cap fires earlier), a malformed exclude pattern makes git fatal (exit 1), an empty diff short-circuits before any bare-tree diff. Widening coverage did not weaken any of them.

### Process Learnings
- **Plan review reviews plan logic, not symbol topology.** The 4-subagent map/reduce caught nothing wrong with the *reasoning*; it did not (and is not designed to) enumerate every external reference to a symbol slated for deletion. Symbol-deletion impact is a separate, mechanical dimension — complementary to the existing plan-time helper-path-verification backlog item.
- **Mid-exec scope additions belong in the exec deviation log, and the plans stay frozen.** The rename was a real scope expansion beyond the approved a/c/d/e plan; recording it as an f deviation (rather than rewriting the plans) keeps the plan docs as honest historical record of what was approved versus what was done.

### Risk Mitigation Strategies
- a-plan Risk 1 ("larger changesets now hit the cap and exit 2 where they previously passed empty") **materialised exactly as predicted** — on this very task. The pre-existing mitigation (the cap + exclude-paths exist to manage volume; hitting the cap means "review manually / split the task", not "feature broken") was the correct frame and resolved it without weakening the gate.
- a-plan Risk 2 ("removing the subs could orphan callers/tests") materialised and under-scoped: the grep-before-removal mitigation was applied to source but the plan did not extend it to *test* assertions on the constant. The mitigation was right; its scope was too narrow.

## Recommendations
### Process Improvements
- **Add a plan-time symbol-deletion reference gate.** When a plan proposes deleting a named symbol (sub, constant, package var), grep the whole repo for it and list every reference as a plan-review finding. Cheap, mechanical, complementary to the existing plan-time helper-path-verification proposal. Captured as a backlog item.
- **Name config keys after their function, not a use case.** A short convention note: a key that excludes paths from a *count* is `…-exclude-paths`, not `test-paths`. Low value as a standalone task; fold into the next config-doc touch.

### Tool and Technique Recommendations
- The "surface the helper `warning:` line verbatim, regardless of exit code" pattern added to both exec SKILLs is a reusable shape for any deprecation/upgrade nudge emitted by a helper — worth reusing rather than re-inventing per-helper.

### Future Work
- **Task-173 permission drift (housekeeping).** Three scripts — `.cwf/scripts/command-helpers/context-manager.d/location`, `.cwf/scripts/migrations/migrate-v2.1-file-order`, `.cwf/scripts/command-helpers/template-copier-v2.0` — sit at on-disk `0700` against recorded `0500` (content-modified in Task 173, baseline `c886856`, which skipped restoring perms). Clamped in the working tree here so the suite passes, but git does not track the distinction so it is not in this task's diff. Needs a dedicated `cwf-manage fix-security` run / housekeeping task. Added to backlog.
- **Plan-time symbol-deletion reference gate** (see Process Improvements). Added to backlog.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-02
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning/design/exec docs: this task directory (a-task-plan.md … g-testing-exec.md).
- Commits (pre-squash): ae66b4f (a), 1caf210 (c), f249bb5 (d), ca52c58 (e), b3e83eb (f), 2d76a40 (g), off baseline c886856.
- Security review verbatim output: task scratch dir `/tmp/-home-matt-repo-coding-with-files-task-174/` (review-output.txt, review-output-g.txt).
