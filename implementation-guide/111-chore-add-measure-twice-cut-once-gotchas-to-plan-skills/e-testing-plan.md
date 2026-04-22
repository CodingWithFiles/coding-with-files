# Add measure-twice-cut-once gotchas to design-plan and implementation-plan skills - Testing Plan
**Task**: 111 (chore)

## Task Reference
- **Task ID**: internal-111
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/111-add-measure-twice-cut-once-gotchas-to-plan-skills
- **Template Version**: 2.1

## Goal
Verify that gotcha 3 is correctly appended to both plan SKILL.md files with
byte-identical text, no project-specific references, and no unintended changes.

## Test Strategy
Manual inspection — documentation-only change to two markdown files. No automated
tests applicable. Same strategy and test pattern as Task 110.

## Test Cases

### Structural Tests
- **TC-S1**: Gotcha 3 present in both files
  - **Given**: Modified SKILL.md (cwf-design-plan, cwf-implementation-plan)
  - **When**: Read the Gotchas section
  - **Then**: Exactly 3 numbered gotchas in each file; gotcha 3 begins with "**Measure twice, cut once"

- **TC-S2**: Gotcha 3 placement
  - **Given**: Modified SKILL.md
  - **When**: Read the file
  - **Then**: Gotcha 3 appears inside the existing `## Gotchas` section, before `## Scope & Boundaries`

### Content Tests
- **TC-C1**: Byte-identical gotcha 3 text across both files
  - **Given**: Modified SKILL.md files
  - **When**: `diff <(sed -n '/^3\./p' .claude/skills/cwf-design-plan/SKILL.md) <(sed -n '/^3\./p' .claude/skills/cwf-implementation-plan/SKILL.md)`
  - **Then**: No output (files identical on gotcha 3 line)

- **TC-C2**: Gotcha 3 addresses codebase verification
  - **Given**: Gotcha 3 text
  - **When**: Read content
  - **Then**: References grep the codebase, reading related files, and reading 2-3 similar implementations

### Project-Neutrality Tests
- **TC-N1**: No "Task NNN" references in gotcha 3
  - **Given**: Modified SKILL.md files
  - **When**: `grep -E "Task [0-9]+" .claude/skills/cwf-design-plan/SKILL.md .claude/skills/cwf-implementation-plan/SKILL.md`
  - **Then**: Zero matches

- **TC-N2**: No commit hashes, branch names, or file paths specific to this repo
  - **Given**: Gotcha 3 text
  - **When**: Visual inspection
  - **Then**: Wording is generic enough to apply in any downstream project

### Regression Tests
- **TC-R1**: Existing gotchas 1 and 2 unchanged
  - **Given**: Modified SKILL.md files
  - **When**: `git diff HEAD~1 -- .claude/skills/cwf-design-plan/SKILL.md .claude/skills/cwf-implementation-plan/SKILL.md`
  - **Then**: Only addition is gotcha 3; gotchas 1 and 2 identical to pre-change

- **TC-R2**: No changes outside Gotchas section
  - **Given**: Modified SKILL.md files
  - **When**: Diff against previous version
  - **Then**: All other sections (Scope & Boundaries, Context, Workflow, Success Criteria) identical

- **TC-R3**: Other SKILL.md files unchanged
  - **Given**: Other `## Gotchas`-bearing SKILL.md files (cwf-requirements-plan, cwf-retrospective)
  - **When**: `git status`
  - **Then**: Only the two target files in scope

## Validation Criteria
- [ ] TC-S1: Gotcha 3 present in both target files
- [ ] TC-S2: Gotcha 3 inside existing Gotchas section, before Scope & Boundaries
- [ ] TC-C1: Gotcha 3 byte-identical across both files
- [ ] TC-C2: Gotcha 3 addresses codebase verification
- [ ] TC-N1: No "Task NNN" references
- [ ] TC-N2: Wording is project-neutral
- [ ] TC-R1: Gotchas 1 and 2 unchanged
- [ ] TC-R2: No changes outside Gotchas section
- [ ] TC-R3: Other SKILL.md files unchanged

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
9 test cases defined, all 9 passed at g-testing-exec. Test pattern reused directly
from Task 110 with minor adaptations (2 files instead of 3-4; adjusted regression
test to check for no changes in the other 2 gotcha-bearing SKILL.md files).

## Lessons Learned
The byte-identity diff check (TC-C1) remains the most valuable regression test
for multi-file identical-text tasks. Cheap to run, catches whitespace drift that
visual inspection misses.
