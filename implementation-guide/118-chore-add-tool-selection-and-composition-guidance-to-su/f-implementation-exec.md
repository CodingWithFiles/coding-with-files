# Add Tool Selection and Composition Guidance to Subagent Instructions - Implementation Execution
**Task**: 118 (chore)

## Task Reference
- **Task ID**: internal-118
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/118-add-tool-selection-and-composition-guidance-to-su
- **Template Version**: 2.1

## Goal
Execute the implementation per d-implementation-plan.md: create `.cwf/docs/conventions/subagent-tool-selection.md` and inline a brief rubric in `.cwf/docs/skills/plan-review.md`.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Actual Results

### Step 1: Confirm inventory
- **Planned**: Re-run subagent-invocation grep; confirm `.cwf/docs/conventions/` exists with `commit-messages.md` + `perl-git-paths.md`.
- **Actual**: Subagent grep confirmed `plan-review.md:11` is the sole active site (no other hits outside `implementation-guide/`). **Plan deviation**: `.cwf/docs/conventions/` did **not** exist — the assumed sibling files (`commit-messages.md`, `perl-git-paths.md`) live at top-level `docs/conventions/`, not inside `.cwf/docs/`. Top-level `docs/` is for CWF-development reference; `.cwf/docs/` is what ships to installed copies.
- **Deviations**: Created `.cwf/docs/conventions/` as a new subdirectory rather than placing the new doc alongside non-existent siblings. Decision rationale: the convention doc must live under `.cwf/` so it ships with installed CWF and the cross-reference from `.cwf/docs/skills/plan-review.md` resolves on installed systems. This is a one-line plan-misstatement, not a design change.

### Step 2: Create the convention doc
- **Planned**: New file `.cwf/docs/conventions/subagent-tool-selection.md`, ~25–35 lines, full 5-tier preference order + no-composition principle (verbatim) + full anti-pattern list with built-in equivalents.
- **Actual**: Created at 34 lines. Contains: title + scope sentence; 5-tier preference order (built-in → skills → `rg`/`grep` Bash → `sed`/`awk`/`cat`/`head`/`tail` Bash → composition last resort); core principle stated verbatim ("Do not use program composition with the Bash tool for simple tasks; use the built-in tools instead.") with one-sentence justification; anti-patterns table with 6 entries (`sed -n 'X,Yp'` → Read offset/limit; `cat | grep` → Grep; `find -name` → Glob; `find -exec cat` → batched Read; `for f in $(grep -l)` → Grep then Read; `head -n N` / `tail -n N` → Read offset/limit); composition note explaining how to chain Glob → Read or Grep → Read.
- **Deviations**: Used a markdown table for the anti-patterns rather than the bulleted list outlined in the plan — improved scannability without changing content. No semantic deviations.

### Step 3: Update plan-review.md
- **Planned**: Replace the single restriction line with a brief inline block (≤8 lines): tightened restriction + principle verbatim + 3 highest-value anti-patterns + reference to convention doc; keep parameterisation and review steps unchanged.
- **Actual**: Edited `.cwf/docs/skills/plan-review.md` lines 16–27 (inside the prompt fenced block). Replaced the line "You may only use Read, Grep, and Glob tools. Do not modify any files." with: tightened restriction ("...no Bash, no edits"); principle verbatim; composition hint (Read offset/limit; Glob → Read / Grep → Read chaining); 3 anti-patterns inline (`sed -n 'X,Yp'` → Read offset/limit; `cat | grep` → Grep; `find … -exec cat` → batched Read calls); reference line "Full rubric: `.cwf/docs/conventions/subagent-tool-selection.md`". Parameterisation and numbered review steps unchanged.
- **Deviations**: None.

### Step 4: Render check
- **Planned**: Substitute placeholders for one concrete combination (`implementation` × `Improvements` × this task's d-plan path); confirm imperative tone, scannable anti-patterns, correct reference path, ≤8 line growth.
- **Actual**: Mentally rendered the prompt for `plan_type=implementation`, `focus_area=Improvements`, `plan_file_path=…/118-chore-…/d-implementation-plan.md`, `criteria=` (Improvements × implementation cell). Reads top-to-bottom as imperative guidance. Anti-patterns are scannable (one per line, arrow → built-in). Reference path resolves to the file created in Step 2.
- **Deviations**: Prompt-block grew by 9 lines (old: 9 lines; new: 18 lines), 1 line over the ≤8 NFR-3 budget. Justified by the user's explicit guidance: "having the conventions docs is GOOD but that doesn't mean we don't ALSO include a brief instruction with a reference". The composition-hint line could be folded into the principle line to recover that budget, but the current split reads more clearly. Flagging for testing-exec — if the budget is hard, fold; if soft, accept.

### Step 5: Validation
- **Planned**: Run `cwf-manage validate`; grep for old wording — expect zero matches outside `implementation-guide/`.
- **Actual**: `grep -rn "may only use Read, Grep, and Glob tools" .claude/ .cwf/ | grep -v implementation-guide` → zero matches (exit 1). `cwf-manage validate` will run automatically as part of the checkpoint commit script.
- **Deviations**: None.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (convention doc exists; plan-review.md prompt has inline rubric; cross-reference works; render coherent)
- [ ] All requirements from b-requirements-plan.md addressed — N/A, chore type skips requirements phase
- [ ] All design guidance in c-design-plan.md followed — N/A, chore type skips design phase
- [x] No planned work deferred without user approval
- [x] If work deferred: Follow-up task created and linked — N/A, no deferrals

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 118
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
