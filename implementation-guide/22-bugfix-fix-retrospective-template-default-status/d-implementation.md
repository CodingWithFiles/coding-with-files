# fix-retrospective-template-default-status - Implementation

## Task Reference
- **Task ID**: internal-22
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/22-fix-retrospective-template-default-status
- **Template Version**: 2.0

## Goal
Implement fix-retrospective-template-default-status following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cig/templates/pool/h-retrospective.md.template` - Fix default status from "Finished" to "Backlog"

### Supporting Changes
None - single file modification

## Implementation Steps
### Step 1: Read Current Template
- [x] Open `.cig/templates/pool/h-retrospective.md.template`
- [x] Locate Status section (lines 97-100)
- [x] Confirm current state matches design specification

### Step 2: Apply Template Fix
- [x] Edit Status section to change:
  - "Finished" → "Backlog"
  - Add "Next Action: Begin retrospective"
  - Add "Blockers: None identified"
- [x] Keep "Completion Date" and "Sign-off" fields

### Step 3: Verify Template Format
- [x] Confirm markdown formatting is correct
- [x] Verify no template variables (`{{...}}`) in Status section
- [x] Check consistency with other workflow templates (matches a-plan, c-design, etc.)

### Step 4: Test Template Substitution
- [x] Create test task using template-copier.pl
- [x] Verify h-retrospective.md has "Backlog" status ✓ (confirmed)
- [x] Verify template substitution works correctly ✓ (no errors)
- [x] Clean up test task

### Step 5: Validation
- [x] Template status changed from "Finished" to "Backlog" ✓
- [x] Template includes "Next Action" and "Blockers" fields ✓
- [x] Template substitution verified to work correctly ✓
- [x] New tasks created from template show "Backlog" status by default ✓

## Code Changes
### Before (.cig/templates/pool/h-retrospective.md.template lines 97-100)
```markdown
## Status
**Status**: Finished
**Completion Date**: YYYY-MM-DD
**Sign-off**: Name/team who completed retrospective
```

### After (.cig/templates/pool/h-retrospective.md.template lines 97-103)
```markdown
## Status
**Status**: Backlog
**Next Action**: Begin retrospective
**Blockers**: None identified
**Completion Date**: YYYY-MM-DD
**Sign-off**: Name/team who completed retrospective
```

## Test Coverage
**See e-testing.md for complete test plan**

## Validation Criteria
**See e-testing.md for validation criteria and test results**

## Status
**Status**: Finished
**Next Action**: Proceed to testing phase (e-testing.md)
**Blockers**: None identified

## Actual Results
**Implementation completed successfully**:
- Template file `.cig/templates/pool/h-retrospective.md.template` updated
- Status section changed from "Finished" to "Backlog"
- Added "Next Action" and "Blockers" fields for consistency
- Template substitution tested and verified working correctly
- New tasks will now show "Backlog" status instead of "Finished"

**All success criteria met** (from a-plan.md:13-18)

## Lessons Learned
*To be captured during implementation*
