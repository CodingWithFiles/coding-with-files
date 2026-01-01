# Add discovery workflow - Design

## Task Reference
- **Task ID**: internal-9
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/9-add-discovery-workflow
- **Template Version**: 2.0

## Goal
Add discovery task type using existing template pool and symlink architecture.

## Design Priorities
Consistency → Simplicity (follow existing patterns exactly)

## Key Decisions
### Architecture Choice
- **Decision**: Symlink-based template pool (same as existing task types)
- **Rationale**: DRY principle - no duplicate template content
- **Trade-offs**: Requires understanding symlink structure, but eliminates maintenance burden

### Template Selection
- **Decision**: 6 templates (a, b, c, d, e, h) - skip f-rollout and g-maintenance
- **Rationale**: Discovery tasks are research/analysis - no deployment phase
- **Reference**: Matches lensman implementation

## File Changes

### 1. Configuration: `implementation-guide/cig-project.json`
Add to `supported-task-types` array:
```json
"supported-task-types": [
  "feature",
  "bugfix",
  "hotfix",
  "chore",
  "discovery"
]
```

### 2. Templates: `.cig/templates/discovery/`
Create directory with 6 symlinks:
```
a-plan.md.template -> ../pool/a-plan.md.template
b-requirements.md.template -> ../pool/b-requirements.md.template
c-design.md.template -> ../pool/c-design.md.template
d-implementation.md.template -> ../pool/d-implementation.md.template
e-testing.md.template -> ../pool/e-testing.md.template
h-retrospective.md.template -> ../pool/h-retrospective.md.template
```

### 3. Command: `.claude/commands/cig-new-task.md`
Update line 19: `type: feature|bugfix|hotfix|chore|discovery`
Add to template documentation: `**discovery**: 6 files (a, b, c, d, e, h)`

### 4. Documentation: `.cig/docs/workflow/workflow-overview.md`
Add discovery to task types section with description.

## Data Flow
```
/cig-new-task N discovery "desc"
    ↓
cig-new-task.md validates type against cig-project.json
    ↓
Reads symlinks from .cig/templates/discovery/
    ↓
Copies pool templates to task directory
    ↓
6 workflow files created (a, b, c, d, e, h)
```

## Validation
- [x] Design follows existing patterns
- [x] No new template content required
- [x] Matches lensman reference

## Status
**Status**: Finished
**Next Action**: Begin implementation
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
