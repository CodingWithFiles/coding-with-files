# Improve scripts to avoid false positives - Requirements

## Task Reference
- **Task ID**: internal-8
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/8-improve-scripts-to-avoid-false-positives
- **Template Version**: 2.0

## Goal
Fix false positives in status extraction and eliminate code duplication between helper scripts.

## Functional Requirements

### Fix False Positives
- **FR1**: Status extraction must only match `**Status**:` within the `## Status` or `## Current Status` section
- **FR2**: Status patterns inside triple-backtick code blocks must be ignored
- **FR3**: Status patterns in other sections (e.g., `### Phase 1:`, `## Maintenance Status`) must be ignored

### Eliminate Duplication (DRY)
- **FR4**: Shared operations (status extraction, path resolution, workflow file handling) must exist in one place
- **FR5**: Scripts with duplicated logic must use the shared implementation

### Backward Compatibility
- **FR6**: Support both v1.0 (`## Current Status`) and v2.0 (`## Status`) formats
- **FR7**: Maintain exact CLI interfaces and output formats

## Non-Functional Requirements

- **NFR1**: No performance degradation (single-pass parsing)
- **NFR2**: No external dependencies (core Perl only)
- **NFR3**: Graceful error handling (warnings to stderr, meaningful exit codes)

## Constraints
- Must update script hashes in security manifest after changes

## Acceptance Criteria
- [ ] AC1: Status extracted from correct section only (false positives eliminated)
- [ ] AC2: Task 7 reports correct status (was 25%, should be 100%)
- [ ] AC3: No duplicated logic between scripts
- [ ] AC4: All existing tasks report same or corrected status values
- [ ] AC5: v1.0 and v2.0 formats both work

## Status
**Status**: Finished
**Next Action**: Proceed to implementation
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
