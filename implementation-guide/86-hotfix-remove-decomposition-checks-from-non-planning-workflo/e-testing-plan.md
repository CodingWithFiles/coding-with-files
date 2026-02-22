# Remove decomposition checks from non-planning workflow steps - Testing Plan
**Task**: 86 (hotfix)

## Task Reference
- **Task ID**: internal-86
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/86-remove-decomposition-checks-from-non-planning-workflo
- **Template Version**: 2.1

## Goal
Verify Step 7 is removed and steps renumbered correctly in both skill files,
and that no `*-plan` skills are affected.

## Test Strategy
Manual doc review — markdown file edits, no automated tests applicable.

## Test Cases

- **TC-1**: `cwf-rollout/SKILL.md` — Step 7 decomposition line removed
  - **Given**: The edited file
  - **When**: Grepped for "decomposition"
  - **Then**: No match

- **TC-2**: `cwf-rollout/SKILL.md` — steps renumbered correctly
  - **Given**: The edited file
  - **When**: Step numbers are read
  - **Then**: Steps run 1-4, 5, 6, 7 (checkpoint commit), 8 (next steps) — no gap, no Step 9

- **TC-3**: `cwf-maintenance/SKILL.md` — Step 7 decomposition line removed
  - **Given**: The edited file
  - **When**: Grepped for "decomposition"
  - **Then**: No match

- **TC-4**: `cwf-maintenance/SKILL.md` — steps renumbered correctly
  - **Given**: The edited file
  - **When**: Step numbers are read
  - **Then**: Steps run 1-4, 5, 6, 7 (checkpoint commit), 8 (next steps) — no gap, no Step 9

- **TC-5**: No `*-plan` skill files changed
  - **Given**: All `*-plan` SKILL.md files
  - **When**: Grepped for "decomposition"
  - **Then**: All still contain their decomposition check unchanged

- **TC-6**: `cwf-manage validate` passes
  - **Given**: Changes committed
  - **When**: `.cwf/scripts/cwf-manage validate` run
  - **Then**: Exit 0, `[CWF] validate: OK`

## Validation Criteria
- [ ] TC-1 passes
- [ ] TC-2 passes
- [ ] TC-3 passes
- [ ] TC-4 passes
- [ ] TC-5 passes
- [ ] TC-6 passes

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 86
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
