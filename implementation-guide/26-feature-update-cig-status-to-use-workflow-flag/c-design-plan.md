# Update cig-status to Use --workflow Flag - Design

## Task Reference
- **Task ID**: internal-26
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/26-update-cig-status-to-use-workflow-flag
- **Template Version**: 2.0

## Goal
Define the architecture for implementing intelligent default behavior in status-aggregator script (automatic workflow mode for task queries, automatic 5-task limit for overview) while providing explicit flag controls (--workflow, --no-workflow, --limit) to override defaults. This avoids complex conditionals in the command file and prevents Claude Code permission issues.

## Design Priorities
Following CIG system design priorities:
1. **Testability** → Simple pass-through design, easy to verify with test calls
2. **Readability** → Single-line change, immediately obvious what it does
3. **Consistency** → Matches existing argument forwarding pattern in other commands
4. **Simplicity** → No new logic, just enable existing functionality
5. **Reversibility** → Trivial to revert if needed (single line change)

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Architecture Choice
- **Decision**: Intelligent Defaults in status-aggregator Script with Explicit Flag Controls
- **Rationale**:
  - The status-aggregator script detects context (task path vs no arguments) and applies intelligent defaults
  - When task path provided: Automatically enable workflow mode (default: --workflow)
  - When no arguments: Automatically enable sorted mode with 5-task limit (default: --sort=modified --limit=5)
  - Explicit flags (--workflow, --no-workflow, --limit=N) override defaults ("tools, not philosophies")
  - Command file remains simple: just `status-aggregator $ARGUMENTS` (no conditionals)
  - All intelligence lives in status-aggregator where it belongs (single source of truth)
- **Trade-offs**:
  - ✅ **Pro**: No complex conditionals in command file (avoids Claude Code permission issues)
  - ✅ **Pro**: Simple command invocation (single line, no if/then/else)
  - ✅ **Pro**: Prevents information overload (5 task limit when no argument)
  - ✅ **Pro**: Detailed workflow view when user wants specific task
  - ✅ **Pro**: Explicit flags provide full control (--no-workflow to disable defaults)
  - ✅ **Pro**: Version detection still handled by trampoline (automatic)
  - ✅ **Pro**: Follows "tools, not philosophies" - provide controls, don't force behavior
  - ✅ **Pro**: Script implements limiting internally (more efficient than piping to head)
  - ⚠️ **Con**: Requires modifying status-aggregator script (not just command file)
  - ⚠️ **Con**: More script logic complexity (but centralized, testable)

### Alternatives Considered
1. **Conditional logic in command file**
   - Rejected: Causes Claude Code permission issues with complex bash conditionals
   - Rejected: Violates NFR3 (maintainability - conditional logic in command)
2. **Wrapper script between command and status-aggregator**
   - Rejected: Adds unnecessary layer; status-aggregator can handle this directly
3. **Always use --workflow flag**
   - Rejected: User requirement - too verbose for 100+ tasks
4. **Parse and transform output**
   - Rejected: Violates NFR3 (maintainability), duplicates logic
5. **New user flag** (e.g., `/cig-status --recent`)
   - Rejected: Requirements specify automatic behavior, no extra flags

### Technology Stack
- **Command Layer**: `.claude/commands/cig-status.md` (existing command file)
- **Helper Script**: `status-aggregator` (trampoline entry point, existing)
- **Implementation**: `status-aggregator-v2.1` (orchestration script, existing)
- **No new components required**: Purely configuration change

## System Design
### Component Overview
- **cig-status.md Command File**: Thin wrapper that invokes status-aggregator and forwards user arguments. Responsibility: Argument forwarding and script invocation only. No conditional logic.
- **status-aggregator Script**: Trampoline entry point that detects context and applies intelligent defaults. Responsibility: Argument parsing, default behavior detection, version detection, routing to version-specific implementation.
- **status-aggregator-v2.0/v2.1**: Version-specific implementations. Responsibility: Tree generation, workflow breakdown, sorting, limiting output.

### Data Flow

**Path A: With Task Argument** (`/cig-status 26`)
```
User invokes: /cig-status 26
              ↓
cig-status.md (line 8 context call)
  - Forwards: status-aggregator 26 (no conditional logic)
              ↓
status-aggregator (trampoline entry point)
  - Detects: Task path "26" provided, no explicit flags
  - Applies default: --workflow (intelligent default for task queries)
  - Detects task 26 format version → v2.1
  - Execs: status-aggregator-v2.1 --workflow 26
              ↓
status-aggregator-v2.1
  - Parses --workflow flag
  - Generates tree view for task 26 and descendants
  - Generates workflow file breakdown for task 26
              ↓
Markdown output returned to user
  - Tree view (existing)
  - Workflow breakdown (new, per file status)
```

