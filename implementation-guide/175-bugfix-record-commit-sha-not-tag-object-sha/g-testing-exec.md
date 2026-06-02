# record commit sha not tag-object sha - Testing Execution
**Task**: 175 (bugfix)

## Task Reference
- **Task ID**: internal-175
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/175-record-commit-sha-not-tag-object-sha
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-1 | install.bash records the annotated-tag *commit* SHA | `cwf_sha == rev-parse <tag>^{commit}`, `!= rev-parse <tag>` | red→green (was tag-object SHA pre-fix) | PASS | `t/version-records-commit-sha.t` subtest 1; precondition asserts tag-object ≠ commit |
| TC-2 | cwf-manage update to annotated tag records commit SHA + keeps `cwf_version` | `cwf_sha` = commit, `cwf_version=v0.0.2` | red→green | PASS | subtest 2; `cwf_version` regression guard green before & after fix |
| TC-3 | copy method shares the fix (no duplicate case) | shared line 310 ⇒ no new case | n/a | N/A (by design) | `resolved_sha` computed once before the method branch |
| TC-4 | non-annotated refs unaffected (peel idempotent) | branch/lightweight/raw-SHA/HEAD unchanged | covered by existing E2E suites | PASS | no dedicated case; existing `build_upstream` (lightweight tags) suites pass unchanged |

### Non-Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-5 | Integrity: `cwf-manage validate` clean after edit + same-commit hash refresh | `validate: OK`, no `cwf-manage` violation | `[CWF] validate: OK` | PASS |
| Security | No new injection surface | list-form (Perl) / quoted single-arg (Bash) preserved | confirmed by exec-phase reviewer (no findings) | PASS |

**Regression suites** (named in e-plan): `t/install-bash-reinstall.t`, `t/cwf-manage-update-end-to-end.t`, `t/cwf-manage-update.t` — 28 tests, all PASS.

**Full suite**: `prove t/` — 55 files, **645 tests, all pass**.

## Test Failures

None in the final run. One transient failure surfaced and was resolved during this phase:

