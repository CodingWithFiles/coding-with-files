# Workflow Steps

Detailed guidance for each of the 8 workflow steps. Each step includes purpose, focus/avoid guidelines, key questions, typical structure, and transition triggers.

## Planning

**Purpose**: Establish clear objectives, success criteria, and high-level approach before diving into details.

**Focus on**:
- Single-sentence objective that captures the "why"
- 3-5 measurable success criteria that define "done"
- Major milestones showing progression
- Top 3-5 risks with mitigation strategies
- Dependencies (external, team, technical)
- Constraints (technical, resource, timeline)
- Decomposition signals check

**Avoid**:
- Implementation details or code specifics
- Detailed design decisions
- Specific technology choices (save for design phase)
- Test case details
- Deployment procedures

**Key Questions**:
- What problem are we solving and why does it matter?
- How will we know when we're successful?
- What are the major milestones from start to finish?
- What could go wrong and how do we mitigate it?
- What do we depend on and what depends on this?
- What constraints limit our approach?
- Is this task too large (check decomposition signals)?

**Typical Structure**:
- Goal: One clear sentence
- Success Criteria: 3-5 measurable outcomes
- Original Estimate: Effort, complexity, dependencies
- Major Milestones: 3-5 high-level achievements
- Risk Assessment: High and medium priority risks with mitigation
- Dependencies: External requirements, team coordination
- Constraints: Technical limitations, resource bounds
- Decomposition Check: Review 5 signals

**Transition Triggers**:
- **Primary → Requirements**: Planning complete, objectives clear
- **Alternative → Decomposition**: 2+ decomposition signals triggered, create subtasks
- **Alternative → Clarification**: Objectives unclear, request user input

---

## Requirements

**Purpose**: Define what the system must do (functional) and how well it must do it (non-functional) with clear acceptance criteria.

**Focus on**:
- Functional requirements (FR1-FRn) with specific acceptance criteria
- Non-functional requirements across 5 dimensions:
  - NFR1: Performance (response time, throughput, resource usage)
  - NFR2: Usability (learning curve, error recovery, consistency)
  - NFR3: Maintainability (code clarity, modularity, testability)
  - NFR4: Security (authentication, authorization, data protection)
  - NFR5: Reliability (availability, error handling, data integrity)
- User stories capturing user perspective
- Acceptance criteria as testable checkpoints
- Constraints (technical, integration, resource)

**Avoid**:
- Implementation approaches or "how" details
- Code structure or architecture decisions
- Deployment strategies
- Specific technology choices
- Design patterns

**Key Questions**:
- What must the system do? (Functional requirements)
- How well must it perform? (Performance NFRs)
- How usable must it be? (Usability NFRs)
- How maintainable must it be? (Maintainability NFRs)
- What security requirements exist? (Security NFRs)
- How reliable must it be? (Reliability NFRs)
- How do we verify each requirement? (Acceptance criteria)
- What are the hard constraints?

**Typical Structure**:
- Goal: Define specifications
- Functional Requirements: FR1-FRn with clear criteria
- Non-Functional Requirements: NFR1-NFR5 with measurable targets
- User Stories: As a...I want...so that...
- Constraints: Technical, integration, resource
- Acceptance Criteria: Testable checkpoints (AC1-ACn)

**Transition Triggers**:
- **Primary → Design**: Requirements clear and approved
- **Alternative → Planning**: Requirements reveal scope issues, return to planning
- **Alternative → Decomposition**: Requirements too complex, create focused subtasks

---

## Design

**Purpose**: Document architecture decisions, component design, and interface contracts that satisfy requirements while following design priorities.

**Focus on**:
- Architecture choice with rationale and trade-offs
- Component overview with clear responsibilities
- Data flow showing component interactions
- Interface design (API endpoints, data models)
- Design priorities: Testability → Readability → Consistency → Simplicity → Reversibility
- Architecture preferences: Composition over inheritance, interfaces over singletons, explicit over implicit
- Technical constraints influencing design

**Avoid**:
- Detailed implementation code
- Specific test cases
- Deployment procedures
- Business requirements justification (covered in requirements)
- Step-by-step implementation instructions

