# Fix Task 3 Workflow Docs - Maintenance

## Task Reference
- **Task ID**: internal-7
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/7-fix-task-3-workflow-docs
- **Template Version**: 2.0

## Goal
Ensure task 3 documentation remains accurate and apply lessons learned to future workflow documentation practices.

## Monitoring Requirements

### Documentation Health
- **Accuracy**: Task 3 files reflect actual implementation (periodic review)
- **Completeness**: All 8 workflow files present and no placeholders remain
- **Parser Validation**: Status aggregator shows 100% completion with zero warnings

### Status Aggregator Health
- **Parser Accuracy**: No false positives from status field patterns
- **Performance**: Status calculation completes in <2 seconds
- **Warning Detection**: Any new warnings investigated promptly

### Alerting Rules
- **Critical**: Task 3 shows <100% completion → Immediate investigation required
- **Warning**: Status aggregator warnings detected → Review within 24 hours
- **Info**: Periodic validation (monthly) → Document any drift from implementation

## Maintenance Tasks

### Regular Maintenance Schedule

**Monthly**:
- Run `/cig-status 3` to verify 100% completion
- Verify all 8 task 3 workflow files exist
- Check for placeholder text: `grep -r "To be filled\|To be captured" implementation-guide/3-*`
- Run status aggregator with warning detection: `.cig/scripts/command-helpers/status-aggregator.sh implementation-guide/3-* 2>&1 | grep -i warning`

**Quarterly**:
- Review task 3 documentation accuracy against actual implementation
- Update h-retrospective.md if new insights emerge
- Verify git commit references remain valid

**As Needed**:
- Update task 3 docs if implementation changes (e.g., new features added to CIG system)
- Apply status parser learnings to new tasks (avoid false positive patterns)
- Review and update CLAUDE.md if workflow patterns change

### Preventive Maintenance

**Documentation Hygiene**:
- Avoid using exact status field syntax in examples (use descriptive text instead)
- Use different field names for sub-statuses ("Phase Status", "Maintenance Phase")
- Complete retrospectives immediately after task completion (don't defer)
- Fill actual results and lessons learned before marking tasks finished

**Status Aggregator Validation**:
- Test status aggregator on new tasks before marking complete
- Check for warnings in stderr output
- Validate completion percentages match expected values
- Document any new false positive patterns discovered

## Incident Response

### Common Issues

**Issue 1: Task 3 shows <100% completion**
- **Symptoms**: `/cig-status` shows task 3 at less than 100%
- **Diagnosis**: Run status aggregator, check for missing/incorrect status markers
- **Resolution**: Review all 8 files for proper status markers, fix any "In Progress" or missing statuses

**Issue 2: Status aggregator warnings**
- **Symptoms**: Warnings about multiple status markers or unknown status values
- **Diagnosis**: Check for status field patterns in examples, phase markers, or documentation
- **Resolution**: Rename conflicting fields, use descriptive text instead of exact syntax

**Issue 3: Placeholder text discovered**
- **Symptoms**: grep finds "To be filled" or "To be captured" in task 3 files
- **Diagnosis**: Incomplete documentation update
- **Resolution**: Fill in actual content based on implementation and git history

### Troubleshooting Guide

**Symptom**: Task 3 completion percentage changed unexpectedly
- **Diagnosis**: Check git diff for recent changes to task 3 files, review status markers
- **Tools**: `git log implementation-guide/3-*`, `git diff HEAD~1 implementation-guide/3-*`
- **Resolution**: Restore correct status markers if changed incorrectly

**Symptom**: New false positives in status aggregator
- **Diagnosis**: Check recent changes for new status field patterns
- **Tools**: `grep -rn '^\*\*Status\*\*:' implementation-guide/3-*`
- **Resolution**: Apply renaming pattern (e.g., "Phase Status" for phase markers)

## Knowledge Base

### Status Parser False Positive Patterns

**Patterns to Avoid**:
- Exact status field syntax in code examples → Use descriptive text instead
- Status markers in phase headers → Use "Phase Status" field instead
- Status markers in nested sections → Use different field names
- Backtick-enclosed status patterns → Parser still picks them up

**Safe Alternatives**:
- "status markers set to Finished" (descriptive text)
- "Phase Status" or "Rollout Phase" (different field name)
- "Maintenance Phase" instead of "Maintenance Status"

### Historical Reconstruction Best Practices

**Data Sources**:
- Git commit history (messages, dates, file changes)
- Observable artifacts (files, directories, deliverables)
- Existing workflow files (plan estimates, requirements, design decisions)
- Git log for specific files: `git log --follow -- path/to/file`

**Validation**:
- Cross-reference git commits mentioned in retrospectives
- Verify file counts and directory structures
- Check deliverables actually exist
- Validate dates against git commit timestamps

## Support Contacts

**Primary**: Project maintainer (Matt)
**Escalation**: N/A (internal documentation task)
**Documentation**: See task 7 workflow files for complete context

## Continuous Improvement

### Metrics to Track
- Task 3 completion percentage (target: 100%)
- Status aggregator warning count (target: 0)
- Placeholder text occurrences (target: 0)
- Monthly validation pass rate (target: 100%)

### Improvement Opportunities
- Automate monthly validation checks (cron job or CI/CD)
- Create status aggregator test suite to catch false positive patterns
- Document additional false positive patterns as discovered
- Consider status aggregator enhancement to ignore examples/code blocks

## Decommissioning

**Not Applicable**: Documentation maintenance is ongoing. Task 3 files will be maintained as long as CIG system is in use.

## Status
**Status**: Finished
**Next Action**: N/A - Maintenance phase documented, move to retrospective
**Blockers**: None
