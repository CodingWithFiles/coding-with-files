# changeset omits untracked files from git diff - Testing Plan
**Task**: 194 (bugfix)

## Task Reference
- **Task ID**: internal-194
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/194-changeset-omits-untracked-files-from-git-diff
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for changeset omits untracked files from git diff.

## Test Strategy
### Test Levels
Integration tests only, added to the existing `t/security-review-changeset.t`. Each
subtest builds a synthetic CWF-layout repo via the existing `make_synthetic_repo`, runs
the helper as a subprocess via `run_helper`, and asserts on the `.out` body, the stderr
summary line, the exit code, **and the post-run git index state** (new for this task).

### Reused harness (no new scaffolding)
- `make_synthetic_repo(baseline => '__MAIN__', ...)` — repo with anchor pinned to main.
- `run_helper($repo, ...)` / `run_helper_raw` — subprocess run; `.out` auto-queued for
  cleanup via the existing `@CLEANUP_OUT` END block.
- `out_path($stdout)` + slurp — read the changeset body for content assertions.
- `git_capture($repo, 'status', '--porcelain', ...)` — assert post-run index cleanliness.
- `--max-lines=N` — drive the cap path with a small N.

### Coverage target
Every numbered case below maps to a code path added or changed in d-implementation-plan.md
(body inclusion, count inclusion, exclude-standard, dirty suffix, `--` invariant, index
restore on normal and `exit 2` paths). 100% of the new branches exercised. Existing
subtests must remain green (tracked-only regression).

## Test Cases
### Functional Test Cases
- **TC-1 — untracked file in body + count**
  - **Given**: repo at anchor; one tracked modification and one untracked non-ignored file
    `new.txt` with N lines.
  - **When**: `run_helper($repo)` (default `--wf-step`).
  - **Then**: exit 0; `.out` body contains a `+++ b/new.txt` new-file hunk with all N lines
    as additions; the stderr summary's reviewed-files count includes `new.txt` and the
    production count rose by N.

- **TC-2 — ignored file excluded**
  - **Given**: repo with `.gitignore` containing `*.log`; an untracked `debug.log`.
  - **When**: `run_helper($repo)`.
  - **Then**: `.out` body does NOT mention `debug.log`; production count unchanged by it.

- **TC-3 — index restored on normal exit**
  - **Given**: untracked `new.txt` present.
  - **When**: `run_helper($repo)` exits 0.
  - **Then**: `git status --porcelain` shows `?? new.txt` (still untracked) with no `A `/`AM`
    intent-to-add entry; the file content is unchanged.

- **TC-4 — cap exceeded still returns exit 2 AND restores index**
  - **Given**: untracked file large enough that its additions push the production count over
    a small `--max-lines`.
  - **When**: `run_helper($repo, '--max-lines=5')` (or a value below the file's line count).
  - **Then**: exit code is 2; `.out` was still written; `git status --porcelain` shows the
    file still `??` (END-block restore ran despite the early `exit 2`, and did not clobber
    the exit code).

- **TC-5 — untracked-only tree renders the "includes uncommitted" suffix**
  - **Given**: repo HEAD-clean for tracked files, with one untracked `new.txt`.
  - **When**: `run_helper($repo)`.
  - **Then**: the stderr summary ends with `, includes uncommitted`; exit 0.

- **TC-6 — dash-prefixed untracked filename (`--` option-injection invariant)**
  - **Given**: an untracked file literally named `-rf` (created via a path that bypasses
    shell parsing).
  - **When**: `run_helper($repo)`.
  - **Then**: exit 0 (no git option-parsing error); `.out` body includes the `-rf` file;
    `git status --porcelain` shows it still untracked afterwards.

- **TC-7 — no untracked files (no-op path / regression)**
  - **Given**: repo with only a tracked modification, zero untracked files.
  - **When**: `run_helper($repo)`.
  - **Then**: behaviour identical to pre-change (body = tracked diff, suffix reflects only
    tracked dirtiness); no signal handler side effects; index untouched.

### Non-Functional / Robustness Test Cases
- **Index integrity (reliability)**: TC-3, TC-4, TC-6 each assert the post-run index is
  exactly as before the run — the read-only-contract guarantee.
- **Security (option injection)**: TC-6 is the FR4(e) `--` guard regression.
- **Exit-code fidelity**: TC-4 confirms cleanup does not mask `exit 2`.
- **Signal-interrupt restore (manual / best-effort)**: automated SIGINT timing is flaky in
  a unit test, so this is a **documented manual check** rather than a CI subtest: in a
  scratch repo, start the helper, send SIGINT during the run, confirm `git status` shows no
  residual intent-to-add. If a deterministic hook is cheap at exec time, add it; otherwise
  record the manual result in g-testing-exec Actual Results. (Rationale: do not add a flaky
  timing-dependent test to the suite.)

## Test Environment
### Setup Requirements
- Perl `Test::More` (core), `File::Temp`, `File::Path` — all already used by the existing
  test file; no new deps (honours Perl core-only policy).
- `git` on PATH; synthetic repos under `tempdir(CLEANUP => 1)`. No production data, no
  network. (Test-DB rule N/A — no database.)

### Automation
- Run via the project's existing test invocation (`prove t/security-review-changeset.t`
  or the full `t/` run). No CI changes.

## Validation Criteria
- [ ] TC-1…TC-7 pass.
- [ ] Full `t/security-review-changeset.t` (existing + new) green; no regression.
- [ ] `.cwf/security/script-hashes.json` refreshed for the helper; `cwf-manage validate`
      clean; helper perms restored to recorded 0500.
- [ ] Signal-interrupt manual check recorded in g-testing-exec.

## Decomposition Check
0 signals — all tests live in one existing file. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective (complete)
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1…TC-7 were implemented as subtests in the existing
`t/security-review-changeset.t` and all pass; full `t/` tree is 741/741 green.
The signal-interrupt case was kept as a documented manual check as planned (the
END-restore guarantee is covered deterministically by TC-3/TC-4). One unplanned
discovery: the new untracked-enumeration behaviour exposed that the harness
wrote its capture files inside the repo-under-test — fixed by relocating them
out of tree (recorded in g-testing-exec.md).

## Lessons Learned
"Reuse the existing harness, add no new scaffolding" was the right call — all
seven cases fit the `make_synthetic_repo`/`make_cap_repo` + `run_helper`
pattern. The harness-pollution bug would have been masked had the new tests used
a bespoke runner instead of the shared one; sharing surfaced it immediately.