**Key Questions**:
- What architecture pattern best fits requirements?
- What are key components and their responsibilities?
- How do components interact? (Data flow)
- What are critical interfaces? (APIs, data models)
- What constraints influenced design?
- What are trade-offs of this approach?
- Does design satisfy requirements?
- Is design validated and approved?

**Typical Structure**:
- Goal: Define architecture
- Design Priorities: Testability → Readability → Consistency → Simplicity → Reversibility
- Key Decisions: Architecture choice, rationale, trade-offs
- Technology Stack: Frontend, backend, database with rationale
- System Design: Component overview, data flow
- Interface Design: API endpoints, data models
- Constraints: Technical factors influencing design
- Validation: Design review, approval, integration verification

**Transition Triggers**:
- **Primary → Implementation**: Design approved and validated
- **Alternative → Requirements**: Design reveals missing requirements
- **Alternative → Spike**: Design uncertainty high, create investigation task

---

## Implementation

**Purpose**: Execute the implementation following approved design, using test-driven approach with clear validation criteria.

**Focus on**:
- Files to modify (primary and supporting changes)
- Implementation steps as numbered, actionable checklist
- Code changes illustrated with before/after examples
- Test coverage (unit, integration, regression)
- Validation criteria before marking complete
- Workflow: Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

**Avoid**:
- Design rationale (covered in design phase)
- Business requirements (covered in requirements)
- Deployment strategies (covered in rollout)
- Performance optimization not required by NFRs
- Gold-plating or scope creep

**Key Questions**:
- What files need creation or modification?
- What is step-by-step implementation approach?
- What tests verify functionality?
- How do we validate requirements are met?
- What are validation criteria before completion?
- Are we following patterns from existing codebase?

**Typical Structure**:
- Goal: Implement following design
- Workflow: Patterns first → Test → Minimal impl → Refactor green
- Files to Modify: Primary and supporting changes
- Implementation Steps: Numbered checklist with checkboxes
- Code Changes: Before/after snippets showing approach
- Test Coverage: Unit, integration, regression tests
- Validation Criteria: How to verify success

**Transition Triggers**:
- **Primary → Testing**: Implementation complete, all tests passing
- **Alternative → Design**: Implementation reveals design gaps
- **Alternative → Decomposition**: Implementation too complex, create subtasks

---

## Testing

**Purpose**: Define test strategy and validate both functional and non-functional requirements through comprehensive test coverage.

**Focus on**:
- Test strategy with test levels (unit, integration, system, acceptance)
- Test coverage targets (overall, critical paths, edge cases, regression)
- Functional test cases in Given/When/Then format
- Non-functional test cases (performance, security, usability, reliability)
- Test environment requirements
- Automation approach and CI/CD integration
- Success criteria for testing phase

**Avoid**:
- Implementation details (covered in implementation)
- Design rationale (covered in design)
- Deployment procedures (covered in rollout)
- Future test scenarios not needed now

**Key Questions**:
- What test levels are needed? (unit, integration, system, acceptance)
- What are coverage targets for each level?
- What critical test cases verify functionality?
- What non-functional tests are needed? (performance, security, usability, reliability)
- What test environment setup is required?
- How will tests be automated and integrated into CI/CD?
- What are success criteria for testing phase?

**Typical Structure**:
- Goal: Define test strategy
- Test Strategy: Test levels, coverage targets
- Test Cases: Functional (Given/When/Then) and non-functional
- Test Environment: Setup requirements, automation
- Validation Criteria: Success metrics

**Transition Triggers**:
- **Primary → Rollout**: All tests passing, coverage targets met
- **Alternative → Implementation**: Tests reveal defects requiring fixes
- **Alternative → Testing Extension**: Coverage insufficient, add more tests

---

## Rollout

**Purpose**: Deploy with phased rollout strategy, monitoring, and tested rollback plan to minimize risk.

**Focus on**:
- Deployment strategy (blue-green, rolling, canary) with rationale
- Pre-deployment checklist (tests, security, performance, docs)
- Phased rollout plan (limited → gradual → full release)
- Monitoring (performance, errors, business metrics)
- Alerting rules (critical, warning, info)
- Rollback plan with triggers and procedures
- Success criteria for each rollout phase

**Avoid**:
- Implementation details (covered in implementation)
- Test cases (covered in testing)
- Design decisions (covered in design)
- Long-term maintenance procedures (covered in maintenance)

