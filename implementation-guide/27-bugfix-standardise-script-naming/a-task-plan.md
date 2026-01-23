# Standardise Script Naming - Plan

## Task Reference
- **Task ID**: internal-27
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/27-standardise-script-naming
- **Template Version**: 2.0

## Goal
Remove file extensions from all CIG helper scripts and standardize invocation using portable shebangs with environment configuration.

## Success Criteria
- [ ] All 6 helper scripts renamed without extensions (5 `.pl` + 1 `.sh`)
- [ ] PERL5OPT configured in `.claude/settings.json` for Unicode handling
- [ ] All Perl shebangs updated to `#!/usr/bin/env perl` (portable)
- [ ] Shell shebang updated to `#!/usr/bin/env bash` (portable)
- [ ] All references fixed throughout entire repo (excluding historic task documents):
  - [ ] Command files (`.claude/commands/*.md`)
  - [ ] Documentation (CLAUDE.md, README.md)
  - [ ] BACKLOG.md
  - [ ] Workflow documentation (`.cig/docs/`)
  - [ ] Template files (`.cig/templates/`)
  - [ ] Any other non-historic references
- [ ] Unicode test passes (Perl scripts handle UTF-8 correctly)
- [ ] No grep hits for "*.pl" or "*.sh" in active references (excluding `implementation-guide/[0-9]*`)

## Original Estimate
**Effort**: 2-3 hours (Quick Win task)
**Complexity**: Low (mechanical changes, clear checklist)
**Dependencies**:
- Task 26 (BACKLOG entry created)
- `.claude/settings.json` must support `env` configuration

## Major Milestones
1. **Environment Configured**: PERL5OPT added to `.claude/settings.json`
2. **Scripts Renamed**: All 6 scripts renamed without extensions (5 `.pl` + 1 `.sh`)
3. **References Updated**: Comprehensive update across entire repo (excluding historic tasks)
   - Search strategy: `grep -r "\.pl\|\.sh" --exclude-dir=implementation-guide`
   - Update: Commands, docs, BACKLOG, templates, workflow documentation
4. **Validation Complete**: Unicode test passes, no broken references remain

## Risk Assessment
### High Priority Risks
- **Breaking command references**: Renaming scripts breaks all command file references
  - **Mitigation**: Use systematic search/replace, test each command after update

### Medium Priority Risks
- **PERL5OPT not applied**: Environment variable doesn't propagate to script execution
  - **Mitigation**: Test with `perl -V` and Unicode echo test before proceeding
- **Missed references**: References in docs, templates, or other files not updated
  - **Mitigation**: Use comprehensive grep search excluding historic tasks: `grep -r "\.pl\|\.sh" --exclude-dir=implementation-guide`
  - **Verification**: After updates, run same grep to confirm no hits (except historic docs)

## Dependencies
- **Claude Code settings.json**: Must support `env` configuration (documented feature)
- **Perl installation**: Scripts require perl in PATH for `#!/usr/bin/env perl`
- **Git working tree**: Clean state recommended for script renames

## Constraints
- **Unix-only**: This system requires Unix environment (Linux, macOS, WSL)
- **Historic documents excluded**: Old references in `implementation-guide/[0-9]*` task directories will remain stale (acceptable - represents historical record)
- **Active references only**: All references outside historic task dirs must be updated
- **Template files unchanged**: `.template` files keep extensions (data files, not executables)
- **Executable names only**: Only script files themselves are renamed, not template or data files

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 2-3 hours
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - single concern: standardize naming
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low risk, reversible changes
- [ ] **Independence**: Can parts be worked on separately? **No** - all parts depend on each other

**Decomposition Analysis**: 0/5 signals triggered

**Recommendation**: Task should proceed as single unit (Quick Win)

## Status
**Status**: Finished
**Next Action**: Proceed to design phase → `/cig-design-plan 27`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

### Planning Completed
- **Scope expanded**: Discovered 6 scripts total (5 `.pl` + 1 `.sh`), not just 4
  - hierarchy-resolver.pl
  - context-inheritance.pl
  - template-copier.pl
  - format-detector.pl
  - status-aggregator.pl
  - template-version-parser.sh
- **Comprehensive reference update required**: All references throughout repo (excluding historic task dirs)
  - Command files, documentation, BACKLOG, templates, workflow docs
  - Historic tasks (`implementation-guide/[0-9]*`) will retain old references (acceptable)
- **Quick Win confirmed**: 2-3 hours estimated, all mechanical changes
- **No decomposition needed**: 0/5 signals triggered, proceed as single unit
- **Foundation task**: Part of Phase 1 preparation for skills migration

### Scripts to Rename
**Perl scripts** (5 files):
- `hierarchy-resolver.pl` → `hierarchy-resolver`
- `context-inheritance.pl` → `context-inheritance`
- `template-copier.pl` → `template-copier`
- `format-detector.pl` → `format-detector`
- `status-aggregator.pl` → `status-aggregator`

**Shell scripts** (1 file):
- `template-version-parser.sh` → `template-version-parser`

**Already correct** (3 files):
- `status-aggregator` (no extension)
- `status-aggregator-v2.0` (no extension)
- `status-aggregator-v2.1` (no extension)

## Lessons Learned
*To be captured during retrospective*
