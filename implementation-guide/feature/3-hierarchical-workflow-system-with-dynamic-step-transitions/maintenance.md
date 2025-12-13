# Hierarchical Workflow System with Dynamic Step Transitions - Maintenance

## Task Reference
- **Task ID**: internal-3
- **Type**: Feature
- **Status**: Not Started

## Overview

This document provides operational procedures, monitoring guidance, and maintenance tasks for the hierarchical workflow system.

## System Components

### Commands (`.claude/commands/`)
- `cig-new-task.md` - Create top-level tasks
- `cig-subtask.md` - Create hierarchical subtasks
- `cig-plan.md` through `cig-retrospective.md` - 8 workflow commands
- `cig-status.md` - Display hierarchical progress
- `cig-extract.md` - Extract sections (both formats)

### Helper Scripts (`.cig/scripts/command-helpers/`)
- `context-inheritance.sh` - Load parent task context
- `hierarchy-resolver.sh` - Resolve task paths
- `format-detector.sh` - Detect old vs new format
- `status-aggregator.sh` - Calculate progress

### Templates (`.cig/templates/workflow-steps/`)
- `a-plan.md` through `h-retrospective.md` - Workflow file templates

### Configuration
- `cig-project.json` - Project configuration
- `.cig/autoload.yaml` - Module autoloading

## Operational Procedures

### Daily Operations

#### Creating New Tasks
```bash
# Top-level task
/cig-new-task <num> <type> "Description"

# Subtask
/cig-subtask <parent-path> <num> <type> "Description"
```

**Guidelines**:
- Use sequential numbering for top-level tasks
- Use decimal notation for subtasks (1.1, 1.2, etc.)
- Choose appropriate task type (feature, bugfix, hotfix, chore)
- Create only needed workflow files (not all 8 required)

#### Workflow Execution
```bash
# Execute workflow steps in order (or non-linearly as needed)
/cig-plan <task-path>
/cig-requirements <task-path>
/cig-design <task-path>
/cig-implementation <task-path>
/cig-testing <task-path>
/cig-rollout <task-path>
/cig-maintenance <task-path>
/cig-retrospective <task-path>
```

**Guidelines**:
- Follow suggested next steps from each command
- Use context inheritance for nested tasks
- Check decomposition signals before detailed work
- Adapt workflow based on outcomes (non-linear paths OK)

#### Status Monitoring
```bash
# All tasks
/cig-status

# Specific task and descendants
/cig-status <task-path>
```

**Review Frequency**: Daily or before starting work

### Weekly Maintenance

#### System Health Check
```bash
# Verify script integrity
/cig-security-check verify

# Check task structure
/cig-status

# Verify git status
git status
```

**Checklist**:
- [ ] All helper scripts pass SHA256 verification
- [ ] No orphaned task directories
- [ ] Git repository in clean state
- [ ] No permission issues on scripts

#### Documentation Review
- [ ] Update examples if new patterns emerge
- [ ] Review and archive completed tasks if desired
- [ ] Update CLAUDE.md with new insights

### Monthly Maintenance

#### Performance Review
- [ ] Check `/cig-status` performance with full hierarchy
- [ ] Review context inheritance speed for deep hierarchies
- [ ] Identify any slow operations

#### Security Audit
```bash
# Full security check
/cig-security-check report

# Verify permissions
find .cig/scripts -type f -exec ls -la {} \;
```

**Checklist**:
- [ ] All scripts maintain 0500 permissions
- [ ] No unauthorized modifications
- [ ] Version tracking accurate

#### Cleanup Tasks
- [ ] Archive or remove old test tasks
- [ ] Clean up any temporary files
- [ ] Remove completed task branches (if applicable)

## Monitoring & Alerting

### Key Metrics

#### Task Health
- **Active tasks**: Count of in-progress tasks
- **Completion rate**: Tasks completed vs created
- **Average depth**: Mean hierarchy depth
- **Max depth**: Deepest task nesting

**Check with**:
```bash
/cig-status | grep "in-progress"
/cig-status | grep "✓"
```

#### System Health
- **Script integrity**: All scripts verified
- **Permission compliance**: All scripts 0500
- **Format consistency**: Old vs new format distribution

**Check with**:
```bash
/cig-security-check verify
ls -la .cig/scripts/command-helpers/
```

### Error Conditions

#### Common Issues

**Issue**: Command not found
```
Error: /cig-<command> not found
```
**Resolution**:
1. Verify file exists: `ls .claude/commands/cig-<command>.md`
2. Check permissions: `ls -la .claude/commands/`
3. Re-source Claude Code if needed

**Issue**: Path resolution fails
```
Error: Task path not found: 1/1.1
```
**Resolution**:
1. Verify task exists: `ls implementation-guide/`
2. Check path format (use `1/1.1` not `1.1`)
3. Verify parent task exists for subtasks

**Issue**: Context inheritance fails
```
Error: Cannot read parent context
```
**Resolution**:
1. Verify parent task files exist
2. Check file permissions (readable)
3. Verify path resolution working

**Issue**: SHA256 verification fails
```
Warning: Script hash mismatch
```
**Resolution**:
1. **STOP** - Do not use script
2. Verify source: Check git history
3. Re-download from canonical source if needed
4. Update hash in security config

## Troubleshooting

### Debug Mode

Enable verbose output in helper scripts:
```bash
# Add to script for debugging
set -x  # Enable trace mode
```

### Log Analysis

Check command execution:
```bash
# Review recent git commits
git log --oneline -10

# Check file modifications
git status
git diff
```

### Recovery Procedures

#### Corrupted Task Structure
1. Identify affected task: `/cig-status`
2. Check git history: `git log -- implementation-guide/<task>/`
3. Restore from git: `git checkout HEAD -- implementation-guide/<task>/`

