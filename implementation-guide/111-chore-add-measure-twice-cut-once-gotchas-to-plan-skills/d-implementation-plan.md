# Add measure-twice-cut-once gotchas to design-plan and implementation-plan skills - Implementation Plan
**Task**: 111 (chore)

## Task Reference
- **Task ID**: internal-111
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/111-add-measure-twice-cut-once-gotchas-to-plan-skills
- **Template Version**: 2.1

## Goal
Append a third project-neutral "measure twice, cut once" gotcha to the existing
`## Gotchas` section in both `cwf-design-plan/SKILL.md` and
`cwf-implementation-plan/SKILL.md`. Use identical wording across both files since
the failure mode is the same.

## Context
Task 107 (LMM memory analysis) identified two related failure modes:
- `cwf-design-plan`: Tasks 104 and 105 chose approaches without checking what existing
  code could be leveraged.
- `cwf-implementation-plan`: Tasks 88, 101, 102, 104, 105 had plans that assumed
  wrong paths or missed existing utilities because no one checked the code first.

Both collapse into the same rule: verify assumptions against the codebase before
committing to a plan. Captured here as a single shared gotcha.

## Files to Modify
- `.claude/skills/cwf-design-plan/SKILL.md` — append gotcha 3 to existing `## Gotchas` section
- `.claude/skills/cwf-implementation-plan/SKILL.md` — append gotcha 3 to existing `## Gotchas` section

No other files change. `cwf-requirements-plan/SKILL.md` is intentionally out of scope
(requirements phase is about user needs, not codebase structure).

## Implementation Steps
### Step 1: Add Gotcha 3 to Both Plan Skills
- [ ] Append the gotcha below as item `3.` to the existing `## Gotchas` section in
      `.claude/skills/cwf-design-plan/SKILL.md`
- [ ] Append the same gotcha (byte-identical) as item `3.` in
      `.claude/skills/cwf-implementation-plan/SKILL.md`

**Gotcha text (identical in both files, single-line to match existing gotchas 1 and 2):**

```
3. **Measure twice, cut once — verify assumptions against the codebase**: Before committing to a plan, grep the codebase, read related files, and check memories for relevant prior context. Plans that assume a function, path, or pattern exists without checking tend to propose duplicate code, wrong imports, or non-existent dependencies. Read 2-3 similar existing implementations before designing a new one.
```

### Step 2: Verify No Other Sections Disturbed
- [ ] Each SKILL.md diff should show only the new gotcha line appended to the Gotchas section
- [ ] All other sections (Scope & Boundaries, Context, Workflow, Success Criteria) identical
- [ ] Existing gotchas 1 and 2 (from Task 110) unchanged

### Step 3: Project-Neutrality Check
- [ ] Gotcha 3 contains no "Task NNN", branch names, or commit hashes
- [ ] Wording is generic enough to apply in any downstream project that installs the skill

## Validation Criteria
- [ ] Both SKILL.md files have exactly 3 numbered gotchas after the change
- [ ] Gotcha 3 text is byte-identical across both files — verify with `diff <(sed -n '/^3\./p' .claude/skills/cwf-design-plan/SKILL.md) <(sed -n '/^3\./p' .claude/skills/cwf-implementation-plan/SKILL.md)` (no output = identical)
- [ ] `grep -E "Task [0-9]+" .claude/skills/cwf-{design,implementation}-plan/SKILL.md` returns zero matches
- [ ] No changes outside the Gotchas section in either file

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Plan applied as written after plan review. Plan review (3 parallel Explore agents)
caught the multi-line formatting inconsistency with existing gotchas 1 and 2 —
collapsed to single-line before implementation.

## Lessons Learned
Plan review is not a wording review. The enumeration ("paths, utilities, scripts,
or interfaces") passed all 3 subagents but was caught by the user. For text-heavy
tasks, expect a wording-review round after plan review passes.
