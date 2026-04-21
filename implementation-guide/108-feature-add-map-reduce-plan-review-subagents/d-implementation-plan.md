# Add map-reduce plan review subagents to requirements, design, and implementation plan skills - Implementation Plan
**Task**: 108 (feature)

## Task Reference
- **Task ID**: internal-108
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/108-add-map-reduce-plan-review-subagents
- **Template Version**: 2.1

## Goal
Implement the map/reduce plan review: create the shared doc with subagent prompts, modify the 3 SKILL.md files, and verify the flow works.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Create
### New File
- `.cwf/docs/skills/plan-review.md` — Shared doc with map/reduce methodology, 9 subagent prompt templates (3 plan types × 3 focus areas), reduce/synthesis instructions, and output format specification

## Files to Modify
### Primary Changes (3 files, same pattern)
- `.claude/skills/cwf-requirements-plan/SKILL.md` — Add Agent to allowed-tools, insert Step 8 (plan review), renumber Steps 8→9, 9→10
- `.claude/skills/cwf-design-plan/SKILL.md` — Same changes
- `.claude/skills/cwf-implementation-plan/SKILL.md` — Same changes

## Implementation Steps

### Step 1: Create `.cwf/docs/skills/plan-review.md`
- [ ] Write the overview section explaining map/reduce methodology
- [ ] Write 1 parameterised subagent prompt template with `{plan_file_path}`, `{plan_type}`, `{focus_area}`, `{criteria}` placeholders
  - Include read-only instruction ("You may only use Read, Grep, and Glob tools")
  - Instruct subagent to read the plan file first, then grep the codebase for relevant existing code
  - Instruct subagent to report findings concisely (what's wrong, where, what to do about it)
- [ ] Write the 3×3 criteria lookup table (from design c-design-plan.md prompt matrix)
- [ ] Write the reduce step instructions:
  - Collect findings from all 3 subagents (skip failures)
  - Identify tradeoffs between competing suggestions
  - Parent agent decides which findings to apply
  - Present summary of changes and unapplied suggestions to user
  - Handle subagent failures gracefully
- [ ] Write the integration instructions: how skills reference this doc

### Step 2: Modify cwf-requirements-plan SKILL.md
- [ ] Add `Agent` to `allowed-tools` list in YAML frontmatter
- [ ] Insert new Step 8 after Step 7 (decomposition check):
  ```
  **Step 8**: Plan review. Read `.cwf/docs/skills/plan-review.md` and follow the plan review procedure for plan type `requirements`.
  ```
- [ ] Renumber current Step 8 (checkpoint commit) → Step 9
- [ ] Renumber current Step 9 (next steps) → Step 10

### Step 3: Modify cwf-design-plan SKILL.md
- [ ] Same as Step 2 but for plan type `design`

### Step 4: Modify cwf-implementation-plan SKILL.md
- [ ] Same as Step 2 but for plan type `implementation`

### Step 5: Validation
- [ ] Verify all 3 SKILL.md files parse correctly (valid YAML frontmatter, consistent step numbering)
- [ ] Verify `.cwf/docs/skills/plan-review.md` contains prompt template and 3×3 criteria table
- [ ] Verify prompt template uses correct placeholder syntax (`{var}` not `<var>`)
- [ ] Verify Agent tool actually works when listed in `allowed-tools` (first CWF skill to use it)
- [ ] Run `cwf-manage validate` to confirm no integrity violations

## Code Changes

### SKILL.md Before (all 3 skills share this pattern)
```yaml
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
```
```
**Step 7**: Check decomposition signals. ...
**Step 8**: Checkpoint commit. ...
**Step 9 (Next Steps)**: ...
```

### SKILL.md After
```yaml
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Agent
```
```
**Step 7**: Check decomposition signals. ...
**Step 8**: Plan review. Read `.cwf/docs/skills/plan-review.md` and follow the plan review procedure for plan type `{requirements|design|implementation}`.
**Step 9**: Checkpoint commit. ...
**Step 10 (Next Steps)**: ...
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 108
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
