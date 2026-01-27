# Fix format detector for v2.1 format - Design

## Task Reference
- **Task ID**: internal-30
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/30-fix-format-detector-for-v2.1-format
- **Template Version**: 2.1

## Goal
Define format detection architecture that distinguishes v2.1 (10-phase) from v2.0 (8-phase) and v1.0 (7-phase) formats using file presence checks.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Architecture Choice: Header-Based Detection with File-Based Fallback

**Decision**: Use headers as authoritative source, with file-based fallback for backward compatibility

**Rationale**:
- **Headers are authoritative**: "Template Version" field should be the primary source of truth
- **Current state is a bug**: v2.1 tasks currently have "Template Version: 2.0" which is incorrect
- **Fix the root cause**: Update templates to emit "Template Version: 2.1" for v2.1 tasks
- **Backward compatibility**: Use file-based detection as fallback for existing misidentified tasks

**Trade-offs**:
- ✅ **Pro**: Headers are authoritative and explicit
- ✅ **Pro**: Future tasks will be correctly identified at creation time
- ✅ **Pro**: No ambiguity (v2.1 header = v2.1 format)
- ✅ **Pro**: Aligns with existing CIG::WorkflowFiles::get_template_version() design
- ⚠️ **Con**: Requires updating templates (7-10 template files)
- ⚠️ **Con**: Requires migrating existing v2.1 tasks (Tasks 26, 30) to update headers
- ✅ **Mitigation**: File-based fallback ensures no breaking changes during transition

### Alternative Considered: File-Based Detection Only

**Rejected**: Doesn't fix root cause. Headers should be authoritative, not a fallback. File-based detection should only be used for backward compatibility with existing misidentified tasks.

## System Design

### Component Overview

**Component 1: CIG::TaskPath::resolve()** (.cig/lib/CIG/TaskPath.pm:107-154)
- **Current Role**: Resolves task path to directory and detects format
- **Current Logic** (lines 135-139):
  ```perl
  my $format = "1.0";
  if (-f "$full_path/a-plan.md" || -f "$full_path/d-implementation.md") {
      $format = "2.0";
  }
  ```
- **Problem**: Only distinguishes v1.0 vs v2.0, doesn't detect v2.1
- **Change Required**: Add v2.1 detection before v2.0 check

**Component 2: CIG::WorkflowFiles::get_template_version()** (.cig/lib/CIG/WorkflowFiles.pm:96-112)
- **Current Role**: Reads "Template Version" header from workflow files
- **Current Logic**: Parses header, returns "1.0" or "2.0"
- **Problem**: Returns "2.0" for v2.1 files (correct per header, wrong for format)
- **Change Required**: Add note in POD that this is TEMPLATE version, not FORMAT version

**Component 3: CIG::WorkflowFiles::V21** (.cig/lib/CIG/WorkflowFiles/V21.pm)
- **Current Role**: Defines v2.1 workflow file arrays by task type
- **Current Usage**: Only used by template-copier and status-aggregator-v2.1
- **Opportunity**: Could export v2.1 indicator files for consistent detection
- **Change Required**: None (informational only)

**New Component 4: CIG::TaskPath::detect_format()** (NEW FUNCTION)
- **Responsibility**: Centralized format detection with v2.1 support
- **Used By**: resolve() function (internal to TaskPath module)
- **Detection Logic**: Three-tier check (v2.1 → v2.0 → v1.0)
- **Returns**: "2.1", "2.0", or "1.0"

### Data Flow

```
User runs command (e.g., /cig-status 30)
              ↓
Command invokes hierarchy-resolver
              ↓
hierarchy-resolver calls CIG::TaskPath::resolve("30")
              ↓
resolve() calls detect_format($full_path)  [NEW]
              ↓
detect_format() checks files:
  1. Check for e-testing-plan.md OR f-implementation-exec.md
     → Found: return "2.1"
  2. Else check for a-task-plan.md OR d-implementation-plan.md
     → Found: return "2.0"
  3. Else check for plan.md
     → Found: return "1.0"
  4. Else: return "1.0" (default for unknown)
              ↓
resolve() returns hashref with format="2.1"
              ↓
hierarchy-resolver outputs "Format: v2.1"
```

## Interface Design

### New Function: CIG::TaskPath::detect_format()

**Location**: .cig/lib/CIG/TaskPath.pm (new function)

**Signature**:
```perl
sub detect_format {
    my ($full_path) = @_;
    # Returns: "2.1", "2.0", or "1.0"
}
```

