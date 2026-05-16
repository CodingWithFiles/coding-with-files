# Split path-allowlist by access mode - Plan
**Task**: 140 (chore)

## Task Reference
- **Task ID**: internal-140
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/140-split-path-allowlist-by-access-mode
- **Baseline Commit**: d3d7b86f6e4869e8e8d27eadff0ef6d0efc674c8
- **Template Version**: 2.1

## Goal
Replace the single `validate_path_allowlist` with three access-mode-specific helpers (write, read, temp) so each call site enforces rules that match its actual threat model.

## Success Criteria
- [ ] `CWF::ArtefactHelpers` exports `validate_write_path_allowlist`, `validate_read_path_allowlist`, and `validate_temp_path_allowlist` with semantics matching the BACKLOG entry.
- [ ] All three existing call sites (`cwf-apply-artefacts`, `cwf-claude-settings-merge`, `backlog-manager --body-file`) call the variant matching their access mode; `backlog-manager --body-file` accepts `/tmp/<task>/...` paths.
- [ ] Old `validate_path_allowlist` is removed (no exports, no callers, no tests).
- [ ] `t/artefacthelpers.t` covers each variant's accept/reject rules; `t/backlog-manager-*.t` exercises a `/tmp/<task>/...` body file successfully.
- [ ] `prove t/` is green; security-review-changeset reports no new findings; script hashes regenerated.

## Original Estimate
**Effort**: 0.5 days
**Complexity**: Low
**Dependencies**: None — all touched files live in `.cwf/lib/`, `.cwf/scripts/command-helpers/`, and `t/`.

## Major Milestones
1. **API defined**: Three new functions land in `CWF::ArtefactHelpers` with unit tests; old function still present.
2. **Call sites migrated**: Each caller switched to the appropriate variant; old function removed.
3. **Verification**: Tests green, hashes regenerated, body-file via `/tmp/<task>/...` confirmed working end-to-end.

## Risk Assessment
### High Priority Risks
- **Risk 1**: A caller's *actual* threat model is mis-classified (e.g. `cwf-claude-settings-merge` looks like a write but the path is read-only at that moment). Wrong variant means we either re-impose the friction we are trying to remove, or weaken a real defence.
  - **Mitigation**: For each call site, read the surrounding code and document on `d-implementation-plan.md` whether the path is *read*, *written*, or *transient*, before choosing a variant. Cross-check against the BACKLOG entry's worked examples.

### Medium Priority Risks
- **Risk 2**: `validate_temp_path_allowlist` has no current callers (BACKLOG says "identify call sites during design"). Adding the function with zero callers risks dead code.
  - **Mitigation**: During implementation planning, audit `cwf-checkpoint-commit` and `security-review-changeset` (the two candidates the BACKLOG entry names). If neither needs it now, defer the function — ship only `validate_write_path_allowlist` and `validate_read_path_allowlist`, leave temp variant on the BACKLOG.
- **Risk 3**: Removing `validate_path_allowlist` outright breaks any out-of-tree script that imports it.
  - **Mitigation**: This repo has no consumers outside the tree (the function lives in `.cwf/lib/`, an internal module). Confirm via `grep -r validate_path_allowlist` across the working copy; nothing else needs deprecation shimming.

## Dependencies
- None.

## Constraints
- Perl core modules only (per repo convention).
- POSIX-only; no Windows-isms.
- All Perl files keep the standard `use utf8;` + `#!/usr/bin/env perl` header.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? — No, ~0.5 day.
- [ ] **People**: Does this need >2 people working on different parts? — No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? — No, single concern (path validation API).
- [ ] **Risk**: Are there high-risk components that need isolation? — No, security-adjacent but small surface; existing test coverage protects against regression.
- [ ] **Independence**: Can parts be worked on separately? — No, the rename + call-site migration must land together.

No signals triggered — single task is appropriate.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 140
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
