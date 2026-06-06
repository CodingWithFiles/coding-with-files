# Adopt guarded worktree enter/exit process - Maintenance
**Task**: 181 (feature)

## Task Reference
- **Task ID**: internal-181
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/181-adopt-guarded-worktree-process
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for Adopt guarded worktree enter/exit process.

## Monitoring Requirements
No runtime service, so no uptime/latency/resource monitoring. The standing signal is
the **FR9 detector**: `cwf-claude-settings-merge` warns on every install/update if either
settings file contains the substring `git worktree`, and the doc's pre-flight step warns
before each `EnterWorktree`. That warning *is* the ongoing monitor for the one residual
(a dangerous allowlist entry); it is advisory and closed only by operator action.

## Maintenance Tasks
### What can drift and needs upkeep
- **Harness tool/contract changes** (highest-value watch): the process is built on the
  harness `EnterWorktree`/`ExitWorktree` tools, the `worktree.baseRef` setting, and the
  C1/C2 behaviours. If a future harness renames/removes the tools, changes the
  `worktree.baseRef` schema, or alters the refusal-on-uncommitted gate, update
  `worktree-process.md` accordingly. The doc already mandates "tool-load failure is a
  stop, not a fallback", so a rename degrades safely (stop + surface) rather than
  silently reopening the raw-`git worktree` path.
- **Hash-tracked helper**: any future edit to `cwf-claude-settings-merge` must refresh
  `.cwf/security/script-hashes.json` in the same commit and restore recorded perms
  (0500) — `hash-updates.md` / `feedback_hashed_script_working_perms`.
- **Convention peers**: keep `worktree-process.md` consistent with its `.cwf/docs/conventions/`
  peers (`tmp-paths.md`, `session-hygiene.md`) if their cross-links or style change.
- **No dependency/DB/log surface**: dead-code audit N/A (the change adds one small,
  reachable sub; no code is retired).

### Open follow-ups (tracked separately, not this task)
- **R2 — audit the 13 `--show-toplevel` call sites** for worktree-safety (per
  `feedback_worktree_cwd_dataloss`). Out of scope for Task 181 (which governs
  create/teardown only); remains an open backlog item.
- **`pretooluse-planning-write-guard` perms drift** (0700→0500): a pre-existing,
  unrelated working-tree drift restored to recorded perms this session; the underlying
  recurrence is a separate Medium backlog item, not introduced or owned by Task 181.

## Incident Response
### Common Issues
- **FR9 warning fires on a read-only entry** (e.g. `Bash(git worktree list)`): expected
  and acceptable — the substring match is deliberately simple and the operator judges.
  Resolution: review the entry; remove/narrow if it grants `remove`/`add`, otherwise
  ignore. Not a defect.
- **`EnterWorktree`/`ExitWorktree` not found via `ToolSearch`**: the tools were
  renamed/removed by the harness. Resolution per the doc: **stop and surface to the
  operator**; never fall back to raw `git worktree`. Update the doc to the new tool names.
- **A worktree is left orphaned under `.claude/worktrees/`** (e.g. probe interrupted):
  surface the path to the operator; remove via the guarded `ExitWorktree` (commit or
  delete scratch first), never blind `git worktree remove --force`.

### Troubleshooting Guide
- **Symptom**: install/update aborts around the settings-merge step.
  **Diagnosis**: it is *not* the FR9 scan — that scan is best-effort and cannot exit
  non-zero (verified TC-11.3/11.4). Look at `read_settings` (malformed `settings.json`)
  or other merge steps.
  **Resolution**: fix the malformed `.claude/settings.json`; re-run `cwf-manage update`.

## Performance Optimisation
N/A. The only added cost is two best-effort whole-file reads at install/update time
(NFR1). No scaling, caching, or query surface.

## Documentation
- **Runbook**: the process doc itself — `.cwf/docs/conventions/worktree-process.md`.
- **Knowledge base**: `reference_worktree_process` + `feedback_worktree_cwd_dataloss`
  memories; Task 172 (incident), Task 177 (C1–C6 facts), Task 181 (this adoption).

## Success Criteria
- [x] Standing detector (FR9) in place as the ongoing residual monitor.
- [x] Maintenance triggers documented (harness contract changes, hash discipline).
- [x] Common issues + troubleshooting captured.
- [x] Open follow-ups (R2, planning-guard drift) recorded as separate items.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
No runtime maintenance surface. Upkeep triggers documented: harness tool/contract changes
(degrade safely to stop), hash discipline on the helper. Two open follow-ups recorded as
separate items (R2 `--show-toplevel` audit; planning-guard perms drift).

## Lessons Learned
The doc's "tool-load failure is a stop, not a fallback" clause is itself the maintenance
safety net — a future tool rename degrades to surface-and-stop, never to raw `git worktree`.
