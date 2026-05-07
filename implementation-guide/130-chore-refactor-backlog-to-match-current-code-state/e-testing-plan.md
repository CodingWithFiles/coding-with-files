# Refactor BACKLOG to match current code state - Testing Plan
**Task**: 130 (chore)

## Task Reference
- **Task ID**: internal-130
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/130-refactor-backlog-to-match-current-code-state
- **Template Version**: 2.1

## Goal
Define how to validate that the BACKLOG.md triage produced a correct, consistent, and orphan-free document — without inventing executable tests for prose edits.

## Test Strategy
This is a content-only edit task. There are no executable tests; validation is structural and referential, performed manually with grep checks. Prior similar chores (Tasks 52, 84) used the same approach.

### Test Levels
- **Structural validation**: BACKLOG.md format and grouping conventions hold post-edit.
- **Referential validation**: No removed entry's title/keyword survives as an orphan reference elsewhere in the repo.
- **Decision validation**: Each entry's final state (kept / edited / coalesced / removed) was an explicit user decision, recorded in commit messages.

### Test Coverage Targets
- **Active entries triaged**: 100% — every non-completed entry has a decision.
- **Cross-reference scope**: 100% of removed entries grep-checked against the doc set listed below.
- **Format integrity**: zero orphan separators or empty sections post-edit.

## Test Cases

### TC-1: Triage completeness
- **Given**: pre-task inventory of active entries (from Step 1 of d-implementation-plan)
- **When**: triage pass completes
- **Then**: every entry in the inventory maps to one of {kept-as-is, edited, coalesced, removed}; no `Needs-Triage` priority remains.

### TC-2: Removed-entry cross-reference check
- **Given**: list of entries removed during triage (from commit messages)
- **When**: each removed entry's distinguishing phrase (title or unique keyword) is grepped against the repo
- **Then**: no orphan references in any of:
  - `CLAUDE.md` (root + `.claude/CLAUDE.md` if any)
  - `.cwf/docs/conventions/*.md`
  - `implementation-guide/*/j-retrospective.md`
  - `BACKLOG.md` itself (forward-references)
  - `README.md`, `INSTALL.md`, `COMMANDS.md` (root level)
- Any hit must be either updated to remove the reference or the entry must be re-added.

### TC-3: Format integrity
- **Given**: the post-triage BACKLOG.md
- **When**: read end-to-end
- **Then**:
  - `---` separator sits between every adjacent pair of entries
  - No double blank lines
  - No empty sections (no headers with no body)
  - Every active entry has a `**Priority**: X` line with X ∈ {High, Medium, Low, Very Low}
  - Completed entries (✓ / ~~) preserved verbatim unless explicitly removed by user decision

### TC-4: Coalesce correctness
- **Given**: any pair of entries marked for coalesce
- **When**: the merged entry is written
- **Then**:
  - The merged entry's priority equals max(source priorities)
  - The merged entry's scope covers both source scopes (no dropped requirements)
  - The user has explicitly approved the merged wording

### TC-5: Implementation-evidence citation
- **Given**: any entry removed because the work is done
- **When**: the commit message is read
- **Then**: it cites the implementing commit hash, task number, or both (e.g. "removed — implemented by Task 117 / commit a1b2c3d").

### TC-6: cwf-manage validate
- **Given**: post-task tree
- **When**: `.cwf/scripts/cwf-manage validate` runs
- **Then**: exits 0 with no errors related to this task's edits.

## Non-Functional
- **Performance**: N/A (markdown edits)
- **Security**: N/A — no scripts, hooks, or permissions change. Confirmed by FR4 review during d-implementation-plan plan review (no findings).
- **Usability**: post-task BACKLOG should remain at-a-glance scannable; the existing grouping by priority must still be discernible from the inline `**Priority**:` lines.
- **Reliability**: not applicable; the file is reviewed under git, fully revertible.

## Test Environment
### Setup Requirements
- Working directory: repo root.
- HEAD: must match the baseline recorded in a-task-plan, OR baseline must be re-confirmed and re-recorded if HEAD has advanced.
- No external services, no test database, no fixtures.

### Automation
- None. All validation is manual (grep + read-through).
- TC-6 runs the existing `cwf-manage validate` helper; not specific to this task but used as a generic regression gate.

## Validation Criteria
- [ ] TC-1 passes — 100% triage coverage
- [ ] TC-2 passes — no orphan references
- [ ] TC-3 passes — format intact
- [ ] TC-4 passes for every coalesce decision (or no coalesces happened)
- [ ] TC-5 passes for every removal (or no removals happened)
- [ ] TC-6 passes — cwf-manage validate clean

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
