---
name: cwf-design-plan
description: Guide user through design phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Agent
---

## Gotchas

1. **Execute every numbered step — do not skip**: Every step in the Workflow section is mandatory, including plan review via subagents. Agents tend to skip steps they judge as low-value (especially ones buried mid-list). Skipping creates rework, which is a form of task failure. If a step genuinely doesn't apply, explain why before skipping.
2. **Do not skip the plan review subagents (Step 8)**: The map/reduce review via 3 parallel Explore subagents catches phase-sequence errors, unchecked assumptions, and other plan defects before implementation. Skipping it has allowed these errors to ship. It is not optional.
3. **Measure twice, cut once — verify assumptions against the codebase**: Before committing to a plan, grep the codebase, read related files, and check memories for relevant prior context. Plans that assume a function, path, or pattern exists without checking tend to propose duplicate code, wrong imports, or non-existent dependencies. Read 2-3 similar existing implementations before designing a new one.

## Scope & Boundaries

**This step**: Complete c-design-plan.md with architecture decisions, component design, and interface specifications.
**Not this step**: Implementation, testing, or deployment.
**If blocked or finished**: Call `.cwf/scripts/command-helpers/workflow-manager control --current-step=c-design-plan --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cwf/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cwf/docs/skills/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `.cwf/docs/workflow/workflow-steps.md#design` for detailed design phase guidance.

**Step 6 (Execute)**:
- Open c-design-plan.md (v2.1) or c-design.md (v2.0) or design.md (v1.0)
- **Focus on**: Architecture decisions, component design, API contracts, data models, interface design
- **Avoid**: Detailed implementation code, specific test cases, deployment procedures
- Apply design priorities: Testability → Readability → Consistency → Simplicity → Reversibility

**Step 7**: Check decomposition signals. See `.cwf/docs/workflow/decomposition-guide.md`.

**Step 8**: Plan review. Read `.cwf/docs/skills/plan-review.md` and follow the plan review procedure for plan type `design`.

**Step 9**: Checkpoint commit. See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `c-design-plan.md`

**Step 10 (Next Steps)**:
- **Primary**: Move to implementation → `/cwf-implementation-plan <task-path>`
- **Alt**: Return to requirements if design reveals gaps
- **Alt**: Create spike/prototype if uncertainty is high

## Success Criteria
- [ ] Design file opened and updated
- [ ] Architecture choice documented with rationale and trade-offs
- [ ] Component overview with clear responsibilities
- [ ] Data flow documented
- [ ] Interface design specified
- [ ] Next steps suggested
