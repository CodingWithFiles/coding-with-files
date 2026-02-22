# Fix stale CIG references in wf step templates and template-copier - Retrospective
**Task**: 90 (hotfix)

## Task Reference
- **Task ID**: internal-90
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/90-fix-stale-cig-references-in-wf-step-templates-and-t
- **Template Version**: 2.1

## Goal
Reflect on task 90 — fixing stale `.cig/` and `/cig-` references missed by the Task 59 rebrand.

---

## Variance Analysis

| Dimension | Planned | Actual | Variance |
|-----------|---------|--------|----------|
| Effort | <0.25 days | ~20 minutes | Well under |
| Complexity | Trivial | Trivial | On target |
| Files changed | 10 templates + 1 script + hash | Same | None |
| Bugs found during fix | 0 | 0 | — |

---

## What Went Well

- **Discovered opportunistically**: The bug was found during Task 89 retrospective analysis
  ("when did we last update the templates?") — not by a dedicated audit. The pattern of
  checking template provenance after a task completion is valuable.

- **Trivial execution**: Both fixes were pure string replacements at known locations.
  Reading all 10 templates and both script lines in parallel made it fast.

- **Broad sweep confirmed completeness**: TC-5 (`grep -r "\.cig/\|/cig-" .cwf/`) gave
  high confidence that nothing else was missed, beyond the two known fix sites.

## What Could Be Improved

- **Task 59 should have had a template test**: The rebrand task had no test case verifying
  that generated files contain correct skill names. A single `grep "/cwf-" <generated-file>`
  check would have caught both bugs immediately.

- **Template changes need a smoke-test step**: Any task touching `template-copier` or the
  template pool should generate a sample task and grep the output for correctness. Currently
  there's no such guard.

---

## Key Learnings

1. **Rebrand tasks need an output-level test**: Renaming a prefix in source files doesn't
   guarantee the output (generated files) is also correct. A generation smoke-test
   (`task-workflow create` → grep output) should be a standard step in any rebrand.

2. **Template copier's `name_to_action` is a latent risk point**: It constructs skill
   names by string concatenation. If the skill prefix ever changes again, this is the
   one place to update — worth noting in the function comment.

---

## Recommendations / Future Work

- **Add a template smoke-test to `cwf-manage validate`** (or a dedicated test): Generate
  a throwaway task in a temp dir and verify the Status footer and Next Action skill names
  contain no stale strings. This would have caught both Task 90 bugs automatically.

---

## Status
**Status**: Finished
**Next Action**: Merge to main (human action)
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Completed in ~20 minutes. 12 files changed (10 templates + script + hash). All 7 TCs
passed. No deviations from plan. No regressions.

## Lessons Learned
See "Key Learnings" section above.
