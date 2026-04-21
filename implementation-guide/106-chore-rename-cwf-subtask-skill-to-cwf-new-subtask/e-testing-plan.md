# Rename cwf-subtask skill to cwf-new-subtask - Testing Plan
**Task**: 106 (chore)

## Task Reference
- **Task ID**: internal-106
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/106-rename-cwf-subtask-skill-to-cwf-new-subtask
- **Template Version**: 2.1

## Goal
Verify the skill directory rename is complete, all live references point to the new name, and no stale references remain.

## Test Strategy

### Test Levels
- **Verification**: Confirm directory rename and file contents correct
- **Reference audit**: Grep for stale `cwf-subtask` references in live files
- **Regression**: Confirm skill appears in listing under new name

### Test Coverage Targets
- **Critical Paths**: 100% — directory exists, SKILL.md `name:` correct, zero stale live references
- **Regression**: Skill listing shows `cwf-new-subtask`

## Test Cases

### Functional Test Cases

- **TC-1**: Skill directory renamed
  - **Given**: Implementation complete
  - **When**: Check `.claude/skills/cwf-new-subtask/SKILL.md` exists
  - **Then**: File exists and contains `name: cwf-new-subtask`

- **TC-2**: Old directory removed
  - **Given**: Implementation complete
  - **When**: Check `.claude/skills/cwf-subtask/` exists
  - **Then**: Directory does not exist

- **TC-3**: No stale references in live files
  - **Given**: Implementation complete
  - **When**: `grep -r 'cwf-subtask' --include='*.md'` excluding `implementation-guide/`, `CHANGELOG.md`
  - **Then**: Zero matches

- **TC-4**: Live files reference new name
  - **Given**: Implementation complete
  - **When**: `grep -r 'cwf-new-subtask' CLAUDE.md README.md .cwf/docs/workflow/decomposition-guide.md .claude/skills/cwf-task-plan/SKILL.md`
  - **Then**: All expected references present

- **TC-5**: Historical files untouched
  - **Given**: Implementation complete
  - **When**: `git diff implementation-guide/63-* implementation-guide/71-* implementation-guide/91-* implementation-guide/96-* implementation-guide/100-* CHANGELOG.md`
  - **Then**: No changes

## Test Environment

### Setup Requirements
- Working git checkout on task branch
- Implementation steps complete

## Validation Criteria
- [ ] TC-1: Skill directory and SKILL.md correct
- [ ] TC-2: Old directory gone
- [ ] TC-3: Zero stale live references
- [ ] TC-4: New name present in all expected live files
- [ ] TC-5: Historical files unchanged

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 106
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