- **`t/cwf-manage-fix-security.t` TC-8** initially failed: provisioned `.claude/agents/cwf-security-reviewer-changeset.md` perms `0400` did not satisfy the recorded **floor** `0444`.
- **Root cause**: a *pre-existing local working-tree perm drift* (unrelated to Task 175's code diff). Earlier this session the drift was repaired with `cwf-manage fix-security`, which **clamps** (`actual & recorded` = `0600 & 0444 = 0400`) and can only remove bits — so it satisfied `validate`'s **ceiling** but left the file below TC-8's **floor**. The two checks together require the perm to equal the recorded value exactly.
- **Resolution**: `chmod 0444 .claude/agents/cwf-security-reviewer-changeset.md` — restored the file to its recorded perms (exactly what `install.bash` provisions for agent definitions). Perms are not git-tracked for non-executables (mode stays `100644`), so this is local environmental repair with **no git diff** and outside Task 175's changeset. Both `validate` (ceiling) and TC-8 (floor) now pass. Not masked, not absorbed — restored to recorded.

## Coverage Report

Both SHA-resolution sites covered by the annotated-tag discriminator: `scripts/install.bash:310` (TC-1) and `.cwf/scripts/cwf-manage` `resolve_sha:225` (TC-2). Non-annotated ref forms covered transitively by the existing lightweight-tag E2E suites (TC-4). 100% of the changed lines exercised.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*

## Security Review

**State**: no findings

Now I have the full threat model. Let me work through each category against the test harness.

## Review

I reviewed the testing-phase changeset for Task 175. The production diff (the two `^{commit}` peeling changes and the refreshed `cwf-manage` hash) was already cleared in the implementation phase and is byte-identical here; integrity/permission concerns belong to `cwf-manage validate`, not this review. My focus is the new test harness `/home/matt/repo/coding-with-files/t/version-records-commit-sha.t` and, by reference, the two CWF-internal workflow docs.

**(a) Bash injection / unsafe command construction.** Every external invocation in the harness uses list-form `system(@args)` / `run(cmd => [...])` — no single-string `system`, no shell parsing. Concretely: `cp_rp` (line 62) uses `system('cp', '-rp', ...)`; `write_file` (line 67) `system('mkdir', '-p', $dir)`; `git_ok` (line 81) `['git', '-C', $dir, @args]`; install at line 132 `['bash', "$upstream/scripts/install.bash"]`; manage at line 146 `['perl', "-I$consumer/.cwf/lib", ...]`. Fixture paths are derived from `tempdir()` and `$FindBin::Bin`, never from user input, and even so they are passed as discrete `execvp` arguments where shell metacharacters cannot fire. No injection surface.

The only backtick in the file is line 35: `bash -c 'echo \$BASH_VERSINFO'` — a fixed literal with no interpolation. Safe.

**(b) Perl consuming git output without `-z` / input validation.** `rev_parse` (lines 87-92) reads `git rev-parse` output and strips all whitespace with `s/\s+//g` to get a single 40-hex SHA — rev-parse emits one token, so there is no path-splitting hazard and `-z` is not applicable. No `split /\n/` over porcelain anywhere; `slurp` reads whole files. The `like/unlike` assertions `\Q$commit\E` / `\Q$tagobj\E` quote the interpolated SHAs in the regex, so even a malformed SHA could not inject regex metacharacters. Clean.

**(c) Prompt injection.** Not applicable — the test feeds no strings into LLM context. The fixture content (`E2E-MARKER`, commit/tag messages) is all hardcoded literals.

**(d) Unsafe environment-variable handling.** The harness *sets* `CWF_METHOD`, `CWF_SOURCE`, `CWF_REF`, `CWF_UPGRADE_RESOLVE` (lines 129-131, 144) and the four `GIT_*` identity vars (lines 29-32), all via `local $ENV{...}` so they are restored on scope exit and do not leak into the parent test process or sibling subtests. `CWF_SOURCE` is `"file://$upstream"` pointing at a tempdir — no network egress beyond a local `file://` clone, matching the stated isolation claim. The deterministic `GIT_*` identity prevents the test from depending on (or mutating) the developer's real git config. This mirrors the canonical safe pattern in `cwf-manage:85-87`. Correct handling.

**Real-repo / database isolation.** This is the load-bearing concern for a test that shells out to `install.bash` and `cwf-manage update`. I verified the harness never writes into `$REPO_ROOT`:
- `$REPO_ROOT` (line 25) is used only as the *source* of `cp -rp` (lines 102-107) — read-only copies out of the real tree into `$base/upstream`.
- All writes target `tempdir(CLEANUP => 1)` roots (`$base` in each subtest, lines 154/172) and the `tempfile(UNLINK => 1)` capture file (line 44).
- `build_upstream`, `install_consumer`, and `consumer_manage` all operate inside `$base/{upstream,consumer}` and pass `git -C <tempdir>` / `dir => <tempdir>`, never the real repo.
- `run` saves and restores real fd 1/2 around the child redirect (lines 46-54) and restores `chdir` (line 55), so a child process cannot leave the test with redirected stdio or a wandering cwd. The `chdir` is process-global, but every `run` brackets it with save/restore, so concurrent-state corruption within this single-process test is not possible.

No production database exists; the analogous "production state" is the real CWF repo, and it is touched read-only. Isolation holds.

**(e) Pattern-based risks.** One worth flagging for future reuse, not as a defect here:

The `run` helper (lines 39-60) redirects the *real* process-level STDOUT/STDERR to a tempfile and restores them afterward. This is safe **here because** the test is single-process, single-threaded, and every `run` call fully brackets the redirect with save/restore before returning — Test::More's TAP output (which also uses STDOUT) never overlaps a redirect window. Audit future uses where that invariant might not hold: if this helper were copied into a harness that emitted TAP/diagnostics concurrently with a `run` call (e.g. a forked or async runner), the redirect window would swallow or corrupt the test's own protocol output. The sibling-test convention re-implements helpers per file rather than importing, so this pattern will be copied; a one-line note in the helper that it assumes synchronous single-process use would protect the next reader. No change required for correctness in this file.

Everything else checks out. No actionable security concerns in the testing-phase changeset.

```cwf-review
state: no findings
summary: Test harness uses list-form spawn throughout, local $ENV for all env vars, writes only to CLEANUP tempdirs (real repo read-only); one safe-here pattern-reuse note on the global STDOUT-redirect helper, no fix required.
```
