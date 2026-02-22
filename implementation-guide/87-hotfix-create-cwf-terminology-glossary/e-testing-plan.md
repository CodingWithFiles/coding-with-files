# Create CWF terminology glossary - Testing Plan
**Task**: 87 (hotfix)

## Task Reference
- **Task ID**: internal-87
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/87-create-cwf-terminology-glossary
- **Template Version**: 2.1

## Goal
Verify glossary.md is correctly structured for tool access and that
workflow-preamble.md references it.

## Test Strategy
Manual doc review — markdown file edits, no automated tests applicable.

## Test Cases

- **TC-1**: `glossary.md` exists at `.cwf/docs/glossary.md`
  - **Given**: The new file
  - **When**: Path checked
  - **Then**: File exists

- **TC-2**: All 8 terms present as `## <TERM>` headings
  - **Given**: The glossary file
  - **When**: `grep "^## " glossary.md`
  - **Then**: 8 headings returned — CWF, checkpoint commit, checkpoints branch,
    skill, slug, squash commit, task branch, wf

- **TC-3**: Index section at top lists all 8 terms
  - **Given**: First ~20 lines of glossary.md
  - **When**: Read with limit=20
  - **Then**: All 8 terms appear in the index

- **TC-4**: Each entry has a "Not" or "Abbrev" field where applicable
  - **Given**: The wf entry
  - **When**: Read the entry
  - **Then**: `**Abbrev**` line present clarifying "wf" = "workflow"

- **TC-5**: `workflow-preamble.md` references glossary
  - **Given**: The edited preamble
  - **When**: `grep "glossary" workflow-preamble.md`
  - **Then**: Match found pointing to `.cwf/docs/glossary.md`

- **TC-6**: No existing docs duplicated — status values, task path etc. not redefined
  - **Given**: The glossary file
  - **When**: Grepped for "Backlog\|Finished\|task path\|decomposition"
  - **Then**: No match (these are defined elsewhere)

- **TC-7**: `cwf-manage validate` passes
  - **Given**: Changes committed
  - **When**: `.cwf/scripts/cwf-manage validate`
  - **Then**: Exit 0, `[CWF] validate: OK`

## Validation Criteria
- [ ] TC-1 passes
- [ ] TC-2 passes
- [ ] TC-3 passes
- [ ] TC-4 passes
- [ ] TC-5 passes
- [ ] TC-6 passes
- [ ] TC-7 passes

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 87
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