**Path B: Without Task Argument** (`/cig-status`)
```
User invokes: /cig-status
              ↓
cig-status.md (line 8 context call)
  - Forwards: status-aggregator (no conditional logic, empty $ARGUMENTS)
              ↓
status-aggregator (trampoline entry point)
  - Detects: No arguments provided, no explicit flags
  - Applies defaults: --sort=modified --limit=5 (intelligent defaults for overview)
  - Detects project format version → v2.1
  - Execs: status-aggregator-v2.1 --sort=modified --limit=5
              ↓
status-aggregator-v2.1
  - Generates tree view for all tasks
  - Sorts by modification time (descending)
  - Limits output to 5 tasks (internal logic, not head piping)
  - No --workflow flag, so no per-file breakdown
              ↓
Markdown output returned to user
  - Tree view (5 most recent tasks only)
  - No workflow breakdown
```

**Path C: With Explicit Flags** (`status-aggregator --no-workflow 26` or `status-aggregator --limit=10`)
```
External invocation or future skill use
              ↓
status-aggregator (trampoline entry point)
  - Detects: Explicit flags provided
  - Flags override defaults (tools, not philosophies)
  - Routes to version-specific implementation with flags as-is
              ↓
Output respects explicit flags regardless of defaults
```

## Interface Design
### Input Interface
**Command Invocation**:
```bash
/cig-status           # 5 most recent tasks (no workflow detail) - uses default --sort=modified --limit=5
/cig-status 26        # Task 26 with workflow detail - uses default --workflow
/cig-status 1.1.3     # Nested task with workflow detail - uses default --workflow
```

**Direct Script Invocation (for advanced use)**:
```bash
status-aggregator                        # Default: --sort=modified --limit=5
status-aggregator 26                     # Default: --workflow
status-aggregator --no-workflow 26       # Explicit: disable workflow for task 26
status-aggregator --workflow             # Explicit: workflow for all tasks
status-aggregator --limit=10             # Explicit: show 10 most recent tasks
status-aggregator --limit=10 --workflow  # Explicit: 10 tasks with workflow detail
```

**New Flags**:
- `--workflow`: Explicitly enable workflow breakdown (overrides defaults)
- `--no-workflow`: Explicitly disable workflow breakdown (overrides defaults)
- `--limit=N`: Explicitly limit to N tasks (applies to tasks only, not workflow files or subtasks)
- `--sort=modified`: Explicitly sort by modification time (existing flag)

**Arguments Forwarded from Command**:
- `$ARGUMENTS` variable contains optional task path and/or flags
- Empty string if no arguments provided
- Example: "26" for `/cig-status 26`
- Example: "--limit=10" for `/cig-status --limit=10`

### Output Interface

**With Task Argument** (`/cig-status 26`):
```
Task Progress:

+ 26 (feature): update-cig-status-to-use-workflow-flag - 50%

Task 26 (feature): update-cig-status-to-use-workflow-flag - 50%
  * a-task-plan.md            Finished	100%
  * b-requirements-plan.md    Finished	100%
  + c-design-plan.md          In Progress	50%
  - d-implementation-plan.md  Backlog	0%
  - e-implementation-exec.md  Backlog	0%
  - f-testing-plan.md         Backlog	0%
  - g-testing-exec.md         Backlog	0%
  - h-rollout.md              Backlog	0%
  - i-maintenance.md          Backlog	0%
  - j-retrospective.md        Backlog	0%
```

**Without Task Argument** (`/cig-status`):
```
Task Progress (5 most recent):

+ 26 (feature): update-cig-status-to-use-workflow-flag - 50%
✓ 25 (feature): v2-1-workflow-with-planning-execution-separation - 100%
✓ 24 (chore): standardize-workflow-step-enumeration - 100%
✓ 23 (feature): add-blocked-status-to-cig-system - 100%
⚙️ 22 (feature): retrospective-structure-and-flow-improvements - 25%
```

**Legend**:
- `*` = Finished (100%) - in workflow breakdown
- `+` = In Progress (25-99%) - in workflow breakdown
- `-` = Not Started (0%) - in workflow breakdown
- ✓ = Finished (100%) - in tree view
- ⚙️ = In Progress - in tree view
- ○ = Not Started - in tree view

## Constraints
### Technical Constraints
1. **Trampoline Architecture**: Must call `status-aggregator` entry point (not `.pl` directly)
   - Ensures version detection works correctly
   - Follows Task 25 architecture decisions

2. **Argument Forwarding**: Must use `$ARGUMENTS` variable
   - Commands receive user arguments in this variable
   - Empty string if no arguments provided

3. **Error Handling**: Must maintain existing fallback
   - `2>/dev/null || echo "Unable to load status"`
   - Graceful degradation if script fails

