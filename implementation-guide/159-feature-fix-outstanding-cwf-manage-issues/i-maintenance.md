# fix outstanding cwf-manage issues - Maintenance
**Task**: 159 (feature)

## Task Reference
- **Task ID**: internal-159
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/159-fix-outstanding-cwf-manage-issues
- **Template Version**: 2.1

## Goal
Define what keeps the FR1/FR2/FR4 changes healthy over time. CWF is a per-repo tooling system with no server, uptime, or telemetry — "maintenance" here means the integrity gates, the regression sentinels, and the one deferred follow-up that prevent the changes from silently drifting.

## Monitoring Requirements
No runtime metrics exist or are added. Health is verified on demand by deterministic gates run inside the consumer's repo:
- **Integrity gate**: `cwf-manage validate` (SHA256 over `script-hashes.json` + recorded perms). The authoritative signal that the `cwf-manage` edit was laid down intact and the hash was refreshed in the same commit.
- **Regression sentinels**:
  - `t/cwf-manage-git-capture.t` — unit coverage for `git_capture` (exit-status fidelity, stderr suppression) and `git_describe_version` (exact-tag / long-form / no-tags-SHA / bad-committish fallback). Guards FR1 + FR4.
  - `t/cwf-manage-update-end-to-end.t` — the only coverage exercising a real install→update; asserts `cwf_version` is the tag-derived semver and `cwf_ref` the requested ref (never a bare SHA in `cwf_version`). The FR1 regression sentinel at the integration level.
  - `t/cwf-manage-fix-security.t` — `--dry-run` no-mutation + exit codes, unknown-arg fail-closed. Guards FR2.
- **perlcritic backtick policy**: `perlcritic --single-policy InputOutput::ProhibitBacktickOperators .cwf/scripts/cwf-manage` must stay `source OK` — the standing guard that FR4's backtick removal does not regress.
- **No alerting pipeline**: there is nothing to page on. The sole external signal is consumer-filed issues.

## Maintenance Tasks
### Recurring obligations
- **On any edit to `cwf-manage`**: re-run the full `t/` suite, then refresh the `cwf-manage` sha256 in `script-hashes.json` in the same commit (per `.cwf/docs/conventions/hash-updates.md`).
- **When adding a new git invocation to `cwf-manage`**: prefer the `git_capture` helper (list-form exec, stderr suppressed, exit captured) over backticks, to keep the `$source`/`$ref` shell-interpolation surface closed and the perlcritic policy green. `resolve_ref`/`resolve_sha` were already backtick-free and were intentionally left untouched.
- **When extending `fix-security` argument handling**: keep the strip-`--dry-run`-then-reject-leftovers contract; any new flag must be stripped before the unknown-arg `die_msg` so it fails closed on typos.

### Follow-up filed (not maintenance debt — scoped work)
- **Copy-method convergence** (BACKLOG, Low): FR3 from this task was **deferred** at the design gate — a new copy-laydown guard script would sit outside the hash ledger and the changeset auto-review set, and carries CWF_FORCE/.cwf-rules preconditions. It remains on the backlog as scoped future work, not silent debt. Do **not** retire it in this task's retrospective.

## Incident Response
### Common Issues
- **`cwf-manage status` shows a bare 40-char SHA in `cwf_version`**: an install made *before* the tag carrying this fix (the version-write fix is run by the consumer's old updater). Resolution: the next `update` writes it correctly, or reinstall immediately via INSTALL.md bootstrap (`CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<url> bash install.bash`). Not a defect in the fixed code.
- **`fix-security --dry-run` reports would-be repairs but exits 0**: by design — dry-run previews and never mutates, exiting 0 even when repairs are pending. A genuine unfixable (sha256 mismatch) still exits 1 under `--dry-run`. Do not "fix" the exit-0 preview behaviour.
- **`validate` fails immediately after an update**: the exact-perms / SHA guard is fatal-on-mismatch by design (it does not silently repair — "surface, never smooth"). Diagnosis: incomplete laydown or a tampered file. Resolution: re-run the bootstrap installer for the target tag; never reach for a hash-recompute tool.

### Troubleshooting Guide
- **Symptom**: git's `fatal: ...` text appears in a value `cwf-manage` parsed (a ref, a toplevel path). **Diagnosis**: a git call bypassed `git_capture` (which sends stderr to `/dev/null`) or merged stderr into stdout. **Resolution**: route the call through `git_capture` and branch on its returned exit status, not on stdout contents.
- **Symptom**: `git_describe_version` returns an empty string. **Diagnosis**: should be impossible — the helper falls back to the input `$sha` on any non-zero `describe` exit. If seen, the fallback branch regressed; the `t/cwf-manage-git-capture.t` "bad committish" subtest is the guard.

## Performance Optimisation
Not applicable. `git_capture` is one fork-exec per call — identical cost to the backticks it replaced. The version-write and `--dry-run` paths run once per consumer action. No hot path, no scaling dimension, no caching.

## Documentation
### Runbooks
- Recovery from a stuck old updater / forward-only reach: INSTALL.md § "Recovering an install stuck on an old cwf-manage".
- Hash refresh discipline: `.cwf/docs/conventions/hash-updates.md`.
- `fix-security [--dry-run]` usage: `cwf-manage help` (documented this task).

### Knowledge Base
- **Design rationale**: c-design-plan.md (FR4 fork-exec `open '-|'` over IPC::Open3; FR3 deferral).
- **Execution record**: f-implementation-exec.md (the in-flight `POSIX::_exit` "statement unlikely to be reached" fix; deviations).
- **Dead-code audit**: `.cwf/docs/dead-code-audit.md` — periodic sweep; no symbols were removed this task, but the helper-extraction pattern is worth confirming has no orphaned callers.

## Success Criteria
- [x] Integrity + regression gates identified as the standing health signal (validate, three `t/` harnesses, perlcritic policy)
- [x] Recurring obligations tied to edits of `cwf-manage` / git invocations / fix-security args
- [x] Common failure modes documented with non-smoothing resolutions
- [x] Deferred follow-up recorded (copy-method convergence) — not silent debt, not retired here
- [x] Runbooks/KB cross-referenced (no new docs duplicated)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 159
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance is gate-based, not metric-based: `cwf-manage validate` for integrity, plus three `t/` harnesses and the perlcritic backtick policy as regression sentinels for FR1/FR2/FR4. The two things a future maintainer must keep in view are the forward-only reach of the version-write fix (delivered by the consumer's old updater) and the still-deferred copy-method convergence on the backlog.

## Lessons Learned
Maintenance for this change is gate-based, not metric-based: `validate` plus three `t/` harnesses and the perlcritic backtick policy are the regression sentinels. The two standing items for a future maintainer are the forward-only reach of the version-write fix and the still-deferred copy-method convergence. See j-retrospective.md.
