# Maintenance

> Part of the [Workflow Steps](../workflow-steps.md) reference.

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

**Structure**: Defined in workflow file template (`.cwf/templates/pool/`).

**Transition Triggers**:
- **Primary → Retrospective**: Task complete, ready for learning capture
- **Alternative → Follow-up Tasks**: Improvements identified, create new tasks
- **Alternative → Monitoring Updates**: New issues discovered, update monitoring
