# Fix format detector for v2.1 format - Implementation

## Task Reference
- **Task ID**: internal-30
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/30-fix-format-detector-for-v2.1-format
- **Template Version**: 2.1

## Goal
Implement header-based format detection with file fallback, update templates to v2.1, consolidate trampoline detection, and migrate existing v2.1 tasks.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Phase 1: Core Detection Logic (3 files)
- `.cig/lib/CIG/TaskPath.pm` - Add detect_format() function with header reading + file fallback
- `.cig/scripts/command-helpers/status-aggregator` - Replace local detection with CIG::TaskPath::resolve()
- `.cig/scripts/command-helpers/context-inheritance` - Replace local detection with CIG::TaskPath::resolve()

### Phase 2: Template Headers (10 files)
Update "Template Version: 2.0" → "Template Version: 2.1":
- `.cig/templates/pool/a-task-plan.md.template`
- `.cig/templates/pool/b-requirements-plan.md.template`
- `.cig/templates/pool/c-design-plan.md.template`
- `.cig/templates/pool/d-implementation-plan.md.template`
- `.cig/templates/pool/e-testing-plan.md.template`
- `.cig/templates/pool/f-implementation-exec.md.template`
- `.cig/templates/pool/g-testing-exec.md.template`
- `.cig/templates/pool/h-rollout.md.template`
- `.cig/templates/pool/i-maintenance.md.template`
- `.cig/templates/pool/j-retrospective.md.template`

### Phase 3: Existing Task Migration (14 files)
Update "Template Version: 2.0" → "Template Version: 2.1" in:
- `implementation-guide/26-bugfix-update-cig-status-to-use-workflow-flag/*.md` (7 files)
- `implementation-guide/30-bugfix-fix-format-detector-for-v2.1-format/*.md` (7 files)

### Phase 4: Security Hash Update (1 file)
- `.cig/security/script-hashes.json` - Update SHA256 for modified scripts

## Implementation Steps

### Phase 1: Core Detection Logic

#### Step 1.1: Add detect_format() to TaskPath.pm
- [ ] Open `.cig/lib/CIG/TaskPath.pm`
- [ ] Add new detect_format() function after get_depth() (around line 186)
- [ ] Implement four-step detection: read header → check files → compare → warn if mismatch
- [ ] Use CIG::WorkflowFiles::get_template_version() pattern for header reading
- [ ] File-based detection logic (CRITICAL - use correct file names):
  - v2.1: Check for `e-testing-plan.md` OR `f-implementation-exec.md`
  - v2.0: Check for `a-plan.md` OR `d-implementation.md` (NOT a-task-plan.md!)
  - v1.0: Check for `plan.md`
  - Default: v1.0
- [ ] Return header version if present, else file-based version

#### Step 1.2: Update resolve() in TaskPath.pm
- [ ] Replace lines 135-139 (format detection block)
- [ ] Change from inline logic to: `my $format = detect_format($full_path);`
- [ ] Verify $format is returned in hashref

#### Step 1.3: Update status-aggregator trampoline
- [ ] Open `.cig/scripts/command-helpers/status-aggregator`
- [ ] Add `use CIG::TaskPath qw(resolve);` to imports (after line 22)
- [ ] Replace detect_version() function (lines 24-67)
- [ ] New logic: call resolve($task_arg) and extract format from result
- [ ] Keep intelligent defaults logic unchanged (lines 109-135)

#### Step 1.4: Update context-inheritance trampoline
- [ ] Open `.cig/scripts/command-helpers/context-inheritance`
- [ ] Add `use CIG::TaskPath qw(resolve);` to imports (after line 11)
- [ ] Replace detect_version() function (lines 20-63)
- [ ] New logic: call resolve($task_arg) and extract format from result
- [ ] Verify trampoline exec logic unchanged (lines 66-79)

