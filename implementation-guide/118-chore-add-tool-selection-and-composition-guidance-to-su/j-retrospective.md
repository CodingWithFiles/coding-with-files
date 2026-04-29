# Add Tool Selection and Composition Guidance to Subagent Instructions - Retrospective
**Task**: 118 (chore)

## Task Reference
- **Task ID**: internal-118
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/118-add-tool-selection-and-composition-guidance-to-su
- **Template Version**: 2.1
- **Retrospective Date**: 2026-04-29

## Executive Summary
- **Duration**: ~1 session (estimated: ~2 hours; actual: ~2 hours including 2 plan revisions and a `/simplify` pass)
- **Scope**: Inline tool-selection rubric in the plan-review subagent prompt + canonical convention doc at `.cwf/docs/conventions/subagent-tool-selection.md`. Final scope matched the user's original instruction ("put this in the instructions to the sub agent") plus the explicit refinement ("having the conventions docs is GOOD but that doesn't mean we don't ALSO include a brief instruction with a reference").
- **Outcome**: Success. Both surfaces in place. Convention doc structure aligned with `docs/conventions/perl-git-paths.md`. All 10 functional + 3 non-functional tests PASS.

## Variance Analysis
### Time and Effort
- **Estimated**: ~2 hours (Original Estimate in a-task-plan.md)
- **Actual**: ~2 hours
  - Planning (a, d, e): ~45 min including one plan-review subagent round and two follow-up plan revisions after user corrections
  - Implementation (f): ~15 min
  - Testing (g): ~15 min including one mid-test fix (NFR-2 cross-reference)
  - `/simplify` pass: ~15 min including a structural refactor of the convention doc
  - Retrospective (j): ~10 min
- **Variance**: On budget overall. The two plan revisions consumed time that could have been saved by reading the user's original instruction more carefully on the first pass.

### Scope Changes
- **Additions**:
  - "Last resort" tier 5 (`find … -exec`, pipelines, `xargs`) — added during planning at user request
  - Convention doc structural refactor (`## Convention` / `## Why` / `## Existing usage` sections) — added during `/simplify` after user pointed out that top-level convention docs serve both humans and agents
  - `workflow-preamble.md#step-4` cross-reference — added during testing-exec (NFR-2 fix)
- **Removals**:
  - "Convention doc only" approach (no inline) — proposed in plan revision 1, rejected by user
  - "Inline only" approach (no convention doc) — proposed in plan revision 2, rejected by user

### Quality Metrics
- **Test Coverage**: 10/10 functional, 3/3 non-functional. NFR-3 prompt-growth budget: 9 lines actual vs ≤8 budget (1 line over, accepted).
- **Defect Rate**: 0 bugs found in testing. One mid-test fix for missing cross-reference (deviation from plan, not a defect).
- **Performance**: N/A (documentation-only change).

## What Went Well
- **Plan-review subagent caught the critical design flaw early**: the Robustness review on the first d-plan caught that mentioning Bash in the inline rubric contradicted the existing "Read, Grep, Glob only" restriction. Without that catch, the implementation would have shipped contradictory guidance.
- **The decomposition check correctly stayed at "no subtasks"**: this was a unitary chore, and the workflow respected that.
- **`/simplify` pass produced one genuinely useful change**: alignment with the existing `perl-git-paths.md` convention structure was a real win that wouldn't have been caught without the explicit review pass.
- **Empirical observation drove the design**: the user's note that subagents in this very task reached for `sed`/`find -exec` (despite a soft prompt restriction) was the deciding evidence that the rubric had to be inline, not linked. Better than abstract reasoning.

