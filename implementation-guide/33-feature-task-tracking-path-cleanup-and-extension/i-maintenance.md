# task-tracking-path-cleanup-and-extension - Maintenance

## Task Reference
- **Task ID**: internal-33
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/33-task-tracking-path-cleanup-and-extension
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for task-tracking-path-cleanup-and-extension.

## Monitoring Requirements

### System Health (Internal Library - Lightweight Monitoring)
- **Availability**: Library available whenever git repository accessible
- **Performance**: Task resolution < 50ms (current: 0.043ms, 1000x headroom)
- **Resource Usage**: Minimal (pure Perl, no external dependencies)

### Application Metrics
- **Functional Correctness**: CIG commands execute without errors
- **API Stability**: Backward compatibility maintained (resolve() alias)
- **Test Coverage**: 100% maintained across all implemented functions
- **Performance**: Sub-millisecond task resolution maintained

### Alerting Rules (Manual/Git-Based)
- **Critical**: CIG commands fail with Perl errors → Immediate investigation
- **Warning**: Performance degradation > 10ms → Review during next update
- **Info**: Version mismatches detected → Note in backlog for cleanup

## Maintenance Tasks

### Regular Maintenance Schedule (Internal Library)
- **Daily**: None required (library is static until code changes)
- **Weekly**: None required
- **Monthly**: None required
- **Quarterly**: Review for optimization opportunities during major CIG updates
- **As-Needed**: Update when bugs discovered or enhancements requested

### Preventive Maintenance
- **Code Quality**: Maintain test coverage at 100%
- **Backward Compatibility**: Maintain resolve() alias, avoid breaking changes
- **Performance**: Monitor task resolution times during normal CIG usage
- **Security**: Validate path traversal protections remain effective
- **Documentation**: Keep inline comments synchronized with code changes

## Incident Response

### Common Issues
- **Issue 1: Task resolution returns undef unexpectedly**
  - Symptoms: CIG commands fail to find tasks that exist
  - Resolution: Check glob pattern in build_glob(), verify flat directory structure
  - Prevention: Comprehensive test suite includes hierarchical scenarios

- **Issue 2: Tree traversal returns incorrect order**
  - Symptoms: find_descendants returns wrong child ordering
  - Resolution: Verify depth-first pre-order logic (child then descendants)
  - Prevention: Test suite validates traversal order

- **Issue 3: Performance degradation**
  - Symptoms: Task resolution > 50ms
  - Resolution: Profile with Devel::NYTProf, check filesystem performance
  - Prevention: Performance test in test suite (currently 0.043ms)

### Troubleshooting Guide

**Symptom**: CIG command fails with "Can't locate CIG/TaskPath.pm"
- **Diagnosis**: Module path issue or file permissions
- **Resolution**:
  1. Verify file exists: `ls -l .cig/lib/CIG/TaskPath.pm`
  2. Check permissions: Should be u+rx (minimum 0500)
  3. Verify @INC includes `.cig/lib`: `perl -I.cig/lib -MCIG::TaskPath -e 'print "OK\n"'`

**Symptom**: Task resolution returns undef for valid task
- **Diagnosis**: Glob pattern mismatch or directory name format
- **Resolution**:
  1. Test glob directly: `perl -e 'print glob("implementation-guide/1.1-*-*")'`
  2. Check directory name format: Must be `NUM-TYPE-SLUG`
  3. Verify normalize() and validate() accept the task number

### Escalation Procedures
- **Level 1**: User reports issue → Check common issues list, run test suite
- **Level 2**: Issue not in common list → Create minimal reproduction case, analyze with test suite
- **Level 3**: Fundamental design issue → Create new task for investigation and fix

## Performance Optimisation

### Optimisation Areas (Future Considerations)
- **Glob Pattern Efficiency**: Currently using simple flat pattern (0.043ms)
  - Future: If repository grows to 10,000+ tasks, consider indexing
  - Current headroom: 1000x better than 50ms target

- **Caching Strategy**: Currently no caching (YAGNI principle applied)
  - Future: If performance degrades, consider memoization of resolve_num()
  - Invalidation: Would need to detect file system changes

