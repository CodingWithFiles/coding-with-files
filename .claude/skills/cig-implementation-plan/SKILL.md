---
name: cig-implementation-plan
description: Guide user through implementation phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

## Scope & Boundaries

**This step**: Complete d-implementation-plan.md with files to modify, implementation steps, and validation criteria.
**Not this step**: Writing code (that's f-implementation-exec), testing, or deployment.
**If blocked or finished**: Call `workflow-manager control --current-step=d-implementation-plan --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cig/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cig/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cig/docs/skills/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `.cig/docs/workflow/workflow-steps.md#implementation` for detailed implementation phase guidance.

**Step 6 (Execute)**:
- Open d-implementation-plan.md (v2.1) or d-implementation.md (v2.0) or implementation.md (v1.0)
- **Focus on**: Files to modify, implementation steps, code changes, test coverage, validation criteria
- **Avoid**: Design rationale, business requirements, deployment strategies
- Workflow: Patterns first → Test → Minimal impl → Refactor green → Commit explains "why"

**Step 7**: Check decomposition signals. See `.cig/docs/workflow/decomposition-guide.md`.

**Step 8**: Checkpoint commit. See `.cig/docs/skills/checkpoint-commit.md`. Stage: `d-implementation-plan.md`

**Step 9 (Next Steps)**:
- **Primary**: Move to testing planning → `/cig-testing-plan <task-path>`
- **Alt**: Return to design if implementation reveals gaps
- **Alt**: Create subtasks if too complex

## Success Criteria
- [ ] Implementation file opened and updated
- [ ] Files to modify identified and documented
- [ ] Implementation steps defined as actionable checklist
- [ ] Test coverage specified
- [ ] Validation criteria defined
- [ ] Next steps suggested
