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

**Step 8 (Changeset Reviews — security + best-practice, run in PARALLEL)**:

Two independent reviewers assess the exec changeset: the **security** reviewer (always) and the **best-practice** reviewer (only when the user has matching best-practice docs). They share no state — the SubagentStop verdict guard is name-matched to `cwf-security-reviewer-changeset` only — and each emits its own `cwf-review` verdict classified independently. **Launch their Agent calls together in a single message so they run in parallel; never one-then-the-other.**

- Read `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" + § "Changeset coverage" and `.cwf/docs/skills/best-practice-review.md` § "Exec prompt template" + § "Doc-list discipline".
- Determine current branch: `git rev-parse --abbrev-ref HEAD`. If `main`: append both `## Security Review\n\n**State**: no findings\n\nno findings: on main\n` and `## Best-Practice Review\n\n**State**: no findings\n\nno findings: on main\n`, then proceed to Step 9 (no agents).

**Prep (deterministic helpers — fast, run both before launching any agent):**

1. Security changeset — run **exactly** as below (agent-invoked, self-managing; no redirects, `wc`, `cat`, `grep`):
   ```
   .cwf/scripts/command-helpers/security-review-changeset --wf-step=testing-exec
   ```
   Capture stdout/stderr/exit. It writes the full diff to a `.out` file per § "Changeset coverage" and prints `security-review-changeset: wrote <N> lines to <abs-path>`. Branch on the **exit code first**, then the count, to decide the **Security verdict-or-agent**:
   - **exit 0, count > 0**: a security agent will be launched in the MAP, `{changeset_file}` = the `<abs-path>`.
   - **exit 0, count 0**: record `## Security Review` `no findings` (`no findings: empty changeset`); no security agent.
   - **exit 0 but no parseable confirmation line**: record `## Security Review` `error` (`error: changeset helper produced no parseable confirmation line`); no security agent.
   - **exit 2** (cap exceeded — the CODE portion is over the cap; **docs are always reviewed**, Task 223): follow the deferred-docs contract in `.cwf/docs/skills/security-review.md` § "Deferred code review (over-cap)". Parse the helper's SECOND confirmation line, `security-review-changeset: wrote <D> doc lines to <docs-abs-path>`:
     - **doc line present, `D` > 0**: launch the security agent on the docs — `{changeset_file}` = `<docs-abs-path>`.
     - **doc line present, `D` == 0**: record `## Security Review` `no findings` (`no findings: no docs to review`); no security agent.
     - **doc line ABSENT**: record `## Security Review` `no findings` (`no findings: docs not separable — base-path unconfigured`); no security agent. Do **not** read this as "no docs".
     - **In ALL three cases** ALSO append a dedicated `## Changeset Review — Code (Deferred)` section carrying `**State**: deferred` and the helper's `cap exceeded: <P> production lines > <cap>` stderr line as the detail — code review is deferred, never silently passed.
   - **any other non-zero**: record `## Security Review` `error` (`error: changeset construction failed (<helper stderr>)`); no security agent.
   - **Regardless of exit code**: surface any stderr `warning:` line (e.g. the deprecated `security.review.test-paths` key) to the user verbatim and note it under `## Security Review`.

2. Best-practice context — run **exactly** as below (same no-boilerplate rule):
   ```
   .cwf/scripts/command-helpers/best-practice-resolve --task-num=<num> --phase=testing-exec
   ```
   Capture stdout/stderr/exit. It prints `best-practice-resolve: wrote <N> matched entries to <abs-path>`. Branch on the **exit code first**, then the count, to decide the **Best-Practice verdict-or-agent**:
   - **exit 1**: record `## Best-Practice Review` `error` (`error: best-practice-resolve failed (<helper stderr>)`); no bp agent (a broken config must never read as clean).
   - **exit 0, count 0**: record `## Best-Practice Review` `no findings` (`no findings: no applicable best practices`); no bp agent.
   - **exit 0, count ≥1**: a bp agent will be launched **iff** helper #1 produced a usable changeset — either an exit-0 changeset (count > 0) OR, on an exit-2 breach, a deferred doc `.out` with `D` > 0 (Task 223: the docs are reviewed, so best-practice reviews them too). `{changeset_file}` = whichever applies, `{bp_context_file}` = this resolver's `<abs-path>`. If there is no changeset to review (empty exit-0 changeset, or an over-cap breach with no doc line or `D` == 0), record `## Best-Practice Review` `no findings` (`no findings: no changeset to review`); no bp agent.
   - **Regardless of exit code**: surface any stderr `warning:` line verbatim and note it under `## Best-Practice Review`.

**MAP (launch in parallel)**: in ONE message, issue the Agent calls for whichever reviewers the Prep selected (0, 1, or 2 calls):
- security: `subagent_type="cwf-security-reviewer-changeset"`, `{wf_step}` = `"testing-exec"`, `{changeset_file}`.
- best-practice: `subagent_type="cwf-best-practice-reviewer-changeset"`, `{wf_step}` = `"testing-exec"`, `{changeset_file}`, `{bp_context_file}`.

**Classify + record**: write each launched agent's verbatim output to its own scratch `.out` named `<reviewer>-review-output-testing-exec.out` (`<reviewer>` ∈ {`security`, `best-practice`}; derive the dir per `.cwf/docs/conventions/tmp-paths.md`, `mkdir -m 0700` on first use). Then classify **all** of them in ONE invocation — no shell loop, no `< <file>` redirect (this single literal argv matches the allowlist and raises no prompt):

```
.cwf/scripts/command-helpers/security-review-classify --dir <scratch-dir> --phase testing-exec
```

It prints one `<reviewer>: <token>` line per discovered file. Map each line's reviewer prefix to its heading and record `**State**: <token>` above that agent's verbatim output: `security` → `## Security Review`, `best-practice` → `## Best-Practice Review`. The helper is the sole classifier — do NOT apply any prose/heuristic rule. **Cross-check** the launched set against the classified lines: a reviewer you launched whose line is absent is recorded `error`, never silently dropped. A tool-level Agent failure is recorded as `error`.

Do NOT block on `findings` from either reviewer. Surface them; the user decides whether to fix-and-re-run or accept-and-record before Step 9.

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
