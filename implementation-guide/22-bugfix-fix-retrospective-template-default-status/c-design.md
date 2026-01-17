# fix-retrospective-template-default-status - Design

## Task Reference
- **Task ID**: internal-22
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/22-fix-retrospective-template-default-status
- **Template Version**: 2.0

## Goal
Define architecture and design decisions for fix-retrospective-template-default-status.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Approach
- **Decision**: Direct template file edit (no architecture needed for template fix)
- **Rationale**: This is a simple bugfix to a markdown template file, not a software architecture task
- **Trade-offs**:
  - **Benefit**: Simple, focused change
  - **Drawback**: None - this is the only viable approach

### File to Modify
- **File**: `.cig/templates/pool/h-retrospective.md.template`
- **Location**: Lines 97-100 (Status section)
- **Change type**: Text substitution

## Change Specification

### Current State (Lines 97-100)
```markdown
## Status
**Status**: Finished
**Completion Date**: YYYY-MM-DD
**Sign-off**: Name/team who completed retrospective
```

### Target State (Proposed)
```markdown
## Status
**Status**: Backlog
**Next Action**: Begin retrospective
**Blockers**: None identified
**Completion Date**: YYYY-MM-DD
**Sign-off**: Name/team who completed retrospective
```

### Rationale for Design
1. **Status change**: "Backlog" → consistent with all other workflow templates (a-plan, c-design, d-implementation, e-testing, f-rollout, g-maintenance)
2. **Add "Next Action"**: Standard field present in all other templates
3. **Add "Blockers"**: Standard field present in all other templates
4. **Keep "Completion Date" and "Sign-off"**: Retrospective-specific fields that get filled when status changes to "Finished"

### Template Variable Compatibility
- Review: Status section does not contain template variables (`{{...}}`)
- Verification: template-copier.pl only substitutes variables in Task Reference section
- Conclusion: This change won't break template substitution

## Constraints
- **Template format compatibility**: Must maintain markdown structure that template-copier.pl expects
- **Backward compatibility**: Change only affects new tasks; existing tasks keep their current status
- **Consistency requirement**: Must match status field format of other workflow templates exactly

## Validation
- [x] Design review completed - change specified with before/after examples
- [x] Template variable compatibility verified - no substitution variables in Status section
- [x] Consistency check - matches format of other templates (a-plan, c-design, etc.)

## Status
**Status**: Finished
**Next Action**: Proceed to implementation phase (d-implementation.md)
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
