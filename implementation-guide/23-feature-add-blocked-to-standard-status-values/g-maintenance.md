# Add "Blocked" to Standard Status Values - Maintenance

## Task Reference
- **Task ID**: internal-23
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/23-add-blocked-to-standard-status-values
- **Template Version**: 2.0

## Goal
Establish minimal ongoing monitoring and support for "Blocked" status feature (documentation/configuration change).

## Monitoring Requirements
### System Health
Since this is a documentation/configuration change with no runtime service:
- **N/A**: No uptime monitoring required
- **Performance**: Status aggregator execution time (baseline: <1ms per task)
- **Usage**: N/A (documentation accessed as-needed)

### Application Metrics
- **Feature Adoption**: Monitor usage of "Blocked" status in tasks
  - Track: Number of tasks using "Blocked" status per month
  - Method: Git grep through implementation-guide directory
- **Status Aggregator Accuracy**: Verify correct percentage calculations
  - Track: Any reports of incorrect status percentages
  - Method: User feedback, manual spot checks
- **Documentation Accessibility**: Ensure workflow-steps.md remains accurate
  - Track: Changes to status values configuration
  - Method: Review changes to cig-project.json and workflow-steps.md

### Alerting Rules
No automated alerting needed for documentation changes. Manual monitoring only:
- **Critical**: Status aggregator breaks (reports errors or wrong percentages)
  - Response: Investigate immediately, revert if necessary
- **Warning**: User confusion about "Blocked" vs "Backlog" semantics
  - Response: Update documentation to clarify
- **Info**: Low/no adoption of "Blocked" status
  - Response: Evaluate usefulness, consider deprecation or better documentation

## Maintenance Tasks
### Regular Maintenance Schedule
- **Daily**: None required
- **Weekly**: None required
- **Monthly**: Review "Blocked" status usage patterns (if any adoption issues observed)
- **Quarterly**: Review whether "Blocked" status is meeting user needs
  - Check: Are tasks using "Blocked" appropriately?
  - Check: Any confusion or support requests?
  - Action: Update documentation or consider improvements

### Preventive Maintenance
- **Documentation Sync**: Ensure cig-project.json and workflow-steps.md remain synchronized
  - If status values change in config, update documentation
  - If new statuses added, verify "Blocked" semantics still clear
- **Template Validation**: Periodically verify new tasks get proper status reference
  - Create test task, check template includes workflow-steps.md reference
- **Progressive Disclosure Audit**: Ensure no hardcoded status lists creep in
  - Quarterly: Grep for potential duplication patterns

## Incident Response
### Common Issues

- **Issue 1**: Status aggregator reports incorrect percentage for "Blocked" tasks
  - **Symptoms**: Tasks with "Blocked" status show 0% instead of 15%, or wrong overall percentage
  - **Diagnosis**: Check cig-project.json has "Blocked": 15 entry; verify status-aggregator.pl can read config
  - **Resolution**:
    1. Verify `jq '.workflow["status-values"]["Blocked"]' implementation-guide/cig-project.json` returns 15
    2. Test with `status-aggregator.pl --workflow <task-with-blocked-status>`
    3. If broken: git revert Task 23 commit, investigate config loading issue

- **Issue 2**: Users confused about when to use "Blocked" vs "Backlog"
  - **Symptoms**: Tasks incorrectly marked as "Blocked" when they haven't started, or vice versa
  - **Diagnosis**: Review task status patterns, check for semantic confusion
  - **Resolution**:
    1. Update workflow-steps.md to clarify: "Blocked" = work started but stopped; "Backlog" = not started
    2. Add examples to documentation
    3. Consider adding usage guidance to command files if widespread issue

- **Issue 3**: Templates missing status reference after update
  - **Symptoms**: New tasks created without workflow-steps.md reference in Status section
  - **Diagnosis**: Check template files in `.cig/templates/pool/` for missing references
  - **Resolution**:
    1. Verify all 8 templates have `**See .cig/docs/workflow/workflow-steps.md#status-values for valid status values**`
    2. If missing: re-apply changes from Task 23
    3. Test with `template-copier.pl` to verify new tasks get reference

### Troubleshooting Guide
- **Symptom**: "Unknown status value: Blocked" in output
- **Diagnosis**: Config not loaded or "Blocked" missing from cig-project.json
- **Resolution**:
  1. Check file exists: `ls implementation-guide/cig-project.json`
  2. Verify entry: `jq '.workflow["status-values"]' implementation-guide/cig-project.json`
  3. If missing: Merge or cherry-pick Task 23 changes

### Escalation Procedures
No formal escalation needed for documentation changes:
- **Level 1**: Developer self-service (check this maintenance guide, review Task 23 implementation)
- **Level 2**: Review git history for Task 23, check for conflicts or reverts
- **Level 3**: N/A (no critical production system)

## Performance Optimisation
### Optimisation Areas
Documentation/configuration changes have minimal performance impact:
- **Status Aggregator**: Already optimized with config caching, no changes needed
- **Documentation Access**: Static files, no optimization needed
- **Template Generation**: One-time operation per task, acceptable performance

