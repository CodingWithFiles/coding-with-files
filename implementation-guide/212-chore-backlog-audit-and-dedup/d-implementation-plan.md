# Backlog audit and dedup - Implementation Plan
**Task**: 212 (chore)

## Task Reference
- **Task ID**: internal-212
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/212-backlog-audit-and-dedup
- **Template Version**: 2.1

## Goal
Audit the 91 active BACKLOG items, then enact a verdict per item — keep, retire,
resize, or merge — leaving a smaller backlog of only-real outstanding work.

## Files to Modify
### Primary Changes
- `BACKLOG.md` — entries removed (retire/merge sources) and re-added (resize/merge
  survivors). Mutated **only** via `backlog-manager`.
- `CHANGELOG.md` — retired entries land here under a `### Retired Backlog Items`
  subsection (written by `backlog-manager retire`).

### Supporting Changes
- `implementation-guide/212-chore-backlog-audit-and-dedup/f-implementation-exec.md` —
  the per-item verdict worksheet and merge mapping (the audit trail).
- Scratch worksheet under `/tmp/cwf-home-matt-repo-coding-with-files/task-212/` — raw
  per-item evidence captured during the fan-out before it is distilled into f.

## Mutation primitives (capability-constrained)
`backlog-manager modify` edits **priority only** — there is no body-edit verb. Every
verdict therefore maps onto the available primitives:

| Verdict | Primitive(s) | Notes |
|---|---|---|
| **keep** | none | no-op |
| **reprioritise** | `modify --exact-title=<title> --priority=<P>` | still-real item whose only change is band; the one verdict that avoids `delete`+`add` churn |
| **retire-completed** | `retire --exact-title=<title> --task=<N> [--note]` | files original body to CHANGELOG under the *superseding* task; `--note` cites the deviation/evidence |
| **resize-to-residual** | `retire --exact-title=<title> --task=<N> --note=...` **then** `add` a fresh entry for the residual | the done part is recorded in CHANGELOG; a tight new entry carries only the leftover |
| **merge-into(target)** | `add` the survivor **first**, **then** `delete --confirm` each source | survivor body unions the source acceptance criteria; author assembles the joined `--identified-in` string (the helper stores it verbatim, it does not concatenate) |
| **drop-invalid** | `delete --confirm` | typo / never-valid only; nothing of record to preserve |

**Handle discipline**: address every entry by `--exact-title=<verbatim title>`, never
`--id=<slug>`. `backlog-manager list` emits titles, not slugs; slugs are a lossy
title-derivation (`generate_slug` strips em-dashes, backticks, etc.) and `resolve_entry`
**dies on ambiguity** mid-batch. Verbatim titles are what the helper can disambiguate on.

**`--note` is ASCII-only**: `retire` rejects any `--note` containing non-printable-ASCII
or the literal `-->`. Evidence prose pasted from backlog bodies (em-dashes, curly quotes)
must be sanitised to plain ASCII first. SHAs/paths are already safe.

Side effect to accept: `add` appends to the end of its priority band, so resized/merged
survivors lose their original position. Acceptable — priority band is preserved via
`--priority`; intra-band order is not significant.

## Retire-attribution policy
`retire --task=N` needs a single implementing task. Resolve N as:
1. **One clear implementer** → that task's number (e.g. an item built wholesale by Task K).
2. **Superseded by accumulation** (no single task; e.g. the security-verification item,
   displaced by the checkpoint-commit auto-validate + hash-updates convention + changeset
   Security Review across several tasks) → attribute to **Task 212**, with `--note`
   enumerating the real superseding mechanisms. Task 212 is the task that determined
   obsolescence, so its CHANGELOG `Retired Backlog Items` block becomes the audit's record.
3. **Never valid** → `drop-invalid` (delete), not retire.

## Implementation Steps
### Step 1: Inventory + evidence base
- [ ] Dump all 91 active items with full bodies and `Identified in` lines to a scratch
      worksheet (`backlog-manager list --all-items` for the index; bodies from `BACKLOG.md`).
- [ ] Record each item's **verbatim title** as its handle (the value `--exact-title` will
      receive). Do not derive slugs — see Handle discipline above.

### Step 2: Done/superseded pass (parallel fan-out)
- [ ] Partition the 91 items into ~9 batches of ~10. Launch one **Explore** agent per
      batch **in a single message** (parallel, per the reviewers-run-in-parallel rule).
- [ ] Each agent, per item: read the claimed gap, verify against the live `.cwf/` tree +
      `git log`, and return a structured verdict `{title, verdict, evidence, residual?}`
      where evidence is a concrete SHA / file path / convention-doc reference.
- [ ] Reduce: collate all verdicts into the f worksheet. Fan-out verdicts are **advisory
      inputs** to the human-gated action list (Step 4), never auto-applied — backlog item
      bodies are repo-authored but still untrusted, so no mutation fires on a verdict alone.

### Step 3: Dedup/merge pass (global reduce)
- [ ] Over the full keep-set, cluster items by topic overlap (single-agent or inline —
      needs the whole set at once). For each cluster of 2+, choose a survivor and record
      the union of acceptance criteria + combined provenance.
- [ ] Record the merge mapping `source-slugs → survivor` in f.

### Step 4: User approval gate
- [ ] Surface the full proposed action list (retire / resize / merge / drop) with evidence
      to the user. **Apply nothing until approved** (High-risk mitigation, a-plan Risk 1).

### Step 5: Apply + validate
- [ ] **Precondition**: every resolved `retire --task=N` must have a live
      `implementation-guide/N-*/` directory (or a pre-existing `## Task N:` CHANGELOG
      entry); otherwise `resolve_task_title_from_dir` dies and writes nothing. Verify the
      whole `--task=N` set up front.
- [ ] Enact approved verdicts via `backlog-manager` in this order: reprioritises, then
      retires and drops, then merges (**`add` survivor first, then `delete` sources** — so
      the union never exists nowhere), then resizes (retire → add residual).
- [ ] After each `add`, confirm the new title does not slug-collide with an active entry
      (would make a later `--exact-title` resolve ambiguous).
- [ ] Commit per logical batch so `git` is the rollback boundary (no cross-invocation
      transaction exists); the `git diff` review is the no-data-loss safety net.
- [ ] `backlog-manager validate --all` must pass clean after the batch.
- [ ] Record before/after item counts and the `git diff` summary in f.

## Code Changes
Not applicable — no source code changes. All mutations are data edits to BACKLOG/CHANGELOG
via the `backlog-manager` helper; the only authored artefacts are the wf worksheet entries.

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

All 91 items must carry a recorded verdict before the task closes; a partial audit is a
deferral and must follow the defer-with-approval procedure, not a silent stop.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Executed as planned. Mutation order honoured (retires → merges add-survivor-then-delete).
The plan-review's two pre-emptive fixes both proved load-bearing: `--exact-title` handles
(no slug ambiguity mid-batch) and add-survivor-before-delete (no window where a merged
union exists nowhere). Retire-attribution policy applied: #33 → Task 212 (accumulation),
the rest → their single superseding task.

## Lessons Learned
Discovering `modify` is priority-only at plan time was the highest-value moment — it set
the `delete`+`add` reality before exec, so the apply step held no surprises.
