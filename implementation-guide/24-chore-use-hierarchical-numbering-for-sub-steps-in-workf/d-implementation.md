# Use Hierarchical Numbering for Sub-steps in Workflow Templates - Implementation

## Task Reference
- **Task ID**: internal-24
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/24-use-hierarchical-numbering-for-sub-steps-in-workf
- **Template Version**: 2.0

## Goal
Standardize workflow command file enumeration by: (1) converting sub-step numbering to hierarchical notation (N.1, N.2, N.3), and (2) converting main step format from markdown headers to numbered lists.

## Workflow
Audit → Pattern → Format standardization → Hierarchical conversion → Validation → Commit message explains "why"

## Files to Modify
### Primary Changes (8 workflow command files)
- `.claude/commands/cig-plan.md` - Convert `### Step N:` headers to `N. **Step Name**:` numbered lists
- `.claude/commands/cig-requirements.md` - Verify numbered list format (already correct)
- `.claude/commands/cig-design.md` - Verify numbered list format (already correct)
- `.claude/commands/cig-implementation.md` - Verify numbered list format (already correct)
- `.claude/commands/cig-testing.md` - Verify numbered list format (already correct)
- `.claude/commands/cig-rollout.md` - Verify numbered list format (already correct)
- `.claude/commands/cig-maintenance.md` - Verify numbered list format (already correct)
- `.claude/commands/cig-retrospective.md` - Convert sub-step numbering to hierarchical format (1→2.1, 2→2.2, etc.)

### Supporting Changes
None - this is a pure documentation formatting change

## Implementation Steps

### Step 1: Audit Current Sub-step Patterns
- [ ] Read all 8 workflow command files to identify locations where sub-steps restart at "1."
- [ ] Document parent step numbers for each sub-step group (e.g., Step 2 has sub-steps 1-3)
- [ ] Create checklist of all conversion points across 8 files

### Step 2: Define Conversion Pattern
- [ ] Establish systematic find-and-replace pattern for each file
- [ ] Pattern: Within Step N context, convert "1. **" → "N.1. **", "2. **" → "N.2. **", etc.
- [ ] Note: Must preserve context to avoid converting top-level steps

### Step 3: Convert cig-plan.md Main Step Format
- [ ] Read `.claude/commands/cig-plan.md`
- [ ] Identify all `### Step N:` markdown headers (Steps 1-8)
- [ ] Convert `### Step 1: Resolve Task Directory` → `1. **Resolve Task Directory**:`
- [ ] Convert `### Step 2: Load Parent Context` → `2. **Load Parent Context**:`
- [ ] Convert `### Step 3: Present Context Summary` → `3. **Present Context Summary**:`
- [ ] Convert `### Step 4: LLM Decision Point` → `4. **LLM Decision Point - Read Parent Details**:`
- [ ] Convert `### Step 5: Reference Workflow Documentation` → `5. **Reference Workflow Documentation**:`
- [ ] Convert `### Step 6: Execute Planning Workflow` → `6. **Execute Planning Workflow**:`
- [ ] Convert `### Step 7: Check Universal Decomposition Signals` → `7. **Check Universal Decomposition Signals**:`
- [ ] Convert `### Step 8: Suggest Next Steps with Reasoning` → `8. **Suggest Next Steps with Reasoning**:`
- [ ] Verify all 8 main steps now use numbered list format

### Step 4: Convert cig-retrospective.md Sub-step Numbering
- [ ] Read `.claude/commands/cig-retrospective.md`
- [ ] Identify Step 2 (Verify Git Branch) with sub-steps 1-3 → convert to 2.1-2.3
- [ ] Identify Step 7 (Verify Task Status) with sub-steps 1-2 → convert to 7.1-7.2
- [ ] Identify Step 9 (Update BACKLOG.md) with sub-steps 1-3 → convert to 9.1-9.3
- [ ] Identify Step 10 (Prepare Final Commit) with sub-steps 1-4 → convert to 10.1-10.4
- [ ] Apply hierarchical numbering to all identified sub-steps

### Step 5: Verify Remaining 6 Files Use Correct Format
- [ ] Verify cig-requirements.md uses `N. **Step Name**:` format (already correct)
- [ ] Verify cig-design.md uses `N. **Step Name**:` format (already correct)
- [ ] Verify cig-implementation.md uses `N. **Step Name**:` format (already correct)
- [ ] Verify cig-testing.md uses `N. **Step Name**:` format (already correct)
- [ ] Verify cig-rollout.md uses `N. **Step Name**:` format (already correct)
- [ ] Verify cig-maintenance.md uses `N. **Step Name**:` format (already correct)
- [ ] Confirm none of these files have sub-steps that restart at "1."

