# Enforce recorded permissions as upper bound - Implementation Plan
**Task**: 170 (feature)

## Task Reference
- **Task ID**: internal-170
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/170-enforce-recorded-permissions-as-upper-bound
- **Template Version**: 2.1

## Goal
Implement the ceiling-only permission model (per the corrected c-design-plan): swap the floor predicate for a ceiling in `Security.pm`, add a `clamp` repair to `cwf-manage`, flip the 31 `0500`-recorded dev scripts to on-disk `0500`, refresh hashes, and update tests + docs.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/lib/CWF/Validate/Security.pm` — in the `if (defined $expected_perms)` block (~lines 112–125), **replace** the floor predicate `($actual_perms & $min_perms) != $min_perms` with the ceiling predicate `($actual_perms & ~$expected & oct('07777')) != 0`; emit a ceiling `_violation` (hint: strip excess / run `fix-security`). Rewrite the header comment (line 7: "has permissions >= 0500 (for scripts) or any valid perms (for lib files)") fully — drop the floor/`>=` framing, state recorded perms = ceiling (less allowed, more flagged).
- `.cwf/scripts/cwf-manage` — (a) **replace** the `additive` branch of `_apply_recorded_perms`'s mode guard (~line 685, the `else`) with a `'clamp'` branch: `want = $actual_perms & oct($expected_perms)`, skip when `$actual_perms == $want` (clamp only clears, so no-excess ⟺ actual==want — same idiom as the `exact` skip). `additive` becomes unreachable once `cmd_fix_security` moves off it, so removing it (rather than leaving dead code) keeps the dispatch to two modes: `exact` (laydown) + `clamp` (fix-security). (b) update the mode comment block (~626–630) to describe `exact`/`clamp` only. (c) switch `cmd_fix_security`'s call (line 733) from `'additive'` to `'clamp'`. (d) **`apply_exact_perms_or_die` / `exact` mode (line 767, caller `cmd_update:500`) is intentionally unchanged** — laydown must establish exact least-privilege, and exact == recorded ⊆ ceiling so a laid-down tree passes the new check. (e) verify the `fix-security` help text (793–795, already direction-neutral — expect no change) and `%FIX_SECURITY_RECOVERY` (569; has no `permissions` key, so a chmod failure surfaces via the generic path — do **not** add a perms hint that says "restore/raise"; any perms wording says "clear excess").
- `oct($expected_perms)` is trusted (integrity-pinned JSON, all values well-formed `0444`/`0500`/`0700`, `defined` guarded) — consistent with the existing manifest trust model; no new validation added.

### Supporting Changes
- **Dev working-perm flip**: `chmod 0500` the 31 scripts recorded `0500` (currently on-disk `0700`). The **8 scripts recorded `0700` stay at on-disk `0700`** (recorded == on-disk, ceiling never fires — do NOT flip them); `Security.pm` stays `0600` (lib, no perms key). Derive both lists from `script-hashes.json` by recorded value (`permissions == "0500"` → flip; `== "0700"` → leave), do not hardcode. `0500` (r-x) keeps the scripts executable for the workflow; `0400` would break execution.
- `.cwf/security/script-hashes.json` — refresh `sha256` for the two edited code files (`CWF::Validate::Security`, `cwf-manage`). The perm flip needs **no** sha change (content unchanged); recorded `permissions` values are unchanged.

### Tests (detail in e-testing-plan.md)
- `t/validate-security.t` — **add** over/under-permissive subtests (there is no dedicated floor subtest today): over-permissive flags, under-permissive passes (the inversion), setuid acquisition flags, `.pm`/unrecorded unaffected.
- `t/cwf-manage-fix-security.t` — under clamp the breaking assertions are the **raise-to-recorded** ones:
  - **TC-4 (`:226`) and TC-5 (`:246`)** assert a `0644`-stripped script is raised to recorded — these genuinely break (clamp gives `0644 & 0500 = 0400`). Rewrite those assertions to clamp results; keep TC-4's existence/recovery-hint assertions and TC-5's mixed-result assertions.
  - **TC-2 (`:165`)** passes only because the `_ensure_cwf_manage_executable` bootstrap (`:40`) re-chmods `cwf-manage` to `0700` before the run; its intent ("fix raised perms") is now false. Rewrite to assert clamp on a **non-bootstrap** script and that post-`validate` passes (stripped scripts land ≤ recorded).
  - **TC-7 (`:266`)** idempotency asserts exit codes + "repaired 0" — likely still passes under clamp; **verify, don't assume rewrite**.
  - Add: over-permissive (`0700`/rec`0500` → stripped to `0500`) and under-permissive (`0400`/rec`0500` → no-op, validate passes) cases. Keep sha-gate (TC-3), dry-run, unknown-arg cases.
- **Read-only-source harness fix (the "rework for 0500 sources" the user mandated)**: once the 31 scripts are `0500` in-repo, any test that `cp -rp`s the tree and then opens a copied script for **write/append** dies "Permission denied". Audit the 5 tree-copying harnesses — `t/install-bash-reinstall.t`, `t/cwf-manage-fix-security.t`, `t/cwf-manage-update-end-to-end.t`, `t/cwf-claude-settings-merge.t`, `t/taskcontextinference.t` — and make their mutation helpers force-writable first. Known sites: `install-bash-reinstall.t::write_file` (`:78`, `open '>'`) and `cwf-manage-fix-security.t::append_byte` (`open '>>'`); fix is a `chmod u+w $path if -e $path` before the open (single-point fix in each shared helper). The `prove t/` gate (S8) catches any missed harness. NOTE: this is the real TC-5 (in `t/install-bash-reinstall.t:237`), not `cwf-manage-update-end-to-end.t` — this is the Task 162 failure the working-perms memory records, now resolved by fixing the harness rather than by the `0700` convention.
- Install/update e2e (`t/cwf-manage-update-end-to-end.t`) — `install.bash` itself needs no change (`rm -rf`+`cp -r`+additive `chmod u+rx` at `:251` is mode-agnostic); add an assertion that **post-`update` the laid-down tree (exact mode) validates clean under the new ceiling** (guards `exact` from silently diverging from the ceiling).

### Docs / memory
- `.cwf/docs/conventions/hash-updates.md` (and the `Security.pm` header comment) — state recorded `permissions` = ceiling: less-permissive allowed, more-permissive flagged; recorded ceilings for scripts MUST NOT carry group/other **write or execute** bits, nor setuid/setgid/sticky (data entries keep g/o **read** at `0444`).
- Working-perms memory `feedback_hashed_script_working_perms` — update: working perms now **match recorded** (e.g. `0500`), not bumped to `0700`; the TC-5 rationale for `0700` is retired (verify in this task).

## Implementation Steps
Order matters: the ceiling check, the perm flip, and the hash refresh land in **one commit** (else the dev tree's `0700` scripts fail the new ceiling). Build it as one logical change:
- [ ] **S1 — Security.pm**: swap floor→ceiling predicate + rewrite header comment.
- [ ] **S2 — cwf-manage**: replace `additive` branch with `clamp`, switch `fix-security` to it, update mode comment (exact/clamp), confirm exact-laydown untouched, check help/recovery wording.
- [ ] **S3 — Tests with code**: add ceiling subtests to `validate-security.t`; rewrite `cwf-manage-fix-security.t` TC-4/TC-5 (+ TC-2 caveat, verify TC-7) and add over/under cases; add the e2e ceiling-after-update assertion.
- [ ] **S4 — Read-only-source harness fix**: make the mutation helpers in the 5 tree-copying harnesses force-writable (`chmod u+w` before write/append) so `0500` sources don't break them.
- [ ] **S5 — Perm flip**: `chmod 0500` the 31 `0500`-recorded scripts (list derived from manifest); leave the 8 `0700`-recorded scripts at `0700`.
- [ ] **S6 — Hash refresh**: recompute sha256 for `Security.pm` + `cwf-manage` into `script-hashes.json` (per hash-updates convention).
- [ ] **S7 — Docs/memory**: hash-updates.md (ceiling semantics + g/o write-or-execute & setuid bound) + working-perms memory (working perms now match recorded; `0700`-bump rationale retired).
- [ ] **S8 — Restore working perms**: confirm `cwf-manage` is `0700` after editing (guard; the flip excludes it).
- [ ] **S9 — Full gate**: `prove t/` (all), `.cwf/scripts/cwf-manage validate` → OK; output-level smoke (run `validate` against a deliberately over-permissive fixture and confirm the ceiling message).

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Decomposition Check
- [ ] **Time/People/Complexity/Risk/Independence**: unchanged from design — single cohesive change to the integrity subsystem; the perm flip and ceiling check cannot be split (correctness ordering). No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All nine steps (S1–S9) executed in order. The one-commit constraint (check + flip +
hash refresh) held — commit `ace8d65`. The read-only-source harness fix (S4) was
needed only for the two helpers that open for write (`append_byte`, `write_file`);
the other three tree-copiers passed untouched, confirmed empirically by the S9 gate.

## Lessons Learned
The d-plan's correction of the TC-5 citation (the real break is
`install-bash-reinstall.t:78`, not the update-e2e suite) was vindicated at exec —
that is exactly where "Permission denied" fired. Plan-time precision on the failing
file saved a debugging cycle.
