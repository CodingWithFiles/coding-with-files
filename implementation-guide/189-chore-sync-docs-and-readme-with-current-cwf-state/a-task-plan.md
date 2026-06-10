# Sync docs and README with current CWF state - Plan
**Task**: 189 (chore)

## Task Reference
- **Task ID**: internal-189
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/189-sync-docs-and-readme-with-current-cwf-state
- **Baseline Commit**: c5797a3d295608a7a580ed8260ba769fb51f96c4
- **Template Version**: 2.1

## Goal
Bring the user- and maintainer-facing documentation back into agreement with the
current CWF implementation so the repo presents a coherent, accurate picture for a
public release.

## Success Criteria
- [ ] Every `/cwf-*` command named in README.md, COMMANDS.md and CLAUDE.md maps to an
      actual skill in `.claude/skills/`; no documented command is missing or invented
      (notably: the non-existent `/cwf-substep` section is removed and
      `/cwf-new-task` syntax matches the real `<num> [<type>] "description"` form).
- [ ] All quantitative claims (helper-script count, skill count, workflow-step count)
      match reality at the time of writing, verified by recount during exec rather than
      copied from prose.
- [ ] No stale system-version assertions remain (no "v2.0 implemented" / "5 helper
      scripts" / "8 steps a–h"); version-format *examples* are either current-era or
      clearly labelled as illustrative.
- [ ] DESIGN.md and CWF-PROJECT-SPEC.md describe the architecture that ships today
      (current helper-script naming, lettered a–j phase files), with no references to
      removed v1 `cig-*` scripts or pre-lettered filenames.
- [ ] The vestigial root `scratchpad.md` is resolved (removed) and `docs/` vs
      `.cwf/docs/` convention duplication has a documented resolution.
- [ ] An output-level smoke test confirms a freshly generated task's docs and a grep of
      the shipped docs surface no stale counts/version strings (per the rebrand lesson).

## Original Estimate
**Effort**: ~1 day
**Complexity**: Medium (breadth across many docs, but each edit is low-risk text)
**Dependencies**: None external. Relies on current skill/script/template state as
ground truth (audit completed during planning).

## Major Milestones
1. **Inventory locked**: Confirmed ground-truth counts (skills, helper scripts,
   workflow steps) and the full drift list, file-by-file (detailed in d-implementation-plan).
2. **High-impact corrections**: COMMANDS.md command set/syntax, CLAUDE.md system-state
   claims, README counts corrected.
3. **Architecture docs**: DESIGN.md / CWF-PROJECT-SPEC.md updated to current naming and
   phase model.
4. **Housekeeping**: scratchpad.md resolved, docs-duplication resolution applied,
   cross-doc references validated.
5. **Verification**: Grep sweep + generated-artefact smoke test clean.

## Risk Assessment
### High Priority Risks
- **Re-introducing new stale numbers**: hand-copying counts (e.g. "24 scripts") risks
  being wrong tomorrow and wrong on audit.
  - **Mitigation**: recount programmatically during exec; prefer descriptive phrasing
    over brittle exact counts where a count adds no value; record the count's basis.

### Medium Priority Risks
- **Scope creep into rewriting architecture**: DESIGN.md is substantially stale and the
  temptation is a full rewrite.
  - **Mitigation**: scope is *sync to current reality*, not redesign; correct claims and
    names, do not re-architect. Larger rewrites go to BACKLOG.
- **CLAUDE.md is an instruction file, not just prose**: careless edits could change
  agent behaviour.
  - **Mitigation**: limit CLAUDE.md edits to the factual Project-Status/architecture
    claims that are wrong; leave conventions/rules untouched.
- **docs/ vs .cwf/docs/ duplication is a design question**, not a pure sync fix.
  - **Mitigation**: in this task, document which location is authoritative and fix the
    references; defer any consolidation that requires moving files to a BACKLOG item if
    it proves non-trivial.

## Dependencies
- Ground-truth state of `.claude/skills/`, `.cwf/scripts/`, `.cwf/templates/pool/`,
  `.cwf/docs/workflow/workflow-steps/`, and current git tag.

## Constraints
- Documentation-only change set; no behavioural code edits expected.
- British spelling in prose; no superlatives; no personal names in committed docs.
- Must itself go through the full CWF chore workflow (dog-fooding).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No — roughly a day.
- [ ] **People**: >2 people? No — single maintainer.
- [x] **Complexity**: 3+ distinct concerns? Arguably yes (count fixes, command-syntax
      fixes, architecture-doc fixes, housekeeping) — but all are the same *kind* of work
      (text edits to docs) under one reviewer.
- [ ] **Risk**: High-risk components needing isolation? No.
- [x] **Independence**: Parts separable? Yes (per-doc) — but separability here is weak
      evidence; the docs share counts/version facts that are cheaper to fix coherently
      in one pass.

**Decision**: Two signals are technically present, but both are weak for a cohesive,
single-reviewer documentation sync. Keep as **one task**; structure the
implementation plan by document so the work stays legible. Revisit only if the
DESIGN.md or docs-duplication work turns out to need real redesign — in which case spin
that out as a subtask/BACKLOG item rather than expanding this task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
