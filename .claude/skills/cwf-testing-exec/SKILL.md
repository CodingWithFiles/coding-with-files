---
name: cwf-testing-exec
description: Guide user through testing execution phase
effort: low
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
- Read `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" and § "Changeset coverage".
- Determine current branch: `git rev-parse --abbrev-ref HEAD`.
  - If `main`: append `## Security Review\n\n**State**: no findings\n\nno findings: on main\n` to `g-testing-exec.md` and proceed to Step 9.
- Construct the changeset by running the helper **exactly** as below — it is agent-invoked and self-managing; do not add redirects, `wc`, `cat`, `grep`, or any surrounding boilerplate:
  ```
  .cwf/scripts/command-helpers/security-review-changeset --wf-step=testing-exec
  ```
  Capture its **stdout, stderr, and exit code**. The helper resolves the anchor, writes the full diff to a `.out` file per § "Changeset coverage", and prints one confirmation line `security-review-changeset: wrote <N> lines to <abs-path>`. Branch on the **exit code first**, then on the reported count:
  - **exit 0, count > 0**: continue to the Agent call below, passing the `<abs-path>` from the confirmation line as `{changeset_file}`.
  - **exit 0, count 0**: append `## Security Review\n\n**State**: no findings\n\nno findings: empty changeset\n` and proceed to Step 9.
  - **exit 0 but no parseable confirmation line**: append `## Security Review\n\n**State**: error\n\nerror: changeset helper produced no parseable confirmation line\n` and proceed to Step 9. Do not invoke the subagent.
  - **exit 2** (production-weighted count exceeds the cap): append `## Security Review\n\n**State**: error\n\nerror: <the helper's `cap exceeded:` stderr line>\n` and proceed to Step 9. Do not invoke the subagent.
  - **any other non-zero** (e.g. `1` — changeset construction failed, including a malformed `security.review.max-lines-exclude-paths` pattern git rejected): append `## Security Review\n\n**State**: error\n\nerror: changeset construction failed (<helper stderr>)\n` and proceed to Step 9. Do not invoke the subagent.
- **Regardless of exit code**: if the helper's stderr contains a `warning:` line (e.g. the deprecation notice for the legacy `security.review.test-paths` config key), surface it to the user verbatim and note it under the `## Security Review` section. These are upgrade nudges; do not swallow them.
- Invoke ONE Agent call with `subagent_type="cwf-security-reviewer-changeset"` using the prompt template, `{wf_step}` = `"testing-exec"`, `{changeset_file}` = the `.out` path from the confirmation line.
- Write the verbatim subagent output to `security-review-output-testing-exec.out` in the task scratch dir (derive the dir per `.cwf/docs/conventions/tmp-paths.md`; `mkdir -m 0700` on first use — this is a distinct file from the helper's changeset `.out`), then classify deterministically: `.cwf/scripts/command-helpers/security-review-classify < <file>` prints one of `no findings|findings|error`. Append `## Security Review\n\n**State**: <token>\n\n<verbatim subagent output>\n` to `g-testing-exec.md`. Do not apply any prose/heuristic rule — the helper is the sole classifier (a tool-level Agent failure is recorded as `error`).
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
