# Add "Blocked" to Standard Status Values - Implementation

## Task Reference
- **Task ID**: internal-23
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/23-add-blocked-to-standard-status-values
- **Template Version**: 2.0

## Goal
Add "Blocked" status with 15% completion to CIG system configuration, documentation, commands, and templates.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes (FR1-FR4)
- `implementation-guide/cig-project.json` - Add "Blocked": 15 to workflow.status-values (FR4)
- `.cig/docs/workflow/workflow-steps.md` - Add "Blocked" to status values documentation (FR1)

### Template Files (FR3 - 8 files) - Progressive Disclosure
- `.cig/templates/pool/a-plan.md.template` - Add HTML comment referencing workflow-steps.md
- `.cig/templates/pool/b-requirements.md.template` - Add HTML comment referencing workflow-steps.md
- `.cig/templates/pool/c-design.md.template` - Add HTML comment referencing workflow-steps.md
- `.cig/templates/pool/d-implementation.md.template` - Add HTML comment referencing workflow-steps.md
- `.cig/templates/pool/e-testing.md.template` - Add HTML comment referencing workflow-steps.md
- `.cig/templates/pool/f-rollout.md.template` - Add HTML comment referencing workflow-steps.md
- `.cig/templates/pool/g-maintenance.md.template` - Add HTML comment referencing workflow-steps.md
- `.cig/templates/pool/h-retrospective.md.template` - Add HTML comment referencing workflow-steps.md

### No Changes Needed
- Command files already follow progressive disclosure (reference workflow-steps.md, don't duplicate)

## Implementation Steps

### Step 1: Configuration Update (FR4)
- [x] Read `implementation-guide/cig-project.json` to verify current structure
- [x] Add "Blocked": 15 to workflow.status-values section
- [x] Maintain alphabetical or logical ordering of status values
- [x] Verify JSON syntax is valid

### Step 2: Documentation Update (FR1)
- [x] Read `.cig/docs/workflow/workflow-steps.md` status values section
- [x] Add "Blocked" (15%) entry with clear semantics
- [x] Position between "Backlog" (0%) and "In Progress" (25%)
- [x] Document when to use "Blocked" vs other statuses

### Step 3: Template Files Update (FR3) - Progressive Disclosure
- [x] Read current Status section format in templates
- [x] Add HTML comment referencing `.cig/docs/workflow/workflow-steps.md#status-values`
- [x] Follow progressive disclosure: reference, don't duplicate
- [x] Apply consistently to all 8 template files

### Step 4: Validation
- [x] Test status aggregator with "Blocked" status in Task 23's d-implementation.md (PASSED: 15% reported)
- [x] Verify existing tasks continue to report correct percentages (regression) (PASSED: Task 22 still 100%)
- [x] Verify all acceptance criteria (AC1-AC8) are met
- [x] Manual review of all modified files for consistency (Pattern: bold text reference)

## Code Changes

### Change 1: Configuration (cig-project.json)
**Before:**
```json
{
  "workflow": {
    "status-values": {
      "Backlog": 0,
      "To-Do": 0,
      "In Progress": 25,
      "Implemented": 50,
      "Testing": 75,
      "Finished": 100
    }
  }
}
```

**After:**
```json
{
  "workflow": {
    "status-values": {
      "Backlog": 0,
      "Blocked": 15,
      "To-Do": 0,
      "In Progress": 25,
      "Implemented": 50,
      "Testing": 75,
      "Finished": 100
    }
  }
}
```

### Change 2: Documentation (workflow-steps.md)
**Before:**
```markdown
### Valid Status Values

The following status values are defined in the project configuration:

- **Backlog** (0%): Task not started, queued for future work
- **To-Do** (0%): Task ready to begin, prioritized
- **In Progress** (25%): Work actively underway
- **Implemented** (50%): Code complete, not yet tested
- **Testing** (75%): Testing in progress, validation ongoing
- **Finished** (100%): Fully complete, all criteria met
```

**After:**
```markdown
### Valid Status Values

The following status values are defined in the project configuration:

- **Backlog** (0%): Task not started, queued for future work
- **Blocked** (15%): Task started but cannot proceed until blocker resolved
- **To-Do** (0%): Task ready to begin, prioritized
- **In Progress** (25%): Work actively underway
- **Implemented** (50%): Code complete, not yet tested
- **Testing** (75%): Testing in progress, validation ongoing
- **Finished** (100%): Fully complete, all criteria met
```

### Change 3: Template Files (8 files) - Progressive Disclosure
**Location Example:** `.cig/templates/pool/d-implementation.md.template`

**Before:**
```markdown
## Status
**Status**: Backlog
**Next Action**: Begin implementation
**Blockers**: None identified
```

**After:**
```markdown
## Status
**Status**: Backlog
**Next Action**: Begin implementation
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**
```

**Pattern Used:** Bold text reference matching existing template pattern (`**See e-testing.md...**`)

**Note:** Command files require no changes - they already follow progressive disclosure principle by referencing workflow-steps.md documentation.

## Test Coverage
**See e-testing.md for complete test plan**

## Validation Criteria
**See e-testing.md for validation criteria and test results**

## Status
**Status**: Finished
**Next Action**: Proceed to testing phase with `/cig-testing 23`
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
