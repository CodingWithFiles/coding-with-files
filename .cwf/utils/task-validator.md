# CWF Task Validator

## Purpose
Validate task arguments and ensure compliance with project configuration.

## Task Type Validation
Check against `supported-task-types` in `cwf-project.json`:
- **Standard types**: feature, bugfix, hotfix, chore
- **Optional types**: docs, refactor, test, style, ci, build

## Task ID Validation
Validate against `task-id-template` regex patterns:

### GitHub Pattern: `#[::digit::]{1,}`
- Valid: `#123`, `#4567`
- Invalid: `123`, `PROJ-123`

### Jira Pattern: `[::upper::]{2,10}-[::digit::]{1,}`  
- Valid: `PROJ-123`, `ECOMMERCE-4567`
- Invalid: `#123`, `proj-123`, `VERYLONGPROJECTNAME-123`

### Custom Patterns
- Linear: `[::upper::]{2,5}-[::digit::]{1,}`
- Monday: `PULSE-[::digit::]{1,}`

## Description Validation
- **Slug generation**: Convert to filesystem-safe format
- **Length limits**: Respect `branch-name-max-length` when generating branches
- **Special characters**: Replace with hyphens for directory names

## Template File Validation
Ensure required templates exist for task type:
- **Feature**: plan.md, requirements.md, design.md, testing.md, rollout.md, maintenance.md
- **Bugfix**: plan.md, implementation.md, testing.md, rollout.md
- **Hotfix**: plan.md, implementation.md, rollout.md  
- **Chore**: plan.md, implementation.md, validation.md, maintenance.md

## Error Handling
**Error**: Unsupported task type specified
**Cause**: Task type not in `supported-task-types` array
**Solution**: Use supported type or update `cwf-project.json` configuration
**Example**: Supported types are: feature, bugfix, hotfix, chore
**Uncertainty**: If task type ambiguous, suggest closest match and ask for confirmation