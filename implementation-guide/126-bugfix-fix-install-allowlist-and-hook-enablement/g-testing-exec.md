# fix install allowlist and hook enablement - Testing Execution
**Task**: 126 (bugfix)

## Task Reference
- **Task ID**: internal-126
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/126-fix-install-allowlist-and-hook-enablement
- **Template Version**: 2.1

## Goal
Execute the test cases defined in e-testing-plan.md against the f-phase implementation.

## Test Results

### Functional Tests (Unit) — `prove t/cwf-claude-settings-merge.t`

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-U1 | Empty `.claude/settings.json` — full population | 3 allow + 1 hook entry; helper as `:*`, hook as exact, `.d/` skipped | as expected; summary `added 3 allowlist entries, 1 hook entries` | PASS |
| TC-U2 | Pre-populated allowlist preserved + dedup + idempotent | existing entries first, no dup, byte-identical re-run | as expected; second run produced byte-identical file | PASS |
| TC-U3 | Hooks across multiple matchers — no dup, append into `[0]` | `Stop[1].stop-stale` not duplicated; `stop-warn` appended to `Stop[0]` | as expected; 2 matcher objects preserved | PASS |
| TC-U4 | `--dry-run` does not write | JSON to stdout, no file, exit 0 | as expected; `would add 3 allowlist entries, 1 hook entries (dry-run)` summary | PASS |
| TC-U5a | Refuse manifest path with `..` | exit non-zero, `[CWF] ERROR: refusing manifest path:` | as expected | PASS |
| TC-U5b | Refuse `.claude/settings.json` symlink | exit non-zero, "must be a regular file" | as expected; symlink unchanged | PASS |
| TC-U5c | Refuse `.claude/` symlink | exit non-zero, "must be a regular directory" | as expected | PASS |
| TC-U5d | Malformed JSON in `.claude/settings.json` | exit non-zero, parse-error message, original untouched | as expected | PASS |
| TC-U6 | Manifest entry references missing file — warn-and-skip | exit 0, WARN line, missing entry omitted | as expected | PASS |

**Unit suite total**: 9 subtests PASS / 0 FAIL.

### Functional Tests (Integration)

| Test ID | Test Case | Result |
|---------|-----------|--------|
| TC-I1 | `validate-security-coverage.t` stays green after manifest update | PASS — 4 subtests OK; TC-C1 went 22 → 23 as planned |
| TC-I2 | `cwf-manage validate` reports zero violations | PASS — `[CWF] validate: OK` |
| TC-I3 | End-to-end smoke against this repo via `--dry-run` | PASS — output contains `Bash(.cwf/scripts/cwf-manage:*)` and both real CWF hook commands (`stop-stale-status-detector`, `stop-uncommitted-changes-warning`) |

### Non-Functional Tests

| Test ID | Test Case | Result |
|---------|-----------|--------|
| TC-NF1 | Atomic write via `File::Temp` + `rename` | PASS — implementation uses the `CWF::Versioning::bump_to` pattern (`File::Temp` with `TEMPLATE => '.settings.json.XXXXXX'` + `rename`); proven structurally and indirectly via TC-U2 idempotency |
| TC-NF2 | Determinism (byte-identical across runs with same inputs) | PASS — TC-U2's idempotency assertion compares the file byte-for-byte across two runs |
| TC-NF3 | No new attack surface | PASS — `grep -nE 'system\|exec\|qx\|eval *"\|`\|LWP\|HTTP' cwf-claude-settings-merge` returned no matches; no stdin processing; only writes `.claude/settings.json` |

### Regression

| Test ID | Test Case | Baseline | Result |
|---------|-----------|----------|--------|
| TC-R1 | Full `prove -r t/` | 29 files / 271 tests | PASS — 30 files / 280 tests, all green; delta is exactly +1 file (`t/cwf-claude-settings-merge.t`) and +9 tests (its 9 subtests) |

## Test Failures
None.

## Coverage Report
- Helper paths exercised by unit suite: empty/populated input, all four KD7 file-type checks, KD3 partition (cwf-manage / top-level helper / `.d/` / hook), KD5 multi-matcher hook scan, `--dry-run` branch, missing-on-disk warn-and-skip.
- Integration: full integrity manifest walked end-to-end via `--dry-run` against this repo.

## Validation Criteria
- [x] TC-U1 through TC-U6 all PASS
- [x] TC-I1 — coverage guard green; TC-C1 = 23
- [x] TC-I2 — `cwf-manage validate` OK
- [x] TC-I3 — repo smoke shows expected entries
- [x] TC-NF1, TC-NF2, TC-NF3 all PASS
- [x] TC-R1 — regression baseline holds

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: findings

Now let me trace through the threat categories systematically:

**Threat Category (a): Bash injection / unsafe command construction**
- The script uses NO system() or backtick/qx operations
- It uses list-form file operations (open, mkdir, rename, unlink)
- No untrusted strings flow into shell commands

**Threat Category (b): Perl helpers consuming git or user output without -z / input validation**
- The script does NOT consume git output
- It reads from .cwf/security/script-hashes.json (manifest)
- The manifest paths are validated against regex before use
- Path validation: line 69 checks `!~ m{^\.cwf/scripts/}` and `=~ m{(^|/)\.\.(/|$)}`

**Threat Category (c): Prompt injection via user-supplied strings**
- Not applicable - this is not a SKILL that outputs to LLM context

**Threat Category (d): Unsafe environment-variable handling**
- The script only checks @ARGV for --dry-run
- It doesn't read any environment variables except implicitly through FindBin

**Threat Category (e): Pattern-based risks**
- Line 69 validates paths with a regex check
- However, I need to examine this more carefully

[Agent then performs detailed flow analysis covering: argument parsing, manifest reading, path validation regex (including `foo..bar` edge cases), settings reading symlink protection, merge dedup logic, atomic_write with File::Temp, and a TOCTOU race-condition analysis between read_settings() validation and atomic_write() execution.]

**Additional observations:**
- Excellent error handling throughout
- Proper use of atomic writes with File::Temp
- Symlink protection in read_settings is good
- JSON parsing is safe
- Deduplication logic is correct

The code appears clean from a security standpoint given the threat model categories (a)-(e).

no findings (Excellent error handling and defensive programming; no security issues detected per threat model categories a-e.)

### Disposition
**Classified `findings` per the three-tier rule** (primary sentinel failed because the agent's first non-blank line is analysis prose, not a sentinel; fallback matches the agent's numbered-list analysis). The agent's substantive conclusion at the end is `no findings`, with no actionable items. The TOCTOU race-condition discussion in the body is explicitly framed as not exploitable in single-threaded execution with a controlled manifest. **Accept-and-record**: no code change.

## Lessons Learned
*To be captured during retrospective*
