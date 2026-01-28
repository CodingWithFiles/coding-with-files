# task-tracking-using-inference-scoring - Plan

## Task Reference
- **Task ID**: internal-32
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/32-task-tracking-using-inference-scoring
- **Template Version**: 2.1

## Goal
Implement a signal-based inference system that automatically determines the current task and workflow step by correlating multiple environmental signals, exposed through a library helper script and two skills (/current-task-wf and /current-task-wf-verbose), eliminating the need for explicit state management or repetitive task number entry.

## Success Criteria
- [ ] task-context-inference helper script returns correct task/workflow step with 95%+ accuracy when signals are correlated
- [ ] /current-task-wf skill provides simple 3-line output (task_num, task_slug, workflow_step) for command use
- [ ] /current-task-wf-verbose skill provides full signal breakdown with scores and correlation analysis for debugging
- [ ] All 8 workflow commands work without task arguments when context is clear (using /current-task-wf skill)
- [ ] Uncorrelated signals trigger user prompt with top candidates instead of guessing wrong task
- [ ] System handles edge cases gracefully (no signals, stale signals, worktree compatibility)

## Original Estimate
**Effort**: 3-4 days
**Complexity**: High (mitigated by library-based architecture)
**Dependencies**:
- Existing helper scripts (hierarchy-resolver, format-detector, status-aggregator)
- Design document at `.cig/docs/context/state-tracking.md` (complete)
- Two new skills (/current-task-wf and /current-task-wf-verbose) for LLM access
- All 8 workflow commands need modification for argument-optional invocation
- Git branch naming conventions and worktree structure

## Major Milestones
1. **Library Implementation**: task-context-inference helper script with all 6 signals, correlation logic, and --verbose flag
2. **Skills Created**: /current-task-wf (simple output) and /current-task-wf-verbose (debugging) for LLM access
3. **Workflow Commands Updated**: Modify all 8 workflow commands to use /current-task-wf skill when no argument provided
4. **Integration Testing Complete**: Verify accuracy across common scenarios (single task, multiple tasks, worktrees, edge cases)
5. **Documentation and Examples**: Document usage patterns, troubleshooting, and verbose debugging mode

## Risk Assessment
### High Priority Risks
- **Risk 1: False Positives in Inference** - System incorrectly infers task/step, user works on wrong context without realizing
  - **Mitigation**: Conservative correlation check (all signals must agree), verbose mode for verification, user prompt when signals disagree
- **Risk 2: Performance Degradation** - Signal scoring requires filesystem scans that slow down commands
  - **Mitigation**: Cache recent results with TTL, optimize signal collection order (fast signals first), make inference opt-in initially

### Medium Priority Risks
- **Risk 3: Worktree Edge Cases** - Complex worktree setups confuse branch/path signals
  - **Mitigation**: Test with multiple worktree configurations, use git worktree list for path resolution
- **Risk 4: Stale Signal Problem** - Old file timestamps or status values mislead inference
  - **Mitigation**: Apply time decay to recency signals, weight recent signals higher, null out signals older than threshold

## Dependencies
**Technical Prerequisites**:
- Design document `.cig/docs/context/state-tracking.md` (complete)
- Existing helper scripts must remain stable during development
- Git branch naming convention: `<type>/<num>-<slug>` must be enforced

**External Dependencies**:
- None - this is internal CIG functionality

**Coordination Needs**:
- Update all 8 workflow commands simultaneously to avoid inconsistent behavior
- Test with existing tasks (26, 29, 31) to verify backward compatibility

## Constraints
**Technical Constraints**:
- Must work with existing Perl-based helper script architecture
- Cannot rely on persistent daemon processes (must be stateless)
- Must handle git worktree scenarios without shared state files
- Signal collection must complete in <500ms to avoid noticeable command latency

**Design Constraints**:
- Output format fixed: `task_num: X\ntask_slug: Y\nworkflow_step: Z\n`
- Correlation logic: all non-null top signals must agree or ask user
- Top-N scoring: each signal returns top 5 candidates (not winner-takes-all)

**Scope Constraints**:
- This task only implements inference system, does NOT implement optional state file
- Focus on correlation accuracy over UI polish
- Library-based architecture: all logic in task-context-inference script (single source of truth)
- Skills are thin wrappers: /current-task-wf (default) and /current-task-wf-verbose (debugging)
- Command updates are mechanical: reference /current-task-wf skill output, no inline logic

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? - No, estimated 3-4 days (library architecture simplifies)
- [ ] **People**: Does this need >2 people working on different parts? - No, single developer
- [ ] **Complexity**: Does this involve 3+ distinct concerns? - No, library-based architecture = 2 concerns: (1) library + skills, (2) command integration
- [ ] **Risk**: Are there high-risk components that need isolation? - Moderate risk, library testable in isolation
- [x] **Independence**: Can parts be worked on separately? - Yes: library + skills can be developed/tested independently before command integration

**Decomposition Decision**: **1/5 signals triggered** - Weak case for decomposition

**Options**:
- **Option A (Recommended)**: Monolithic implementation - Library architecture makes this manageable
- **Option B**: 2 Subtasks if preferred:
  1. **32.1**: Implement task-context-inference library + create both skills
  2. **32.2**: Update 8 workflow commands + integration testing + documentation

**Rationale**: Library-based architecture significantly reduces complexity. Command updates are now mechanical (~10 lines each × 8 commands). Skills-first design aligns with stated direction. Testing can be incremental (library first, then commands).

## Status
**Status**: Finished
**Next Action**: Completed - proceeded to requirements phase
**Alternative**: N/A
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
