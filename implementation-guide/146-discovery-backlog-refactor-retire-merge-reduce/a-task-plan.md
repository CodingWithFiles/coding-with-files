# Backlog refactor: retire, merge, reduce - Plan
**Task**: 146 (discovery)

## Task Reference
- **Task ID**: internal-146
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/146-backlog-refactor-retire-merge-reduce
- **Baseline Commit**: ed94f608f4764f4846f520bf0e3a6f2aa040ebbe
- **Template Version**: 2.1

## Goal
Review every BACKLOG.md entry against three axes -- still-applicable, mergeable, scope-reducible -- and produce a per-item recommendation list for user approval before any mutation.

## Success Criteria
- [ ] Every BACKLOG.md entry (68 at task start) is classified against all three axes and assigned one of: retire, merge-into-other, reduce-scope, keep-as-is
- [ ] Recommendations are captured in a single review artefact under the task directory, one row per entry, with a short rationale per non-keep action
- [ ] User explicitly approves the recommendations (or amended subset) before any edit lands in BACKLOG.md / CHANGELOG.md
- [ ] After approved edits land, `backlog-manager validate` passes clean and the round-trip property (parse -> serialise is byte-identical) holds
- [ ] Net entry count in BACKLOG.md is reduced relative to baseline (i.e. measurable shrink, not just renames)

## Original Estimate
**Effort**: 1 day
**Complexity**: Medium
**Dependencies**: Read access to retrospectives referenced by entries (for "still applicable" judgement); `backlog-manager` helper for retire / validate operations

## Major Milestones
1. **Inventory pass**: Tabulate all 68 entries with current priority, age, and originating task; first-pass classification per axis
2. **Recommendations draft**: Single artefact listing per-item action + rationale; cross-cut summary (counts per action category)
3. **User review gate**: Present recommendations; capture approvals, amendments, and overrides
4. **Apply approved edits**: Use `backlog-manager retire` for retirements; manual edits for merges and scope reductions; re-run validate

## Risk Assessment
### High Priority Risks
- **R1 -- Subjective judgement discards items the user still wants**: Many "low" entries are deliberately parked, not stale
  - **Mitigation**: Recommendations are advisory only; nothing mutates BACKLOG.md until the user approves the row-by-row list. Default ambiguous cases to "keep" rather than "retire".

### Medium Priority Risks
- **R2 -- Token budget**: BACKLOG.md plus referenced retrospectives is large; re-reading everything per item is wasteful
  - **Mitigation**: Read BACKLOG.md once; only read a retrospective when the entry's body is too thin to judge on its own. Process entries in priority order so high-signal items get the most attention.
- **R3 -- Merge loses nuance**: Combining two related entries can drop a constraint or rationale present in only one
  - **Mitigation**: Merge target preserves the union of constraints / rationales from both source entries; never the intersection. Source-entry text is quoted into the merge target before retirement.

### Low Priority Risks
- **R4 -- Pure-ASCII invariant regression**: Discovery output and any new BACKLOG content must not introduce upper-plane Unicode (em-dashes, curly quotes) per editor-portability principle
  - **Mitigation**: Use `--` and `'...'` in any new prose; spot-check edits with `LC_ALL=C grep -nP '[^\x00-\x7F]' BACKLOG.md` before commit

## Dependencies
- `.cwf/scripts/command-helpers/backlog-manager` (list, validate, retire)
- `.cwf/lib/CWF/Backlog.pm` parser (round-trip property must hold)
- Per-entry retrospective references (read on demand only)

## Constraints
- All retirements must go through `backlog-manager retire` (preserves CHANGELOG block + idempotency), not direct edits
- Round-trip property and validator must remain clean after every committed edit
- No new upper-plane Unicode codepoints introduced into BACKLOG.md or CHANGELOG.md
- This is a discovery task: the deliverable is a reviewed plan + applied edits, not new functionality

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? No -- one coherent review pass
- [x] **People**: Does this need >2 people working on different parts? No
- [x] **Complexity**: Does this involve 3+ distinct concerns? Three axes, but one reviewer applying a uniform rubric
- [x] **Risk**: Are there high-risk components that need isolation? No -- user gate covers the only material risk
- [x] **Independence**: Can parts be worked on separately? Not usefully -- merge decisions depend on seeing the whole corpus
- **Conclusion**: No decomposition. Single discovery pass with explicit user gate before mutation.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 success criteria met. 68 entries classified; recommendations artefact preserved; maintainer approved as-is; post-batch validate clean and round-trip property held; net 68 -> 61 entries (measurable shrink), plus one entry reduced ~210 lines -> ~17.

## Lessons Learned
Estimate of 1 day held. R1 (subjective discards) mitigated by the approval gate -- maintainer accepted all 68 rows as drafted; no override workflow needed at this corpus size. R3 (merge nuance loss) mitigated successfully by listed carry-over phrases (3 merges, 3 phrases each, all grep-traceable in survivors). Decomposition check held: a single coherent review pass was the right shape for this corpus.