#### Lost Context
1. Verify parent files exist
2. Regenerate context manually if needed
3. Document missing pieces

#### Migration Issues
1. Check git log for migration commit
2. Verify `git mv` was used (preserves history)
3. Revert migration if needed: `git revert <commit>`

## Runbooks

### Runbook 1: Add New Workflow Step

**Scenario**: Add new workflow step (e.g., `i-review.md`)

**Steps**:
1. Create template: `.cig/templates/workflow-steps/i-review.md`
2. Update template lists in `cig-new-task.md`
3. Create command: `.claude/commands/cig-review.md`
4. Add to documentation: `COMMANDS.md`
5. Test with new task
6. Update this maintenance guide

### Runbook 2: Migrate Single Task

**Scenario**: Migrate one old-format task to new format

**Steps**:
1. Identify task: `implementation-guide/<type>/<num>-<slug>/`
2. Create target path: `<num>-<type>-<slug>/`
3. Execute migration:
   ```bash
   cd implementation-guide
   git mv <type>/<num>-<slug> <num>-<type>-<slug>
   cd <num>-<type>-<slug>
   git mv plan.md a-plan.md
   git mv requirements.md b-requirements.md  # if exists
   # ... other files
   ```
4. Commit: `git commit -m "Migrate task <num> to new format"`
5. Verify: `/cig-status <num>`

### Runbook 3: Emergency Rollback

**Scenario**: Critical issue requires immediate rollback

**Steps**:
1. **Stop all work** on affected system
2. Identify problematic commit: `git log --oneline`
3. **If not pushed**: `git reset --hard <good-commit>`
4. **If pushed**: `git revert <bad-commit>`
5. Verify system: `/cig-status`
6. Document issue in retrospective
7. Plan fix and re-rollout

### Runbook 4: Add New Task Type

**Scenario**: Add new task type (e.g., "spike")

**Steps**:
1. Update `cig-project.json` supported-task-types
2. Create template list in templates section
3. Create template files if unique workflow needed
4. Update validation in `/cig-new-task`
5. Document in README.md
6. Test creation and workflow

## Backup & Recovery

### What to Backup
- `.cig/` directory (configuration, scripts, templates)
- `.claude/commands/cig-*.md` (commands)
- `implementation-guide/` (all tasks)
- `cig-project.json` (configuration)

### Backup Frequency
- **Git commits**: After every significant change
- **Repository backups**: Handled by git remotes
- **Local backups**: As needed before major changes

### Recovery Process
1. Clone repository fresh
2. Verify `.cig/scripts` permissions (chmod 0500)
3. Run `/cig-security-check verify`
4. Verify `/cig-status` works

## Performance Optimization

### Current Performance Targets
- Status display: <2 seconds for 100 tasks
- Context inheritance: <1 second
- Command execution: <500ms

### If Performance Degrades

#### Slow Status Display
1. Check task count: `find implementation-guide -type d -name "*-*" | wc -l`
2. Profile script: Add timing to status-aggregator.sh
3. Consider caching for large hierarchies

#### Slow Context Inheritance
1. Check hierarchy depth: Deep tasks slower
2. Profile helper script
3. Consider context caching

#### Slow Command Execution
1. Check git repository size
2. Profile individual commands
3. Optimize helper scripts

## Version Updates

### Updating CIG System

**Process**:
1. Check current version: `cat cig-project.json | grep version`
2. Review changelog/release notes
3. Backup current state: `git commit -am "Pre-update backup"`
4. Update files (scripts, commands, templates)
5. Run security check: `/cig-security-check verify`
6. Test with existing tasks
7. Update version in `cig-project.json`
8. Commit: `git commit -m "Update CIG to v<version>"`

### Breaking Changes

If update includes breaking changes:
1. **Read migration guide carefully**
2. Create backup branch: `git branch backup-pre-v<version>`
3. Test on single task first
4. Validate thoroughly before full migration
5. Document any manual steps needed

## Support & Escalation

### Self-Service Resources
1. Check COMMANDS.md for command reference
2. Review scratchpad.md for design rationale
3. Check git history for examples
4. Review this maintenance guide

### When to Escalate
- Security issues (SHA256 mismatches, permission changes)
- Data loss or corruption
- System-wide failures
- Performance degradation >50%

### How to Report Issues
1. Document exact error message
2. Include steps to reproduce
3. Note system state (`/cig-status`, `git status`)
4. Attach relevant logs or output
5. Create GitHub issue (if applicable)

## Continuous Improvement

### Metrics to Track
- Task creation frequency
- Average time per workflow step
- Decomposition frequency (how often subtasks created)
- Common error patterns

### Regular Reviews
- **Monthly**: Review metrics, identify patterns
- **Quarterly**: Major system review, optimization opportunities
- **Yearly**: Architecture review, major improvements

### Improvement Process
1. Identify improvement opportunity
2. Create task: `/cig-new-task <num> chore "Improve X"`
3. Follow workflow (plan → design → implement → test → rollout)
4. Document in retrospective
5. Update maintenance guide

## Decommissioning

### End-of-Life Process

**Not currently planned**, but if needed:

1. **Archive tasks**: Export to static documentation
2. **Document state**: Final `/cig-status` output
3. **Preserve history**: Ensure git history intact
4. **Remove active components**: Delete `.claude/commands/cig-*.md`
5. **Keep documentation**: Maintain README for reference
6. **Final commit**: Mark system as archived

## Notes

- This system is self-documenting through tasks
- Use retrospectives to improve processes
- Update this guide as new patterns emerge
- Trust the workflow, adapt as needed

## Maintenance Status

**Last Review**: Not Started (system not yet deployed)
**Next Review**: After rollout completion
**Status**: Documentation complete, awaiting implementation
