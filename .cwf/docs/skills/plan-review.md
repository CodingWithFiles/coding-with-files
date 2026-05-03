# Plan Review (Map/Reduce)

After writing a plan file and checking decomposition signals, review the plan using 4 parallel subagents before the checkpoint commit.

## Procedure

Given the plan type (`requirements`, `design`, or `implementation`):

### 1. MAP: Launch 4 Subagents

Launch all 4 Agent calls in a single message (parallel execution). Use `subagent_type: "Explore"`. For each, substitute `{focus_area}` and `{criteria}` from the lookup table below.

**Prompt template** (substitute `{plan_file_path}`, `{plan_type}`, `{focus_area}`, `{criteria}`):

```
Review the {plan_type} plan at {plan_file_path} for {focus_area}.

You may only use Read, Grep, and Glob (no Bash, no edits).

Do not use program composition with the Bash tool for simple tasks; use the built-in tools instead. Read with `offset`/`limit` for line ranges; chain Glob → Read or Grep → Read instead of pipelines.

Common anti-patterns (use the built-in):
- `sed -n 'X,Yp' file` → Read with `offset=X limit=Y-X+1`
- `cat file | grep …` → Grep
- `find … -exec cat {} \;` for a handful of files → batched Read calls

Full rubric: `.cwf/docs/conventions/subagent-tool-selection.md`.

1. Read the plan file.
2. Grep the codebase for existing code, patterns, or utilities relevant to what the plan proposes.
3. Assess the plan against these criteria: {criteria}

For each finding, state: what is wrong, where it is in the plan, and what to do about it. Be concise — report only actionable findings. If the plan is sound for your focus area, say so briefly.
```

### 2. Criteria Lookup Table

|              | Improvements | Misalignment | Robustness | Security |
|--------------|-------------|--------------|------------|----------|
| requirements | Does the plan achieve its goal with minimal acceptance criteria? Are any requirements unnecessary or redundant? Could fewer requirements cover the same ground? | Do requirements overlap with existing functionality? Are conventions and existing patterns referenced rather than reinvented? | Are acceptance criteria testable? Are edge cases covered? Are failure scenarios addressed? | Are security-relevant requirements (input handling, file permissions, env vars, prompt-injection surface) named explicitly? Are any missing? See `.cwf/docs/skills/security-review.md` § "Threat categories" for the CWF threat model. |
| design       | Is the architecture as simple as possible? Are there unnecessary components, layers, or abstractions? Could the design achieve the same result with fewer moving parts? | Does the design reuse existing patterns and abstractions in the codebase? Is it consistent with established conventions? Does it avoid reinventing what already exists? | Are failure modes identified? Are degradation paths defined? Does the design prioritise correctness over maintainability over performance? | Does the design name how each FR4(a–e) threat category is addressed (or explicitly out-of-scope)? Do new components introduce attack surface (file writes, exec, hook registration, env-var reads) without a deliberate decision? See `.cwf/docs/skills/security-review.md`. |
| implementation | Does the plan minimise file changes? Does it reuse existing code? Could the same result be achieved with less new code? | Does the plan use existing libraries, modules, and utilities? Does it check what already exists before proposing new code? Does it match project abstractions? | Does the plan handle errors correctly? Does it follow correct > maintainable > performant ordering? Are edge cases addressed in the implementation steps? | Do the planned code changes introduce any of the FR4(a–d) anti-patterns? Are any FR4(e) pattern-based risks present (safe here, risky if reused)? See `.cwf/docs/skills/security-review.md` for examples and remediation. |

### 3. REDUCE: Synthesise Findings

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
