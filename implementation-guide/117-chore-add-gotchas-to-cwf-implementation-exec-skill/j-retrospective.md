# Add gotchas to cwf-implementation-exec skill - Retrospective
**Task**: 117 (chore)

## Task Reference
- **Task ID**: internal-117
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/117-add-gotchas-to-cwf-implementation-exec-skill
- **Template Version**: 2.1
- **Retrospective Date**: 2026-04-29

## Executive Summary
- **Duration**: 1 session (estimated: <1 session — on target)
- **Scope**: Insert a `## Gotchas` section into `cwf-implementation-exec/SKILL.md` containing the two BACKLOG-defined execution-phase gotchas: (1) `git status` before every commit; (2) verify both source and generated output after a rename. Direct follow-up to Tasks 109/110/111 in the gotcha-rollout series.
- **Outcome**: Single-file edit shipped. 8/8 tests pass. Plan review caught two valid content gaps (missing "unstaged" coverage; implicit source-grep ordering) and one valid edge case (pre-existence check). User caught a vague word ("rebrand") and replaced it with "rename or string substitution".

## Variance Analysis
### Scope Changes
- **Additions**:
  - Pre-existence validation criterion (no prior `## Gotchas` section before insertion) — added after plan review flagged the one-shot/non-idempotent edit risk.
  - Explicit "untracked or unstaged" wording in gotcha 1 — added after plan review pointed out the BACKLOG distinction had been lost.
  - Explicit "grep source, then grep output, both required" ordering in gotcha 2 — added after plan review pointed out the BACKLOG ordering had become implicit.
- **Removals**:
  - The word "rebrand" — replaced with "rename or string substitution" after the user pointed out "rebrand" conflates with marketing/product-name changes and risks readers dismissing the gotcha as not applicable to ordinary symbol renames.

### Quality Metrics
- **Test Coverage**: 8/8 manual test cases (2 structural, 2 content, 2 project-neutrality, 2 regression).
- **Defect Rate**: 0 shipped defects. Plan review and user review caught all wording issues before implementation.

## What Went Well
- **Plan review delivered three actionable findings on a 2-gotcha change.** The robustness reviewer in particular pulled gotcha texts apart against the BACKLOG source and noticed the lost "unstaged" coverage and the implicit source-grep ordering. Same shape as Task 111's review — runs are cheap relative to the cost of a wrong gotcha shipping.
- **User wording review caught what plan review missed (again).** "Rebrand" passed all three plan-review subagents and read as fine to me at write time; the user's "what is the exact definition of 'rebrand'?" forced the imprecision into the open. This is the second consecutive task in the gotcha series where user prose review found the highest-value fix after plan review passed (Task 111 had the same pattern).
- **Status sweep was clean.** All 5 prior phases were Finished before retrospective. No stale-status fix needed. Second task in a row with a clean sweep.
- **Project-neutrality held.** Zero "Task NNN" references in the inserted text at any point. Task 110's lesson continues to stick.
- **Eating our own dog food.** Gotcha 1 from this very skill ("`git status` before every checkpoint commit") was used during the f-phase commit of this task — `git status --short` ran before staging and confirmed the SKILL.md was present with the workflow file. Self-validating.
- **Boy-scout extension to checkpoint-commit.md.** Mid-retrospective the user pointed out the gotcha applies one doc-level deeper too: `.cwf/docs/skills/checkpoint-commit.md` is referenced from every phase's checkpoint step, so its "Script (primary method)" section was the right place to land a sibling instruction (run `git status --untracked-files=all` first). One-line addition; same forcing function, broader reach. Caught two backlog over-reaches in the process: a vague-words-audit task (rule-of-three not met — single incident) and a misframed script-level preflight (would have checked, then committed anyway — nonsense).

## What Could Be Improved
- **Plan review still cannot catch vague single words.** "Rebrand" is exactly the kind of word that reads fine to three "is this consistent with the codebase" reviewers but is wrong on its own merits. Task 111's retrospective predicted this would recur for prose-heavy tasks; it did. The lever isn't another reviewer agent — it's user wording review as a routine gate after plan review for any installable-text change.
- **I imported BACKLOG wording too directly on first draft.** The BACKLOG's gotcha 1 said "untracked or unstaged"; my first-draft version dropped "unstaged" while expanding the rationale. Same failure mode as Task 111 (cargo-cult enumeration). The drafter has to read BACKLOG wording with "what specifically does this preserve?" in mind, not just "what's the gist?".

## Key Learnings
### Technical Insights
- **The `## Gotchas` section is now consistent across 4 SKILL.md files** (cwf-design-plan, cwf-implementation-plan, cwf-retrospective, cwf-implementation-exec). The 4-file consistency makes the convention strong enough that future skills should default to including the section even if empty at first.

### Process Learnings
- **For installable-text tasks, treat user wording review as a mandatory gate, not optional.** Two consecutive tasks (111, 117) have had user-caught wording fixes that plan review didn't catch. The cost of asking "want me to read these two sentences out before I edit the file?" is one prompt; the cost of shipping the wrong word is a fix-up commit at minimum.
- **Eat your own dog food at the earliest possible point.** The f-phase commit of this task was the first opportunity to apply gotcha 1 (`git status` before commit). It worked. That's evidence that gotchas drafted from real failures are actionable, not just descriptive.

## Recommendations
### Process Improvements
- **For any future task whose deliverable is text inside an installable SKILL.md or doc, surface the candidate wording to the user before the implementation-exec checkpoint commit.** Plan review covers structure; user review covers prose. Both are needed.
- **When importing wording from BACKLOG, do a token-by-token diff between the source and the draft.** Lost qualifiers ("or unstaged") and lost ordering ("source first") have been the recurring failure mode. A 30-second diff reading would have caught both.

### Future Work
None — gotcha 1 is now in both the SKILL.md and the shared checkpoint-commit doc.
No further mechanism needed; rule of three not yet met for going broader.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-04-29

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**