4. **Tool Permissions**: Update allowed-tools line
   - Current: `Bash(.cig/scripts/command-helpers/status-aggregator.pl:*)`
   - New: `Bash(.cig/scripts/command-helpers/status-aggregator:*)`

### Implementation Details

#### Files to Modify

**1. Command File**: `.claude/commands/cig-status.md` (minimal changes)

**Line 4** (allowed-tools):
```markdown
Before: allowed-tools: Read, Bash(.cig/scripts/command-helpers/hierarchy-resolver.pl:*), Bash(.cig/scripts/command-helpers/status-aggregator.pl:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)

After:  allowed-tools: Read, Bash(.cig/scripts/command-helpers/hierarchy-resolver.pl:*), Bash(.cig/scripts/command-helpers/status-aggregator:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
```
Changes:
- `status-aggregator.pl` → `status-aggregator` (use trampoline entry point)
- Remove `Bash(head:*)` (no longer needed - no command-side filtering)

**Line 8** (context call - SIMPLIFIED, NO CONDITIONALS):
```markdown
Before: - Task hierarchy with progress: !`.cig/scripts/command-helpers/status-aggregator.pl 2>/dev/null || echo "Unable to load status"`

After:  - Task hierarchy with progress: !`.cig/scripts/command-helpers/status-aggregator $ARGUMENTS 2>/dev/null || echo "Unable to load status"`
```
Changes:
- `status-aggregator.pl` → `status-aggregator` (use trampoline)
- Add `$ARGUMENTS` (forward user arguments to script)
- No conditionals - script handles defaults

**Lines 30-32** (documentation reference):
```markdown
Before: ### 2. Calculate Progress with status-aggregator.pl
        - Call `status-aggregator.pl [task-path]` to get progress calculations

After:  ### 2. Calculate Progress with status-aggregator
        - **With task argument**: Calls `status-aggregator [task-path]` (auto-enables --workflow)
        - **Without task argument**: Calls `status-aggregator` (auto-enables --sort=modified --limit=5)
        - Use explicit flags (--workflow, --no-workflow, --limit=N) to override defaults
```

**Total Command File Changes**: 3 lines (simple, no conditionals)

---

**2. Status-Aggregator Script**: `.cig/scripts/command-helpers/status-aggregator` (trampoline entry point)

**New Logic Required**:
1. **Argument Parsing**: Detect flags (--workflow, --no-workflow, --limit=N, --sort=modified) vs task paths
2. **Default Behavior Detection**:
   - If task path provided AND no explicit --workflow/--no-workflow → Apply `--workflow` default
   - If no arguments AND no explicit flags → Apply `--sort=modified --limit=5` default
   - If explicit flags provided → Use them (override defaults)
3. **Version Detection**: Detect task format version (existing logic)
4. **Routing**: Exec appropriate version-specific script with final flags

**Pseudo-logic** (not implementation):
```
Parse arguments → Separate flags from task path
If explicit --workflow or --no-workflow → Use them
Else if task path provided → Default to --workflow
Else → Default to --sort=modified --limit=5
Detect version → Exec status-aggregator-v2.x with final flags
```

---

**3. Version-Specific Scripts**: `.cig/scripts/command-helpers/status-aggregator-v2.0` and `status-aggregator-v2.1`

**New Features Required**:
1. **--limit=N Flag**: Limit output to N tasks (tasks only, not workflow files or subtasks)
   - Apply limit after sorting, before output
   - Count top-level tasks only (Task 1, Task 26, etc.)
   - Still show all subtasks within limited tasks (Task 1 includes 1.1, 1.1.1, etc.)
   - Still show all workflow files if --workflow enabled
2. **--no-workflow Flag**: Explicitly disable workflow breakdown
   - Suppress per-file workflow breakdown even when task path provided

**Total Script Changes**: Moderate (argument parsing, default detection, limiting logic)

## Validation
- [x] Design review completed
- [x] Architecture approved (Intelligent Defaults in Script pattern)
- [x] Integration points verified (status-aggregator trampoline entry point)
- [x] All requirements addressed (FR1-FR4, NFR1-NFR5)
- [x] Trade-offs documented and acceptable
- [x] Design priorities followed (Testability → Readability → Consistency → Simplicity → Reversibility)
- [x] Intelligent defaults minimize information overload for large projects
- [x] Explicit flags provide full control ("tools, not philosophies")
- [x] Command file simplified (no conditionals, avoids Claude Code permission issues)
- [x] Script-based limiting more efficient than command-side piping

## Requirements Traceability
**FR1: Intelligent Default Behavior**:
- ✅ AC1.1: Task path → auto-enable workflow → status-aggregator detects task path, applies --workflow default
- ✅ AC1.2: No arguments → auto-enable sorted+limit → status-aggregator detects no args, applies --sort=modified --limit=5 default
- ✅ AC1.3: Workflow breakdown shown for specific task → Handled by status-aggregator-v2.1
- ✅ AC1.4: Completion indicators shown → Handled by status-aggregator-v2.1

