# Fix stale CIG references in wf step templates and template-copier - Implementation Plan
**Task**: 90 (hotfix)

## Task Reference
- **Task ID**: internal-90
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/90-fix-stale-cig-references-in-wf-step-templates-and-t
- **Template Version**: 2.1

## Goal
Two targeted string replacements to fix stale CIG references missed by Task 59.

## Files to Modify

### Primary Changes
- `.cwf/templates/pool/*.template` (all 10) — fix `.cig/docs/` → `.cwf/docs/` in Status footer
- `.cwf/scripts/command-helpers/template-copier-v2.1` — fix `/cig-` → `/cwf-` at lines 332 and 399

### Supporting Changes
- `.cwf/security/script-hashes.json` — update SHA256 for modified `template-copier-v2.1`

## Implementation Steps

### Step 1: Fix all 10 wf step templates
- [ ] In each `*.template` file, change:
  ```
  **See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**
  ```
  to:
  ```
  **See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**
  ```
- [ ] Files: `a-task-plan`, `b-requirements-plan`, `c-design-plan`, `d-implementation-plan`,
  `e-testing-plan`, `f-implementation-exec`, `g-testing-exec`, `h-rollout`,
  `i-maintenance`, `j-retrospective`

### Step 2: Fix `template-copier-v2.1`
- [ ] Line 332: `my $command = "/cig-" . $command_name;  # Prepend /cig-`
  → `my $command = "/cwf-" . $command_name;  # Prepend /cwf-`
- [ ] Line 399: `return "/cig-" . $name;`
  → `return "/cwf-" . $name;`

### Step 3: Update script hash
- [ ] `sha256sum .cwf/scripts/command-helpers/template-copier-v2.1`
- [ ] Update `template-copier-v2.1` entry in `.cwf/security/script-hashes.json`

### Step 4: Validate
- [ ] `cwf-manage validate` — no violations
- [ ] `grep -r "\.cig/" .cwf/templates/` — no matches
- [ ] `grep -n "/cig-" .cwf/scripts/command-helpers/template-copier-v2.1` — no matches
- [ ] Broad sweep: `grep -r "\.cig/\|/cig-" .cwf/` — confirm nothing else missed

## Test Coverage
**See e-testing-plan.md**

## Validation Criteria
- `cwf-manage validate` clean
- No `.cig/` or `/cig-` remaining in templates or template-copier
- Newly generated task file (spot-check via template-copier dry-run or grep) contains only `.cwf/` refs

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 90
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All steps executed as planned. 10 templates fixed, 2 lines in template-copier-v2.1 fixed,
hash updated. Broad sweep confirmed no remaining stale references.

## Lessons Learned
template-copier-v2.1 name_to_action() is the single point where skill names are
constructed — worth a comment flagging it as the place to update on future rebrands.
