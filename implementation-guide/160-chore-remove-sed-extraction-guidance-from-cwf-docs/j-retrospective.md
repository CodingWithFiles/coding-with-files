# Remove sed extraction guidance from CWF docs - Retrospective
**Task**: 160 (chore)

## Task Reference
- **Task ID**: internal-160
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/160-remove-sed-extraction-guidance-from-cwf-docs
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-24

## Executive Summary
- **Duration**: ~1 short session on 2026-05-24 (estimated <0.5 day; on estimate).
- **Scope**: Applied the session-stashed `sed`→grep+read doc edits to `COMMANDS.md` and `DESIGN.md`. No scope change; the skill/template-engine `awk` alignment was deliberately kept out and filed as a follow-up.
- **Outcome**: Success. Both files now describe section extraction via grep+read tools (matching the project's no-sed-line-range-reads preference); full suite green, validate clean.

## Variance Analysis
### Time and Effort
- **Estimated**: <0.5 day, Low complexity, change pre-authored in `stash@{0}`.
- **Actual**: One short session across the chore phases (a, d, e, f, g, j). The implementation itself was a clean `git stash apply`.
- **Variance**: On estimate. The only non-trivial work was process, not content — the plan-review pass (below) added the most value.

### Scope Changes
- **Additions**: None to the code change.
- **Removals**: None — the awk-alignment of `.claude/skills/cwf-extract/SKILL.md:48` and `.cwf/utils/template-engine.md:41` was *never in scope*; it was surfaced by plan review and filed as a new backlog item rather than absorbed here.
- **Impact**: Scope held to exactly the stashed two-file edit.

### Quality Metrics
- **Test Coverage**: TC-1..TC-4 (grep-based content checks) all PASS; both edited files fully covered. No code-coverage dimension (docs-only).
- **Defect Rate**: Zero. The plan-review pass caught three *plan* defects pre-implementation (see below); the implementation itself had no rework.
- **Regression**: `prove -lr t/` 48 files / 527 tests green; `cwf-manage validate` OK.

## What Went Well
- **Plan review earned its keep on a "trivial" task.** Four reviewers independently caught that the plan's rationale was factually wrong ("the skill uses grep+read internally" — it uses `awk`), that the verification grep (`grep sed`) could never pass because it matches `based`/`used`/`standardised`, and that the plan deferred acceptance to an empty template. All three were fixed before any file was touched.
- **Discriminating verification.** Switching to `grep -nE 'sed -n|sed commands'` plus positive assertions for the replacement strings made the acceptance check falsifiable rather than an eyeball scan.
- **Stash hygiene.** Applying (not popping) and dropping only after a verified-identity check protected the unrelated `stash@{1}` (WIP on main) from a positional-index mistake.

## What Could Be Improved
- **The plan shipped a false premise about existing code.** The "skill already uses grep+read" claim was an assumption, not a checked fact — exactly the "measure twice" gotcha. A 10-second grep of the skill before writing the rationale would have avoided it. Caught by review, but it should not have been written.

## Key Learnings
### Technical Insights
- **The repo describes section extraction three ways**: `awk` (the actual `/cwf-extract` skill + `template-engine.md`), and now grep+read (the two user-facing docs). This task aligned the docs to the user's tool preference but did not unify the mechanism — a real, if low-priority, inconsistency now explicitly tracked.

### Process Learnings
- **"Trivial" tasks still benefit from the full gate.** The temptation on a two-line doc edit is to skip plan review; doing it anyway caught a verification step that would have silently passed on nothing. The quality gate is cheapest exactly when the task looks too small to need it.

### Risk Mitigation Strategies
- **Verify identity before any positional `git stash drop`.** With more than one stash present, the bare index is ambiguous; confirming the message first is the cheap guard.

## Recommendations
### Process Improvements
- When a plan cites the behaviour of existing code as justification, grep/read that code in the same step — do not assert it from memory.

### Tool and Technique Recommendations
- Prefer `grep -E '<command pattern>'` over a bare keyword when verifying string *removal*; a keyword that is also a common English substring can never verify absence.

### Future Work
- **Align `/cwf-extract` skill + template-engine extraction guidance to grep+read** (new BACKLOG item, Low): `.claude/skills/cwf-extract/SKILL.md:48` and `.cwf/utils/template-engine.md:41` still use the `awk` one-liner. Now that the user-facing docs describe grep+read, the implementing skill and its design doc diverge from them. Decide whether to converge the skill on grep+read (matching the docs and the no-sed tool preference) or to re-document the docs back to `awk` — and apply consistently.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-24
**Sign-off**: Task maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, d-implementation-plan.md, e-testing-plan.md
- Execution: f-implementation-exec.md, g-testing-exec.md
- Edited docs: COMMANDS.md (line 89 removed), DESIGN.md (lines 13, 117)
- Commits: b3a632f(a) e9c2c7f(d) b1732dc(e) 953b427(f) 79111e3(g)
