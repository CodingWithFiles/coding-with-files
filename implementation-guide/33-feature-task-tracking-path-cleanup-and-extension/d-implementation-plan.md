# task-tracking-path-cleanup-and-extension - Implementation

## Task Reference
- **Task ID**: internal-33
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/33-task-tracking-path-cleanup-and-extension
- **Template Version**: 2.1

## Goal
Implement task-tracking-path-cleanup-and-extension following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Implementation Status Note

**IMPORTANT**: Implementation was executed before design/requirements were finalized. This plan documents the CORRECT approach based on approved requirements and design. The existing implementation in CIG::TaskPath.pm must be reviewed and potentially refactored to ensure:

1. **Orthogonal resolution**: resolve_branch and resolve_path delegate to resolve_num (not duplicated logic)
2. **Predicate naming**: Functions renamed from validate_* to task_exists/branch_exists with *_exists suffix
3. **Availability pattern**: Remove *_free functions, use negative predicates instead
4. **Optional base_dir**: All functions use $base_dir //= find_base_dir() pattern consistently
5. **No premature optimization**: Remove any caching logic (YAGNI principle)

During implementation execution, verify each function against this plan, not against what was already coded.

## Files to Modify

### Primary Changes
- `.cig/lib/CIG/TaskPath.pm` - Add new functions following orthogonal API design
  - Add format functions (format_dirname, parse_dirname, format_branch, parse_branch)
  - Add orthogonal resolution (resolve_num, resolve_branch, resolve_path) with delegation pattern
  - Add existence predicates (task_exists, branch_exists) using *_exists suffix
  - Add tree traversal primitives (find_parent, find_children) returning hashrefs
  - Add tree traversal composed (find_siblings, find_ancestors, find_descendants) using functional composition
  - Add allocation function (find_first_free) for relative depth navigation
  - Ensure all functions use optional base_dir with smart defaults ($base_dir //= find_base_dir())

### Supporting Changes
- `.cig/tests/TaskPath.t` - Comprehensive test suite for all new functions
- `.cig/docs/api/TaskPath.md` - API documentation (if exists, otherwise create)

### Dependencies
- Existing resolve_num, resolve_path, resolve_branch functions remain backwards compatible
- New functions use composition pattern (primitives → composed)

## Implementation Steps

### Step 1: Format Functions (FR3.1-3.4)
Implement string formatting/parsing functions (no filesystem access):

- [ ] **format_dirname($num, $type, $slug)**
  - Return "num-type-slug" format
  - Input validation (defined, non-empty)
  - Test: (32, "feature", "task-tracking") → "32-feature-task-tracking"

- [ ] **parse_dirname($dirname)**
  - Regex match "(\d+(?:\.\d+)*)-(\w+)-(.+)" pattern
  - Return list ($num, $type, $slug) or undef
  - Test: "32-feature-slug" → (32, "feature", "slug")

- [ ] **format_branch($num, $type, $slug)**
  - Return "type/num-slug" format
  - Input validation
  - Test: (32, "feature", "task-tracking") → "feature/32-task-tracking"

- [ ] **parse_branch($branch)**
  - Regex match "(\w+)/(\d+(?:\.\d+)*)-(.+)" pattern
  - Return list ($num, $type, $slug) or undef
  - Test: "feature/32-slug" → (32, "feature", "slug")

### Step 2: Tree Traversal Primitives (FR4.1-4.2)
Implement base functions returning hashrefs (rich metadata):

- [ ] **find_parent($num, $base_dir)**
  - Parse parent number: remove last dotted component ("3.1.2" → "3.1")
  - Call resolve_num($parent_num, $base_dir) to get full hashref
  - Return hashref or undef if top-level
  - **Implementation**:
    ```perl
    sub find_parent {
        my ($num, $base_dir) = @_;
        return undef unless $num =~ /\./;  # Top-level has no parent
        my $parent_num = $num;
        $parent_num =~ s/\.\d+$//;  # Remove last component
        return resolve_num($parent_num, $base_dir);
    }
    ```
  - Test edge cases: top-level returns undef, multi-level returns hashref

- [ ] **find_children($num, $base_dir)**
  - Scan base_dir for directories matching "$num.\d+" pattern
  - Use glob or readdir to get matching directories
  - For each match, call resolve_path to get hashref
  - Sort by num field (natural sort for hierarchical numbers)
  - Return list of hashrefs
  - **Implementation**:
    ```perl
    sub find_children {
        my ($num, $base_dir) = @_;
        $base_dir //= get_base_dir();
        my @dirs = glob("$base_dir/$num.*-*-*");
        my @children = map { resolve_path($_) } @dirs;
        return sort { version_compare($a->{num}, $b->{num}) } @children;
    }
    ```
  - Test: with real filesystem fixture, verify hashrefs returned

### Step 3: Tree Traversal Composed (FR4.3-4.5)
Build from primitives using functional composition (map, grep):

- [ ] **find_siblings($num, $base_dir)**
  - **Implementation** (one-liner using composition):
    ```perl
    sub find_siblings {
        my ($num, $base_dir) = @_;
        my $parent = find_parent($num, $base_dir);
        return grep { $_->{num} ne $num }
               find_children($parent ? $parent->{num} : '', $base_dir);
    }
    ```
  - Uses grep to filter, find_children to scan
  - Test: sibling detection, self-exclusion, top-level case

- [ ] **find_ancestors($num, $base_dir)**
  - **Implementation** (iterative, collecting hashrefs):
    ```perl
    sub find_ancestors {
        my ($num, $base_dir) = @_;
        my @ancestors;
        my $current = find_parent($num, $base_dir);
        while ($current) {
            push @ancestors, $current;
            $current = find_parent($current->{num}, $base_dir);
        }
        return @ancestors;
    }
    ```
  - Pure iteration of find_parent
  - Test: multi-level hierarchy returns list of hashrefs, top-level returns empty

- [ ] **find_descendants($num, $base_dir)**
  - **Implementation** (recursive using map and list flattening):
    ```perl
    sub find_descendants {
        my ($num, $base_dir) = @_;
        my @children = find_children($num, $base_dir);
        return (
            @children,
            map { find_descendants($_->{num}, $base_dir) } @children
        );
    }
    ```
  - Functional style: map over children, flatten results
  - Test: multi-level tree returns all hashrefs, leaf nodes return empty, verify depth-first order

### Step 4: Orthogonal Resolution Functions (FR1)
Implement resolution with delegation pattern:

- [ ] **resolve_num($num, $base_dir)** - Already exists, verify it follows design
  - Core resolution function
  - All other resolve_* delegate to this

- [ ] **resolve_branch($branch, $base_dir)**
  - Parse using parse_branch → extract ($num, $type, $slug)
  - Delegate to resolve_num($num, $base_dir)
  - Test: "feature/32-slug" returns same hashref as resolve_num("32")

- [ ] **resolve_path($path, $base_dir)**
  - Parse using parse_dirname(basename($path)) → extract ($num, $type, $slug)
  - Delegate to resolve_num($num, $base_dir)
  - Test: "32-feature-slug" returns same hashref as resolve_num("32")

- [ ] **resolve() as backward compatibility alias**
  - Simply delegates to resolve_num
  - Ensure existing code continues to work

### Step 5: Existence Predicates (FR2)
Implement predicate functions with *_exists suffix:

- [ ] **task_exists($num, $base_dir)**
  - Use resolve_num, return 1 if defined, 0 if undef
  - Boolean return: 1 = exists, 0 = not found
  - Optional base_dir with smart default
  - Test: task_exists("33") returns 1, task_exists("999") returns 0
  - Test: Use negatively: `if not task_exists("999")` for availability check

- [ ] **branch_exists($branch)**
  - Shell out to `git branch --list $branch` or use git rev-parse
  - Check if output is empty
  - Boolean return: 1 = exists, 0 = not found
  - Test: Use negatively for availability check

### Step 6: Allocation Function (FR3.5)
Implement task number allocation:

- [ ] **find_first_free($depth, $num)**
  - Resolve anchor: use $num if provided, else read .git/cig-current-task
  - Calculate target level using depth arithmetic:
    - Positive: go deeper (child = current + 1 component)
    - Zero: sibling (same level)
    - Negative: go up (parent's sibling, grandparent's sibling, etc.)
  - Scan filesystem at target level for existing tasks
  - Find first gap in numeric sequence (1, 2, 3, ...)
  - Return undef if depth calculation fails (too negative)
  - Test: all relative depths, top-level calculation

### Step 7: Update Exports and Documentation
Ensure all new functions are properly exported:

- [ ] **Update @EXPORT_OK in TaskPath.pm**
  - Add all new function names
  - Group by category (resolution, predicates, format, traversal, allocation)

- [ ] **Add POD documentation**
  - Document each function with examples
  - Show delegation pattern for orthogonal resolution
  - Show negative usage pattern for existence predicates
  - Show functional composition examples for tree traversal

- [ ] **Backwards compatibility verification**
  - Run existing tests to ensure no regressions
  - Verify existing code using resolve() continues to work
  - Test with existing CIG commands

### Step 8: Testing & Validation
- [ ] Write unit tests for each function (see e-testing.md)
- [ ] Test composition: verify find_siblings actually calls find_children
- [ ] Test edge cases: empty trees, single node, deep nesting
- [ ] Integration tests with real task hierarchy
- [ ] Performance test: find_descendants on large tree (100+ tasks)

## Implementation Order Rationale

Functions are implemented in dependency order following design principles:

1. **Format functions first** (FR3): No dependencies, pure string manipulation, easy to test
2. **Tree traversal primitives** (FR4.1-4.2): Foundation returning hashrefs via delegation to resolve_num
3. **Tree traversal composed** (FR4.3-4.5): Build using functional composition (map, grep, recursion)
4. **Orthogonal resolution** (FR1): Implement delegation pattern (resolve_branch/resolve_path → resolve_num)
5. **Existence predicates** (FR2): Simple wrappers around resolve functions
6. **Allocation function** (FR3.5): Uses predicates and traversal functions
7. **Exports and documentation**: Make functions discoverable
8. **Testing and validation**: Verify all requirements met

This order follows design priorities:
- **Testability**: Test primitives in isolation before composition
- **Simplicity**: Build complex from simple
- **Consistency**: Establish patterns early (hashrefs, optional base_dir, delegation)
- **Incremental verification**: Each step verifiable before next

## Test Coverage
**See e-testing.md for complete test plan**

## Validation Criteria
**See e-testing.md for validation criteria and test results**

## Status
**Status**: Finished
**Next Action**: Move to testing planning → `/cig-testing-plan 33`
**Blockers**: None

**Note**: Implementation was executed out of order (before design approval). Plan documents correct approach based on approved requirements and design. Existing code in CIG::TaskPath.pm requires review/refactoring to match this plan.

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
