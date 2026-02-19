# Fix template-copier-v2.1 uninitialized variable warnings - Implementation Plan
**Task**: 74 (bugfix)

## Task Reference
- **Task ID**: internal-74
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/74-fix-template-copier-v2.1-uninitialized-variable-warn
- **Template Version**: 2.1

## Goal
Two targeted line edits to `build_template_vars` in `template-copier-v2.1`, plus security hash update.

## Files to Modify
- `.cwf/scripts/command-helpers/template-copier-v2.1` — fix `build_template_vars`
- `.cwf/security/script-hashes.json` — update SHA256 for `template-copier-v2.1`

## Implementation Steps

### Step 1: Fix config key path (line 354)
- [ ] Change:
  ```perl
  my $pattern = $config->{'branch-naming-convention'} // '';
  ```
  To:
  ```perl
  my $pattern = $config->{'source-management'}{'branch-naming-convention'} // '';
  ```

### Step 2: Fix brace format in substitution regex (lines 368-370)
- [ ] Change:
  ```perl
  $branch =~ s/\{\{task-type\}\}/$params->{task_type}/g;
  $branch =~ s/\{\{task-id\}\}/$params->{task_num}/g;
  $branch =~ s/\{\{description-slug\}\}/$slug/g;
  ```
  To:
  ```perl
  $branch =~ s/\{task-type\}/$params->{task_type}/g;
  $branch =~ s/\{task-id\}/$params->{task_num}/g;
  $branch =~ s/\{description-slug\}/$slug/g;
  ```

### Step 3: Update security hash
- [ ] Run `sha256sum .cwf/scripts/command-helpers/template-copier-v2.1`
- [ ] Update `template-copier-v2.1` entry in `.cwf/security/script-hashes.json`
- [ ] Run `.cwf/scripts/cwf-manage validate` — must pass clean

## Validation Criteria
- `Branch` field in generated templates = correct branch name (e.g. `bugfix/74-fix-...`)
- No Perl warnings on stderr during `task-workflow create`
- `cwf-manage validate` passes

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 74
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 3 steps executed as planned. Steps 1 and 2 applied with one minor addition: an inline
comment explaining the single-brace convention. Security hash updated; validate passes.

## Lessons Learned
Plan was accurate; no surprises. Verifying adjacent call sites at lines 175 and 192
(identified as a risk) took minimal time and confirmed no changes needed.
