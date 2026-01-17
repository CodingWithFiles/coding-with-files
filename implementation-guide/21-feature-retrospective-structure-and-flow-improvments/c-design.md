# retrospective-structure-and-flow-improvments - Design

## Task Reference
- **Task ID**: internal-21
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/21-retrospective-structure-and-flow-improvments
- **Template Version**: 2.0

## Goal
Define architecture and design decisions for retrospective-structure-and-flow-improvments.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Architecture Choice
- **Decision**: Direct in-place documentation edits (no architectural pattern needed)
- **Rationale**: This is a documentation task, not a software architecture task. We're improving workflow documentation clarity through three distinct edits to `.claude/commands/cig-retrospective.md`
- **Trade-offs**:
  - **Benefits**: Simple, focused, low-risk changes
  - **Drawbacks**: Step renumbering is breaking change for user muscle memory (mitigated by documenting in commit)

### Documentation Structure
- **File**: `.claude/commands/cig-retrospective.md` (single file modification)
- **Format**: Markdown with YAML frontmatter
- **Rationale**: Existing CIG command file structure, no new files needed

## System Design
### Edit Components (Three Improvements)
This task involves three independent documentation improvements to the retrospective workflow:

**Edit 1: Sequential Step Numbering (FR1)**
- **Current state**: Steps numbered 1, 1.5, 2, 3, 4, 5, 6, 7, (implied 7.5), 8
- **Target state**: Steps numbered 1-10 sequentially
- **Scope**: Renumber main workflow steps (lines ~31-121)
- **Impact**: Breaking change for user muscle memory, but necessary for clarity
- **Validation**: Search codebase for references to "Step 1.5", "Step 7.5", "Step 8" that need updating

**Edit 2: BACKLOG.md Synchronization Step (FR2)**
- **Current state**: Step missing entirely
- **Target state**: New Step 9 "Update BACKLOG.md" (based on current file reading, this appears already added as Step 9)
- **Location**: Between "Execute Retrospective" and "Prepare Final Commit"
- **Content structure**:
  1. Check for completed BACKLOG items → mark complete or remove
  2. Check retrospective for new items → add to BACKLOG.md
  3. Stage BACKLOG.md if modified
  4. Rationale explaining why this step matters
- **Examples**: Two concrete scenarios from Task 20

**Edit 3: Commit Message Guidance (FR3)**
- **Current state**: Final commit step shows examples but lacks principles
- **Target state**: Explicit guidance section before commit examples in Step 10
- **Content structure**:
  - Concise title (~50 chars)
  - Body explains "why" not "what"
  - Technical details non-obvious from code
  - Anti-pattern: Redundant suffixes
  - Co-Authored-By line
- **Format**: 3-5 bullet points (concise, scannable)

### Edit Order (Sequential Implementation)
1. **First**: Verify current state (read file, check if edits already exist)
2. **Second**: Complete any missing edits from FR1-FR3
3. **Third**: Search codebase for broken references
4. **Fourth**: Update any references found
5. **Fifth**: Validate all edits against acceptance criteria

## Interface Design
### File Structure
**Target File**: `.claude/commands/cig-retrospective.md`

**Current Structure**:
```
---
YAML frontmatter (metadata)
---
## Context
## Your task
Follow the N-step workflow structure:
  1. Resolve Task Directory
  2. Verify Git Branch (originally 1.5)
  3. Load Parent Context (originally 2)
  ...
  8. Execute Retrospective (originally 7)
  9. Update BACKLOG.md (NEW - appears already added)
  10. Prepare Final Commit (originally 8)
## Success Criteria
```

**Target Structure** (after improvements):
- Steps 1-10 with sequential numbering (no decimals)
- Step 9 includes BACKLOG.md synchronization workflow with examples
- Step 10 includes commit message guidance before commit examples

### Documentation Content Model
**Step Structure Template**:
```markdown
N. **Step Name**:

Brief introduction explaining purpose

[Workflow instructions with numbered sub-steps]

[Optional: Code examples in bash blocks]

[Optional: Rationale explaining why this step matters]
```

