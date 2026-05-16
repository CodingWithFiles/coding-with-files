# Plan Review (Map/Reduce)

After writing a plan file and checking decomposition signals, review the plan using 4 parallel subagents before the checkpoint commit.

## Procedure

Given the plan type (`requirements`, `design`, or `implementation`):

### 1. MAP: Launch 4 Subagents

Launch all 4 Agent calls in a single message (parallel execution). Each
call uses a distinct CWF agent — one per column — and each column's
criteria are baked into the agent body, so the SKILL-side prompt only
needs to pass `{plan_file_path}` and `{plan_type}`.

| Column        | `subagent_type`                       |
|---------------|---------------------------------------|
| Improvements  | `cwf-plan-reviewer-improvements`      |
| Misalignment  | `cwf-plan-reviewer-misalignment`      |
| Robustness    | `cwf-plan-reviewer-robustness`        |
| Security      | `cwf-plan-reviewer-security`          |

**Prompt template** (substitute `{plan_file_path}` and `{plan_type}`):

```
Review the {plan_type} plan at {plan_file_path}.

Inputs:
- plan_file_path: {plan_file_path}
- plan_type: {plan_type}

Follow the procedure in your agent definition.
```

### 2. REDUCE: Synthesise Findings

After all 4 subagents complete (skip any that failed):

1. Collect findings from all subagents
2. Identify tradeoffs between competing suggestions
3. Use your judgement to decide which findings to apply
4. Apply chosen changes to the plan file using the Edit tool
5. Present a summary to the user: what was changed and any unapplied suggestions
6. If no actionable findings: output "Plan review: no changes needed"

## Failure Handling

- If some subagents fail (but not all): synthesise the remaining results normally
- If all 4 fail: log a warning and proceed to checkpoint commit without review
