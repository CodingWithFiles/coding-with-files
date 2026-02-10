# add slug generation to template-copier - Implementation Plan
**Task**: 53 (bugfix)

## Task Reference
- **Task ID**: internal-53
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/53-add-slug-generation-to-template-copier
- **Template Version**: 2.1

## Goal
Add slug generation function and make destination parameter optional in template-copier-v2.1.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cig/scripts/command-helpers/template-copier-v2.1` - Add slug generation, optional destination logic

### Supporting Changes
- `.cig/security/script-hashes.json` - Update SHA256 hash for template-copier-v2.1 after modification

## Implementation Steps

### Step 1: Add Slug Generation Function
- [ ] Add `generate_slug()` function after line 118 (after `find_templates_directory()`)
- [ ] Port bash algorithm to Perl: lowercase → remove special chars → hyphens → collapse → truncate 50
- [ ] Test function with sample inputs to verify exact bash algorithm match

### Step 2: Add Destination Constructor Function
- [ ] Add `construct_destination()` function after `generate_slug()`
- [ ] Read `directory-structure` config from cig-project.json using `load_config()`
- [ ] Build path: `{base_path}/{task_num}-{task_type}-{slug}`
- [ ] Handle edge cases (missing config, invalid pattern)

### Step 3: Modify Parameter Validation
- [ ] Line 74: Remove `destination` from required parameters array (keep task_type, task_num, description)
- [ ] After line 90: Add conditional logic to construct destination if not provided
- [ ] Preserve existing validation for other parameters

### Step 4: Update Usage Documentation
- [ ] Update `print_usage()` to mark `--destination` as optional (line 98)
- [ ] Add note: "If omitted, auto-constructed from config pattern"
- [ ] Keep examples showing both explicit and omitted destination

### Step 5: Manual Testing
- [ ] Test with explicit destination (backward compatibility): `--destination=/tmp/test`
- [ ] Test with omitted destination (auto-construction): no `--destination` flag
- [ ] Test various descriptions (special chars, long strings, edge cases)
- [ ] Verify output paths match expected pattern

### Step 6: Update Security Hash
- [ ] Calculate new SHA256 hash: `sha256sum .cig/scripts/command-helpers/template-copier-v2.1`
- [ ] Update `.cig/security/script-hashes.json` with new hash
- [ ] Verify hash integrity check passes

## Code Changes

### Change 1: Add generate_slug() Function

**Location**: After line 118 (after `find_templates_directory()`)

```perl
# Generate slug from description (matches bash: tr/sed/cut pipeline)
sub generate_slug {
    my ($description) = @_;

    # Lowercase
    $description = lc($description);

    # Remove special characters (keep alphanumeric, spaces, hyphens)
    $description =~ s/[^a-z0-9 -]//g;

    # Replace spaces with hyphens
    $description =~ s/ +/-/g;

    # Collapse consecutive hyphens
    $description =~ s/-+/-/g;

    # Truncate to 50 characters
    return substr($description, 0, 50);
}
```

### Change 2: Add construct_destination() Function

**Location**: After `generate_slug()`

```perl
# Construct destination path from config pattern if not provided
sub construct_destination {
    my ($params) = @_;

    my $config = load_config();
    unless ($config) {
        print STDERR "Error: Failed to load config\n";
        exit 2;
    }

    my $base_path = $config->{directory_structure}{base_path} || 'implementation-guide';
    my $slug = generate_slug($params->{description});
    my $task_dir = "$params->{task_num}-$params->{task_type}-$slug";

    return "$base_path/$task_dir";
}
```

### Change 3: Modify parse_parameters()

**Before** (line 74):
```perl
for my $required (qw(task_type destination task_num description)) {
    unless (exists $params{$required}) {
        my $param_name = $param_names{$required};
        print STDERR "Error: Missing required parameter --$param_name\n";
        print STDERR "Use --help for usage information\n";
        exit 1;
    }
}
```

**After** (line 74):
```perl
# destination now optional - removed from required list
for my $required (qw(task_type task_num description)) {
    unless (exists $params{$required}) {
        my $param_name = $param_names{$required};
        print STDERR "Error: Missing required parameter --$param_name\n";
        print STDERR "Use --help for usage information\n";
        exit 1;
    }
}

# Construct destination if not provided
unless (exists $params{destination}) {
    $params{destination} = construct_destination(\%params);
}
```

### Change 4: Update Usage Documentation

**Before** (line 102):
```perl
  --destination=PATH   Full path to task directory
```

**After** (line 102):
```perl
  --destination=PATH   Full path to task directory (optional, auto-constructed if omitted)
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

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
**Next Action**: /cig-testing-plan 53
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
