# Fix template-copier undef warnings for unresolved variables - Implementation Plan
**Task**: 63 (bugfix)

## Task Reference
- **Task ID**: internal-63
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/63-fix-template-copier-undef-warnings
- **Template Version**: 2.1

## Goal
Apply two defined-or guards in template-copier-v2.1 to eliminate undef warnings, add sparse-checkout bootstrap to README/INSTALL.md, and update the security hash.

## Files to Modify

### Primary Changes
- `.cwf/scripts/command-helpers/template-copier-v2.1` — Two `// ''` guards

### Supporting Changes
- `.cwf/security/script-hashes.json` — Update template-copier-v2.1 hash
- `README.md` — Add sparse-checkout bootstrap sequence
- `INSTALL.md` — Add sparse-checkout bootstrap sequence

## Implementation Steps

### Step 1: Guard `$pattern` in `compute_variables()` (line 352)
- [ ] Change: `my $pattern = $config->{'branch-naming-convention'};`
- [ ] To: `my $pattern = $config->{'branch-naming-convention'} // '';`

### Step 2: Guard `$value` in `substitute_variables()` (line 384)
- [ ] Change: `my $value = $vars->{$key};`
- [ ] To: `my $value = $vars->{$key} // '';`

### Step 3: Add sparse-checkout bootstrap to README.md
- [ ] Add "Agent Install" or "Quick Install" section with:
  ```bash
  git clone --depth 1 --filter=blob:none --sparse <url> /tmp/cwf-bootstrap
  git -C /tmp/cwf-bootstrap sparse-checkout set scripts
  CWF_SOURCE=<url> bash /tmp/cwf-bootstrap/scripts/install.bash
  rm -rf /tmp/cwf-bootstrap
  ```
- [ ] Keep existing curl|bash path for GitHub users

### Step 4: Add sparse-checkout bootstrap to INSTALL.md
- [ ] Add matching bootstrap sequence to INSTALL.md

### Step 5: Verify
- [ ] `perl -c .cwf/scripts/command-helpers/template-copier-v2.1`
- [ ] `perlcritic --stern .cwf/scripts/command-helpers/template-copier-v2.1`

### Step 6: Security Hash Update
- [ ] Regenerate SHA256 for template-copier-v2.1 in `.cwf/security/script-hashes.json`

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
- Zero warnings when running `task-workflow create` with all params
- Zero warnings when running with missing config fields
- Existing template substitution still produces correct output
- `perl -c` and `perlcritic --stern` pass

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 63
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 6 planned steps completed. Two additional fixes applied: perlcritic stern violations and array deref guard found during external testing.

## Lessons Learned
When auditing a file for undef safety, grep for all dereference patterns in one pass rather than fixing reactively.
