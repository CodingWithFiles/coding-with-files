# Refactor task plan success guidelines - Design

## Task Reference
- **Task ID**: internal-42
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/42-refactor-task-plan-success-guidelines
- **Template Version**: 2.1

## Goal
Design minimal guidance additions to planning phase that encourage simplicity without adding complexity.

## Design Priorities
**Simplicity** → Readability → Consistency

(Testability and Reversibility are less relevant for documentation changes)

## Architecture Preferences
Minimal intervention. Explicit principles. Quote attribution for credibility.

## Key Decisions

### Architecture Choice
- **Decision**: Add a standalone "Simplicity Principles" subsection to the Planning phase in workflow-steps.md
- **Rationale**:
  - Standalone section is easy to find and understand
  - Doesn't disrupt existing structure (focus/avoid/questions/structure/transitions)
  - Can be read independently without requiring full context
- **Trade-offs**:
  - ✅ Benefit: Clear, visible, doesn't clutter existing guidance
  - ⚠️ Drawback: One more section to read (mitigated by keeping it very short)

### Placement Strategy
- **Decision**: Insert "Simplicity Principles" after "Purpose" and before "Focus on"
- **Rationale**:
  - Sets the mindset before detailing what to focus on
  - Principles inform how to interpret the rest of the guidance
  - Natural reading order: Why → Principles → What → How
- **Location**: Line 52-53 in workflow-steps.md (after "Purpose", before "Focus on")

## Content Design

### Simplicity Principles Section

**Exact wording**:

```markdown
**Simplicity Principles**:

Keeping the system simple is a core goal. Sometimes this means "don't add new features/code for the sake of adding" and can also sometimes mean "we don't need that (anymore), remove it".

- **"The best part is no part"**: The simplest, most reliable solution often involves removing unnecessary code or not adding it in the first place
- **"Reduce, reuse, recycle"**: Minimize new code, leverage existing solutions, extract common patterns only when proven necessary

When planning, explicitly consider:
- What can be removed or simplified?
- What existing code/files/artifacts does this make obsolete?
- What's the minimal solution that satisfies requirements?
```

**Design rationale**:
1. **Opening paragraph**: Frames the mindset (simplicity as goal, not subtraction as goal)
2. **Two quoted principles**: Memorable, quotable, well-known
3. **Three explicit questions**: Actionable prompts that would have caught Tasks 39/40/41 failures
4. **Total**: ~100 words, <10 lines - minimal addition

### Integration with Existing Content

**No changes to**:
- Focus on / Avoid lists
- Key Questions
- Typical Structure
- Transition Triggers

**Why**: These sections work fine. Adding simplicity questions here would dilute their existing structure.

## System Design

### Component Overview

This is a single-component change:
- **Component**: `.cig/docs/workflow/workflow-steps.md` (Planning section only)
  - Purpose: Add simplicity guidance
  - Responsibility: Insert new subsection, no other modifications

### Change Flow

```
1. Read workflow-steps.md Planning section (lines 50-93)
2. Identify insertion point (after line 52 "Purpose")
3. Insert "Simplicity Principles" subsection
4. Verify formatting and markdown rendering
5. No other sections modified
```

## Interface Design

### File Modification Specification

**File**: `.cig/docs/workflow/workflow-steps.md`

**Insertion point**: After line 52 ("**Purpose**: Establish clear objectives...")

**New content** (insert as lines 53-65):

```markdown

**Simplicity Principles**:

Keeping the system simple is a core goal. Sometimes this means "don't add new features/code for the sake of adding" and can also sometimes mean "we don't need that (anymore), remove it".

- **"The best part is no part"**: The simplest, most reliable solution often involves removing unnecessary code or not adding it in the first place
- **"Reduce, reuse, recycle"**: Minimize new code, leverage existing solutions, extract common patterns only when proven necessary

When planning, explicitly consider:
- What can be removed or simplified?
- What existing code/files/artifacts does this make obsolete?
- What's the minimal solution that satisfies requirements?
```

**Existing content shifts down**: Lines 53-93 become lines 66-106 (13-line shift)

## Constraints

- **Minimalism**: Must not add significant reading burden to planning phase
- **Backwards compatibility**: Existing tasks don't need to retroactively follow this guidance
- **No enforcement**: This is guidance, not a checklist to enforce
- **British spelling**: Use "minimise" not "minimize" per CLAUDE.md (CORRECTION: quotes use American spelling, prose can be British)

## Validation

### Design Validation

Test with retrospective analysis:
- [ ] Would this guidance have prompted asking "What old scripts become obsolete?" in Task 39?
- [ ] Would this guidance have caught the incomplete scope in Task 40 ("COMPLETE" without removing old artifacts)?
- [ ] Would this guidance have identified cleanup work in Task 41 planning?

### Expected Answer: Yes to all three
- "What existing code/files/artifacts does this make obsolete?" directly prompts identifying old scripts
- "The best part is no part" encourages thinking about removal as much as addition
- "What's the minimal solution?" encourages complete migration rather than side-by-side duplication

### Integration Validation
- [ ] Markdown renders correctly
- [ ] Section numbering doesn't break
- [ ] Reading flow is natural (Purpose → Principles → Focus → Questions → Structure → Transitions)
- [ ] Total planning guidance remains <1 page

## Trade-off Analysis

**Alternative Considered**: Add questions to existing "Key Questions" list

**Rejected because**:
- Would dilute the existing 7 questions (each serves a specific purpose)
- Doesn't establish the principle, just asks tactical questions
- Less memorable than standalone principles section

**Alternative Considered**: Create separate "Planning Checklist" file

**Rejected because**:
- Adds another file to reference (violates simplicity)
- Creates indirection (have to leave workflow-steps.md to understand planning)
- More complex than adding 13 lines inline

## Status
**Status**: Finished
**Next Action**: Design complete, moved to implementation
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
