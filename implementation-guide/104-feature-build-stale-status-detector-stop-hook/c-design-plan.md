# Build Stale Status Detector Stop Hook - Design
**Task**: 104 (feature)

## Task Reference
- **Task ID**: internal-104
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/104-build-stale-status-detector-stop-hook
- **Template Version**: 2.1

## Goal
Design the script structure, detection logic, and hook integration for the stale status detector.

## Key Decisions

### Script Location and Language
- **Decision**: Bash script at `.cwf/scripts/hooks/stop-stale-status-detector`
- **Rationale**: Hooks run shell commands. Bash is sufficient — this is a pipeline of `git diff` | `grep` | read status lines. No complex logic warranting Perl. New `hooks/` subdirectory separates hook scripts from `command-helpers/`.
- **Trade-off**: Bash is less testable than Perl, but the script is ~30 lines with no branching logic beyond "found stale files or not."

### Detection Strategy
- **Decision**: `git diff HEAD --name-only -- 'implementation-guide/*/[a-j]-*.md'` — pathspec passed directly to git, no separate grep
- **Rationale**: `git diff HEAD` captures both staged and unstaged changes. Pathspec filtering is faster than piping through grep (one fork, not two). If no wf files changed, git produces empty output and the script exits immediately.

### Staleness Definition
- **Decision**: A wf file is "stale" if it appears in the diff and its `**Status**:` field value is "Backlog"
- **Rationale**: "Backlog" is the template default. If the file was modified but status is still "Backlog", the agent forgot to update it.

### Output Format
- **Decision**: JSON `{"systemMessage": "⚠ Stale: <file1>, <file2> still Backlog"}` when stale files found. Cap at 3 files; if more, append `+N more`. No output when clean.
- **Rationale**: No output = zero token cost on clean stops. Cap bounds worst-case to ~60 tokens.

### Error Handling
- **Decision**: `set -u` only (no `set -e`, no `set -o pipefail`). Handle errors explicitly.
- **Rationale**: `set -e` kills the script when `grep` finds no matches (exit 1) — this is the common case (clean stop). NFR2 requires exit 0 on all paths. `set -u` catches undefined variables without the side effects.

### Hook Registration
- **Decision**: Add to `.claude/settings.local.json` under `hooks.Stop` (project-local, git-ignored)
- **Rationale**: Script is committed in `.cwf/scripts/hooks/`; hook registration is developer-local.

## Data Flow

1. Stop event → hook runs script
2. `git diff HEAD --name-only -- 'implementation-guide/*/[a-j]-*.md'`
3. If empty → exit 0, no output
4. For each file: `grep '^\*\*Status\*\*:.*Backlog'` → collect stale files
5. If any stale: emit JSON `{"systemMessage": "..."}` (max 3 files)
6. Exit 0

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 104
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
