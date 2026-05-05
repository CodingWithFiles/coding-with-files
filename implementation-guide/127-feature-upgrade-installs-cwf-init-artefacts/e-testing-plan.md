# upgrade installs cwf-init artefacts - Testing Plan
**Task**: 127 (feature)

## Task Reference
- **Task ID**: internal-127
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/127-upgrade-installs-cwf-init-artefacts
- **Template Version**: 2.1

## Goal
Map every requirement (FR1-FR12, NFR1-NFR5) and acceptance criterion (AC1-AC8) to a concrete TAP test, organised by file, with the fixture and assertion shape. Match the patterns already in use by `t/cwf-claude-settings-merge.t` so the new tests fit the existing harness.

## Test Strategy

### Test Levels
- **Unit (`t/artefacthelpers.t`)**: Pure functions in `CWF::ArtefactHelpers`. No filesystem-state assumptions beyond `tempdir`.
- **Helper-level (`t/cwf-apply-artefacts.t`)**: `cwf-apply-artefacts` invoked as a subprocess against synthetic fixtures (manifest + on-disk + source root, all under `tempdir`). One conflict mode per subtest.
- **Integration (`t/cwf-manage-update.t`)**: `cwf-manage update` end-to-end against a fake source repo. Asserts AC1 byte-identical convergence, FR11 lock behaviour, the path-traversal smoke test from implementation Step 4.
- **Init regression (`t/cwf-init-bootstrap.t`)**: Optional — exercise the new `--bootstrap-init` invocation in `/cwf-init` end-to-end. Skip if `t/cwf-manage-update.t` already covers `--bootstrap-init` via the helper directly.
- **Existing tests**: `t/cwf-claude-settings-merge.t`, `t/cwf-manage-*.t`, `t/cwf-set-status.t`, etc. — must pass unchanged after the `CWF::ArtefactHelpers` extraction (regression gate for the refactor).

### Test Coverage Targets
- **Critical paths (FR1-FR12)**: 100% — every FR has at least one TC below.
- **Acceptance criteria (AC1-AC8)**: 100% — every AC maps to a named TC.
- **Edge cases**: enumerated below per requirement (newline injection, malformed JSON, symlink attack, schema-version skew, no-manifest bootstrap, kill-mid-prompt, etc.).
- **Existing tests**: zero regressions. Verified by `prove t/` in `g-testing-exec`.

### Conventions reused from `t/cwf-claude-settings-merge.t`
- `Test::More` + `subtest` blocks with `plan tests => N`.
- `File::Temp::tempdir(CLEANUP => 1)` per test for isolation.
- `build_fixture($tmp, %opts)` factory creating `.cwf/security/script-hashes.json`, source tree, etc.
- `run_helper($tmp, @args)` wrapper invoking the helper from the tempdir, capturing stdout/stderr/exit.
- Idempotency assertions via byte-for-byte file comparison after a second run.

## Test Cases

### Functional Test Cases — `t/artefacthelpers.t` (unit)

- **TC-AH-1: `read_json_file` happy path**
  - **Given**: a tempdir with `data.json` containing valid JSON.
  - **When**: `read_json_file($path)` is called.
  - **Then**: returns the decoded hashref.

- **TC-AH-2: `read_json_file` rejects malformed JSON**
  - **Given**: a tempdir with `data.json` containing `{`.
  - **When**: `read_json_file($path)` is called.
  - **Then**: dies with `[CWF] ERROR:` prefix.

- **TC-AH-3: `atomic_write_json` produces same-directory temp + rename**
  - **Given**: a target path under `tempdir/.claude/settings.json`.
  - **When**: `atomic_write_json` writes a hashref.
  - **Then**: target file contains the JSON; no `*.tmp.*` siblings remain (assert via `glob`).

