# Fix template-copier-v2.1 uninitialized variable warnings - Plan
**Task**: 74 (bugfix)

## Task Reference
- **Task ID**: internal-74
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/74-fix-template-copier-v2.1-uninitialized-variable-warn
- **Template Version**: 2.1

## Goal
Fix `template-copier-v2.1` so that the `Branch` field in generated template files is
correctly populated from the project's branch-naming convention.

## Root Cause (discovered during planning)

Two bugs in `build_template_vars` (template-copier-v2.1):

1. **Wrong config key path** (line 354):
   ```perl
   my $pattern = $config->{'branch-naming-convention'} // '';
   ```
   The key `branch-naming-convention` is nested under `source-management` in
   `cwf-project.json`, so this always returns `undef` → `''` (empty string).
   Correct path: `$config->{'source-management'}{'branch-naming-convention'}`.

2. **Brace mismatch in substitution regex** (lines 368-370):
   The code searches for `\{\{task-type\}\}` (double braces) but the config pattern
   uses `{task-type}` (single braces). Even if the path were fixed, the substitution
   would never fire.
   Fix: change regex to `\{task-type\}`, `\{task-id\}`, `\{description-slug\}`.

Result: `$vars{branchName}` is always `''`, so `{{branchName}}` in templates
becomes blank, requiring manual fill-in at every task plan step.

## Success Criteria
- [x] `Branch` field in generated template files contains the correct branch name
      (e.g. `bugfix/74-fix-template-copier-v2.1-uninitialized-variable-warn`)
- [x] No uninitialized variable warnings during template copy
- [x] `cwf-manage validate` passes (security hash updated)
- [x] `cwf-new-task` end-to-end smoke test produces correct Branch field in all files

## Original Estimate
**Effort**: Trivial (<1 session)
**Complexity**: Low — two-line fix in a single function
**Dependencies**: None

## Major Milestones
1. **Fix**: Two-line change to `build_template_vars` in `template-copier-v2.1`
2. **Hash update**: Update security hash in `script-hashes.json`
3. **Test + retrospective**: Verify output and close out

## Risk Assessment

### Low Priority Risks
- **Other callers of `load_config`**: Two other call sites in template-copier-v2.1
  (lines 175, 192) also access config fields. Check they use correct paths.
  - **Mitigation**: Read those sections during implementation.

## Dependencies
- None

## Constraints
- `template-copier-v2.1` is security-hash-tracked — must update
  `.cwf/security/script-hashes.json` after edit

## Decomposition Check
- [ ] **Time**: No — trivial
- [ ] **People**: No
- [ ] **Complexity**: No — single function, two lines
- [ ] **Risk**: No
- [ ] **Independence**: No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: N/A — task complete
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Two targeted fixes to `build_template_vars` in `template-copier-v2.1`: corrected config
key path and substitution brace format. Branch field now populates correctly in all
generated templates. Security hash updated; validate passes. All success criteria met.

## Lessons Learned
Two silent bugs can compound: a `// ''` undef-guard hides a wrong config path (returns
`''` not undef), and a wrong brace format means substitution never fires — neither
produces a warning alone, together they silently produce blank output.
