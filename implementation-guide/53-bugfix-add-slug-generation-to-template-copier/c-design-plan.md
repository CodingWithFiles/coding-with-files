# add slug generation to template-copier - Design
**Task**: 53 (bugfix)

## Task Reference
- **Task ID**: internal-53
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/53-add-slug-generation-to-template-copier
- **Template Version**: 2.1

## Goal
Add slug generation function to template-copier and make destination parameter optional with automatic path construction.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Architecture Choice
- **Decision**: Add slug generation as pure function + modify parameter validation to make destination optional
- **Rationale**:
  - Pure function approach makes slug generation testable and reusable
  - Optional parameter with fallback preserves backward compatibility
  - Minimal code changes - single script modification
- **Trade-offs**:
  - **Benefits**: Eliminates permission prompts, simplifies commands, single source of truth for slug logic
  - **Drawbacks**: Slightly more complex parameter validation logic (if/else for destination)

### Technology Stack
- **Language**: Perl (existing template-copier implementation)
- **Configuration**: cig-project.json (`directory-structure.pattern` for path construction)
- **Algorithm**: Direct port of existing bash pipeline to Perl regex

## System Design
### Component Overview
- **`generate_slug($description)`**: Pure function converting description to slug
  - Input: Raw description string (e.g., "Add User Authentication")
  - Output: Slugified string (e.g., "add-user-authentication")
  - Algorithm: lowercase → remove special chars → spaces to hyphens → collapse hyphens → truncate to 50
- **`construct_destination($params)`**: Build destination path if not provided
  - Input: task_num, task_type, description (or pre-generated slug)
  - Output: Full destination path following `directory-structure.pattern` from config
  - Logic: Read config → generate slug → substitute into pattern → prepend base-path
- **Modified `parse_parameters()`**: Make destination optional
  - If `--destination` provided: Use as-is (existing behavior)
  - If `--destination` omitted: Call `construct_destination()` to build path

### Data Flow
1. **Command invocation**: `cig-new-task` calls template-copier with type/num/description (no destination)
2. **Parameter parsing**: `parse_parameters()` detects missing destination
3. **Slug generation**: `generate_slug()` converts description to slug
4. **Path construction**: `construct_destination()` builds path from config pattern
5. **Template copying**: Existing logic uses constructed destination
6. **Output**: Script returns success with destination path (for branch creation)

## Interface Design
### Function Signatures

**New Functions**:
```perl
# Generate slug from description
# Input: "Add User Authentication"
# Output: "add-user-authentication"
sub generate_slug {
    my ($description) = @_;

    $description = lc($description);           # Lowercase
    $description =~ s/[^a-z0-9 -]//g;         # Remove special chars
    $description =~ s/ +/-/g;                  # Spaces to hyphens
    $description =~ s/-+/-/g;                  # Collapse hyphens
    return substr($description, 0, 50);        # Truncate to 50 chars
}

# Construct destination path if not provided
# Input: { task_num => "53", task_type => "bugfix", description => "add slug..." }
# Output: "implementation-guide/53-bugfix-add-slug-generation-to-template-copier"
sub construct_destination {
    my ($params) = @_;

    my $config = load_config();
    my $base_path = $config->{directory_structure}{base_path} || 'implementation-guide';
    my $pattern = $config->{directory_structure}{pattern};

    my $slug = generate_slug($params->{description});
    my $task_dir = "$params->{task_num}-$params->{task_type}-$slug";

    return "$base_path/$task_dir";
}
```

**Modified Function**:
```perl
# parse_parameters() changes:
# - Line 74: Remove 'destination' from required parameters list
# - After line 90: Add destination construction if not provided
sub parse_parameters {
    # ... existing parsing logic ...

    # NEW: Make destination optional
    for my $required (qw(task_type task_num description)) {  # destination removed
        unless (exists $params{$required}) {
            # ... error handling ...
        }
    }

    # NEW: Construct destination if not provided
    unless (exists $params{destination}) {
        $params{destination} = construct_destination(\%params);
    }

    return %params;
}
```

### Parameter Changes
**Before**:
```bash
--task-type=bugfix --destination=implementation-guide/53-bugfix-add-slug-generation-to-template-copier --task-num=53 --description="add slug generation to template-copier"
```

**After** (optional destination):
```bash
--task-type=bugfix --task-num=53 --description="add slug generation to template-copier"
# Destination auto-constructed: implementation-guide/53-bugfix-add-slug-generation-to-template-copier
```

**Backward compatible** (explicit destination still works):
```bash
--task-type=bugfix --destination=/tmp/test-task --task-num=53 --description="test"
```

## Constraints
- **Algorithm Exactness**: Perl implementation must produce byte-for-byte identical output to existing bash pipeline
- **Backward Compatibility**: Existing scripts using explicit `--destination` must work unchanged
- **Config Dependency**: Requires `directory-structure.pattern` in cig-project.json (already exists)
- **No Breaking Changes**: Commands can transition gradually (old invocations still work)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? **NO** - 2-4 hours estimated
- [x] **People**: Does this need >2 people working on different parts? **NO** - single developer change
- [x] **Complexity**: Does this involve 3+ distinct concerns? **NO** - two closely related functions (slug generation + path construction)
- [x] **Risk**: Are there high-risk components that need isolation? **NO** - straightforward pure functions with clear test cases
- [x] **Independence**: Can parts be worked on separately? **NO** - path construction depends on slug generation

**Decomposition Decision**: No decomposition needed. All signals negative. Cohesive design with two interdependent functions.

## Validation
- [x] Design review completed - clear function signatures and data flow
- [x] Architecture approved - pure functions, optional parameters, backward compatible
- [x] Integration points verified - modifies only template-copier, commands benefit automatically

## Status
**Status**: Finished
**Next Action**: /cig-implementation-plan 53
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
