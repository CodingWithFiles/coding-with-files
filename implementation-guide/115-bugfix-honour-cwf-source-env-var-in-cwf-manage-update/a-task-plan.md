# Honour CWF_SOURCE env var in cwf-manage update - Plan
**Task**: 115 (bugfix)

## Task Reference
- **Task ID**: internal-115
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/115-honour-cwf-source-env-var-in-cwf-manage-update
- **Template Version**: 2.1

## Goal
Make `cwf-manage` honour the `CWF_SOURCE` environment variable so users can redirect update/list-releases at a non-default repo (e.g. `file:///` for local development) without editing `.cwf/version`.

## Success Criteria
- [ ] `CWF_SOURCE=file:///path cwf-manage update` clones from the env-var path, ignoring `cwf_source` in `.cwf/version`
- [ ] `CWF_SOURCE=file:///path cwf-manage list-releases` queries tags from the env-var path
- [ ] When `CWF_SOURCE` is unset, behaviour is unchanged — `cwf-manage` falls back to `cwf_source` in `.cwf/version`
- [ ] `.cwf/version` is **not** rewritten with the env-var value after an env-driven update (env var is a session override, not a re-pin)
- [ ] Behaviour matches `scripts/install.bash` (which already honours `CWF_SOURCE`); convention is documented in one place
- [ ] Regression test in `t/` covers env-var override for both `update` and `list-releases`

## Original Estimate
**Effort**: 0.5 days
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Design**: Decide precedence rules (env > file? warn on mismatch?) and whether `.cwf/version` is rewritten
2. **Implement**: Threading `CWF_SOURCE` through `cmd_update` and `cmd_list_releases` in `.cwf/scripts/cwf-manage`
3. **Test**: Subtest in `t/` exercising env-var override and the unset fallback
4. **Document**: Update `cwf-manage --help` (or its `usage` block) to mention `CWF_SOURCE`, mirroring `install.bash` lines 10–15

## Risk Assessment
### High Priority Risks
- **Silent re-pin**: If `cwf-manage update` writes the env-var value back into `.cwf/version`, a one-shot `CWF_SOURCE=file:///...` invocation permanently re-pins the source. Easy to miss.
  - **Mitigation**: Explicit decision in design phase — env var is a session override, not persisted. Test asserts `.cwf/version` `cwf_source` field is unchanged after an env-driven update.

### Medium Priority Risks
- **Divergence from install.bash convention**: If precedence rules differ between `install.bash` (env > default) and `cwf-manage` (env > file), users will be confused.
  - **Mitigation**: Document precedence in one place (e.g. `INSTALL.md` or a glossary entry); both code paths cite it. Cross-check during design.
- **Hidden callers**: `cwf_source` may be read by code paths beyond `cmd_update` / `cmd_list_releases`. Patching only the obvious two leaves drift.
  - **Mitigation**: Grep audit during design (`grep -n cwf_source .cwf/scripts/cwf-manage`) to enumerate all readers; decide which honour the env var.

## Dependencies
- None — self-contained fix in `.cwf/scripts/cwf-manage`.

## Constraints
- Must not break existing default-source flow (no `CWF_SOURCE` set, no `.cwf/version` change required).
- Must not silently rewrite `.cwf/version` based on a transient env var.
- Convention must match `install.bash`'s existing `CWF_SOURCE` semantics.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? **No** — half-day fix.
- [x] **People**: Does this need >2 people working on different parts? **No** — single contributor.
- [x] **Complexity**: Does this involve 3+ distinct concerns? **No** — one script, one env-var convention.
- [x] **Risk**: Are there high-risk components that need isolation? **No** — local script change with regression test coverage.
- [x] **Independence**: Can parts be worked on separately? **No** — design/impl/test are tightly coupled.

**Conclusion**: No decomposition needed. Single top-level task.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 115
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