#### Step 1.5: Test Phase 1
- [ ] Run `hierarchy-resolver 30` - expect warning (header says 2.0, files say 2.1)
- [ ] Run `hierarchy-resolver 26` - expect warning (header says 2.0, files say 2.1)
- [ ] Verify warning message clear and actionable
- [ ] Verify format returned is "2.0" (header takes precedence)

### Phase 2: Template Headers

#### Step 2.1: Update v2.1 template headers
- [ ] Use Edit tool with replace_all=true for efficiency
- [ ] Pattern: `"Template Version**: 2.0"` → `"Template Version**: 2.1"`
- [ ] Update all 10 template files in `.cig/templates/pool/`
- [ ] Verify only v2.1 templates updated (not v2.0-only templates)

#### Step 2.2: Test Phase 2
- [ ] Create test task with template-copier: `template-copier --task-type=bugfix --destination=implementation-guide/99-test-v21-detection --task-num=99 --description="Test v2.1 detection"`
- [ ] Run `hierarchy-resolver 99`
- [ ] Verify reports "Format: v2.1" (no warning)
- [ ] Verify header shows "Template Version: 2.1"
- [ ] Clean up test task: `rm -rf implementation-guide/99-test-v21-detection`

### Phase 3: Existing Task Migration

#### Step 3.1: Update Task 26 headers
- [ ] Find all .md files in Task 26: `ls implementation-guide/26-*/*.md`
- [ ] Update header in each file (7 files): "Template Version: 2.0" → "Template Version: 2.1"
- [ ] Use Edit tool for each file

#### Step 3.2: Update Task 30 headers
- [ ] Find all .md files in Task 30: `ls implementation-guide/30-*/*.md`
- [ ] Update header in each file (7 files): "Template Version: 2.0" → "Template Version: 2.1"
- [ ] Use Edit tool for each file

#### Step 3.3: Test Phase 3
- [ ] Run `hierarchy-resolver 26` - expect "Format: v2.1", no warning
- [ ] Run `hierarchy-resolver 30` - expect "Format: v2.1", no warning
- [ ] Run `/cig-status 26` - verify uses v2.1 script
- [ ] Run `/cig-status 30` - verify uses v2.1 script

### Phase 4: Security and Validation

#### Step 4.1: Update script hashes
- [ ] Calculate SHA256 for status-aggregator: `sha256sum .cig/scripts/command-helpers/status-aggregator`
- [ ] Calculate SHA256 for context-inheritance: `sha256sum .cig/scripts/command-helpers/context-inheritance`
- [ ] Update `.cig/security/script-hashes.json` with new hashes
- [ ] Verify with `/cig-security-check verify`

#### Step 4.2: Regression Testing
- [ ] Find v2.0 task: `ls -d implementation-guide/*-feature-* | head -1`
- [ ] Run hierarchy-resolver on v2.0 task - expect "Format: v2.0", no warning
- [ ] Verify v2.0 detection unchanged

#### Step 4.3: Create checkpoint commit
- [ ] Stage all changes: `git add .cig/ implementation-guide/`
- [ ] Review staged changes: `git diff --staged`
- [ ] Commit with descriptive message including "why"

## Code Changes

### Change 1: TaskPath.pm - Add detect_format()

**Before** (.cig/lib/CIG/TaskPath.pm lines 135-139):
```perl
# Detect format (v1.0 or v2.0)
my $format = "1.0";
if (-f "$full_path/a-plan.md" || -f "$full_path/d-implementation.md") {
    $format = "2.0";
}
```

