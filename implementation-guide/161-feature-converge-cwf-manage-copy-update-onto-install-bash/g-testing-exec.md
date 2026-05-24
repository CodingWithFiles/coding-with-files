# converge cwf-manage copy update onto install.bash - Testing Execution
**Task**: 161 (feature)

## Task Reference
- **Task ID**: internal-161
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/161-converge-cwf-manage-copy-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Execute TC-1..TC-8 from e-testing-plan.md and verify FR1-FR5 / AC1-AC9.

## Test Results

### Functional Tests

| Test ID | Test file | Coverage | Status |
|---------|-----------|----------|--------|
| TC-1 | `t/cwf-check-tree-symlinks.t` (`_escapes_src` unit) | sibling/same-dir allowed; absolute, `..`-escape, multi-parent, **source-root-equal** rejected | PASS |
| TC-2 | `t/cwf-check-tree-symlinks.t` (CLI) | clean multi-root → exit 0; escaping → non-zero + message; per-root attribution; pool-pointing allowed; no-args → exit 2 | PASS |
| TC-3 | `t/install-bash-reinstall.t` | fresh copy install refuses an absolute- and a `..`-escaping upstream symlink; no `.cwf` laid down | PASS |
| TC-4 | `t/install-bash-reinstall.t` | forced copy re-install over an existing install refuses an escaping source **and leaves the existing `.cwf/` + sentinel intact** (guard before `rm -rf`) | PASS |
| TC-5 | `t/cwf-manage-update-end-to-end.t` | copy-method `cwf-manage update` over an existing install succeeds; method stays `copy`; `cwf_ref` recorded; `.cwf`+`.cwf-rules` present; rules symlink regenerated | PASS |
| TC-6 | `t/install-bash-reinstall.t` | copy vs subtree install: identical `.cwf-rules` structure and `.claude/rules` symlink set | PASS |
| TC-7 | `t/cwf-check-tree-symlinks.t` | helper in `script-hashes.json` (path/0500/sha matches); `.cwf/scripts/` in `@CWF_INTERNAL_PREFIXES`; one-byte tamper → `CWF::Validate::Security` `sha256` violation | PASS |
| TC-8 | `t/cwf-manage-update.t` | six removed subs + five orphaned imports absent from `cwf-manage` | PASS |

**Full suite**: `prove -lr t/` → **49 files, 533 tests, all pass** (up from 527; +6 new subtests). `cwf-manage validate`: OK.

### Non-Functional Tests
- **Security**: TC-3/TC-4 (guard on both paths, fail-closed before mutation), TC-7 (integrity + tamper). The D4 trust-model shift (guard runs from the target-version copy) is documented/accepted, asserted by review not test.
- **Reliability (NFR5)**: TC-4 (existing install intact on refusal), TC-5 (`CWF_FORCE` idempotent over an existing tree).
- **Performance (NFR1)**: one lexical walk; no measurable latency — by inspection, no dedicated TC.
- **Maintainability (NFR3)**: TC-8 (two laydown paths collapsed; dead subs + imports removed).

## Test Failures
None. Two issues hit during test development (both fixed before the suite run):
- The guard test initially appended to a `0500` (read-only) fixture file → "Permission denied" → exit 2; fixed by `chmod 0700` before tampering.
- An `exec(...)` statement-unreachable warning in the forked child; silenced with the `exec(...) or POSIX::_exit(127)` idiom.

## Deviations from e-testing-plan.md
- **TC-1/TC-2** were authored during the implementation phase (Step 1) alongside the helper, not in this phase — same content as the e-plan specifies.
- **TC-2(c) readlink-failure** is covered by inspection, not an automated case: an `lstat` reporting `-l` while `readlink` fails is a TOCTOU/permission race not reproducible portably. The `unless (defined $link)` fail-closed guard is documented in the test file.
- **TC-6** placed in `t/install-bash-reinstall.t` (a fresh-install comparison) rather than the update e2e file; it compares two bare `install.bash` installs, which is where the copy/subtree laydown parity is established.

## AC → Test Case Map (all satisfied)
| AC | TC | Status |
|----|----|--------|
| AC1 (copy update via install.bash; no update_copy/copy_tree) | TC-5, TC-6, TC-8 | PASS |
| AC2 (callers enumerated; no orphaned ref; suite green) | TC-8 + full suite | PASS |
| AC3 (update refuses absolute/`..`/source-root-equal) | TC-1, TC-4 | PASS |
| AC4 (fresh install refuses the three escaping cases) | TC-3 | PASS |
| AC5 (guard before any copy; no partial laydown) | TC-2, TC-3, TC-4 | PASS |
| AC6 (ledger + prefixes + tamper detected) | TC-7 | PASS |
| AC7 (copy update over existing `.cwf/` succeeds) | TC-5 | PASS |
| AC8 (`.cwf-rules` once, identical to subtree; symlinks match) | TC-6 | PASS |
| AC9 (hash refresh same commit; validate each phase) | process gate — validate OK at every checkpoint | PASS |

## Coverage Report
Critical path (the symlink-escape guard) covered at unit, CLI, fresh-install, and update levels — both escaping forms plus the source-root-equal branch. Every AC maps to ≥1 passing TC.

## Security Review

**State**: no findings

The full `--phase=testing` changeset is 953 lines (> the 500-line cap) because it re-includes the already-reviewed implementation-phase source. Per the "split the change" remedy, the testing review was scoped to the 490-line test-file delta (the new material this phase); the three production source files were reviewed in the implementation phase (no findings) and are unchanged since. Subagent verdict on the test delta:

> no findings
>
> Reviewed the 490-line testing-phase delta across the test files. These are test artefacts: no shell-string interpolation of untrusted input (all `system`/`run`/`git_ok` use list-form, never `system($string)`), no newline-splitting of git output, no `{arguments}`-style LLM prompt-injection surface, no env-var path-handling defects (`CWF_SOURCE`/`CWF_METHOD` set via `local $ENV{...}` to test-controlled tempdir paths). The fixtures that intentionally plant attacker-shaped inputs (`/etc/passwd`, `../../../../../etc/passwd`, the `git rm` shim, the failing settings-merge stub) are the security tests themselves and confine those values to per-test `tempdir(CLEANUP=>1)` sandboxes. Each test's assertions verified against the real code it exercises — the escape logic, the `install.bash` guard-before-`rm -rf` ordering, the die message, the ledger entry, and the `field=sha256` tamper violation all match. `POSIX::_exit`-in-forked-child idiom correctly applied.
>
> Pattern-risk note (category (e)): the `taint_upstream` helper builds symlinks from a caller-supplied `%links` hash and re-points a git tag. Safe here because every callsite passes literal, test-author-controlled names/targets into a throwaway upstream tempdir; audit any future reuse where the link names/targets could derive from a non-literal/partly-external source.

No actionable findings; the pattern-risk note is advisory for future test reuse. Nothing to fix before rollout.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
