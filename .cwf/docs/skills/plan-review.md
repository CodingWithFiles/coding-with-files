# Plan Review (Map/Reduce)

After writing a plan file and checking decomposition signals, review the plan using parallel subagents before the checkpoint commit. Four reviewers always run; a fifth (best-practice) runs only when the user has matching best-practice documentation for this task.

## Procedure

Given the plan type (`requirements`, `design`, or `implementation`):

### 0. Pre-MAP: resolve best-practice context

Run the resolver for this task (it is agent-invoked and self-managing — no surrounding redirect / `wc` / `cat` / `grep`):

```
.cwf/scripts/command-helpers/best-practice-resolve --task-num=<num> --phase=plan
```

Read its **exit code** and the **match count** from its confirmation line `best-practice-resolve: wrote <N> matched entries to <abs-path>`:

- **exit 1**: resolution failed — surface the stderr to the user, skip the 5th agent, run the four as normal.
- **exit 0, count 0**: no applicable best practices — skip the 5th agent.
- **exit 0, count ≥1**: include the 5th agent below, passing the `<abs-path>` as `{bp_context_file}`.

Regardless of exit code, surface any `warning:` line from the helper's stderr to the user verbatim (config diagnostics are upgrade nudges, not failures).

### 1. MAP: Launch Subagents

Launch all Agent calls in a single message (parallel execution). Each call uses a distinct CWF agent — one per column. The four core columns' criteria are baked into the agent body, so their SKILL-side prompt only passes `{plan_file_path}` and `{plan_type}`.

| Column        | `subagent_type`                       |
|---------------|---------------------------------------|
| Improvements  | `cwf-plan-reviewer-improvements`      |
| Misalignment  | `cwf-plan-reviewer-misalignment`      |
| Robustness    | `cwf-plan-reviewer-robustness`        |
| Security      | `cwf-plan-reviewer-security`          |
| Best Practice | `cwf-plan-reviewer-best-practice` (conditional — only when step 0 reports ≥1 match) |

**Core prompt template** (the four always-run columns — substitute `{plan_file_path}` and `{plan_type}`):

```
Review the {plan_type} plan at {plan_file_path}.

Inputs:
- plan_file_path: {plan_file_path}
- plan_type: {plan_type}

Follow the procedure in your agent definition.
```

**Best-Practice prompt template** (the 5th column — it needs the extra `{bp_context_file}` input, so it does not share the core template). Use the template in `.cwf/docs/skills/best-practice-review.md` § "Planning prompt template", substituting `{plan_file_path}`, `{plan_type}`, and `{bp_context_file}` (the `<abs-path>` from step 0).

So the MAP launches **4 agents, or 5 when best-practices match**.

### 2. REDUCE: Synthesise Findings

After all subagents complete (skip any that failed):

1. Collect findings from all subagents (the best-practice reviewer reports prose, like the others)
2. Identify tradeoffs between competing suggestions
3. Use your judgement to decide which findings to apply
4. Apply chosen changes to the plan file using the Edit tool
5. Present a summary to the user: what was changed and any unapplied suggestions
6. If no actionable findings: output "Plan review: no changes needed"

## Failure Handling

- If some subagents fail (but not all): synthesise the remaining results normally
- If all subagents fail: log a warning and proceed to checkpoint commit without review
