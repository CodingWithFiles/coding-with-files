# backlog validate minimum structural contract - Plan
**Task**: 190 (feature)

## Task Reference
- **Task ID**: internal-190
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/190-backlog-validate-minimum-structural-contract
- **Baseline Commit**: 48b12c6cbe65c67eb94e65655f4ab6e5de4b3d44
- **Template Version**: 2.1

## Goal
Make `backlog-manager validate` assert a minimum structural contract so a clean
result accurately means the file is *manageable*, instead of passing vacuously on a
foreign-shaped `BACKLOG.md` that the tooling silently treats as "0 items".

## Success Criteria
- [ ] A foreign but well-formed-markdown `BACKLOG.md` (wrong shape, no recognised skeleton/entries) **fails** `validate` with a clear structural error, instead of reporting success.
- [ ] A legitimately empty backlog (required structure present, zero entries) and **every existing repo fixture** continue to validate clean — no false positives, and the legacy pre-`normalise` refusal path stays coherent.
- [ ] Mutation subcommands (`add`/`modify`/`retire`/`delete`) refuse to operate on a file that fails the structural check (no silent no-op or canonicalise-over-foreign-content).
- [ ] A decision is recorded on whether CHANGELOG needs the same minimum-structure treatment, with parity either applied or explicitly scoped out.
- [ ] Test fixtures cover both the foreign-file and empty-but-valid cases; full `prove -lr t/` and `cwf-manage validate` are green.

## Original Estimate
**Effort**: ~0.5–1 day
**Complexity**: Medium (the logic is small; the risk is false positives on our own files)
**Dependencies**: `CWF::Backlog` (heading-tree model, Task 132) and the `backlog-manager` helper — no external deps

## Major Milestones
1. **Reproduce**: a fixture — a foreign-shaped `BACKLOG.md` — that today validates clean yet lists 0 items.
2. **Define the contract**: enumerate the AST elements the manager's read/mutate paths actually depend on, and the signal that distinguishes *empty-but-valid* from *foreign*.
3. **Implement**: the validate rule plus mutation-path refusal; add fixtures and tests.
4. **Verify & retire**: no false positives across existing fixtures + bootstrap/legacy paths; retire backlog item `48b12c6`.

## Risk Assessment
### High Priority Risks
- **False positives on our own files**: an over-strict contract rejects valid/empty/legacy BACKLOGs.
  - **Mitigation**: derive the contract strictly from what the manager *reads*; test against all existing fixtures and the empty/bootstrap case before finalising.

### Medium Priority Risks
- **Empty-vs-foreign is subtle**: "zero entries" cannot be the sole signal (a valid empty backlog also has zero entries).
  - **Mitigation**: anchor on a required structural marker (mirroring CHANGELOG-001's `# Changelog` assertion); settle the exact signal in design.
- **Scope creep**: drifting into a full schema language or a CHANGELOG redesign.
  - **Mitigation**: keep the contract minimal — only what the manager relies on; CHANGELOG parity is a yes/no decision, not a rework.

## Dependencies
- Builds on the `CWF::Backlog` parser/validator and the `backlog-manager` helper; no external or team dependencies.

## Constraints
- Perl core-only, POSIX (per project conventions).
- Contract must stay **flexible**: prose and additions *outside* the required skeleton must remain valid and must not break the tooling.
- Must not regress the existing pre-`normalise` refusal path for legacy `**Field**:` entries.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? — No (~1 day)
- [ ] **People**: Does this need >2 people working on different parts? — No
- [ ] **Complexity**: Does this involve 3+ distinct concerns? — No (one validator rule + mutation gate + tests)
- [ ] **Risk**: Are there high-risk components that need isolation? — No
- [ ] **Independence**: Can parts be worked on separately? — No (single cohesive change)

**Outcome**: 0 signals triggered — no decomposition; proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