- **Parallel Tree Traversal**: Currently sequential depth-first
  - Future: Unlikely to be needed (tree depth typically < 5)
  - Current performance adequate for typical usage

### Scaling Strategy
- **Not Applicable**: Internal library scales with repository size
- **Current Capacity**: Tested with hierarchical tasks up to depth 3
- **Growth Projection**: Expected task count < 1000 (current: ~50)
- **Scaling Trigger**: Performance > 10ms would trigger optimization review
- **Approach**: Optimize glob patterns, add caching layer if needed

## Documentation

### Runbooks
- **Operational Procedures**:
  - Running test suite: `perl test_complete.t` in test directory
  - Verifying installation: `perl -I.cig/lib -MCIG::TaskPath -e 'print "OK\n"'`
  - Performance benchmarking: Use test suite timing output

- **Emergency Response**:
  - Critical failure: Rollback via git revert (< 5 minutes)
  - Test failures: Re-run comprehensive test suite for diagnostics
  - Performance issues: Profile with Devel::NYTProf

- **Maintenance Checklists**:
  - Before changes: Run full test suite (41 assertions)
  - After changes: Verify backward compatibility (resolve() alias)
  - Before release: Check performance meets < 50ms target

### Knowledge Base
- **Architecture Decisions**:
  - c-design-plan.md:187 - Orthogonal API design principle
  - c-design-plan.md:201 - Optional base_dir parameter convention
  - c-design-plan.md:214 - Functional composition approach

- **Implementation Details**:
  - .cig/lib/CIG/TaskPath.pm:79 - build_glob() flat structure
  - .cig/lib/CIG/TaskPath.pm:343 - find_parent() validation logic
  - .cig/lib/CIG/TaskPath.pm:451 - find_descendants() depth-first traversal

- **Test Coverage**:
  - g-testing-exec.md - Complete test results with hierarchical fixture
  - Test fixture structure documented at line 19-28

- **Common Issues**: See Incident Response section above

## Success Criteria
- [x] Monitoring and alerting operational and validated (git-based, manual)
- [x] Maintenance procedures documented (lightweight for internal library)
- [x] Support procedures documented (common issues, troubleshooting guide)
- [x] Performance consistently within acceptable ranges (0.043ms < 50ms)
- [x] Incident response procedures established (3-level escalation)
- [x] Knowledge base created (architecture, implementation, tests)

## Status
**Status**: Finished
**Next Action**: Proceed to retrospective → `/cig-retrospective 33`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

**Maintenance Plan Completed**: 2026-02-02

**Monitoring Approach**:
- Lightweight manual monitoring appropriate for internal library
- Git-based version tracking for integrity verification
- Test suite provides comprehensive validation
- Performance monitoring via test execution timing

**Maintenance Strategy**:
- As-needed updates (no regular schedule required)
- Test coverage maintained at 100%
- Backward compatibility maintained via resolve() alias
- Documentation synchronized with code changes

**Incident Response**:
- 3 common issues documented with resolutions
- Troubleshooting guide created for typical problems
- 3-level escalation procedure established
- Emergency rollback procedure < 5 minutes

**Performance Optimization**:
- Current performance 1000x better than target (0.043ms vs 50ms)
- Optimization deferred until performance > 10ms
- Clear optimization path documented (caching, indexing)
- Scaling strategy defined for future growth

**Documentation Created**:
- Runbooks for operations, emergency response, maintenance
- Knowledge base with architecture decisions and implementation details
- Cross-references to design and testing documentation

## Lessons Learned

**What Went Well**:
- Lightweight maintenance approach appropriate for internal library
- Comprehensive test suite provides ongoing validation
- Documentation references enable quick troubleshooting
- Performance headroom eliminates optimization pressure

**What Could Be Improved**:
- Could add automated test execution on git pre-commit hook
- Could document performance profiling procedure more explicitly
- Could create example debugging session for common issues

**Key Takeaways**:
- Internal libraries need lighter maintenance than external services
- Comprehensive testing reduces ongoing maintenance burden
- Documentation references are more maintainable than duplication
- Performance headroom provides operational flexibility
