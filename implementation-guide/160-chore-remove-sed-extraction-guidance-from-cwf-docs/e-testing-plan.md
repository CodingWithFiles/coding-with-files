# Remove sed extraction guidance from CWF docs - Testing Plan
**Task**: 160 (chore)

## Task Reference
- **Task ID**: internal-160
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/160-remove-sed-extraction-guidance-from-cwf-docs
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for Remove sed extraction guidance from CWF docs.

## Test Strategy
This is a docs-only change. There is no executable assertion over prose, so verification is **grep-based** (absence of the stale command pattern, presence of the replacement guidance) plus a **full-suite regression run** to confirm nothing else moved. Grep patterns are discriminating — never a bare `sed` substring (which matches `based`/`used`/`standardised`).

### Test Levels
- **Content checks (grep)**: assert exact-string removal/addition in the two edited files.
- **Regression**: `prove -lr t/` — the existing Perl suite must stay green (no doc string is referenced by any test, so this is a guard against accidental collateral edits).

### Coverage Target
Both edited files (`COMMANDS.md`, `DESIGN.md`) fully covered by the content checks below. No code coverage dimension (no code changed).

## Test Cases
### Functional Test Cases
- **TC-1**: COMMANDS.md `sed` Method line removed
  - **Given**: the stash applied to the branch
  - **When**: `grep -nE 'sed -n|sed commands' COMMANDS.md`
  - **Then**: zero matches (the `/cwf-extract` `**Method**: Uses sed -n …` line is gone)

- **TC-2**: DESIGN.md `sed` extraction guidance removed
  - **Given**: the stash applied
  - **When**: `grep -nE 'sed -n|sed commands' DESIGN.md`
  - **Then**: zero matches (both the success criterion and the Section Extraction Commands fenced block no longer reference `sed`)

- **TC-3**: DESIGN.md replacement guidance present
  - **Given**: the stash applied
  - **When**: `grep -n 'grep and read tools' DESIGN.md` and `grep -n 'offset and limit' DESIGN.md`
  - **Then**: each returns ≥1 match (the grep-for-line-number + read-with-offset/limit guidance landed)

- **TC-4**: change confined to the two intended files
  - **Given**: the stash applied, before commit
  - **When**: `git status --short`
  - **Then**: only `COMMANDS.md` and `DESIGN.md` are modified; nothing else

### Non-Functional Test Cases
- **Regression**: `prove -lr t/` → full suite green (expected unaffected; docs-only).
- **Integrity**: `cwf-manage validate` → OK (neither file is hash-tracked; this confirms no unexpected hashed-file drift).

## Test Environment
### Setup Requirements
- The repo at the task branch with `stash@{0}` ("Task 159 follow-up: sed→grep+read") available to apply.
- No test data, mocks, or services — content checks run against the working tree.

### Automation
- Manual grep checks + the existing `prove` harness. No new automation; no CI wiring for doc prose.

## Validation Criteria
- [ ] TC-1, TC-2 — zero `sed`-extraction matches in either file
- [ ] TC-3 — grep+read guidance present in DESIGN.md
- [ ] TC-4 — only the two intended files modified
- [ ] `prove -lr t/` green; `cwf-manage validate` OK

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1..TC-4 all PASS; full suite 48 files / 527 tests green; `cwf-manage validate` OK. Results in g-testing-exec.md.

## Lessons Learned
For verifying string *removal*, grep the command pattern (`sed -n`), never the bare keyword — `sed` is a substring of `based`/`used`/`standardised`, so a keyword grep can never confirm absence. See j-retrospective.md.
