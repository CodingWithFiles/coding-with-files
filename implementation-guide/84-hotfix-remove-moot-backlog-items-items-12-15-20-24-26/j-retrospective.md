# Remove moot backlog items: items 12, 15, 20, 24, 26 - Retrospective
**Task**: 84 (hotfix)

## Task Reference
- **Task ID**: internal-84
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/84-remove-moot-backlog-items-items-12-15-20-24-26
- **Template Version**: 2.1
- **Retrospective Date**: 2026-02-21

## Executive Summary
- **Duration**: ~1 hour (estimated: 1 hour, variance: 0%)
- **Scope**: Original 5 removals expanded to 8 removals + 1 update following user review
- **Outcome**: Backlog reduced from 41 to 33 active items; all moot items removed with documented rationale

## Variance Analysis

### Time and Effort
Minimal — documentation-only task completed in a single session.

### Scope Changes
- **Additions**: User reviewed list during session and identified 3 further moot items ("Automated Test Harness", "Security Review Bash Invocations", "Standardize Script Naming"); also corrected scope of 1 item ("Remove Decomposition Checks")
- **Impact**: Positive — more thorough cleanup than originally planned

### Quality Metrics
- 6/6 structural test cases passed
- `cwf-manage validate` clean throughout

## What Went Well
- Codebase investigation before each removal confirmed the rationale — no guesswork
- User review session caught 3 additional moot items the original plan missed
- HTML comment format with rationale makes removals fully traceable and reversible
- Decomposition scope correction was a genuine improvement, not just a removal

## What Could Be Improved
- **Workflow skills not called initially**: Implementation happened before the CWF workflow phases were run. The plan document identified the skill to call but the workflow files weren't filled in at each step — they were backfilled retrospectively. This is the core process gap this task exposed.
- **`Implemented` is not a valid status**: Used in f-implementation-exec.md — caught by `cwf-manage validate` in the retrospective phase. Valid value is `Finished`.
- **h-rollout.md referenced `git branch -f main <sha>` as a "project convention"**: It is not. The correct approach is `git checkout main && git merge --ff-only <task-branch>`, which is what was actually done.

## Key Learnings

### Process Learnings
- **The plan must explicitly invoke skills, not just name them**: Writing "/cwf-new-task 84" in a plan doc doesn't run the skill. Plans should say "invoke `/cwf-new-task`" but the actual skill invocation must happen at execution time via the Skill tool — and so must every subsequent workflow step skill.
- **Backlog audits are high-value, low-cost**: 8 items removed in ~1 hour. Architecture evolves faster than the backlog is cleaned. Periodic audits (every ~20 tasks) prevent backlog rot.
- **Status values must come from the allowed set**: `Implemented` is not valid; `Finished` is. The validator catches this but only at validate-time, not at write-time.

### Risk Mitigation
- Storing removal rationale in HTML comments means any disputed removal can be re-evaluated from git history without guesswork.

## Recommendations

### Process Improvements
- **Add to plan template / planning guidance**: Plans that create CWF tasks must explicitly note that each workflow step skill must be invoked in sequence during execution — not just listed as prose.
- **Periodic backlog audit**: Add a recurring backlog audit task every ~20 tasks or whenever a major architectural refactor completes.

### Future Work
None identified.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None
**Completion Date**: 2026-02-21

## Archived Materials
- Branch: `hotfix/84-remove-moot-backlog-items-items-12-15-20-24-26`
- Checkpoints branch: `hotfix/84-remove-moot-backlog-items-items-12-15-20-24-26-checkpoints`
