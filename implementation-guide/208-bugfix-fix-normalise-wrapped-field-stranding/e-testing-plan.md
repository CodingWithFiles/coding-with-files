# Fix normalise wrapped-field stranding - Testing Plan
**Task**: 208 (bugfix)

## Task Reference
- **Task ID**: internal-208
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/208-fix-normalise-wrapped-field-stranding
- **Template Version**: 2.1

## Goal
Pin the wrapped-field fold (KD1–KD3a) with a regression subtest, prove the existing
single-line/body-prose paths are untouched, and confirm idempotency.

## Test Strategy
### Test Levels
- **Unit/behavioural**: `t/backlog-manager.t` subtest driving the `normalise`
  subcommand end-to-end via `run_bm` on isolated fixtures (`make_isolated`), the
  established AC18 pattern. No new harness.
- **Regression**: full `prove -lr t/` — every existing suite must stay green
  (the AC18a/b/c single-line legacy path is the key no-regression guard).

### Test Coverage Targets
- **Critical path**: the fold's four terminators + seed-empty edge — one fixture row
  each (KD3 matrix), all asserted.
- **Regression**: 0 failures across `t/`; AC18c idempotency (byte-identical re-run)
  extended to the wrapped fixture.

## Test Cases
### Functional Test Cases (new subtest, AC18 block, ~`t/backlog-manager.t:967`)
- **TC-1 — wrap terminated by next field**
  - **Given**: `**Scope**:` value spanning 3 physical lines, immediately followed by `**Priority**: High`.
  - **When**: `normalise`.
  - **Then**: one `### Scope: <all three lines joined by single spaces>`; `### Priority: High` present; no Scope fragment remains in body.
- **TC-2 — wrap terminated by blank line + body prose**
  - **Given**: wrapped `**Rationale**:` value, then a blank line, then genuine paragraph prose.
  - **When**: `normalise`.
  - **Then**: full value in one `### Rationale:` heading; the prose survives intact in the body (hoisted below the metadata block per KD2a); nothing stranded.
- **TC-3 — wrap terminated by `---`**
  - **Given**: wrapped value as the last field of an entry, followed by a `^---$` separator.
  - **When**: `normalise`.
  - **Then**: full value folded; `---` dropped (existing behaviour); next entry intact.
- **TC-4 — wrap terminated by end-of-entry**
  - **Given**: wrapped value as the final lines of the final entry (EOF).
  - **When**: `normalise`.
  - **Then**: full value folded; no trailing artefact.
- **TC-5 — seed-empty field**
  - **Given**: `**Notes**:` with the value beginning on the next physical line (`**Notes**:\n  first line\n  second line`).
  - **When**: `normalise`.
  - **Then**: `### Notes: first line second line` — single space after the colon, no double space.
- **TC-6 — idempotency (extends AC18c)**
  - **Given**: the TC-1..TC-5 fixture, already normalised once.
  - **When**: `normalise` a second time.
  - **Then**: byte-identical output (the fold is a fixed point, KD3a).
- **TC-7 — single-line regression (no behaviour change)**
  - **Given**: the existing single-line legacy fixture (`$LEGACY_BACKLOG`).
  - **When**: `normalise`.
  - **Then**: identical to current AC18b output — confirms the inner `while` no-ops for single-line fields.

### Non-Functional / Out-of-Scope
- **CRLF input**: `^\s*$` (blank terminator) and `^---\r?\n?\z` already tolerate `\r`,
  so CRLF blank/separator lines terminate correctly. Full CRLF round-trip fidelity is
  **out of scope** — the repo's fixtures are LF and `normalise` has never promised CRLF
  byte-preservation. Recorded here so the omission is deliberate, not a gap (robustness
  review point). No CRLF fixture row added.
- **Whitespace-only continuation**: unreachable as a `$cont` (it is a blank-line
  terminator), so no test asserts consuming one.
- **Performance/security**: N/A — deterministic in-memory text fold, no new surface
  (confirmed by plan-review security pass).

## Test Environment
### Setup Requirements
- Perl core + `Test::More`; `prove`. No DB, no network, no external services.
- Fixtures are in-test heredoc strings materialised by `make_isolated` into a temp dir;
  no mutation of the repo's real `BACKLOG.md`/`CHANGELOG.md`.

### Automation
- `prove -lr t/backlog-manager.t` for the focused run; `prove -lr t/` for the full
  regression sweep. Run in g-testing-exec.

## Validation Criteria
- [ ] TC-1..TC-7 all pass
- [ ] Full `prove -lr t/` green (no regressions)
- [ ] Idempotent re-run byte-identical (TC-6)
- [ ] `cwf-manage validate` OK after hash refresh

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
