# Add gotchas to cwf-implementation-exec skill - Testing Plan
**Task**: 117 (chore)

## Task Reference
- **Task ID**: internal-117
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/117-add-gotchas-to-cwf-implementation-exec-skill
- **Template Version**: 2.1

## Goal
Verify that the new `## Gotchas` section is correctly inserted into
`cwf-implementation-exec/SKILL.md` with two project-neutral gotchas, in the right
placement, and without disturbing any other section.

## Test Strategy
Manual inspection — documentation-only change to one markdown file. No automated
tests applicable. Same pattern as Task 111 (which followed Task 110).

## Test Cases

### Structural Tests
- **TC-S1**: Gotchas section exists with 2 numbered items
  - **Given**: Modified `cwf-implementation-exec/SKILL.md`
  - **When**: Read the Gotchas section
  - **Then**: `## Gotchas` heading present; exactly 2 numbered items beneath it; item 1 begins with "**Run `git status`"; item 2 begins with "**After any rename or string substitution"

- **TC-S2**: Section placement
  - **Given**: Modified `cwf-implementation-exec/SKILL.md`
  - **When**: List section headings (`grep -n '^##' SKILL.md`)
  - **Then**: `## Gotchas` appears between front-matter terminator and `## Scope & Boundaries`, matching the order seen in `cwf-retrospective/SKILL.md`

### Content Tests
- **TC-C1**: Gotcha 1 covers both untracked AND unstaged
  - **Given**: Gotcha 1 text
  - **When**: Read content
  - **Then**: Mentions `git status` as the action, and explicitly references both untracked and unstaged files (the BACKLOG distinction)

- **TC-C2**: Gotcha 2 requires both source-grep AND output-grep
  - **Given**: Gotcha 2 text
  - **When**: Read content
  - **Then**: Explicitly instructs to grep the source AND generate a sample output artefact and grep that too; states neither is sufficient alone

### Project-Neutrality Tests
- **TC-N1**: No "Task NNN" references
  - **Given**: Modified file
  - **When**: `grep -E "Task [0-9]+" .claude/skills/cwf-implementation-exec/SKILL.md`
  - **Then**: Zero matches

- **TC-N2**: No commit hashes, branch names, or repo-specific paths
  - **Given**: Gotcha section text
  - **When**: Visual inspection
  - **Then**: Wording is generic enough to apply in any downstream project that installs the skill

### Regression Tests
- **TC-R1**: No changes outside Gotchas section in target file
  - **Given**: Modified file
  - **When**: `git diff HEAD~1 -- .claude/skills/cwf-implementation-exec/SKILL.md`
  - **Then**: Only addition is the new `## Gotchas` block; front-matter, Scope & Boundaries, Context, Workflow, Success Criteria sections byte-identical

- **TC-R2**: Other SKILL.md files unchanged
  - **Given**: Sibling skill files (cwf-design-plan, cwf-implementation-plan, cwf-retrospective)
  - **When**: `git status` after the implementation step
  - **Then**: Only `cwf-implementation-exec/SKILL.md` modified; no other skill files in the diff

## Validation Criteria
- [ ] TC-S1: Gotchas section with exactly 2 items
- [ ] TC-S2: Section sits between front-matter and Scope & Boundaries
- [ ] TC-C1: Gotcha 1 covers untracked and unstaged
- [ ] TC-C2: Gotcha 2 requires both source-grep and output-grep
- [ ] TC-N1: No Task NNN references
- [ ] TC-N2: Wording is project-neutral
- [ ] TC-R1: No changes outside the Gotchas section
- [ ] TC-R2: Other SKILL.md files unchanged

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
8/8 test cases executed at g-testing-exec, 8 PASS, 0 FAIL. TC-S1 expected prefix
updated mid-flight when "rebrand" was replaced with "rename or string substitution".
No tests modified after the wording fix; the test plan adapted to the source-of-truth
change in the implementation plan.

## Lessons Learned
TC pattern reused directly from Task 111 with minor adaptations (1 file instead of 2;
8 test cases instead of 9 — TC-C1 byte-identity check not applicable for single-file
insertion). Manual inspection remains the right strategy for documentation-only
SKILL.md changes.
