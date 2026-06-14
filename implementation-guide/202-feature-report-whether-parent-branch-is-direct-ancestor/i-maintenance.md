# report whether parent branch is direct ancestor - Maintenance
**Task**: 202 (feature)

## Task Reference
- **Task ID**: internal-202
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/202-report-whether-parent-branch-is-direct-ancestor
- **Template Version**: 2.1

## Goal
Define ongoing maintenance for the parent-branch-ancestry signal. This is a synchronous,
fail-soft addition to a local helper script — no running service, no SLA, no fleet.
Maintenance is the standard CWF integrity machinery plus the contract discipline that
keeps the tri-state honest.

## Monitoring Requirements
### System Health
- **No service to monitor.** The ancestry probe runs in-process during a
  `context-manager hierarchy` invocation and exits. Health is observed through CWF's
  existing integrity tooling, not uptime/latency metrics.
- **Integrity**: `cwf-manage validate` confirms the four edited files
  (`Common.pm`, `TaskPath.pm`, `context-manager.d/hierarchy`, `task-workflow.d/delete`)
  match their `script-hashes.json` sha256 entries. A mismatch is the primary health
  signal — surface it, never smooth.
- **Latency**: two extra `git` calls (`rev-parse --verify`, `merge-base --is-ancestor`)
  per *parented*-task `hierarchy` call; both are local and bounded. No external monitoring.

### Correctness signals
- **Tri-state contract**: `true`/`false`/`null` must keep distinguishing *diverged* from
  *undecidable*. The signal that this still holds is the regression suite — TC-1…TC-9
  cover every row of the c-design edge-case table.
- **Fail-soft**: any git error (unborn HEAD, missing branch) must yield `undef` → `null`,
  never a crash or a wrong verdict. A wrong verdict (e.g. `true` across diverged branches)
  is the only correctness incident worth a follow-up release.

## Maintenance Tasks
### Routine
- **On edit to any of the four files**: refresh the matching `script-hashes.json` sha256
  in the same commit (per `.cwf/docs/conventions/hash-updates.md`); deferring defeats the
  integrity check.
- **On reuse of `run_quiet`**: it is now shared from `CWF::Common`; new callers get the
  list-form fork/exec (shell-injection-safe) and `POSIX::_exit(127)` child for free. Keep
  call sites list-form — never interpolate a branch/path into a shell string.
- **On adding a `hierarchy` consumer**: treat `null` as "no assertion", never as
  "diverged". Code that conflates the two breaks the contract.
- **Per release**: `cwf-manage validate` after `update` confirms the four hashes installed
  intact.
- **Dead-code audit**: include `parent_branch_ancestry` and `run_quiet` in periodic sweeps
  (see `.cwf/docs/dead-code-audit.md`) — the function is dormant until a consumer reads it.

## Incident Response
### Common Issues
- **`hierarchy` asserts a wrong ancestry verdict**: investigate `parent_branch_ancestry`'s
  `merge-base` mapping (`0⇒1, 1⇒0, else⇒undef`) and the exact-match existence guard.
  A wrong `true`/`false` is a project-level defect — back out per h-rollout's procedure.
- **`cwf-manage validate` reports a hash mismatch on one of the four files**: integrity
  signal. Inspect the diff; if a legitimate edit, refresh the hash in the editing commit;
  if not, treat as tampering. Never add tooling that silences this without surfacing first.
- **`null` where a verdict was expected**: the parent branch is absent, the task is
  top-level, or HEAD is unborn — all correct `undef` outcomes, not bugs. The `branch_exists`
  glob is deliberately *not* reused here, so a prefix-collision sibling branch will not
  false-positive (TC-6).

### Troubleshooting Guide
- **Symptom**: unexpected `null`. **Diagnosis**: confirm the parent branch exists exactly
  (`git rev-parse --verify refs/heads/<type>/<num>-<slug>`) and HEAD is born.
  **Resolution**: none needed if the branch is genuinely absent — `null` is correct.
- **Symptom**: a downstream consumer treats divergence as a hard error. **Diagnosis**:
  it is conflating `false` (diverged) with `null` (undecidable). **Resolution**: fix the
  consumer to honour the tri-state.

### Escalation
- Local tool, single operator. No on-call tiers. The only condition warranting a
  project-level fix and follow-up release is a wrong ancestry verdict; everything else is
  a correct `undef`/`null` or an integrity signal handled by `cwf-manage validate`.

## Documentation
- **Contract**: the tri-state semantics are recorded in c-design-plan.md; the markdown
  line (`Parent branch ancestor of HEAD: yes|no|unknown`) is self-documenting.
- **Conventions touched**: `hash-updates.md` (in-task hash refresh), and the Task-159
  `POSIX::_exit` convention now embodied in the shared `run_quiet`.

## Success Criteria
- [x] Health/integrity signals identified (`cwf-manage validate`, regression suite)
- [x] Routine maintenance documented (hash refresh, list-form discipline, consumer contract)
- [x] Common issues documented with resolutions (wrong verdict, hash mismatch, expected null)
- [x] Escalation scoped to the single wrong-verdict defect class

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance model recorded: no service monitoring; integrity via `cwf-manage validate`,
correctness via the TC-1…TC-9 regression suite, and contract discipline (treat `null` as
"no assertion") for future consumers. The only project-level incident class is a wrong
ancestry verdict, handled by the h-rollout rollback path.

## Lessons Learned
*Consolidated in j-retrospective.md.*
