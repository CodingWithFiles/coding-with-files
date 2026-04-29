# Reject Overlong Task Slugs - Plan
**Task**: 119 (feature)

## Task Reference
- **Task ID**: internal-119
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/119-reject-overlong-task-slugs
- **Template Version**: 2.1

## Goal
Replace the silent 50-char truncation in CWF's slug generation with a hard error that aborts task creation and tells the user to use a shorter description, so branch names and `implementation-guide/` directory names always match the task description verbatim instead of mid-word stubs like `…silent-truncati`.

## Success Criteria
- [ ] Slug-generation paths used by `/cwf-new-task` and `/cwf-new-subtask` exit non-zero when the slugified description exceeds the configured length limit
- [ ] Error message names the limit and the actual length, and tells the user what to do (e.g. "Slug 'foo-bar-baz' is 56 characters; limit is 50. Use a briefer task description (≤ N words)")
- [ ] No silent truncation remains: the substring/truncate operation is removed, not just guarded
- [ ] The user-visible failure is identical regardless of which surface generates the slug (`task-workflow create` script vs the skill's LLM-side slugification)
- [ ] Existing tasks with already-truncated slugs continue to work unchanged (no retroactive rename, no validation gate on existing dirs)

## Original Estimate
**Effort**: ~2-3 hours
**Complexity**: Low
**Dependencies**: None — touches one helper script + skill docs + tests

## Major Milestones
1. **Inventory**: Locate every slug-generation site and decide whether the limit lives in the script, the skill, or both
2. **Implement**: Replace `substr(..., 0, 50)` in `template-copier-v2.1`'s `generate_slug` with a length check + error exit; update SKILL.md guidance for `cwf-new-task` and `cwf-new-subtask` so the LLM stops pre-truncating
3. **Test**: Unit-test `generate_slug` with under/at/over-limit inputs; manually verify the user-visible error from `/cwf-new-task` on an overlong description
4. **Migration note**: Document in CHANGELOG that overlong descriptions now error out (was: silently truncate)

## Risk Assessment

### Medium Priority Risks
- **The skill's LLM-side slug generation could mask the script's error**: the cwf-new-task SKILL.md tells the LLM to "truncate 50 chars" before calling `task-workflow create --destination=...`. If the LLM pre-truncates, the script never sees the overlong input and the error never fires.
  - **Mitigation**: Update SKILL.md to tell the LLM **not** to truncate — pass the full slug, let the script reject. Confirm with a smoke-test invocation that an overlong description hits the error rather than getting silently shortened by the LLM.
- **Two template-copier versions exist** (v2.0 and v2.1): need to confirm which is still wired up and avoid leaving a silent-truncation hole in the legacy path.
  - **Mitigation**: Grep for callers of each version during the inventory milestone; only fix actively-wired paths; if v2.0 is still wired anywhere, fix both.

### Low Priority Risks
- **Limit value is arbitrary**: 50 chars is a stylistic choice (terminal width, branch-name readability), not a filesystem limit. The user might want a different number, or want it configurable.
  - **Mitigation**: Surface this in requirements/design — keep the existing 50 unless there's a reason to change. Make the limit a named constant in the script for easy adjustment, but don't add config plumbing in this task.

## Dependencies
- Existing slug-generation logic at `.cwf/scripts/command-helpers/template-copier-v2.1:152` (`generate_slug` function, `substr(..., 0, 50)` at line 168)
- SKILL.md docs at `.claude/skills/cwf-new-task/SKILL.md` and `.claude/skills/cwf-new-subtask/SKILL.md`
- CWF error-message convention (`die_msg` / `[CWF] error: …` style — confirmed in design phase)
- Existing test harness under `t/` for Perl helper scripts (per Tasks 115/116 patterns)

## Constraints
- The error message must be CWF-prefixed and follow the established pattern from `cwf-manage` (e.g. the `check_clean_tree` error in Task 116)
- Breaking change for users with overly long task descriptions — must land with a CHANGELOG entry that explains the new behaviour and the recovery (use a shorter description)
- No retroactive renaming of existing tasks: this fix applies forward; existing truncated slugs (incl. several in `implementation-guide/`) stay as-is
- This task itself was created with a deliberately short description (`reject-overlong-task-slugs`, 26 chars) to dogfood the new constraint

## Decomposition Check
- [ ] **Time**: <1 day → no decomposition
- [ ] **People**: 1 person → no decomposition
- [ ] **Complexity**: 2 small concerns (script error + skill alignment) → no decomposition
- [ ] **Risk**: low → no decomposition
- [ ] **Independence**: unitary → no decomposition

No signals triggered. Single feature task; proceed without subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 119
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- Delivered as planned: `template-copier-v2.1` rejects descriptions whose slug exceeds 50 chars or normalises to empty; both SKILL.md files updated to drop the truncate instruction; 8 unit tests added; hash refreshed; `cwf-manage validate` clean. 17/17 test cases pass. Original effort estimate (2–3 hours) hit on the lower end.
- Two scope additions (empty-slug rejection; leading/trailing hyphen strip) and one removal (dual destination-basename validation) were absorbed during c-design without timeline impact — all surfaced by plan-review subagents.

## Lessons Learned
See j-retrospective.md.
