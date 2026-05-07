# Refactor BACKLOG to match current code state - Plan
**Task**: 130 (chore)

## Task Reference
- **Task ID**: internal-130
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/130-refactor-backlog-to-match-current-code-state
- **Baseline Commit**: 26ad3fd81711fc9eeb8a534098c88c330f0800aa
- **Template Version**: 2.1

## Goal
Triage every BACKLOG.md entry against the current repo state and remove, edit, or coalesce items so the backlog is an accurate forward-looking work queue.

## Success Criteria
- [ ] Every active (non-completed) BACKLOG entry has been individually triaged with the user
- [ ] Obsolete entries (work already done) are removed; commit messages cite the implementing task/commit
- [ ] Outdated entries (partially-implemented or scope-shifted) are edited to reflect remaining work
- [ ] Duplicate or overlapping entries are coalesced into single entries
- [ ] Resulting BACKLOG.md is grouped and ordered consistently (priority bands preserved)
- [ ] At least one stale entry confirmed pre-task — `Add Settings.json Merge Helper Script` — is resolved (`cwf-claude-settings-merge` already implements it)

## Original Estimate
**Effort**: 1 day (interactive review session)
**Complexity**: Low
**Dependencies**: User co-review for every entry — judgement-driven, not automatable

## Major Milestones
1. **Inventory**: Snapshot all active entries with priority and short description (already produced this session — reuse)
2. **Triage pass**: Walk entries top-to-bottom; for each, decide keep / edit / remove / coalesce against current code
3. **Apply**: Edit BACKLOG.md to reflect decisions; commit in logical chunks (not one giant diff)
4. **Verify**: Final read-through to confirm grouping, no orphan references, no broken cross-links to other docs

## Risk Assessment
### Medium Priority Risks
- **Subjective triage**: Different readings of "still relevant" can produce different outcomes
  - **Mitigation**: User co-reviews every decision; ambiguous items stay until both parties agree
- **Hidden cross-references**: Removing an entry may break references from other docs (CLAUDE.md, conventions docs, retrospectives)
  - **Mitigation**: Before deleting, grep for the entry's distinguishing phrase across the repo

### Low Priority Risks
- **Scope creep**: Tempting to fix a "small" item inline rather than defer it
  - **Mitigation**: This task only edits BACKLOG.md; any code change spawns a separate task
- **Context loss across sessions**: If triage spans multiple sessions, partial state lives in a long-lived branch
  - **Mitigation**: Commit per logical batch (e.g. per priority band) so progress is durable

## Dependencies
- User availability for interactive review — every entry needs a decision
- Current repo state at HEAD (26ad3fd) is the reference point; later commits during this task may invalidate triage decisions

## Constraints
- BACKLOG.md only — no code changes in this task
- Preserve completed-task entries (`✓` / `~~`) as historical record unless the user explicitly says otherwise
- Priority labels and grouping conventions stay as-is; this is content cleanup, not format reform

## Decomposition Check
- [ ] **Time**: Will this take >1 week? No — single interactive sweep
- [ ] **People**: >2 people? No — solo + user
- [ ] **Complexity**: 3+ distinct concerns? No — one concern (BACKLOG hygiene)
- [ ] **Risk**: High-risk components needing isolation? No — single-file edits, fully reversible
- [ ] **Independence**: Parts that can be worked on separately? Entries are independent, but co-located in one file; subtasks would be process overhead without benefit

No decomposition warranted.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
