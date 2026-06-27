# Backlog audit and dedup - Plan
**Task**: 212 (chore)

## Task Reference
- **Task ID**: internal-212
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/212-backlog-audit-and-dedup
- **Baseline Commit**: 124c706c37d103fe612b92acd3d52764d80bf47d
- **Template Version**: 2.1

## Goal
Audit all 91 active BACKLOG items, retiring or resizing those already implemented or
superseded and merging duplicate/related entries, so the backlog reflects only real
outstanding work.

## Success Criteria
- [ ] Every active item (18 Medium + 73 Low = 91) carries a recorded verdict: keep /
      retire-completed / resize-to-residual / merge-into(`<target>`).
- [ ] Each retire or resize verdict cites concrete superseding evidence (a commit SHA,
      file path, or convention doc) — no verdict on assertion alone.
- [ ] Duplicate and related items are clustered and merged so each surviving entry is
      distinct; merged entries union the acceptance criteria of their sources.
- [ ] All mutations applied via `backlog-manager` (no direct edits); `backlog-manager
      validate --all` passes clean afterwards.
- [ ] The Task-32 "Add Security Verification to Testing Workflow" entry is resolved
      (retired or resized to the lone `workflow-steps.md` doc gap) as worked example #1,
      with the supersession evidence recorded.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium
**Dependencies**: `backlog-manager` helper (list/validate/delete/retire/modify/add); git
history and the installed `.cwf` tree as the evidence base for "already done".

## Major Milestones
1. **Inventory + evidence base**: extract all 91 items with bodies into a worksheet under
   the task scratch dir; capture each item's `Identified in` provenance.
2. **Done/superseded pass**: per item, verify the claimed gap against the live codebase;
   assign keep / retire / resize with cited evidence.
3. **Dedup/merge pass**: cluster related items; decide a single survivor per cluster and
   the union of its acceptance criteria.
4. **Apply + validate**: enact verdicts via `backlog-manager`; run `validate --all`;
   produce a before/after item count and a reviewable diff.

## Risk Assessment
### High Priority Risks
- **Risk 1 — False "already done"**: retiring an item that is only partially superseded
  silently drops real outstanding work.
  - **Mitigation**: every retire/resize must cite concrete evidence; prefer *resize to
    residual* over outright delete when supersession is partial; surface the full
    kill/resize list for user approval before any mutation is applied.

### Medium Priority Risks
- **Risk 2 — Bulk mutation corrupts the backlog**: many deletes/merges in one task risk
  format breakage or accidental loss.
  - **Mitigation**: all changes go through `backlog-manager` (format-validated); work on
    the task branch; `validate --all` after each batch; the git diff is the audit trail.
- **Risk 3 — Merging loses nuance**: a merged survivor drops a distinct sub-point or
  provenance from a source entry.
  - **Mitigation**: merged entries union the source acceptance criteria and retain each
    source's `Identified in` line; record the merge mapping in the exec file.
- **Risk 4 — Retire has no implementing task**: `retire` files an entry to CHANGELOG
  under an *implementing* task, but obsolete-never-built items were superseded by other
  tasks. Choosing the wrong attribution mis-records history.
  - **Mitigation**: resolve the retire-attribution policy in the implementation plan
    (attribute to the task that actually superseded it; fall back to delete for
    never-relevant/typo entries).

## Dependencies
- `backlog-manager` subcommands: `list`, `validate`, `delete`, `retire`, `modify`, `add`.
- Git history (`git log`) and the installed `.cwf/` tree as the evidence base.

## Constraints
- BACKLOG/CHANGELOG mutated only via `backlog-manager` — never direct Edit/Write.
- British spelling, no personal names, role nouns only in any reworded entry.
- The audit assesses; it does not implement any audited item's underlying work.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — estimated 1-2 days.
- [ ] **People**: Does this need >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? Two passes (done/superseded, dedup/merge)
      over 91 items — one cohesive audit, but the exec phase will fan out across reviewer
      agents per item-cluster rather than decompose into subtasks.
- [ ] **Risk**: High-risk components needing isolation? No — mutations are reversible on a
      branch and gated by user approval.
- [ ] **Independence**: Can parts be worked separately? Medium vs Low bands could split,
      but the user scoped a single all-91 audit; kept whole.

Verdict: 1 signal (complexity); below the 2-signal threshold. Keep as a single task;
parallelise within the exec phase, not via subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 success criteria met. 91 items each carry a recorded verdict (f ledger); every retire
cites concrete superseding evidence; 7 duplicates merged into 3 distinct survivors;
`validate --all` clean; the security-verification item resolved as worked example #1.

## Lessons Learned
The decomposition call (single task, parallelise within exec) held — a 10-agent fan-out
kept it one session. Risk 1 (false "already done") materialised exactly once and was caught
by the evidence requirement.
