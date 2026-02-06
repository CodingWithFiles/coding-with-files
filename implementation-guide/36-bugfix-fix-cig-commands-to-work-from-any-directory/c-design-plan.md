# Fix CIG Commands to Work from Any Directory - Design

## Task Reference
- **Task ID**: internal-36
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/36-fix-cig-commands-to-work-from-any-directory
- **Template Version**: 2.1

## Goal
Add git root detection to all CIG commands enabling execution from any directory within the repository.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Architecture Choice: Option B (Explicit CD to Git Root)

**Decision**: Commands explicitly `cd` to git root at start of execution

**Rationale**:
- **Simplicity**: Matches existing relative path assumptions in all commands
- **Consistency**: All 17 commands use same pattern (easy to test and validate)
- **Minimal Changes**: No need to rewrite path logic throughout commands
- **Explicit Behavior**: Clear communication of directory change to user/LLM
- **Git Dependency**: Acceptable (CIG already requires git)

**Trade-offs**:
- ✅ **Pros**:
  - Simple 4-line addition to each command
  - No changes to helper script invocations
  - Preserves all existing relative path references
  - Easy to test (from root, from subdirectory, from outside repo)
  - Clear error messaging when not in git repository
- ❌ **Cons**:
  - Changes working directory (could confuse LLM)
  - Mitigation: Echo new working directory clearly
  - Not truly directory-agnostic (relies on cd)

**Rejected Alternative (Option A: Dynamic Git Root Detection)**:
- Convert all relative paths to absolute paths based on git root
- Pros: No directory change, truly directory-agnostic
- Cons: Complex, requires rewriting path logic, harder to maintain
- **Reason for rejection**: Over-engineering for marginal benefit

## System Design

### Component Overview
**Single Component**: Git root detection snippet added to each command file

```bash
# Git root detection (added at start of each command)
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository"
    exit 1
fi

cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"
```

**Responsibilities**:
1. Detect git repository root
2. Fail gracefully if not in git repository
3. Change to git root directory
4. Communicate directory change to user/LLM

### Data Flow
1. User invokes command (e.g., `/cig-new-task 37 feature "description"`)
2. Command script executes git root detection snippet
3. If not in git repo → Error message, exit 1
4. If in git repo → cd to root, echo working directory
5. Command proceeds with existing logic using relative paths

## Interface Design

### Command File Changes (17 files)
**Affected Commands**:
- Workflow: cig-task-plan, cig-requirements-plan, cig-design-plan, cig-implementation-plan, cig-testing-plan, cig-implementation-exec, cig-testing-exec, cig-rollout, cig-maintenance, cig-retrospective
- Utility: cig-new-task, cig-subtask, cig-status, cig-extract, cig-config, cig-init, cig-security-check

**Insertion Point**: After command metadata section, before first bash command block

**Pattern**:
```markdown
## Your task
[Existing command description]

## Implementation
Execute git root detection and proceed:

!{bash}
# Ensure we're in git repository root
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository. CIG commands must be run from within a git repository."
    exit 1
fi

cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"

# [Existing command logic continues here]
```

## Constraints
- **Git Dependency**: Commands require git (already a CIG prerequisite)
- **Backward Compatibility**: Must work from repository root (existing behavior)
- **LLM Communication**: Must echo working directory to maintain LLM context
- **Error Handling**: Clear error when not in git repository
- **No Helper Script Changes**: All changes confined to command files

## Validation
- [x] Design review completed (Option B selected from BACKLOG analysis)
- [x] Architecture approved (user initiated task creation)
- [x] Integration points verified (no helper script changes needed)

## Status
**Status**: Finished
**Next Action**: Begin implementation planning → `/cig-implementation-plan 36`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
