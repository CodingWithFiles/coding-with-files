# subtask retrospective must not version-bump or tag - Retrospective
**Task**: 163 (bugfix)

## Task Reference
- **Task ID**: internal-163
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/163-subtask-retrospective-must-not-version-bump-or-tag
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-24

## Executive Summary
- **Duration**: single session (estimate <1 day, Low complexity). On estimate.
- **Scope**: As planned, plus one design-driven widening — the fix landed in all **three** version helpers (bump/tag/next) via a shared predicate, not the two originally scoped. No descopes.
- **Outcome**: Success. A subtask retrospective now skips version-bump and version-tag with a clean `exit 0` + `skipped:` line instead of the misleading `unknown argument: --task-num=3.2` error reported by the downstream user.

## Variance Analysis
### Scope Changes
- **Addition (design phase)**: `cwf-version-next` brought into scope. The a/c plans first asserted two runtime consumers; plan review found a third helper carrying the identical `^--task-num=(\d+)$` parser. Fixing two and leaving the third emitting the old error would have created intra-triplet inconsistency.
- **Addition (design phase)**: a shared exported predicate `is_subtask_num` in `CWF::Versioning`, rather than three inline regex checks. Rule of Three was met once the third call site surfaced; `feedback_design_tradeoff_priority` (reuse over duplication) applied.
- **Removal**: none.
- **Impact**: marginal — one extra symbol, one extra import per helper, one extra unit truth-table. Centralisation gives a single place to change if the version scheme ever admits a sub-patch.

### Quality Metrics
- **Test coverage**: 45 targeted tests pass (`versioning.t` + the three helper `.t` files). Predicate covered by a 9-row truth table (TC-V7c) independent of the CLI capture regex; skip / short-circuit-before-`read_config` / malformed-error paths covered per helper; integer path unchanged.
- **Full suite**: 585 tests, 583 pass. The 2 failures (`cwf-manage-fix-security.t` TC-1/TC-8) are **pre-existing and unrelated** — a working-tree perms drift on `.claude/agents/cwf-security-reviewer-changeset.md` (0600 vs recorded 0444 floor), last committed by Task 162, absent from `git diff main..HEAD`. Fixed locally with `chmod 0444` (validate now clean, suite green); the fix is a no-op in git (mode 100644 either way) and belongs to no Task 163 commit.
- **Defects**: none found in the change under test.

## What Went Well
- **Plan review earned its keep on a "trivial" bugfix.** Three of four reviewers independently caught the "sole consumers" miscount (two → three), correcting scope *before* implementation. The exec phase had zero rework.
- **The fix composes with the existing skill contract.** Because the guard emits a `skipped:` line and SKILL.md Step 9 already keys on that prefix ("nothing further to stage"), no skill logic changed — the deterministic behaviour lives in the scripts (`feedback_bake_in_good_work`), not in agent prose.
- **Security posture narrowed, not widened.** The relaxed capture admits decimal numbers only to *skip* them; the `next_version` `^\d+$` backstop is retained, so a bare integer remains the only value that can reach a mutation or `git tag`. The digits-only invariant feeding `git tag -l '$version'` is preserved.
- **Edge cases were pinned as tests, not assumed.** `3.` / `.2` / `3..2` route to the error path (not the skip) by explicit assertion.

## What Could Be Improved
- **Enumerate call sites by grep, not by memory.** The two-vs-three consumer miscount is the same class of error Task 161's retrospective recorded (under-counted orphaned imports: "grep imports the same way you grep callers"). The design phase should grep for the shared parser pattern across `command-helpers/` before claiming a consumer count. Plan review caught it here, but it should not have reached plan review.
- **The exec-phase security review classified `error` twice.** Both the implementation and testing reviewers produced substantively clean verdicts ("no findings", no injection/traversal/secret/destructive concerns) but **omitted the required fenced `cwf-review` block**, so `security-review-classify` correctly returned `error` (conservative default). This was surfaced honestly in both exec files with verbatim output, not smoothed. It directly bears on the open Task 162 follow-up (live security-reviewer verification in a fresh session) — see Recommendations.

## Key Learnings
### Technical Insights
- **A predicate that classifies shape is not a sanitiser.** `is_subtask_num` answers "is this a dotted number" on already-numeric task ids; its comment documents that input contract so a future caller does not feed it arbitrary user text expecting validation. The security review raised exactly this (category-e reuse risk) and the comment was added in response.
- **Short-circuit before side effects, not after.** The skip exits inside the `@ARGV` parse loop, ahead of `read_config()`. TC-2 proves it: a subtask number skips cleanly even against an absent or malformed `cwf-project.json` that would otherwise `die`.

### Process Learnings
- **The cost of a wrong assumption is paid at review, not at exec — if review runs.** The consumer miscount was free to fix because plan review is mandatory. This is the second consecutive retrospective (161, 163) where an "eyeball the list" enumeration error was the main process miss; worth treating as a standing checklist item for deletion/duplication tasks.

## Recommendations
### Process Improvements
- On tasks that touch a "family" of helpers (the version triplet, the reviewer agents, etc.), grep the shared pattern across the family directory at design time and state the count with evidence.

### Future Work
- **No new backlog item for the security-review `error` observations** — they corroborate the **existing** Task 162 follow-up ("re-run `cwf-security-reviewer-changeset` in a fresh session; confirm it ends with a `cwf-review` block"). Task 163 adds two more data points in the *negative* direction (block still absent within an editing session). That item already carries the right scope; it should be prioritised, and Task 163's f/g security sections referenced as additional evidence.
- The pre-existing `cwf-security-reviewer-changeset.md` perms drift was fixed locally this session; if it recurs on fresh checkouts, a dedicated investigation of why the working-tree mode drifts to 0600 may be warranted (out of scope here).

## Status
**Status**: Finished
**Next Action**: Suggest merge to parent (top-level task → main)
**Blockers**: None
**Completion Date**: 2026-05-24
**Sign-off**: The maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`, `c-design-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`
- Execution: `f-implementation-exec.md`, `g-testing-exec.md` (incl. verbatim security reviews)
- Commits: `1dfb62a`..`7b549fa` on `bugfix/163-...`; full reasoning preserved on the checkpoints branch
