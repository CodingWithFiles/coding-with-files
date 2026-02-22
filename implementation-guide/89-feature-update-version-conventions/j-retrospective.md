# Update version conventions - Retrospective
**Task**: 89 (feature)

## Task Reference
- **Task ID**: internal-89
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/89-update-version-conventions
- **Template Version**: 2.1

## Goal
Reflect on task 89 — versioning convention doc and `cwf-manage list-releases` filter.

---

## Variance Analysis

| Dimension | Planned | Actual | Variance |
|-----------|---------|--------|----------|
| Effort | 0.5 days | ~2 hours | Under — as expected for low-complexity task |
| Complexity | Low | Low | On target |
| Scope | CLAUDE.md + cwf-manage | Same | None |
| Bug found | 0 | 1 (parse_semver v-prefix) | Caught by TC-2 before merge |

---

## What Went Well

- **Tests caught a real bug**: TC-2 (`parse_semver` accepting no-`v`-prefix tags) revealed
  that the plan's `s/^v//` approach silently accepted `1.2.3`. The fix (single-regex
  `/^v(\d+)\.(\d+)\.(\d+)$/`) is both correct and more concise. Test-first planning earned
  its keep.

- **Closure-based `@rules` pattern**: Separating bucket-classification rules from pipeline
  mechanics made `filter_releases` easy to read and verify. The business rules are listed
  explicitly; the map/grep/dedup pipeline is generic and reusable.

- **Pre-sorted input simplifies deduplication**: Designing `filter_releases` to accept tags
  already sorted descending meant first-seen deduplication (`!$seen{key}++`) was sufficient
  — no explicit max comparison needed.

- **Two-task scope merge**: Combining the CLAUDE.md doc and the `list-releases` filter into
  one task was the right call — both changes share the semver context and are too small to
  warrant separate branches.

## What Could Be Improved

- **`do $SCRIPT` lib path not in plan**: The test file needed `use lib '.cwf/lib'` to load
  `CWF::Validate::*` when `do`-ing the script. This is a minor but non-obvious step that
  should be noted in any future pattern for testing Perl scripts via `do`.

- **Plan code had a latent bug**: The `parse_semver` implementation in `d-implementation-plan.md`
  used `s/^v//` + split, which doesn't enforce the `v` prefix. The tests caught it, but the
  plan itself could have been more precise. Future plans for regex-gated parsing should
  use the regex from the start.

---

## Key Learnings

1. **Single-regex parsing over strip+split**: When strict prefix enforcement is required,
   capture directly with `/^v(\d+)\.(\d+)\.(\d+)$/` rather than stripping and re-parsing.
   Less code, more precise.

2. **Testing Perl scripts via `do`**: Add `use lib` for the script's own lib paths before
   calling `do $SCRIPT`. Otherwise `BEGIN`-time `use` statements in the script fail.

3. **Closures over shared outer lexicals**: The `@rules` pattern (closures capturing `$cm`,
   `$cmi`, `$cp` from the outer scope and `$tm`, `$tmi`, `$tp` mutated per iteration) works
   cleanly in Perl. The key is declaring the iteration variables with `my` outside the map,
   not inside it, so the closures in `@rules` see the same scalars.

---

## Recommendations / Future Work

- **Tag `v0.1.89` on main post-merge** (human action): Per the new convention, the patch
  number should be the task number (89). This is the first version tagged under the new
  documented scheme.

- **`list-releases` default view with real remote**: Once a tag exists on the remote, a
  live smoke-test of `cwf-manage list-releases` would confirm the end-to-end flow. No
  code change needed — this is a validation step for the human post-merge.

---

## Status
**Status**: Finished
**Next Action**: Merge to main (human action)
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Task completed in ~2 hours. All 15 test cases pass. One implementation bug found and fixed
by the test suite (parse_semver strict v-prefix enforcement). No scope deferred.

## Lessons Learned
See "Key Learnings" section above.
