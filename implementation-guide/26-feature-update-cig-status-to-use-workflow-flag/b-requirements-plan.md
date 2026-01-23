# Update cig-status to Use --workflow Flag - Requirements

## Task Reference
- **Task ID**: internal-26
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/26-update-cig-status-to-use-workflow-flag
- **Template Version**: 2.0

## Goal
Define functional and non-functional specifications for displaying workflow phase breakdown in cig-status output.

## Functional Requirements
### Core Features
- **FR1: Intelligent Default Behavior in status-aggregator**: status-aggregator script provides intelligent defaults based on arguments
  - AC1.1: When task path provided (no explicit flags): Automatically enable workflow mode
  - AC1.2: When NO arguments provided (no explicit flags): Automatically enable sorted mode with 5-task limit
  - AC1.3: Workflow breakdown shows all phase files (a-j for v2.1, a-h for v2.0) for specific task
  - AC1.4: Each phase displays completion indicator (finished/in-progress/not-started)

- **FR2: Explicit Flag Controls**: status-aggregator provides flags for explicit control ("tools, not philosophies")
  - AC2.1: `--workflow` flag: Explicitly enable workflow breakdown (even when no task path)
  - AC2.2: `--no-workflow` flag: Explicitly disable workflow breakdown (even when task path provided)
  - AC2.3: `--sort=modified` flag: Explicitly sort by modification time
  - AC2.4: `--limit=N` flag: Explicitly limit output to N tasks (tasks only, not workflow files or subtasks)
  - AC2.5: Flags override default behavior when explicitly provided

- **FR3: Output Behavior Based on Defaults**
  - **With task argument (default)**:
    - AC3.1: Tree view shows task hierarchy with percentage completion
    - AC3.2: Workflow detail shows per-file status for queried task
    - AC3.3: Output is additive (doesn't remove existing tree view)
  - **Without task argument (default)**:
    - AC3.4: Show only 5 most recently updated tasks
    - AC3.5: No workflow detail (tree view only)
    - AC3.6: Tasks sorted by most recent update time (descending)

- **FR4: Version Detection**: Correct workflow display for v2.0 and v2.1 tasks
  - AC4.1: v2.0 tasks show 8 phases (a-plan through j-retrospective, skipping e,g)
  - AC4.2: v2.1 tasks show 10 phases (a-task-plan through j-retrospective)
  - AC4.3: Version detection handled by status-aggregator (no command-side logic)

### User Stories
- **As a** developer **I want** to see which workflow phases are complete for a specific task **so that** I know what step to work on next
- **As a** project manager **I want** to see detailed phase breakdown for a task **so that** I can understand progress beyond simple percentages
- **As a** developer **I want** workflow detail without extra flags when querying a specific task **so that** I get comprehensive status with minimal typing
- **As a** developer **I want** to see only recent tasks when running `/cig-status` without arguments **so that** I don't get overwhelmed with information in large projects

## Non-Functional Requirements
### Performance (NFR1)
- Response time: < 500ms for 24 tasks (no performance degradation from --workflow flag)
- No additional file reads beyond what status-aggregator already performs
- Negligible overhead from argument forwarding

### Usability (NFR2)
- Output fits within standard terminal width (80-120 characters)
- Workflow indicators visually distinct (* finished, + in-progress, - not-started)
- Workflow file names self-documenting (a-task-plan.md, not cryptic codes)
- No additional flags required (workflow detail shown by default)

### Maintainability (NFR3)
- Command file change <5 lines (simple pass-through to status-aggregator)
- No conditional logic in command file (all intelligence in status-aggregator script)
- No parsing or transformation of status-aggregator output in command
- Command remains shell invocation (! prefix), not inline documentation
- Follows established argument forwarding pattern
- Script changes: status-aggregator implements default behavior detection and new --limit, --no-workflow flags

### Security (NFR4)
- No security requirements (read-only status display)
- No authentication/authorization changes
- No data protection concerns

### Reliability (NFR5)
- Graceful degradation: Falls back to "Unable to load status" on error
- Error handling unchanged from current implementation
- Works correctly whether status-aggregator succeeds or fails

## Constraints
- Must maintain existing cig-status behavior for task-specific queries (hierarchical tree view must remain)
- Without task argument: Limit to 5 most recent tasks to prevent information overload
- Output must be terminal-friendly (consider width constraints)
- Must work for both commands (current) and skills (future migration path)
- All conditional logic and default behavior detection must be in status-aggregator script (not command file)
- Command file must avoid complex bash conditionals to prevent Claude Code permission issues
- Must call status-aggregator entry point (not .pl directly) per trampoline architecture
- status-aggregator must implement --limit flag for output limiting
- status-aggregator must implement --no-workflow flag for explicit control
- Default behavior is "smart" but explicit flags always override defaults ("tools, not philosophies")

## Acceptance Criteria
### FR1: Intelligent Default Behavior
- [ ] AC1.1: When task path provided (no explicit flags): Automatically enable workflow mode
- [ ] AC1.2: When NO arguments provided (no explicit flags): Automatically enable sorted mode with 5-task limit
- [ ] AC1.3: Workflow breakdown shows all phase files (a-j for v2.1, a-h for v2.0)
- [ ] AC1.4: Each phase displays completion indicator (* finished, + in-progress, - not-started)

### FR2: Explicit Flag Controls
- [ ] AC2.1: `--workflow` flag explicitly enables workflow breakdown
- [ ] AC2.2: `--no-workflow` flag explicitly disables workflow breakdown
- [ ] AC2.3: `--sort=modified` flag explicitly sorts by modification time
- [ ] AC2.4: `--limit=N` flag explicitly limits output to N tasks
- [ ] AC2.5: Flags override default behavior when explicitly provided

### FR3: Output Behavior Based on Defaults
- [ ] AC3.1: With task (default): Tree view shows task hierarchy with percentage completion
- [ ] AC3.2: With task (default): Workflow detail shows per-file status for queried task
- [ ] AC3.3: With task (default): Output is additive (doesn't remove existing tree view)
- [ ] AC3.4: Without task (default): Show only 5 most recently updated tasks
- [ ] AC3.5: Without task (default): No workflow detail (tree view only)
- [ ] AC3.6: Without task (default): Tasks sorted by most recent update time (descending)

### FR4: Version Detection
- [ ] AC4.1: v2.0 tasks show 8 phases (a-plan through j-retrospective, skipping e,g)
- [ ] AC4.2: v2.1 tasks show 10 phases (a-task-plan through j-retrospective)
- [ ] AC4.3: Version detection handled by status-aggregator (no command-side logic)

### Non-Functional Requirements
- [ ] NFR1: Performance: Response time < 500ms for 24 tasks
- [ ] NFR2: Usability: Output fits within 80-120 character terminal width
- [ ] NFR3: Maintainability: Command file change < 5 lines (no complex conditionals)

## Status
**Status**: Finished
**Next Action**: Proceed to design phase with `/cig-design-plan 26`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
