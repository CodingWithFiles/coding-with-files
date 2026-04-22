# Add Gotchas to Plan Skills to Prevent Step-Skipping - Testing Plan
**Task**: 110 (bugfix)

## Task Reference
- **Task ID**: internal-110
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/110-add-gotchas-to-plan-skills-to-prevent-step-skipping
- **Template Version**: 2.1

## Goal
Verify that gotchas are correctly placed in all three plan skill SKILL.md files and
that the text is identical across all three.

## Test Strategy
Manual inspection — documentation-only change to three markdown files. No automated
tests applicable.

## Test Cases

### Structural Tests
- **TC-S1**: Gotchas section placement (per file)
  - **Given**: Modified SKILL.md (each of the three plan skills)
  - **When**: Read the file
  - **Then**: `## Gotchas` appears after frontmatter closing `---` and before `## Scope & Boundaries`

- **TC-S2**: Two gotchas present (per file)
  - **Given**: Modified SKILL.md
  - **When**: Count numbered items in Gotchas section
  - **Then**: Exactly two numbered items

### Content Tests
- **TC-C1**: Identical gotcha text across all three files
  - **Given**: Modified SKILL.md files
  - **When**: Diff Gotchas sections pairwise
  - **Then**: Gotchas sections byte-identical across cwf-requirements-plan, cwf-design-plan, cwf-implementation-plan

- **TC-C2**: Gotcha 1 addresses generic step-skipping
  - **Given**: Gotcha 1 text
  - **When**: Read content
  - **Then**: References "every numbered step" and mentions skipping causes rework/failure

- **TC-C3**: Gotcha 2 specifically references plan review subagents (Step 8)
  - **Given**: Gotcha 2 text
  - **When**: Read content
  - **Then**: References "Step 8" and "plan review subagents", cites Task 109 evidence

### Project-Neutrality Tests
- **TC-N1**: No "Task NNN" references in plan skills
  - **Given**: Modified plan SKILL.md files (3)
  - **When**: Grep for "Task [0-9]+"
  - **Then**: Zero matches

- **TC-N2**: No "Task NNN" references in cwf-retrospective
  - **Given**: Modified cwf-retrospective SKILL.md
  - **When**: Grep for "Task [0-9]+"
  - **Then**: Zero matches

- **TC-N3**: cwf-retrospective gotchas retain semantic intent
  - **Given**: Modified cwf-retrospective SKILL.md
  - **When**: Read the 3 gotchas
  - **Then**: All 3 gotchas present with equivalent rationale (stale status sweep, suggest-don't-execute merge, don't skip retrospective)

### Regression Tests
- **TC-R1**: No other sections disturbed (per file)
  - **Given**: All 4 modified SKILL.md files
  - **When**: Diff against previous version
  - **Then**: Only change is the Gotchas section (addition or rewording); all other sections identical

## Validation Criteria
- [ ] TC-S1: Gotchas section correctly placed in all 3 plan skills
- [ ] TC-S2: Exactly 2 gotchas in each plan skill
- [ ] TC-C1: Gotchas text byte-identical across all 3 plan skills
- [ ] TC-C2: Gotcha 1 addresses generic step-skipping
- [ ] TC-C3: Gotcha 2 references Step 8 in project-neutral terms
- [ ] TC-N1: No "Task NNN" references in plan skills
- [ ] TC-N2: No "Task NNN" references in cwf-retrospective
- [ ] TC-N3: cwf-retrospective gotchas retain semantic intent
- [ ] TC-R1: No unintended changes in any of the 4 files

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
9 test cases defined (expanded from 6 after /simplify added project-neutrality checks).
All 9 passed at g-testing-exec.

## Lessons Learned
TC-N1/N2 (no Task NNN refs) are broadly useful — any installable skill file should
pass them.
