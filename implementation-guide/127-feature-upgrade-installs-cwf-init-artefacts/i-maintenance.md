# upgrade installs cwf-init artefacts - Maintenance
**Task**: 127 (feature)

## Task Reference
- **Task ID**: internal-127
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/127-upgrade-installs-cwf-init-artefacts
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for upgrade installs cwf-init artefacts.

## Skipped — Rationale
This task ships a developer-tool change (`cwf-manage update` extension) inside a single-repo CWF project. There is no live deployment, no SLA, no on-call rotation, no monitoring stack — the operational template (uptime targets, alerting tiers, scaling strategy, runbook escalation) does not map to this task.

The signals worth watching post-merge and the rollback levers are documented in `h-rollout.md` § "Monitoring" and § "Rollback Plan" — those sections subsume the operationally relevant subset of this template.

The shared module (`CWF::ArtefactHelpers`) and new helper (`cwf-apply-artefacts`) are covered by the SHA-pinned integrity check (`cwf-manage validate`) and unit tests (`t/artefacthelpers.t`, `t/cwf-apply-artefacts.t`). Future regressions surface organically through the next CWF task's dogfood usage.

## Status
**Status**: Skipped
**Next Action**: /cwf-retrospective
**Blockers**: None — phase intentionally skipped

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**
