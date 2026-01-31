# task-tracking-path-cleanup-and-extension - Requirements

## Task Reference
- **Task ID**: internal-33
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/33-task-tracking-path-cleanup-and-extension
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for extending CIG::TaskPath with orthogonal resolution, lifecycle validation, and format conversion functions.

## Functional Requirements

### Orthogonal Resolution Functions (FR1)
Three resolution functions that accept different input types but return identical output structure:

**FR1.1 - resolve_num($num, $base_dir)**
- **Input**: Task number ("32", "32.1"), optional base_dir
- **Output**: Hashref {full_path, num, type, slug, format, parent_path, depth} or undef
- **Acceptance**: Resolves task by number, defaults base_dir to git root

**FR1.2 - resolve_branch($branch, $base_dir)**
- **Input**: Git branch name ("feature/32-slug"), optional base_dir
- **Output**: Same hashref structure as resolve_num or undef
- **Acceptance**: Parses branch format, validates type/slug match, returns metadata

**FR1.3 - resolve_path($path, $base_dir)**
- **Input**: Filesystem dirname ("32-feature-slug") or full path, optional base_dir
- **Output**: Same hashref structure as resolve_num or undef
- **Acceptance**: Parses dirname format, validates directory exists, returns metadata

**FR1.4 - resolve() as backward compatibility alias**
- **Input**: Same as resolve_num
- **Output**: Same as resolve_num
- **Acceptance**: Existing code using resolve() continues to work unchanged

### Lifecycle-Aware Validation Functions (FR2)

**FR2.1 - validate_exists($num, $base_dir)**
- **Input**: Task number, optional base_dir
- **Output**: Boolean (1 if task directory exists, 0 if not)
- **Acceptance**: Returns true only when task directory exists at expected location

**FR2.2 - validate_free($num, $base_dir)**
- **Input**: Task number, optional base_dir
- **Output**: Boolean (1 if task number available, 0 if taken)
- **Acceptance**: Returns true only when task number can be used for creation

**FR2.3 - validate_branch_exists($branch)**
- **Input**: Git branch name
- **Output**: Boolean (1 if branch exists in current worktree, 0 if not)
- **Acceptance**: Uses git rev-parse to check branch existence

**FR2.4 - validate_branch_free($branch)**
- **Input**: Git branch name
- **Output**: Boolean (1 if branch name available, 0 if taken)
- **Acceptance**: Returns true only when branch name can be used for creation

### Format Converter Functions (FR3)

**FR3.1 - format_dirname($num, $type, $slug)**
- **Input**: Task number, type, slug
- **Output**: String in format "num-type-slug"
- **Acceptance**: Returns "32-feature-task-tracking" for inputs (32, feature, task-tracking)

**FR3.2 - parse_dirname($dirname)**
- **Input**: Directory name string
- **Output**: List (num, type, slug) or undef if invalid
- **Acceptance**: Parses "32-feature-slug" → (32, feature, slug), returns undef for invalid format

**FR3.3 - format_branch($num, $type, $slug)**
- **Input**: Task number, type, slug
- **Output**: String in format "type/num-slug"
- **Acceptance**: Returns "feature/32-task-tracking" for inputs (32, feature, task-tracking)

**FR3.4 - parse_branch($branch)**
- **Input**: Git branch name string
- **Output**: List (num, type, slug) or undef if invalid
- **Acceptance**: Parses "feature/32-slug" → (32, feature, slug), returns undef for invalid format

