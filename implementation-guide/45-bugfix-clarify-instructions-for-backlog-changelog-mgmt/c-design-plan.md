# clarify instructions for backlog changelog mgmt - Design
**Task**: 45 (bugfix)

## Task Reference
- **Task ID**: internal-45
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/45-clarify-instructions-for-backlog-changelog-mgmt
- **Template Version**: 2.1

## Goal
Define architecture and design decisions for clarify instructions for backlog changelog mgmt.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Architecture Choice
- **Decision**: Enhance Step 9 in `.claude/commands/cig-retrospective.md` with explicit CHANGELOG/BACKLOG workflow
- **Rationale**:
  - Minimal invasive change (single file, single step enhancement)
  - Preserves existing retrospective workflow structure
  - Leverages existing tools (Read, Edit, Grep) agents already know
  - Progressive disclosure pattern - instructs agents to read existing patterns first
- **Trade-offs**:
  - **Benefits**: Simple, clear, token-efficient, follows existing patterns
  - **Drawbacks**: Requires agents to infer CHANGELOG format (but this is intentional - prevents rigid templates that become stale)

### Implementation Approach
- **Tool Strategy**: Use Grep for efficient BACKLOG task discovery (returns line numbers), Read with offset/limit for pattern learning, Edit for targeted changes
- **Guidance Level**: Directive not prescriptive - tell agents what to do and which tools to use, let them decide exact format based on existing patterns
- **Example References**: Point to Task 40 and Task 44 as reference implementations

## System Design
### Component Overview
Single component: `.claude/commands/cig-retrospective.md` Step 9

**Current behavior** (problematic):
- Step 9.1: "Mark items complete or remove them from BACKLOG.md" - ambiguous
- CHANGELOG.md updates never mentioned
- No guidance on tool usage (Read vs Grep, Edit vs Write)

**New behavior** (enhanced):
- Step 9.1: Update CHANGELOG.md (explicit instruction to add entry at top)
- Step 9.2: Remove completed BACKLOG items (clarifies "mark complete" means move to CHANGELOG)
- Step 9.3: Add new BACKLOG items from retrospective
- Step 9.4: Stage both files atomically
- Tool guidance embedded in each step

### Data Flow
1. Agent executes retrospective phase → reaches Step 9
2. Step 9.1: Agent reads CHANGELOG.md (limit ~100 lines) → sees pattern → creates new entry using Edit
3. Step 9.2: Agent uses Grep to find BACKLOG task headers → gets line numbers → optionally reads details with offset/limit → removes completed items using Edit
4. Step 9.3: Agent reads retrospective recommendations → adds new BACKLOG items using Edit
5. Step 9.4: Agent stages both files atomically (git add CHANGELOG.md BACKLOG.md)

## Interface Design
### Input Interface
- **File to modify**: `.claude/commands/cig-retrospective.md`
- **Section**: Step 9 (lines ~117-136)
- **Current content**: BACKLOG-only instructions with ambiguous "mark complete" language

### Output Interface
- **Enhanced Step 9**: Four sub-steps (9.1-9.4) with explicit tool guidance
- **Structure**:
  - 9.1: CHANGELOG update (what, how, which tools, example)
  - 9.2: BACKLOG cleanup (what, how, which tools, example)
  - 9.3: BACKLOG additions (what, how, format spec, example)
  - 9.4: Git staging (both files)
  - Rationale paragraph explaining why
  - Token-efficient approach paragraph with tool guidance

### Content Specifications
**Step 9.1 (CHANGELOG update)**:
- Instruct: Read CHANGELOG.md with limit parameter to see pattern
- Instruct: Use Edit tool to add entry at top
- Specify: What to include (task num, date, duration, problems, changes, BACKLOG items)
- Example: Reference Task 40

**Step 9.2 (BACKLOG cleanup)**:
- Instruct: Use Grep tool with pattern `^## Task:` to find headers with line numbers
- Instruct: Optionally use Read with offset/limit if details needed
- Instruct: Use Edit tool to remove completed items
- Clarify: Completed items now live in CHANGELOG
- Example: Reference Task 40

**Step 9.3 (BACKLOG additions)**:
- Instruct: Read retrospective Recommendations/Future Work
- Instruct: Use Edit tool to add new items
- Specify: Required fields (Task-Type, Priority, Status, Description, Identified in)
- Example: Reference Task 44

## Constraints
- **Must work within existing retrospective workflow**: Cannot add new phases or reorder steps
- **Must use existing tools**: Read, Edit, Grep, Bash (no new tool requirements)
- **Must be token-efficient**: Use Read with limit/offset, Grep for search, Edit for changes (not Write)
- **Must support progressive disclosure**: Point agents to existing patterns, don't create rigid templates
- **Must be backward compatible**: Existing tasks unaffected, only future retrospectives improved
- **Must prevent skips**: Explicit numbered steps with clear actions prevent LLM from skipping

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? If yes, consider decomposition
- [ ] **People**: Does this need >2 people working on different parts? If yes, consider decomposition
- [ ] **Complexity**: Does this involve 3+ distinct concerns? If yes, consider decomposition
- [ ] **Risk**: Are there high-risk components that need isolation? If yes, consider decomposition
- [ ] **Independence**: Can parts be worked on separately? If yes, consider decomposition

## Validation
- [ ] Design review completed
- [ ] Architecture approved by team
- [ ] Integration points verified

## Status
**Status**: Finished
**Next Action**: Move to implementation planning → `/cig-implementation-plan 45`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
