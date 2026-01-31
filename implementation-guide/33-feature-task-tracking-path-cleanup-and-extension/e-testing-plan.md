# task-tracking-path-cleanup-and-extension - Testing

## Task Reference
- **Task ID**: internal-33
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/33-task-tracking-path-cleanup-and-extension
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for task-tracking-path-cleanup-and-extension.

## Test Strategy

### Test Levels

**Unit Tests** (Priority: Critical)
- Test each function in isolation with mocked dependencies
- Focus on pure functions (format_*, parse_*)
- Test primitives before composed functions
- Coverage target: 100% for all new functions

**Integration Tests** (Priority: High)
- Test function composition (primitives → composed)
- Test delegation patterns (resolve_branch → parse_branch → resolve_num)
- Test with real filesystem fixture (sample task directories)
- Coverage target: All function interactions

**Regression Tests** (Priority: Critical)
- Verify existing CIG commands unchanged
- Test backward compatibility (resolve() alias)
- Verify existing resolve_num/resolve_path/resolve_branch behavior
- Coverage target: All existing usage patterns

**Acceptance Tests** (Priority: High)
- Validate against acceptance criteria (AC1-AC6 from requirements)
- Test user stories with real-world scenarios
- Verify non-functional requirements (performance, usability)
- Coverage target: All acceptance criteria from b-requirements-plan.md

### Test Coverage Targets
- **Overall Coverage**: 95% minimum (library code, high quality bar)
- **Critical Paths**: 100% (resolution, existence checks, tree traversal)
- **Edge Cases**: Comprehensive (invalid input, missing directories, empty trees, deep nesting)
- **Regression**: 100% (all existing functionality must continue to work)

## Test Cases

### Unit Tests: Format Functions (FR3.1-3.4)

**TC-F1: format_dirname success**
- **Given**: Valid inputs (32, "feature", "task-tracking")
- **When**: format_dirname(32, "feature", "task-tracking") called
- **Then**: Returns "32-feature-task-tracking"

**TC-F2: format_dirname with hierarchical number**
- **Given**: Hierarchical number (3.1.2, "bugfix", "fix-parser")
- **When**: format_dirname("3.1.2", "bugfix", "fix-parser") called
- **Then**: Returns "3.1.2-bugfix-fix-parser"

**TC-F3: parse_dirname success**
- **Given**: Valid dirname "32-feature-task-tracking"
- **When**: parse_dirname("32-feature-task-tracking") called
- **Then**: Returns (32, "feature", "task-tracking")

**TC-F4: parse_dirname with hyphens in slug**
- **Given**: Complex slug "32-feature-fix-nested-slug-parsing"
- **When**: parse_dirname("32-feature-fix-nested-slug-parsing") called
- **Then**: Returns (32, "feature", "fix-nested-slug-parsing")

**TC-F5: parse_dirname invalid format**
- **Given**: Invalid dirname "invalid-format"
- **When**: parse_dirname("invalid-format") called
- **Then**: Returns empty list (not undef, not die)

**TC-F6: format_branch success**
- **Given**: Valid inputs (32, "feature", "task-tracking")
- **When**: format_branch(32, "feature", "task-tracking") called
- **Then**: Returns "feature/32-task-tracking"

**TC-F7: parse_branch success**
- **Given**: Valid branch "feature/32-task-tracking"
- **When**: parse_branch("feature/32-task-tracking") called
- **Then**: Returns (32, "feature", "task-tracking")

**TC-F8: parse_branch hierarchical**
- **Given**: Hierarchical branch "bugfix/1.1-fix-parser"
- **When**: parse_branch("bugfix/1.1-fix-parser") called
- **Then**: Returns ("1.1", "bugfix", "fix-parser")

### Unit Tests: Orthogonal Resolution (FR1)

**TC-R1: resolve_num success**
- **Given**: Task 33 exists in base_dir
- **When**: resolve_num("33", base_dir) called
- **Then**: Returns hashref with {num => "33", type => "feature", depth => 1, ...}

**TC-R2: resolve_num with optional base_dir**
- **Given**: Task 33 exists, base_dir not provided
- **When**: resolve_num("33") called
- **Then**: Uses find_base_dir(), returns hashref

**TC-R3: resolve_num non-existent task**
- **Given**: Task 999 does not exist
- **When**: resolve_num("999", base_dir) called
- **Then**: Returns undef

