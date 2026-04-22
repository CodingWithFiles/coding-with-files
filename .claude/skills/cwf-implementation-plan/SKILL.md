---
name: cwf-implementation-plan
description: Guide user through implementation phase
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

**This step**: Complete d-implementation-plan.md with files to modify, implementation steps, and validation criteria.
**Not this step**: Writing code (that's f-implementation-exec), testing, or deployment.
**If blocked or finished**: Call `.cwf/scripts/command-helpers/workflow-manager control --current-step=d-implementation-plan --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cwf/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cwf/docs/skills/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `.cwf/docs/workflow/workflow-steps.md#implementation` for detailed implementation phase guidance.

**Step 6 (Execute)**:
- Open d-implementation-plan.md (v2.1) or d-implementation.md (v2.0) or implementation.md (v1.0)
- **Focus on**: Files to modify, implementation steps, code changes, test coverage, validation criteria
- **Avoid**: Design rationale, business requirements, deployment strategies
- Workflow: Patterns first → Test → Minimal impl → Refactor green → Commit explains "why"

**Step 7**: Check decomposition signals. See `.cwf/docs/workflow/decomposition-guide.md`.

**Step 8**: Plan review. Read `.cwf/docs/skills/plan-review.md` and follow the plan review procedure for plan type `implementation`.

**Step 9**: Checkpoint commit. See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `d-implementation-plan.md`

**Step 10 (Next Steps)**:
- **Primary**: Move to testing planning → `/cwf-testing-plan <task-path>`
- **Alt**: Return to design if implementation reveals gaps
- **Alt**: Create subtasks if too complex

## Success Criteria
- [ ] Implementation file opened and updated
- [ ] Files to modify identified and documented
- [ ] Implementation steps defined as actionable checklist
- [ ] Test coverage specified
- [ ] Validation criteria defined
- [ ] Next steps suggested
