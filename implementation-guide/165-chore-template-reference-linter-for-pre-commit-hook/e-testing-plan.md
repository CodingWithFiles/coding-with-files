# Template Reference Linter for Pre-Commit Hook - Testing Plan
**Task**: 165 (chore)

## Task Reference
- **Task ID**: internal-165
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/165-template-reference-linter-for-pre-commit-hook
- **Template Version**: 2.1

## Goal
Validate that `CWF::Validate::TemplateRefs::validate` flags genuinely-orphaned template references while not flagging legitimate back-compat names, substring/compound decoys, or out-of-scope history files — and that it integrates cleanly into `cwf-manage validate`.

## Test Strategy
### Test Levels
- **Unit (synthetic trees)**: `t/validate-template-refs.t` builds fixture roots via `File::Temp` and asserts the exact violation set for each case (mirrors `t/validate-perl-conventions.t`).
- **Integration (real repo)**: call `validate($real_git_root)` and assert zero violations on HEAD (after the D6 fixes land).
- **System (gate wiring)**: `cwf-manage validate` returns OK with the new module registered.
- **Regression**: full `prove t/` shows no new failures; existing `validate-*.t` unaffected.

### Test Coverage Targets
- **Critical paths**: KNOWN-set derivation (all four sources), anchored token classification, scope exclusions — 100%.
- **Edge cases**: substring decoy, compound decoy, back-compat name, out-of-scope history file, fail-closed guard.
- **Regression**: existing test suite passes unchanged.

## Test Cases
### Functional Test Cases
- **TC-1 (valid tree → clean)**: 
  - **Given**: a fixture root whose `.md`/`.pl`/`.pm` files reference only current and historical-but-known names (`a-task-plan.md`, `a-plan.md`).
  - **When**: `validate($root)` runs.
  - **Then**: returns zero violations.

- **TC-2 (genuine orphan → flagged)**: 
  - **Given**: a fixture file referencing `z-bogus.md` (matches grammar, in no version).
  - **When**: `validate($root)` runs.
  - **Then**: exactly one violation, with `file`/`field`(line)/`actual=z-bogus.md`.

- **TC-3 (back-compat name → not flagged)**: 
  - **Given**: a fixture file with "Open a-task-plan.md (v2.1) or a-plan.md (v2.0)".
  - **When**: `validate($root)` runs.
  - **Then**: zero violations (`a-plan.md` is a known v2.0 name).

- **TC-4 (substring decoy → not flagged)**: 
  - **Given**: a fixture file referencing `retrospective-extras.md` and `cwf-plan-reviewer-misalignment.md`.
  - **When**: `validate($root)` runs.
  - **Then**: zero violations (left look-behind rejects the embedded `e-extras.md` / `f-plan-...` substrings).

- **TC-5 (compound decoy → matched whole)**: 
  - **Given**: a fixture file referencing `f-implementation-exec-audit.md` (a removed compound name).
  - **When**: `validate($root)` runs.
  - **Then**: exactly one violation for the whole token `f-implementation-exec-audit.md` (confirms multi-segment names match whole; documents intended behaviour).

- **TC-6 (out-of-scope history → not flagged)**: 
  - **Given**: a fixture `BACKLOG.md` and `CHANGELOG.md` each referencing an orphan token, plus an in-scope `.md` with the same token.
  - **When**: `validate($root)` runs.
  - **Then**: only the in-scope file is flagged; the BACKLOG/CHANGELOG hits are excluded (D4).

- **TC-7 (integration → real repo clean)**: 
  - **Given**: the real repo at HEAD after D6 orphan fixes.
  - **When**: `validate($git_root)` runs.
  - **Then**: zero violations.

### Non-Functional Test Cases
- **Reliability (fail-closed)**: if the KNOWN set is missing a required minimum name (`a-task-plan.md`, `f-implementation-exec.md`, `e-testing.md`), `validate` dies with a clear `[CWF] Validate::TemplateRefs:` message rather than passing everything. Asserted by a guard test (simulate by pointing derivation at an empty/partial source if feasible, else assert the guard exists).
- **Conventions**: module uses core-only Perl, `use utf8;`, `git ls-files -z` split on `\0`; UTF-8 paths handled.
- **Usability**: violation hashrefs carry an actionable `fix` string, consistent with sibling validators' output.

## Test Environment
### Setup Requirements
- Perl with `Test::More`, `File::Temp`, `FindBin` (all core); no external services.
- Fixtures created per-subtest under `tempdir(CLEANUP => 1)`; never touches the real tree except the read-only TC-7 integration call.

### Automation
- Runner: `prove t/validate-template-refs.t` (and full `prove t/` for regression).
- Gate: `cwf-manage validate` (invoked by `cwf-checkpoint-commit` on every CWF commit) — no separate CI/git-hook exists.

## Validation Criteria
- [ ] TC-1 … TC-7 all pass.
- [ ] Fail-closed guard verified.
- [ ] `cwf-manage validate` reports OK with the module registered.
- [ ] Full `prove t/` shows no regressions.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
Git-backed temp fixtures (`git init` + `git add`, no commit) are the clean way to test a `git ls-files`-based scanner. Keeping `.t` out of scan scope was fortunate: it lets fixtures embed deliberate orphan tokens without self-tripping the real-repo integration assertion.
