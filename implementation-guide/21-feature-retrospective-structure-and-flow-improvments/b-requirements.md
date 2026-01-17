# retrospective-structure-and-flow-improvments - Requirements

## Task Reference
- **Task ID**: internal-21
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/21-retrospective-structure-and-flow-improvments
- **Template Version**: 2.0

## Goal
Define functional and non-functional specifications for retrospective-structure-and-flow-improvments.

## Functional Requirements
### FR1: Sequential Step Numbering
**What**: Renumber all workflow steps as sequential integers (1, 2, 3, ..., 9)

**Why**: Fractional numbers (1.5, 7.5) imply priority/subordination that doesn't exist

**Current state**:
- Step 1: Resolve Task Directory
- Step 1.5: Verify Git Branch (line 38)
- Step 2: Load Parent Context (line 61)
- ...continuing with off-by-one numbering...
- Step 7: Execute Retrospective (line 80)
- Implied Step 7.5: Update BACKLOG.md (missing, will be Step 8)
- Step 8: Prepare Final Commit (line 99, will become Step 9)

**Acceptance**: All steps numbered 1-9 without decimals, no broken references

### FR2: BACKLOG.md Update Step
**What**: Add explicit step for synchronizing BACKLOG.md with task completion and retrospective findings

**Why**: Tasks often complete BACKLOG items or identify new ones during retrospective

**Current state**: Missing entirely, discovered during Task 20 retrospective

**Location**: Between Execute Retrospective and Prepare Final Commit (new Step 8)

**Workflow**:
1. Check if task completed any BACKLOG.md items → mark complete or remove
2. Check retrospective for new items identified → add to BACKLOG.md
3. Stage BACKLOG.md if modified

**Examples needed**:
- Scenario A: Task 20 completed "Fix d-implementation.md Template" item
- Scenario B: Task 20 identified "Rename Constraints headers" in retrospective

**Acceptance**: New step documented with clear examples for both scenarios

### FR3: Commit Message Guidance
**What**: Add explicit guidance about writing meaningful commit messages

**Why**: Users need reminder to keep commits brief and focus on "why" not "what"

**Current state**: Step 8 shows examples but doesn't state principles

**Guidance to add**:
- Keep title concise (~50 chars): "Task N: Brief description"
- Body should explain WHY, not just WHAT
  - What changed is visible in the diff
  - Why it changed provides context for future readers
- Include technical details that aren't obvious from code
- End with Co-Authored-By line
- **Anti-pattern**: Redundant suffixes like "Finished with retrospective" (waste SNR)

**Acceptance**: Commit guidance documented in Step 9 before commit examples

### User Stories
- **US1**: As a developer completing a retrospective, I want sequential step numbers so I can easily follow the workflow without wondering if sub-steps are optional.
- **US2**: As a developer finishing a task, I want explicit guidance to update BACKLOG.md so I don't forget to mark completed items or capture new findings.
- **US3**: As a developer writing commit messages, I want clear guidance about brevity and "why over what" so my commits are maintainable.

## Non-Functional Requirements
### NFR1: Maintainability
- Zero broken references when step numbers change
- Search codebase for references to "Step 1.5" or "Step 7.5" and update
- Clear section headers for easy scanning

### NFR2: Usability
- BACKLOG.md workflow examples must be actionable (show actual file edits)
- Commit guidance must be concise (3-5 bullet points, not essay)
- Step numbering change shouldn't break user muscle memory (document change in commit)

### NFR3: Backward Compatibility
- Existing tasks don't retroactively need BACKLOG.md updates
- Old workflow still works, new workflow adds best practice step

## Constraints
- Changes limited to `.claude/commands/cig-retrospective.md` file only
- Must preserve all existing workflow functionality
- Step renumbering is breaking change for user habits but necessary for clarity
- Must maintain backward compatibility with existing tasks (old tasks won't have BACKLOG.md updates)

## Acceptance Criteria
- [ ] AC1: All workflow steps in cig-retrospective.md numbered 1-9 sequentially without fractional numbers (FR1)
- [ ] AC2: New Step 8 added for BACKLOG.md synchronization with clear workflow and examples (FR2)
- [ ] AC3: Step 9 (final commit) includes explicit commit message guidance with principles and anti-patterns (FR3)
- [ ] AC4: No broken references to old step numbers found in codebase (NFR1)
- [ ] AC5: BACKLOG.md examples are actionable showing actual file edits (NFR2)
- [ ] AC6: Commit guidance is concise (3-5 bullet points) (NFR2)
- [ ] AC7: Workflow tested with example to verify completeness

## Status
**Status**: Finished
**Next Action**: Proceed to design phase (c-design.md)
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
