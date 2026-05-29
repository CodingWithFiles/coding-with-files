---
name: cwf-implementation-exec
description: Guide user through implementation execution phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Agent
---

## Gotchas

1. **Run `git status` before every checkpoint commit**: `git diff` only shows unstaged changes to already-tracked files. New files created during the phase (workflow files, helper scripts, generated docs) and tracked files that were modified but never staged are easy to miss, and the commit will silently exclude them. Always inspect `git status` for untracked or unstaged entries before staging.
2. **After any rename or string substitution, verify both source and generated output**: A clean source grep is not proof the change is complete — stale strings persist in artefacts produced from templates, script-emitted text, or rendered documentation. After renaming, grep the entire codebase for the old string, then generate at least one sample output artefact and grep that too. Both checks are required; neither is sufficient alone.
3. **Editing a hash-tracked file requires an in-task hash refresh**: any source change to a file listed in `.cwf/security/script-hashes.json` (typically paths under `.cwf/scripts/`, `.cwf/lib/CWF/`, `.claude/agents/`, `.claude/hooks/`, `.claude/rules/`) MUST refresh the matching `sha256` entry in the same commit. See `.cwf/docs/conventions/hash-updates.md`. Deferring the refresh — even to "the next task" or retrospective — defeats the integrity check.

## Scope & Boundaries

**This step**: Now you write code. Execute the implementation steps from d-implementation-plan.md and document actual results in f-implementation-exec.md.
**Not this step**: Planning what to implement (that's d-implementation-plan), testing (that's e-testing-plan + g-testing-exec), or deployment.
**If blocked or finished**: Call `.cwf/scripts/command-helpers/workflow-manager control --current-step=f-implementation-exec --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cwf/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cwf/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cwf/docs/skills/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `d-implementation-plan.md` for detailed implementation steps, files to modify, and expected changes.

**Re-execution check**: If `f-implementation-exec.md` already has results from a prior run, read `.cwf/docs/skills/re-execution.md` before proceeding.

**Step 6 (Execute)**:
- Open f-implementation-exec.md and update as you work
- **Focus on**: Executing planned steps, recording actual results, documenting deviations
- **Avoid**: Changing the plan (update d-implementation-plan.md if plan needs adjustment)
- Status: "In Progress" when starting, "Finished" when complete, "Blocked" if stuck

**Step 7**: Execute implementation steps systematically per d-implementation-plan.md. Test locally, document results, note deviations.

**Step 8 (Security Review)**:
- Read `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" and § "Pathspec coverage".
- Determine current branch: `git rev-parse --abbrev-ref HEAD`.
  - If `main`: append `## Security Review\n\n**State**: no findings\n\nno findings: on main\n` to `f-implementation-exec.md` and proceed to Step 9.
- Construct changeset: run `.cwf/scripts/command-helpers/security-review-changeset --phase=implementation --max-lines=500`, capturing **both stdout and the exit code** (and stderr, for the cap reason). The helper resolves the anchor, applies CWF-internal-dir + shebang-sniff classification per § "Pathspec coverage", and enforces the production-weighted review cap. Branch on the exit code:
  - **exit 0, empty stdout**: append `## Security Review\n\n**State**: no findings\n\nno findings: empty changeset\n` and proceed to Step 9.
  - **exit 0, non-empty stdout**: continue to the Agent call below with the captured stdout as `{changeset}`.
  - **exit 2** (production-weighted count exceeds the cap): append `## Security Review\n\n**State**: error\n\nerror: <the helper's `cap exceeded:` stderr line>\n` and proceed to Step 9. Do not invoke the subagent.
  - **any other non-zero** (e.g. `1` — changeset construction failed, including a malformed `security.review.test-paths` pattern git rejected): append `## Security Review\n\n**State**: error\n\nerror: changeset construction failed (<helper stderr>)\n` and proceed to Step 9. Do not invoke the subagent.
- Invoke ONE Agent call with `subagent_type="cwf-security-reviewer-changeset"` using the prompt template, `{phase}` = `"implementation"`.
- Write the verbatim subagent output to a file in the task scratch dir (derive the dir per `.cwf/docs/conventions/tmp-paths.md`; `mkdir -m 0700` on first use), then classify deterministically: `.cwf/scripts/command-helpers/security-review-classify < <file>` prints one of `no findings|findings|error`. Append `## Security Review\n\n**State**: <token>\n\n<verbatim subagent output>\n` to `f-implementation-exec.md`. Do not apply any prose/heuristic rule — the helper is the sole classifier (a tool-level Agent failure is recorded as `error`).
- Do NOT block on `findings`. Surface them; the user decides whether to fix-and-re-run or accept-and-record before Step 9.

**Step 9**: Checkpoint commit. See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `f-implementation-exec.md` (and any changed files)

**Step 10 (Next Steps)**:
- **Primary**: Move to testing → `/cwf-testing-exec <task-path>`
- **Alt**: Document blockers, update status to "Blocked"
- **Alt**: Return to `/cwf-implementation-plan` to revise plan
- **Alt**: Return to `/cwf-design-plan` if execution reveals design issues

## Success Criteria
- [ ] Task directory resolved, plan reviewed
- [ ] Implementation steps executed according to plan
- [ ] Actual results documented for each step
- [ ] Deviations documented with rationale
- [ ] Security review subagent invoked; result recorded in f-implementation-exec.md
- [ ] Next steps suggested with reasoning
