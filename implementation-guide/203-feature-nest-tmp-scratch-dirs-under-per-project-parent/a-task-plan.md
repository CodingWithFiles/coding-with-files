# Nest tmp scratch dirs under per-project parent dir - Plan
**Task**: 203 (feature)

## Task Reference
- **Task ID**: internal-203
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/203-nest-tmp-scratch-dirs-under-per-project-parent
- **Baseline Commit**: 7d09f1dbceef9aa8be9f6410e4bbde82657d5d34
- **Template Version**: 2.1

## Goal
Change the per-task scratch convention from sibling top-level `/tmp` dirs to a
single per-project parent dir holding `task-<num>/` subdirs, so the Bash
permission prompt for scratch artefacts fires once per project, not once per task.

## Problem
The current form `${TMPDIR:-/tmp}/<dashified-repo>-task-<num>/` makes every task a
**new top-level** scratch dir. Running a one-off script or capturing output from it
trips a fresh Bash permission prompt each task, because the path prefix changes with
`<num>`. The accumulating per-task allowlist entries in `.claude/settings.local.json`
(e.g. `Bash(/tmp/-home-…-task-185/probe.bash)`, lines 137, 146–150) are the visible
cost. A stable parent prefix (`${TMPDIR:-/tmp}/cwf-<dashified-repo>/`) lets a single
allowlist rule cover every task's scratch dir, present and future.

## Success Criteria
- [ ] Canonical form in `tmp-paths.md` is the nested parent/`task-<num>` shape, with
      derivation snippet, worked example, and 0700 symlink-defence guard updated
- [ ] `security-review-changeset` writes its `.out` under the new nested path
- [ ] One allowlist prefix rule (shipped `.claude/settings.json`) covers all tasks'
      scratch execution; per-task entries no longer needed going forward
- [ ] All call sites / docs referencing the old form are updated or carved out
- [ ] Existing tests pass; new test covers the helper's path derivation

## Original Estimate
**Effort**: ~0.5 day
**Complexity**: Medium
**Dependencies**: `tmp-paths.md` convention, `security-review-changeset` helper, agent memory `[[tmp-paths]]`

## Major Milestones
1. **Convention rewrite**: `tmp-paths.md` canonical form + derivation snippet + threat model
2. **Helper update**: `security-review-changeset` path derivation + test
3. **Allowlist + references**: shipped settings prefix rule; sweep stale references

## Risk Assessment
### High Priority Risks
- **Stale references left behind**: the old form is referenced across docs, skills,
  and agent memory; missing one leaves drift.
  - **Mitigation**: grep sweep at implementation; output-level smoke test of the helper.

### Medium Priority Risks
- **Symlink-defence regression**: a two-level `mkdir` must preserve the atomic 0700
  guard on the *parent* as well as the task dir.
  - **Mitigation**: design the mkdir sequence explicitly; test parent perms.
- **`.cwfkeep` sentinel may not earn its place**: the proposed sentinel touch needs a
  concrete justification or it is dead surface (KISS).
  - **Mitigation**: resolve as an explicit design decision in c-design-plan.

## Dependencies
- `.cwf/docs/conventions/tmp-paths.md` (the convention being changed)
- `.cwf/scripts/command-helpers/security-review-changeset` (only in-tree consumer)
- Agent memory `[[tmp-paths]]` (update after merge)

## Constraints
- Single-user host threat model unchanged; 0700 guard remains the containment boundary
- POSIX-only; Perl core modules only
- Hash refresh for `security-review-changeset` happens in the same commit as the edit

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? No (~0.5 day)
- [x] **People**: Does this need >2 people working on different parts? No
- [x] **Complexity**: Does this involve 3+ distinct concerns? No (one convention + one consumer)
- [x] **Risk**: Are there high-risk components that need isolation? No
- [x] **Independence**: Can parts be worked on separately? No — convention and consumer move in lockstep

**Conclusion**: No decomposition. Single coherent change, 0 signals triggered.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All success criteria met. One scope variance: SC3's "shipped `.claude/settings.json`
prefix rule" was changed in design (D4) to a **documented, user-owned** optional allowlist
— CWF edits no settings file (the path embeds a machine-specific absolute path). 0 of 5
decomposition signals triggered, as planned; the change stayed a single coherent unit.

## Lessons Learned
*Consolidated in j-retrospective.md.*
