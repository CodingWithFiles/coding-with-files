# Remove cd to git root from backlog-manager skill - Plan
**Task**: 138 (bugfix)

## Task Reference
- **Task ID**: internal-138
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/138-remove-cd-to-git-root-from-backlog-manager-skill
- **Baseline Commit**: 7500aefb5dac24b40ef9f01da3307afcfe12757e
- **Template Version**: 2.1

## Goal
Remove the `cd "$(git rev-parse --show-toplevel)" && ` prefix from every example and instruction in `.claude/skills/cwf-backlog-manager/SKILL.md` because relative addressing (`.cwf/scripts/command-helpers/backlog-manager`) already enforces "run from git root" via kernel path resolution, making the cd dead weight and the cited threat model moot.

## Success Criteria
- [ ] Zero occurrences of `git rev-parse --show-toplevel` remain in `.claude/skills/cwf-backlog-manager/SKILL.md`
- [ ] Every code-fenced example invokes the helper directly as `.cwf/scripts/command-helpers/backlog-manager <subcommand> ...`
- [ ] The "Mandatory pre-step" paragraph (lines 18-23) and the matching Success-Criterion checkbox (line 95) are removed; no orphaned references to the removed guidance remain
- [ ] The skill still passes `cwf-security-check verify` (no integrity drift outside the intended file)
- [ ] All retained subcommand examples remain executable as-shown when run from the repo root (smoke-tested for `list`, `validate`)

## Original Estimate
**Effort**: <0.5 day
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Edits applied**: `SKILL.md` rewritten with the prefix removed and the threat-model paragraph deleted
2. **Verified**: smoke-tested examples; `cwf-security-check verify` clean
3. **Merged**: squash to main via standard CWF flow

## Risk Assessment
### Medium Priority Risks
- **Risk: orphaned cross-references**: Other docs or skills may quote the "Mandatory pre-step" wording. Removing it could leave dangling references.
  - **Mitigation**: grep the repo for `Mandatory pre-step` and `cd .*git rev-parse --show-toplevel` before finalising; fix or note any hits in the design phase.

### Low Priority Risks
- **Risk: rewording the threat-model paragraph instead of deleting it**: Tempting to keep a "security note" that documents why the cd is *not* needed. Adds noise and tempts future re-introduction.
  - **Mitigation**: Delete outright; the rationale lives in the task's c-design-plan.md and the retrospective, which is sufficient archaeology.

## Dependencies
- None. The change is local to one skill file.

## Constraints
- Skill examples are user-facing reference material; their executable form must remain copy-pasteable from the repo root.
- No change to the helper script itself (`backlog-manager`) is in scope — only the calling convention documented in the skill.

## Decomposition Check
- [ ] **Time**: <0.5 day — no
- [ ] **People**: single-author edit — no
- [ ] **Complexity**: one file, mechanical edits + one paragraph deletion — no
- [ ] **Risk**: low; reversible — no
- [ ] **Independence**: not splittable into useful subparts — no

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 138
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
