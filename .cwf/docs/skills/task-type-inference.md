# Task Type Inference

This rubric guides the `cwf-new-task` and `cwf-new-subtask` skills when `<type>`
is omitted from the argument list. The skills read this file at invocation
time and use it to (1) infer which wf steps the described work needs, then
(2) pick the supported task type whose canonical step set is the closest fit.

The rubric is also the human-readable documentation for what each task type
means. No code parses this file; the LLM reads and reasons over it directly.

## Step Semantics

| Letter | Step | Purpose |
|---|---|---|
| a | task-plan | Frame the work: goal, success criteria, milestones, risks. |
| b | requirements | Elicit and record functional/non-functional requirements when scope is fuzzy or has multiple defensible interpretations. |
| c | design | Record architecture choices, interface contracts, and the trade-offs that motivated them. |
| d | implementation-plan | Decide which files change, in what order, and how the change is verified. |
| e | testing-plan | Decide what "tested" means for this change: levels, coverage, test cases. |
| f | implementation-exec | Write the code. |
| g | testing-exec | Run the tests. Record outcomes. |
| h | rollout | Coordinate the cutover: migration, announcement, deploy, deprecation. |
| i | maintenance | Establish ongoing care: cron entries, dashboards, runbooks, monitoring. |
| j | retrospective | Capture what was learned; surface drift between plan and reality. |

## Always-Required Steps

Every task type includes `a, d, e, f, g, j`. Rationale:

- `a` frames the work — without it the rest is undirected.
- `d, e, f, g` are the minimum execute-and-verify loop.
- `j` is the project's quality-feedback channel; skipping it breaks the
  "eat-your-own-dog-food" loop CWF depends on.

The remaining four steps (`b`, `c`, `h`, `i`) are what distinguish one task
type from another.

## Discriminating Questions

For a given task description, answer four yes/no questions. The combined
answers form a 4-bit signature `(b, c, h, i)` that determines which canonical
task type fits.

### b — Does this task need requirements elicitation?

Include `b` when:
- The user describes outcomes ("make the dashboard faster") rather than a
  specific change ("rewrite the n+1 query in get_dashboard()").
- Multiple plausible "what should it do?" interpretations exist.
- Acceptance criteria are elastic or undefined at task start.

Skip `b` when:
- The change has a clear, single, externally-defined target (a bug report,
  a precise mechanical migration, a known deprecation).
- A reasonable engineer reading the description would arrive at the same
  acceptance criteria without further conversation.

### c — Does this task need design?

Include `c` when:
- Multiple plausible *how* approaches exist (algorithm choice, library
  choice, schema layout, where to put a boundary).
- The change touches an interface boundary or architectural seam.
- Non-trivial trade-offs need to be recorded for future readers.

Skip `c` when:
- The implementation is a single obvious approach (rename, lint fix,
  parameter tweak, doc edit).
- The change is purely mechanical (e.g. a syntactic migration with one
  reasonable transformation per call site).

### h — Does this task need rollout?

Include `h` when:
- The change is externally observable: end-user-visible behaviour, deploy
  surface, public API contract, schema available to other services.
- Migration, announcement, or coordinated cutover is required.
- Other people or systems must adapt before, during, or after merge.

Skip `h` when:
- The change is internal-only (refactor with identical external behaviour,
  internal helper rename, dev-tooling tweak).
- The deploy mechanism handles the change without operator action.

### i — Does this task need maintenance?

Include `i` when:
- The change introduces something requiring ongoing care: a cron job, a
  dashboard, a deprecation window, a runbook entry, a monitoring alert.
- The change has a follow-up obligation with a stated future date.

Skip `i` when:
- The change is self-contained and complete at merge.
- No future-dated obligation is created by the work.

## Canonical Step Sets

The five supported task types are exhaustive over the practically relevant
`(b, c, h, i)` combinations. The mapping is fixed and version-controlled here.

| Type | (b,c,h,i) | Step letters |
|---|---|---|
| chore | (0,0,0,0) | a,d,e,f,g,j |
| hotfix | (0,0,1,0) | a,d,e,f,g,h,j |
| bugfix | (0,1,0,0) | a,c,d,e,f,g,j |
| discovery | (1,1,0,0) | a,b,c,d,e,f,g,j |
| feature | (1,1,1,1) | a,b,c,d,e,f,g,h,i,j |

## Resolution Algorithm

1. Read this rubric.
2. Apply the discriminating questions to the task description to produce a
   step set `S ⊆ {a..j}`, always including the six always-required steps.
3. For each candidate type `T` in the canonical table above, compute the
   symmetric-difference distance `d(T) = |S Δ C_T|` where `C_T` is the step
   set listed for `T`.
4. If exactly one type has `d(T) == 0`, select it silently. Proceed to
   `task-workflow create` with that type as the resolved `<type>`.
5. Otherwise, show the user the ambiguity prompt (next section). Do not
   pick a type silently when `min d(T) > 0`.
6. If `min d(T) >= 3` across all types, treat the inference as degenerate:
   show the inferred set, all distances, and the 3-arg-form fallback hint.
   Refuse to auto-prompt — a distance of 3+ usually means the description
   or the rubric is wrong, not that any canonical type is "close enough".

## Ambiguity Prompt Format

When no exact match exists, show the user something like:

```
No exact task-type match for description: "Investigate why X is slow and fix it"
Inferred steps: a, b, c, d, e, f, g, j  (requirements + design + standard execution + retrospective, no rollout/maintenance)

Closest matches:
  1. discovery  (distance 0)  — differs in: none (exact)
  2. bugfix     (distance 1)  — differs in: b   (would drop requirements)
  3. feature    (distance 2)  — differs in: h, i (would add rollout + maintenance)

Pick a type (1/2/3), or rerun with explicit type (e.g. /cwf-new-task <num> feature "...").
```

Response handling:
- Numeric pick in `1..N` → use that candidate, proceed to
  `task-workflow create`.
- Any other input (empty, `q`, out-of-range) → cancel. Print the 3-arg
  form fallback and exit. No directory created, no branch checked out.

## Adding A New Task Type

Adding a new task type (e.g. a future `spike`) requires three coordinated
edits. All three are needed before the type is selectable:

1. Create `.cwf/templates/<new-type>/` containing symlinks to the
   appropriate templates in `.cwf/templates/pool/`.
2. Add `<new-type>` to `cwf-project.json:supported-task-types`. The
   `template-copier-v2.1::validate_task_type` gate enforces this list.
3. Add a row to the canonical-step-set table above:
   `<new-type> | (b,c,h,i tuple) | <step letters>`.

The drift-detection test `t/task-type-inference-rubric.t` enforces
consistency between the rubric's table and the actual template
directories — a missing or mismatched row fails the test.
