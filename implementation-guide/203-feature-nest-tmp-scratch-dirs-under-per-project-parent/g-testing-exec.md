# Nest tmp scratch dirs under per-project parent dir - Testing Execution
**Task**: 203 (feature)

## Task Reference
- **Task ID**: internal-203
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/203-nest-tmp-scratch-dirs-under-per-project-parent
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready (Perl core + Test::More)
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

### Functional Tests (`t/security-review-changeset.t` — extended in place)

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-OUTFILE | `.out` written under nested path; parent + leaf 0700; `.out` 0600 | path matches `…/cwf<dash>/task-<num>/…`; both dirs 0700; `.out` 0600 | path nested ✓; parent 0700 ✓; leaf 0700 ✓; `.out` 0600 ✓ | PASS | subtest 29; 2 new load-bearing assertions (nested shape + parent mode) |
| TC-PARENT-SYMLINK | symlinked `cwf<dash>` parent rejected | exit 1, diagnostic, no write-through | exit 1 ✓; stderr names unusable parent ✓; attacker dir empty ✓ | PASS | subtest 30; `@CLEANUP_SYMLINK` unlink teardown (survives subtest failure) |
| TC-PARENT-REUSE | pre-existing 0755 parent reused unchanged | proceeds; parent stays 0755 (no auto-chmod); leaf written | exit 0 ✓; parent still 0755 ✓; `.out` written ✓ | PASS | subtest 31; observable "never auto-chmod" |
| TC-CLEANUP (END block) | leaf + now-empty `cwf<dash>` parent removed; no `/tmp` residue | both rmdir'd after `.out` unlink | no residue across full-suite runs | PASS | hygiene; verified by repeated full-suite runs leaving no `cwf*` leftovers |
| Regression (full `t/`) | all other suites green | 809 tests | 808 PASS, 1 FAIL (TC-VALIDATE only) | PARTIAL | see Test Failures — the one failure is an in-flight-status artifact, not a regression |

### Non-Functional Tests
- **Security (FR4a / AC6)**: TC-PARENT-SYMLINK + TC-PARENT-REUSE above exercise the
  defence-in-depth `-d && !-l` parent reject and the no-auto-chmod posture. The Step-8
  security-review subagent (below) found **no findings**; the changeset adds no shell-out
  and the new path uses only the already-validated `$task_num` + literal `cwf`/`task-` segments.
- **Reliability (FR5 / D6)**: manual provisioning smoke (`d6-provision-smoke.bash`) confirmed
  both the success path (creates `task-999` at 0700, surfaces the path) and the forced-failure
  path (leaf pre-planted as a regular file → `mkdir` fails → `WARNING` printed, no path
  claimed, snippet rc 0 = non-fatal). Helper leaf-mkdir failure is fail-closed (warn + exit 1),
  covered by the functional cases.
- **Performance (NFR1)**: one extra `mkdir` at first use; no measurable change (full suite
  wall-clock unchanged at ~37–39s).

### Output-level smoke (rebrands-need-output-smoke lesson)
Real helper run in this repo wrote its `.out` to
`/tmp/cwf-home-matt-repo-coding-with-files/task-203/security-review-changeset-implementation-exec.out`
— parent **and** leaf both 0700, parent basename begins with `cwf` (provably disjoint from the
`-tool-check` carve-out). Grep sweep: no stale sibling-form refs in active docs/scripts (sole
`-task-` hit is the deliberate rejected-basename counter-example in `tmp-paths.md`); the
`-tool-check` state-dir form is intact (D5).

## Test Failures

**TC-VALIDATE (`t/security-review-changeset.t` subtest 37) — FAIL, not a regression.**
- **What it asserts**: the *live* repo's `cwf-manage validate` exits 0 (fully clean).
- **Why it fails now**: Task 203's in-flight phase files (`a`–`e`) carry template placeholder
  statuses ("Planning", "Requirements", "Design", "Implementation Planning", "Testing Planning")
  which are not in `cwf-project.json`'s status-values set, so `validate` reports 5 `[WORKFLOW]`
  violations and exits non-zero.
- **Pre-existing, not caused by this change**: those files were committed during the planning
  phases (commits 514f796…55b96e0), so `validate` was already non-clean at HEAD before f-exec.
  The fixture-based `t/validate-workflow.t` passes; only this live-repo assertion trips.
- **Resolution path**: the standing convention performs the status sweep (all phases →
  Finished/Skipped) before the retrospective (j). Once swept, `validate` is clean and
  TC-VALIDATE goes green. The TC-VALIDATE assertions specific to *this change* (no integrity
  violation names the helper or the agent) already pass — the hash refresh is consistent.
- **Reproduction**: `prove t/security-review-changeset.t` with any CWF task mid-flight whose
  phase files still hold placeholder statuses.

## Coverage Report

New/changed security-critical behaviour (nested path derivation, two-level mkdir, parent
symlink-reject, shared-parent reuse, END-block cleanup): covered by TC-OUTFILE,
TC-PARENT-SYMLINK, TC-PARENT-REUSE and the cleanup block — 100% of the planned coverage targets
in e-testing-plan.md. D6 provisioning (a skill step, not a `t/` test) covered by manual smoke.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*Consolidated in j-retrospective.md.*

## Security Review

**State**: no findings

## Security review — Task 203 testing-exec changeset

