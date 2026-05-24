# converge cwf-manage copy update onto install.bash - Maintenance
**Task**: 161 (feature)

## Task Reference
- **Task ID**: internal-161
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/161-converge-cwf-manage-copy-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Define what keeps the converged copy path and the extracted symlink-escape guard healthy over time. CWF is a per-repo tooling system with no server, uptime, or telemetry — "maintenance" here means the integrity gates, the regression sentinels, and the single-laydown-path invariant that prevent the change from silently drifting back to two divergent copy implementations.

## Monitoring Requirements
No runtime metrics exist or are added. Health is verified on demand by deterministic gates run inside the consumer's repo:
- **Integrity gate**: `cwf-manage validate` (SHA256 over `script-hashes.json` + recorded perms) — now also covers the new `cwf-check-tree-symlinks` helper (0500). The authoritative signal that the guard helper was laid down intact and its hash refreshed in the same commit.
- **Regression sentinels**:
  - `t/cwf-check-tree-symlinks.t` — unit (`_escapes_src`, incl. the source-root-equal `..` branch) + CLI (exit 0 clean / non-zero+message on escape / exit 2 no-args / per-root attribution) + TC-7 (ledger entry, `@CWF_INTERNAL_PREFIXES` coverage, tamper → sha256 violation). The guard's primary sentinel.
  - `t/install-bash-reinstall.t` — TC-3 (fresh copy refuses an escaping upstream, no `.cwf` laid down), TC-4 (guard runs *before* `rm -rf`; existing install survives a refused source), TC-6 (copy vs subtree `.cwf-rules` + `.claude/rules` symlink parity). The guard-ordering + laydown-parity sentinel.
  - `t/cwf-manage-update-end-to-end.t` — TC-5 (copy-method `update` over an existing install delegates to `install.bash`; method stays `copy`, `cwf_ref` recorded, rules symlink regenerated). The convergence sentinel at the integration level.
  - `t/cwf-manage-update.t` — TC-8 (the six removed copy-laydown subs + five orphaned imports stay absent from `cwf-manage`). The anti-regression guard against the dead code creeping back.
- **No alerting pipeline**: there is nothing to page on. The sole external signal is consumer-filed issues.

## Maintenance Tasks
### Recurring obligations
- **Single laydown path is the invariant**: any change to how the tree is copied/symlinked on install OR copy-update belongs in `scripts/install.bash` only. Do not reintroduce a parallel laydown in `cwf-manage` — that divergence (and its unguarded fresh-copy path) is exactly what this task removed. `cwf-manage`'s copy branch must stay a thin delegation to `install.bash`.
- **On any edit to `cwf-check-tree-symlinks`**: re-run the full `t/` suite, then refresh its sha256 in `script-hashes.json` in the same commit (per `.cwf/docs/conventions/hash-updates.md`). The guard is integrity-covered precisely so a weakening edit cannot pass `validate` silently.
- **Never weaken the guard to make an install proceed**: if a source tree is refused, the out-of-tree symlink is the problem, not the guard ("surface, never smooth"). The guard is lexical (no disk-following) and fails closed on readlink failure and on absolute/`..`-escaping/source-root-equal targets — keep all three branches.
- **Preserve guard-before-mutation ordering in `install_copy`**: the guard and its `[[ -x "$guard" ]] || die` precheck must run before any `rm -rf`/`cp`. A silent skip when the helper is absent would be a fail-open (violates FR2/NFR5). TC-4 is the ordering sentinel.

### Follow-up status
- **This task IS the deferred follow-up.** FR3 (copy-method convergence) was deferred at Task 159's design gate and parked on the BACKLOG as "Converge cwf-manage copy-method update onto install.bash". This task implements it; the backlog item is to be **retired against task 161** in the retrospective. No new follow-up is filed.