- **TC-AH-4: `validate_path_allowlist` rejects `..` and absolute**
  - **Given**: allowlist `[".cwf-rules/", "CLAUDE.md"]`.
  - **When**: called with `../etc/passwd`, `/etc/passwd`, `.cwf-rules/../etc/passwd`, `.cwf-rules/cwf-foo.md`.
  - **Then**: first three die with `[CWF] ERROR: refusing path:`; the fourth returns truthy.

- **TC-AH-5: `compute_file_sha256` matches `sha256sum`**
  - **Given**: a tempdir with `data.bin` containing 100 bytes of binary content.
  - **When**: `compute_file_sha256($path)` is called.
  - **Then**: returns the same value as `Digest::SHA::sha256_hex` reading the file in `:raw` mode.

### Functional Test Cases — `t/cwf-apply-artefacts.t` (helper-level)

For each TC: fixture builder is `build_fixture($tmp, source_files => {...}, ondisk_files => {...}, manifest => {...}, version_file => {...})`. Helper invocation is `run_helper($tmp, $tmp, @flags)` (git_root and source_root both pointed at `$tmp` for unit isolation).

#### FR3 three-way detection (AC2)
- **TC-3A — Case 1: `baseline == new`** (no upstream change). Source manifest entry sha equals installed manifest entry sha. On-disk arbitrary. Expect: no-op, no prompt, exit 0, file unchanged.
- **TC-3B — Case 2: `on-disk == new`** (already up to date). On-disk file's sha matches source. Expect: no-op, no prompt, exit 0.
- **TC-3C — Case 3: `on-disk == baseline`** (user has not modified; safe replace). On-disk matches installed manifest, differs from source. Expect: silent install, exit 0, file content == source.
- **TC-3D — Case 4: three-way conflict** (all differ). Expect: prompt invoked (verified via stdin scripted "K"); on K, file unchanged.
- **TC-3E — Structural conflict (file ↔ symlink)**. On-disk is a regular file, source ships a symlink-equivalent (or vice versa for `.claude/rules/`). Expect: treated as conflict, prompt invoked.

#### FR4 prompt options (AC2)
- **TC-4K — Keep**: scripted stdin "K\n" → on-disk unchanged, exit 0.
- **TC-4I — Install new**: scripted stdin "I\n" → on-disk replaced with source content, exit 0.
- **TC-4D-then-K — Display diff then keep**: stdin "D\nK\n" → diff appears in stdout, then prompt re-shown, then keep applied. Assert diff output contains both file paths.
- **TC-4A — Abort**: stdin "A\n" → exit 1 (user-aborted), file unchanged, no further artefacts processed (assert via fixture with two conflicts; only the first prompt fires).
- **TC-4-INVALID-INPUT-LIMIT**: scripted stdin of 12 lines of garbage → after 10 invalid attempts, helper exits 1 (NFR5 hard re-prompt limit).

#### FR4 redaction enforcement (AC6)
- **TC-4-REDACT-SETTINGS**: conflict on `.claude/settings.json`; stdin "D\nK\n" → diff output contains `[CWF] diff suppressed for .claude/settings.json` and does NOT contain the file content.
- **TC-4-REDACT-DOTENV**: conflict on a fixture artefact whose dest is `.env.test` → same redaction notice.
- **TC-4-NO-FALSE-REDACT**: conflict on `.cwf-rules/cwf-foo.md` (not a secrets path) → diff output contains the actual file content (no `diff suppressed` notice).

#### FR5 non-interactive resolution (AC2)
- **TC-5-PROMPT-DEFAULT-NONTTY**: stdin closed (non-TTY), `CWF_UPGRADE_RESOLVE` unset. Conflict present. Expect: keep applied silently, `[CWF] WARN:` log line, exit non-zero.
- **TC-5-KEEP**: `CWF_UPGRADE_RESOLVE=keep`, conflict present. Expect: on-disk unchanged, exit 0.
- **TC-5-NEW**: `CWF_UPGRADE_RESOLVE=new`, conflict present. Expect: on-disk == source, exit 0.
- **TC-5-ABORT**: `CWF_UPGRADE_RESOLVE=abort`, conflict present. Expect: exit 1, on-disk unchanged.
- **TC-5-INVALID-ENV**: `CWF_UPGRADE_RESOLVE=delete_all`. Expect: exit 1, error message `invalid CWF_UPGRADE_RESOLVE='delete_all'`, no fixture mutation.

