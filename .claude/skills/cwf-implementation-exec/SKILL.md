---
name: cwf-implementation-exec
description: Guide user through implementation execution phase
effort: low
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

**Step 8 (Changeset Reviews — security + best-practice + three lens reviewers, run in PARALLEL)**:

Five independent reviewers assess the exec changeset: the **security** reviewer (always), the **best-practice** reviewer (only when the user has matching best-practice docs), and three **lens** reviewers — **improvements** (reuse), **robustness** (reliability), and **misalignment** (alignment) — each whenever there is a changeset to review. The three lens reviewers are advisory exactly like best-practice: they share no state with the security guard — the SubagentStop verdict guard is name-matched to `cwf-security-reviewer-changeset` only — and each emits its own `cwf-review` verdict classified independently. (This MAP runs only after **implementation-exec**; `cwf-testing-exec` keeps the narrower two-reviewer MAP.) **Launch all selected Agent calls together in a single message so they run in parallel; never one-then-the-other.**

- Read `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" + § "Changeset coverage" and `.cwf/docs/skills/best-practice-review.md` § "Exec prompt template" + § "Doc-list discipline". The three lens reviewers reuse the same exec prompt shape (`{wf_step}` + `{changeset_file}`) as the security reviewer.
- Determine current branch: `git rev-parse --abbrev-ref HEAD`. If `main`: append **all five** `no findings: on main` sections — `## Security Review`, `## Best-Practice Review`, `## Improvements Review`, `## Robustness Review`, `## Misalignment Review`, each as `\n\n**State**: no findings\n\nno findings: on main\n` — then proceed to Step 9 (no agents).

**Prep (deterministic helpers — fast, run both before launching any agent):**

1. Security changeset — run **exactly** as below (agent-invoked, self-managing; no redirects, `wc`, `cat`, `grep`):
   ```
   .cwf/scripts/command-helpers/security-review-changeset --wf-step=implementation-exec
   ```
   Capture stdout/stderr/exit. It writes the full diff to a `.out` file per § "Changeset coverage" and prints `security-review-changeset: wrote <N> lines to <abs-path>`. This single run is the source of truth for **four** sections — the security section **and** the three lens sections (improvements / robustness / misalignment), which share its verdict-or-agent decision across every exit state. Branch on the **exit code first**, then the count:
   - **exit 0, count > 0**: the security agent **and** the three lens agents will be launched in the MAP; `{changeset_file}` = the `<abs-path>` for all four.
   - **exit 0, count 0**: record `## Security Review` **and** each of `## Improvements Review` / `## Robustness Review` / `## Misalignment Review` as `no findings` (`no findings: empty changeset`); no security or lens agent.
   - **exit 0 but no parseable confirmation line**: record those same four sections as `error` (`error: changeset helper produced no parseable confirmation line`); no security or lens agent.
   - **exit 2** (cap exceeded — the CODE portion is over the cap; **docs are always reviewed**, Task 223): follow the deferred-docs contract in `.cwf/docs/skills/security-review.md` § "Deferred code review (over-cap)". Parse the helper's SECOND confirmation line, `security-review-changeset: wrote <D> doc lines to <docs-abs-path>`:
     - **doc line present, `D` > 0**: launch the security **and** three lens agents on the docs — `{changeset_file}` = `<docs-abs-path>` for all four.
     - **doc line present, `D` == 0**: record `## Security Review` and the three lens sections as `no findings` (`no findings: no docs to review`); no security or lens agent.
     - **doc line ABSENT**: record those four sections as `no findings` (`no findings: docs not separable — base-path unconfigured`); no security or lens agent. Do **not** read this as "no docs" — docs simply could not be separated from code, so they counted toward the cap.
     - **In ALL three cases** ALSO append a dedicated `## Changeset Review — Code (Deferred)` section carrying `**State**: deferred` and the helper's `cap exceeded: <P> production lines > <cap>` stderr line as the detail — code review is *deferred to a smaller changeset*, never silently passed.
   - **any other non-zero**: record those same four sections as `error` (`error: changeset construction failed (<helper stderr>)`); no security or lens agent.
   - **Regardless of exit code**: surface any stderr `warning:` line (e.g. the deprecated `security.review.test-paths` key) to the user verbatim and note it **once** under `## Security Review` (it derives from this one helper run — do not duplicate it under the lens sections).

