# Blocker Patterns

Centralized blocker handling guidance for all CWF workflow phases. This document consolidates common blockers, reversion strategies, and decomposition signals that were previously duplicated across workflow commands.

## By Workflow Phase

### Planning Phase (a-task-plan.md)

**Common Blockers**:
- Unclear scope or missing requirements → Revert to stakeholder discussion/clarification
- Conflicting stakeholder goals → Revert to goal alignment before continuing
- Too many unknowns to estimate → Recommend creating discovery/spike task first
- Dependencies cannot be resolved → Update status to "Blocked", document blockers
- Decomposition needed but unclear how → Create investigation subtask to explore options

**Reversion Guidance**:
- If reverting to earlier phase: Update status to "Backlog" or "To-Do", document reason
- Document the blocker in "Actual Results" or "Blockers" section
- Update status to "Blocked" until blocker is resolved
- When blocker resolved, restart planning with new information

**When to Revert**:
- Planning reveals the task description is fundamentally wrong
- Planning shows task is not feasible with current constraints
- Planning requires information that must come from earlier work

### Requirements Phase (b-requirements-plan.md)

**Common Blockers**:
- Stakeholders cannot agree on acceptance criteria → Revert to a-task-plan.md to realign on goals
- Requirements reveal scope is much larger than planned → Revert to planning, consider task decomposition
- External dependencies discovered that change feasibility → Update a-task-plan.md with new constraints
- Conflicting requirements that cannot be reconciled → Revert to stakeholder alignment
- Missing domain knowledge to specify requirements → Create discovery subtask or research spike

**Reversion Guidance**:
- If reverting to planning: Update a-task-plan.md with new understanding, then restart requirements
- Document the blocker in "Actual Results" section
- Update status to "Blocked" until blocker is resolved
- When blocker resolved, update requirements with new information

**When to Revert**:
- Requirements gathering reveals the planned approach is not viable
- Acceptance criteria cannot be defined without design exploration
- Requirements show task needs to be split into multiple subtasks

### Design Phase (c-design-plan.md)

**Common Blockers**:
- Multiple design approaches with no clear winner → Create spike task to prototype alternatives
- Design reveals requirements are incomplete/incorrect → Revert to b-requirements-plan.md to clarify
- Technical constraints make all approaches infeasible → Revert to a-task-plan.md to reconsider scope
- Missing expertise to make design decisions → Consult expert or create research subtask
- Design shows task is too complex for one phase → Revert to planning, decompose into subtasks

**Reversion Guidance**:
- If reverting to requirements: Update b-requirements-plan.md with design insights, then redesign
- If reverting to planning: Update a-task-plan.md with new constraints, reconsider approach
- Document the blocker in "Actual Results" section
- Update status to "Blocked" until blocker is resolved
- When blocker resolved, update design with new approach

**When to Revert**:
- Design exploration reveals fundamental requirement gaps
- All considered approaches violate stated constraints
- Design complexity indicates need for task decomposition

### Implementation Planning Phase (d-implementation-plan.md)

**Common Blockers**:
- Design proves insufficient during planning → Revert to c-design-plan.md to address gaps
- Implementation reveals missing requirements → Revert to b-requirements-plan.md to clarify
- Discovered technical debt blocks planned approach → Create cleanup subtask first
- Complexity exceeds estimation, needs decomposition → Revert to a-task-plan.md, create subtasks
- Missing tools/libraries not in design → Revert to design to evaluate alternatives

**Reversion Guidance**:
- If reverting to design: Update c-design-plan.md with implementation insights, then replan
- If reverting to requirements: Update b-requirements-plan.md, propagate changes through design
- Document the blocker in "Actual Results" section
- Update status to "Blocked" until blocker is resolved
- When blocker resolved, update implementation plan with new approach

**When to Revert**:
- Implementation plan reveals design is not implementable as specified
- Plan shows implementation requires 3x more work than estimated
- Critical dependencies are missing or incompatible

### Implementation Execution Phase (f-implementation-exec.md)

**Common Blockers**:
- Code changes cause unexpected test failures → Debug root cause, may need design revision
- Dependencies have breaking changes → Revert to d-implementation-plan.md to adjust approach
- Implementation reveals design is flawed → Revert to c-design-plan.md to redesign
- Complexity is much higher than estimated → Consider decomposing into subtasks
- External API changes break integration → Update plan and design to accommodate

**Reversion Guidance**:
- If reverting to planning: Update d-implementation-plan.md with learnings, then re-execute
- If reverting to design: Update c-design-plan.md with discovered constraints, replan and re-execute
- Document the blocker in "Blockers Encountered" section
- Update status to "Blocked" until blocker is resolved
- When blocker resolved, resume execution with updated approach

**When to Revert**:
- Execution proves the planned approach does not work
- Unforeseen technical constraints make plan impossible
- Implementation reveals fundamental design flaws

### Testing Planning Phase (e-testing-plan.md)

**Common Blockers**:
- Test environment cannot be set up → Create infrastructure subtask or escalate to ops
- Requirements lack testable acceptance criteria → Revert to b-requirements-plan.md to add criteria
- Design makes testing extremely difficult → Revert to c-design-plan.md to improve testability
- Implementation incomplete, tests cannot be planned → Wait for d-implementation-plan.md completion
- Missing test data or test doubles → Create test infrastructure subtask first

**Reversion Guidance**:
- If reverting to requirements: Add testable acceptance criteria, then update test plan
- If reverting to design: Add testability considerations, then replan testing
- Document the blocker in "Actual Results" section
- Update status to "Blocked" until blocker is resolved
- When blocker resolved, update test plan with new test cases

**When to Revert**:
- Test planning reveals requirements are not testable as written
- Design decisions make achieving test coverage impossible
- Test environment dependencies are unavailable