**FR3.5 - find_first_free($depth, $num)**
- **Input**: Relative depth from current/specified task, optional task number
- **Output**: String representing next available task number
- **Behaviour**:
  - If $num provided, use as anchor; otherwise use current task from stack
  - $depth is relative: 0 = sibling, 1 = child, -1 = parent's sibling (uncle), -2 = grandparent's sibling
  - For next top-level task: caller computes `find_first_free(1 - $current->{depth}, $num)`
    - From depth 1 (top-level): 1-1=0 (next sibling, also top-level)
    - From depth 2: 1-2=-1 (uncle = parent's sibling = top-level)
    - From depth 3: 1-3=-2 (grand-uncle = top-level)
  - Returns undef if: no anchor available, negative depth exceeds hierarchy, invalid parameters
- **Acceptance**:
  - Current task 3.1.2 (depth 3): `find_first_free(0)` → "3.1.3", `find_first_free(1)` → "3.1.2.1", `find_first_free(-1)` → "3.2"
  - Explicit anchor: `find_first_free(1, "3")` → "3.1"
  - Next top-level from 33 (depth 1): `find_first_free(0, "33")` → "34"

### Tree Traversal Functions (FR4)

These functions provide standard tree navigation using Perl's functional programming strengths. All functions return hashrefs (same structure as resolve_num) for composability and rich metadata access.

**Return Structure** (all functions):
```perl
{
    full_path   => "/path/to/implementation-guide/num-type-slug",
    num         => "task.number",
    type        => "feature|bugfix|hotfix|chore",
    slug        => "descriptive-slug",
    format      => "2.0|2.1",
    parent_path => "/parent/path" | undef,
    depth       => integer
}
```

**Implementation Strategy**:
- **Primitives**: find_parent (string + resolve), find_children (filesystem + resolve)
- **Composed**: Use map, grep, list flattening for functional composition
- **Flexibility**: Caller extracts needed fields: `map { $_->{num} } find_children(...)`

**FR4.1 - find_parent($num, $base_dir)**
- **Input**: Task number string, optional base directory
- **Output**: Hashref for parent task, or undef if top-level
- **Implementation**: Parse parent number from string, call resolve_num
- **Acceptance**:
  - "3.1.2" → `{ num => "3.1", type => "feature", depth => 2, ... }`
  - "3" → undef

**FR4.2 - find_children($num, $base_dir)**
- **Input**: Task number, optional base directory
- **Output**: List of hashrefs for direct children (sorted by num)
- **Implementation**: Scan filesystem for "$num.\d+" pattern, resolve each
- **Acceptance**:
  - "3.1" → `({ num => "3.1.1", ... }, { num => "3.1.2", ... }, { num => "3.1.3", ... })`
  - "3.1.2" with no children → `()`

**FR4.3 - find_siblings($num, $base_dir)**
- **Input**: Task number, optional base directory
- **Output**: List of hashrefs for siblings (excluding self, sorted by num)
- **Implementation**: `grep { $_->{num} ne $num } find_children(find_parent($num)->{num})`
- **Acceptance**:
  - "3.1.2" → `({ num => "3.1.1", ... }, { num => "3.1.3", ... })`
  - Top-level "3" → `({ num => "1", ... }, { num => "2", ... }, { num => "4", ... }, ...)`

**FR4.4 - find_ancestors($num, $base_dir)**
- **Input**: Task number string, optional base directory
- **Output**: List of hashrefs from immediate parent to root
- **Implementation**: Iteratively call find_parent, collect results until undef
- **Acceptance**:
  - "3.1.2" → `({ num => "3.1", depth => 2, ... }, { num => "3", depth => 1, ... })`
  - "3" → `()`

**FR4.5 - find_descendants($num, $base_dir)**
- **Input**: Task number, optional base directory
- **Output**: List of hashrefs for all descendants (depth-first pre-order)
- **Implementation**: `my @c = find_children($num); return (@c, map { find_descendants($_->{num}) } @c);`
- **Acceptance**:
  - "3" with tree → `({ num => "3.1", ... }, { num => "3.1.1", ... }, { num => "3.2", ... })`
  - Leaf task → `()`

### Worktree-Aware Base Directory (FR5)
- **FR5.1**: When base_dir parameter omitted, all functions default to `git rev-parse --show-toplevel`/implementation-guide
- **FR5.2**: Base directory detection works in main worktree, separate worktrees, and submodules
- **FR5.3**: Functions fall back gracefully if git command fails (not in git repo)

### User Stories
- **As a** workflow command **I want** to resolve tasks by number **so that** I can find task directories from user input
- **As a** signal collector **I want** to resolve tasks from git branches **so that** I can infer current task from branch name
- **As a** state file reader **I want** to resolve tasks from filesystem format **so that** I can validate entries in .git/cig-current-task
- **As a** task creation command **I want** lifecycle validation **so that** I can check if task numbers/branches are available before creating
- **As a** format converter **I want** bidirectional parsing **so that** I can convert between filesystem and git branch formats

## Non-Functional Requirements

### Performance (NFR1)
- **Response time**: < 50ms for resolution functions (typical case)
- **File system operations**: Minimize disk I/O - resolve functions should read metadata, not file contents
- **Regex efficiency**: Parsing functions use pre-compiled patterns for O(1) lookup
- **No external process spawns**: Format converters are pure Perl (except git commands for base_dir)

### Usability (NFR2)
- **Learning curve**: Function names indicate input type (resolve_num vs resolve_branch vs resolve_path)
- **Error recovery**: parse_* functions return undef (not die) - caller decides error handling
- **Consistency**: All resolve_* functions return identical hashref structure
- **API discoverability**: Export tags group related functions (resolution, validation, formatting)

### Maintainability (NFR3)
- **Code clarity**: Orthogonal function names avoid ambiguity
- **Modularity**: Resolution, validation, and formatting are separate concerns with clear boundaries
- **Testability**: Pure functions (no side effects) - easy to unit test with mock inputs
- **Documentation**: POD documentation for each function with examples
- **DRY principle**: resolve_branch and resolve_path call resolve_num internally

### Security (NFR4)
- **Input validation**: All parsing functions validate format before processing
- **No code injection**: Regex patterns use \Q..\E quoting where needed
- **Path traversal protection**: Base directory validation prevents ../.. attacks
- **Git command safety**: Shell command escaping for git operations

### Reliability (NFR5)
- **Graceful degradation**: If git command fails, functions return undef (not crash)
- **Error handling**: All file system operations check return values
- **Data integrity**: Resolution validates directory exists before returning metadata
- **Backward compatibility**: Existing code using resolve() continues to work
- **Worktree safety**: Base directory detection works across all worktree configurations

## Constraints
- **Perl 5.x compatibility**: Must work with existing CIG Perl version (no modern Perl features)
- **No external dependencies**: Only core Perl modules (File::Spec, File::Basename, Cwd)
- **Backward compatibility**: Cannot change existing function signatures or return values
- **Filesystem as ground truth**: Directory existence is authoritative source of truth
- **Git dependency**: Functions requiring worktree detection need git commands (fail gracefully if unavailable)
- **No breaking changes**: All existing CIG commands must continue to work without modification

## Acceptance Criteria

### Orthogonal Resolution (AC1)
- [ ] resolve_num("32") returns hashref with full_path, num, type, slug, format, parent_path, depth
- [ ] resolve_branch("feature/32-slug") returns identical structure to resolve_num("32")
- [ ] resolve_path("32-feature-slug") returns identical structure to resolve_num("32")
- [ ] resolve("32") works as alias for resolve_num("32") - backward compatibility maintained
- [ ] All three functions return undef for non-existent tasks

### Base Directory Defaults (AC2)
- [ ] resolve_num("32") without base_dir uses git rev-parse --show-toplevel/implementation-guide
- [ ] Works correctly in main worktree (returns main repo path)
- [ ] Works correctly in separate worktree (returns worktree path)
- [ ] Falls back gracefully when not in git repo (uses relative path or returns undef)

### Lifecycle Validation (AC3)
- [ ] validate_exists("32") returns 1 when task directory exists, 0 when not
- [ ] validate_free("32") returns 1 when task number available, 0 when taken
- [ ] validate_branch_exists("feature/32-slug") checks current worktree's branches
- [ ] validate_branch_free("feature/32-slug") returns inverse of validate_branch_exists

### Format Converters (AC4)
- [ ] format_dirname(32, "feature", "slug") returns "32-feature-slug"
- [ ] parse_dirname("32-feature-slug") returns (32, "feature", "slug")
- [ ] format_branch(32, "feature", "slug") returns "feature/32-slug"
- [ ] parse_branch("feature/32-slug") returns (32, "feature", "slug")
- [ ] parse_* functions return undef for invalid formats (not die)

### Edge Cases (AC5)
- [ ] Nested task numbers work: "1.1", "1.1.1", "12.3.4"
- [ ] Slugs with hyphens parse correctly: "32-feature-fix-nested-slug-parsing"
- [ ] Invalid formats rejected: parse_dirname("invalid") returns undef
- [ ] Missing directories detected: resolve_num("999") returns undef
- [ ] Branch format variations handled: "feature/32-slug", "bugfix/1.1-slug"

### Integration (AC6)
- [ ] All existing CIG commands work without modification
- [ ] hierarchy-resolver continues to work (uses resolve internally)
- [ ] task-context-inference can use resolve_branch for branch signal
- [ ] Future /cig-current command can use resolve_path for state file validation

## Status
**Status**: In Progress
**Next Action**: Begin design phase - `/cig-design-plan 33`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
