# Split workflow-steps into per-anchor docs - Plan
**Task**: 176 (chore)

## Task Reference
- **Task ID**: internal-176
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/176-split-workflow-steps-into-per-anchor-docs
- **Baseline Commit**: 91d0b4cabf75e93e517de57a5c9f8c486f79ae65
- **Template Version**: 2.1

## Goal
Split the monolithic `.cwf/docs/workflow/workflow-steps.md` into per-anchor
`workflow-steps/{anchor}.md` documents so a skill can fetch its phase guidance with a
single `Read` of a single file — eliminating the `sed`/`awk` section-extraction that
trips Claude Code's permission gate and halts skills mid-run.

## Problem & Motivation
Skills reference phase guidance by markdown anchor (`workflow-steps.md#planning`). The
Read tool cannot honour an anchor, so the agent improvises extraction. Every available
path is strictly worse than reading a dedicated file:

| Path | Cost |
|------|------|
| Read whole file + anchor | Read ignores the anchor → pulls all ~460 lines = wasted tokens |
| `sed`/`awk` slice | **Permission prompt halts the skill** mid-run |
| `grep` line range → Read with offset/limit | Two tool calls (extra round-trip + latency) + tokens to find the boundary |
| **Read `workflow-steps/{anchor}.md`** | One call, exactly the needed bytes, no prompt |

Per-anchor files collapse all four options into the last: fewer tool calls, fewer
tokens, no permission halt.

## Success Criteria
- [ ] Each skill-referenced phase section exists as `.cwf/docs/workflow/workflow-steps/{anchor}.md`, content-identical to its former section (verified by diff), with an up-link to `../workflow-steps.md`.
- [ ] All 8 skill references point to `workflow-steps/{anchor}.md` (plain path, no `#anchor`); fetching any phase's guidance is a single `Read` with no shell command and no over-read.
- [ ] `workflow-steps.md` is rewritten as a table of contents linking down to each anchor doc.
- [ ] `git grep` finds no dangling reference to a removed `#anchor`; BACKLOG.md/CHANGELOG.md history is left untouched.
- [ ] The `#status-values` references (12 live: 10 templates + glossary + workflow-preamble) remain valid under the chosen handling.

## Original Estimate
**Effort**: ~0.5 day
**Complexity**: Low (mechanical content move + reference updates; many touchpoints, single concern)
**Dependencies**: None

## Major Milestones
1. **Design the mapping**: Decide section→file mapping (incl. anchor mismatches and exec sections), and status-values / version-differences handling.
2. **Split**: Create `workflow-steps/{anchor}.md` files from the existing sections, each with an up-link.
3. **Re-point references**: Update the 8 skill references to the new paths.
4. **ToC rewrite**: Reduce `workflow-steps.md` to a table of contents.
5. **Verify**: `git grep` sweep for dangling anchors + per-file content diff.

## Risk Assessment
### High Priority Risks
- **Anchor/filename mismatch**: The file's headers are `## Implementation Planning` / `## Testing Planning` (anchors `#implementation-planning` / `#testing-planning`), but `cwf-implementation-plan` / `cwf-testing-plan` reference `#implementation` / `#testing` — anchors that already don't resolve. There are 10 phase sections but only 8 are skill-referenced (exec sections aren't). Mis-mapping would point a skill at the wrong content.
  - **Mitigation**: Produce an explicit section→file mapping table in `d-implementation-plan.md`; confirm each plan skill maps to its *planning* content, not execution.

### Medium Priority Risks
- **Dangling/forgotten references**: `#status-values` has 12 live references outside the skills (templates + glossary + workflow-preamble); `checkpoint-commit.md` references the whole file (no anchor).
  - **Mitigation**: Treat status-values handling as an explicit design decision (split + update 12 refs, vs. keep inline in the ToC so `#status-values` still resolves). `git grep` sweep is an acceptance gate. Whole-file ref is satisfied by the ToC and stays as-is.
- **Content drift during the move**: Accidental edits while relocating prose.
  - **Mitigation**: Mechanical extraction; diff each new file against the original section before commit.

## Dependencies
- None external. Self-contained documentation/reference change.

## Constraints
- BACKLOG.md and CHANGELOG.md mention the file as historical record — must not be edited.
- Per-anchor docs must remain self-contained (the point is reading one file, not slicing).
- Follow cross-doc reference convention: intra-repo relative paths (`../workflow-steps.md`).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No (~0.5 day).
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one concern (relocate content + re-point refs).
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Can parts be worked on separately? Parts are sequential, not independent.

**Conclusion**: 0 signals triggered — no decomposition. Proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 success criteria met. 10 per-anchor files created (content verbatim, machine-checked); 8 skill references repointed to single-`Read` paths; `workflow-steps.md` reduced to a ToC; zero dangling references; 12 `#status-values` referrers preserved. On estimate (~0.5 day, one session). 0 decomposition signals confirmed — single task throughout.

## Lessons Learned
The pre-planning `git grep` sweep was what kept this from being under-scoped: the change surface was 8 skills + 12 status-values referrers + a whole-file reference, not just "8 skills". Surfacing that in the plan prevented dangling links.
