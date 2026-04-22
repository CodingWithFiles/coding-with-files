# Add Gotchas to Plan Skills to Prevent Step-Skipping - Retrospective
**Task**: 110 (bugfix)

## Task Reference
- **Task ID**: internal-110
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/110-add-gotchas-to-plan-skills-to-prevent-step-skipping
- **Template Version**: 2.1
- **Retrospective Date**: 2026-04-22

## Executive Summary
- **Duration**: 1 session (estimated: <1 session — on target)
- **Scope**: Started as 3 plan skills + 2 gotchas each. Expanded during /simplify review to also project-neutralise cwf-retrospective SKILL.md (added in Task 109) which had the same project-specific-reference bug.
- **Outcome**: 4 SKILL.md files now project-neutral. 9/9 tests pass. Key discovery: the gotchas from Task 109 had the same bug they were supposed to prevent being ship-ready-in-downstream-projects.

## Variance Analysis
### Scope Changes
- **Additions**:
  - cwf-retrospective SKILL.md project-neutralisation (found via /simplify review)
  - Step 4 added to implementation plan to ensure plan-skill Gotcha 2 is project-neutral (initially had Task 108/109 refs)
- **Removals**: None

### Quality Metrics
- **Test Coverage**: 9/9 manual test cases (3 structural, 3 content, 2 project-neutrality, 1 regression)
- **Defect Rate**: 0 shipped defects; 2 caught by plan review (Gotcha 3 ambiguity from /simplify, Gotcha 2 task refs from user feedback)

## What Went Well
- **Plan review subagents ran this time** — the very thing this task is about. Three parallel Explore agents produced actionable findings on what was nominally a 3-line-per-file change.
- **Status sweep (Gotcha 1 from Task 109) caught stale statuses again** — d and e were "In Progress" at retrospective time. Gotcha working as designed on its second use.
- **/simplify review caught the "Gotcha 3" ambiguity** — the text "Gotcha 3 cited the wrong phase transition" was a reference to Task 109's Gotcha 3, but read as a reference to a non-existent Gotcha 3 in the current file. Subagent caught it, we fixed it.
- **User caught the project-specific task-number bug** — the whole point of installable SKILL.md files is that they ship into other projects. Task numbers are meaningless elsewhere. Applied retroactively to Task 109's work too.

## What Could Be Improved
- **Task 109's gotchas shipped with the same bug**. The gotchas I wrote in Task 109 cited Tasks 65, 67, 81, 84, 98, 103 etc. They were merged to main and would have shipped to every downstream project. This is the exact failure mode we're trying to prevent but in a different dimension: user-facing "skill files" should never contain development-repo-specific references.
- **I proposed skipping the plan review again in this task** — when the user gave "call the plan wf step skills", my instinct was to skip them for a trivial change. The gotcha at the top of the skill (which this task added) would have prevented that had it been in place. The forcing function is working post-hoc.
- **Initial implementation had project-specific task refs** — Gotcha 2 text in the plan skills cited Task 108 and Task 109. These were real Task 110-in-progress artefacts that made it through planning, implementation, and testing. Only caught at /simplify.

## Key Learnings
### Process Learnings
- **"SKILL.md files ship to other projects" is a durable constraint** worth capturing. Any text in an installable SKILL.md that references specific tasks, branches, PRs, commit hashes, or internal task numbers is a bug.
- **Plan review subagents find real bugs even for 3-line changes**. The "Gotcha 3" ambiguity and the Gotcha 3 phase-sequence error (from Task 109) would have shipped without review. The review-to-fix ratio is high.
- **Retroactive bug-fixing across tasks is acceptable when scope creep is the same bug class**. Fixing cwf-retrospective within Task 110 was cleaner than creating Task 111 for a 3-line rewording of the same pattern.

## Recommendations
### Process Improvements
- **Add to MEMORY.md or CLAUDE.md**: installable SKILL.md files must not reference specific task numbers, branches, or internal artefacts. State failure modes and rationale generically.
- **Consider a linter for SKILL.md files** that greps for "Task [0-9]+", commit hashes, and branch-name patterns. Low priority but catches the whole class of bugs.

### Future Work
- **TaskCreate-based forcing function** for skill steps (discussed in Task 109) — still the strongest next lever. Gotchas are working but the agent still needed user prompting to run the review in Task 109.
- **Other Task 107 gotchas remain to be implemented**: cwf-implementation-exec (High), cwf-implementation-plan (Medium, skill-specific: codebase investigation), cwf-design-plan (Medium, skill-specific: assumption verification).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-04-22

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**
