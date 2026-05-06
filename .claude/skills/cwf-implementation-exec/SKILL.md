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
- Construct changeset: capture stdout of `.cwf/scripts/command-helpers/security-review-changeset --phase=implementation`. The helper resolves the anchor and applies CWF-internal-dir + shebang-sniff classification per § "Pathspec coverage".
  - If empty: append `## Security Review\n\n**State**: no findings\n\nno findings: empty changeset\n` and proceed to Step 9.
  - If >500 lines (count via `wc -l`): append `## Security Review\n\n**State**: error\n\nerror: changeset exceeds 500-line review cap; split the change or perform manual review\n` and proceed to Step 9.
- Invoke ONE Agent call with `subagent_type="Explore"` using the prompt template, `{phase}` = `"implementation"`.
- Append `## Security Review\n\n**State**: <findings|no findings|error>\n\n<verbatim subagent output>\n` to `f-implementation-exec.md`. Classify per the three-tier rule in `security-review.md` (primary sentinel → numbered-list fallback → conservative-default error).
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
