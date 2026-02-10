# dead-code-removal - Design
**Task**: 51 (bugfix)

## Task Reference
- **Task ID**: internal-51
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/51-dead-code-removal
- **Template Version**: 2.1

## Goal
Remove 4 confirmed dead functions (~160 lines) from 3 Perl library modules using surgical deletion with verification.

## Design Priorities
Testability → Simplicity → Reversibility → Readability

## Removal Strategy
**Approach**: Surgical deletion with comprehensive verification

### Key Decision: Atomic Commits Per File
- **Decision**: Remove dead code from each file in separate commits (3 commits total)
- **Rationale**: Enables easy rollback if issues discovered in specific file
- **Trade-offs**: More commits vs. easier bisect/revert if problems arise

### Verification Strategy
- **Pre-removal**: Grep search confirms functions unused (already done in audit)
- **Post-removal**: Run full test suite to verify no hidden dependencies
- **Security**: Update SHA256 hashes in script-hashes.json after each file

## Removal Plan

### File 1: TaskContextInference.pm (4 functions, ~150 lines)

**Functions to Remove:**
1. `_get_status_signal()` (lines 431-475, ~45 lines)
   - Status signal deliberately removed per Task 32
   - Comment at lines 142-143 explains removal
   - Never called in current codebase

2. `_score_status()` (~15 lines)
   - Helper for _get_status_signal()
   - Only called by dead function above

3. `_get_task_status_score()` (~20 lines)
   - Helper for _get_status_signal()
   - Only called by dead function above

4. `_format_uncorrelated()` (lines 672-694, ~23 lines)
   - Marked "DEPRECATED" at line 675
   - Replaced by unified format_output()
   - No longer in call path

### File 2: CIG::WorkflowFiles.pm (1 function, ~5 lines)

**Function to Remove:**
- `workflow_file_mappings()` (lines 53-55)
  - Returns `\@WORKFLOW_MAPPINGS`
  - Duplicates V20.pm::get_workflow_files()
  - Exported but never called

### File 3: CIG::Common.pm (1 function, ~5 lines)

**Function to Remove:**
- `format_error()` (lines 29-34)
  - Exported but never called
  - Simple utility that was never adopted

## Verification Steps

### Pre-Removal Verification (Already Complete)
- ✅ Codebase grep search confirmed zero usage
- ✅ No imports/use statements reference these functions
- ✅ No POD documentation promises these as public API

### Post-Removal Verification
1. **Grep Search**: Verify function names don't appear in:
   - Documentation (*.md files)
   - Comments (remaining code)
   - POD (remaining modules)

2. **Security Hashes**: Update `.cig/security/script-hashes.json` with new SHA256:
   - TaskContextInference.pm
   - CIG/WorkflowFiles.pm
   - CIG/Common.pm

3. **Test Suite**: Run any available tests (if CIG has test suite)

## Change Impact Assessment

**Files Modified**: 3 library modules
**Lines Removed**: ~160 lines
**API Impact**: None (all functions are internal or exported-but-unused)
**Dependency Impact**: Zero (dead code has no dependencies)
**Risk Level**: Very Low (atomic changes, easy rollback)

## Constraints
- **Must preserve module structure**: Only remove function definitions, keep module metadata (package, use, exports)
- **Must maintain @EXPORT lists**: Remove dead functions from @EXPORT/@EXPORT_OK if present
- **Must update security hashes**: SHA256 hashes required for all modified library files
- **No test suite exists**: Cannot rely on automated tests, must verify manually via grep

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? **NO** - estimated 1-2 hours
- [x] **People**: Does this need >2 people working on different parts? **NO** - single developer
- [x] **Complexity**: Does this involve 3+ distinct concerns? **NO** - single concern (delete code)
- [x] **Risk**: Are there high-risk components that need isolation? **NO** - very low risk
- [x] **Independence**: Can parts be worked on separately? **MAYBE** - could remove per-file, but easier atomically

**Decomposition Decision**: No decomposition needed. Surgical deletion from 3 files is simple and low-risk. Atomic commits per file provide sufficient rollback granularity.

## Validation
- [x] Design review completed (removal strategy defined)
- [x] Line numbers identified for each function
- [x] Verification strategy defined (grep + security hashes)
- [x] Rollback strategy defined (per-file commits)

## Status
**Status**: Finished
**Next Action**: /cig-implementation-plan 51
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
