# Session Hygiene

## Convention
Sessions accumulate context, drift from standing instructions, and lose
durable state across boundaries (`/clear`, `/compact`, resume). Treat
session boundaries as load-bearing — decide deliberately when to cross
them and what to preserve. This convention captures observed deviation
patterns (P1–P5 in the Task 150 audit) and the defender-side response.

## When to `/clear`
- When the next sub-task is unrelated to current context AND no in-flight
  workflow state would be lost (addresses P1 — agent does not reload
  memories at session start, so a clean session forces a fresh read).
- When session-specific drift (off-topic tangents, abandoned approaches)
  outweighs the cost of reloading project memories and current wf step
  (addresses P4 — Stop-hook context cost is paid each turn until the
  next compaction).
- When a long debugging arc has produced churn that does not inform the
  next task — capture the conclusion in a memory entry or task doc
  first, then `/clear`.
- Do NOT `/clear` to escape a stuck security gate, hash mismatch, or
  failing validator. Surface the issue; never smooth it.

## When to `/compact` + what to preserve
- `/compact` is operator-initiated; auto-compaction is harness-initiated
  when context fills. Either way, the *conversation* is summarised — but
  the CLAUDE.md preamble and project memories are reloaded fresh on each
  turn, independent of the summary.
- Preserve across the boundary:
  - **Standing security rules** from CLAUDE.md `## Critical Rules` and
    MEMORY.md (addresses P2 — summarisation silently drops standing
    instructions).
  - **In-flight workflow state**: current task path, wf step, any
    decisions not yet committed.
  - **Active correction context**: anything the user just said that
    should become a memory entry but is not yet written.
- Do not propose: `recompute-hashes`, `validate --fix`,
  `validate --ignore`, `/clear`-as-gate-bypass, or accepting
  compaction-induced rule loss as the working state. The friction is
  the feature — surface security signals; never smooth them. The same
  principle is inlined in `.cwf/docs/conventions/hash-updates.md`
  `## What NOT to build`, applied here to session boundaries.

## Session boundaries: memory + workflow-state on resume
- Read MEMORY.md at session start (addresses P1 — entries exist but go
  unread). When the user corrects an approach, confirm-then-write:
  check whether a memory entry already exists; if not, write it; if
  yes, update or note why the entry was not applied (addresses P3 —
  cross-session principle leaks).
- On session-resume, re-derive the current wf step from on-disk task
  files (`a-task-plan.md` through `j-retrospective.md` Status fields) —
  do not trust the resumed conversation's claim about "what step we're
  on" (P5 residue; the on-disk state is authoritative).

## See also
- `.cwf/docs/workflow/stop-hooks-framework.md` — `/clear`, `/compact`, resume Stop-hook semantics and context cost
- `.cwf/docs/conventions/hash-updates.md` `## What NOT to build` — sibling residence of the "surface, never smooth" principle
- MEMORY.md "Recurring Process Errors" — workflow-process residue category
- CLAUDE.md `## Critical Rules` — standing rules referenced in the preservation list
