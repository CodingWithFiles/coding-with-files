# add-task-stack-script - Maintenance

## Task Reference
- **Task ID**: internal-34
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/34-add-task-stack-script
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for add-task-stack-script.

## Monitoring Requirements

### System Health
- **Availability**: Local development tool - no uptime requirements (runs on-demand)
- **Performance**: Operations complete in <100ms (currently ~12-13ms)
- **Resource Usage**: Minimal footprint - file-based storage, no persistent processes

### Application Metrics
- **Usage Visibility**: Task 32 inference provides indirect monitoring (state signal usage)
- **Adoption**: Track `/cig-current-task` skill invocations via Claude Code logs
- **Error Detection**: Script exit codes and stderr output for error tracking
- **File Health**: `.cig/task-stack` file integrity (valid dirname format per line)

### Alerting Rules
- **Critical**: File corruption (unparseable format) - would affect Task 32 inference
- **Warning**: Performance degradation (>100ms operations) - indicates scaling issues
- **Info**: Invalid task push attempts - user education opportunity

### Monitoring Methods
1. **Task 32 Integration**: State signal provides visibility into stack usage
2. **Script Exit Codes**: Non-zero exit indicates errors (empty stack, invalid task)
3. **File Integrity**: Stack file should parse cleanly (one dirname per line)
4. **Security Validation**: `/cig-security-check verify` ensures script hash matches

## Maintenance Tasks

### Regular Maintenance Schedule
- **As-Needed**: No daily/weekly maintenance required (stateless script)
- **Per-Release**: Update security hashes when script modified
- **Quarterly**: Review performance characteristics if usage patterns change
- **Annually**: Review design assumptions (file size limits, operation performance)

### Preventive Maintenance
- **Stack File Cleanup**: User responsibility (clear old entries manually)
- **Security Validation**: Run `/cig-security-check verify` after script updates
- **Performance Testing**: Re-run performance tests if Perl version changes
- **Documentation Updates**: Keep CLAUDE.md and skill docs current

### No Maintenance Required For
- Log rotation (no persistent logs)
- Database optimization (no database)
- Backup/restore (file is gitignored, user-specific)
- Dependency updates (core Perl modules only)

## Incident Response

### Common Issues

**Issue 1: Stack File Corrupted**
- **Symptoms**: Task 32 inference fails, list operation shows garbled output
- **Diagnosis**: Check `.cig/task-stack` - look for invalid dirname format
- **Resolution**:
  1. Run `task-stack clear` to reset
  2. Re-push current tasks
  3. Verify with `task-stack list`
- **Prevention**: Use `/cig-current-task` skill instead of direct edits

**Issue 2: Empty Stack Pop Error**
- **Symptoms**: Error message "stack is empty" when running pop
- **Diagnosis**: Run `task-stack size` to confirm stack is empty
- **Resolution**:
  1. Push current task with `task-stack push <num>`
  2. Verify with `task-stack list`
- **Prevention**: Check stack size before pop operations

**Issue 3: Invalid Task Number**
- **Symptoms**: Error "task XXXX not found" when pushing
- **Diagnosis**: Task number doesn't exist in implementation-guide/
- **Resolution**:
  1. Verify task exists: `ls implementation-guide/*<num>*`
  2. Use correct task number
  3. Create task if needed: `/cig-new-task <num> <type> "description"`
- **Prevention**: Use tab completion or `/cig-status` to verify task numbers

**Issue 4: Performance Degradation**
- **Symptoms**: Operations take >100ms
- **Diagnosis**: Check stack size with `wc -l .cig/task-stack`
- **Resolution**:
  1. If >1000 entries, consider clearing old entries
  2. Run performance test: `/tmp/perf-test.sh`
  3. Review file system performance
- **Prevention**: Periodically clear completed tasks from stack

**Issue 5: Task 32 Inference Not Using Stack**
- **Symptoms**: State signal shows "null" in verbose output
- **Diagnosis**: Check if `.cig/task-stack` exists and has content
- **Resolution**:
  1. Verify file exists: `ls -la .cig/task-stack`
  2. Push current task: `task-stack push <num>`
  3. Test inference: `task-context-inference --verbose`
