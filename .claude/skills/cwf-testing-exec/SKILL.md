---
name: cwf-testing-exec
description: Guide user through testing execution phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Agent
---

## Scope & Boundaries

**This step**: Now you run tests. Execute test cases from e-testing-plan.md and document results in g-testing-exec.md.
**Not this step**: Planning tests (that's e-testing-plan), fixing bugs (that's f-implementation-exec), or deployment.
**If blocked or finished**: Call `.cwf/scripts/command-helpers/workflow-manager control --current-step=g-testing-exec --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cwf/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cwf/docs/skills/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `e-testing-plan.md` for test strategy, test cases, and success criteria.

**Re-execution check**: If `g-testing-exec.md` already has results from a prior run, read `.cwf/docs/skills/re-execution.md` before proceeding.

**Step 6 (Execute)**:
- Open g-testing-exec.md and update as you work
- **Focus on**: Executing planned tests, recording results, documenting failures
- **Avoid**: Changing the test plan (update e-testing-plan.md if needed)
- Status: "Testing" when starting, "Finished" when all pass, "Blocked" if environment issues

**Step 7**: Execute test cases systematically. Record PASS/FAIL, document failure details with reproduction steps, measure coverage.

**Step 8 (Security Review)**:
- Read `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" and § "Pathspec coverage".
- Determine current branch: `git rev-parse --abbrev-ref HEAD`.
  - If `main`: append `## Security Review\n\n**State**: no findings\n\nno findings: on main\n` to `g-testing-exec.md` and proceed to Step 9.
- Construct changeset: `git diff $(git merge-base HEAD main)..HEAD -- <pathspec from § "Pathspec coverage">`.
  - If empty: append `## Security Review\n\n**State**: no findings\n\nno findings: empty changeset\n` and proceed to Step 9.
  - If >500 lines (count via `wc -l`): append `## Security Review\n\n**State**: error\n\nerror: changeset exceeds 500-line review cap; split the change or perform manual review\n` and proceed to Step 9.
- Invoke ONE Agent call with `subagent_type="Explore"` using the prompt template, `{phase}` = `"testing"`.
- Append `## Security Review\n\n**State**: <findings|no findings|error>\n\n<verbatim subagent output>\n` to `g-testing-exec.md`. Classify per the three-tier rule in `security-review.md` (primary sentinel → numbered-list fallback → conservative-default error).
- Do NOT block on `findings`. Surface them; the user decides whether to fix-and-re-run or accept-and-record before Step 9.

**Step 9**: Checkpoint commit. See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `g-testing-exec.md`

**Step 10 (Next Steps)**:
- **Primary**: Move to rollout → `/cwf-rollout <task-path>`
- **Alt**: Return to `/cwf-implementation-exec` to fix bugs
- **Alt**: Return to `/cwf-testing-plan` to add tests
- **Alt**: Return to `/cwf-design-plan` if tests reveal design flaws

## Success Criteria
- [ ] Task directory resolved, test plan reviewed
- [ ] All functional test cases executed with results recorded
- [ ] Non-functional tests executed (if applicable)
- [ ] Test failures documented with reproduction steps
- [ ] Test coverage metrics recorded
- [ ] Security review subagent invoked; result recorded in g-testing-exec.md
- [ ] Next steps suggested with reasoning