#### FR6 idempotency (AC3)
- **TC-6-IDEM-NOOP**: run helper twice in succession on a fixture with no conflicts. Expect: second run produces zero file modifications (assert via stat-mtime preservation OR `git status -z` on a git-initialised tempdir).

#### FR7 atomicity / FR12 malformed pre-existing state (AC4)
- **TC-7-MALFORMED-SETTINGS**: install a deliberately-truncated `.claude/settings.json` (`{` only) before invoking `cwf-manage update`. Expect: exit non-zero with `[CWF] ERROR: .claude/settings.json is not valid JSON`; no other artefact mutated.
- **TC-7-KILL-MID-PROMPT**: fork the helper, send SIGTERM during the prompt (use `expect`-style or a fixture that prompts on TC-3D's conflict, then `kill` the child after seeing the prompt prefix on stdout). Expect: `.claude/settings.json` parseable JSON afterwards (verified by `JSON::PP::decode_json`); no `*.tmp.*` files left under `.claude/`.

#### FR9 bootstrap from no-manifest (AC5)
- **TC-9-NO-INSTALLED-MANIFEST**: project has no `.cwf/install-manifest.json`. Expect: additive categories (line-additive) apply silently; `replace`/`tree-replace` follow D4's "treat on-disk as baseline" — silent if `on-disk == new`, prompt otherwise. Exit 0 when no real conflict exists.
- **TC-9-NO-SOURCE-MANIFEST**: cloned source has no `.cwf/install-manifest.json`. Expect: log `[CWF] WARN: cloned source has no install-manifest.json`; non-script artefacts skipped; exit 0; script-only update still proceeds (verified at integration level by TC-INT-NO-SOURCE).

#### D11 schema-version skew
- **TC-11-SOURCE-NEWER**: source manifest has `schema_version: 2`. Expect: exit 1, error `source manifest schema_version=2 not supported by this helper; upgrade cwf-manage first`.
- **TC-11-SOURCE-OLDER**: installed has `schema_version: 2`, source has `1`. Expect: exit 1, same family of error, hint to `cwf-manage rollback`.

#### Strategy-specific
- **TC-LA-1 — line-additive idempotency**: `.gitignore` already contains `.cwf/task-stack`. Run helper. Expect: no append, byte-identical file.
- **TC-LA-2 — line-additive missing line append**: `.gitignore` lacks `.cwf/.update.lock`. Run helper. Expect: line appended; second run no-op.
- **TC-LA-3 — line-additive newline-injection rejection** (security guard): manifest `lines: ["legit\nmalicious"]`. Expect: exit 3, `[CWF] ERROR: manifest line contains forbidden newline character`; `.gitignore` unchanged.
- **TC-EB-1 — embedded-block sentinel-detect**: CLAUDE.md already has the sentinel-wrapped preamble matching new content. Expect: no-op silently.
- **TC-EB-2 — embedded-block legacy wrap-in-place**: CLAUDE.md has the legacy preamble (no sentinels) matching new content byte-for-byte. Expect: sentinels added in-place (only contiguous `>`-prefixed lines wrapped); no conflict prompt; on-disk content (modulo sentinel lines) unchanged.
- **TC-EB-3 — embedded-block user-content-outside-sentinels preserved**: CLAUDE.md has the sentinel-wrapped preamble plus a user paragraph below the END marker. Conflict on the preamble (force via differing source). Stdin "I". Expect: preamble replaced; the paragraph below END marker unchanged.
- **TC-EB-4 — embedded-block user-content-INSIDE-sentinels overwritten on Install**: CLAUDE.md has user-edited content INSIDE the sentinel region. Stdin "I". Expect: user content inside sentinels replaced (this is the documented contract of D6); user content outside sentinels untouched.
- **TC-RS-1 — regenerate-symlinks creates fresh links**: empty `.claude/rules/`, populated `.cwf-rules/cwf-foo.md`. Expect: `.claude/rules/cwf-foo.md` created as a relative symlink.
- **TC-RS-2 — regenerate-symlinks cleans stale**: `.claude/rules/cwf-removed-upstream.md` is a symlink to a non-existent target. Expect: removed. (Addresses 3c's deferred-delete edge.)
- **TC-RS-3 — regenerate-symlinks leaves user files alone**: `.claude/rules/my-personal-note.md` is a regular file (not `cwf-*`). Expect: untouched.
- **TC-RI-1 — rules-inject SHA-transition INFO log**: source ships an updated `rules-inject.txt`. Expect: replacement applied; stdout/stderr contains `[CWF] INFO: .cwf/rules-inject.txt updated (was <sha-old>, now <sha-new>)`.

### Functional Test Cases — `t/cwf-manage-update.t` (integration)

Fixture: a temp git repo simulating a CWF-installed project (with `.cwf/`, `.cwf-skills/`, `.claude/`, `CLAUDE.md`, `.gitignore` bootstrapped from a snapshot of the repo HEAD), plus a temp "cloned source" pointing to a different ref of the same content with deliberate divergences. Helper: `run_cwf_manage($installed, 'update')`.

- **TC-INT-AC1 — End-to-end byte-identical convergence**: install at v(N-1), upgrade to v(N). Compare each artefact against what `install.bash + /cwf-init` would produce against v(N) in a fresh tempdir. Expect: byte-identical (modulo user-owned per FR2).
- **TC-INT-AC3 — Idempotent re-run**: run `cwf-manage update` twice. Expect: second run leaves `git status -z` clean across `.claude/`, `.cwf-rules/`, `CLAUDE.md`, `.gitignore`.
- **TC-INT-AC8 — FR11 concurrent lock**: `fork()` two `cwf-manage update` processes in parallel. Expect: one wins (exit 0), the other exits non-zero with `another cwf-manage update is in progress`. `.claude/settings.json` parseable by both before and after.
- **TC-INT-LOCK-SYMLINK-TOCTOU**: pre-create `.cwf/.update.lock` as a symlink to `/tmp/innocent`. Run update. Expect: exit non-zero with `is a symlink; refusing to lock`.
- **TC-INT-PATH-TRAVERSAL** (Step 4 smoke test): synthetic source manifest with `dest: ../../etc/passwd`. Expect: `cwf-apply-artefacts` exits 3, `cwf-manage update` aborts before writing `.cwf/version`, no file outside the project root created (assert no new file under the tempdir's parent).
- **TC-INT-MANIFEST-SHA-TAMPER** (D12): after a successful update, hand-edit `.cwf/install-manifest.json`. Run `cwf-manage update` again. Expect: exit non-zero, error `.cwf/install-manifest.json content does not match .cwf/version`.
- **TC-INT-NO-SOURCE-MANIFEST**: cloned source lacks `.cwf/install-manifest.json` (simulate older release). Expect: exit 0; WARN logged; script-only update completes (verified by checking `.cwf/`'s contents updated).
- **TC-INT-PRE-D12-INSTALL**: installed `.cwf/version` lacks `cwf_install_manifest_sha`; new release ships one. Expect: exit 0; after update, `.cwf/version` contains the new field; second update is idempotent.
- **TC-INT-VALIDATE**: after a successful update, run `cwf-manage validate`. Expect: exit 0, no violations.

### Non-Functional Test Cases

- **NFR1 (performance)** — **TC-NFR-1-PERF**: time `cwf-apply-artefacts` against a fixture with 30 artefacts (no conflicts). Assert wall-clock < 2 s on the test runner.
- **NFR2 (usability)** — covered structurally by FR4 / FR5 TCs (prompt format, log line format) and TC-RI-1 (audit log).
- **NFR3 (maintainability)** — covered by static review during `f-implementation-exec`: confirm `@INVENTORY` is data, dispatcher is one switch, adding a new artefact is one row + one manifest entry.
- **NFR4 (security)** — covered by: TC-AH-4 (path validation), TC-LA-3 (newline injection), TC-4-REDACT-SETTINGS (secrets in diff), TC-INT-LOCK-SYMLINK-TOCTOU (lock TOCTOU), TC-INT-PATH-TRAVERSAL (manifest dest traversal), TC-INT-MANIFEST-SHA-TAMPER (D12 integrity), TC-5-INVALID-ENV (env-var validation).
- **NFR5 (reliability)** — covered by: TC-7-MALFORMED-SETTINGS (FR12), TC-7-KILL-MID-PROMPT (atomicity), TC-4-INVALID-INPUT-LIMIT (re-prompt cap), TC-INT-AC8 (concurrency).

### Test fixture hygiene (security)
- All `.claude/settings.json` fixtures use placeholder strings only. Pre-commit guard (run by hand at the end of `f-implementation-exec`):
  ```
  grep -rE '(sk-(ant|live)-[a-z0-9]|claude-[0-9]|gpt-[0-9])' t/cwf-apply-artefacts.t t/cwf-manage-update.t
  ```
  must return no matches. Failure aborts the commit.

## Test Environment

### Setup Requirements
- POSIX shell + Perl ≥ 5.20 (already required by CWF). `Digest::SHA`, `JSON::PP`, `File::Temp`, `Fcntl` (all core).
- `git` available on PATH (already required by `cwf-manage`).
- `prove` (TAP harness) — already used by existing tests.
- No external services, no Docker, no test database. All fixtures are tempdir-local.

### Automation
- Tests run via `prove -lr t/` (matches existing convention).
- `.cwf/scripts/cwf-manage validate` is the integrity gate at the end of every implementation step (per d-implementation-plan §"Per-step gates").
- No CI changes required — the project's existing pre-commit + `prove` harness covers the new test files automatically.

### Determinism
- Stdin scripting for FR4 prompt tests uses `IPC::Open3` or fixture files, not `expect` (avoids non-deterministic timing).
- SIGTERM-mid-prompt test (TC-7-KILL-MID-PROMPT) is the one timing-sensitive test; uses a synchronisation marker (helper prints a known string before reading stdin, parent waits for that string before sending the signal). Tag with `# SKIP: timing-sensitive` if it proves flaky in CI.

## Validation Criteria
- [ ] All TCs above pass (`prove -lr t/` exit 0).
- [ ] AC1-AC8 each have at least one passing TC.
- [ ] All FRs and NFRs each map to at least one TC.
- [ ] Existing tests pass (no regression from `CWF::ArtefactHelpers` extraction).
- [ ] Fixture-secrets grep guard returns no matches.
- [ ] `cwf-manage validate` exits 0 from a clean post-implementation tree.

## Decomposition Check
- [ ] Time / People / Independence: not applicable for a testing plan; this is one author writing TAP.
- [x] **Complexity**: yes — many TCs, but each is small and follows the same harness shape. Not a decomposition trigger; would be over-fragmentation.
- [ ] **Risk**: contained.

**Recommendation**: do not decompose; execute in `g-testing-exec` after `f-implementation-exec`.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
54 new tests across 3 new files (`artefacthelpers.t`, `cwf-apply-artefacts.t`, `cwf-manage-update.t`); 100% of planned TC IDs covered (PASS or PARTIAL with documented gap). Full PASS/PARTIAL table in g-testing-exec.md.

## Lessons Learned
Discovered during testing that a single-process `flock(2)` test always passes — the test must use `fork` to demonstrate per-process locking. Future tests touching per-process kernel state (flock, fcntl locks, sigaction) need the same pattern.
