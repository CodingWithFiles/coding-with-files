# Nest tmp scratch dirs under per-project parent dir - Testing Plan
**Task**: 203 (feature)

## Task Reference
- **Task ID**: internal-203
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/203-nest-tmp-scratch-dirs-under-per-project-parent
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for Nest tmp scratch dirs under per-project parent dir.

## Test Strategy
### Test Levels
- **Unit/integration**: `t/security-review-changeset.t` (Perl `Test::More`, the project's
  only test mechanism) — extend in place, no new file.
- **Output-level smoke**: run the helper for real in this repo and inspect the reported
  `.out` path (per the recurring "rebrands need output-level smoke-test" lesson — source
  grepping alone is insufficient).
- **Static sweep**: grep for stale references to the old form.

### Coverage Targets
- New/changed behaviour (nested path derivation, two-level mkdir, parent-symlink reject,
  shared-parent reuse): 100% — these are the security-critical paths.
- Regression: full `t/` suite green; `cwf-manage validate` clean.

## Test Cases
### Functional (extend `t/security-review-changeset.t`)
- **TC-OUTFILE (extend; AC1/AC2)**: nested path shape + both dir modes.
  - **Given**: a synthetic repo + task fixture, `$TMPDIR` pointed at a tempdir.
  - **When**: the helper runs and reports `wrote N lines to <path>`.
  - **Then**: `<path>` matches `…/cwf<dash>/task-<num>/security-review-changeset-<step>.out`;
    the `cwf<dash>` **parent** and the `task-<num>` **leaf** are both mode 0700; `.out` is
    0600 (existing assertion retained).
- **TC-PARENT-SYMLINK (new; AC6)**: defence-in-depth symlink reject.
  - **Given**: an **isolated** repo root; the `cwf<dash>` parent pre-created as a symlink
    to an attacker-controlled dir (skip if symlinks unsupported).
  - **When**: the helper runs.
  - **Then**: it exits 1 with a diagnostic; no `.out` is written through the link; teardown
    uses **`unlink`** (not `rmdir`) and runs **even on subtest failure**.
- **TC-PARENT-REUSE (new; AC6, observable no-chmod)**: shared-parent second-task path.
  - **Given**: the `cwf<dash>` parent pre-created at **0755** (not 0700).
  - **When**: the helper runs.
  - **Then**: it proceeds, writes the leaf, and leaves the parent at **0755 (unchanged, not
    clamped)** — the observable form of "never auto-chmod".
- **TC-CLEANUP (END block; hygiene)**: the END block removes the `task-<num>` leaf **and** the
  now-empty `cwf<dash>` parent (no sentinel), leaving no `/tmp` residue across runs.

### Non-Functional
- **Security**: TC-PARENT-SYMLINK + TC-PARENT-REUSE above; plus confirm no new shell-out / no
  unvalidated interpolation in the new path assembly (FR4a — verified by the changeset
  security review; path uses only the already-validated `$task_num` + literal `cwf`/`task-`).
- **Reliability**: leaf-mkdir failure is fail-closed (warn + exit 1); D6 provisioning failure
  is non-fatal and must not block task/branch creation nor print a non-existent path.
- **Performance**: not applicable (one extra `mkdir` at first use).

## Test Environment
- Perl core + `Test::More`; `prove t/security-review-changeset.t` and full `prove t/`.
- Symlink-dependent subtest guarded by the existing `eval { symlink('', ''); 1 }` skip idiom.
- Hash integrity: `.cwf/scripts/command-helpers/cwf-manage validate` after the hash refresh.
- D6 provisioning is a **skill** step (not a `t/` test) → manual smoke only.

## Validation Criteria
- [ ] `prove t/security-review-changeset.t` green incl. TC-PARENT-SYMLINK, TC-PARENT-REUSE,
      extended TC-OUTFILE
- [ ] Full `prove t/` green (no regressions)
- [ ] `cwf-manage validate` clean (helper hash refreshed in-commit)
- [ ] Smoke: real helper run writes `.out` at the nested path; parent basename begins with
      `cwf`; stdout one-line contract intact
- [ ] **Manual** provisioning smoke: `/cwf-new-task` creates parent+leaf and surfaces the
      path; a forced `mkdir` failure warns, does not block branch creation, prints no path
- [ ] Grep sweep (anchored on `-task-`): old dash-form gone except carve-outs; `-tool-check`
      form intact (D5)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned validation criteria executed (see g-testing-exec.md). The three planned
functional cases (extended TC-OUTFILE, TC-PARENT-SYMLINK, TC-PARENT-REUSE) plus the
END-block cleanup, output-level smoke, grep sweep, and manual D6 provisioning smoke all
passed. The one full-suite failure (TC-VALIDATE) was a pre-existing in-flight-status
artefact, resolved by the retrospective status sweep — not a regression.

## Lessons Learned
*Consolidated in j-retrospective.md.*