- **Prevention**: Ensure tasks are pushed to stack during active work

### Troubleshooting Guide

**Symptom: Script Permission Denied**
- **Diagnosis**: Check permissions with `ls -la .cig/scripts/command-helpers/task-stack`
- **Resolution**: Fix permissions with `chmod 755 .cig/scripts/command-helpers/task-stack`

**Symptom: "Cannot locate CIG/TaskPath.pm"**
- **Diagnosis**: Perl module path issue
- **Resolution**:
  1. Verify Task 33 installed: `ls .cig/lib/CIG/TaskPath.pm`
  2. Check script uses correct path: `use lib "$FindBin::Bin/../../lib"`

**Symptom: File Lock Timeout**
- **Diagnosis**: Another process holds flock on `.cig/task-stack`
- **Resolution**:
  1. Check for stuck processes: `lsof .cig/task-stack`
  2. Kill if necessary, then retry operation

### Escalation Procedures
- **Level 1 (User Self-Service)**:
  - Check error message and consult troubleshooting guide
  - Use `task-stack clear` to reset if corrupted
  - Review CLAUDE.md file protection advisory

- **Level 2 (Internal Developer)**:
  - Review implementation in f-implementation-exec.md
  - Check test results in g-testing-exec.md
  - Verify security hashes: `/cig-security-check verify`

- **Level 3 (Critical Issue)**:
  - File corruption affecting Task 32: Rollback to pre-Task-34 state
  - Security vulnerability: Update script and security hashes immediately
  - Performance regression: Review implementation for inefficiencies

## Performance Optimisation

### Current Performance Characteristics
- **Baseline**: ~12-13ms per operation with 100 entries
- **Target**: <100ms per operation (8x headroom)
- **Bottlenecks**: File I/O (read entire file on each operation)
- **Scalability**: Linear degradation with file size

### Optimization Opportunities
1. **Large Stack Handling** (>1000 entries):
   - Consider binary format or index file
   - Implement pagination in list operation
   - Add archive/compress old entries feature

2. **Concurrent Access**:
   - Current: flock serializes all operations
   - Future: Consider reader/writer locks if needed
   - Unlikely bottleneck (single-user tool)

3. **File Format**:
   - Current: Plain text (human-readable, grep-able)
   - Alternative: JSON/YAML for structured metadata
   - Trade-off: Simplicity vs extensibility

### Scaling Strategy
- **Current Capacity**: Tested to 100 entries, no performance issues
- **Expected Growth**: <100 entries typical (periodic cleanup expected)
- **Scaling Approach**: Vertical (file-based, single-user)
- **Capacity Planning**: Monitor if users report >1000 entries

### When to Optimize
- Performance degrades below 100ms threshold
- Stack files regularly exceed 1000 entries
- Concurrent access becomes bottleneck (unlikely)
- User feedback indicates slowness

## Documentation

### Runbooks

**Daily Operations** (User-Facing):
```bash
# Push current task onto stack
/cig-current-task push 34

# Show current stack
/cig-current-task

# Pop completed task
/cig-current-task pop

# Clear entire stack (context switch)
/cig-current-task clear
```

**Emergency Procedures**:
```bash
# Reset corrupted stack
.cig/scripts/command-helpers/task-stack clear

# Verify script integrity
/cig-security-check verify

# Check Task 32 integration
.cig/scripts/command-helpers/task-context-inference --verbose

# Rollback if needed (post-merge)
git revert <commit-hash>
```

**Maintenance Checklist**:
- [ ] After script modifications: Update security hashes
- [ ] After Perl upgrades: Re-run performance tests
- [ ] Quarterly: Review stack usage patterns
- [ ] Annually: Validate design assumptions

### Knowledge Base

**Location**: Implementation guide files
- **Architecture**: `implementation-guide/34-.../c-design-plan.md`
- **Requirements**: `implementation-guide/34-.../b-requirements-plan.md`
- **Implementation**: `implementation-guide/34-.../f-implementation-exec.md`
- **Testing**: `implementation-guide/34-.../g-testing-exec.md`