### Testing Execution Phase (g-testing-exec.md)

**Common Blockers**:
- Tests reveal critical defects → Revert to f-implementation-exec.md to fix issues
- Test environment failures → Resolve infrastructure issues, may need infrastructure subtask
- Tests uncover design flaws → Revert to c-design-plan.md to address fundamental issues
- Coverage targets cannot be met → Revert to e-testing-plan.md to adjust strategy
- Missing test data or fixtures → Create test data generation subtask

**Reversion Guidance**:
- If reverting to implementation: Fix defects, re-run tests until passing
- If reverting to design: Address design issues, update implementation, retest
- Document the blocker in "Blockers Encountered" section
- Update status to "Blocked" until blocker is resolved
- When blocker resolved, resume testing with fixes applied

**When to Revert**:
- Critical defects found that require implementation changes
- Test failures reveal fundamental design problems
- Testing strategy needs adjustment to achieve coverage goals

### Rollout Phase (h-rollout.md)

**Common Blockers**:
- Deployment environment not ready → Coordinate with ops team, may need infrastructure subtask
- Rollout reveals critical production issues → Revert deployment, fix in implementation
- Dependencies missing in production → Add dependency installation to rollout plan
- Configuration issues in production → Create configuration management subtask
- Monitoring/alerting not set up → Create observability subtask before rollout

**Reversion Guidance**:
- If deployment fails: Rollback to previous version, document issue
- If critical issues found: Revert to f-implementation-exec.md to fix, retest, redeploy
- Document the blocker in "Actual Results" section
- Update status to "Blocked" until blocker is resolved
- When blocker resolved, attempt rollout again with fixes

**When to Revert**:
- Deployment fails and cannot be completed
- Production issues require code changes
- Environment prerequisites not met

### Maintenance Phase (i-maintenance.md)

**Common Blockers**:
- Maintenance burden higher than estimated → Re-evaluate if feature should be simplified or removed
- Dependencies have breaking changes → Create upgrade subtask to handle migration
- Documentation insufficient for maintainers → Create documentation subtask
- Monitoring reveals performance issues → Create performance optimization subtask
- Technical debt accumulating → Create refactoring subtask to address

**Reversion Guidance**:
- Document maintenance issues in "Actual Results" section
- Create subtasks to address specific maintenance problems
- Update status to "Blocked" if maintenance issues prevent further work
- When issues resolved, resume normal maintenance

**When to Revert**:
- Maintenance costs exceed expected thresholds
- Breaking changes require significant rework
- Feature needs redesign for maintainability

### Retrospective Phase (j-retrospective.md)

**Common Blockers**:
- Missing data to complete retrospective → Gather from team members, git history, documentation
- Unclear what went wrong → Review workflow files, git log, discuss with team
- Team not available for retrospective → Schedule dedicated time, document asynchronously if needed

**Reversion Guidance**:
- Retrospective has no formal "reversion" - it's reflection on completed work
- If data is missing: Document with available information, note gaps
- Update status to "Blocked" if retrospective cannot proceed without key information

## General Reversion Guidance

### When to Revert to Earlier Phases

Revert when:
1. Current phase reveals fundamental issues with previous phase output
2. Assumptions made in earlier phases prove incorrect
3. New information invalidates earlier decisions
4. Complexity or constraints were underestimated

### How to Revert Effectively

1. **Document the reason**: Clearly explain why reversion is needed in current phase "Actual Results"
2. **Update previous phase**: Add new insights to the phase being reverted to
3. **Update status**: Set current phase to "Blocked", previous phase to "In Progress"
4. **Propagate changes**: After updating earlier phase, work forward through subsequent phases
5. **Capture learning**: Document in retrospective what was missed initially

### Avoiding Unnecessary Reversion

Before reverting, ask:
- Can the issue be resolved within the current phase?
- Is this truly a fundamental problem or just a minor adjustment?
- Will reverting actually prevent similar issues in the future?

## Decomposition Signals

### When Blockers Indicate Task Should Be Split

Consider decomposing into subtasks when:

1. **Time Signal**: Current task will take >1 week even with reversion
2. **People Signal**: Different parts need different expertise
3. **Complexity Signal**: Task involves 3+ distinct concerns that could be separated
4. **Risk Signal**: High-risk components should be isolated for focused testing
5. **Independence Signal**: Parts can be worked on separately without blocking each other
6. **Blocker Signal**: Same blocker keeps recurring, suggesting task is too large

### How to Decompose When Blocked

1. Identify independent sub-concerns within the task
2. Create subtasks using `/cwf-subtask <parent> <num> <type> "description"`
3. Update parent task to reference new subtasks
4. Set parent task status to show it's decomposed into subtasks
5. Work on subtasks independently
6. Integrate results back into parent task

### Example Decomposition Scenarios

- **Large feature blocked by missing API**: Split into "API implementation" + "Feature using API"
- **Complex design with no consensus**: Split into "Spike alternative A" + "Spike alternative B" + "Design comparison"
- **Implementation revealing scope creep**: Split into "Core functionality" + "Nice-to-have enhancements"

## References

This document consolidates blocker handling guidance that was previously in:
- `.claude/commands/cwf-task-plan.md`
- `.claude/commands/cwf-requirements-plan.md`
- `.claude/commands/cwf-design-plan.md`
- `.claude/commands/cwf-implementation-plan.md`
- `.claude/commands/cwf-implementation-exec.md`
- `.claude/commands/cwf-testing-plan.md`
- `.claude/commands/cwf-testing-exec.md`
- `.claude/commands/cwf-rollout.md`
- `.claude/commands/cwf-maintenance.md`
- `.claude/commands/cwf-retrospective.md`

For workflow step details, see `.cwf/docs/workflow/workflow-steps.md`
