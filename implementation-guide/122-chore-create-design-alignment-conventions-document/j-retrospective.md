# Create Design-Alignment Conventions Document - Retrospective
**Task**: 122 (chore)

## Task Reference
- **Task ID**: internal-122
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/122-create-design-alignment-conventions-document
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-02

## Executive Summary
- **Duration**: <0.5 day, single session (estimated: <1 day; variance ~0%)
- **Scope**: As planned. Five-topic convention doc + CLAUDE.md/BACKLOG.md/CHANGELOG.md wiring. No additions, no removals.
- **Outcome**: Successful. New `docs/conventions/design-alignment.md` shipped (168 lines), 10/10 functional + 3/3 non-functional checks PASS, `cwf-manage validate` clean, BACKLOG entry closed.

## Variance Analysis
### Time and Effort
- **Estimated**: <1 day total (no per-phase split for chore tasks)
- **Actual**: ~1 session, well under estimate
- **Variance**: ~0%. Pure-doc tasks with concrete prior failures to draw on tend to estimate accurately.

### Scope Changes
- **Additions**: None.
- **Removals**: Glossary entry for "design alignment" — deliberately omitted, not deferred. Reason: the term is the doc's title, not a term used in skill/doc prose elsewhere; an entry would duplicate the doc's first paragraph. Recorded in f-implementation-exec.md§Step 4 and verified in g-testing-exec.md TC-10.
- **Impact**: None.

### Quality Metrics
- **Test Coverage**: 10/10 functional + 3/3 non-functional PASS
- **Defect Rate**: 0
- **Performance**: N/A (documentation task)

## What Went Well
- **Plan-review subagents earned their cost**: three findings (helper `<name>.d/` subdirs, version-suffix scope, `cwf-manage` external contract) were load-bearing — the doc would have been incomplete without them. The map-reduce pattern caught all three before drafting started.
- **Reference-surface inventory was data-driven, not guessed**: the audit checklist prescribes the same `git ls-files | grep | xargs grep` that produced the inventory, so future renames inherit the inventory rather than re-discovering it. This dodges the most common rename failure (missed surfaces).
- **Mid-task user feedback on `find`/`sed` was applied immediately**: an earlier plan-review subagent had suggested `find -type l` for the symlink audit; replaced with `cwf-manage validate` (which already enforces symlink integrity) before any code was written. Memory updated so this carries to future sessions.
- **Honest "I can't find that decision" response** when the user asked about the "survey" rename — rather than fabricating a memory or commit, said so. The user accepted and moved on. Cost of honesty: zero. Cost of confabulation: trust erosion.

## What Could Be Improved
- **Doc came in over the 80–150 line target** (168 lines). Not a real defect — the helper inventory is genuinely denser than the perl-git-paths.md reference doc — but the target was set in the plan and missed. Either the target should have flexed during d-implementation-plan or the inventory should be split into an appendix. For a 168-line doc this is academic; flagging for self-awareness only.
- **The "survey" check-in revealed that I used a word the user thought we'd retired** without a record to back it. There may be a not-yet-saved preference. Worth noting that "inventory" / "audit" describe these activities more precisely anyway, and the new convention doc itself uses "audit" not "survey".
- **TC-3's permissive interpretation** (one match for `.claude/commands/` allowed because it's in `## Why` describing Task 35) could mask real regressions in a future doc. A stricter version would scope the grep to `## Convention` only. Not material here, but worth keeping in mind for any future "no stale references" check.

## Key Learnings
### Technical Insights
- The right level for a rename audit checklist is "the grep that produces the list", not "the list". Listing surfaces inline freezes them; prescribing the grep stays correct as the repo grows. `git ls-files | grep -v ^implementation-guide/ | xargs grep -l '<name>'` is the canonical form for CWF.
- `cwf-manage validate` already covers what `find -type l ... -exec test -e` would have done for symlink integrity, plus sha256 and recorded-perm checks. Reaching for `find` was a habit, not a need.
- The asymmetry between in-repo renames (no deprecation) and `cwf-manage` renames (one-minor alias) is real and worth documenting — not because it's complex, but because the asymmetry is exactly the kind of thing that gets forgotten and then breaks installed copies silently.

### Process Learnings
- Plan-review subagents are most valuable when the work is *small enough that reviewers can hold it all in mind*. For a 1-doc task, all three subagents read the entire plan and the entire codebase region; findings were specific and actionable. For larger tasks, findings tend to be partial.
- The mid-task user feedback on `find`/`sed` is now memory; the next session won't need the correction. This is the right granularity for memory — not "rules for this task" but "rules that survive across sessions".
- Honest "no record" beats inventing one. A confabulated "yes you're right we removed it" would have shipped wrong language without anyone catching it.

### Risk Mitigation Strategies
- The two highest-priority risks identified in a-task-plan.md ("drift from reality" and "convention vs aspiration") were both mitigated by (a) inventorying actual code before drafting and (b) checking each convention against current behaviour. Neither risk materialised.

## Recommendations
### Process Improvements
- None new. The existing "inventory before drafting" pattern (already implicit in d-implementation-plan templates) worked exactly as designed.

### Tool and Technique Recommendations
- Worth surfacing `git ls-files | grep -v ^implementation-guide/ | xargs grep -l <name>` as the canonical CWF grep idiom. The new convention doc does this for renames; a future task could lift it into a small helper script if it gets used in 3+ contexts (Rule of Three).

### Future Work
- None. The convention doc closes the BACKLOG entry it was created for; no follow-ups identified during this task.

## Status
**Status**: Finished
**Next Action**: Squash to task branch, suggest merge to user
**Blockers**: None identified
**Completion Date**: 2026-05-02
**Sign-off**: Matt Keenan (with Claude Opus 4.7)

## Archived Materials
- a-task-plan.md, d-implementation-plan.md, e-testing-plan.md, f-implementation-exec.md, g-testing-exec.md (all in this task directory)
- New doc: `docs/conventions/design-alignment.md`
- Wiring edits: `CLAUDE.md` (§Conventions bullet), `BACKLOG.md` (completion marker), `CHANGELOG.md` (Task 122 entry)
- Checkpoint commits: 124b4a7 (a), 16ecc0e (d), 419db9f (e), 6105785 (f), af5a08d (g)
