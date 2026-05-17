# retire bootstraps missing CHANGELOG task entry - Maintenance
**Task**: 147 (feature)

## Task Reference
- **Task ID**: internal-147
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/147-retire-bootstraps-missing-changelog-task-entry
- **Template Version**: 2.1

## Scope
This is a small internal change to a developer CLI (`backlog-manager retire`). There is no service, no monitoring infrastructure, no SLA, and no oncall rotation. Most of the template's monitoring/alerting/scaling sections do not apply. The maintenance burden is bounded to: (a) keeping the new helpers in step with the parser-tree shape if `CWF::Backlog`'s entry hashref is ever refactored, and (b) the cross-module scan-helper consolidation already captured as a separate BACKLOG item.

## Ongoing Maintenance Surface

### Entry-shape coupling (Backlog.pm)
`bootstrap_changelog_entry` builds the entry hashref directly, mirroring the shape produced by `_parse_tree` at `.cwf/lib/CWF/Backlog.pm:235-246`. If that shape ever changes (new required key, renamed field, additional `lineno` discipline), the bootstrap helper must change in lockstep or the next serialise pass will malform the entry.

**Mitigation**: TC-U3 (`t/backlog-tree-mutators.t`) parses → serialises → re-parses a bootstrapped entry and deep-compares; any drift in the parser shape will surface as a TC-U3 failure before reaching production.

### `_load_supported_types` cache
The `@_SUPPORTED_TYPES` cache is process-scoped. Safe for the one-shot `backlog-manager` CLI (each invocation is a fresh `perl` process). If `CWF::Backlog` is ever loaded into a long-running consumer that operates across multiple project roots, the cache becomes stale.

**Mitigation**: documented inline at the cache declaration; security-review subagent flagged this as a pattern-risk to audit on reuse. No code change needed for the current consumer.

### Cross-module scan-helper duplication
Three slightly-different `implementation-guide/N-*-*/` directory scans now exist across two modules (Backlog.pm, TaskContextInference.pm). Tracked as the BACKLOG item added in this task ("Unify implementation-guide directory-scan helpers across CWF::Backlog and CWF::TaskContextInference", Low priority chore).

**Mitigation**: pick up via the normal backlog grooming process; no urgency.

## Open Items From Rollout
1. Refresh `.cwf/security/script-hashes.json` for the two modified files. Maintainer decision; non-blocking, surfaced loudly by every `cwf-manage validate` run until updated.
2. Pre-existing `t/backlog-roundtrip-live.t::TC-ROUNDTRIP-LIVE-BACKLOG` UTF-8 failure on the live BACKLOG.md. Out of scope for this task; flag as its own BACKLOG entry if not already there.

## Common Issues / Runbook
- **"cannot bootstrap CHANGELOG entry for Task N: no directory matching 'implementation-guide/N-*/'"** — the retire was invoked for a task whose `implementation-guide/N-<type>-<slug>/` directory doesn't exist. Either run `/cwf-new-task` to create it first, or pick a different `--task` value.
- **"multiple directories match (…)"** — the legacy task-1 condition (three sibling dirs for the same number). Manually create `## Task N: <title>` in `CHANGELOG.md` first (per the error message's hint), then re-run retire.
- **"derived title '…' violates CHANGELOG heading constraints"** — a hand-created directory has a `:` or control character in its slug. Rename the directory to remove the offending character.
- **"refusing symlink at …"** — pre-existing guard; CHANGELOG.md or BACKLOG.md is a symlink. Replace with a real file.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 147
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
