# add-task-stack-script - Design

## Task Reference
- **Task ID**: internal-34
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/34-add-task-stack-script
- **Template Version**: 2.1

## Goal
Define architecture for file-based task stack with atomic operations, self-documenting output, and optional Task 32 integration.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice
- **Decision**: File-based LIFO stack with Perl script operations
- **Rationale**:
  - Simple: Single text file (`.cig/task-stack`), one dirname per line
  - Transparent: Human-readable format, easy to debug
  - Portable: Works anywhere git repo exists, no server/database needed
  - Atomic: Perl's `flock()` provides file-level locking
  - Testable: Operations invocable via command line, no complex setup
- **Trade-offs**:
  - ✅ Benefits: Simplicity, transparency, no dependencies, easy testing
  - ❌ Drawbacks: No concurrent multi-user support (workspace-specific by design)
  - ❌ Drawbacks: Manual cleanup required (no auto-expiry)
  - Decision: Acceptable for user-specific workspace state

### Technology Stack
- **Script**: Perl 5.x with core modules (Fcntl, FindBin)
  - Rationale: Matches existing CIG helper scripts, no external dependencies
- **Storage**: Plain text file, newline-delimited
  - Rationale: Grep-able, scriptable, version control friendly
- **Locking**: `flock(LOCK_EX)` for exclusive access
  - Rationale: Prevents race conditions, standard Unix file locking
- **Integration**: CIG::TaskPath module (Task 33)
  - Rationale: Reuses existing dirname format functions

### Output Format Design
- **Decision**: Self-documenting multi-line format
- **Structure**:
  ```
  {rel_path}/task-stack: {operation} (use --help for options)
  {rel_path}/task-stack: showing N of M total tasks, most recent last
  34-feature-add-task-stack-script
  33-feature-task-tracking-path-cleanup-and-extension
  ```
- **Rationale**:
  - Line 1: Teaches agent script location + discovery mechanism
  - Line 2: Human-readable metadata (count, order)
  - Lines 3+: Raw dirnames for scripting (`tail -n 1` gets current)
- **Trade-offs**:
  - ✅ Self-documenting for agents and humans
  - ✅ Scriptable (tail/head/grep work)
  - ❌ Slightly more complex parsing than single-line output
  - Decision: Educational value outweighs parsing complexity

## System Design

### Component Overview

**1. Core Stack Script** (`.cig/scripts/command-helpers/task-stack`)
- **Responsibility**: Atomic file operations on `.cig/task-stack`
- **Operations**: push, pop, peek, list, clear, size
- **Key Functions**:
  - `push_task($task_num)`: Resolve → format → append with lock
  - `pop_task()`: Read → remove last → truncate → return
  - `peek_stack()`: Read → return last line
  - `list_stack()`: Read → format output with metadata
  - `clear_stack()`: Delete file (idempotent)
  - `get_size()`: Count lines
  - `get_script_rel_path()`: Calculate relative path for output

**2. User Skill** (`.claude/skills/cig-current-task/SKILL.md`)
- **Responsibility**: User-friendly wrapper around task-stack script
- **Interface**: Parse arguments → delegate to script → display output
- **Operations**:
  - No args → `task-stack list`
  - `push <num>` → `task-stack push <num>`
  - `pop` → `task-stack pop`
  - `clear` → `task-stack clear`

**3. Security Hook** (`.claude/CLAUDE.md` or plugin hooks)
- **Responsibility**: Advisory protection against direct file editing
- **Trigger**: PreToolUse with Edit/Write to `.cig/task-stack`
- **Action**: Block + explain + suggest `/cig-current-task` instead
- **Note**: Advisory only (script validates format on read)

**4. Inference Integration** (Task 32 `TaskContextInference.pm`)
- **Responsibility**: Read stack as high-confidence signal
- **Integration Point**: `read_state_signal()` function
- **Process**: Read file → parse last 5 dirnames → extract task numbers
- **Output**: Primary candidate (top) + context (all 5) + score 100

**5. Initialization Integration** (`/cig-init` skill)
- **Responsibility**: Add `.cig/task-stack` to `.gitignore` during setup
- **Action**: Check if entry exists, add if missing
- **Rationale**: User-specific workspace state, not shared via git

### Data Flow

**Push Operation**:
```
User: /cig-current-task push 34
  ↓
Skill: Parse args → delegate
  ↓
Script: task-stack push 34
  ↓
resolve_num(34) → {num: 34, type: feature, slug: add-task-stack-script}
  ↓
format_dirname() → "34-feature-add-task-stack-script"
  ↓
open(O_APPEND) + flock(LOCK_EX)
  ↓
write "34-feature-add-task-stack-script\n"
  ↓
close + release lock
  ↓
Output: ".cig/scripts/.../task-stack: pushed 34-feature-add-task-stack-script"
```

**Pop Operation**:
```
User: /cig-current-task pop
  ↓
Skill: Parse args → delegate
  ↓
Script: task-stack pop
  ↓
open(O_RDWR) + flock(LOCK_EX)
  ↓
read all lines → @lines
  ↓
pop @lines → $popped = "34-feature-add-task-stack-script"
  ↓
seek(0, SEEK_SET) + truncate(0)
  ↓
write remaining @lines
  ↓
close + release lock
  ↓
parse_dirname($popped) → {num: 34, type: feature, slug: ...}
  ↓
Output: ".cig/scripts/.../task-stack: popped 34-feature-add-task-stack-script"
```

