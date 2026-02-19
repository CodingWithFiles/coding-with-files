# Fix template-copier-v2.1 uninitialized variable warnings - Design
**Task**: 74 (bugfix)

## Task Reference
- **Task ID**: internal-74
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/74-fix-template-copier-v2.1-uninitialized-variable-warn
- **Template Version**: 2.1

## Goal
Document the minimal fix for the two bugs in `build_template_vars` that cause `branchName` to always be empty.

## Key Decisions

### Fix 1: Config key path
- **Current**: `$config->{'branch-naming-convention'}`
- **Fixed**: `$config->{'source-management'}{'branch-naming-convention'}`
- **Rationale**: The key is nested one level deeper in `cwf-project.json`. The `// ''`
  default was masking the undef silently.

### Fix 2: Brace format in substitution regex
- **Current**: `s/\{\{task-type\}\}/…/g` (double braces — matches `{{task-type}}`)
- **Fixed**: `s/\{task-type\}/…/g` (single braces — matches `{task-type}`)
- **Rationale**: The config pattern uses single-brace placeholders
  (`{task-type}/{task-id}-{description-slug}`), not the double-brace template format
  used in `.md.template` files. The two systems use different placeholder syntaxes.

### No changes to other call sites
Lines 175 and 192 in template-copier-v2.1 call `load_config()` to check supported
task types (`$config->{'supported-task-types'}`), which IS a top-level key. No fix
needed there.

## Decomposition Check
- [ ] **Time**: No
- [ ] **People**: No
- [ ] **Complexity**: No — two lines in one function
- [ ] **Risk**: No
- [ ] **Independence**: No

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 74
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design is the fix itself — two targeted line changes confirmed correct by code reading.
Both fixes implemented exactly as designed; no deviations.

## Lessons Learned
When `// ''` guards a config lookup, it silently converts wrong-path undef to empty string.
Always verify the full key path when a field is unexpectedly empty rather than assuming
the guard is masking a missing value.