**After** (.cig/lib/CIG/TaskPath.pm lines 135 + new function):
```perl
# Detect format (v1.0, v2.0, or v2.1)
my $format = detect_format($full_path);

# ... (after get_depth function, around line 186)

# Detect task format version from headers and files
# Args: $full_path - full path to task directory
# Returns: "1.0", "2.0", or "2.1"
sub detect_format {
    my ($full_path) = @_;

    # Step 1: Read header version (authoritative)
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

    # Step 2: File-based detection (fallback/validation)
    my $file_version;
    if (-f "$full_path/e-testing-plan.md" || -f "$full_path/f-implementation-exec.md") {
        $file_version = "2.1";
    } elsif (-f "$full_path/a-task-plan.md" || -f "$full_path/d-implementation-plan.md") {
        $file_version = "2.0";
    } elsif (-f "$full_path/plan.md") {
        $file_version = "1.0";
    } else {
        $file_version = "1.0";
    }

    # Step 3: Warn if mismatch
    if ($header_version && $header_version ne $file_version) {
        warn "WARNING: Version mismatch in $full_path\n";
        warn "  Header says: v$header_version\n";
        warn "  Files indicate: v$file_version\n";
        warn "  Using header version (v$header_version)\n";
        warn "  Consider running migration to sync files\n\n";
    }

    # Step 4: Return header if present, else file-based
    return $header_version || $file_version;
}
```

### Change 2: status-aggregator - Use CIG::TaskPath

**Before** (.cig/scripts/command-helpers/status-aggregator lines 24-67):
```perl
# Detect version by checking Template Version header in workflow files
sub detect_version {
    my $task_arg = shift || '';

    # ... (43 lines of local detection logic)

    # Fallback: check for v2.1 indicators (WRONG - checks ANY task)
    if (-d $base_dir) {
        my @v21_files = glob("$base_dir/*-*-*/f-implementation-exec.md");
        return 'v2.1' if @v21_files;
    }

    return 'v2.0';
}
```

**After**:
```perl
use CIG::TaskPath qw(resolve);

# Detect version by resolving task path
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

### Change 3: context-inheritance - Use CIG::TaskPath

**Before** (.cig/scripts/command-helpers/context-inheritance lines 20-63):
```perl
# Detect version by checking Template Version header (same as status-aggregator)
sub detect_version {
    # ... (identical buggy logic)
}
```

**After**:
```perl
use CIG::TaskPath qw(resolve);

# Detect version by resolving task path
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

### Change 4: Template Headers

**Before** (all 10 templates):
```markdown
- **Template Version**: 2.1
```

**After** (all 10 templates):
```markdown
- **Template Version**: 2.1
```

### Change 5: Task Headers

**Before** (Tasks 26 and 30, 7 files each):
```markdown
- **Template Version**: 2.1
```

**After** (Tasks 26 and 30, 7 files each):
```markdown
- **Template Version**: 2.1
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

Key tests to implement:
- TC-1: v2.1 detection with correct headers (Tasks 26, 30 post-migration)
- TC-2: v2.0 detection unchanged (regression test)
- TC-3: v1.0 detection unchanged (regression test)
- TC-4: Warning on mismatch (temporary incorrect header)
- TC-5: Trampoline script routing (status-aggregator, context-inheritance)
- TC-6: New task creation with v2.1 templates

## Validation Criteria

### Functional Validation
- [ ] `hierarchy-resolver 26` reports "Format: v2.1" (no warning)
- [ ] `hierarchy-resolver 30` reports "Format: v2.1" (no warning)
- [ ] v2.0 tasks still detect correctly (no regression)
- [ ] v1.0 tasks still detect correctly (no regression)
- [ ] Warning appears when header/files mismatch
- [ ] `/cig-status 30` uses status-aggregator-v2.1
- [ ] New tasks created with "Template Version: 2.1" headers

### Code Quality
- [ ] No duplicate detection logic across scripts
- [ ] All trampoline scripts use CIG::TaskPath::resolve()
- [ ] detect_format() follows existing code patterns
- [ ] Script hashes updated in .cig/security/script-hashes.json

### Documentation
- [ ] Code comments explain "why" (version mismatch warning rationale)
- [ ] Commit message explains problem + solution

## Status
**Status**: Finished
**Next Action**: Proceed to retrospective → `/cig-retrospective 30`
**Blockers**: None
**Change Log**:
- 2026-01-27: Added correct v2.0 file names to Step 1.1 (`a-plan.md`, NOT `a-task-plan.md`)
- 2026-01-27: Implementation plan completed and validated

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
