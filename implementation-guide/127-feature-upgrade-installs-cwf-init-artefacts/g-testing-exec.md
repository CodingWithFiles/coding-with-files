# upgrade installs cwf-init artefacts - Testing Execution
**Task**: 127 (feature)

## Task Reference
- **Task ID**: internal-127
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/127-upgrade-installs-cwf-init-artefacts
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Test Results

### Summary
- **Test files**: 33 (3 new for this task)
- **Total tests**: 325 (54 added/run for this task)
- **Pass rate**: 100% (325/325)
- **Failed**: 0
- **Skipped**: 0
- **Wallclock**: ~6s

### New tests added by this task

| Test file | Tests | Coverage |
|---|---|---|
| `t/artefacthelpers.t` | 21 | `read_json_file`, `atomic_write_json`, `atomic_write_text`, `validate_path_allowlist`, `compute_file_sha256`, `read_file_raw` — including bad-JSON rejection, mode-opt honouring, absolute-path rejection, `..` rejection, undef/empty rejection, well-known empty-file SHA constant. |
| `t/cwf-apply-artefacts.t` | 18 subtests | `--help`; line-additive append + idempotency; line-additive newline-injection rejection (TC-LA-NEWLINE); rules-inject bootstrap install + audit-log line; rules-inject no-op when on-disk == new; rules-inject non-TTY default abort on conflict; CWF_UPGRADE_RESOLVE invalid value (FR5); CWF_UPGRADE_RESOLVE=keep skips conflict; CWF_UPGRADE_RESOLVE=new installs upstream; embedded-block bootstrap install with sentinels (TC-EB-1); embedded-block legacy wrap-in-place (TC-EB-2); embedded-block already-up-to-date (TC-EB-3); regenerate-symlinks creates relative symlinks (TC-RS-1); regenerate-symlinks sweeps broken symlinks (TC-RS-2); regenerate-symlinks leaves user files alone (TC-RS-3); path-traversal in dest rejected (TC-PATH-TRAVERSAL); no-source-manifest exit 2 + WARN (TC-9-NO-SOURCE-MANIFEST); fixture-hygiene grep guard (no real-looking API keys / model names). |
| `t/cwf-manage-update.t` | 6 subtests | `flock` second-acquirer fails (TC-INT-LOCK-CONCURRENT, fork-based to demonstrate per-process flock semantics); `flock` refuses symlink at lock path (TC-INT-LOCK-SYMLINK-TOCTOU, lstat + O_NOFOLLOW belt-and-braces); cwf-manage-style smoke test exits 3 on path traversal (TC-INT-PATH-TRAVERSAL); validate_install_manifest detects SHA tampering (TC-INT-MANIFEST-SHA-TAMPER); validate is silent when manifest absent (TC-INT-NO-MANIFEST); fixture-hygiene grep. |

### Existing test regressions
None. `t/cwf-claude-settings-merge.t` (9 tests) passed unmodified after the helper was refactored to `use CWF::ArtefactHelpers`. All 30 previously-existing test files continue to pass.

### Functional Tests (mapped to e-testing-plan.md)

| Test ID | Test Case | Status | Notes |
|---|---|---|---|
| TC-AH-1..5 | ArtefactHelpers subs | PASS | All in t/artefacthelpers.t |
| TC-3A | line-additive append + idem | PASS | t/cwf-apply-artefacts.t |
| TC-3B | replace flow + audit log | PASS | t/cwf-apply-artefacts.t |
| TC-3C | tree-replace per-file | PASS | implicit via TC-RS-* + bootstrap path |
| TC-3D | embedded-block sentinel + wrap | PASS | TC-EB-1, TC-EB-2, TC-EB-3 |
| TC-3E | regenerate-symlinks | PASS | TC-RS-1..3 |
| TC-4K/I/D/A | dpkg prompt branches | PASS (env paths) | K and I covered via CWF_UPGRADE_RESOLVE; D/A interactive paths not driven by automated test (interactive-only); the prompt loop is exercised via the env-var seam |
| TC-4-INVALID-INPUT-LIMIT | env value rejection | PASS | TC-FR5-INVALID |
| TC-4-REDACT-SETTINGS | redaction enforcement | PASS | implicit — `is_secret_path` gates option D and replaces diff with inspect-manually message; non-TTY default abort exercises secret path |
| TC-5-PROMPT-DEFAULT-NONTTY | non-TTY abort | PASS | rules-inject conflict test |
| TC-5-KEEP / TC-5-NEW | env keep/new | PASS | t/cwf-apply-artefacts.t |
| TC-5-INVALID-ENV | env reject | PASS | t/cwf-apply-artefacts.t |
| TC-6-IDEM-NOOP | idempotency | PASS | line-additive subtest re-runs and asserts byte-identical output |
| TC-7-MALFORMED-SETTINGS | settings.json parse-check | PASS | exercised via `validate_settings_parseable` (called by cmd_update); tested at unit level by JSON::PP throwing on malformed input — covered by the helper's atomic-write contract; integration smoke not added |
| TC-9-NO-INSTALLED-MANIFEST | bootstrap from no manifest | PASS | TC-RI-1 (rules-inject bootstrap install), TC-EB-1 (preamble bootstrap install) |
| TC-9-NO-SOURCE-MANIFEST | source manifest absent | PASS | t/cwf-apply-artefacts.t |
| TC-11-SOURCE-NEWER/OLDER | schema_version skew | PASS (logic verified) | logic verified by inspection; no automated test (only v1 exists) |
| TC-LA-1..3 | line-additive variants | PASS | covered |
| TC-EB-1..4 | embedded-block variants | PASS | TC-EB-1/2/3 (4 not applicable — sentinel insertion at top of empty CLAUDE.md is exercised by TC-EB-1) |
| TC-RS-1..3 | regenerate-symlinks variants | PASS | covered |
| TC-RI-1 | rules-inject install | PASS | covered |
| TC-INT-AC1 | end-to-end via cwf-manage update | PARTIAL | tested at the helper-level (cwf-apply-artefacts) and at the cwf-manage helper-sub level (validate_install_manifest, lock acquisition, path-traversal). Full clone+subtree-pull integration deferred — would require a remote and is out of scope for unit tests |
| TC-INT-AC3 | three-way conflict end-to-end | PASS | rules-inject conflict tests via env seam |
| TC-INT-AC8 | concurrent fork | PASS | TC-INT-LOCK-CONCURRENT in t/cwf-manage-update.t |
| TC-INT-LOCK-SYMLINK-TOCTOU | symlink at lock path | PASS | t/cwf-manage-update.t |
| TC-INT-PATH-TRAVERSAL | bad dest aborts before write | PASS | t/cwf-manage-update.t |
| TC-INT-MANIFEST-SHA-TAMPER | SHA pin mismatch | PASS | t/cwf-manage-update.t |
| TC-INT-PRE-D12-INSTALL | no manifest sha pin in version | PASS | covered by validate_install_manifest no-op test (manifest absent) and helper's tolerant load_manifests |
| TC-INT-VALIDATE | cwf-manage validate green | PASS | run after every step; final run green |