**TC-R4: resolve_branch delegates to resolve_num**
- **Given**: Task 33 exists, branch "feature/33-slug"
- **When**: resolve_branch("feature/33-slug", base_dir) called
- **Then**: Returns same hashref as resolve_num("33", base_dir)

**TC-R5: resolve_path delegates to resolve_num**
- **Given**: Task 33 exists, dirname "33-feature-slug"
- **When**: resolve_path("33-feature-slug", base_dir) called
- **Then**: Returns same hashref as resolve_num("33", base_dir)

**TC-R6: resolve() backward compatibility**
- **Given**: Task 33 exists
- **When**: resolve("33", base_dir) called
- **Then**: Returns same result as resolve_num("33", base_dir)

### Unit Tests: Existence Predicates (FR2)

**TC-E1: task_exists returns 1 for existing task**
- **Given**: Task 33 exists
- **When**: task_exists("33", base_dir) called
- **Then**: Returns 1

**TC-E2: task_exists returns 0 for non-existent task**
- **Given**: Task 999 does not exist
- **When**: task_exists("999", base_dir) called
- **Then**: Returns 0

**TC-E3: task_exists negative for availability**
- **Given**: Task 999 does not exist
- **When**: `if (not task_exists("999"))` evaluated
- **Then**: Condition is true (available for creation)

**TC-E4: branch_exists returns 1 for existing branch**
- **Given**: Branch "feature/33-slug" exists
- **When**: branch_exists("feature/33-slug") called
- **Then**: Returns 1

**TC-E5: branch_exists returns 0 for non-existent branch**
- **Given**: Branch "feature/999-new" does not exist
- **When**: branch_exists("feature/999-new") called
- **Then**: Returns 0

### Unit Tests: Tree Traversal Primitives (FR4.1-4.2)

**TC-T1: find_parent returns hashref**
- **Given**: Task 3.1.2 exists with parent 3.1
- **When**: find_parent("3.1.2", base_dir) called
- **Then**: Returns hashref with {num => "3.1", ...}

**TC-T2: find_parent top-level returns undef**
- **Given**: Task 33 is top-level (no parent)
- **When**: find_parent("33", base_dir) called
- **Then**: Returns undef

**TC-T3: find_children returns list of hashrefs**
- **Given**: Task 3.1 has children 3.1.1, 3.1.2
- **When**: find_children("3.1", base_dir) called
- **Then**: Returns list of 2 hashrefs, sorted by num

**TC-T4: find_children leaf task returns empty**
- **Given**: Task 3.1.2 has no children
- **When**: find_children("3.1.2", base_dir) called
- **Then**: Returns empty list ()

**TC-T5: find_children filters non-immediate children**
- **Given**: Tasks 3.1, 3.1.1, 3.1.1.1 exist
- **When**: find_children("3.1", base_dir) called
- **Then**: Returns only 3.1.1 (not 3.1.1.1)

### Unit Tests: Tree Traversal Composed (FR4.3-4.5)

**TC-C1: find_siblings excludes self**
- **Given**: Tasks 3.1.1, 3.1.2, 3.1.3 exist
- **When**: find_siblings("3.1.2", base_dir) called
- **Then**: Returns list with 3.1.1 and 3.1.3 (not 3.1.2)

**TC-C2: find_siblings top-level**
- **Given**: Tasks 1, 2, 33 exist at top-level
- **When**: find_siblings("33", base_dir) called
- **Then**: Returns list with 1, 2, ... (not 33)

**TC-C3: find_ancestors returns parent-to-root**
- **Given**: Task 3.1.2 with ancestors 3.1, 3
- **When**: find_ancestors("3.1.2", base_dir) called
- **Then**: Returns list [{num => "3.1", ...}, {num => "3", ...}]

**TC-C4: find_ancestors top-level returns empty**
- **Given**: Task 33 is top-level
- **When**: find_ancestors("33", base_dir) called
- **Then**: Returns empty list ()

**TC-C5: find_descendants depth-first pre-order**
- **Given**: Task tree: 3 → 3.1 → 3.1.1, 3 → 3.2
- **When**: find_descendants("3", base_dir) called
- **Then**: Returns list in order: 3.1, 3.1.1, 3.2

