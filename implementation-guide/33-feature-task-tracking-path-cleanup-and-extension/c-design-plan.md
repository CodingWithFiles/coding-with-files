# task-tracking-path-cleanup-and-extension - Design

## Task Reference
- **Task ID**: internal-33
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/33-task-tracking-path-cleanup-and-extension
- **Template Version**: 2.1

## Goal
Define architecture and design decisions for task-tracking-path-cleanup-and-extension.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice
- **Decision**: Composition-based library with primitive and composed functions
- **Rationale**:
  - Tree traversal algorithms are well-understood and mechanical
  - DRY principle: build complex functions from simple primitives
  - Easier to test primitives in isolation
  - Reduces code duplication and maintenance burden
- **Trade-offs**:
  - Benefits: Clear separation of concerns, testable, maintainable
  - Drawbacks: Slight performance overhead from function composition (negligible for filesystem operations)

### Orthogonal API Design Principle
- **Decision**: Orthogonality in semantic namespace, not implementation
- **Rationale**:
  - Function names indicate input type for caller clarity (resolve_num vs resolve_branch vs resolve_path)
  - Clear, differentiated entry points based on what data caller has
  - Implementation shares code via delegation (DRY principle)
  - Single source of truth for core logic while providing discoverable API
- **Trade-offs**:
  - Benefits: Caller knows which function to use, maintainable (change logic in one place), discoverable API
  - Drawbacks: Slight function call overhead (negligible), more functions in namespace

### Optional base_dir Parameter Convention
- **Decision**: All functions accepting base_dir make it optional with smart defaults
- **Default calculation**:
  ```perl
  $base_dir //= find_base_dir();  # Uses //= operator for undef check
  ```
- **find_base_dir() logic**:
  1. Try `git rev-parse --show-toplevel`/implementation-guide (worktree-aware)
  2. Fall back to relative path search (../implementation-guide, ../../implementation-guide)
  3. Return undef if not found (graceful degradation)
- **Rationale**:
  - Caller convenience: most calls use current working directory context
  - Explicit override: caller can specify base_dir when needed (testing, multi-repo)
  - Fail gracefully: functions return undef rather than die on missing base_dir
- **Trade-offs**:
  - Benefits: Ergonomic API, works in worktrees/submodules automatically
  - Drawbacks: Implicit git dependency (mitigated by graceful fallback)

### Technology Stack
- **Language**: Perl 5 (existing CIG codebase)
- **Module**: TaskPath.pm (Perl library module)
- **Testing**: Perl Test::More framework
- **Dependencies**: Minimal - only core Perl modules

## System Design

### Component Overview

**Design Philosophy**: Return rich data structures (hashrefs), use functional composition (map, grep), leverage Perl's list flattening.

**Primitive Functions** (require actual implementation):
- **find_parent($num, $base_dir)**: Parse parent number + resolve_num
  - Returns hashref with full task metadata
  - Enables chaining: `find_parent($num)->{type}`
  - Foundation for find_ancestors

- **find_children($num, $base_dir)**: Filesystem scan + resolve_num for each
  - Returns list of hashrefs (full task metadata)
  - Enables filtering: `grep { $_->{type} eq 'feature' } find_children($num)`
  - Foundation for find_siblings and find_descendants

**Composed Functions** (functional composition):
- **find_siblings($num, $base_dir)**:
  ```perl
  grep { $_->{num} ne $num } find_children(find_parent($num)->{num}, $base_dir)
  ```

- **find_ancestors($num, $base_dir)**:
  ```perl
  my @ancestors;
  my $current = find_parent($num, $base_dir);
  while ($current) {
      push @ancestors, $current;
      $current = find_parent($current->{num}, $base_dir);
  }
  return @ancestors;
  ```

- **find_descendants($num, $base_dir)**:
  ```perl
  my @children = find_children($num, $base_dir);
  return (
      @children,
      map { find_descendants($_->{num}, $base_dir) } @children
  );
  ```

**Resolution Functions** (orthogonal API, shared implementation):

*Design principle: Orthogonality is in the semantic namespace (API), not implementation. Functions have distinct, clear names based on input type, but share code underneath.*

- **resolve_num($num, $base_dir)**: Core resolution - find task by number
  - Primary implementation function
  - All other resolve_* functions delegate to this

- **resolve_branch($branch, $base_dir)**: Resolve from git branch name
  - Parse branch using parse_branch → extract num
  - Delegate to resolve_num for core resolution
  - Semantic clarity: "I have a branch name"

- **resolve_path($path, $base_dir)**: Resolve from filesystem dirname/path
  - Parse dirname using parse_dirname → extract num
  - Delegate to resolve_num for core resolution
  - Semantic clarity: "I have a filesystem path"

- **resolve()**: Backward compatibility alias for resolve_num

**Rationale**: Orthogonal naming provides caller clarity (function name matches input type) while implementation sharing (delegation to resolve_num) maintains DRY principle and single source of truth for resolution logic.

