# Consolidate Status Extraction to CWF::TaskState - Plan
**Task**: 105 (chore)

## Task Reference
- **Task ID**: internal-105
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/105-consolidate-status-extraction-to-cwf-taskstate
- **Template Version**: 2.1

## Goal
Consolidate 4 independent implementations of section-scoped, code-block-aware markdown field extraction into a single general-purpose function in `CWF::MarkdownParser`, then layer `TaskState` on top for status-specific operations, and fix the hardcoded status list bug in `Validate::Workflow`.

## Success Criteria
- [ ] `CWF::MarkdownParser` generalised with `extract_field($file, $section_re, $key_re)` and `find_field_line()` (for read+write)
- [ ] `extract_status()` deleted — no callers remain after migration to `TaskState::status_get()`
- [ ] `TaskState::_find_status_line` delegates to `MarkdownParser::find_field_line()` — zero duplicated parsing logic
- [ ] All status-specific callers use `TaskState` (proper layering: MarkdownParser → TaskState → callers)
- [ ] `Validate::Consistency::_extract_fields` uses `MarkdownParser::extract_field()` — eliminates 4th copy
- [ ] `Validate::Workflow` uses `TaskState::status_is_valid()` instead of hardcoded `%ALLOWED_STATUS_SET`
- [ ] `cwf-manage validate` passes after all changes

## Original Estimate
**Effort**: 1 day
**Complexity**: Medium (many callers, but each change is mechanical)
**Dependencies**: None

## Major Milestones
1. **Generalise MarkdownParser**: Add `extract_field()` and `find_field_line()`, rewrite `extract_status` as wrapper
2. **Refactor TaskState**: Replace `_find_status_line` with `MarkdownParser::find_field_line()`, add `status_is_valid()`
3. **Migrate callers**: Status callers → TaskState, field callers → MarkdownParser, fix Validate modules

## Risk Assessment
### Medium Priority Risks
- **Subtle behavioural difference between existing parsers**: `extract_status` uses `(.+)$` then trims, `_find_status_line` uses `(.+?)\s*$`. The new `extract_field` must match existing behaviour.
  - **Mitigation**: Existing `t/markdownparser.t` tests provide behavioural specification; run them against the generalised implementation to verify identical results.

## Dependencies
- None — all modules are internal to CWF

## Constraints
- Must not change any public interface behaviour (return values, exit codes)

## Decomposition Check
- [x] **Time**: No — estimated 1 day
- [x] **People**: No — single person
- [x] **Complexity**: No — 2 distinct concerns (caller migration + validation fix) but tightly coupled
- [x] **Risk**: No — all changes are internal, tests provide safety net
- [x] **Independence**: No — changes are sequential and interdependent

**Result**: 0 signals triggered. No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