**Detection Algorithm**:
```perl
sub detect_format {
    my ($full_path) = @_;

    # Step 1: Get version from header (authoritative source)
    my $header_version = undef;
    for my $file (glob("$full_path/*.md")) {
        open(my $fh, '<', $file) or next;
        while (my $line = <$fh>) {
            if ($line =~ /^\- \*\*Template Version\*\*:\s*([0-9.]+)/) {
                $header_version = $1;
                close($fh);
                last;
            }
            last if $line =~ /^## / && $line !~ /^## Task Reference/;
        }
        last if $header_version;
    }

    # Step 2: Detect version from file presence (fallback/validation)
    my $file_version;
    if (-f "$full_path/e-testing-plan.md" || -f "$full_path/f-implementation-exec.md") {
        $file_version = "2.1";
    } elsif (-f "$full_path/a-task-plan.md" || -f "$full_path/d-implementation-plan.md") {
        $file_version = "2.0";
    } elsif (-f "$full_path/plan.md") {
        $file_version = "1.0";
    } else {
        $file_version = "1.0";  # Default
    }

    # Step 3: Check for inconsistency and warn
    if ($header_version && $header_version ne $file_version) {
        warn "WARNING: Version mismatch in $full_path\n";
        warn "  Header says: v$header_version\n";
        warn "  Files indicate: v$file_version\n";
        warn "  Using header version (v$header_version) as authoritative\n";
        warn "  Consider running migration to sync files with header\n\n";
    }

    # Step 4: Return header version if present (authoritative), else file-based
    return $header_version || $file_version;
}
```

**Detection Sequence**:
1. Read header version from "Template Version" field
2. Detect version from file presence (e/f for v2.1, a/d for v2.0, plan.md for v1.0)
3. Compare both results - warn if they disagree
4. Return header version if present, otherwise file-based version

**Rationale for Warning**:
- Catches migration issues (tasks with outdated headers)
- Alerts to corrupted/incomplete tasks
- Helps debugging version detection problems
- Guides user to fix inconsistencies

### Modified Function: CIG::TaskPath::resolve()

**Change** (line 135-139):
```perl
# OLD:
my $format = "1.0";
if (-f "$full_path/a-plan.md" || -f "$full_path/d-implementation.md") {
    $format = "2.0";
}

# NEW:
my $format = detect_format($full_path);
```

**Impact**: Single line change, delegates to new function

## Constraints

### Technical Constraints
1. **Backward Compatibility**: Must not break v1.0 or v2.0 detection
2. **File Naming Convention**: Depends on v2.1 using e-testing-plan.md and f-implementation-exec.md
3. **No Header Parsing**: Cannot use "Template Version" header (v2.1 uses "2.0")
4. **Fast Execution**: Must remain <10ms per task (filesystem checks only)

### Performance Considerations
- Filesystem checks (-f) are fast (~1μs per check)
- Three-tier check worst-case: 7 filesystem checks (v2.1: 2, v2.0: 2, v1.0: 1, fallback)
- Typical case: 2 checks (v2.1 detected immediately)
- No header parsing overhead (parsing would be ~100x slower)

### Security Requirements
- No user input in file paths (paths constructed from validated task numbers)
- Filesystem checks only (no execution risk)
- Same security model as existing detection

## Validation

### Test Cases (To Be Implemented in Testing Phase)

**TC-1: v2.1 Task Detection**
- Given: Task 30 with e-testing-plan.md and f-implementation-exec.md
- When: hierarchy-resolver 30
- Then: Reports "Format: v2.1"

**TC-2: v2.0 Task Detection (No Regression)**
- Given: Task with a-task-plan.md but no e-testing-plan.md
- When: hierarchy-resolver resolves task
- Then: Reports "Format: v2.0" (not v2.1)

**TC-3: v1.0 Task Detection (No Regression)**
- Given: Task with plan.md only
- When: hierarchy-resolver resolves task
- Then: Reports "Format: v1.0"

**TC-4: Partial v2.1 Task (Edge Case)**
- Given: Task with only a-d files (e not created yet)
- When: hierarchy-resolver resolves task
- Then: Reports "Format: v2.0" (acceptable - task incomplete)

**TC-5: Partial v2.1 Task (With e-testing-plan.md)**
- Given: Task with a-e files (f not created yet)
- When: hierarchy-resolver resolves task
- Then: Reports "Format: v2.1" (correct - e exists)

### Design Validation Checklist
- [x] Architecture choice documented with rationale
- [x] Component responsibilities clearly defined
- [x] Data flow documented with sequence
- [x] Interface contracts specified (function signature, algorithm)
- [x] Design priorities followed (Testability: 5 test cases; Readability: explicit checks; Simplicity: single function)
- [x] Trade-offs explicitly stated
- [x] Constraints identified (backward compat, performance, security)
- [x] Integration points identified (resolve() function)

## Duplicate Detection Logic Audit

Audited all helper scripts for local format detection. Found **3 scripts with local format detection**:

