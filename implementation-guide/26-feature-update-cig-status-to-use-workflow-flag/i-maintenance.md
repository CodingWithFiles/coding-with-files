# Update cig-status to Use --workflow Flag - Maintenance

## Task Reference
- **Task ID**: internal-26
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/26-update-cig-status-to-use-workflow-flag
- **Template Version**: 2.0

## Goal
Define ongoing maintenance, monitoring, and support requirements for Update cig-status to Use --workflow Flag.

## Monitoring Requirements

**Not Applicable**: Internal CLI tool with no telemetry infrastructure.

### Manual Observation
Maintenance relies on user observation during normal usage:
- **Functional**: Commands execute without errors during daily use
- **Performance**: Commands respond quickly (subjectively <500ms)
- **Reliability**: No unexpected failures or incorrect output

### Issue Detection
- **During routine use**: Repository owner observes any unexpected behaviour
- **Git tracking**: Changes tracked via version control for rollback capability
- **BACKLOG monitoring**: Known limitations tracked for future resolution
  - TC-F11: Interface-based version dispatch (Medium priority)
  - Template ordering fix (High priority)

## Maintenance Tasks

**Minimal Maintenance Required**: Local CLI tool with no infrastructure dependencies.

### As-Needed Maintenance
No regular maintenance schedule required. Maintenance triggered by:
- **Bug reports**: User discovers issues during normal usage
- **Feature requests**: User identifies enhancement opportunities
- **BACKLOG review**: Periodic review of documented known limitations
- **CIG system updates**: When core CIG infrastructure changes

### Code Maintenance
- **Git history**: All changes tracked, rollback available via git revert
- **Testing validation**: Re-run test cases if behaviour changes
- **Documentation updates**: Keep cig-status.md synchronized with implementation
- **Script permissions**: Verify helper scripts maintain u+rx permissions (0500+)

## Incident Response

### Known Limitations
1. **TC-F11: Mixed-version workflow display**
   - **Symptom**: `/cig-status --workflow` without task argument shows workflow breakdown only for tasks matching detected version
   - **Root Cause**: Version detection happens once at trampoline level, not per-task
   - **Impact**: Minimal - primary use case (single-task queries) works correctly
   - **Workaround**: Use task-specific queries (`/cig-status <task-path>`)
   - **Resolution**: BACKLOG entry "Implement Interface-Based Version Dispatch for status-aggregator"

### Troubleshooting Guide

**Symptom**: `/cig-status` exits with non-zero code
- **Diagnosis**: Check stderr output for error messages
- **Resolution**: Verify status-aggregator script permissions (u+rx), check for corrupted task files

**Symptom**: Workflow breakdown not shown for task-specific query
- **Diagnosis**: Run `status-aggregator --workflow <task-path>` directly to see raw output
- **Resolution**: Verify task has workflow files (a-h for v2.0, a-j for v2.1)

**Symptom**: Performance degradation (>2 seconds)
- **Diagnosis**: Test with individual commands: `status-aggregator <task-path>`, `status-aggregator --workflow <task-path>`
- **Resolution**: Check for filesystem issues, verify no concurrent heavy I/O operations

### Escalation Procedures
**Single-user tool**: No formal escalation. User investigates issues using:
1. Review g-testing-exec.md (test cases and expected behaviour)
2. Review e-implementation-exec.md (implementation details and known limitations)
3. Check BACKLOG.md for known issues
4. Create new bug task if issue not documented

## Performance Optimisation

### Current Performance
- **Baseline**: 182ms (default mode), 33ms (task-specific with --workflow)
- **Target**: <500ms (subjectively instant)
- **Status**: Well within acceptable range, no optimization required

### Future Optimisation Opportunities
**If performance degrades**:
- **Caching**: Cache task hierarchy traversal results (currently regenerated each call)
- **Parallel processing**: Process multiple tasks concurrently for default mode
- **Incremental updates**: Track changed tasks since last invocation

**Not currently needed**: Performance exceeds requirements by 2.7x-15x margin.

### Scaling Considerations
**Not applicable**: Local CLI tool processes single repository.

**If supporting multiple repositories**:
- Maintain per-repository caches
- Limit default mode to N most recent tasks per repository
- Consider background indexing for large repositories

## Documentation

### Runbooks
**Embedded in task documentation**:
- **User guide**: `.claude/commands/cig-status.md` - Command usage and examples
- **Implementation**: `e-implementation-exec.md` - Technical details and design decisions
- **Testing**: `g-testing-exec.md` - Test cases and expected behaviour
- **Troubleshooting**: This file (i-maintenance.md) - Common issues and resolutions

### Knowledge Base
**Task 26 implementation guide serves as knowledge base**:
- **Design rationale**: `c-design-plan.md` - Intelligent defaults design
- **Test coverage**: `f-testing-plan.md` - Comprehensive test matrix
- **Known limitations**: `g-testing-exec.md`, BACKLOG.md - TC-F11 and future work
- **Architecture**: `e-implementation-exec.md` - Status aggregator integration

### Future Documentation Needs
**If BACKLOG items implemented**:
- Update cig-status.md with interface-based dispatch behaviour
- Document per-task version detection when TC-F11 is resolved
- Update testing plan with new test cases for interface dispatch

## Success Criteria
- [x] Monitoring approach defined (manual observation during usage)
- [x] Maintenance procedures documented (as-needed, git-based)
- [x] Known limitations documented with troubleshooting steps
- [x] Performance baseline established (182ms/33ms << 500ms target)
- [x] Runbooks embedded in task documentation
- [x] Knowledge base established (implementation guide files)

## Status
**Status**: Finished
**Next Action**: Proceed to retrospective phase
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

### Maintenance Strategy
**Minimal maintenance approach** selected for internal CLI tool:
- No automated monitoring infrastructure (not cost-effective for single-user tool)
- Manual observation during routine usage
- Git-based change tracking and rollback capability
- As-needed maintenance triggered by user observations

### Key Decisions
1. **No telemetry**: Local CLI tool doesn't warrant instrumentation overhead
2. **Documentation-first troubleshooting**: Known limitations documented in implementation guide
3. **BACKLOG-driven improvements**: Structured approach to future enhancements
4. **Embedded runbooks**: Task documentation serves as operational guide

### Documented Artifacts
- ✅ Known limitation (TC-F11) with troubleshooting steps
- ✅ Performance baseline (182ms/33ms)
- ✅ Troubleshooting guide for common issues
- ✅ References to implementation and testing documentation
- ✅ Future optimization opportunities identified (caching, parallel processing)

### Maintenance Readiness
All success criteria met:
- Monitoring approach: Manual observation strategy
- Maintenance procedures: As-needed, git-based workflow
- Incident response: Troubleshooting guide and escalation to BACKLOG
- Performance: Baseline established, well within target
- Documentation: Complete runbooks embedded in task files

## Lessons Learned
*To be captured during retrospective*