**Key Questions**:
- What deployment strategy is appropriate? (blue-green, rolling, canary)
- What pre-deployment checks must pass?
- How will rollout be phased? (limited → gradual → full)
- What metrics will be monitored during rollout?
- What are rollback triggers and procedures?
- What are success criteria for each rollout phase?

**Typical Structure**:
- Goal: Define deployment strategy
- Deployment Strategy: Release type, rationale, rollback plan
- Pre-Deployment Checklist: Tests, security, performance, docs
- Rollout Plan: Phased approach with monitoring periods
- Monitoring: Key metrics, alerting rules
- Rollback Plan: Triggers and procedures
- Success Criteria: Deployment complete, metrics within range

**Transition Triggers**:
- **Primary → Maintenance**: Deployment successful, monitoring stable
- **Alternative → Rollback**: Issues detected, execute rollback
- **Alternative → Extended Monitoring**: Uncertainty remains, extend monitoring period

---

## Maintenance

**Purpose**: Establish ongoing monitoring, support, and optimization to ensure long-term success.

**Focus on**:
- Monitoring requirements (system health, application metrics, alerting)
- Maintenance schedule (daily, weekly, monthly, quarterly)
- Incident response (common issues, troubleshooting, escalation)
- Performance optimization (optimization areas, scaling strategy)
- Documentation (runbooks, knowledge base)
- Success criteria for maintenance phase

**Avoid**:
- Initial implementation details (covered in implementation)
- Design decisions (covered in design)
- Testing procedures (covered in testing)
- Initial deployment strategy (covered in rollout)

**Key Questions**:
- What monitoring is needed? (uptime, performance, errors, business KPIs)
- What are alerting rules and escalation procedures?
- What regular maintenance tasks are required?
- What are common issues and their resolutions?
- What performance optimization opportunities exist?
- What scaling strategy is appropriate?
- What runbooks and documentation are needed?

**Typical Structure**:
- Goal: Define ongoing support
- Monitoring Requirements: System health, metrics, alerting
- Maintenance Tasks: Regular schedule (daily, weekly, monthly, quarterly)
- Incident Response: Common issues, troubleshooting, escalation
- Performance Optimization: Areas, scaling strategy
- Documentation: Runbooks, knowledge base
- Success Criteria: Monitoring operational, procedures documented

**Transition Triggers**:
- **Primary → Retrospective**: Task complete, ready for learning capture
- **Alternative → Follow-up Tasks**: Improvements identified, create new tasks
- **Alternative → Monitoring Updates**: New issues discovered, update monitoring

---

## Retrospective

**Purpose**: Capture learnings, analyze variances, and provide recommendations to improve future work.

**Focus on**:
- Executive summary (duration, scope, outcome)
- Variance analysis (time/effort, scope changes, quality metrics)
- What went well (successes, effective processes, collaboration highlights)
- What could be improved (challenges, inefficiencies, gaps)
- Key learnings (technical insights, process learnings, risk mitigation strategies)
- Recommendations (process improvements, tool recommendations, future work)
- Actual results in all workflow files
- Task marked complete with retrospective date

**Avoid**:
- Future work planning (capture as recommendations only)
- Blame or finger-pointing (focus on process and learnings)
- Generic platitudes (be specific and actionable)

**Key Questions**:
- What were estimated vs actual time and effort?
- What scope changes occurred during execution?
- What went well and why?
- What could be improved and how?
- What did we learn? (technical, process, risk mitigation)
- What recommendations do we have for future similar work?
- Are all Actual Results sections filled in?
- Is task marked as complete?

**Typical Structure**:
- Goal: Capture learnings and variance
- Executive Summary: Duration, scope, outcome
- Variance Analysis: Time/effort, scope changes, quality
- What Went Well: Successes, effective processes
- What Could Be Improved: Challenges, inefficiencies
- Key Learnings: Technical, process, risk mitigation
- Recommendations: Process improvements, tools, future work
- Status: Finished with completion date

**Transition Triggers**:
- **Primary → Complete**: Retrospective done, archive materials
- **Alternative → Follow-up Tasks**: Recommendations create new tasks
- **Alternative → Knowledge Sharing**: Share learnings with team
