# Assess harness worktree tools vs CWF code - Plan
**Task**: 177 (discovery)

## Task Reference
- **Task ID**: internal-177
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/177-assess-harness-worktree-tools-vs-cwf-code
- **Baseline Commit**: 60300d3ba77e805119b7a89795b1194a449b07a5
- **Template Version**: 2.1

## Goal
Verify the harness worktree-tool semantics that the "Adopt guarded
EnterWorktree/ExitWorktree" backlog item assumes — against the current Claude
Code docs and CWF's actual worktree code — and rewrite that backlog item with
grounded context so the eventual feature task can be planned on facts, not on
Task-172-era inference.

## Success Criteria
- [ ] Each harness-semantics claim in the backlog item is marked
      Confirmed / Refuted / Unverifiable against a cited current source
      (live tool schema, harness docs, or empirical probe).
- [ ] CWF's raw-worktree call sites are inventoried with file:line, stating
      for each whether the guarded tools could replace the raw `git worktree`
      call and what would block that.
- [ ] The `worktree.baseRef` default and the `discard_changes` /
      `action: remove` refusal behaviour are each pinned to a concrete source,
      not paraphrased from memory.
- [ ] The deferred-tool reality (EnterWorktree/ExitWorktree now load via
      ToolSearch) is assessed for whether it blocks invocation from CWF skills.
- [ ] The backlog item is rewritten in place via `cwf-backlog-manager`,
      with claims updated to match findings and any refuted assumptions removed.

## Original Estimate
**Effort**: <1 day
**Complexity**: Low (read/verify/document; no production code change)
**Dependencies**: Access to current Claude Code tool schemas (via ToolSearch)
and harness worktree docs; the Task 172 f/j files as the source of the original
claims.

## Major Milestones
1. **Claims extracted**: Every harness-semantics assertion in the backlog item
   and its Task 172 source files is itemised as a discrete, testable claim.
2. **Sources gathered**: Live EnterWorktree/ExitWorktree schemas + any harness
   worktree docs read; CWF raw-worktree call sites located.
3. **Verdicts assigned**: Each claim Confirmed/Refuted/Unverifiable with a cite.
4. **Backlog item rewritten**: Updated entry written via the helper.

## Risk Assessment
### High Priority Risks
- **Risk 1**: Tool schemas/docs are not authoritative on runtime behaviour
  (e.g. the `discard_changes` refusal), so a claim is "verified" from a schema
  description that does not reflect what the tool actually does.
  - **Mitigation**: Prefer an empirical probe (create a throwaway worktree, try
    `ExitWorktree(action: remove)` with dirty state) over schema prose; when no
    safe probe exists, mark Unverifiable rather than Confirmed.

### Medium Priority Risks
- **Risk 2**: Scope creep into designing/implementing the adoption itself.
  - **Mitigation**: This task ends at a rewritten backlog item. No production
    edits to CWF worktree code, no skill changes. The feature task does that.
- **Risk 3**: An empirical probe mutates the working tree or loses work.
  - **Mitigation**: Probe only in a disposable scratch worktree on a throwaway
    branch; never run a destructive variant against the live tree
    (cf. `feedback_worktree_cwd_dataloss`).

## Dependencies
- Task 172 `f-implementation-exec.md` (§2/§3/§6) and `j-retrospective.md`
  (§Future Work) — the origin of the claims under test.
- Current Claude Code harness (this session) for live tool schemas.

## Constraints
- Discovery only: deliverable is verified findings + a rewritten backlog item.
- No `discard_changes: true` in any probe (cf.
  `feedback_surface_security_dont_smooth`).
- Probes must obey the no-`cd`-into-disposable-worktree rule
  (`feedback_worktree_cwd_dataloss`).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No.
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one concern (verify + rewrite).
- [ ] **Risk**: High-risk components needing isolation? No (probes are scratch).
- [ ] **Independence**: Can parts be worked on separately? Not usefully.

No decomposition signals triggered — proceed as a single discovery task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Completed on estimate (<1 day). All success criteria met: C1–C4 Confirmed against
live schemas, C5 Refuted, C6 Confirmed; backlog item rewritten via helper. See
`f-implementation-exec.md` (findings) and `g-testing-exec.md` (TC-1…TC-6 PASS).

## Lessons Learned
The goal widened from "verify the claims" to "characterise how worktrees are *used*
with CWF" (C6) after an operator clarification. See `j-retrospective.md`.
