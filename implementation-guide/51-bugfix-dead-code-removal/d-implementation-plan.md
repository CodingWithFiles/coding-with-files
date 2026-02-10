# dead-code-removal - Implementation Plan
**Task**: 51 (bugfix)

## Task Reference
- **Task ID**: internal-51
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/51-dead-code-removal
- **Template Version**: 2.1

## Goal
Remove 4 confirmed dead functions (~160 lines) from 3 Perl library modules using surgical deletion with per-file atomic commits.

## Workflow
Verify unused → Remove code → Update hashes → Commit → Verify no regressions

## Files to Modify
### Primary Changes
- `.cig/lib/TaskContextInference.pm` - Remove 4 dead functions (~150 lines)
- `.cig/lib/CIG/WorkflowFiles.pm` - Remove 1 dead function (~5 lines)
- `.cig/lib/CIG/Common.pm` - Remove 1 dead function (~5 lines)

### Supporting Changes
- `.cig/security/script-hashes.json` - Update SHA256 hashes for all 3 modified files

## Implementation Steps

### Step 1: Pre-Removal Verification
- [ ] Grep search confirms functions unused (should already be done from audit)
  ```bash
  grep -r "_get_status_signal\|_score_status\|_get_task_status_score\|_format_uncorrelated" .cig/ .claude/
  grep -r "workflow_file_mappings" .cig/ .claude/
  grep -r "format_error" .cig/ .claude/
  ```
- [ ] Verify no POD documentation promises these as public API
- [ ] Review function definitions to identify exact line ranges

### Step 2: Remove Dead Code from TaskContextInference.pm
- [ ] Locate and remove `_get_status_signal()` function (lines ~431-475)
- [ ] Locate and remove `_score_status()` function
- [ ] Locate and remove `_get_task_status_score()` function
- [ ] Locate and remove `_format_uncorrelated()` function (lines ~672-694)
- [ ] Remove any associated comments referencing these functions
- [ ] Calculate new SHA256 hash: `sha256sum .cig/lib/TaskContextInference.pm`
- [ ] Update `.cig/security/script-hashes.json` with new hash
- [ ] Commit changes: "Remove 4 dead functions from TaskContextInference.pm"

### Step 3: Remove Dead Code from CIG::WorkflowFiles.pm
- [ ] Locate and remove `workflow_file_mappings()` function (lines ~53-55)
- [ ] Remove from @EXPORT or @EXPORT_OK if present
- [ ] Calculate new SHA256 hash: `sha256sum .cig/lib/CIG/WorkflowFiles.pm`
- [ ] Update `.cig/security/script-hashes.json` with new hash
- [ ] Commit changes: "Remove dead workflow_file_mappings() from WorkflowFiles.pm"

### Step 4: Remove Dead Code from CIG::Common.pm
- [ ] Locate and remove `format_error()` function (lines ~29-34)
- [ ] Remove from @EXPORT or @EXPORT_OK if present
- [ ] Calculate new SHA256 hash: `sha256sum .cig/lib/CIG/Common.pm`
- [ ] Update `.cig/security/script-hashes.json` with new hash
- [ ] Commit changes: "Remove dead format_error() from Common.pm"

### Step 5: Post-Removal Verification
- [ ] Grep search confirms no references to removed functions:
  ```bash
  grep -r "_get_status_signal\|_score_status\|_get_task_status_score\|_format_uncorrelated" .cig/ .claude/
  grep -r "workflow_file_mappings" .cig/ .claude/
  grep -r "format_error" .cig/ .claude/
  ```
- [ ] Security hash verification: `/cig-security-check verify`
- [ ] Manual smoke test: Run status aggregator on sample task
- [ ] Check git diff to confirm only intended code removed

### Step 6: Documentation Updates
- [ ] Update CHANGELOG.md with removal summary
- [ ] Note: No user-facing documentation affected (internal library cleanup)

## Code Changes

### Example: TaskContextInference.pm

**Before** (lines ~431-475):
```perl
sub _get_status_signal {
    my ($task_num, $task_dir) = @_;
    # ... ~45 lines of dead code ...
    return { ... };
}

sub _score_status {
    # ... ~15 lines of dead code ...
}

sub _get_task_status_score {
    # ... ~20 lines of dead code ...
}

sub _format_uncorrelated {  # DEPRECATED at line 675
    # ... ~23 lines of dead code ...
}
```

**After**:
```perl
# Functions removed - no replacement needed (dead code)
```

### Example: CIG::WorkflowFiles.pm

**Before** (lines ~53-55):
```perl
sub workflow_file_mappings {
    return \@WORKFLOW_MAPPINGS;
}
```

**After**:
```perl
# Function removed - use CIG::WorkflowFiles::V20::get_workflow_files() instead
```

### Example: CIG::Common.pm

**Before** (lines ~29-34):
```perl
sub format_error {
    my ($message) = @_;
    return "Error: $message\n";
}
```

**After**:
```perl
# Function removed - never used in codebase
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

**Note**: No unit tests exist for removed functions (they were dead code). Validation relies on:
- Grep search confirming no references
- Security hash verification
- Manual smoke testing

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

**Quick Validation Checklist**:
- [ ] All 4 functions removed (~160 lines)
- [ ] No grep hits for removed function names
- [ ] Security hashes updated and verified
- [ ] Status aggregator runs without errors
- [ ] 3 atomic commits created (one per file)

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cig-testing-plan 51
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