**Key Design Decisions**:
1. File-based LIFO stack (simplicity over database)
2. Dirname format storage (preserves full task context)
3. flock for atomicity (prevents race conditions)
4. Self-documenting output (teaches agent discovery)
5. Graceful degradation (works without stack file)

**Performance Characteristics**:
- Operations: ~12-13ms with 100 entries
- Tested capacity: 100 entries
- Scaling: Linear with file size
- Optimization threshold: 100ms per operation

**Integration Points**:
- Task 32 inference: State signal (score 85)
- `/cig-init`: Gitignore management
- `/cig-current-task`: User-facing skill wrapper
- Security tracking: Script hash verification

**Common Patterns**:
```bash
# Context switch workflow
/cig-current-task push 34    # Save current
/cig-current-task push 35    # Work on urgent task
/cig-current-task pop        # Return to 35
/cig-current-task pop        # Return to 34

# Stack inspection
/cig-current-task            # Show last 5 tasks
.cig/scripts/command-helpers/task-stack size  # Get count
.cig/scripts/command-helpers/task-stack peek  # See top

# Cleanup
/cig-current-task clear      # Start fresh
```

## Success Criteria
- [x] Monitoring strategy defined (Task 32 integration, exit codes, file integrity)
- [x] Maintenance procedures documented (minimal maintenance required)
- [x] Common issues and resolutions documented (5 common issues + troubleshooting)
- [x] Performance baseline established (~12-13ms, 8x faster than target)
- [x] Runbooks created (daily operations, emergency procedures)
- [x] Knowledge base organized (design docs, test results, integration points)

## Status
**Status**: Finished
**Next Action**: Move to retrospective → `/cig-retrospective 34`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

### Maintenance Strategy Defined
Comprehensive maintenance documentation completed covering:
- Monitoring requirements and methods
- Minimal ongoing maintenance needs
- 5 common issues with troubleshooting procedures
- Performance optimization opportunities
- Complete runbooks and knowledge base

### Key Maintenance Characteristics
1. **Low Maintenance**: Stateless script requires minimal ongoing support
2. **Self-Monitoring**: Task 32 integration provides visibility
3. **User Self-Service**: Clear error messages enable user troubleshooting
4. **Simple Recovery**: `clear` operation resets corrupted state

### Monitoring Implementation
- Task 32 state signal provides indirect monitoring (score 85)
- Script exit codes indicate errors
- File integrity validation via security hashes
- No additional monitoring infrastructure required

### Support Model
- Level 1: User self-service via error messages and troubleshooting guide
- Level 2: Developer review of implementation documentation
- Level 3: Rollback procedure for critical issues

## Lessons Learned

### Maintenance Design
1. **Simplicity reduces maintenance burden**: File-based design eliminates database/server maintenance
2. **Self-documenting output aids troubleshooting**: Script path in output helps users understand tooling
3. **Graceful degradation reduces support load**: System works without stack file (Task 32 fallback)
4. **Clear error messages enable self-service**: "stack is empty" more helpful than generic errors

### Monitoring Insights
1. **Integration provides monitoring**: Task 32 inference integration doubles as health check
2. **Exit codes are sufficient**: Simple CLI tool doesn't need complex monitoring
3. **File integrity is key metric**: Stack file corruption is main failure mode
4. **Performance headroom reduces alerts**: 8x faster than target means unlikely performance issues

### Documentation Value
1. **Runbooks prevent repetitive questions**: Common patterns documented reduce support burden
2. **Troubleshooting guide accelerates resolution**: 5 common issues cover most scenarios
3. **Knowledge base location matters**: Linking to implementation docs preserves context
4. **Emergency procedures critical**: Clear rollback procedure reduces incident response time

### Future Maintenance Considerations
1. **Stack growth patterns unknown**: May need optimization if usage exceeds expectations
2. **Perl version sensitivity**: Performance tests should be re-run after Perl upgrades
3. **User education ongoing**: File protection advisory in CLAUDE.md may need reinforcement
4. **Cleanup responsibility**: User must manage old stack entries (no auto-expiry)
