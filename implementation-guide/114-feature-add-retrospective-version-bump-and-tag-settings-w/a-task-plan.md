# Add retrospective version bump and tag settings with versioning helper script - Plan
**Task**: 114 (feature)

## Task Reference
- **Task ID**: internal-114
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/114-add-retrospective-version-bump-and-tag-settings-w
- **Template Version**: 2.1

## Goal
Make retrospective version-bump and tag steps deterministic and configurable per project, so external CwF users can opt in or out of each, while encoding CwF's own policy (bump yes, tag no) in project settings.

## Success Criteria
- [ ] `cwf-project.json` supports a hierarchical `wf_step_config.retrospective.{bump_version,tag_version}` section with boolean values, defaulted sensibly when absent
- [ ] CwF's own `cwf-project.json` is updated to `bump_version: true`, `tag_version: false` (matching the human-only-tag rule in CLAUDE.md)
- [ ] A versioning standard is documented (semver only, with `v{major}.{minor}` HITL field maintained by humans and `{patch}` derived from latest task number)
- [ ] A helper script reads the wf-step config, computes the next version from the HITL field + last completed task number, and conditionally bumps and/or tags
- [ ] The retrospective skill (`j-retrospective`) calls the helper script instead of inlining bump/tag logic
- [ ] Stale `CIG` strings in `version.yml` are replaced with `CwF`, and `version.yml` reflects the new versioning standard

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium
**Dependencies**: None — schema change, new helper script, retrospective skill update, doc updates

## Major Milestones
1. **Schema and standard defined**: `wf_step_config` tree added to project schema; semver versioning standard documented; HITL `v{major}.{minor}` field location chosen
2. **Helper script implemented**: New `cwf-version` (or similar) script that reads config, computes next version, conditionally bumps the HITL field and/or creates a git tag
3. **Retrospective integration**: `j-retrospective` skill calls the helper; CwF's own settings updated; `version.yml` rebranded and aligned with the standard

## Risk Assessment
### High Priority Risks
- **Risk 1**: Helper script accidentally tags or pushes when it shouldn't (violates human-only-tag rule)
  - **Mitigation**: Default `tag_version` to false; require explicit true; never `git push --tags`; add a smoke test for the "bump only, no tag" path which is CwF's own configuration

### Medium Priority Risks
- **Risk 2**: HITL `v{major}.{minor}` field drift — humans forget to bump major/minor when they should
  - **Mitigation**: Document the rule clearly (when to bump major vs minor) co-located with the field; the script's job is only `{patch}`, so drift is contained
- **Risk 3**: Existing tasks/scripts reference the current versioning shape (`version.yml` with `git-based-versioning: true`) and break when the source of truth moves
  - **Mitigation**: Audit references during design phase; keep `version.yml` as the source of truth, just restructure its contents

## Dependencies
- None external; all changes are inside this repo

## Constraints
- Must preserve the human-only-tag rule from `CLAUDE.md` (CwF itself never tags from the script)
- Must be backward compatible for projects with no `wf_step_config` block — sensible defaults apply
- Initial scope is semver only; pluggable versioning schemes are out of scope

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — 1-2 days
- [ ] **People**: Does this need >2 people working on different parts? No
- [x] **Complexity**: Does this involve 3+ distinct concerns? Yes — schema, helper script, retrospective integration, doc/version.yml cleanup. Borderline; staying as one task because the parts are tightly coupled (script depends on schema, retrospective depends on script)
- [ ] **Risk**: Are there high-risk components that need isolation? No
- [ ] **Independence**: Can parts be worked on separately? Not meaningfully — sequential

**Decision**: One task. 1 signal triggered, but coupling makes subtasks high-overhead.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 114
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 6 success criteria delivered as planned. `version.yml` rebrand and CwF self-config landed in this task as committed. No criteria descoped. Duration came in well under estimate (1 session vs 1-2 days).

## Lessons Learned
The "tightly coupled — single task" decomposition decision (1 signal triggered, kept as one task) was correct. The four parts (schema, helper module, scripts, retrospective integration) had real coupling: testing the script chain end-to-end required all of them present.
