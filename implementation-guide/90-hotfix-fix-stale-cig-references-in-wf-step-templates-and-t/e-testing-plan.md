# Fix stale CIG references in wf step templates and template-copier - Testing Plan
**Task**: 90 (hotfix)

## Task Reference
- **Task ID**: internal-90
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/90-fix-stale-cig-references-in-wf-step-templates-and-t
- **Template Version**: 2.1

## Goal
Verify all stale CIG references are removed from templates and template-copier,
and that no regressions are introduced.

## Test Strategy
- **Static**: grep-based checks — fast, exhaustive, no test harness needed
- **Regression**: `prove t/` and `cwf-manage validate`
- No new unit tests warranted — changes are pure string replacements with no logic

---

## Test Cases

### TC-1: Templates have no `.cig/` path references
- **Given**: all 10 `.cwf/templates/pool/*.template` files updated
- **When**: `grep -r "\.cig/" .cwf/templates/`
- **Then**: no matches

### TC-2: Each template has the correct `.cwf/` path
- **Given**: all 10 templates updated
- **When**: `grep -c "\.cwf/docs/workflow/workflow-steps.md" .cwf/templates/pool/*.template`
- **Then**: each file shows count of 1

### TC-3: `template-copier-v2.1` has no `/cig-` references
- **Given**: both lines 332 and 399 updated
- **When**: `grep "/cig-" .cwf/scripts/command-helpers/template-copier-v2.1`
- **Then**: no matches

### TC-4: `template-copier-v2.1` emits `/cwf-` skill names
- **Given**: `name_to_action` updated
- **When**: `grep "/cwf-" .cwf/scripts/command-helpers/template-copier-v2.1`
- **Then**: two matches (lines 332 and 399)

### TC-5: Broad sweep — nothing else missed in `.cwf/`
- **Given**: fixes applied
- **When**: `grep -r "\.cig/\|/cig-" .cwf/`
- **Then**: no matches

### TC-6: `cwf-manage validate` passes
- **Given**: script hash updated in `script-hashes.json`
- **When**: `.cwf/scripts/cwf-manage validate`
- **Then**: exits 0, `[CWF] validate: OK`

### TC-7: Full test suite — no regressions
- **Given**: fixes applied
- **When**: `prove t/`
- **Then**: all tests pass

---

## Validation Criteria
- [ ] TC-1: no `.cig/` in templates
- [ ] TC-2: `.cwf/` path present in all 10 templates
- [ ] TC-3: no `/cig-` in template-copier-v2.1
- [ ] TC-4: `/cwf-` present at both fix sites
- [ ] TC-5: broad sweep clean
- [ ] TC-6: validate OK
- [ ] TC-7: `prove t/` clean

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 90
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 7 TCs passed. TC-5 broad sweep was the most valuable — confirmed no stale
references remained anywhere in .cwf/ beyond the two known fix sites.

## Lessons Learned
Grep-based static checks are sufficient and fast for pure string-replacement hotfixes.
No unit test infrastructure needed.
