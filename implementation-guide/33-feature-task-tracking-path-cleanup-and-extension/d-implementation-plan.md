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

## Files to Modify

### Primary Changes
- `.cig/lib/TaskPath.pm` - Add new functions, refactor existing functions
  - Add format functions (format_dirname, parse_dirname, format_branch, parse_branch)
  - Add tree traversal primitives (find_parent, find_children)
  - Add tree traversal composed (find_siblings, find_ancestors, find_descendants)
  - Add allocation functions (find_first_free, validate_num_free, validate_branch_free)
  - Refactor existing resolve_* functions to use new format functions

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

### Step 4: Allocation Functions (FR2, FR3.5)
Implement task number allocation and validation:

- [ ] **validate_num_free($num, $base_dir)**
  - Check if task directory exists
  - Use resolve_num, check if returns undef
  - Boolean return (1 = available, 0 = taken)

- [ ] **validate_branch_free($branch)**
  - Shell out to `git branch --list $branch`
  - Check if output is empty
  - Boolean return

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

### Step 5: Refactor Existing Functions
Use new format functions in resolve_* implementations:

- [ ] **resolve_num refactor**
  - Use parse_dirname instead of inline regex
  - DRY: eliminate duplicated parsing logic

- [ ] **resolve_branch refactor**
  - Use parse_branch instead of inline regex
  - Consistent error handling

- [ ] **Backwards compatibility verification**
  - Run existing tests to ensure no regressions
  - Verify return values unchanged

### Step 6: Testing & Validation
- [ ] Write unit tests for each function (see e-testing.md)
- [ ] Test composition: verify find_siblings actually calls find_children
- [ ] Test edge cases: empty trees, single node, deep nesting
- [ ] Integration tests with real task hierarchy
- [ ] Performance test: find_descendants on large tree (100+ tasks)

## Implementation Order Rationale

Functions are implemented in dependency order to enable incremental testing:

1. **Format functions first**: No dependencies, pure string manipulation, easy to test
2. **Primitives second**: Foundation for composed functions (find_parent, find_children)
3. **Composed functions third**: Build on primitives, verify composition works
4. **Allocation functions fourth**: Depend on tree traversal and resolution functions
5. **Refactoring last**: Ensure new functions work before using them in existing code

This order allows:
- Test each function in isolation before composition
- Verify primitives before building on them
- Incremental commits as each function group completes
- Early detection of design issues

## Test Coverage
**See e-testing.md for complete test plan**

## Validation Criteria
**See e-testing.md for validation criteria and test results**

## Status
**Status**: Backlog
**Next Action**: Move to testing planning → `/cig-testing-plan <task>`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
