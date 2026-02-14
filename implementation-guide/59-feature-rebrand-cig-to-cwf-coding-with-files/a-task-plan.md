# Rebrand CIG to CWF (Coding with Files) - Plan
**Task**: 59 (feature)

## Task Reference
- **Task ID**: internal-59
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/59-rebrand-cig-to-cwf-coding-with-files
- **Template Version**: 2.1

## Goal
Rebrand from "Code Implementation Guide" (CIG) to "Coding with Files" (CWF / "swiff") across the entire codebase — renaming directories, files, Perl namespaces, skill names, script names, config keys, and documentation prose — while preserving historical task workflow documents unchanged.

## Success Criteria
- [ ] `.cig/` directory renamed to `.cwf/` (entire tree)
- [ ] All 19 skill directories renamed from `cig-*` to `cwf-*` (`.claude/skills/`)
- [ ] `CIG::*` Perl namespace renamed to `CWF::*` (11 modules + all use/package statements)
- [ ] All `cig-` prefixed helper scripts renamed to `cwf-*`
- [ ] `cig-project.json` renamed to `cwf-project.json` (+ template)
- [ ] All documentation updated: README, CLAUDE.md, COMMANDS.md, CHANGELOG, BACKLOG, project spec, `.cwf/docs/*`
- [ ] All SKILL.md files and helper scripts updated with new paths and references
- [ ] Historical task workflow docs (`implementation-guide/*/`) left unchanged
- [ ] System functional end-to-end: `/cwf-status`, `/cwf-task-plan`, etc. all work after rename

## Original Estimate
**Effort**: 3-5 hours
**Complexity**: Medium-High (wide blast radius across ~70 files, interconnected references, Perl namespace rename)
**Dependencies**: Tasks 57 and 58 complete (they are)

## Major Milestones
1. **Requirements clarified**: Decide on all naming questions (implementation-guide dir, config keys, "swiff" usage, Perl namespace consolidation)
2. **Design complete**: Ordered rename strategy, file inventory, content replacement rules
3. **Structural renames**: `.cig/` → `.cwf/`, skill dirs, script names, Perl namespace dirs
4. **Content updates**: All internal references (Perl `use`/`package`, paths in skills/scripts/docs)
5. **Documentation updates**: README, CLAUDE.md, COMMANDS.md, CHANGELOG, BACKLOG, spec
6. **Validation**: Run renamed skills and scripts, verify system works end-to-end

## Risk Assessment

### Medium Priority Risks
- **Broken cross-references**: ~70 files with interconnected references — missing one breaks the system
  - **Mitigation**: Grep for residual `cig` / `.cig/` / `CIG::` references after each milestone
- **Perl module loading failures**: Renaming `CIG::` → `CWF::` affects `use`, `package`, and `lib` paths across all scripts
  - **Mitigation**: Update package declarations and all callers in the same step. Verify with `perl -c` after rename.
- **Security hash invalidation**: `.cig/security/script-hashes.json` contains SHA256 hashes that will change
  - **Mitigation**: Regenerate hashes after all renames. Run `/cwf-security-check`.

### Low Priority Risks
- **Historical docs reference old paths**: Task workflow docs will still say `.cig/`, `CIG::`, etc.
  - **Mitigation**: Intentionally left unchanged. These are historical records.

## Dependencies
- Task 57 (commands→skills): Complete
- Task 58 (Cancelled status): Complete

## Constraints
- Must not modify historical task workflow docs in `implementation-guide/*/`
- Must not break git history (use `git mv` for renames where possible)
- Must preserve file permissions (u+rx on scripts)
- GitHub repo slug change to `coding-with-files` is out of scope (manual GitHub operation)

## Decomposition Check
- [ ] **Time**: >1 week? **No** — 3-5 hours
- [ ] **People**: >2 people? **No**
- [x] **Complexity**: 3+ concerns? **Yes** — structural renames, Perl namespace, content updates, docs, config, validation
- [ ] **Risk**: High-risk components? **No** — wide but shallow
- [x] **Independence**: Parts separable? **Yes** — structural, content, docs, validation are independent milestones

**Decision**: No decomposition. 2 signals triggered but the concerns are sequential steps of a single rename process. The interdependencies (content refers to structure) mean they must be done in order, not in parallel.

## Status
**Status**: Finished
**Next Action**: /cig-requirements-plan 59
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
