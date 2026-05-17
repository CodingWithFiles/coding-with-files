# update cwf skills to use namespaced tmp paths - Retrospective
**Task**: 145 (chore)

## Task Reference
- **Task ID**: internal-145
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/145-update-cwf-skills-to-use-namespaced-tmp-paths
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-17

## Executive Summary
- **Duration**: 1 session, well under the <1-day estimate.
- **Scope**: Originally one new convention doc + cross-references + agent-memory updates. Scope grew during plan review to include (i) a 4th memory file discovered by the grep gate (`project_archaeological_main.md`) and (ii) the orthogonal-but-noisy `cwf-security-reviewer-changeset.md` 0444 perms restoration that was bleeding `cwf-manage validate` warnings into every checkpoint commit.
- **Outcome**: Success. Single source of truth for project-namespaced `/tmp/` scratch paths now exists at `.cwf/docs/conventions/tmp-paths.md` and is discoverable via `CLAUDE.md § Conventions`. `cwf-manage validate` now reports `OK` (zero violations), down from 1 pre-implementation. Both security-review subagent invocations returned `no findings`.

## Variance Analysis
### Time and Effort
- **Estimated**: <1 day total (chore, docs-only, single concern).
- **Actual**: 1 session (well under).
- **Variance**: On target. The plan-review cycle absorbed more time than the implementation itself — three round-trips on the mirror question (no copy → symlink → single file in `.cwf/`) plus the chmod fold-in. Implementation steps were ~5 minutes once the plan was locked.

### Scope Changes
- **Additions**:
  - `cwf-security-reviewer-changeset.md` 0444 restoration folded into Step 6 of d-implementation-plan. Strictly orthogonal to the namespaced-tmp-paths goal but the SHA-pre-verified restoration eliminated noise that would have bled into a follow-up task with no proportionate gain. Plan amendment and TC-NF3 (SHA unchanged) added.
  - `project_archaeological_main.md` memory update — not on the original plan's three-file list. Discovered by the TC-M1 grep gate. The gate is *designed* to catch exactly this kind of plan-list completeness gap; this is a positive validation of the gate, not a plan defect.
- **Removals**: None — the original "mirror in both `docs/conventions/` and `.cwf/docs/conventions/`" intent was reframed (not removed) to "single source under `.cwf/`" after the reviewer-driven re-examination.
- **Impact**: Net positive. Both additions were small, surfaced cleanly, and resolved drift that would otherwise persist.

### Quality Metrics
- **Test Coverage**: 100% of e-testing-plan.md cases executed (TC-1..TC-7, TC-5b, TC-NF1..TC-NF3, TC-M1). All pass.
- **Defect Rate**: Zero. No bugs found in implementation; security review returned `no findings` n=2/2 (f-phase + g-phase).
- **Performance**: N/A (docs change).

## What Went Well
- **Plan-review map/reduce caught the mirror duplication early.** The "no mirror" advice was initially over-applied (would have stranded adopters); user's "are we duplicating? is that the issue?" reframe led to the cleaner "single file under `.cwf/`" outcome. Plan review surfaced the tension; user judgement resolved it.
- **TC-M1 grep gate did its job.** Discovering the 4th memory file (`project_archaeological_main.md`) at the gate instead of post-merge is the exact value proposition of a verification gate — the plan's file list is a starting point, not an oracle.
- **Folding the 0444 restoration in was net-positive.** SHA pre-verification eliminated the integrity-bypass concern; the warning had been firing on every checkpoint commit throughout planning phases; carrying it into a follow-up task would have repeated the noise.
- **Subagent sentinel-line compliance held at n=2/2.** Both security-review invocations led with `no findings` as the literal first non-blank line — the calling SKILL's **primary** classifier fired both times, not the conservative-default fallback. Continues the Task 144 dogfood positive observation.

## What Could Be Improved
- **The plan named three memory files; reality was four.** Without the TC-M1 gate this would have shipped incomplete. The fix isn't bigger upfront plan lists — it's continuing to gate on grep, not on the plan's prose.
- **Initial awk for TC-5 collapsed to one line.** `awk '/^## Conventions/,/^## /'` self-terminates because `/^## /` matches the same line that opens the range. Caught immediately at first PASS-attempt; flag-based awk replaced it. Worth folding into the project's awk-pattern memory if this recurs.
- **First Bash invocation for TC-3 used a heredoc** (empty body, by accident). Drift back to a habit even with explicit `feedback_no_heredocs` memory in place. Caught immediately; Write tool used instead. The memory is correct; the lapse was mine.

## Key Learnings
### Technical Insights
- **`mkdir -m 0700 -p` is atomic and idempotent**: it sets the mode at creation time and is a no-op (mode unchanged) when the directory already exists owned by the caller. Sufficient defence against `/tmp` symlink-attack scenarios on multi-user hosts without a separate stat-check round-trip. This is the threat-model framing in `tmp-paths.md`.
- **Dashified-absolute-path naming has precedent in the user's environment** (`~/.claude/projects/`). Re-using the same shape for `/tmp/` scratch dirs reduces cognitive load — the user already parses the dashified form mentally.
- **`security-review-changeset` CWF-internal-prefix coverage is narrow by design.** This task's 7-file changeset produced a 14-line diff because only `.cwf/docs/skills/security-review.md` falls inside the unconditional-include prefixes. `.cwf/docs/conventions/`, `CLAUDE.md`, `docs/conventions/`, and user-memory files are all outside coverage. Expected behaviour; noted so future reviewers don't wonder why the diff is small relative to the change.

### Process Learnings
- **Grep gates beat plan-list completeness.** The plan's file list is the starting hypothesis; the gate is the arbiter. Future plans should explicitly list the gate, not promise an exhaustive file list.
- **Folding orthogonal hygiene work is net-positive when**: (a) the SHA pre-verifies as a restoration (not new content), (b) the noise has been recurring across phases of the current task, and (c) the alternative is a follow-up task that repeats the same noise.
- **Reviewer-driven advice can over-rotate.** The "no mirror" plan-review feedback was correct *for in-repo conventions* but wrong for *ship-to-adopter conventions*; the user's reframe ("are we duplicating?") restored the correct framing. Worth holding plan-review output to scrutiny when it conflicts with adopter-shipping invariants.

### Risk Mitigation Strategies
- **"Surface security issues, never smooth them" applied correctly.** The 0444 restoration was authorised explicitly by the user after SHA pre-verification confirmed restoration (not new content). No `recompute-hashes`-class smoothing tooling was proposed.

## Recommendations
### Process Improvements
- For convention/rename-class tasks: codify the grep-gate-as-arbiter pattern. The plan should name the gate and accept that the file-list is a starting hypothesis.
- For plan-review map/reduce output: flag advice that conflicts with adopter-shipping invariants (anything that lives only under `docs/` cannot reach adopters via the `.cwf/` subtree install).

### Tool and Technique Recommendations
- The `mkdir -m 0700 -p` idiom is reusable beyond this convention; consider linking from any future doc that prescribes a per-session scratch dir.

### Future Work
- None identified. The convention is single-file, additive, and self-documenting; no follow-up tasks needed.

## Status
**Status**: Finished
**Next Action**: Suggest merge (human action)
**Blockers**: None identified
**Completion Date**: 2026-05-17

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`
- Execution: `f-implementation-exec.md` (`701929a`), `g-testing-exec.md` (`6f8c3cd`)
- Branch: `chore/145-update-cwf-skills-to-use-namespaced-tmp-paths`
- Baseline: `e435162`
- Convention: `.cwf/docs/conventions/tmp-paths.md`
