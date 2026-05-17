# retire bootstraps missing CHANGELOG task entry - Retrospective
**Task**: 147 (feature)

## Task Reference
- **Task ID**: internal-147
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/147-retire-bootstraps-missing-changelog-task-entry
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-17

## Executive Summary
- **Duration**: ~1 session (~half-day), matches a-task-plan original estimate.
- **Scope**: delivered as planned. One scope addition: AC14 in `t/backlog-manager.t` needed to be rewritten to match the new contract (was asserting the legacy "no CHANGELOG entry → die" path that this task explicitly replaces).
- **Outcome**: `backlog-manager retire` now bootstraps a `## Task N: <title>` entry deterministically from the on-disk task directory when CHANGELOG has no matching entry, instead of forcing the user to hand-craft one or defer to retrospective. 87 backlog subtests pass; live `backlog-manager validate` clean.

## Variance Analysis

### Time / Effort
| Phase | Estimated | Actual | Notes |
|---|---|---|---|
| a-plan | trivial | trivial | — |
| b-requirements | small | small | Plan reviewers caught CHANGELOG-002 validator blocker on the bare stub (forced placeholder-metadata approach). Worth the iteration. |
| c-design | small | small | D1 (scope of the helper consolidation) and D4 (insertion position) took the most thinking; both simplified under review. |
| d-implementation-plan | small | small | Plan reviewers caught reuse opportunities (`WorkflowFiles::load_config`, `find_git_root`) and forced dropping a private `_parse_tree` call. |
| e-testing-plan | small | small | — |
| f-implementation-exec | small | small | One unplanned step: rewriting AC14 in the existing test suite. Caught at the first post-implementation test run. |
| g-testing-exec | trivial | trivial | All tests pass; tabular summary in g-testing-exec.md. |
| h-rollout, i-maintenance | trivial | trivial | Internal CLI; most template sections N/A. |

**Total variance**: within the half-day estimate. The plan-review subagents added clear value at every plan phase — every save flagged in the f-impl-exec deviations section traced back to a specific review-finding response, not to an exec-time discovery.

### Scope Changes
- **Addition (small)**: AC14 in `t/backlog-manager.t` rewritten. Not in the implementation plan because the plan phase didn't grep existing tests for the legacy contract message. Discovered at first test run; ~10 minutes to update.
- **Subsumption (small)**: TC-AC2, TC-AC8c, TC-AC9, TC-LT1, TC-LT2 from e-testing-plan recorded as "subsumed/redundant" rather than implemented as standalone test subtests, with rationale in f-implementation-exec.md. Same coverage, fewer moving parts.
- **No removals from b-requirements**.

### Quality Metrics
- **Test coverage**: 11 new subtests in `t/backlog-bootstrap-changelog.t` + 3 in `t/backlog-tree-mutators.t` + 1 updated AC14 = covers all 9 b-requirements ACs (either directly or by documented subsumption).
- **Defects found post-implementation**: 0.
- **Pre-existing failures surfaced (not introduced)**: 1 (UTF-8 round-trip on live BACKLOG.md, unrelated).
- **Security-review findings**: 0 (subagent invoked manually after size-cap skip; verbatim no-findings recorded in f-impl-exec).

