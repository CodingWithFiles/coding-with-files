# Add discovery workflow - Implementation

## Task Reference
- **Task ID**: internal-9
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/9-add-discovery-workflow
- **Template Version**: 2.0

## Goal
Add discovery as a new supported task type.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `implementation-guide/cig-project.json` - Add discovery to supported-task-types
- `.cig/templates/discovery/` - Create directory with 6 symlinks
- `.claude/commands/cig-new-task.md` - Add discovery to type validation

### Supporting Changes
- `.cig/docs/workflow/workflow-overview.md` - Document discovery workflow

## Implementation Steps
### Step 1: Update Configuration
- [ ] Add `discovery` to supported-task-types in cig-project.json

### Step 2: Create Templates
- [ ] Create `.cig/templates/discovery/` directory
- [ ] Create symlink: a-plan.md.template -> ../pool/a-plan.md.template
- [ ] Create symlink: b-requirements.md.template -> ../pool/b-requirements.md.template
- [ ] Create symlink: c-design.md.template -> ../pool/c-design.md.template
- [ ] Create symlink: d-implementation.md.template -> ../pool/d-implementation.md.template
- [ ] Create symlink: e-testing.md.template -> ../pool/e-testing.md.template
- [ ] Create symlink: h-retrospective.md.template -> ../pool/h-retrospective.md.template

### Step 3: Update Command
- [ ] Update cig-new-task.md type validation to include discovery
- [ ] Add discovery to template documentation section

### Step 4: Update Documentation
- [ ] Add discovery to workflow-overview.md

### Step 5: Validation
- [ ] Test creating a discovery task
- [ ] Verify 6 files created (not 8)
- [ ] Verify /cig-status shows discovery task

## Code Changes
### cig-project.json - Before
```json
"supported-task-types": [
  "feature",
  "bugfix",
  "hotfix",
  "chore"
]
```

### cig-project.json - After
```json
"supported-task-types": [
  "feature",
  "bugfix",
  "hotfix",
  "chore",
  "discovery"
]
```

## Test Coverage
- Manual test: Create discovery task and verify 6 workflow files
- Integration test: /cig-status includes discovery task
- Regression test: Existing task types still work

## Validation Criteria
- [ ] cig-project.json includes discovery
- [ ] .cig/templates/discovery/ has 6 symlinks
- [ ] /cig-new-task accepts discovery type
- [ ] Created task has 6 files (a, b, c, d, e, h)

## Status
**Status**: Finished
**Next Action**: Execute implementation steps
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
