# Refactor workflow docs for efficiency - Implementation Plan
**Task**: 88 (bugfix)

## Task Reference
- **Task ID**: internal-88
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/88-refactor-workflow-docs-for-efficiency
- **Template Version**: 2.1

## Goal
Implement the doc changes specified in the design: fix placeholders, remove duplicated blocks, replace with canonical references and skill calls.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- `.cwf/docs/skills/checkpoint-commit.md` — fix stale command + `<>` → `{}`
- `.cwf/docs/skills/retrospective-extras.md` — `<>` → `{}` on 6 lines
- `.cwf/docs/workflow/workflow-steps.md` — replace checkpoint blocks, structure sections, jq blocks
- `.cwf/docs/workflow/blocker-patterns.md` — remove boilerplate, replace file-edit instructions, replace decomposition body, remove stale refs
- `.cwf/docs/workflow/decomposition-guide.md` — replace context inheritance body with reference

### Supporting Changes
- `implementation-guide/88-bugfix-refactor-workflow-docs-for-efficiency/e-testing-plan.md` — test cases
- `implementation-guide/88-bugfix-refactor-workflow-docs-for-efficiency/f-implementation-exec.md` — execution notes

## Implementation Steps

### Step 1: Fix skill docs (checkpoint-commit.md, retrospective-extras.md)
- [ ] `checkpoint-commit.md` line 13: `<task-dir>/<workflow-file>.md` → `{task-dir}/{workflow-file}.md`
- [ ] `checkpoint-commit.md` line 18: `Task N: Complete <phase>` → `Task {N}: Complete {phase}`
- [ ] `checkpoint-commit.md` line 30: `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` → `.cwf/scripts/cwf-manage validate`
- [ ] `retrospective-extras.md`: replace all 6 `<var>` model-substitution variables with `{var}`

### Step 2: Simplify workflow-steps.md — checkpoint blocks
- [ ] Planning phase: replace ~8-line checkpoint commit block with 1-line reference
- [ ] Requirements phase: replace ~8-line block with 1-line reference
- [ ] Design phase: replace ~8-line block with 1-line reference
- [ ] Implementation Plan phase: replace ~8-line block with 1-line reference
- [ ] Implementation Exec phase: replace ~8-line block with 1-line reference
- [ ] Testing Plan phase: replace ~8-line block with 1-line reference
- [ ] Testing Exec phase: replace ~8-line block with 1-line reference
- [ ] Rollout phase: replace ~8-line block with 1-line reference

### Step 3: Simplify workflow-steps.md — structure sections
- [ ] Replace each of 8 "**Typical Structure**" sections with 1-line template pool reference

### Step 4: Simplify workflow-steps.md — jq blocks
- [ ] Remove two `jq -r` code blocks; keep human-readable status list; add 1-line config source reference

### Step 5: Simplify blocker-patterns.md — boilerplate removal
- [ ] Remove 3-line per-phase boilerplate from all 9 phases
- [ ] Add single forward pointer after phase 1's reversion guidance

### Step 6: Simplify blocker-patterns.md — skill call replacements
- [ ] Replace all 13 file-edit reversion instructions with `/cwf-` skill call chains (per design table)

### Step 7: Simplify blocker-patterns.md — decomposition and stale refs
- [ ] Replace Decomposition Signals body with 1-line reference to `decomposition-guide.md`
- [ ] Remove stale References section entirely

### Step 8: Simplify decomposition-guide.md
- [ ] Replace Context Inheritance body with 1-line reference to `workflow-overview.md`

### Step 9: Verify
- [ ] Run `cwf-manage validate`
- [ ] Run verification greps from plan

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 88
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