## What Went Well
- **Plan-review subagents earned their cost**. Across requirements + design + implementation, 12 subagent invocations produced ~6 substantive saves (validator-blocking placeholder issue; `load_config`/`find_git_root` reuse; dropping private-parser call; simplifying D4 insertion; tmp-paths namespacing; multi-match corner-case handling). Each save would have been a re-do at exec time.
- **Direct hashref construction over parser-roundtrip**. c-design originally proposed parsing a 7-line stub string via `parse_changelog_tree` to extract entry[0]. Misalignment reviewer flagged this as a private-API call; the rewrite built the hashref directly. Result: simpler code, no parser-error-array gap, and TC-U3 round-trips it back through the parser anyway as the safety net.
- **Refusing to add a `--title` flag for the legacy task-1 multi-match case** kept FR8 (no new flags) intact. The error message names the manual workaround; the corner case is one occurrence in the entire corpus.
- **Pre-existing failure surfaced rather than worked around**. The roundtrip-live UTF-8 mangling exists on `main` HEAD; flagging it as a separate task (instead of either fixing it inline or silently ignoring) keeps Task 147's diff bounded and gives the unrelated issue its own visibility.
- **Manual security-review-subagent invocation after size-cap skip** (at user's request) produced a clean independent confirmation of the maintainer's manual sweep.

## What Could Be Improved
- **AC14 should have been caught at plan time**, not at first test run. Adding "grep existing test files for messages that mention the contract being changed" to the implementation-plan checklist (or to the plan-review prompts) would have flagged it during d-impl-plan review.
- **`@_SUPPORTED_TYPES` cache scope** is documented but not enforced. A long-running consumer that loads CWF::Backlog across multiple project roots would see stale types. Not exploitable today (one-shot CLI), but the pattern is one assertion away from breaking on reuse — worth either a comment-only watch item or a cache-clear hook in a future refactor.
- **The 500-line security-review cap fires on test-heavy changes**. The production diff was ~120 lines; the test file added 334 alone. Twice in this session the cap forced the skip-then-manual-review fallback. A "test-file deweighting" rule (e.g. count only production lines toward the cap, or count test files at half weight) would make the cap meaningful for test-rich changes. Worth a BACKLOG entry against the helper.
- **SHA-hash drift on `.cwf/security/script-hashes.json`** is reported as a non-fatal violation every commit. This is correct per [[feedback_surface_security_dont_smooth]] — the friction is the feature — but the per-commit noise is high for a development branch that touches `.cwf/` files. Worth thinking about whether the validator should distinguish "expected drift on a feature branch" from "unexpected drift on main".

## Key Learnings
### Technical
- **Parser-shape coupling is real and testable**. `bootstrap_changelog_entry` hard-codes the entry hashref shape; TC-U3 (parse → serialise → re-parse → deep-compare) closes the loop. If `_parse_tree` ever grows a new key, TC-U3 will fail before the change ships.
- **Anchoring regexes against external config lists** (here: `supported-task-types` from cwf-project.json) is a small surface-shrink win. The strict filter (`qr/\A[a-z][a-z0-9-]{0,31}\z/`) defends against future config drift; the quotemeta-and-alternation pattern is reusable for other regex-from-config cases.

### Process
- **Plan-review subagents are not optional**. Every one of the substantive saves on this task traces to a specific review finding the human-authored plan missed. The cost (3-4 minutes per phase) is dwarfed by the cost of re-doing exec work.
- **Documenting test-plan deviations beats silently dropping cases**. The "subsumed/N/A" entries in g-testing-exec map every e-testing-plan AC to either a test or an explicit rationale — keeps coverage auditable without padding the suite with redundant subtests.

### Risk Mitigation
- **Surfacing the pre-existing roundtrip failure early** kept it out of the task's blocker list. Confirming "reproduces on `main` HEAD" took two commands; doing it before starting the implementation prevented an unrelated bug from being attributed to this task.

## Recommendations / Future Work
1. **Unify implementation-guide/N-*-*/ scan helpers** across `CWF::Backlog` and `CWF::TaskContextInference` into a `CWF::TaskDir` module. Already added to BACKLOG as a Low chore in this task.
2. **Investigate UTF-8 round-trip failure** in `t/backlog-roundtrip-live.t::TC-ROUNDTRIP-LIVE-BACKLOG`. Pre-existing on main HEAD; reproducible; worth its own task. Adding to BACKLOG as a Medium bugfix.
3. **Tune the 500-line security-review cap** so test files don't dominate. Options: count only paths matching a "production" pathspec, or apply a 0.5× weight to test files. Adding to BACKLOG as a Low chore.
4. **Add a "grep existing tests for contract messages being changed" item** to the implementation-plan checklist (or plan-review prompt set). Catches AC14-style breakage at plan time, not test-run time. Adding to BACKLOG as a Low chore.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-17

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- a-task-plan through i-maintenance under `implementation-guide/147-feature-retire-bootstraps-missing-changelog-task-entry/`.
- Checkpoint commits 371deb7 → ab2f58d on `feature/147-retire-bootstraps-missing-changelog-task-entry`.
- Tests: `t/backlog-bootstrap-changelog.t` (new), `t/backlog-tree-mutators.t` (TC-U1/U2/U3 added), `t/backlog-manager.t` (AC14 updated).
- Production: `.cwf/lib/CWF/Backlog.pm` (bootstrap helpers), `.cwf/scripts/command-helpers/backlog-manager` (cmd_retire branch).
