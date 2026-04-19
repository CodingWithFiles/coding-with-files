# Build Stale Status Detector Stop Hook - Retrospective
**Task**: 104 (feature)

## Task Reference
- **Task ID**: internal-104
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/104-build-stale-status-detector-stop-hook
- **Template Version**: 2.1
- **Retrospective Date**: 2026-04-19

## Executive Summary
- **Estimated**: 1 session, Low complexity
- **Actual**: 1 session, 42-line Perl script, 7/7 tests pass
- **Outcome**: Stop hook deployed. Two additional backlog items created from findings during implementation.

## Variance Analysis

### Scope Changes
- **Changed**: Bash → Perl. Plan originally specified a ~30-line bash script with `grep` for status extraction. `/simplify` review identified this would be a 4th independent status extraction implementation. User directed rewrite in Perl using `CWF::TaskState::status_get()`. Net effect: same line count, but uses the canonical module.
- **Added**: Backlog items — "Consolidate Status Extraction to Single Canonical Module" (Very High) and "Progress Signal Scores Completed Tasks Highest" (Medium) discovered during task execution.

### Quality Metrics
- **Tests**: 7/7 pass (6 functional + 1 validate)
- **Defects**: 0
- **Script size**: 42 lines

## What Went Well
- `/simplify` review caught the `set -euo pipefail` vs exit-0 contradiction before implementation — would have caused the hook to error on every clean stop (the common case)
- User's insistence on using `CWF::TaskState::status_get()` avoided creating technical debt and led to discovery of the 3-way status extraction duplication (now a Very High backlog item)
- The Task 103 framework document (`stop-hooks-framework.md`) provided a clear, grounded spec — Candidate A's scope, token budget, and detection strategy were all pre-defined

## What Could Be Improved
- The original design chose bash "because hooks run shell commands" without checking whether existing Perl modules could be leveraged. Should have checked for existing status extraction utilities during design phase, not after implementation.
- Planning docs were over-specified for a small task — `/simplify` found the same information repeated 3-4 times across a/b/c/d files. For low-complexity tasks, lighter planning documentation would be more appropriate.

## Key Learnings
- **Reuse existing modules before writing new extraction logic.** The CWF codebase already had `status_get()` — reaching for `grep` was the path of least resistance but created duplication.
- **`set -e` is dangerous in hook scripts.** Hooks must always exit 0. `set -e` kills the script on `grep` no-match (exit 1), which is the common clean-stop case. Use `set -u` only and handle errors explicitly.
- **Stop hooks fire on every stop, not just task completion.** The common path (no stale files) must be zero-cost. Using git pathspec filtering (`-- 'pattern'`) instead of a separate grep avoids an unnecessary fork.

## Recommendations

### Future Work
- **Consolidate status extraction** (Very High backlog) — migrate StatusAggregator and ContextInheritance from `MarkdownParser::extract_status()` to `TaskState::status_get()`, delete MarkdownParser, fix Validate::Workflow's hardcoded status list
- **Fix progress signal scoring** (Medium backlog) — `_score_progress()` in TaskContextInference.pm scores 100% tasks highest; should filter them out or use bell curve
- **Build Candidate B** (Uncommitted Changes Warning Stop Hook) — next hook from Task 103 framework, Medium priority

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge
**Blockers**: None identified
**Completion Date**: 2026-04-19

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**