**Format Functions** (new):
- **format_dirname($num, $type, $slug)**: Build directory name
- **parse_dirname($dirname)**: Parse directory name
- **format_branch($num, $type, $slug)**: Build git branch name
- **parse_branch($branch)**: Parse git branch name

**Existence Predicates** (new):
- **task_exists($num, $base_dir)**: Check if task directory exists
  - Use negatively for availability: `if not task_exists($num)` means available
  - base_dir optional, defaults to git root/implementation-guide

- **branch_exists($branch)**: Check if branch exists
  - Use negatively for availability: `if not branch_exists($branch)` means available

**Allocation Functions** (new):
- **find_first_free($depth, $num)**: Find next available task number at relative depth
  - Uses task_exists internally to check availability

### Function Composition Diagram

```
Primitives (return hashrefs):
    find_parent($num) → hashref | undef
    find_children($num) → list of hashrefs

Composed (using map/grep):
    find_ancestors($num) → iterate find_parent, collect hashrefs
    find_siblings($num) → grep { $_->{num} ne $num } find_children(find_parent($num)->{num})
    find_descendants($num) → recursive: @children + map { descend } @children

Callers extract what they need:
    map { $_->{num} } find_children($num)        # Just numbers
    map { $_->{type} } find_ancestors($num)      # Just types
    grep { $_->{type} eq 'feature' } find_*()    # Filter by metadata
```

### Data Flow

**Task Resolution Flow**:
1. User provides task number → resolve_num
2. resolve_num scans filesystem → returns hashref with metadata
3. Metadata includes depth, parent_path, format version

**Tree Traversal Flow**:
1. Caller requests tree operation (find_siblings, find_ancestors, etc.)
2. Function delegates to primitives (find_parent or find_children)
3. Primitives return raw data
4. Composed function processes and returns result

**Task Allocation Flow**:
1. Caller requests next free task at relative depth
2. find_first_free resolves anchor task (from stack or $num parameter)
3. Calculates target level using depth arithmetic
4. Scans filesystem for existing tasks at that level
5. Returns first available number in sequence

## Interface Design

### Core Function Signatures

**Resolution Functions**:
```perl
resolve_num($num, $base_dir) → hashref { full_path, num, type, slug, format, parent_path, depth }
resolve_path($dir) → hashref { full_path, num, type, slug, format, parent_path, depth }
resolve_branch($branch, $base_dir) → hashref (same structure)
```

**Format Functions**:
```perl
format_dirname($num, $type, $slug) → string "num-type-slug"
parse_dirname($dirname) → list ($num, $type, $slug) | undef
format_branch($num, $type, $slug) → string "type/num-slug"
parse_branch($branch) → list ($num, $type, $slug) | undef
```

**Tree Traversal Functions** (all return hashrefs with full task metadata):
```perl
find_parent($num, $base_dir) → hashref | undef
find_children($num, $base_dir) → list of hashrefs
find_siblings($num, $base_dir) → list of hashrefs
find_ancestors($num, $base_dir) → list of hashrefs
find_descendants($num, $base_dir) → list of hashrefs

# Hashref structure (same as resolve_num):
{
    full_path   => "/path/to/implementation-guide/num-type-slug",
    num         => "task.number",
    type        => "feature|bugfix|hotfix|chore",
    slug        => "descriptive-slug",
    format      => "2.0|2.1",
    parent_path => "/parent/path" | undef,
    depth       => integer
}

# Usage examples (functional style):
my @nums = map { $_->{num} } find_children("3.1");
my @features = grep { $_->{type} eq 'feature' } find_descendants("1");
my $parent_type = find_parent("3.1.2")->{type};
```

**Existence Predicates**:
```perl
task_exists($num, $base_dir) → boolean (1 = exists, 0 = not found)
branch_exists($branch) → boolean (1 = exists, 0 = not found)

# Usage for availability checks (use negatively):
if (not task_exists($num)) {
    # Number available for creation
}

if (not branch_exists($branch)) {
    # Branch name available for creation
}
```

**Allocation Functions**:
```perl
find_first_free($depth, $num) → string | undef
```

### Error Handling

- Invalid input: return undef or empty list
- Missing filesystem: return undef (graceful degradation)
- Invalid depth calculation: return undef with warning
- No anchor task: return undef

## Constraints

**Technical Constraints**:
- Must work in main worktree, git worktrees, and submodules
- Must handle v2.0 (flat) and v2.1 (hierarchical) task formats
- Must be backwards compatible with existing resolve_* functions

**Performance Considerations**:
- Filesystem scans (glob, readdir) are the primary cost
- find_descendants is O(n) where n = total tasks in subtree
- find_first_free scans only one level (O(siblings) not O(total tasks))
- git commands (~2-5ms each) are negligible compared to filesystem I/O
- Design prioritizes simplicity over premature optimization

**Security Requirements**:
- Validate all path inputs to prevent directory traversal
- Use git commands for base_dir detection (trusted source)
- No shell interpolation of user input

## Validation
- [ ] Design review completed
- [ ] Architecture approved by team
- [ ] Integration points verified

## Status
**Status**: Backlog
**Next Action**: Begin implementation planning
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
