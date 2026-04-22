# Add Gotchas to Plan Skills to Prevent Step-Skipping - Implementation Plan
**Task**: 110 (bugfix)

## Task Reference
- **Task ID**: internal-110
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/110-add-gotchas-to-plan-skills-to-prevent-step-skipping
- **Template Version**: 2.1

## Goal
Add a `## Gotchas` section to the top of cwf-requirements-plan, cwf-design-plan, and
cwf-implementation-plan SKILL.md files. Two gotchas each, mirroring the placement
pattern established in Task 109 (cwf-retrospective).

## Bug Context
During Task 109, the agent skipped Step 8 (plan review via map/reduce subagents)
despite it being clearly documented in the skill. The user had to prompt for the
review to be run. This is the exact failure pattern Task 107 identified: instructions
buried mid-workflow get skipped when the agent judges them low-value. Task 108 added
the plan review step, but no mechanism enforces its execution.

## Scope Note
This task addresses step-skipping behaviour only. Task 107 identified additional
skill-specific gotchas (codebase investigation for cwf-implementation-plan, assumption
verification for cwf-design-plan) which remain as separate backlog items. Combining
them would dilute the step-skipping focus.

## Known Limitation
Task 109's retrospective documented that gotchas alone may not prevent step-skipping
— the agent skipped Step 8 in Task 109 even though the skill was well-documented.
Task 110 is an interim measure. A stronger forcing function (e.g., mandatory TaskCreate
checklists at skill entry) is tracked separately for future work.

## Files to Modify
- `.claude/skills/cwf-requirements-plan/SKILL.md` — add Gotchas section after frontmatter
- `.claude/skills/cwf-design-plan/SKILL.md` — add Gotchas section after frontmatter
- `.claude/skills/cwf-implementation-plan/SKILL.md` — add Gotchas section after frontmatter
- `.claude/skills/cwf-retrospective/SKILL.md` — project-neutralise existing gotchas (added in Task 109) that cited specific task numbers

## Implementation Steps
### Step 1: Add Gotchas Section to Each Plan Skill
- [ ] Insert a `## Gotchas` section between the frontmatter (`---`) and `## Scope & Boundaries`
      in all three SKILL.md files
- [ ] Use identical gotcha text across all three skills (they share the same failure modes)

**Gotchas to add (same text in each skill):**

1. **Execute every numbered step — do not skip**: Every step in the Workflow section is
   mandatory, including plan review via subagents. Agents tend to skip steps they judge
   as low-value (especially ones buried mid-list). Skipping creates rework, which is a
   form of task failure. If a step genuinely doesn't apply, explain why before skipping.

2. **Do not skip the plan review subagents (Step 8)**: When this was skipped in Task 109,
   the resulting plan had a sequence error (Gotcha 3 cited the wrong phase transition)
   that would have shipped. The map/reduce review via 3 parallel Explore subagents,
   added in Task 108, catches these errors before implementation. It is not optional.

### Step 2: Verify No Other Sections Disturbed
- [ ] Each SKILL.md should have exactly two changes: the new Gotchas section
- [ ] All other sections (Scope & Boundaries, Context, Workflow, Success Criteria) identical

### Step 3: Project-Neutralise cwf-retrospective Gotchas
- [ ] Reword the 3 gotchas in `.claude/skills/cwf-retrospective/SKILL.md` (added in Task 109)
      to remove project-specific task number citations (Tasks 65, 67, 81, 84, 98, 103)
- [ ] Replace with semantically-equivalent project-neutral rationale — skill files are
      installed into downstream projects where those task numbers don't exist

### Step 4: Ensure Plan-Skill Gotcha 2 is Project-Neutral
- [ ] The "Do not skip plan review subagents" gotcha must not reference Task 108 or Task 109
- [ ] State the failure mode generically: plan review catches phase-sequence errors,
      unchecked assumptions, and other defects before implementation

## Validation Criteria
- [ ] All three plan SKILL.md files have `## Gotchas` section between frontmatter and Scope & Boundaries
- [ ] Gotcha text is byte-identical across the three plan skills
- [ ] Gotcha 1 addresses generic step-skipping
- [ ] Gotcha 2 addresses plan review subagent skipping (Step 8) in project-neutral terms
- [ ] cwf-retrospective gotchas contain no "Task NNN" references
- [ ] No other sections disturbed in any of the 4 files

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
Plan expanded during /simplify review to include cwf-retrospective (Step 3) and
ensure plan-skill Gotcha 2 is project-neutral (Step 4). All 4 steps executed.

## Lessons Learned
Installable SKILL.md files must never reference specific task numbers — caught
only at /simplify review. Plan review subagents found a Gotcha 3 ambiguity that
would have shipped.
