# Remove sed extraction guidance from CWF docs - Implementation Plan
**Task**: 160 (chore)

## Task Reference
- **Task ID**: internal-160
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/160-remove-sed-extraction-guidance-from-cwf-docs
- **Template Version**: 2.1

## Goal
Apply the staged `sed`→grep+read doc edits to `COMMANDS.md` and `DESIGN.md`. The change is already authored in `stash@{0}`; this plan records what it touches and how it is verified.

## Workflow
Apply stash → grep-verify no stale `sed`-extraction strings → full suite green → commit.

## Files to Modify
### Primary Changes
- `COMMANDS.md` (line 89) — delete the `/cwf-extract` `**Method**: Uses sed -n '…/p' | head -n -1` line. The doc line is stale regardless of mechanism (the `/cwf-extract` skill no longer uses `sed`); deleting it removes the only `sed`-extraction reference in this file.
- `DESIGN.md` (lines 13, 117) — (1) success criterion: `extract specific sections using sed commands` → `using grep and read tools`; (2) **Section Extraction Commands** block: replace the `sed -n '…/p'` fenced command with two bullets (grep for `^## {section name}` to get line numbers, then read with offset/limit).

### Supporting Changes
- None. Neither file is hash-tracked → no `script-hashes.json` refresh. No tests reference these doc strings.

### Convention note (plan review, in scope decision)
The canonical extraction mechanism elsewhere in the repo is an `awk` one-liner (`.claude/skills/cwf-extract/SKILL.md:48`, `.cwf/utils/template-engine.md:41`) — *not* `sed` and *not* grep+read. The original `sed` guidance in these two docs was already divergent from that. This task replaces `sed` with grep+read (the user's authored stash, matching the project's no-sed-line-range-reads tool preference), which is the intended user-facing direction. Aligning the skill/template-engine `awk` references to the same grep+read story is **deliberately out of scope** here (the user scoped this task to the stashed docs); flagged as a candidate follow-up backlog item rather than silently expanding scope.

## Implementation Steps
### Step 1: Apply the staged change
- [ ] `git stash apply stash@{0}` (do not drop yet — keep until verified)
- [ ] Confirm only `COMMANDS.md` and `DESIGN.md` are modified

### Step 2: Verify (discriminating, not substring)
A bare `grep sed` matches `based`/`used`/`standardised`/`optimised` and can never be empty — use the command pattern instead:
- [ ] `grep -nE 'sed -n|sed commands' COMMANDS.md DESIGN.md` → **zero matches** (the `sed`-extraction lines are gone)
- [ ] `grep -n 'grep and read tools' DESIGN.md` and `grep -n 'offset and limit' DESIGN.md` → **each matches** (the replacement guidance landed)
- [ ] `prove -lr t/` green (no regression — docs-only, expected unaffected)

### Step 3: Commit + housekeeping
- [ ] Checkpoint commit (f-phase) stages `COMMANDS.md`, `DESIGN.md`
- [ ] Before dropping: confirm `git stash list` still shows the "Task 159 follow-up: sed→grep+read" message at `stash@{0}` (a `stash@{1}` exists; the index is positional). Drop by verified identity, not blindly by bare index.

### Step 1 failure path
- [ ] If `git stash apply` conflicts (files drifted since the stash), **abort and reconcile by hand** — re-create the three edits directly (COMMANDS.md:89 delete; DESIGN.md:13 + :117). Do not force the apply.

## Test Coverage
**See e-testing-plan.md for complete test plan** — verification is grep-based (absence of stale strings) plus a full-suite regression run; there is no executable assertion over doc prose.

## Validation Criteria
**See e-testing-plan.md** — acceptance is: zero `sed`-extraction references in either file, grep+read guidance present in `DESIGN.md`, suite green.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Plan executed exactly: stash applied cleanly (no conflict), discriminating verification passed, stash dropped by verified identity. Detail in f-implementation-exec.md.

## Lessons Learned
Plan review revised this plan three times before exec — false "skill uses grep+read" rationale (it uses awk), an unverifiable `grep sed` check, and a missing stash-drop identity guard. All cheaper to fix at plan time than after. See j-retrospective.md.
