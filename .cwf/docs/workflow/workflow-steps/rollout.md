# Rollout

> Part of the [Workflow Steps](../workflow-steps.md) reference.

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

**Structure**: Defined in workflow file template (`.cwf/templates/pool/`).

**Checkpoint Commit**: See `.cwf/docs/skills/checkpoint-commit.md`. Stage: `h-rollout.md`

**Transition Triggers**:
- **Primary → Maintenance**: Deployment successful, monitoring stable
- **Alternative → Rollback**: Issues detected, execute rollback
- **Alternative → Extended Monitoring**: Uncertainty remains, extend monitoring period
