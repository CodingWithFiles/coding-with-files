# Refactor task plan success guidelines - Implementation

## Task Reference
- **Task ID**: internal-42
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/42-refactor-task-plan-success-guidelines
- **Template Version**: 2.1

## Goal
Add "Simplicity Principles" subsection to Planning phase in workflow-steps.md to prevent scope gaps.

## Workflow
Read existing → Design insertion → Insert content → Validate rendering → Commit with "why"

## Files to Modify
### Primary Changes
- `.cig/docs/workflow/workflow-steps.md` - Add "Simplicity Principles" subsection to Planning phase (lines 52-65)

### Supporting Changes
- None - This is a documentation-only change

## Implementation Steps

### Step 1: Read Current Planning Section
- [ ] Read `.cig/docs/workflow/workflow-steps.md` lines 50-93 (Planning section)
- [ ] Verify insertion point is correct (after line 52 "Purpose", before line 53 "Focus on")
- [ ] Confirm no other tasks have modified this section since design phase

### Step 2: Insert Simplicity Principles Subsection
- [ ] Use Edit tool to insert new content after line 52
- [ ] Insert blank line (53)
- [ ] Insert "**Simplicity Principles**:" header (54)
- [ ] Insert blank line (55)
- [ ] Insert opening paragraph about simplicity as core goal (56-57)
- [ ] Insert blank line (58)
- [ ] Insert "The best part is no part" principle with explanation (59)
- [ ] Insert "Reduce, reuse, recycle" principle with explanation (60)
- [ ] Insert blank line (61)
- [ ] Insert "When planning, explicitly consider:" prompt (62)
- [ ] Insert three bullet questions (63-65)
- [ ] Verify existing content shifts down correctly (old line 53 → new line 66)

### Step 3: Validate Markdown Rendering
- [ ] Read the modified section to verify markdown formatting
- [ ] Check bullet points render correctly
- [ ] Check bold text renders correctly
- [ ] Verify no accidental line breaks or formatting issues

### Step 4: Test with Retrospective Analysis
- [ ] Re-read Task 39 planning (a-task-plan.md)
- [ ] Verify: Would new guidance have prompted "What becomes obsolete?" → Yes
- [ ] Re-read Task 40 planning (a-task-plan.md)
- [ ] Verify: Would new guidance have caught incomplete "COMPLETE" scope → Yes
- [ ] Re-read Task 41 planning (a-task-plan.md)
- [ ] Verify: Would new guidance have identified cleanup work → Yes

### Step 5: Commit Changes
- [ ] Stage `.cig/docs/workflow/workflow-steps.md`
- [ ] Write commit message explaining "why" (prevent scope gaps from Tasks 39/40/41)
- [ ] Commit with Co-Authored-By trailer

## Code Changes

### Before (lines 50-55)
```markdown
## Planning

**Purpose**: Establish clear objectives, success criteria, and high-level approach before diving into details.

**Focus on**:
- Single-sentence objective that captures the "why"
```

### After (lines 50-68)
```markdown
## Planning

**Purpose**: Establish clear objectives, success criteria, and high-level approach before diving into details.

**Simplicity Principles**:

Keeping the system simple is a core goal. Sometimes this means "don't add new features/code for the sake of adding" and can also sometimes mean "we don't need that (anymore), remove it".

- **"The best part is no part"**: The simplest, most reliable solution often involves removing unnecessary code or not adding it in the first place
- **"Reduce, reuse, recycle"**: Minimise new code, leverage existing solutions, extract common patterns only when proven necessary

When planning, explicitly consider:
- What can be removed or simplified?
- What existing code/files/artifacts does this make obsolete?
- What's the minimal solution that satisfies requirements?

**Focus on**:
- Single-sentence objective that captures the "why"
```

## Test Coverage

### Validation Test Cases (Manual)

**VC-1**: Retrospective validation with Task 39
- Input: Re-read Task 39 a-task-plan.md with new guidance in mind
- Expected: Guidance prompts "What old scripts become obsolete?"
- Result: [To be filled during testing]

**VC-2**: Retrospective validation with Task 40
- Input: Re-read Task 40 a-task-plan.md with new guidance in mind
- Expected: Guidance catches incomplete "COMPLETE" scope (old scripts still exist)
- Result: [To be filled during testing]

**VC-3**: Retrospective validation with Task 41
- Input: Re-read Task 41 a-task-plan.md with new guidance in mind
- Expected: Guidance identifies cleanup work as part of scope
- Result: [To be filled during testing]

**VC-4**: Markdown rendering validation
- Input: Read modified workflow-steps.md
- Expected: Proper formatting, no broken bullets or bold text
- Result: [To be filled during testing]

## Validation Criteria

Before marking implementation complete:
- [ ] Simplicity Principles subsection inserted at correct location
- [ ] 13 lines added (1 blank + 1 header + 11 content lines)
- [ ] Existing content shifted down correctly (no lost lines)
- [ ] Markdown renders properly (bullets, bold, spacing)
- [ ] Retrospective validation: All 3 tests (VC-1, VC-2, VC-3) pass
- [ ] Commit created with clear "why" message

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: Implementation planning complete, moved to execution
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
