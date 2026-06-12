# Reconcile or retire stale .cwf/utils spec docs - Testing Plan
**Task**: 197 (chore)

## Task Reference
- **Task ID**: internal-197
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/197-reconcile-or-retire-stale-cwfutils-spec-docs
- **Template Version**: 2.1

## Goal
Verify the four `.cwf/utils/*.md` files are cleanly retired with no dangling references and no integrity regression.

## Test Strategy
This is a documentation-only deletion — no code, no unit/integration/automated suite applies. Verification is a set of deterministic shell checks run in g-testing-exec, each with a precise expected result. No test database is involved (no DB interaction).

### Test Coverage Targets
- 100% of the four target files removed.
- 0 dangling references to the removed files (excluding the historical/closed records that are intended to remain).
- Integrity gate (`cwf-manage validate`) green.

## Test Cases
### Functional Test Cases
- **TC-1: Files removed**
  - **Given**: The four docs existed on the branch baseline.
  - **When**: `git ls-files .cwf/utils/` is run after deletion.
  - **Then**: Empty output (no tracked files); the `.cwf/utils/` directory is absent from the worktree.

- **TC-2: No dangling functional reference**
  - **Given**: Deletion applied.
  - **When**: `grep -rn "config-loader\|template-engine\|task-validator\|hierarchy-manager" --include=*.md --include=*.pl --include=*.pm --include=*.json .` excluding `implementation-guide/`.
  - **Then**: The only remaining hits are the intended-permanent historical records (`CHANGELOG.md:13`, `CHANGELOG.md:789`) and this task's own new CHANGELOG entry. No helper/lib/skill/template/test hit.

- **TC-3: Second backlog item de-referenced (not left dangling)**
  - **Given**: BACKLOG.md:1272 previously cited `.cwf/utils/template-engine.md:41`.
  - **When**: `grep -n "utils/template-engine" BACKLOG.md`.
  - **Then**: No match — the citation was dropped; the item remains present and open with `SKILL.md:48` as its surviving target.

- **TC-4: Originating backlog item retired**
  - **Given**: BACKLOG.md:1459 was the originating follow-up.
  - **When**: backlog is listed via `/cwf-backlog-manager`.
  - **Then**: The "Reconcile or retire the stale .cwf/utils/*.md spec docs" item no longer appears as active (retired for task 197).

- **TC-5: Integrity gate green**
  - **Given**: All edits staged/committed.
  - **When**: `.cwf/scripts/cwf-manage validate`.
  - **Then**: Exit 0, `validate: OK` — no sha256 or permission drift (none expected; files not hash-tracked).

### Non-Functional Test Cases
N/A — no performance, security-auth, or reliability surface in a doc deletion. (Security was reviewed in the d-phase plan review: purely subtractive, no executable/hash-tracked content.)

## Test Environment
### Setup Requirements
- The task branch with deletion applied. No test data, services, or DB.

### Automation
- Manual/deterministic shell checks in g-testing-exec; no CI harness change.

## Validation Criteria
- [ ] TC-1 through TC-5 all pass
- [ ] No dangling references beyond the intended historical records

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