### Scaling Strategy
N/A - Documentation scales linearly with repository size, no special scaling needed

## Documentation
### Runbooks
- **Verifying "Blocked" Status Works**:
  ```bash
  # Create test task with "Blocked" status
  # Run status aggregator
  .cig/scripts/command-helpers/status-aggregator.pl --workflow <task-num>
  # Verify shows "Blocked 15%"
  ```

- **Checking Template References**:
  ```bash
  # Verify all templates have status reference
  grep -l "workflow-steps.md#status-values" .cig/templates/pool/*.template
  # Should return 8 files
  ```

### Knowledge Base
- **When to Use "Blocked"**: Work has started but cannot proceed due to external blocker (dependencies, waiting for approval, external system unavailable)
- **When to Use "Backlog"**: Work has not started yet, queued for future work
- **When to Use "In Progress"**: Work is actively underway with no blockers

## Active Maintenance Requirements

### Scheduled Maintenance Tasks
**NONE** - This is a documentation/configuration change with no scheduled maintenance.

No regular tasks required:
- No databases to maintain
- No services to patch
- No scheduled updates
- No regular cleanup tasks
- No performance tuning needed

### Reactive Maintenance Only

**When Action Required**:
1. **IF** status-values modified in cig-project.json → THEN verify workflow-steps.md updated (1-time, 2 min)
2. **IF** templates modified → THEN verify status reference still present (1-time, 2 min)
3. **IF** user reports confusion → THEN update documentation (rare, 15 min)
4. **IF** status-aggregator breaks → THEN investigate/fix (rare, 30 min)

**Estimated Annual Burden**: ~0-1 hour/year (reactive only, may be zero)

### Deprecation Decision Point

**Review trigger**: After 6 months of feature availability
**Decision criteria**: Has "Blocked" status been used in ≥1 task?
- **YES**: Keep feature (provides value, zero ongoing cost)
- **NO**: Deprecate feature (unused features add cognitive load)

**Deprecation cost**: ~15 minutes
1. Remove "Blocked" from cig-project.json (1 min)
2. Remove from workflow-steps.md (1 min)
3. Remove template references (8 min)
4. Document removal reason (5 min)

### Cost/Benefit Summary

**Ongoing Active Costs**: ~0 hours/year (no scheduled tasks)
**Reactive Support Costs**: ~0-1 hour/year (if issues arise)
**Deprecation Cost**: ~15 min (one-time, if unused after 6 months)

**Benefits** (if feature used):
- Clear task status communication (eliminates "started but blocked" ambiguity)
- More accurate progress reporting (15% vs 0% for partial work)
- Explicit blocker signaling in status reports

**Justification**: Zero scheduled maintenance cost justifies keeping feature. If unused after 6 months, cheap to deprecate. Low-risk addition with clear exit strategy.

## Success Criteria
- [x] Active maintenance requirements documented (NONE - no scheduled tasks)
- [x] Reactive maintenance triggers defined (4 IF/THEN scenarios)
- [x] Common issues documented with resolutions (3 scenarios)
- [x] Deprecation decision point established (6-month review)
- [x] Incident response: Self-service troubleshooting guide provided
- [x] Cost/benefit analysis: ~0 hours/year active cost justifies keeping feature

## Status
**Status**: Finished
**Next Action**: Proceed to retrospective phase with `/cig-retrospective 23`
**Blockers**: None identified

## Actual Results

**Active Maintenance Tasks Identified**: None (zero scheduled maintenance required)

**Reactive Maintenance Triggers**: 4 IF/THEN scenarios documented
- Config sync verification (2 min if triggered)
- Template reference validation (2 min if triggered)
- Documentation updates for user confusion (15 min if triggered)
- Status aggregator troubleshooting (30 min if triggered)

**Cost Analysis Completed**:
- Scheduled maintenance: 0 hours/year
- Reactive support: 0-1 hours/year (may be zero)
- Deprecation path: 15 min (if needed after 6 months)
- **Total ongoing commitment**: ~0 hours/year active work

**Justification**: Zero active maintenance cost makes feature low-risk. Clear deprecation trigger (6-month unused review) provides exit strategy.

## Lessons Learned

**What Went Well**:
- Clear distinction between active vs reactive maintenance
- Explicit cost/benefit analysis prevents open-ended commitments
- Deprecation decision point provides feature hygiene mechanism
- Documentation/configuration changes require minimal ongoing support

**What Didn't Go Well**:
- Initial maintenance plan conflated monitoring benefits with active tasks
- Template doesn't prompt for cost/benefit analysis of ongoing work
- Easy to propose "quarterly reviews" without justifying the time commitment

**Future Improvements**:
- Maintenance template should require explicit cost analysis
- Distinguish "scheduled active tasks" from "reactive support" from "passive benefits"
- Templates should prompt: "What MUST be done on a schedule vs what MIGHT need fixing?"
