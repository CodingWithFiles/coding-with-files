# retire bootstraps missing CHANGELOG task entry - Plan
**Task**: 147 (feature)

## Task Reference
- **Task ID**: internal-147
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/147-retire-bootstraps-missing-changelog-task-entry
- **Baseline Commit**: 3ff7155c7ca9c6f40a2faa46ee385c5fc53a3ef2
- **Template Version**: 2.1

## Goal
Make `backlog-manager retire` bootstrap a minimal CHANGELOG entry for `--task=N` when none exists, so retiring a backlog item mid-task no longer requires a pre-existing destination.

## Success Criteria
- [ ] `retire --task=N` succeeds when CHANGELOG has no `## Task N: ...` entry, creating the entry and the `### Retired Backlog Items` subsection in one atomic write pair.
- [ ] When the entry already exists, behaviour is byte-identical to today (no spurious metadata, no reordering).
- [ ] Stub entry derives its title deterministically from `implementation-guide/N-<type>-<slug>/` and is well-formed enough that subsequent retires and the existing retrospective workflow can append to it without rework.
- [ ] `backlog-manager validate` passes against the resulting CHANGELOG (no schema regressions).
- [ ] Test coverage exists for both "entry absent → bootstrapped" and "entry present → untouched-except-for-block" paths.

## Original Estimate
**Effort**: 1 session (~half-day)
**Complexity**: Low
**Dependencies**: None — change is internal to `backlog-manager retire` and `CWF::Backlog`.

## Major Milestones
1. **Requirements**: Pin down the stub entry's exact shape (which headings/fields are mandatory at bootstrap time vs filled later at retrospective).
2. **Design**: Decide whether bootstrap logic lives in `cmd_retire` or as a new `CWF::Backlog::ensure_changelog_entry_for_task` helper; settle title-derivation rule.
3. **Implementation + tests**: Replace the `die_user` at line 465 with a bootstrap-then-append path; add tests for both paths and for the `--task` arg validation against the on-disk task directory.

## Risk Assessment
### High Priority Risks
- **Risk: malformed stub diverges from retrospective-generated entries.** If the bootstrap shape differs from what `/cwf-retrospective` later produces, the retrospective phase might double-write headings, fight the parser, or silently lose the `### Retired Backlog Items` subsection.
  - **Mitigation**: Inspect 2-3 recent CHANGELOG entries written by retrospective (e.g. Task 146) and define the bootstrap as a strict subset; verify in design phase that retrospective is additive over the stub, not replacement.

### Medium Priority Risks
- **Risk: title derivation surprises the user.** Deriving title from the task dir slug ("retire-bootstraps-...") produces a kebab-case string, whereas retrospective titles are prose ("Backlog refactor: retire, merge, reduce").
  - **Mitigation**: Design phase decides — options include de-slugifying with sentence-case, requiring `--title` when bootstrapping, or accepting kebab-case as a known-acceptable placeholder that retrospective overwrites.
- **Risk: validator rejects sparse stub.** `backlog-manager validate` may require certain headings that retrospective normally provides (Status, Duration, Impact).
  - **Mitigation**: Run validate against a hand-crafted minimal entry early in design to enumerate the actually-required headings.

## Dependencies
- None external. Internal: `CWF::Backlog` parser/writer must round-trip the bootstrapped entry losslessly (already a tested property).

## Constraints
- POSIX-only, core Perl only ([[feedback_perl_core_only]]).
- No new flags unless requirements phase justifies one — preserve the current CLI surface.
- The atomic-write ordering at lines 467-482 (CHANGELOG before BACKLOG, both atomic) must be preserved; bootstrap happens in-memory before the CHANGELOG write.

## Decomposition Check
- [ ] **Time**: >1 week? No — half-day estimate.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one helper, one call site, one parser invariant.
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Separable parts? No.

No decomposition signals triggered → proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 147
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
