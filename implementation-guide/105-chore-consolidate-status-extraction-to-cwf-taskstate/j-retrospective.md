# Consolidate Status Extraction to CWF::TaskState - Retrospective
**Task**: 105 (chore)

## Task Reference
- **Task ID**: internal-105
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/105-consolidate-status-extraction-to-cwf-taskstate
- **Template Version**: 2.1
- **Retrospective Date**: 2026-04-19

## Executive Summary
- **Duration**: 1 session (estimated: 1 day, on track)
- **Scope**: Expanded from original backlog item — generalised MarkdownParser instead of deleting it, added Validate::Consistency migration (4th copy discovered), eliminated `status_to_percent` duplication
- **Outcome**: 4 independent parsing loops consolidated to 1. Net -91 LOC in production code. Bug fixed (hardcoded status list in Validate::Workflow). General-purpose field extraction API created for future use.

## Variance Analysis

### Scope Changes
- **Addition**: Generalise MarkdownParser (original plan was to delete it). User correctly identified that parsing markdown is a superset of status extraction, and 4 independent copies exceeded Rule of Three.
- **Addition**: Migrate Validate::Consistency `_extract_fields` (4th copy discovered during exploration)
- **Addition**: Eliminate `WorkflowFiles::status_to_percent` from StatusAggregator (found by /simplify review — identical to `TaskState::status_percent`)
- **Removal**: `extract_status` convenience wrapper (user pointed out zero callers remain post-migration — no deprecation needed for internal module)

### Quality Metrics
- **Test Coverage**: 12 unit tests in markdownparser.t (7 status + 2 non-status + 2 find_field_line + 1 use_ok), 182 total tests across 19 files
- **Defect Rate**: 0 — all tests passed first time, zero regressions
- **LOC**: -91 production lines (98 insertions, 189 deletions across 10 files)

## What Went Well
- **/simplify review caught three issues before implementation**: redundant `_load_allowed_statuses` cache, `status_to_percent` duplication, and over-decomposed implementation steps (5→3)
- **User review caught two architectural issues**: MarkdownParser should be generalised not deleted (layering concern), and `extract_status` wrapper is unnecessary (zero callers)
- **Mechanical migration pattern** made the 5-caller migration trivial — identical find-and-replace across all files
- **Existing test suite** provided confidence — 182 tests caught no regressions, validating that `status_get` and `extract_status` were behaviourally identical despite different regex patterns

## What Could Be Improved
- **Initial plan was wrong about deleting MarkdownParser** — the backlog item said "Delete CWF::MarkdownParser" but the right answer was generalise it. The exploration that found the 4th copy (Validate::Consistency) was only done because the user challenged the deletion. Without that challenge, we'd have deleted a module and later recreated it.
- **Backlog item scope was too narrow** — it described 3 copies but there were 4. A pre-implementation grep for the parsing pattern (`in_code_block`) would have found all copies upfront.

## Key Learnings

### Technical Insights
- **Count before you consolidate**: `grep -rn 'in_code_block' .cwf/lib/` is a better way to find duplicated parsing loops than listing known callers. The backlog item missed the 4th copy.
- **Layering matters for consolidation tasks**: "consolidate to module X" isn't always right — if X is at the wrong abstraction level (TaskState is domain-specific, MarkdownParser is general-purpose), the consolidation creates coupling. The right question is "where does this logic belong in the dependency graph?"

### Process Learnings
- **/simplify on plans** is high-value — caught 3 issues that would have produced unnecessary code. "Simplifying the plan simplifies the code" is a concrete principle.
- **User challenges during planning** prevented architectural mistakes that would have required rework.

## Recommendations

### Future Work
- **`WorkflowFiles::status_to_percent`** is now dead code in StatusAggregator callers (they use `TaskState::status_percent`), but the function still exists in WorkflowFiles.pm. It may have other callers — audit and remove if unused.
- **`ContextInheritance::Core::extract_headers` and `calculate_boundaries`** are a related parsing concern (markdown structure, not field extraction). Could potentially move to MarkdownParser if more callers emerge, but only 1 implementation exists today — no consolidation needed yet.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-04-19

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**
