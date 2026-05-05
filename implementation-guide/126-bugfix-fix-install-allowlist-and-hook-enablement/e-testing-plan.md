# fix install allowlist and hook enablement - Testing Plan
**Task**: 126 (bugfix)

## Task Reference
- **Task ID**: internal-126
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/126-fix-install-allowlist-and-hook-enablement
- **Template Version**: 2.1

## Goal
Verify the new `cwf-claude-settings-merge` helper produces the right `.claude/settings.json` from a synthetic manifest, is idempotent, refuses unsafe inputs, that registering it leaves Task 125's coverage guard green, and that the regression baseline holds.

## Test Strategy

### Test Levels
- **Unit (`U`)**: `t/cwf-claude-settings-merge.t` — fixture-driven `Test::More` suite. Each test case sets up a `tempdir`, drops a synthetic `.cwf/security/script-hashes.json` and (optionally) a starting `.claude/settings.json`, runs the helper, and asserts the rendered output.
- **Integration (`I`)**: full-repo runs of `cwf-manage validate` and `prove t/validate-security-coverage.t` against the actual manifest update.
- **Regression (`R`)**: full `prove -r t/`. Baseline at start of g-phase: 29 files / 271 tests (Task 125 close).

### Test Coverage Targets
- **Helper behaviour**: 100% of `cwf-claude-settings-merge` paths exercised by unit cases below — including the `--dry-run` branch, KD3 partition rule, all four KD7 file-type checks, KD5 multi-matcher hook scan, and KD10 atomic write.
- **Integrity surface**: Task 125's `validate-security-coverage.t` must remain green after manifest update; `cwf-manage validate` must report 0 violations.
- **Regression**: zero new failures vs the baseline; `prove -r t/` count grows by exactly +1 file.

## Test Cases

### Functional Test Cases (Unit)

- **TC-U1: Empty `.claude/settings.json` — full population**
  - **Given**: `tempdir`/`.cwf/security/script-hashes.json` listing one each of: `cwf-manage`, a top-level helper, a `.d/` subcommand, a hook. No `.claude/settings.json`.
  - **When**: helper invoked from the tempdir with no args.
  - **Then**: `.claude/settings.json` is created. `permissions.allow` contains `Bash(.cwf/scripts/cwf-manage:*)`, `Bash(.cwf/scripts/command-helpers/<helper>:*)`, `Bash(.cwf/scripts/hooks/<hook>)` (exact). The `.d/` path produces no allowlist entry. `hooks.Stop[0].hooks[]` contains exactly one entry for the hook with `type: command`, `timeout: 5`. Exit 0; stdout summary `[CWF] settings: added 3 allowlist entries, 1 hook entries`.

- **TC-U2: Pre-populated allowlist — additive, deduplicated, order preserved**
  - **Given**: same manifest as TC-U1, plus a `.claude/settings.json` containing `permissions.allow = ["Bash(git status:*)", "Bash(.cwf/scripts/cwf-manage:*)"]`.
  - **When**: helper invoked.
  - **Then**: the existing two entries appear first in the result (in their original order); the missing two CWF entries are appended after; `Bash(.cwf/scripts/cwf-manage:*)` is NOT duplicated. Re-running the helper produces a byte-identical file (idempotency).

- **TC-U3: Pre-populated Stop hooks across multiple matcher objects**
  - **Given**: `.claude/settings.json` already has `hooks.Stop` with **two** matcher objects: `[0].hooks` contains a user lint hook; `[1].hooks` contains `stop-stale-status-detector` (CWF hook in the unusual second matcher). The other CWF hook (`stop-uncommitted-changes-warning`) is absent.
  - **When**: helper invoked.
  - **Then**: the existing user lint stays in `Stop[0]`. `stop-stale-status-detector` in `Stop[1]` is NOT duplicated. The missing `stop-uncommitted-changes-warning` is appended to `Stop[0].hooks[]` (per KD5: append into the first matcher when adding new entries). Final layout has 3 hook objects total, no duplicates.

- **TC-U4: `--dry-run` does not write**
  - **Given**: same as TC-U1.
  - **When**: helper invoked with `--dry-run`.
  - **Then**: the rendered JSON is printed to stdout. `.claude/settings.json` is NOT created. Exit 0. Stdout's first line of output (after any summary) is the JSON content; running the same input without `--dry-run` produces a file whose contents equal the dry-run stdout (sans trailing summary line).

- **TC-U5: Refuse unsafe inputs**
  - **Given (a)**: manifest contains a path like `../../../etc/passwd` under `scripts.<key>.path`.
  - **When**: helper invoked.
  - **Then**: exit non-zero with `[CWF] ERROR: refusing manifest path: ../../../etc/passwd`. No file written.
  - **Given (b)**: `.claude/settings.json` is a symlink to a different file.
  - **When**: helper invoked.
  - **Then**: exit non-zero with `[CWF] ERROR: .claude/settings.json must be a regular file (found symlink)`. The symlink target is unchanged.
  - **Given (c)**: `.claude/` is a symlink to a different directory.
  - **When**: helper invoked.
  - **Then**: exit non-zero with `[CWF] ERROR: .claude/ must be a regular directory`. No write.
  - **Given (d)**: malformed JSON in existing `.claude/settings.json`.
  - **When**: helper invoked.
  - **Then**: exit non-zero with `[CWF] ERROR: cannot parse .claude/settings.json`. Original file untouched.