2. Best-practice context — run **exactly** as below (same no-boilerplate rule):
   ```
   .cwf/scripts/command-helpers/best-practice-resolve --task-num=<num> --phase=implementation-exec
   ```
   Capture stdout/stderr/exit. It prints `best-practice-resolve: wrote <N> matched entries to <abs-path>`. Branch on the **exit code first**, then the count, to decide the **Best-Practice verdict-or-agent**:
   - **exit 1**: record `## Best-Practice Review` `error` (`error: best-practice-resolve failed (<helper stderr>)`); no bp agent (a broken config must never read as clean).
   - **exit 0, count 0**: record `## Best-Practice Review` `no findings` (`no findings: no applicable best practices`); no bp agent.
   - **exit 0, count ≥1**: a bp agent will be launched **iff** helper #1 produced a usable changeset — either an exit-0 changeset (count > 0) OR, on an exit-2 breach, a deferred doc `.out` with `D` > 0 (Task 223: the docs are reviewed, so best-practice reviews them too, keeping the MAP 5-reviewer). `{changeset_file}` = whichever applies, `{bp_context_file}` = this resolver's `<abs-path>`. If there is no changeset to review (empty exit-0 changeset, or an over-cap breach with no doc line or `D` == 0), record `## Best-Practice Review` `no findings` (`no findings: no changeset to review`); no bp agent.
   - **Regardless of exit code**: surface any stderr `warning:` line verbatim and note it under `## Best-Practice Review`.

**Invariant**: *every one of the five sections is always emitted* — by the classifier when its agent launched, or by a direct verdict-or-agent record when it did not (on-main, empty changeset, helper error). No section is ever silently absent.

**MAP (launch in parallel)**: in ONE message, issue the Agent calls for whichever reviewers the Prep selected (0 to 5 calls):
- security: `subagent_type="cwf-security-reviewer-changeset"`, `{wf_step}` = `"implementation-exec"`, `{changeset_file}`.
- best-practice: `subagent_type="cwf-best-practice-reviewer-changeset"`, `{wf_step}` = `"implementation-exec"`, `{changeset_file}`, `{bp_context_file}`.
- improvements: `subagent_type="cwf-improvements-reviewer-changeset"`, `{wf_step}` = `"implementation-exec"`, `{changeset_file}`.
- robustness: `subagent_type="cwf-robustness-reviewer-changeset"`, `{wf_step}` = `"implementation-exec"`, `{changeset_file}`.
- misalignment: `subagent_type="cwf-misalignment-reviewer-changeset"`, `{wf_step}` = `"implementation-exec"`, `{changeset_file}`.

**Classify + record**: write each launched agent's verbatim output to its own scratch `.out` named `<reviewer>-review-output-implementation-exec.out` (`<reviewer>` ∈ {`security`, `best-practice`, `improvements`, `robustness`, `misalignment`}; derive the dir per `.cwf/docs/conventions/tmp-paths.md`, `mkdir -m 0700` on first use). Then classify **all** of them in ONE invocation — no shell loop, no `< <file>` redirect (this single literal argv matches the allowlist and raises no prompt):

```
.cwf/scripts/command-helpers/security-review-classify --dir <scratch-dir> --phase implementation-exec
```

It prints one `<reviewer>: <token>` line per discovered file (lexical order). Map each line's reviewer prefix to its section heading and record `**State**: <token>` above that agent's verbatim output:

- `security` → `## Security Review`
- `best-practice` → `## Best-Practice Review`
- `improvements` → `## Improvements Review`
- `robustness` → `## Robustness Review`
- `misalignment` → `## Misalignment Review`

The helper is the sole classifier — do NOT apply any prose/heuristic rule. Each section is recorded **independently**: one reviewer's `error` never suppresses another's. **Cross-check** the launched set against the classified lines: any reviewer you launched whose line is absent (its `.out` was never written) is recorded `error`, never silently dropped (an unreadable-but-present file already classifies as `error`). A tool-level Agent failure is recorded as `error`.

Do NOT block on `findings` from either reviewer. Surface them; the user decides whether to fix-and-re-run or accept-and-record before Step 9.

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
