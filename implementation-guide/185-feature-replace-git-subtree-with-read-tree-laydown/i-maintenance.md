# Replace git-subtree with read-tree laydown - Maintenance
**Task**: 185 (feature)

## Task Reference
- **Task ID**: internal-185
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/185-replace-git-subtree-with-read-tree-laydown
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for Replace git-subtree with read-tree laydown.

## Monitoring Requirements
CWF is local tooling with no runtime service, uptime, or telemetry. "Monitoring" here is
the set of integrity/behaviour checks a maintainer or consumer runs on demand:
- **`cwf-manage validate`** — recorded perms + sha256 over the laid-down tree. The
  authoritative post-migration health check (the migration runs
  `apply_exact_perms_or_die`, so a migrated consumer validates clean).
- **`cwf-manage check-merges`** — on-demand, read-only merge-commit report; the same
  surface the migration emits automatically. Used during the maintainer's individual
  outreach to consumers.
- **`prove t/`** — regression gate in the CWF dev repo; must stay green.

## Maintenance Invariants (must not regress)
These are the load-bearing properties of this change; a future edit that breaks one is a
defect even if tests still pass:
- **`CWF_PAIRS` elements stay string literals** in `scripts/install.bash`. The read-tree
  laydown is injection-safe *because* `$src`/`$dest` are hardcoded. Never plumb a prefix
  from an env var, manifest, or any external input — a `../`-bearing `$dest` would let
  `read-tree --prefix` escape the staging area (flagged in the implementation-exec security
  review).
- **`cwf-detect-merges` stays counts-only and read-only.** It must never echo a raw commit
  subject (prompt-injection surface), never mutate the repo, and always `exit 0`. The
  under-claim rule (ambiguous → total, never the CWF subset) is a correctness contract:
  never over-claim a user's own merge.
- **Migration stays fail-closed.** `cwf_method` is rewritten to `read-tree` only after
  laydown/artefacts/perms succeed. The detector is invoked with its rc **ignored** — a
  detection fault must never abort a good migration (TC-12).
- **Hash discipline.** Any edit to `cwf-manage` or `cwf-detect-merges` refreshes
  `script-hashes.json` in the **same commit** (`.cwf/docs/conventions/hash-updates.md`).
- **`subtree` stays refused for fresh installs but migrated on update.** Do not "helpfully"
  re-add a subtree laydown path.

### Preventive Maintenance
- Dead-code audit (`.cwf/docs/dead-code-audit.md`) — note `seed_tracked_dirs` in
  `t/install-bash-reinstall.t` is now unused (the item-1 subtests it served were removed);
  a future sweep may drop it.
- Keep the fingerprint current: if a future git changes the squash-merge shape (subject
  `Squashed '…' content` or the absence of a `git-subtree-dir` trailer), revisit
  `second_parent_is_squash` in `cwf-detect-merges`.

## Incident Response
### Common Issues / Troubleshooting Runbook
- **Fresh `curl|bash` install shows `validate` perm violations.**
  *Diagnosis*: recorded-ceiling drift — `git checkout-index`/`cp` honour umask, not the
  recorded ceiling. **Pre-existing and identical for `copy`**, not a read-tree regression.
  *Resolution*: `cwf-manage fix-security` (clamps to ceiling). The `update` path does this
  automatically.
- **`read-tree` install aborts with "refusing to install: source tree contains an
  out-of-tree symlink".** *Diagnosis*: the upstream source carries an escaping symlink under
  a CWF prefix; the guard fired before any consumer-tree change (fail-closed, working as
  designed). *Resolution*: fix the source; do not bypass the guard.
- **`read-tree failed for <prefix>` / "Cannot bind".** *Diagnosis*: a dest prefix was not
  cleared before laydown (read-tree refuses to overlay). The installer clears all four
  prefixes first; a stale state can be recovered by re-running (the clear is idempotent).
  *Resolution*: re-run the install/update.
- **`git fetch from clone failed`.** *Diagnosis*: the source clone's `HEAD` was not at the
  intended ref. The installer fetches the clone's `HEAD` (just checked out to `$ref`) rather
  than `$ref` by name precisely so a raw-SHA `$ref` is fetchable. *Resolution*: confirm the
  clone checkout step succeeded.
- **`check-merges` attributes a merge wrongly.** *Diagnosis*: over-claim is a bug
  (rollback-worthy); under-claim (an "Add CWF …" subject with no squash second parent shown
  in "elsewhere") is correct by design. *Resolution*: only over-claim warrants a fix to the
  fingerprint predicate.

### Escalation
Re-linearisation of a consumer's history is **out of CWF's scope by design** — the maintainer
handles it individually with a separate skill. CWF never rewrites consumer history.

## Success Criteria
- [x] On-demand health checks documented (`validate`, `check-merges`, `prove`)
- [x] Maintenance invariants recorded (laydown literals, counts-only detector, fail-closed
      migration, hash discipline)
- [x] Common issues documented with resolutions (perms ceiling, symlink guard, prefix
      collision, fetch, mis-attribution)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
