# CWF install script and release management - Plan
**Task**: 61 (feature)

## Task Reference
- **Task ID**: internal-61
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/61-cwf-install-script
- **Template Version**: 2.1

## Goal
Create a zero-interaction install script (`install.bash`) that agents and humans can use to install, update, and manage CWF in their repos via `curl | bash`, with env-var-based configuration.

## Success Criteria
- [ ] `curl -fsSL $URL | bash` installs CWF into the current repo with no interaction
- [ ] `curl -fsSL $URL | CWF_METHOD=copy bash` installs via file copy instead of subtree
- [ ] `curl -fsSL $URL | CWF_REF=v2.1.0 bash` installs a specific version
- [ ] Default method is dual git subtree split; default ref is latest semver tag
- [ ] Post-install management script (`.cwf/scripts/cwf-manage`) supports `update`, `status`, `rollback`, `list-releases`
- [ ] INSTALL.md updated to document both the script and manual methods

## Original Estimate
**Effort**: 1-2 sessions
**Complexity**: Medium
**Dependencies**: Task 60 (INSTALL.md), a tagged release to test against

## Major Milestones
1. **Bootstrap script**: `install.bash` handles install via subtree (default) or copy, with `CWF_METHOD` and `CWF_REF` env vars
2. **Management script**: `.cwf/scripts/cwf-manage` handles update, status, rollback, list-releases
3. **Release tagging**: Convention established, at least one tagged release exists for testing
4. **Documentation**: INSTALL.md updated with script-based install alongside manual methods

## Risk Assessment
### High Priority Risks
- **Ref resolution complexity**: Supporting tags, branches, and commit SHAs (both SHA-1 40-char and SHA-2/256 64-char, plus short forms) adds validation complexity
  - **Mitigation**: Use `git rev-parse` for validation rather than regex; let git do the work

### Medium Priority Risks
- **Agent compatibility**: Agents may not handle all shell idioms or env var patterns correctly
  - **Mitigation**: Test with a real agent running the install in an external repo (as done in Task 60)
- **Subtree split performance**: `git subtree split` on a large history may be slow
  - **Mitigation**: Use `--squash` to limit history; benchmark and document expected times

### Low Priority Risks
- **curl | bash security perception**: Some users/orgs reject pipe-to-bash installs
  - **Mitigation**: Document download-then-inspect alternative (`curl -o` then `bash`)

## Dependencies
- Task 60 complete (INSTALL.md exists with manual instructions)
- At least one tagged release on main for testing ref resolution
- External test repo for validation

## Constraints
- Script must work with Bash 4+ (no bashisms beyond that)
- Zero interaction — all configuration via env vars, no prompts
- Must handle both SHA-1 and SHA-2/256 commit refs (Git `object-format` support)
- Must work when run by an agent (no interactive prompts, clear stdout feedback)

## Decomposition Check
- [x] **Time**: No — estimated 1-2 sessions
- [x] **People**: No — single author
- [ ] **Complexity**: Borderline — bootstrap script + management script + release convention are 3 concerns, but tightly coupled
- [x] **Risk**: No — no high-risk components needing isolation
- [ ] **Independence**: Borderline — management script could be developed separately from bootstrap

Two signals borderline. The components are tightly coupled enough that decomposition would add overhead without benefit. Proceed as single task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 61
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 6 success criteria met. Bootstrap script (`scripts/install.bash`, ~240 lines) supports subtree and copy methods with `.cwf-skills/` staging prefix and symlinks. Management script (`.cwf/scripts/cwf-manage`, ~345 lines Perl) supports status, list-releases, update, rollback. INSTALL.md fully updated. 28/28 tests pass. Task required a full process rework (b→g) after testing revealed the original `.claude/skills/` subtree prefix clobbered existing consumer skills.

## Lessons Learned
- Original estimate of 1-2 sessions was accurate despite the rework — the structured process caught the design flaw early enough.
- Two borderline decomposition signals were correctly assessed as not warranting decomposition — the tight coupling between bootstrap and management scripts meant a single task was more efficient.
