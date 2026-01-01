# Improve scripts to avoid false positives - Implementation

## Task Reference
- **Task ID**: internal-8
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/8-improve-scripts-to-avoid-false-positives
- **Template Version**: 2.0

## Goal
Implement shared Perl library and migrate scripts to fix false positives and eliminate duplication.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### New Files (Create)
- `.cig/lib/CIG/MarkdownParser.pm` - Status extraction with structure awareness
- `.cig/lib/CIG/TaskPath.pm` - Path normalisation, validation, resolution
- `.cig/lib/CIG/WorkflowFiles.pm` - File lists, version detection, status mapping
- `.cig/scripts/command-helpers/status-aggregator.pl` - Rewrite using lib
- `.cig/scripts/command-helpers/hierarchy-resolver.pl` - Rewrite using lib
- `.cig/scripts/command-helpers/format-detector.pl` - Rewrite using lib

### Modified Files
- `.cig/scripts/command-helpers/context-inheritance.pl` - Rewrite to use lib
- `.cig/security/script-hashes.json` - Update with new hashes

### Files to Remove (after validation)
- `.cig/scripts/command-helpers/status-aggregator.sh`
- `.cig/scripts/command-helpers/hierarchy-resolver.sh`
- `.cig/scripts/command-helpers/format-detector.sh`

## Implementation Steps

### Step 1: Create Directory Structure
- [x] Create `.cig/lib/` directory
- [x] Create `.cig/lib/CIG/` directory

### Step 2: Implement CIG::MarkdownParser
- [x] Create `MarkdownParser.pm` with `extract_status($file)`
- [x] Implement state machine (in_code_block, in_status_section)
- [x] Handle `## Status` and `## Current Status` headers
- [x] Skip triple-backtick code blocks
- [x] Test against known false positive cases

### Step 3: Implement CIG::TaskPath
- [x] Create `TaskPath.pm`
- [x] Implement `normalize($path)` - convert `/` to `.`
- [x] Implement `validate($path)` - check format
- [x] Implement `build_glob($path)` - create search pattern
- [x] Implement `resolve($path)` - find task directory
- [x] Implement `get_parent($path)` - get parent path
- [x] Implement `get_depth($path)` - calculate depth

### Step 4: Implement CIG::WorkflowFiles
- [x] Create `WorkflowFiles.pm`
- [x] Implement `list($task_dir)` - list workflow files
- [x] Implement `get_template_version($file)` - detect version
- [x] Implement `status_to_percent($status)` - status mapping
- [x] Implement `load_config()` - load cig-project.json

### Step 5: Migrate Scripts
- [x] Rewrite `status-aggregator.pl` using lib modules
- [x] Rewrite `hierarchy-resolver.pl` using lib modules
- [x] Rewrite `format-detector.pl` using lib modules
- [x] Rewrite `context-inheritance.pl` using lib modules
- [x] Set permissions (chmod 500)

### Step 6: Validation
- [x] Test each script CLI interface matches original
- [x] Test output format matches original
- [x] Run `/cig-status` and verify Task 7 shows correct status
- [x] Verify all existing tasks report correct status

### Step 7: Security and Cleanup
- [x] Update `.cig/security/script-hashes.json`
- [x] Run `/cig-security-check verify`
- [x] Backup and remove old .sh scripts

## Code Changes

### Status Extraction - Before (false positives)
```bash
# status-aggregator.sh - matches FIRST occurrence anywhere
status=$(grep -m 1 -i '\*\*Status\*\*:' "$file" | sed -E 's/.*\*\*Status\*\*: *//i')
```

### Status Extraction - After (structure-aware)
```perl
# CIG::MarkdownParser - only matches in ## Status section
sub extract_status {
    my ($file_path) = @_;
    open(my $fh, '<', $file_path) or return "Unknown";

    my ($in_code_block, $in_status_section) = (0, 0);

    while (my $line = <$fh>) {
        chomp $line;

        # Toggle code block state
        if ($line =~ /^```/) { $in_code_block = !$in_code_block; next; }
        next if $in_code_block;

        # Enter status section
        if ($line =~ /^## (Current )?Status\s*$/i) { $in_status_section = 1; next; }

        # Exit on next L2 header
        if ($in_status_section && $line =~ /^## /) { $in_status_section = 0; }

        # Extract status only if in correct section
        if ($in_status_section && $line =~ /^\*\*Status\*\*:\s*(.+)$/) {
            close($fh);
            my $status = $1;
            $status =~ s/\s+$//;
            return $status;
        }
    }
    close($fh);
    return "Unknown";
}
```

## Test Coverage

### False Positive Tests
- Status in code block → ignored
- Status in `### Phase 1:` section → ignored
- Status in `## Maintenance Status` → ignored
- Status in `## Status` section → extracted

### Backward Compatibility Tests
- v1.0 format (`## Current Status`) → works
- v2.0 format (`## Status`) → works

### Integration Tests
- `/cig-status` output matches expected format
- `/cig-status 7` shows 100% (was falsely showing 25%)
- All CLI interfaces unchanged

## Validation Criteria
- [x] False positives eliminated (AC1)
- [x] Task 7 reports correct status (AC2)
- [x] No duplicated logic between scripts (AC3)
- [x] All existing tasks report correct values (AC4)
- [x] v1.0 and v2.0 formats work (AC5)

## Status
**Status**: Finished
**Next Action**: Proceed to testing phase
**Blockers**: None

## Actual Results
- Created shared Perl library with 3 modules (~400 lines total)
- Migrated 4 scripts to use shared lib (~350 lines total, down from ~600)
- Task 7 now correctly shows 100% (was falsely showing 25%)
- All 8 existing tasks report correct status
- Old .sh scripts removed after validation

## Lessons Learned
- State machine parsing is essential for markdown structure awareness
- Perl `-CDSL` flag handles UTF-8 cleanly in shebangs
- Shared library significantly reduces maintenance burden
- Incremental testing during implementation caught issues early
