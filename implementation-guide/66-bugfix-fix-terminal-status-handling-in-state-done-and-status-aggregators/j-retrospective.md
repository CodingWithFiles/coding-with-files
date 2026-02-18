# Fix terminal status handling in state_done and status aggregators - Retrospective
**Task**: 66 (bugfix)

## Task Reference
- **Task ID**: internal-66
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/66-fix-terminal-status-handling-in-state-done-and-status-aggregators
- **Template Version**: 2.1
- **Retrospective Date**: 2026-02-18

## Executive Summary
- **Duration**: <1 session (estimated: <1 session — on target)
- **Scope**: `CWF::TaskState.pm`, both aggregators, `cwf-project.json`, `script-hashes.json` — plus design revised once mid-task
- **Outcome**: Full success. Task 11 (all Cancelled) now scores 100%. `_is_terminal` removed and replaced by the cleaner `_is_closed` concept. Blocked tasks now surface in inference at low DORMANT score rather than being hidden.

## Variance Analysis

### Time and Effort
- **Estimated**: Trivial — single-session bugfix
- **Actual**: Trivial — but required two design passes (user correctly identified that `_is_terminal` and `_is_workable` were the same concept, leading to a simpler design)
- **Variance**: Design phase took longer than expected due to the conceptual clarification; implementation and testing were fast

### Scope Changes
- **Additions**:
  - `cwf-project.json` fix (`"Skipped": null` → `100`) — found during TC-1 testing; config overrides `%DEFAULT_STATUS_MAP` so the Perl change alone was insufficient
  - 4 pre-existing perlcritic violations fixed in `TaskState.pm` during implementation
  - `state_achievable` simplified by removing dead code (`$blocked_count`, `$is_workable`, `!$is_workable` branch)
- **Removals**: None
- **Impact**: Scope additions were all improvements; no timeline impact

### Quality Metrics
- **Test Coverage**: 14/14 test cases pass; all new code paths covered
- **Defects**: 1 defect found during testing (TC-1 `cwf-project.json`) — fixed inline
- **Regressions**: None — TC-6/7/10 confirmed no change to active-task scoring

## What Went Well
- User's conceptual questions during design led to a meaningfully simpler solution — `_is_terminal` and `$is_workable` eliminated entirely rather than patched
- The test harness (temp dirs with stub files) was fast to write and covered all branches cleanly
- `cwf-manage validate` caught the hash updates correctly after every code change
- perlcritic violations fixed cleanly — the `RequireBriefOpen` pattern (slurp into `@lines`) is now consistent with the rest of the codebase

## What Could Be Improved
- **`cwf-project.json` was not in scope during planning**: The implementation plan only identified `TaskState.pm` as the source of `status_percent` mappings. The config file overrides the Perl map at runtime — this should have been checked during implementation planning. The testing phase caught it, but an earlier check of `cwf-project.json` would have avoided the TC-1 failure.
- **Design revised twice**: The first design pass kept `_is_terminal` and added `_is_closed` alongside it. User questioning revealed they were redundant. Asking "does this existing concept still serve a purpose?" during design would have caught this sooner.

## Key Learnings

### Technical
- **`cwf-project.json` overrides `%DEFAULT_STATUS_MAP` entirely**: When `workflow.status-values` is present in the config, `status_percent` uses it exclusively. Any new status value must be added to both the Perl default map *and* `cwf-project.json`. Worth checking both when adding new status values.
- **`null` in JSON status map returns `undef` from Perl**: A `null` JSON value becomes Perl `undef`, which silently passes `exists` checks but fails numeric comparisons. `"Skipped": null` was a trap — it looked like a placeholder but actively caused TC-1 to return empty string.
- **Dead code removal via design reasoning**: The `!$is_workable` branch was dead code after the `_is_closed` fix — not because it was never reached, but because the CLIFF check always fires first for all-closed tasks. Reasoning about code paths before writing is more reliable than testing alone.

### Process
- **When a user asks "what's the difference between X and Y?", slow down**: The question revealed that `_is_terminal` and `_is_workable` were the same concept. The right response is to trace the code carefully before defending the distinction.
- **Check config files alongside code files** when a function has a config-driven code path — both must be updated together.

## Recommendations
- **Add `cwf-project.json` to implementation plan checklists** for tasks touching `status_percent` or status values — it's the live override and easy to miss.
- **Add to retrospective extras**: "Before marking Finished, set all preceding workflow files (a through g) to Finished." (Same recommendation as Task 65 — still not in the extras doc.)

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None
**Completion Date**: 2026-02-18

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Files changed: `CWF/TaskState.pm`, `status-aggregator-v2.0`, `status-aggregator-v2.1`, `cwf-project.json`, `script-hashes.json`
- Task 11: now shows 100% (was 0%)
