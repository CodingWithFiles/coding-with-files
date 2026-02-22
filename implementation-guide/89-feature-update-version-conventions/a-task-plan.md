# Update version conventions - Plan
**Task**: 89 (feature)

## Task Reference
- **Task ID**: internal-89
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/89-update-version-conventions
- **Template Version**: 2.1

## Goal
Establish a human-controlled `{major}.{minor}.{task_num}` versioning convention for CWF releases, documented dev-side only, and update `cwf-manage list-releases` to show a curated upgrade view rather than the full tag dump.

## Success Criteria
- [ ] `CLAUDE.md` has a `## Versioning` section documenting the `{major}.{minor}.{task_num}` scheme, definitions of major/minor/patch, and an explicit statement that tagging and releasing are human-only actions (not model actions)
- [ ] The convention doc is not reachable from any installed file (not referenced in `.cwf/docs/`, `.cwf/templates/`, or any skill)
- [ ] `cwf-manage list-releases` default output shows: latest patch on current minor, latest per each higher minor within current major, latest per each higher major — not the full dump
- [ ] `cwf-manage list-releases --all` still shows every tag
- [ ] `cwf-manage validate` passes

## Original Estimate
**Effort**: 0.5 days
**Complexity**: Low
**Dependencies**: `v0.1.88` tag applied to main post-merge (human prerequisite for live testing; unit tests use constructed tag lists so not a blocker for implementation)

## Major Milestones
1. **Milestone 1**: `CLAUDE.md` versioning section written
2. **Milestone 2**: `cwf-manage list-releases` filtering logic implemented and unit-tested
3. **Milestone 3**: `v0.1.88` tag applied to main after merge (human action, not part of implementation)

## Risk Assessment
### High Priority Risks
- **Risk**: Filtering logic gets semver comparison wrong at boundaries (no higher minor exists, no higher major exists, current version is already the latest)
  - **Mitigation**: Unit-test the filter with constructed tag lists covering all edge cases before using the live remote

### Medium Priority Risks
- **Risk**: Convention doc leaks into installed files via future copy/paste
  - **Mitigation**: Explicit "do not reference from installed files" note in the section; dev-only placement in `CLAUDE.md`

## Dependencies
- No external dependencies
- Tagging `v0.1.88` on main is a post-merge human action, not a task deliverable

## Constraints
- Convention must be dev-side only — no installed file may reference it
- Tagging and releasing are human-only; the model must not tag, push, or suggest merging
- `cwf-manage` is Perl — filtering must extend `version_cmp` cleanly, no new dependencies

## Decomposition Check
- [ ] **Time**: No — under 0.5 days
- [ ] **People**: No
- [ ] **Complexity**: No — two small independent changes (doc edit + Perl sub), neither complex enough to warrant a subtask
- [ ] **Risk**: No
- [ ] **Independence**: N/A at this scale

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 89
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Completed in ~2 hours. CLAUDE.md versioning section added; cwf-manage list-releases
filtered view implemented with parse_semver + filter_releases. All 15 TCs pass.

## Lessons Learned
Single-regex parsing enforces strict prefix requirements more reliably than strip+split.
Testing Perl scripts via `do` requires adding the script's own lib path first.