### 1. template-copier (lines 13-27)
**Purpose**: Detect which template version to use for NEW tasks
**Current Logic**: Checks template pool for `f-implementation-exec.md.template`
**Assessment**: ✅ **Keep as-is** - Different purpose (template availability, not task detection)

### 2. status-aggregator (lines 24-67)
**Purpose**: Detect which version-specific script to exec for EXISTING task
**Current Logic**:
```perl
# 1. Try Template Version header in task files
# 2. Fallback: glob for ANY v2.1 task in implementation-guide (WRONG!)
my @v21_files = glob("$base_dir/*-*-*/f-implementation-exec.md");
return 'v2.1' if @v21_files;
```
**Problem**: Fallback checks if ANY task is v2.1, not the SPECIFIC task
**Fix**: ⚠️ **Should use CIG::TaskPath::detect_format()** for task-specific detection

### 3. context-inheritance (lines 20-63)
**Purpose**: Detect which version-specific script to exec for EXISTING task
**Current Logic**: Identical to status-aggregator (same bug)
**Problem**: Same fallback bug - checks ANY task, not specific task
**Fix**: ⚠️ **Should use CIG::TaskPath::detect_format()** for task-specific detection

### Design Decision: Consolidate Task Detection

**Change**: Update trampoline scripts to use centralized detection

**Benefits**:
- ✅ Single source of truth for task format detection
- ✅ Fixes fallback bug (currently checks ANY task, not specific task)
- ✅ Automatic v2.1 support when TaskPath.pm updated
- ✅ Consistent detection logic across all scripts

**Implementation**:
```perl
# In status-aggregator and context-inheritance trampolines:

use CIG::TaskPath qw(resolve);

sub detect_version {
    my $task_arg = shift || '';

    # If specific task provided, detect its format
    if ($task_arg && $task_arg =~ /^\d+(\.\d+)*$/) {
        my $result = resolve($task_arg);
        return "v$result->{format}" if $result;
    }

    # No task specified: default to v2.0
    return 'v2.0';
}
```

**Impact**: 2 additional files to modify (status-aggregator, context-inheritance)

## Critical Files

**Files to Modify** (13+ total):

### Phase 1: Core Detection Logic (3 files)
1. `.cig/lib/CIG/TaskPath.pm` - Add detect_format() function, update resolve() [PRIMARY]
2. `.cig/scripts/command-helpers/status-aggregator` - Use CIG::TaskPath::resolve() [CONSOLIDATION]
3. `.cig/scripts/command-helpers/context-inheritance` - Use CIG::TaskPath::resolve() [CONSOLIDATION]

### Phase 2: Template Headers (10 files)
Update "Template Version: 2.0" → "Template Version: 2.1" in v2.1 templates:
4. `.cig/templates/pool/a-task-plan.md.template`
5. `.cig/templates/pool/b-requirements-plan.md.template`
6. `.cig/templates/pool/c-design-plan.md.template`
7. `.cig/templates/pool/d-implementation-plan.md.template`
8. `.cig/templates/pool/e-testing-plan.md.template`
9. `.cig/templates/pool/f-implementation-exec.md.template`
10. `.cig/templates/pool/g-testing-exec.md.template`
11. `.cig/templates/pool/h-rollout.md.template`
12. `.cig/templates/pool/i-maintenance.md.template`
13. `.cig/templates/pool/j-retrospective.md.template`

### Phase 3: Existing Task Migration (2 tasks)
Update headers in existing v2.1 tasks:
14. `implementation-guide/26-bugfix-update-cig-status-to-use-workflow-flag/*.md` (7 files)
15. `implementation-guide/30-bugfix-fix-format-detector-for-v2.1-format/*.md` (7 files)

**Files to Review** (no changes needed, but verify compatibility):
16. `.cig/scripts/command-helpers/hierarchy-resolver` - Consumer of resolve()
17. `.cig/scripts/command-helpers/template-copier` - Different purpose (template pool check), keep as-is
18. `.cig/lib/CIG/WorkflowFiles.pm` - get_template_version() documentation clarification
19. `.cig/lib/CIG/WorkflowFiles/V21.pm` - v2.1 workflow file definitions (reference only)

**Test Coverage**:
- Task 26 (v2.1 bugfix task) - verify detects as v2.1 after header update
- Task 30 (v2.1 bugfix task) - verify detects as v2.1 after header update
- Any v2.0 tasks - verify no regression, still detect as v2.0
- Any v1.0 tasks - verify no regression, still detect as v1.0
- Mismatch scenario - temporarily set wrong header, verify warning appears
- `/cig-status 30` - verify uses correct version-specific script
- `/cig-requirements 30` - verify uses correct version-specific script

## Status
**Status**: Finished
**Next Action**: Task complete with retrospective
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