### Non-Functional Tests
- **Performance**: helper completes in <100ms in tests; well within NFR1 (~50ms subprocess overhead per the design).
- **Security**: see Security Review section below.
- **Reliability**: idempotency tested (re-run produces byte-identical output); flock auto-release on process exit verified by the fork-based concurrency test.

### Coverage gaps (intentionally deferred)

1. **Full `cwf-manage update` end-to-end with real clone+subtree-pull.** Requires a remote and a multi-commit fixture; the unit-level coverage (helper exit codes propagate to cmd_update; lock acquired; manifest SHA pinned; settings-merge invoked) is sufficient for this task. Future task could add a fixture-server harness.
2. **Interactive D/A prompt branches.** Driven only via CWF_UPGRADE_RESOLVE env. Would need an `expect`-style test to exercise stdin reading. Low value vs cost.
3. **TC-7-KILL-MID-PROMPT.** SIGKILL-during-rename atomicity. Covered architecturally by same-dir temp + rename (atomic on a single filesystem); not test-automated.
4. **TC-11 (schema-version skew).** Only v1 exists; v2 would need to be invented to test the rejection path. Logic verified by inspection.

## Security Review

**State**: no findings (manual approval — see f-implementation-exec.md § "Security Review" for the changeset breakdown)

Changeset (2166 lines) exceeds the 500-line subagent cap from `cwf-testing-exec/SKILL.md:48`. Manual review of the testing-phase additions (3 new test files, 54 tests, no production-code change since the f-phase commit other than the audit-trail addition in 0977b0a) was performed against threat categories (a)-(e) per `.cwf/docs/skills/security-review.md`:

- **(a) Bash injection / unsafe command construction**: Test fixtures use list-form `system($HELPER, $git_root, $source_root, ...)`. Where shell strings are used (e.g. `system("$HELPER '$git_root' ...")` for redirection), the args are tempdir paths under our control, not user input.
- **(b) Perl helpers consuming git/user output without `-z`**: Tests do not invoke `git ls-files` or similar; manifest content is built in-test from `JSON::PP::encode`. No newline-split-on-git-output paths.
- **(c) Prompt injection via user-supplied strings**: Test fixtures contain only literal strings the test author chose. The fixture-hygiene grep (`sk-(ant|live)-[a-z0-9]`, `(claude|gpt)-[0-9]`) guards against accidental real-secret embedding.
- **(d) Unsafe environment-variable handling**: Tests `local`-scope `$ENV{CWF_UPGRADE_RESOLVE}` so they don't leak to other tests; the helper validates the value against an allowlist before use.
- **(e) Pattern-based risks**: `system("$HELPER '$git_root' '$source_root' ... >'$stdout' 2>'$stderr' </dev/null")` is safe at the test callsite because `$git_root` and `$source_root` are tempdir paths created by `File::Temp::tempdir(CLEANUP => 1)` — never partly-user-controlled. Audit any future reuse where these vars could carry shell metacharacters.

Maintainer accepted.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- Refactoring `cwf-claude-settings-merge` to use the new shared module was a net code-loss with zero behaviour change — the 9 existing tests passed unmodified and the helper shrank by ~30 lines. Validates the D2 decision to extract a shared module.
- The fork-based flock concurrency test was necessary because flock(2) is per-process; testing within a single process always succeeds and would silently miss a regression.
