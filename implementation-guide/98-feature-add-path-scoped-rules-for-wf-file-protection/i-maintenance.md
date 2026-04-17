# Add path-scoped rules for wf file protection - Maintenance
**Task**: 98 (feature)

## Task Reference
- **Task ID**: internal-98
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/98-add-path-scoped-rules-for-wf-file-protection
- **Template Version**: 2.1

## Goal
Define ongoing maintenance for the path-scoped rule file and install pipeline integration.

## Monitoring Requirements
### Rule Effectiveness
- Observe whether the agent invokes skills instead of editing wf step files directly
- The rule is advisory — compliance is not guaranteed, only encouraged
- No automated metrics; effectiveness observed through agent behaviour and rework frequency

## Maintenance Tasks
### As Needed
- **Update rule content**: Edit `.claude/rules/cwf-workflow-files.md` if skill names change or new wf steps are added
- **Update glob pattern**: If task directory structure changes (currently `implementation-guide/**/{a,b,c,d,e,f,g,h,i,j}-*.md`)
- **Update symlink pattern**: If `.cwf-rules/` staging directory convention changes

### After Each CWF Release
- Verify `install.bash` correctly splits and installs `.claude/rules/` via subtree
- Verify `create_rule_symlinks` (or its replacement) creates symlinks correctly
- Verify cwf-init step 6b creates rules directory and symlinks in target projects

## Common Issues
### Rule Not Loading
- **Symptom**: Agent edits wf step files without skill reminder appearing
- **Diagnosis**: Check `.claude/rules/cwf-workflow-files.md` exists and has correct YAML frontmatter with `globs` field
- **Resolution**: Verify symlink resolves (`ls -la .claude/rules/cwf-workflow-files.md`), recreate if broken

### Glob Pattern Mismatch
- **Symptom**: Rule loads for wrong files or doesn't load for wf step files
- **Diagnosis**: Check glob `implementation-guide/**/{a,b,c,d,e,f,g,h,i,j}-*.md` against actual file paths
- **Resolution**: Update glob in rule frontmatter; verify with Claude Code's rule matching

### Symlink Broken After Install
- **Symptom**: `.claude/rules/cwf-workflow-files.md` exists but is a broken symlink
- **Diagnosis**: `readlink .claude/rules/cwf-workflow-files.md` — check target exists
- **Resolution**: Re-run cwf-init step 6b, or manually recreate: `ln -s ../../.cwf-rules/cwf-workflow-files.md .claude/rules/cwf-workflow-files.md`

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 98
**Blockers**: None

## Actual Results
Maintenance procedures documented. No automated monitoring needed.

## Lessons Learned
Rule file is low-maintenance — only needs updating when new wf step prefixes are added. Symlink install means updates propagate automatically on reinstall.