## Incident Response
### Common Issues
- **A clean source tree is refused with "out-of-tree symlink"**: a false positive in the guard, or an in-tree symlink the lexical check mis-resolves. Diagnosis: run `cwf-check-tree-symlinks <root>...` directly; STDERR names the offending `entry -> target`. Resolution: confirm the named target genuinely stays within a source root; if the symlink is legitimately in-tree and still refused, the `_collapse_dotdot`/`_escapes_src` logic regressed — `t/cwf-check-tree-symlinks.t` unit cases are the guard. Do not disable the check to proceed.
- **`install.bash` copy install dies with "symlink-escape guard missing from source tree"**: the target ref predates the guard helper (pre-161). Resolution: install/update to a ref at/after 161, which carries the helper. This is the intended fail-closed precheck, not a defect.
- **A copy install/update lays down a tree that differs from a subtree install**: convergence regression. Diagnosis: `t/install-bash-reinstall.t` TC-6 parity assertion. Resolution: the divergence is in `install.bash` (the single laydown path) — fix it there; never re-fork a copy-specific path in `cwf-manage`.
- **`validate` fails immediately after an update**: the exact-perms / SHA guard is fatal-on-mismatch by design (it does not silently repair). Diagnosis: incomplete laydown or a tampered file. Resolution: re-run the bootstrap installer for the target tag; never reach for a hash-recompute tool.

### Troubleshooting Guide
- **Symptom**: `cwf-manage update` with `cwf_method=copy` errors with "Unknown install method". **Diagnosis**: the method field in `.cwf/version` is neither `subtree` nor `copy`. **Resolution**: the converged `cmd_update` validates the method up front and dies closed on anything else — correct the recorded method or reinstall.
- **Symptom**: the guard exits 0 on a tree that contains an out-of-tree symlink. **Diagnosis**: a `-l` entry was skipped (the walk only inspects symlinks) or `_escapes_src` regressed. **Resolution**: the `t/cwf-check-tree-symlinks.t` CLI escape subtests are the guard; extend them with the missed shape before re-fixing.

## Performance Optimisation
Not applicable. The guard is one `File::Find` lexical walk over the source roots per install/update — no disk-following, run once per consumer action. No hot path, no scaling dimension, no caching.

## Documentation
### Runbooks
- Recovery from a target ref that predates the guard, or a stuck old updater: INSTALL.md bootstrap reinstall (`CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<url> bash install.bash`).
- Hash refresh discipline: `.cwf/docs/conventions/hash-updates.md`.

### Knowledge Base
- **Design rationale**: c-design-plan.md (single-laydown-path convergence; guard extraction into one integrity-covered helper; D4 trust-model shift — guard runs from the target-version clone).
- **Execution record**: f-implementation-exec.md (the five-not-three orphaned-import removal; the `[[ -x ]]` precheck deviation from the plan's snippet) and g-testing-exec.md (the `chmod 0700` tamper-fixture fix; the `exec ... or POSIX::_exit` idiom).
- **Dead-code audit**: `.cwf/docs/dead-code-audit.md` — this task removed six subs + five imports; TC-8 is the standing guard that they stay removed.

## Success Criteria
- [x] Integrity + regression gates identified as the standing health signal (validate, four `t/` harnesses)
- [x] Single-laydown-path invariant recorded as the primary maintenance obligation
- [x] Guard-weakening and fail-open footguns documented with non-smoothing resolutions
- [x] Follow-up status resolved (this task implements the deferred FR3; backlog item to be retired against 161)
- [x] Runbooks/KB cross-referenced (no new docs duplicated)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 161
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance is gate-based, not metric-based: `cwf-manage validate` (now covering `cwf-check-tree-symlinks`) for integrity, plus four `t/` harnesses as regression sentinels. The standing obligation for a future maintainer is the single-laydown-path invariant — all install/copy-update laydown changes go in `install.bash`, never re-forked in `cwf-manage` — and never weakening the guard to make a refused install proceed.

## Lessons Learned
The maintenance burden of a convergence task is mostly an *invariant to defend*, not a process to run: keep the laydown in one place (`install.bash`) and keep the guard integrity-covered and fail-closed. TC-8 (dead code stays gone) and TC-6 (copy/subtree parity) are the two sentinels that catch re-divergence. See j-retrospective.md.