**Example Application (Step 9 - BACKLOG.md Update)**:
```markdown
9. **Update BACKLOG.md**:

Synchronise BACKLOG.md with task completion and retrospective findings:

1. **Check for completed BACKLOG items**:
   - Review BACKLOG.md for items this task addressed
   - Mark items complete or remove them
   - Example: Task 20 completed "Fix d-implementation.md Template"

2. **Check retrospective for new items**:
   - Review h-retrospective.md Recommendations section
   - Add new tasks identified during retrospective
   - Example: Task 20 identified "Rename Constraints headers"

3. **Stage changes if modified**:
   ```bash
   git add BACKLOG.md
   ```

**Rationale**: BACKLOG.md synchronisation ensures completed work
is tracked and new discoveries captured atomically with task completion.
```

## Constraints
### Technical Constraints
- **Single file modification**: All changes confined to `.claude/commands/cig-retrospective.md`
- **Markdown format**: Must maintain valid markdown with YAML frontmatter
- **YAML frontmatter**: Must preserve allowed-tools configuration for security
- **Backward compatibility**: Existing tasks using old step numbers still work (documentation-only change)

### Usability Constraints
- **Breaking change**: Step renumbering breaks user muscle memory for the retrospective workflow
  - **Mitigation**: Document change clearly in commit message
  - **Justification**: Clarity improvement outweighs temporary disruption
- **Conciseness**: Commit guidance must be 3-5 bullet points (NFR2)
- **Actionable examples**: BACKLOG.md workflow must show concrete file edits (NFR2)

### Maintainability Constraints
- **Zero broken references**: Must search codebase for references to old step numbers and update them (NFR1)
- **Clear section headers**: Must maintain scannable structure
- **Preserve functionality**: All existing workflow steps must continue to work as before

## Validation
### Design Review Checklist
- [x] **Edit approach defined**: Three independent documentation improvements (FR1-FR3)
- [x] **Implementation order specified**: Sequential verification → edits → reference check → validation
- [x] **Content structure documented**: Step template and examples provided
- [x] **Constraints identified**: Technical, usability, and maintainability constraints documented
- [x] **Risk assessment**: Breaking change acknowledged with mitigation strategy

### Pre-Implementation Verification
Before starting implementation, verify:
- [ ] Current file state matches expectations (check if edits already exist)
- [ ] Step 9 BACKLOG.md workflow already present (appears to be added based on reading)
- [ ] Step 10 commit guidance already present (appears to be added based on reading)
- [ ] If edits exist, validate against acceptance criteria
- [ ] If edits missing, identify which FRs need implementation

### Acceptance Criteria Mapping
- **AC1** (FR1 - Sequential numbering): Verify steps 1-10 without decimals ✓ (appears done)
- **AC2** (FR2 - BACKLOG.md step): Verify Step 9 has workflow + examples ✓ (appears done)
- **AC3** (FR3 - Commit guidance): Verify Step 10 has guidance before examples ✓ (appears done)
- **AC4** (NFR1 - No broken refs): Search codebase for old step references (pending)
- **AC5** (NFR2 - Actionable examples): Verify BACKLOG.md examples show file edits (pending)
- **AC6** (NFR2 - Concise guidance): Verify commit guidance is 3-5 bullets (pending)
- **AC7** (Testing): Test workflow with example task (pending)

## Status
**Status**: Finished
**Next Action**: Proceed to implementation phase (d-implementation.md)
**Blockers**: None identified

## Design Summary
This task improves the retrospective workflow documentation through three targeted edits:

1. **Sequential Step Numbering**: Renumber workflow steps 1-10 (eliminating fractional steps 1.5, 7.5)
2. **BACKLOG.md Synchronization**: Add explicit Step 9 for updating BACKLOG.md when tasks complete
3. **Commit Message Guidance**: Add principles section to Step 10 before commit examples

**Key Finding**: Initial file reading suggests all three improvements may already be implemented in `.claude/commands/cig-retrospective.md`. Implementation phase will verify current state and complete any missing pieces.

**Implementation Strategy**:
- Verify current file state against acceptance criteria
- Complete any missing edits
- Search codebase for broken references to old step numbers
- Update any found references
- Validate all changes against AC1-AC7

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
