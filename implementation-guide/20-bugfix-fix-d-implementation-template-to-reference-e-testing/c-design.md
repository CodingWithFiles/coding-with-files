# fix-d-implementation-template-to-reference-e-testing - Design

## Task Reference
- **Task ID**: internal-20
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/20-fix-d-implementation-template-to-reference-e-testing
- **Template Version**: 2.0

## Goal
Design template text replacements to eliminate duplication between d-implementation.md and e-testing.md templates.

## Design Priorities
Simplicity → Consistency → Readability (template maintenance task)

## Key Decisions
### Architecture Choice
- **Decision**: Replace duplicate sections with static text references to e-testing.md
- **Rationale**: Maintains single source of truth (DRY principle), eliminates confusion about where tests belong
- **Trade-offs**: None - pure improvement. Users must navigate to e-testing.md for test details, but that's the correct workflow anyway

### Replacement Strategy
- **Approach**: Direct text replacement (find-and-replace)
- **Rationale**: Simple, low-risk, no logic changes
- **Alternative considered**: Delete sections entirely - rejected because explicit reference is clearer than omission

## Template Changes

### Change 1: Test Coverage Section (Lines 67-70)

**Current text (lines 67-70)**:
```markdown
## Test Coverage
- Unit tests: Specific test cases for new functionality
- Integration tests: Test cases for interaction with existing systems
- Regression tests: Verify existing functionality still works
```

**New text**:
```markdown
## Test Coverage
**See e-testing.md for complete test plan**
```

**Rationale**: Removes placeholder bullet points that duplicate e-testing.md template structure. Clear pointer to actual test location.

### Change 2: Validation Criteria Section (Lines 72-76)

**Current text (lines 72-76)**:
```markdown
## Validation Criteria
- [ ] All tests pass
- [ ] Code review approved
- [ ] Performance requirements met
- [ ] Documentation updated
```

**New text**:
```markdown
## Validation Criteria
**See e-testing.md for validation criteria and test results**
```

**Rationale**: Removes generic checkboxes that belong in testing phase. Points to e-testing.md where actual test cases and validation criteria are defined.

### Preserved Content

**Keep unchanged**:
- Lines 1-66: Everything before "Test Coverage" section (Goal, Workflow, Files to Modify, Implementation Steps, Code Changes)
- Lines 78-88: Everything after "Validation Criteria" (Status, Actual Results, Lessons Learned)
- **Implementation Steps** (lines 25-48): Particularly Step 3 ("Testing") and Step 5 ("Validation") which correctly reference executing tests defined in e-testing.md

## Constraints
- Must preserve {{variable}} template substitution (no variables in replacement text)
- Must not break markdown formatting
- Must maintain section structure (## headers must remain)
- Only modify `.cig/templates/pool/d-implementation.md.template` (central template pool)

## Validation
- [x] Design review completed (user approved in backlog)
- [x] Change locations verified (lines 67-70, 72-76)
- [x] Replacement text confirmed not to use template variables
- [x] No impact on existing tasks (only affects future task creation)

## Status
**Status**: Finished
**Next Action**: Proceed to implementation
**Blockers**: None

## Actual Results
Design complete with exact text replacements specified:
- Change 1: Lines 67-70 (Test Coverage section) → single line reference
- Change 2: Lines 72-76 (Validation Criteria section) → single line reference
- Both changes maintain section headers and markdown formatting
- No template variables used in replacement text

## Lessons Learned
- Template maintenance requires precise before/after specifications
- Explicit references clearer than section deletion
- Preserving section structure maintains consistency across templates