### Step 6: Validate Consistency Across All Files
- [ ] Verify all 8 files use `N. **Step Name**:` format for main steps
- [ ] Verify all 8 files use hierarchical numbering (N.M) for sub-steps where they exist
- [ ] Check no sub-steps restart at "1." within parent steps
- [ ] Grep for any remaining format violations: `### Step` or `^\s*1\. \*\*` within step contexts
- [ ] Verify markdown renders correctly in Claude Code interface

### Step 7: Check for Broken References
- [ ] Search all 8 files for references to step numbers (e.g., "Step 1", "see step 2")
- [ ] Update any cross-references if step numbering changed
- [ ] Verify no documentation refers to old numbering patterns or header format

## Code Changes

### Example: cig-retrospective.md Step 2 (Verify Git Branch)

**Before:**
```markdown
2. **Verify Git Branch**:

Before proceeding with retrospective, verify you're on the correct task branch:

1. **Check current branch**:
   ```bash
   git branch --show-current
   ```

2. **Expected branch format**:
   - Feature: `feature/<task-num>-<slug>`
   - Bugfix: `bugfix/<task-num>-<slug>`
   - Hotfix: `hotfix/<task-num>-<slug>`
   - Chore: `chore/<task-num>-<slug>`

3. **If on wrong branch**:
   - STOP execution
   - Inform user they should be on task branch for retrospective
   - Suggest checking out correct branch: `git checkout <task-branch>`
   - Do not proceed with retrospective until on correct branch
```

**After:**
```markdown
2. **Verify Git Branch**:

Before proceeding with retrospective, verify you're on the correct task branch:

2.1. **Check current branch**:
   ```bash
   git branch --show-current
   ```

2.2. **Expected branch format**:
   - Feature: `feature/<task-num>-<slug>`
   - Bugfix: `bugfix/<task-num>-<slug>`
   - Hotfix: `hotfix/<task-num>-<slug>`
   - Chore: `chore/<task-num>-<slug>`

2.3. **If on wrong branch**:
   - STOP execution
   - Inform user they should be on task branch for retrospective
   - Suggest checking out correct branch: `git checkout <task-branch>`
   - Do not proceed with retrospective until on correct branch
```

**Pattern:** Within Step N context, sub-steps numbered "1., 2., 3." become "N.1., N.2., N.3."

**Impact:** Eliminates ambiguity - reader immediately knows "2.1" is a sub-step of Step 2, not a top-level step

## Test Coverage
**See e-testing.md for complete test plan**

## Validation Criteria
**See e-testing.md for validation criteria and test results**

## Status
**Status**: Finished
**Next Action**: Proceed to testing phase with `/cig-testing 24`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

**Implementation Summary**:
- **Files Modified**: 2 workflow command files (.claude/commands/cig-plan.md, .claude/commands/cig-retrospective.md)
- **Total Changes**: 20 step conversions (8 main steps in cig-plan.md + 12 sub-steps in cig-retrospective.md)

**Detailed Results**:

1. **cig-plan.md Conversion** (Step 3):
   - Converted 8 markdown headers (`### Step N:`) to numbered list format (`N. **Step Name**:`)
   - Steps 1-8 now use consistent numbered list pattern
   - No broken references found

2. **cig-retrospective.md Conversion** (Step 4):
   - Converted 12 sub-steps to hierarchical notation:
     - Step 2: 1,2,3 → 2.1, 2.2, 2.3
     - Step 7: 1,2 → 7.1, 7.2
     - Step 9: 1,2,3 → 9.1, 9.2, 9.3
     - Step 10: 1,2,3,4 → 10.1, 10.2, 10.3, 10.4
   - Cross-reference validated: "Proceed to Step 8" remains correct

3. **Remaining 6 Files Verification** (Step 5):
   - Confirmed cig-requirements, cig-design, cig-implementation, cig-testing, cig-rollout, cig-maintenance already use correct format
   - No changes needed for these files

4. **Consistency Validation** (Step 6):
   - All 8 workflow files now use `N. **Step Name**:` format for main steps
   - Only cig-retrospective.md uses hierarchical sub-steps (N.M format)
   - No sub-steps restart at "1." within parent steps anywhere

5. **Reference Check** (Step 7):
   - 1 cross-reference found and validated in cig-retrospective.md
   - No broken references detected

## Lessons Learned
*To be captured during implementation*
