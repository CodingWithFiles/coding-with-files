# Add PreToolUse hook for rule re-injection - Maintenance
**Task**: 99 (feature)

## Task Reference
- **Task ID**: internal-99
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/99-add-pretooluse-hook-for-rule-re-injection
- **Template Version**: 2.1

## Goal
Define ongoing maintenance for the rules injection hook and rules file.

## Monitoring Requirements
### Rule Effectiveness
- Observe whether the agent follows the 4 injected rules during sessions
- Compare rule adherence in long sessions (post-compaction) vs short sessions
- No automated metrics — effectiveness is observed through agent behaviour

### Token Cost
- Rules file is 5 lines; injected as system reminder on every user message
- Monitor whether token cost is noticeable in long sessions
- If cost becomes a concern, reduce rules to the most critical subset

## Maintenance Tasks
### As Needed
- **Update rules content**: Edit `.cwf/rules-inject.txt` when recurring process errors change
- **Add/remove rules**: Keep file under 10 lines (NFR1) — every line costs tokens per turn
- **Update cwf-init step 6c**: If Claude Code hook format changes in future versions

### After Each CWF Release
- Verify `install.bash` correctly splits and installs `.cwf/rules-inject.txt` via `.cwf/` subtree
- Verify `create_cwf_symlinks` still creates rule symlinks correctly

## Common Issues
### Hook Not Firing
- **Symptom**: Rules not appearing as system reminders
- **Diagnosis**: Check `.claude/settings.json` for `hooks.PreToolUse` with `UserPromptSubmit` matcher
- **Resolution**: Re-run `/cwf-init` step 6c or manually add hook configuration

### Rules File Missing
- **Symptom**: No rules injected but no errors either (silent failure by design)
- **Diagnosis**: Check `.cwf/rules-inject.txt` exists
- **Resolution**: Re-install CWF or recreate the file

### Rules Not Surviving Compaction
- **Symptom**: Agent stops following rules after compaction
- **Diagnosis**: This should not happen — hook re-injects on every message regardless of compaction
- **Resolution**: Verify hook is on `UserPromptSubmit` (fires per message, not per tool call)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 99
**Blockers**: None

## Actual Results
Maintenance procedures documented. No automated monitoring needed — effectiveness is observed.

## Lessons Learned
- Rule effectiveness can only be observed through agent behaviour, not automated metrics
