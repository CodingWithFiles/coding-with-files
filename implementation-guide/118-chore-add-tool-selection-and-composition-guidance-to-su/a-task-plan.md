# Add Tool Selection and Composition Guidance to Subagent Instructions - Plan
**Task**: 118 (chore)

## Task Reference
- **Task ID**: internal-118
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/118-add-tool-selection-and-composition-guidance-to-su
- **Template Version**: 2.1

## Goal
Add tool selection and composition guidance to CWF subagent prompts so subagents prefer built-in tools (Read/Grep/Glob) over shell substitutes (`sed -n 'X,Yp'`, `cat | grep`, etc.) and use skills where applicable.

## Success Criteria
- [ ] A documented tool preference order is captured in the repo: built-in tools > skills > `rg`/`grep` via Bash > `sed`/`awk`/`cat` shell substitutes
- [ ] Composition guidance is captured: when to use a single tool vs chain tools, and which substitutions are explicitly discouraged (e.g. `sed -n 'X,Yp' file` → `Read file offset=X limit=Y-X+1`)
- [ ] Every CWF-managed subagent prompt (currently the plan-review template at `.cwf/docs/skills/plan-review.md`) references or inlines this guidance
- [ ] A dry render of an updated subagent prompt shows the guidance is present and concise (no significant prompt bloat)

## Original Estimate
**Effort**: ~2 hours
**Complexity**: Low
**Dependencies**: None — touches docs/templates only

## Major Milestones
1. **Inventory**: Locate every subagent invocation point in the repo (skills, helper docs) and confirm `plan-review.md` is the sole shared template
2. **Draft guidance**: Write the tool preference order + composition examples (terse, scannable) and decide whether to inline or link from the prompt template
3. **Wire it in**: Update the prompt template(s) so subagents receive the guidance at invocation time
4. **Sanity check**: Render a sample prompt and confirm the guidance reads cleanly in-context

## Risk Assessment
### Medium Priority Risks
- **Prompt bloat**: Adding guidance lengthens every subagent prompt; verbose advice dilutes the focused review brief.
  - **Mitigation**: Cap the inline guidance at ~5 lines; offload examples to a referenced doc if needed.
- **Missed invocation sites**: Other skills may invoke subagents directly (not via `plan-review.md`).
  - **Mitigation**: Grep for `subagent_type`, `Agent(`, and `Task tool` across `.claude/skills/` and `.cwf/docs/skills/` during the inventory milestone before drafting.

### Low Priority Risks
- **Guidance drift from existing memory rules**: The repo already has feedback memories on `sed` line-ranges and Perl/git conventions; the new guidance could contradict them.
  - **Mitigation**: Cross-reference `feedback_no_sed_line_ranges.md` and `docs/conventions/` and align wording.

## Dependencies
- Existing subagent prompt template: `.cwf/docs/skills/plan-review.md`
- Existing convention docs in `docs/conventions/` for tone/format consistency

## Constraints
- Documentation-only change; no script or skill behaviour changes
- Guidance must remain repo-agnostic enough that it travels with installed CWF copies, not just CWF-on-CWF
- Must not contradict existing feedback memories or `CLAUDE.md` rules

## Decomposition Check
- [ ] **Time**: <1 day → no decomposition
- [ ] **People**: 1 person → no decomposition
- [ ] **Complexity**: single concern (prompt content) → no decomposition
- [ ] **Risk**: low → no decomposition
- [ ] **Independence**: unitary task → no decomposition

No signals triggered. Single chore task; proceed without subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 118
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
