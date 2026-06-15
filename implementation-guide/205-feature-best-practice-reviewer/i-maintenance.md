# Best-practice reviewer for plan and exec steps - Maintenance
**Task**: 205 (feature)

## Task Reference
- **Task ID**: internal-205
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/205-best-practice-reviewer
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for Best-practice reviewer for plan and exec steps.

## Monitoring Requirements
No runtime service, so no uptime/throughput telemetry. The integrity and
correctness signals that matter:
- **Integrity**: `cwf-manage validate` clean — the three tracked files
  (`best-practice-resolve` 0500, two agents 0444) must match
  `script-hashes.json`. A mismatch is the primary alarm (tamper or an edit that
  skipped the same-commit hash refresh).
- **Fail-open correctness**: a malformed `best-practices.json` must surface as
  `error` in the review section, never as silent `no findings`. If a broken
  config ever reads as clean, that is a defect, not a maintenance event.
- **No-op when unconfigured**: absence of `best-practices.json` yields 0 matches
  and an unchanged workflow — the steady state for repos that don't use it.

## Maintenance Tasks
### Triggered (not scheduled)
- **Edit any of the three tracked files** → refresh its `sha256` in
  `script-hashes.json` in the **same commit** (`.cwf/docs/conventions/hash-updates.md`).
  This is the single most likely maintenance slip.
- **Permission drift** on the helper/agents → fix on sight with
  `cwf-manage fix-security` (recorded perms are a ceiling: a 0500-recorded
  script left at 0700 fails validate).
- **Production-line cap friction**: if CWF's own larger tasks keep tripping the
  500-line security cap, revisit `security.review.max-lines` /
  `max-lines-exclude-paths` rather than working around it per-task.
- **URL allowlist hygiene**: review `security.review.url-allow-hosts` and
  `allow-url-fetch` when a user reports a fetch was refused or wrongly allowed
  (DNS-rebinding residual is documented, not fixed).

### Periodic
- Dead-code audit (see `.cwf/docs/dead-code-audit.md`) — include
  `best-practice-resolve` and the two agents in the next sweep.

## Incident Response
### Common Issues
- **Review section reads `error: best-practice-resolve failed`**: the config is
  unparseable or a source path is unreadable. Diagnose by running
  `best-practice-resolve --task-num=N --phase=plan` directly and reading stderr;
  fix the `best-practices.json` entry. Fail-open is working as designed — the
  workflow is not blocked.
- **`cwf-manage validate` reports a hash mismatch on a shipped file**: surface
  it, do not smooth it. If it followed a legitimate edit, the hash refresh was
  missed — make it in a corrective commit. If unexplained, treat as tampering.
- **A best practice the user expected wasn't applied**: tag mismatch. Confirm
  the entry's `tags` casefold-intersect the task tag set (project `active-tags`
  ∪ the task's `**Tags**` line); matching is exact-token, not substring.
- **A URL doc was skipped**: expected unless `allow-url-fetch: true`, scheme is
  https, and host is in `url-allow-hosts`. This is default-deny by design.

### Escalation
Single-maintainer tool — no tiered on-call. A suspected security defect in path
confinement or URL handling is the only "stop and fix before next use" class;
everything else degrades gracefully (fail-open / no-op).

## Documentation
- **Single normative source**: `.cwf/docs/skills/best-practice-review.md`
  (helper contract, manifest discipline, prompt templates, config schema +
  precedence, limitations). Update it — not the skills — when behaviour changes;
  the skills reference it (progressive disclosure).
- **Config reference + schema**: same doc's config section.
- **Threat model / accepted residuals**: recorded in f-implementation-exec.md
  § Security Review and the design plan.

## Success Criteria
- [x] Integrity signal identified (`cwf-manage validate`) — no bespoke monitoring built
- [x] Maintenance is triggered (hash refresh, perm/cap/allowlist) not calendar-driven
- [x] Common failure modes documented with direct-invocation diagnosis
- [x] Single normative doc named as the change-surface; skills defer to it
- [x] Fail-open / no-op steady state confirmed as the design contract

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance defined as triggered (hash-refresh-on-edit, perm/cap/allowlist
hygiene) rather than scheduled; integrity signal is `cwf-manage validate`; the
single normative doc is the change-surface. See § above.

## Lessons Learned
The most likely future slip is editing one of the three tracked files without
the same-commit hash refresh — called out explicitly as the primary maintenance
risk. See `j-retrospective.md`.