**FR2: Explicit Flag Controls**:
- ✅ AC2.1: --workflow flag → status-aggregator implements flag, overrides defaults
- ✅ AC2.2: --no-workflow flag → status-aggregator implements flag, overrides defaults
- ✅ AC2.3: --sort=modified flag → status-aggregator existing flag
- ✅ AC2.4: --limit=N flag → status-aggregator implements flag (tasks only, not workflows/subtasks)
- ✅ AC2.5: Flags override defaults → status-aggregator argument parsing prioritizes explicit flags

**FR3: Output Behavior Based on Defaults**:
- ✅ AC3.1: With task (default): Tree view with percentages → status-aggregator default behavior
- ✅ AC3.2: With task (default): Workflow detail per file → status-aggregator --workflow (auto-applied)
- ✅ AC3.3: With task (default): Additive output → --workflow adds detail, doesn't remove tree
- ✅ AC3.4: Without task (default): 5 most recent tasks → status-aggregator --limit=5 (auto-applied)
- ✅ AC3.5: Without task (default): No workflow detail → No --workflow flag (auto-omitted)
- ✅ AC3.6: Without task (default): Sorted by update time → status-aggregator --sort=modified (auto-applied)

**FR4: Version Detection**:
- ✅ AC4.1: v2.0 shows 8 phases → status-aggregator-v2.0 handles
- ✅ AC4.2: v2.1 shows 10 phases → status-aggregator-v2.1 handles
- ✅ AC4.3: Automatic detection → trampoline entry point handles

**NFR1: Performance**:
- ✅ No degradation → Script-based limiting more efficient than piping

**NFR2: Usability**:
- ✅ Output readable → status-aggregator already implements proper formatting
- ✅ Information overload prevented → 5 task limit when no argument
- ✅ Explicit control available → --no-workflow, --limit flags

**NFR3: Maintainability**:
- ✅ <5 line change → 3 lines in command file (no conditionals)
- ✅ No conditional logic in command → All intelligence in status-aggregator script
- ✅ Shell invocation → Simple ! prefix with $ARGUMENTS forwarding
- ✅ Script complexity isolated → status-aggregator handles all logic

**NFR4: Future Compatibility**:
- ✅ Works with skills → Simple argument forwarding pattern
- ✅ Works with direct invocation → Flags available for all use cases

**NFR5: Reliability**:
- ✅ Graceful degradation → Fallback message preserved
- ✅ Error handling unchanged → 2>/dev/null || echo pattern maintained

## Risks and Mitigations
**Risk 1: Filtering to 5 tasks might cut off important information**
- **Likelihood**: Low (user can always query specific task or use --limit flag)
- **Impact**: Low (user experience - might need to run `/cig-status <task>` for details)
- **Mitigation**: This is by design per requirements (FR3). Users can query specific task for full details, or use `--limit=10` to override. 5 most recent provides quick overview without overwhelming output.

**Risk 2: Script argument parsing complexity**
- **Likelihood**: Medium (parsing flags vs task paths requires careful logic)
- **Impact**: Medium (bugs could misinterpret arguments)
- **Mitigation**: Clear argument parsing logic with explicit flag detection. Test all combinations: flags only, task path only, flags + task path, no arguments. Document expected behavior in script comments.

**Risk 3: Default behavior might not be obvious to users**
- **Likelihood**: Low (behavior matches user expectations per requirements)
- **Impact**: Low (users might not realize --workflow is auto-applied)
- **Mitigation**: Document default behavior in command documentation. Provide explicit flags for all controls. Users can always override with --no-workflow if needed.

**Risk 4: --limit implementation complexity**
- **Likelihood**: Medium (must count tasks correctly, not subtasks or workflow files)
- **Impact**: Medium (incorrect limit would show wrong number of tasks)
- **Mitigation**: Clear definition: limit applies to top-level tasks only (Task 1, Task 26). Subtasks within a task hierarchy are always shown. Workflow files are always shown if --workflow enabled. Test with nested hierarchies.

**Risk 5: Format detector bug affects testing**
- **Likelihood**: High (known bug in BACKLOG)
- **Impact**: Low (doesn't affect implementation, only testing edge cases)
- **Mitigation**: Test with known v2.0/v2.1 tasks, document bug as separate issue

**Risk 6: Argument forwarding breaks with special characters in flags**
- **Likelihood**: Low (flags are well-formed, task paths validated as digits/dots)
- **Impact**: Low (would fail gracefully)
- **Mitigation**: status-aggregator already validates task path format, standard flag parsing handles --flag=value format

## Status
**Status**: Finished
**Next Action**: Proceed to implementation planning → `/cig-implementation-plan 26`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
