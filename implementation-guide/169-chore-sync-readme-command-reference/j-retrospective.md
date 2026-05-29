# Sync README command reference - Retrospective
**Task**: 169 (chore)

## Task Reference
- **Task ID**: internal-169
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/169-sync-readme-command-reference
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-29

## Executive Summary
- **Duration**: <1 day (estimated: <1 day, variance: ~0%)
- **Scope**: README command/skill reference synced to the shipped surface. Final scope
  matched plan plus one in-scope addition (stale Contributing example).
- **Outcome**: Success. All five test cases pass; README now documents exactly the
  shipped command set with correct signatures and task types.

## Variance Analysis
### Scope Changes
- **Additions**: Fixed a third stale signature instance (README:245
  `/cwf-new-task feature` → valid form), surfaced by TC-4. Same defect class as the
  planned signature fix, so folded in rather than deferred.
- **Removals**: None. Non-command prose drift (architecture/install/config) was
  explicitly held out of scope; none requiring action was found.
- **Impact**: Negligible — one extra one-line edit.

### Quality Metrics
- **Test Coverage**: 5/5 functional TCs + all non-functional checks PASS.
- **Defect Rate**: 0 defects introduced; `cwf-manage validate` clean throughout.

## What Went Well
- The plan-review subagents earned their keep: they caught a validation-oracle bug
  (Step 5 originally diffed task types against template dirs, which would have falsely
  flagged the non-type `install/` dir) and the parallel `cwf-new-subtask` signature
  staleness — both fixed before execution rather than after.
- Diff-based verification (documented set vs authoritative source) gave unambiguous
  pass/fail with no manual judgement.
- Task 166's subtask-aware inference resolved task 169 cleanly at every phase
  (`conclusive / correlated`), live-confirming that fix on a real fresh task.

## What Could Be Improved
- README drift went unnoticed for 62 tasks (last touched Task 106). There is no
  mechanical gate tying the documented skill list to the shipped `.claude/skills/` set,
  so this class of drift recurs silently. Candidate for a follow-up linter.

## Key Learnings
### Process Learnings
- A validation step is only as good as its oracle. The reviewer-caught template-dir
  oracle would have "passed" while pointing at the wrong source of truth. Authoritative
  source for task types is `cwf-project.json:supported-task-types` /
  `V21::supported_types()`, never the template directory listing (which includes the
  non-type `install/`).

## Recommendations
### Future Work
- Consider a lightweight check (linter or test) asserting README's documented `/cwf-*`
  set equals the shipped `.claude/skills/cwf-*` set, to prevent silent re-drift. Logged
  to BACKLOG as a candidate; not built here (out of scope, and value vs maintenance of a
  new gate needs its own judgement).

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge
**Blockers**: None identified
**Completion Date**: 2026-05-29
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Plan/exec/test docs: this task directory (a, d, e, f, g).
- Implementation: single-file change to `README.md` (Commands + Task Types sections).