I read the full changeset at `/tmp/cwf-home-matt-repo-coding-with-files/task-203/security-review-changeset-testing-exec.out` and reviewed it against the FR4(a–e) threat categories under the single-user developer-host model. Since the baseline anchor the new material beyond what implementation-exec already reviewed is: the extended test file `t/security-review-changeset.t` (TC-PARENT-SYMLINK, TC-PARENT-REUSE, extended END-block cleanup, extended TC-OUTFILE assertions) and the workflow docs `f-implementation-exec.md` / `g-testing-exec.md`. The helper code, the `tmp-paths.md`/`CLAUDE.md`/skill doc edits, and the in-commit sha256 refresh are unchanged from the implementation-exec review (which had no findings). I focused on the new test code, as instructed.

### (a) Injection / command execution

No new shell-out, `system`, backticks, `eval` of data, or string-built commands in the test code. The new subtests drive the helper through the existing `run_helper`/`git_in` harness helpers, which pass arguments as lists (not via a shell string). Path manipulation is pure Perl regex (`s{/[^/]+$}{}`) and the filesystem primitives `unlink`/`rmdir`/`symlink`/`make_path`/`chmod`/`opendir`/`readdir` are called with explicit arguments, not interpolated command lines. The one `eval { symlink('', ''); 1 }` is the established capability-probe idiom (matching the existing TC-SYMLINK skip guard), not data evaluation. No injection surface.

### (b) Path traversal / symlink / TOCTOU

This is the focus area for the new test code, and it is handled safely:

- **The planted symlink and attacker directory stay inside the test's own tempdir tree.** `make_synthetic_repo` returns a `tempdir(CLEANUP => 1)` root; `$attacker = "$repo-attacker"` and the planted `$parent` symlink are both derived from that root. The symlink target is the test-created `$attacker` dir, not a sensitive system path. Nothing is planted at an absolute attacker-chosen location.
- **The path components the test feeds back are derived, not attacker-shaped.** `$leaf`/`$parent` are computed by stripping trailing segments off the helper's own reported `.out` path (`out_path($o1)` from a clean first run), so the test targets exactly the canonical nested location the helper would use — it does not hand-craft a traversal path. The `skip 'no .out path to target'` guard prevents acting on an undefined path.
- **The write-through assertion is the right negative check.** After planting the parent symlink, TC-PARENT-SYMLINK re-runs the helper and asserts (i) exit 1, (ii) a diagnostic naming the unusable parent, and (iii) that `$attacker` is empty — i.e. no `.out` was written *through* the link. This correctly verifies the helper's `-d && !-l` lstat reject blocks the symlink-to-dir case rather than following it. The check confirms, rather than weakens, the traversal/symlink defence.
- **TOCTOU in the test is not a security concern.** The teardown ordering is deliberate and safe: planted symlinks are removed with `unlink` (never `rmdir`/`rmtree`), gated on `-l $l`, so cleanup cannot follow a link to delete a target directory's contents. The END block's `rmdir $leaf; rmdir $parent` only removes now-empty directories (no-op if non-empty), so a stray foreign entry under the shared parent is left intact rather than force-removed. The `@CLEANUP_SYMLINK` list runs in END even on subtest failure, so a leaked symlink cannot poison a re-run — that is a robustness improvement, not a risk.
- **The shared-parent reuse path is exercised without smoothing.** TC-PARENT-REUSE loosens the parent to 0755 and asserts the helper leaves it at 0755 (no auto-chmod), confirming the "surface, never smooth" posture is observable. This is a behavioural assertion on the helper already reviewed clean; the test adds no new filesystem risk.

### (c) Secret / credential exposure

No secrets in the diff. The test writes only synthetic `work`/`foo` script stubs and reads back `.out` content it generated. No credentials, `.env`, tokens, or real paths-with-secrets appear. The workflow docs (f/g) record the prior security review verbatim and test results; no secret material.

### (d) Untrusted-input handling / prompt-injection surface

The test data (synthetic repo content, the `work` script body) is entirely test-authored, not externally ingested. The f/g workflow docs are agent-facing process records, not new ingestion of untrusted external content. No new prompt-injection surface. The only externally-shaped helper inputs remain `$task_num` (regex-gated `^\d+(?:\.\d+)*$`) and `$wf_step` (allowlist-gated) — unchanged and not weakened by the tests; the TC-OUTFILE regex even re-asserts the `task-\d+(?:\.\d+)*` shape.

### (e) Environment-variable handling

The new subtests rely on the existing harness's `$TMPDIR` plumbing (synthetic repos and scratch land under a controlled tempdir); they introduce no new env-var reads or writes and do not alter `$TMPDIR` handling. No new environment surface.

### Integrity

The sha256 refresh (`b5662d45…` → `2f031317…`) and `0500` permission on `security-review-changeset` in `.cwf/security/script-hashes.json` are unchanged from the implementation-exec review, which confirmed byte-for-byte match and same-commit refresh per the hash-updates convention. The test file `t/security-review-changeset.t` is not a hashed script (no entry in `script-hashes.json`), so its edits need no hash refresh — consistent with the convention.

### Conclusion

The new test code plants its symlink and attacker directory entirely within its own `CLEANUP`-tracked tempdir tree, targets the helper's own derived scratch path (not an attacker-crafted traversal), removes symlinks with `unlink` (never following them), and asserts the helper rejects the symlinked parent without write-through. No injection, traversal, secret-exposure, untrusted-input, or env-var surface is introduced. The single-user threat model is upheld. No actionable security concerns.

```cwf-review
state: no findings
summary: New TC-PARENT-SYMLINK/TC-PARENT-REUSE tests plant symlink+attacker dir within their own CLEANUP tempdir, target the helper's derived path (no crafted traversal), tear down symlinks via unlink-only, and assert no write-through; helper/docs/hash unchanged from the clean implementation-exec review. Single-user model upheld.
```
