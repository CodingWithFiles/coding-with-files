# fix-checkpoints-branch-perms-issue-with-script - Design
**Task**: 49 (bugfix)

## Task Reference
- **Task ID**: internal-49
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/49-fix-checkpoints-branch-perms-issue-with-script
- **Template Version**: 2.1

## Goal
Design `checkpoints-branch-manager` script to handle compound git commands deterministically, eliminating Step 10 permission prompts.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Architecture Choice
- **Decision**: Perl-based subcommand script pattern (matching existing CIG helper scripts)
- **Rationale**: Consistency with existing `.cig/scripts/command-helpers/` architecture. Perl provides robust error handling, file locking, and git integration. Subcommand pattern (create/show-history/verify) provides clear interface.
- **Trade-offs**:
  - **Benefits**: Consistent with CIG patterns, reliable error handling, already in allowed permissions
  - **Drawbacks**: Adds script overhead for simple git operations, but eliminates permission complexity

### Technology Stack
- **Script**: Perl (matches task-stack, context-manager, etc.)
- **Git integration**: Shell out to git commands (standard CIG pattern)
- **Error handling**: get_script_rel_path() pattern for consistent error messages

## System Design
### Component Overview
- **checkpoints-branch-manager script**: Main entry point, parses subcommands and delegates to handlers
- **create subcommand**: Executes compound git command `git branch "$(git rev-parse --abbrev-ref HEAD)-checkpoints"`
- **show-history subcommand**: Executes `git log --oneline --graph -20` to help identify base commit
- **verify subcommand**: Executes compound git command `git log "$(git rev-parse --abbrev-ref HEAD)-checkpoints" --oneline`
- **get_script_rel_path()**: Error message helper (standard CIG pattern)

### Data Flow
1. User invokes script with subcommand (e.g., `checkpoints-branch-manager create`)
2. Script validates git repository context
3. Script executes appropriate git command(s) internally
4. Output/errors written to stdout/stderr
5. Exit code indicates success (0) or failure (1)

## Interface Design
### Script API
```bash
checkpoints-branch-manager <subcommand>
```

**Subcommands**:
- `create` - Creates checkpoints branch with current branch name + "-checkpoints" suffix
  - Executes: `git branch "$(git rev-parse --abbrev-ref HEAD)-checkpoints"`
  - Output: "Created branch: <branch-name>-checkpoints" or error message
  - Exit code: 0 on success, 1 on failure

- `show-history [count]` - Shows recent commit history for identifying base commit
  - Executes: `git log --oneline --graph -<count>` (default count: 20)
  - Output: Git log output (colorized if terminal supports)
  - Exit code: 0 on success, 1 on failure

- `verify` - Verifies checkpoints branch exists and shows its commits
  - Executes: `git log "$(git rev-parse --abbrev-ref HEAD)-checkpoints" --oneline`
  - Output: Commit list from checkpoints branch or error message
  - Exit code: 0 on success, 1 if branch doesn't exist

### Error Handling
- **Not in git repo**: Print "error: not in a git repository" to stderr, exit 1
- **Branch already exists** (create): Print "error: branch <name> already exists" to stderr, exit 1
- **Branch doesn't exist** (verify): Print "error: checkpoints branch not found" to stderr, exit 1
- **Detached HEAD**: Print "error: not on a branch" to stderr, exit 1
- **Invalid subcommand**: Print usage message to stderr, exit 1

## Constraints
- **Security**: Script must follow CIG security model (u+rx permissions, SHA256 verification in `.cig/security/script-hashes.json`)
- **Backward compatibility**: Existing Step 10 instructions must remain valid (users can still use direct git commands if preferred)
- **Permission system**: Cannot modify frontmatter permission pattern matching - must work within existing `Bash(.cig/scripts/command-helpers/*:*)` allowance
- **Git context**: Must be run from within git repository, must be on a branch (not detached HEAD)
- **Naming convention**: Must use "checkpoints" (plural) consistently to match branch naming pattern

## Additional Changes Required
1. **Update `.claude/commands/cig-retrospective.md` Step 10** instructions to use script:
   - 10.1: Replace direct git command with `checkpoints-branch-manager create`
   - 10.2: Add optional `checkpoints-branch-manager show-history` before git rebase
   - 10.4: Replace direct git command with `checkpoints-branch-manager verify`

2. **Frontmatter** already allows `.cig/scripts/command-helpers/*:*` - no changes needed

3. **Security hashes**: Add script to `.cig/security/script-hashes.json` after creation

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** - script is ~100-150 lines
- [ ] **People**: Does this need >2 people working on different parts? **NO** - single script + doc updates
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **NO** - single concern (wrap git commands)
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** - low-risk wrapper script
- [ ] **Independence**: Can parts be worked on separately? **NO** - script + documentation tightly coupled

**Decomposition Decision**: No decomposition needed.

## Validation
- [x] Design follows existing CIG script patterns (task-stack, context-manager)
- [x] Subcommand interface is clear and testable
- [x] Error handling covers edge cases (detached HEAD, missing branch, not in repo)
- [x] Backward compatibility maintained (old approach still works)
- [x] Security constraints satisfied (script in allowed path, will add hash)

## Status
**Status**: In Progress
**Next Action**: /cig-implementation-plan
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
