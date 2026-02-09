# clarify instructions for backlog changelog mgmt - Implementation Plan
**Task**: 45 (bugfix)

## Task Reference
- **Task ID**: internal-45
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/45-clarify-instructions-for-backlog-changelog-mgmt
- **Template Version**: 2.1

## Goal
Implement clarify instructions for backlog changelog mgmt following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.claude/commands/cig-retrospective.md` - Enhance Step 9 with explicit CHANGELOG/BACKLOG workflow instructions

### Supporting Changes
None - single file documentation update

## Implementation Steps
### Step 1: Read Current State
- [ ] Read `.claude/commands/cig-retrospective.md` to locate Step 9 (around lines 117-136)
- [ ] Identify exact text to replace in Step 9

### Step 2: Implement Enhanced Step 9
- [ ] Replace Step 9 content with new 4-substep workflow (9.1-9.4)
- [ ] Step 9.1: Add CHANGELOG.md update instructions with tool guidance
- [ ] Step 9.2: Add BACKLOG.md cleanup instructions with Grep tool usage
- [ ] Step 9.3: Add new BACKLOG items instructions with format spec
- [ ] Step 9.4: Add git staging for both files
- [ ] Add rationale paragraph explaining CHANGELOG/BACKLOG synchronization
- [ ] Add token-efficient approach paragraph with tool guidance

### Step 3: Verification
- [ ] Verify Edit tool applied changes correctly
- [ ] Read modified section to confirm all 4 substeps present
- [ ] Verify tool guidance (Grep, Read with limit, Edit) is clear
- [ ] Verify examples reference Task 40 and Task 44

## Code Changes
### Before
Current Step 9 in `.claude/commands/cig-retrospective.md` (lines ~117-136):

```markdown
9. **Update BACKLOG.md**:

Synchronise BACKLOG.md with task completion and retrospective findings:

9.1. **Check for completed BACKLOG items**:
   - Review BACKLOG.md for items this task addressed
   - Mark items complete or remove them from BACKLOG.md
   - Example: Task 20 completed "Fix d-implementation.md Template to Reference e-testing.md"

9.2. **Check retrospective for new items**:
   - Review h-retrospective.md Recommendations/Future Work sections
   - Add new tasks identified during retrospective to BACKLOG.md
   - Example: Task 20 identified "Rename Constraints section headers in templates"

9.3. **Stage changes if BACKLOG.md modified**:
   ```bash
   git add BACKLOG.md
   ```

**Rationale**: BACKLOG.md synchronisation ensures completed work is tracked and new discoveries captured atomically with task completion.
```

**Problems**:
- "Mark items complete" is ambiguous (mark how? where?)
- CHANGELOG.md updates never mentioned
- No tool guidance (agents don't know to use Grep for efficient search)
- Only stages BACKLOG.md, not CHANGELOG.md

### After
Enhanced Step 9 with explicit 4-substep workflow:

```markdown
9. **Update CHANGELOG.md and BACKLOG.md**:

Document completed work and synchronize backlog with task completion:

9.1. **Update CHANGELOG.md with task completion**:
   - Read CHANGELOG.md (first ~100 lines using Read tool with limit parameter) to understand format pattern
   - Create new entry at top using Edit tool for current task including:
     - Task number and title
     - Completion date, duration vs estimate
     - What problems were addressed
     - Key changes made
     - BACKLOG items completed (if any)
   - Follow existing entry style - keep it concise
   - Example: See Task 40 entry for reference format

9.2. **Remove completed BACKLOG items**:
   - Use Grep tool to find all task headers in BACKLOG.md (pattern: `^## Task:`)
   - This returns line numbers efficiently - agent can see all tasks at a glance
   - If details needed to confirm completion, use Read with offset/limit around specific line numbers
   - Use Edit tool to remove completed items (they're now documented in CHANGELOG)
   - Note in CHANGELOG entry which BACKLOG items were addressed
   - Example: Task 40 removed "Complete Helper Script Migration to Trampoline Pattern"

9.3. **Add new BACKLOG items**:
   - Read j-retrospective.md Recommendations/Future Work sections
   - Add new items to BACKLOG.md using Edit tool with standard format:
     - `## Task: {descriptive-name}`
     - `**Task-Type**: bugfix|chore|feature|hotfix|discovery`
     - `**Priority**: High|Medium|Low`
     - `**Status**: Follow-up from Task X`
     - Description, Problems, Solution, Scope, Rationale
     - `**Identified in**: Task X retrospective (j-retrospective.md)`
   - Example: Task 44 added "Clarify Maintenance Phase Applicability"

9.4. **Stage changes**:
   ```bash
   git add CHANGELOG.md BACKLOG.md
   ```

**Rationale**: CHANGELOG documents what was accomplished, BACKLOG tracks future work. Synchronizing atomically ensures project history is complete and work items properly tracked.

**Token-Efficient Approach**:
- Use Read with offset/limit to sample existing format (don't read entire files)
- Use Grep to find task headers with line numbers (efficient task discovery)
- Use Edit for targeted changes (preserves formatting, more reliable than Write)
- Let agent match existing patterns rather than rigid templates
```

**Improvements**:
- Explicit CHANGELOG update instruction (9.1)
- Clarifies "mark complete" means remove from BACKLOG, add to CHANGELOG (9.2)
- Tool guidance: Grep for search, Read with limit for patterns, Edit for changes
- Stages both files atomically (9.4)
- Token-efficient approach section guides optimal tool usage

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

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
**Next Action**: Move to testing planning → `/cig-testing-plan 45`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
