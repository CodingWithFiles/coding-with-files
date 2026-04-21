# Add map-reduce plan review subagents to requirements, design, and implementation plan skills - Plan
**Task**: 108 (feature)

## Task Reference
- **Task ID**: internal-108
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/108-add-map-reduce-plan-review-subagents
- **Template Version**: 2.1

## Goal
Add a map/reduce review step to the three planning workflow skills (requirements, design, implementation) that runs 3 focused subagents in parallel after the plan file is written but before the checkpoint commit, then synthesises their findings to improve the plan before committing.

## Success Criteria
- [ ] Each of the 3 plan skills (cwf-requirements-plan, cwf-design-plan, cwf-implementation-plan) has a new review step between Step 7 (decomposition check) and Step 8 (checkpoint commit)
- [ ] Each review step launches 3 subagents in parallel (improvements, misalignment, robustness) using a single parameterised prompt template
- [ ] Prompt template uses a 3×3 criteria lookup table to tailor review criteria per plan type and focus area
- [ ] A reduce step synthesises the 3 subagent results, assesses tradeoffs, and applies the best changes to the plan file
- [ ] Review step is documented (new doc in `.cwf/docs/skills/`) so skills reference it rather than duplicating content

## Original Estimate
**Effort**: 1 day
**Complexity**: Medium
**Dependencies**: None — modifies existing skill files only

## Major Milestones
1. **Design**: Define subagent prompt templates for each (plan type × focus area) combination and the reduce/tradeoff synthesis step
2. **Implementation**: Add new step to all 3 SKILL.md files, create shared review doc
3. **Validation**: Run a plan skill end-to-end and verify the review step fires correctly

## Risk Assessment
### High Priority Risks
- **Token cost**: 9 subagents per planning cycle could be expensive if prompts are verbose
  - **Mitigation**: Keep subagent prompts focused and concise; they read the plan file and return findings only — no exploration

### Medium Priority Risks
- **Diminishing returns**: Some plan types may not benefit from all 3 focus areas equally (e.g., requirements rarely have robustness concerns beyond acceptance criteria)
  - **Mitigation**: Subagent prompts are tailored per plan type — a robustness subagent for requirements focuses on different things than one for implementation
- **Subagent quality variance**: Subagents may return generic or low-signal feedback
  - **Mitigation**: Prompts must be specific about what "good" looks like for each focus area; include concrete examples of what to look for

## Dependencies
- Existing skill files: `.claude/skills/cwf-requirements-plan/SKILL.md`, `.claude/skills/cwf-design-plan/SKILL.md`, `.claude/skills/cwf-implementation-plan/SKILL.md`
- Agent tool is available in Claude Code but not yet used by any CWF skill — this task introduces it as a new tool dependency

## Constraints
- Skills currently allow Read, Write, Edit, Bash tools — Agent tool must be added to `allowed-tools` in SKILL.md frontmatter for each modified skill
- Subagent prompts must be self-contained (subagents have no conversation context)
- Progressive disclosure: skill files reference docs, don't duplicate content

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? **No** — estimated 1 day
- [x] **People**: Does this need >2 people? **No** — single developer
- [x] **Complexity**: Does this involve 3+ distinct concerns? **No** — same pattern applied 3 times with tailored prompts
- [x] **Risk**: Are there high-risk components? **No** — additive change to existing skills
- [x] **Independence**: Can parts be worked on separately? **Yes**, but overhead of 3 subtasks exceeds benefit for a 1-day task

**Decision**: No decomposition. The 3 skills share the same structure; the work is repetitive application of one pattern, not 3 independent concerns.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 108
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
