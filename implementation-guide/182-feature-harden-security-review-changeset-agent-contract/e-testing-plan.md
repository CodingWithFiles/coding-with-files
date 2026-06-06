# Harden security-review-changeset agent contract - Testing Plan
**Task**: 182 (feature)

## Task Reference
- **Task ID**: internal-182
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/182-harden-security-review-changeset-agent-contract
- **Template Version**: 2.1

## Goal
Define the test strategy for the contract migration: extend `t/security-review-changeset.t`, migrate existing assertions to the file-output model, and add cases for AC1–AC8.

## Test Strategy
### Test Levels
- **Integration (primary)**: extend the existing `t/security-review-changeset.t` Test::More harness — it builds a synthetic git repo and runs the helper as a subprocess. This is the right level: the contract is the script's stdout/stderr/exit + the `.out` file.
- **Output-level smoke (docs)**: grep the four installed consumer sites for the new invocation contract and the absence of stale strings (per the "rebrands need an output-level smoke-test" lesson — source-level grep alone is insufficient).
- **System (post-hash)**: `cwf-manage validate` clean for the changed script.

### Harness changes (prerequisite, done in g)
- `run_helper` must pass a valid `--wf-step` by default (e.g. `implementation-exec`); without it the helper now exits 1, so every existing subtest would otherwise fail.
- Add a helper that computes the canonical `.out` path for the synthetic repo — `"/tmp/" . ($repo =~ s{/}{-}gr) . "-task-$num/security-review-changeset-<wf-step>.out"` — and reads it, so assertions that used to match `$out` (stdout) now match file contents.

### Existing-test migration (regression — must stay green)
The diff moved from stdout to the `.out` file. Migrate assertions accordingly:
- **TC-F1/F2/F3/F4/F5/F6/F7/F8, TC-WIDEN1, TC-Task141-uncommitted**: change `like($out, qr{…diff…})` / `unlike($out, …)` to read the `.out` file and match its contents. stderr summary assertions unchanged.
- **TC-CAP1**: exit 2 unchanged; "full diff still printed to stdout" → "full diff written to `.out`"; assert confirmation line on stdout.
- **TC-CAP3**: semantics change — "absent `--max-lines` never caps" is **no longer true** (default 500). Re-purpose: absent flag with production < 500 → exit 0; and a 200-line script (<500) still passes. Pair with new TC-DEFAULTCAP below.
- **TC-EMPTY1**: `is($out,'','stdout empty')` → stdout is the confirmation line with count 0; assert a 0-line `.out` file exists.
- **TC-NF2 / TC-CAP5 / TC-CAP7**: error paths (exit 1) — `is($out,'')` still holds (the script exits before writing/confirming). Keep.

### Coverage target
Every AC (AC1–AC8) has ≥1 dedicated case; all pre-existing subtests migrated and green (no regression).

## Test Cases (new — Given/When/Then)
### Functional
- **TC-WFSTEP-REJECT** (AC1/AC2): **Given** a valid repo, **When** run with `--phase=implementation`, or `--wf-step=bogus`, or `--wf-step=../escape`, or no `--wf-step`, **Then** exit 1, stderr names the failure (`unknown argument` / `expected one of: …`), stdout empty, no `.out` written.
- **TC-WFSTEP-ACCEPT** (AC2): **Given** a valid repo + change, **When** `--wf-step=design-plan`, **Then** exit 0 and the `.out` filename contains `design-plan`.
- **TC-DEFAULTCAP** (AC3): **Given** a >500-production-line diff, **When** run with **no** `--max-lines`, **Then** exit 2 (default cap fired); **and** with `--max-lines=100000` the same diff → exit 0 (override works).
- **TC-OUTFILE** (AC4): **Given** a non-empty change, **When** run, **Then** the `.out` exists at the canonical `mkdir -m 0700` path, mode 0600, contains the full diff; stdout contains no diff lines (no `^diff --git`, no `^+`/`^-`).
- **TC-CONFIRM** (AC5): **Given** a run, **Then** stdout is exactly one line `security-review-changeset: wrote <N> lines to <abs-path>` and `<N>` equals `wc -l` of the file.
- **TC-EMPTY** (AC4.3): **Given** an empty changeset (anchor == worktree), **When** run, **Then** exit 0, a 0-line `.out` file is written, and the confirmation line reports count 0 (no reliance on empty stdout).
- **TC-TRUNCATE** (AC4.2): **Given** a prior larger `.out` from run 1, **When** run 2 produces a smaller diff, **Then** the `.out` is fully replaced and its count matches run 2 (no leftover lines).

### Non-Functional
- **TC-SYMLINK** (AC4.2, security): **Given** a pre-planted symlink at the target `.out` path pointing at a sentinel file, **When** run, **Then** the sentinel's content is **unmodified** (no write-through), and `.out` is a regular file containing the diff. (SKIP if symlinks unsupported, per existing TC-GUARD1a pattern.)
- **TC-WORKTREE** (AC4.1): **Given** the repo with a linked worktree (`git worktree add`), **When** the helper runs from inside the worktree, **Then** the `.out` resolves under the **main**-tree dashified namespace, not the worktree path. (SKIP if `git worktree` unavailable.)
- **TC-CAP-WRITES-FILE** (AC7): **Given** a diff over the cap, **When** run, **Then** the `.out` file is written **and** the confirmation line printed **before** exit 2 (caller can still recover the path).

### Output-level / system (AC6/AC8) — run in g
- **TC-DOCS** (AC6): grep the four sites (`cwf-implementation-exec/SKILL.md`, `cwf-testing-exec/SKILL.md`, `cwf-security-reviewer-changeset.md`, `security-review.md`): assert **no** `--phase`, **no** `--max-lines=500`, **no** inline `{changeset}` capture; assert presence of the exact invocation string and the `.out`-path/`{changeset_file}` consumption.
- **TC-VALIDATE** (AC8): after hash refresh, `.cwf/scripts/cwf-manage validate` reports no violation for `security-review-changeset` (the pre-existing `cwf-claude-settings-merge` drift is out of scope).

## Test Environment
### Setup Requirements
- Perl core + `Test::More` (already used by the suite); `git`; symlink + `git worktree` support is probed and SKIPped if absent.
- No production data; synthetic tempdir repos only (`tempdir(CLEANUP=>1)`).

### Automation
- `prove t/security-review-changeset.t` (or direct execution); part of the existing suite.

## Validation Criteria
- [ ] All migrated existing subtests green (no regression)
- [ ] New TCs for AC1–AC8 present and green (SKIPs only where symlink/worktree unsupported)
- [ ] Output-level grep (TC-DOCS) clean across the four sites
- [ ] `cwf-manage validate` clean for the changed script (TC-VALIDATE)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Strategy executed in `g`: 35 subtests, 0 failures. The planned harness changes (default `--wf-step`, `.out`-path computation) were realised by parsing the helper's confirmation line rather than re-deriving the path — more robust (macOS symlink resolution). TC-EMPTY and TC-CAP-WRITES-FILE were consolidated into the migrated TC-EMPTY1 / TC-CAP1 (identical scenarios); no coverage lost.

## Lessons Learned
Migrated assertions must be *run*, not reasoned about: one missed stdout→file site (TC-WIDEN1) passed source inspection and failed the suite. See `g-testing-exec.md`.
