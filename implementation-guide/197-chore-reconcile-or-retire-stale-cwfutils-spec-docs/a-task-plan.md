# Reconcile or retire stale .cwf/utils spec docs - Plan
**Task**: 197 (chore)

## Task Reference
- **Task ID**: internal-197
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/197-reconcile-or-retire-stale-cwfutils-spec-docs
- **Baseline Commit**: 4234034eef7d6e37c80bf0d4aab08508c9f5b784
- **Template Version**: 2.1

## Goal
Stop the four inert `.cwf/utils/*.md` docs from shipping a pre-Task-189 design to end users, by retiring or reconciling them against the current source of truth (`CWF-PROJECT-SPEC.md` and the live skills/helpers).

## Success Criteria
- [ ] No file under `.cwf/utils/` describes a superseded design as if it were current (each is either deleted or brought into agreement with `CWF-PROJECT-SPEC.md` and the live implementation).
- [ ] A reference sweep confirms no helper, lib, skill, template, or test depends on any retained/removed `.cwf/utils/*.md` (current state: only an historical `CHANGELOG.md` note refers to them).
- [ ] The `cwf-manage validate` integrity check passes (no sha256/permission drift introduced).
- [ ] The originating backlog item (BACKLOG.md:1459) is retired and the change recorded in `CHANGELOG.md`.

## Original Estimate
**Effort**: <0.5 day
**Complexity**: Low
**Dependencies**: None — files are inert (no code path reads them).

## Major Milestones
1. **Decide direction (per file)**: retire vs reconcile, settled in the implementation-plan phase and confirmed at plan review.
2. **Apply**: delete or rewrite each of the four files; refresh any affected index/manifest.
3. **Verify & close**: reference sweep clean, `cwf-manage validate` green, backlog/changelog updated.

## Risk Assessment
### Medium Priority Risks
- **Wrong reconciliation target**: hand-written prose specs re-drift the moment the validator/helpers change again — the same failure that produced this task.
  - **Mitigation**: Strong lean toward *retire* (delete). Per the planning "best part is no part" principle, `CWF-PROJECT-SPEC.md` is already the authoritative config spec and the behaviours in `template-engine`/`task-validator`/`hierarchy-manager` are now embodied in live skills/helpers. Only reconcile a file if there is a concrete current consumer for its prose (none found so far).

### Low Priority Risks
- **Hidden consumer missed by grep**: a dynamic/late reference (e.g. a doc cross-link) not caught by a literal `.cwf/utils` search.
  - **Mitigation**: Sweep widens to bare `utils/` and per-filename basenames before deletion; deletion is trivially reversible via git if a consumer surfaces.

## Dependencies
- None external. Self-contained doc change within this repo's `.cwf/` tree.

## Constraints
- Files are not hash-tracked (absent from `.cwf/security/script-hashes.json`), so no same-commit hash refresh is required — but `cwf-manage validate` must still pass.
- `.cwf/` ships to end users wholesale via `git read-tree --prefix=.cwf/`, so whatever is retained is published as current guidance.
- Scope note: the backlog names three files; `hierarchy-manager.md` is equally stale (describes obsolete `implementation-guide/<category>/` dirs and `find|sed` numbering) and is folded into scope.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — under half a day.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one concern (four parallel doc files, same treatment).
- [ ] **Risk**: Are there high-risk components that need isolation? No — inert, git-reversible.
- [ ] **Independence**: Can parts be worked on separately? Technically yes, but not worth the overhead.

**Verdict**: 0 signals triggered — single task, no subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