## What Could Be Improved
- **I drifted from the user's clear initial direction**: the user's first instruction was unambiguous — "put this in the instructions to the sub agent". I introduced a separate convention doc as a structural improvement, then later wandered to "inline only", before being told both/and was the right answer. Each detour cost a plan revision. The user explicitly said "i already knew this, this is why i said that explicitly" when correcting one of my detours.
- **My assumption about subagent compliance was wrong, and unexamined**: I wrote "Subagents apply only the tiers their tool grant allows" in the plan as if the prompt's "may only use" line were enforced. The user pointed out that the very subagents I had just dispatched ignored that line. I should have noticed this empirically before writing the assumption into the plan.
- **Sloppy audience reasoning**: I dismissed the `/simplify` agent's structural-mismatch finding by claiming top-level `docs/conventions/` was "for CWF developers". The user correctly pointed out that all CWF docs serve both humans and agents — agentic software development means agents read the docs too. This was a careless distinction that obscured a real alignment opportunity.
- **Plan-review wasn't re-run after the major plan revision**: when the d-plan changed from "convention-doc-only" → "inline-only" → "both", I committed each revision without re-dispatching the 3 review subagents. The first review caught the Bash contradiction; later revisions could have benefited from a similar check. Acceptable given the user was reviewing manually, but worth noting.

## Key Learnings
### Technical Insights
- **Soft tool restrictions in subagent prompts are not enforced**: Explore subagents have Bash available regardless of what the prompt says. Telling them "may only use Read, Grep, Glob" is advisory; they will still reach for `sed`/`find -exec` if the rubric isn't visible at decision time. Implication: any tool-availability claim in a subagent prompt must be backed by inline behavioural guidance, not the restriction line alone.
- **Both surfaces (canonical doc + brief inline) is the right pattern for prompt-embedded guidance**: the inline excerpt is what the subagent reads at decision time; the canonical doc is what humans and future skills reference. Neither replaces the other.
- **CWF doc audiences are bimodal**: human readers and agent readers consume the same files, with the same standards. The structural conventions of `docs/conventions/perl-git-paths.md` (Convention / Why / Existing usage) work for both.

### Process Learnings
- **Trust the user's initial framing**: when a user phrases an instruction with structural choices ("put this in X"), they have usually already considered the alternatives. Re-deriving the design from scratch and proposing alternatives wastes their time and mine.
- **Empirical signals in the conversation are evidence**: when the user references behaviour they observed ("the subagents explicitly used `sed -n 'X,Yp'` and `find ... -exec`"), that is data, not opinion. Plans should update against it immediately, not push back.
- **`/simplify` is most useful when applied after a phase has shipped**: the structural refactor wouldn't have been worth the time during planning, but post-impl `/simplify` made it worthwhile.

### Risk Mitigation Strategies
- The plan-review subagent map/reduce is doing real work — at least one of the 3 reviews caught a critical issue on this small chore. The mandatory-step gotcha in the cwf-implementation-plan SKILL.md is justified.

## Recommendations
### Process Improvements
- **Re-run plan-review subagents after material plan revisions**: when a plan changes substantially mid-phase (as d-plan did here, twice), re-dispatch the 3 reviews. The token cost is low and the catch rate is high.
- **Be more deferential to the user's initial framing on small tasks**: for chores phrased as a single sentence, the user's framing is usually the design. Reach for an alternative only when there's a concrete reason the framing won't work.

### Tool and Technique Recommendations
- The `perl-git-paths.md` structure (Convention / Why / Existing usage) is a good template for any new doc in `.cwf/docs/conventions/` going forward — apply this in future convention docs without re-deriving.

### Future Work
- **Audit other CWF subagent prompts (none currently exist)**: as new subagent invocation sites are added, ensure they reference or inline the rubric. Captured in `.cwf/docs/conventions/subagent-tool-selection.md` "Existing usage" section.
- **Consider a similar inline rubric for the parent agent** (Claude Code itself): the same anti-patterns apply when the parent reaches for `sed`/`find -exec`. Could become a separate task that adds the rubric to CLAUDE.md or similar.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None
**Completion Date**: 2026-04-29
**Sign-off**: Matt Keenan + Claude Opus 4.7

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`
- Execution: `f-implementation-exec.md`, `g-testing-exec.md`
- Source-of-truth changes: `.cwf/docs/conventions/subagent-tool-selection.md` (new), `.cwf/docs/skills/plan-review.md` (modified)
- Commits: `b864d3d` (a-plan), `9417f0e` (d-plan), `782bf55` (e-plan), `7ba80e4` (plan revisions: both surfaces), `660dd58` (f-impl-exec), `f43c413` (g-testing-exec), `5e41796` (`/simplify` — structural alignment + wording sync)