**List Operation**:
```
User: /cig-current-task
  ↓
Skill: No args → task-stack list
  ↓
Script: task-stack list
  ↓
git rev-parse --show-toplevel → calculate relative path
  ↓
read .cig/task-stack → @lines
  ↓
count total → get last 5 → format output:
  Line 1: {rel_path}/task-stack: list task stack (use --help for options)
  Line 2: {rel_path}/task-stack: showing 5 of 8 total tasks, most recent last
  Lines 3-7: Raw dirnames (oldest → newest)
  ↓
Output to stdout (scriptable with tail -n 1)
```

**Inference Integration**:
```
Task 32: infer_task_context()
  ↓
read_state_signal()
  ↓
Check if .cig/task-stack exists
  ↓
Read file → get last 5 lines
  ↓
For each line: parse_dirname() → extract task_num
  ↓
Return {
  primary: "34" (top of stack),
  context: ["30", "31", "32", "33", "34"],
  score: 100,
  source: "state_file"
}
  ↓
Task 32 correlates with other signals
```

## Interface Design

### Script Operations (task-stack)

**Command-Line Interface**:
```bash
task-stack push <task-num>    # Push task onto stack
task-stack pop                # Pop task from stack
task-stack peek               # Show current task
task-stack list               # Show last 5 tasks with metadata
task-stack clear              # Empty stack
task-stack size               # Return count only
```

**Exit Codes**:
- `0`: Success
- `1`: Operational error (empty stack, task not found)
- `2`: Usage error (invalid arguments)

**Output Formats**:

*Push*:
```
.cig/scripts/command-helpers/task-stack: pushed 34-feature-add-task-stack-script
```

*Pop*:
```
.cig/scripts/command-helpers/task-stack: popped 34-feature-add-task-stack-script
```

*Peek*:
```
34-feature-add-task-stack-script
```

*List*:
```
.cig/scripts/command-helpers/task-stack: list task stack (use --help for options)
.cig/scripts/command-helpers/task-stack: showing 3 of 3 total tasks, most recent last
32-feature-task-tracking-using-inference-scoring
33-feature-task-tracking-path-cleanup-and-extension
34-feature-add-task-stack-script
```

*Size*:
```
3
```

### Skill Interface (/cig-current-task)

**User-Facing Commands**:
```bash
/cig-current-task              # Show stack (→ task-stack list)
/cig-current-task push 34      # Push task (→ task-stack push 34)
/cig-current-task pop          # Pop task (→ task-stack pop)
/cig-current-task clear        # Clear stack (→ task-stack clear)
```

**Implementation**: Skill parses arguments and delegates to script, displays output.

### File Format (.cig/task-stack)

**Format**: Plain text, one dirname per line
```
32-feature-task-tracking-using-inference-scoring
33-feature-task-tracking-path-cleanup-and-extension
34-feature-add-task-stack-script
```

**Properties**:
- No header/footer (just dirnames)
- Newline-delimited
- Last line is most recent (top of stack)
- Empty file or missing file = empty stack

### CIG::TaskPath Integration

**Used Functions**:
```perl
use CIG::TaskPath qw(resolve_num format_dirname parse_dirname);

# Push: task number → dirname
my $info = resolve_num($task_num);
my $dirname = format_dirname(
    num  => $info->{num},
    type => $info->{type},
    slug => $info->{slug}
);

# Display: dirname → parsed info
my $info = parse_dirname($dirname);
# Returns: {num => "34", type => "feature", slug => "add-task-stack-script"}
```

## Constraints

### Technical Constraints
- **Perl flock limitations**: Not all filesystems support flock (NFS issues)
  - Mitigation: Document requirement, test on common filesystems
- **Concurrent access**: flock is process-level, not thread-level
  - Mitigation: Single-threaded script design (Perl default)
- **File size**: No built-in limit, could grow unbounded
  - Mitigation: Display limited to last 5, manual cleanup responsibility

### Integration Constraints
- **Task 33 dependency**: Must load CIG::TaskPath module
  - Mitigation: `use lib "$FindBin::Bin/../../lib"` for module path
- **Git dependency**: Relative path calculation needs git
  - Mitigation: Fallback to script name if git unavailable
- **Task 32 modification required**: Currently references `.cig/current-task`, must update to `.cig/task-stack`
  - Files to update: task-context-inference script header comment, TaskContextInference.pm if applicable
  - Mitigation: Update references atomically with Task 34 implementation
- **Backward compatibility**: Task 32 must work without stack
  - Mitigation: Inference checks file existence, gracefully handles absence

### Performance Constraints
- **File I/O on every operation**: Read/write entire file
  - Impact: < 100ms target for 1000 entries (measured in testing)
  - Mitigation: Typical usage <100 entries, acceptable performance

## Validation

### Design Review
- [x] Architecture satisfies all functional requirements (FR1-FR10)
- [x] Non-functional requirements addressed (NFR1-NFR5)
- [x] Design priorities applied (Testability first - CLI invocable)
- [x] Architecture preferences followed (Composition - script + skill + hook)
- [x] Constraints documented and mitigated

### Integration Verification
- [x] Task 33 (CIG::TaskPath) provides required functions
- [x] Task 32 (inference) integration point identified
- [x] Skill system supports thin wrapper pattern
- [x] PreToolUse hook mechanism available (advisory)

### Trade-off Analysis
| Decision | Benefit | Cost | Justification |
|----------|---------|------|---------------|
| File-based storage | Simple, transparent, no deps | No multi-user | Workspace-specific by design |
| Self-documenting output | Agent learning, human-readable | Parsing complexity | Educational value worth it |
| flock for atomicity | Prevents corruption | NFS limitations | Standard Unix approach |
| Dirname format storage | Full context preserved | Slightly larger | Context worth the bytes |
| Optional Task 32 integration | Works standalone | More integration testing | Flexibility important |

## Status
**Status**: Finished
**Next Action**: Proceed to implementation planning → `/cig-implementation-plan 34`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