- **TC-U6: Manifest entry references a missing file**
  - **Given**: manifest lists a path under `command-helpers/missing-helper`; the file is not on disk.
  - **When**: helper invoked.
  - **Then**: helper warns `[CWF] WARN: manifest entry .cwf/scripts/command-helpers/missing-helper not found on disk; skipping` to stderr, completes successfully, exits 0. Output file omits the missing entry.

### Functional Test Cases (Integration)

- **TC-I1: `validate-security-coverage.t` stays green after manifest update**
  - **Given**: f-phase has registered the new helper in `.cwf/security/script-hashes.json`.
  - **When**: `prove t/validate-security-coverage.t`.
  - **Then**: All 4 subtests PASS; TC-C1 count goes 22 → 23 (new helper); TC-C2 (7) and TC-C3 (2) unchanged.

- **TC-I2: `cwf-manage validate` reports zero violations**
  - **Given**: f-phase complete, manifest registered, helper on disk with `0500` perms.
  - **When**: `.cwf/scripts/cwf-manage validate`.
  - **Then**: Output `[CWF] validate: OK`. Zero sha256 violations, zero permissions violations.

- **TC-I3: End-to-end smoke against this repo**
  - **Given**: clean working tree on the task branch.
  - **When**: run `cwf-claude-settings-merge --dry-run` from the repo root and diff its output against the current `.claude/settings.local.json` (read-only — we don't actually clobber).
  - **Then**: dry-run output contains `Bash(.cwf/scripts/cwf-manage:*)`, both hook commands, and one entry per top-level command-helper in the manifest. The diff is informational; this TC is a sanity check that the helper's view of the repo matches reality.

### Non-Functional Test Cases

- **TC-NF1 (Atomic write)**
  - **Given**: helper run is interrupted between encode and rename (simulated by injecting a `die` post-encode in a unit subtest).
  - **When**: assert temp file naming pattern + that no partial `.claude/settings.json` exists.
  - **Then**: original `.claude/settings.json` is unchanged; only the temp file in `.claude/.settings.json.XXXXXX` exists (and is cleaned up on next successful run, or by the test's tempdir teardown).

- **TC-NF2 (Determinism)**
  - **Given**: identical inputs across two runs.
  - **When**: compare stdout + output file byte-for-byte.
  - **Then**: identical. `canonical` ordering is stable; sorted iteration through manifest is stable.

- **TC-NF3 (No new attack surface)**
  - **Given**: f-phase diff vs main.
  - **When**: manual review.
  - **Then**: no new `system()`/`exec()`/`qx//`/`eval STRING`/network calls; helper writes only to `.claude/settings.json`; no stdin processing.

- **TC-R1 (No regression in baseline suite)**
  - **Given**: full `prove -r t/` baseline before f-phase changes (refresh count at start of g).
  - **When**: re-run `prove -r t/` after f-phase.
  - **Then**: file count = baseline + 1 (new test file); pass count strictly greater than baseline (existing tests unchanged + new TCs all pass).

## Test Environment

### Setup Requirements
- Working tree on `bugfix/126-fix-install-allowlist-and-hook-enablement`.
- Perl 5.10+ with core modules: `Test::More`, `JSON::PP`, `File::Temp`, `File::Spec`, `File::Path`, `FindBin`, `Digest::SHA`.
- `.cwf/scripts/cwf-manage` executable; `.cwf/security/script-hashes.json` present.

### Automation
- Unit cases run by `prove t/cwf-claude-settings-merge.t` and the wider `prove -r t/`.
- Integration cases run by `cwf-manage validate` (already wired into the post-checkpoint hook).
- No new CI configuration required.

## Validation Criteria
- [ ] TC-U1: empty-input path produces full settings.json with the right entries and counts.
- [ ] TC-U2: pre-populated allowlist is preserved + additively merged + idempotent.
- [ ] TC-U3: hooks across multiple matchers are detected without duplication; new hooks land in `Stop[0]`.
- [ ] TC-U4: `--dry-run` prints without writing; output matches a real-write file.
- [ ] TC-U5 (a-d): all four unsafe inputs refused with the expected error strings, no file mutation.
- [ ] TC-U6: missing-on-disk manifest entry warns-and-skips; exit 0.
- [ ] TC-I1: `validate-security-coverage.t` GREEN with TC-C1 = 23.
- [ ] TC-I2: `cwf-manage validate` reports OK with zero violations.
- [ ] TC-I3: dry-run output of the helper from this repo aligns with reality (sanity).
- [ ] TC-NF1: temp+rename atomic write proven via interrupted-write subtest.
- [ ] TC-NF2: deterministic across runs.
- [ ] TC-NF3: no new attack surface.
- [ ] TC-R1: baseline regression count holds; new file adds expected delta.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
