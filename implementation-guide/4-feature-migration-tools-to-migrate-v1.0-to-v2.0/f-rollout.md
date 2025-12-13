# {{description}} - Rollout

## Task Reference
- **Task ID**: {{taskId}}
- **Task URL**: {{taskUrl}}
- **Parent Task**: {{parentTask}}
- **Branch**: {{branchName}}
- **Template Version**: 2.0

## Goal
Define deployment strategy and rollout plan for {{description}}.

## Deployment Strategy
### Release Type
- **Strategy**: Blue-green|Rolling|Canary deployment
- **Rationale**: Why this approach was chosen
- **Rollback Plan**: Quick rollback procedure if issues arise

### Pre-Deployment Checklist
- [ ] Code review completed and approved
- [ ] All tests passing (unit, integration, system)
- [ ] Security scan completed with no critical issues
- [ ] Performance testing validated against requirements
- [ ] Documentation updated (user docs, API docs, runbooks)
- [ ] Monitoring and alerting configured
- [ ] Rollback plan tested and ready

## Rollout Plan
### Phase 1: Limited Release
- **Scope**: X% of users or specific user groups (e.g., internal team, beta users)
- **Duration**: X days monitoring period
- **Success Metrics**: Key indicators to monitor (error rates, performance, user feedback)

### Phase 2: Gradual Rollout
- **Scope**: Expand to X% of users
- **Duration**: X days monitoring period
- **Success Metrics**: Continued monitoring of all key metrics

### Phase 3: Full Release
- **Scope**: 100% of users
- **Monitoring**: Full production monitoring and ongoing optimisation

## Monitoring
### Key Metrics
- **Performance**: Response times, throughput, resource usage
- **Errors**: Error rates, exception tracking, failed requests
- **Business**: User engagement, conversion rates, feature adoption

### Alerting
- Critical error thresholds and notification channels
- Performance degradation alerts and escalation procedures
- Business metric anomalies and stakeholder communication

## Rollback Plan
### Triggers
- Error rate above X%
- Performance degradation > X%
- Critical business metric impact
- Security vulnerability discovered

### Procedure
1. **Immediate**: Stop deployment, assess impact and scope
2. **Rollback**: Execute rollback procedure (automated or manual)
3. **Communication**: Notify stakeholders and users if necessary
4. **Analysis**: Root cause investigation and post-incident review

## Success Criteria
- [ ] Deployment completed without issues
- [ ] All monitoring metrics within acceptable ranges
- [ ] User feedback positive or neutral
- [ ] Business objectives met
- [ ] No rollbacks required

## Status
**Status**: Backlog
**Next Action**: Finalise deployment procedures
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