**TC-C6: find_descendants leaf returns empty**
- **Given**: Task 3.1.2 has no descendants
- **When**: find_descendants("3.1.2", base_dir) called
- **Then**: Returns empty list ()

### Unit Tests: Allocation Function (FR3.5)

**TC-A1: find_first_free next sibling**
- **Given**: Current task 33, tasks 1-33 exist
- **When**: find_first_free(0, "33", base_dir) called
- **Then**: Returns "34"

**TC-A2: find_first_free next child**
- **Given**: Current task 33, no children exist
- **When**: find_first_free(1, "33", base_dir) called
- **Then**: Returns "33.1"

**TC-A3: find_first_free uncle (parent's sibling)**
- **Given**: Current task 3.1.2 (depth 3)
- **When**: find_first_free(-1, "3.1.2", base_dir) called
- **Then**: Returns next sibling of parent "3.1" → "3.2" (or higher)

**TC-A4: find_first_free gap detection**
- **Given**: Tasks 1, 2, 4 exist (gap at 3)
- **When**: find_first_free(0, "2", base_dir) called
- **Then**: Returns "3" (fills gap)

**TC-A5: find_first_free depth too negative**
- **Given**: Current task 33 (depth 1)
- **When**: find_first_free(-5, "33", base_dir) called
- **Then**: Returns undef (can't go 5 levels up from depth 1)

### Integration Tests

**TC-I1: Composition pattern verification**
- **Given**: Task 3.1.2 with full hierarchy
- **When**: find_siblings("3.1.2") called
- **Then**: Verify it calls find_parent then find_children (check delegation)

**TC-I2: Delegation pattern verification**
- **Given**: Branch "feature/33-slug" exists
- **When**: resolve_branch("feature/33-slug") called
- **Then**: Verify it calls parse_branch then resolve_num (no duplicated logic)

**TC-I3: Optional base_dir consistency**
- **Given**: All functions called without base_dir
- **When**: Functions use find_base_dir() default
- **Then**: All functions use same calculated base_dir

**TC-I4: Real filesystem test fixture**
- **Given**: Sample task directories created (1, 1.1, 1.1.1, 2)
- **When**: Tree traversal functions called
- **Then**: Correct hierarchy detected, all hashrefs valid

### Regression Tests

**TC-REG1: Existing CIG commands unchanged**
- **Given**: Existing commands (cig-new-task, cig-status, etc.)
- **When**: Commands execute with new TaskPath.pm
- **Then**: All commands work without modification

**TC-REG2: resolve() backward compatibility**
- **Given**: Code using resolve() function
- **When**: resolve("33") called
- **Then**: Returns same result as before (no breaking changes)

**TC-REG3: hierarchy-resolver uses resolve**
- **Given**: hierarchy-resolver script
- **When**: Script calls resolve internally
- **Then**: Continues to work correctly

### Non-Functional Test Cases

**Performance Tests (NFR1)**
- **TC-P1: Resolution response time < 50ms**
  - **Given**: Task 33 exists
  - **When**: resolve_num("33") called 100 times
  - **Then**: Average response time < 50ms

- **TC-P2: find_descendants on large tree**
  - **Given**: Task tree with 100+ descendants
  - **When**: find_descendants(root) called
  - **Then**: Completes in reasonable time (< 500ms)

- **TC-P3: No caching overhead**
  - **Given**: Functions called with varying base_dir
  - **When**: base_dir parameter changes
  - **Then**: No stale cache issues (no caching implemented per design)

**Security Tests (NFR4)**
- **TC-S1: Path traversal protection**
  - **Given**: Malicious input "../../../etc/passwd"
  - **When**: resolve_num("../../../etc/passwd") called
  - **Then**: Input validation rejects (returns undef, no directory traversal)

- **TC-S2: No shell injection**
  - **Given**: Input with shell metacharacters "; rm -rf /"
  - **When**: Functions process input
  - **Then**: No shell command execution (safe regex parsing)

**Usability Tests (NFR2)**
- **TC-U1: Function name discoverability**
  - **Given**: Developer has task number
  - **When**: Looking for resolution function
  - **Then**: resolve_num name is clear and discoverable

- **TC-U2: Error messages clarity**
  - **Given**: Invalid input to parse functions
  - **When**: parse_dirname("invalid") called
  - **Then**: Returns empty list (caller handles error, no confusing exceptions)

- **TC-U3: Predicate usage pattern**
  - **Given**: Developer wants to check availability
  - **When**: Using `if (not task_exists($num))`
  - **Then**: Pattern is clear and idiomatic

**Reliability Tests (NFR5)**
- **TC-RL1: Graceful degradation no git**
  - **Given**: Not in git repository
  - **When**: Functions called without base_dir
  - **Then**: find_base_dir() falls back to relative paths or returns undef

- **TC-RL2: Missing directory handling**
  - **Given**: Task directory does not exist
  - **When**: resolve_num("999") called
  - **Then**: Returns undef (no die, no crash)

- **TC-RL3: Worktree compatibility**
  - **Given**: Separate git worktree
  - **When**: Functions use find_base_dir()
  - **Then**: Correctly detects worktree root/implementation-guide

## Test Environment

### Setup Requirements

**Test Data**:
- Sample task directory structure in test fixture:
  ```
  test-fixture/implementation-guide/
    1-feature-first-task/
    2-bugfix-second-task/
    1.1-chore-first-subtask/
    1.1.1-feature-deep-nesting/
    3-feature-has-children/
    3.1-chore-child-one/
    3.2-chore-child-two/
  ```
- Minimal workflow files (a-task-plan.md with Template Version header)
- Various task formats (v2.0, v2.1) for format detection testing

**Environment Dependencies**:
- Perl 5.x (existing CIG version)
- Git repository (for worktree testing, base_dir detection)
- Core Perl modules only (File::Basename, Cwd, File::Spec)

**Mock Services**:
- None required (library functions, no external services)
- Git commands may be mocked for base_dir fallback testing

### Automation

**Test Framework**: Perl Test::More
- Standard Perl testing framework
- TAP (Test Anything Protocol) output
- `prove` test runner for execution

**Test File Structure**:
```
.cig/tests/
  TaskPath/
    01-format.t          # Format functions unit tests
    02-resolution.t      # Orthogonal resolution tests
    03-predicates.t      # Existence predicate tests
    04-primitives.t      # Tree traversal primitives
    05-composed.t        # Tree traversal composed
    06-allocation.t      # find_first_free tests
    10-integration.t     # Integration tests
    20-regression.t      # Regression tests
    30-performance.t     # Performance tests
    40-security.t        # Security tests
```

**Test Execution**:
```bash
# Run all tests
prove -v .cig/tests/TaskPath/*.t

# Run specific test category
prove -v .cig/tests/TaskPath/01-format.t

# Coverage analysis
cover -test
```

**CI/CD Integration**:
- Add to existing CIG test suite
- Run on every commit to feature branch
- Block merge if tests fail
- Coverage report generated and archived

## Validation Criteria

### Test Execution
- [ ] All unit tests passing (100% pass rate)
- [ ] All integration tests passing
- [ ] All regression tests passing
- [ ] All acceptance criteria validated (AC1-AC6 from requirements)

### Coverage Metrics
- [ ] Overall code coverage ≥ 95%
- [ ] Critical path coverage = 100% (resolution, predicates, tree traversal)
- [ ] Edge case coverage comprehensive (invalid input, missing dirs, empty trees)
- [ ] All new functions covered by tests

### Performance Benchmarks
- [ ] Resolution functions < 50ms response time (NFR1)
- [ ] find_descendants on 100+ task tree < 500ms
- [ ] No performance regression vs baseline

### Security Validation
- [ ] Path traversal protection verified
- [ ] Shell injection protection verified
- [ ] Input validation prevents malicious input

### Regression Validation
- [ ] All existing CIG commands work unchanged
- [ ] hierarchy-resolver continues to work
- [ ] resolve() backward compatibility verified
- [ ] No breaking changes in existing APIs

### Code Quality
- [ ] All functions follow design patterns (delegation, composition, optional base_dir)
- [ ] Predicate naming convention followed (*_exists suffix)
- [ ] Error handling graceful (return undef, not die)
- [ ] POD documentation complete

## Status
**Status**: Finished
**Next Action**: Implementation execution (review existing code against plan) → `/cig-implementation-exec 33`
**Blockers**: None

**Note**: Comprehensive test plan defined. Implementation was done out-of-order, so testing execution will validate existing code against this plan.

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
