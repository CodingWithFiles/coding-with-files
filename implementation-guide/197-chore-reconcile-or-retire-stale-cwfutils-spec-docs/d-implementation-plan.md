# Reconcile or retire stale .cwf/utils spec docs - Implementation Plan
**Task**: 197 (chore)

## Task Reference
- **Task ID**: internal-197
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/197-reconcile-or-retire-stale-cwfutils-spec-docs
- **Template Version**: 2.1

## Goal
Retire the four inert `.cwf/utils/*.md` prototype-era spec docs by deleting them, leaving `CWF-PROJECT-SPEC.md` and the live skills/helpers as the single source of truth.

## Chosen Direction: Retire (delete), not reconcile
Settled here because a chore has no requirements/design phase. Per-file rationale (all four are git-tracked, none hash-tracked, none referenced by any helper/lib/skill/template/test — only an historical `CHANGELOG.md` note mentions them):

| File | Why it is dead | Why not reconcile |
|------|----------------|-------------------|
| `config-loader.md` | Describes pre-Task-189 config (`project.name`, `source-management.url`, `branch-name-max-length`). | `CWF-PROJECT-SPEC.md` is the authoritative config spec; a prose duplicate would re-drift. |
| `template-engine.md` | `{{taskId}}`/`{{taskUrl}}` vars don't match the live `{{baselineCommit}}` substitution; prescribes the retired awk extraction. | Behaviour lives in the `task-workflow` helper + templates. |
| `task-validator.md` | Lists `plan.md`/`requirements.md` filenames (pre-lettered-phase) and old template sets. | Validation lives in `cwf-new-task` + `task-workflow`. |
| `hierarchy-manager.md` | Describes obsolete `implementation-guide/<category>/` dirs and `find\|sed` numbering. | Numbering lives in the hierarchy helper. |

Reconciling would create four hand-maintained prose specs with no consumer — the exact drift that produced this task. "The best part is no part."

## Workflow
Verify-inert → delete → sweep-clean → close-out → commit explains "why"

## Files to Modify
### Primary Changes (delete)
- `.cwf/utils/config-loader.md` — remove (git rm)
- `.cwf/utils/template-engine.md` — remove (git rm)
- `.cwf/utils/task-validator.md` — remove (git rm)
- `.cwf/utils/hierarchy-manager.md` — remove (git rm)
- `.cwf/utils/` — directory disappears once empty (git tracks no empty dirs)

### Supporting Changes (close-out)
- `BACKLOG.md` — two edits:
  - Retire the **originating** item (BACKLOG.md:1459) via `/cwf-backlog-manager` (retire for task 197).
  - Amend the **second, still-open** item (BACKLOG.md:1272, body :1278): drop its now-dead `.cwf/utils/template-engine.md:41` citation, noting the doc was retired in Task 197. The item stays valid — its surviving converge target is `.claude/skills/cwf-extract/SKILL.md:48`. (Found by plan review; deleting the file would otherwise leave a dangling reference in a live backlog item.)
- `CHANGELOG.md` — add a new entry recording the retirement of **all four** files, explicitly including `hierarchy-manager.md` (named in no prior note — prevents a "described three, deleted four" mismatch against the historical note at line 13). Append-only: do **not** rewrite the historical notes at line 13 or line 789, which legitimately record the pre-retirement state.

## Implementation Steps
### Step 1: Re-confirm inert (immediately before deletion)
- [ ] `grep -rn "utils/" --include=*.md --include=*.pl --include=*.pm --include=*.json .` excluding `implementation-guide/` and `.cwf/utils/` itself → expect no functional consumer
- [ ] Widen sweep to each basename (`config-loader`, `template-engine`, `task-validator`, `hierarchy-manager`) to catch references that omit the `utils/` prefix
- [ ] **Known, expected non-consumer hits** (do NOT treat as a STOP): `BACKLOG.md:1459` (originating item, retired in Step 3), `BACKLOG.md:1278` (second item, amended in Step 3), `CHANGELOG.md:13` and `CHANGELOG.md:789` (historical notes, left as-is)
- [ ] STOP only if a *functional* consumer (helper/lib/skill/template/test) surfaces that isn't in the known-hits list above, and revisit direction

### Step 2: Delete
- [ ] `git rm .cwf/utils/config-loader.md .cwf/utils/template-engine.md .cwf/utils/task-validator.md .cwf/utils/hierarchy-manager.md`
- [ ] Confirm `.cwf/utils/` is gone from the worktree (no orphaned empty dir)

### Step 3: Close out
- [ ] Retire BACKLOG.md:1459 via `/cwf-backlog-manager` (retire for task 197)
- [ ] Amend BACKLOG.md:1278: drop the `.cwf/utils/template-engine.md:41` citation (note: retired in Task 197); leave the item open with `SKILL.md:48` as the remaining converge target
- [ ] Add `CHANGELOG.md` entry naming all four removed files (incl. `hierarchy-manager.md`); leave historical notes at lines 13 and 789 untouched

### Step 4: Validate
- [ ] `.cwf/scripts/cwf-manage validate` passes (no sha256/permission drift — none expected, files not hash-tracked)
- [ ] Post-deletion sweep: `git ls-files .cwf/utils/` returns empty

## Code Changes
No code changes — documentation-only deletion. No before/after code applies.

## Test Coverage
**See e-testing-plan.md** — verification is a reference-sweep + `cwf-manage validate`, not a code test.

## Validation Criteria
**See e-testing-plan.md.** Done when: four files removed, sweep clean, `cwf-manage validate` green, backlog/changelog updated.

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
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
