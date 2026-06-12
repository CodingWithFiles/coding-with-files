# specify low effort level for retrospective skill - Plan
**Task**: 198 (chore)

## Task Reference
- **Task ID**: internal-198
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/198-specify-low-effort-level-for-retrospective-skill
- **Baseline Commit**: edbb2e081342643ce2f4b9e792ed52da43b55132
- **Template Version**: 2.1

## Goal
Add `effort: low` to the `cwf-retrospective` SKILL.md frontmatter so the retrospective
phase runs the session-pinned Opus at reduced effort, matching the exec-phase skills.

## Success Criteria
- [ ] `effort: low` present as a top-level key in `.claude/skills/cwf-retrospective/SKILL.md`
      frontmatter (placed after `description:`, mirroring the Task 187 exec-skill layout)
- [ ] Frontmatter remains valid YAML and the skill still parses/invokes
- [ ] `.cwf/scripts/cwf-manage validate` reports `validate: OK` (no integrity regression)

## Original Estimate
**Effort**: <1 hour (single frontmatter line)
**Complexity**: Low
**Dependencies**: None — `cwf-retrospective/SKILL.md` is not hash-tracked (verified)

## Major Milestones
1. **Edit**: Add `effort: low` to the retrospective skill frontmatter
2. **Validate**: Confirm clean `cwf-manage validate` and well-formed YAML

## Risk Assessment
### High Priority Risks
- None. The skill is not hash-tracked, so there is no `script-hashes.json` coupling.

### Medium Priority Risks
- **Harness honour-check gap**: `cwf-manage validate` proves integrity, not that the
  harness actually honours the `effort` key (an unrecognised key would be silently
  ignored). Same Known Limitation as Task 187.
  - **Mitigation**: `effort` is documented for SKILL.md frontmatter
    (`low|medium|high|xhigh|max`); testing phase (e/g) owns the YAML-validity check.

## Dependencies
- Precedent: Task 187 (`effort: low` on the two exec-phase skills). Same pattern, new file.

## Constraints
- Frontmatter-only change; no behavioural logic in the skill body is touched.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: No — single-line edit, well under an hour
- [x] **People**: No — one file, one editor
- [x] **Complexity**: No — one concern (one frontmatter key)
- [x] **Risk**: No — not hash-tracked, no security coupling
- [x] **Independence**: No — atomic change, nothing to split

**Verdict**: 0 signals triggered. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Completed as planned, on estimate (<1 hour). All three success criteria met: `effort: low`
added after `description:`, frontmatter valid YAML, `cwf-manage validate` → OK. 0 decomposition
signals held — atomic single-line change.

## Lessons Learned
A direct precedent (Task 187) made planning near-zero-risk. See j-retrospective.md for the
`allowed-tools:` vs `tools:` distinction surfaced by a mid-task user question.
