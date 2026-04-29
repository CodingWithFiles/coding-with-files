# Reject Overlong Task Slugs - Testing Plan
**Task**: 119 (feature)

## Task Reference
- **Task ID**: internal-119
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/119-reject-overlong-task-slugs
- **Template Version**: 2.1

## Goal
Validate that the slug-length rejection works correctly at all surfaces, atomically (no filesystem writes on failure), with a useful error message, and without breaking any existing CWF behaviour.

## Test Strategy
### Test Levels
- **Unit (Perl)**: `t/template-copier-slug-validation.t` exercising `parse_parameters`'s validation in isolation via `*main::die_msg` symbol-table override. Mirrors the Tasks 115/116 pattern (`t/cwf-manage-check-clean-tree.t`, `t/cwf-manage-resolve-source.t`).
- **Integration (script)**: invoke `.cwf/scripts/command-helpers/template-copier-v2.1` directly from a shell with overlong / valid / empty inputs; assert exit code, STDERR content, and absence of filesystem writes. Verifies the full script path including the new `main() unless caller();` guard.
- **System (skill)**: invoke `/cwf-new-task` end-to-end with an overlong description; assert the user sees `[CWF] ERROR:` and no directory or branch is created.
- **Regression**: full `prove t/` run; existing CWF skills / scripts unaffected; `cwf-manage validate` returns OK after the hash refresh.

### Test Coverage Targets
- **All five FRs covered**: FR1 (overlong rejection), FR2 (error message contents), FR3 (single source of truth), FR4 (skill not pre-truncating), FR5 (existing tasks unaffected)
- **All NFRs covered**: NFR2 (atomicity, usability), NFR3 (testability)
- **Edge cases**: empty slug after normalising, leading/trailing hyphens, exactly at limit, `--destination` bypass moot (description fires first per design Decision 6)
- **Regression budget**: zero new failures in the existing test suite (baseline: full `prove t/` passing before this task)

## Test Cases
### Functional — Unit Tests (`t/template-copier-slug-validation.t`)

- **TC-1: Slug under limit accepted**
  - **Given**: A description that slugifies to 49 characters
  - **When**: `parse_parameters` is invoked with that description (in eval to catch any die)
  - **Then**: No die; `$@` is empty

- **TC-2: Slug at limit accepted**
  - **Given**: A description that slugifies to exactly 50 characters
  - **When**: `parse_parameters` is invoked with that description
  - **Then**: No die; `$@` is empty

- **TC-3: Slug just over limit rejected**
  - **Given**: A description that slugifies to 51 characters
  - **When**: `parse_parameters` is invoked
  - **Then**: Dies with message matching `/Task slug '.+' is 51 characters; limit is 50/`; matches `/briefer/`

- **TC-4: Slug well over limit rejected**
  - **Given**: A 100-character description
  - **When**: `parse_parameters` is invoked
  - **Then**: Dies with overlong-error message; actual length appears in the message

- **TC-5: Empty slug after normalising rejected**
  - **Given**: Description `"!!!"` (slugifies to empty after stripping non-alphanumerics)
  - **When**: `parse_parameters` is invoked
  - **Then**: Dies with message matching `/empty slug/i`; original description appears in the message

- **TC-6: Leading/trailing hyphens stripped, content accepted**
  - **Given**: Description `"---valid-content---"` (would slugify to `"-valid-content-"` without strip; `"valid-content"` with strip)
  - **When**: `parse_parameters` is invoked
  - **Then**: No die; the resulting slug is `"valid-content"` (length 13, under limit)

- **TC-7: Error message contents**
  - **Given**: An overlong description
  - **When**: Validation fires
  - **Then**: Error string contains: the actual length (numeric); the literal `50`; a recovery substring (e.g. "briefer" or "Use a"); is prefixed `[CWF] ERROR:` (per overridden die_msg test stub)

- **TC-8: Atomicity — no filesystem writes on rejection**
  - **Given**: A fresh `tempdir(CLEANUP => 1)` and an overlong description
  - **When**: `parse_parameters` is invoked (wrapped in eval)
  - **Then**: After the eval returns, the tempdir's listing is unchanged from before the call; no new files or subdirectories created

### Functional — Integration Tests (script-level)

- **TC-9: Direct script invocation with overlong description**
  - **Given**: An empty scratch directory
  - **When**: `.cwf/scripts/command-helpers/template-copier-v2.1 --task-type=feature --task-num=999 --description="$(perl -e 'print "long-" x 20')"` is run with `cwd=$scratch`
  - **Then**: Exit code is 1; STDERR contains `[CWF] ERROR:` and the overlong message; no files or subdirectories created in `$scratch`

- **TC-10: Direct script invocation with valid description**
  - **Given**: An empty scratch directory with `implementation-guide/` set up
  - **When**: Same script invocation but with a short description
  - **Then**: Exit code is 0; task directory created; templates copied (sanity that the new code doesn't break the happy path)

### Functional — System Tests (skill-level)

- **TC-11: `/cwf-new-task` smoke test with overlong description**
  - **Given**: A clean working tree on the task branch
  - **When**: User invokes `/cwf-new-task 999 chore "this is deliberately a very long task description that should be rejected by the new validation logic"`
  - **Then**: User sees the `[CWF] ERROR:` message; no `implementation-guide/999-…/` directory created; no `chore/999-…` branch created; current branch unchanged

- **TC-12: `/cwf-new-task` smoke test with valid description (regression)**
  - **Given**: A clean working tree on the task branch
  - **When**: User invokes `/cwf-new-task 999 chore "short test task"`
  - **Then**: Task created normally; directory `implementation-guide/999-chore-short-test-task/` exists with template files; branch `chore/999-short-test-task` checked out
  - **Cleanup**: After verification, switch back to the task branch and delete the test branch + directory

### Functional — FR3 Single-Source-of-Truth Check

- **TC-13: SLUG_MAX_LEN appears in exactly one declaration**
  - **Given**: The implementation is complete
  - **When**: `grep -rn "SLUG_MAX_LEN" .cwf/scripts/ .cwf/lib/ .claude/skills/cwf-new-task/ .claude/skills/cwf-new-subtask/` is run
  - **Then**: The `use constant SLUG_MAX_LEN => 50;` declaration appears in exactly one source file (`template-copier-v2.1`); other matches (if any) are usages of the constant within the same file, not redeclarations

### Functional — FR4 Skill De-truncation Check

- **TC-14: SKILL.md no longer instructs LLM to truncate**
  - **Given**: The implementation is complete
  - **When**: `grep -E "truncate.*50|truncate 50 chars" .claude/skills/cwf-new-task/ .claude/skills/cwf-new-subtask/` is run
  - **Then**: Zero matches

### Functional — FR5 Backwards Compatibility Check

- **TC-15: Existing tasks with truncated slugs still operable**
  - **Given**: Existing tasks in `implementation-guide/` with slugs ≥ 50 chars (several exist from prior tasks)
  - **When**: `/cwf-status` is run on the repo (and ad-hoc `/cwf-extract` on one such existing task)
  - **Then**: Both succeed; no validation error fired against pre-existing directories

### Non-Functional Test Cases

- **NFR-1 Atomicity (covered by TC-8 and TC-9)**: validation runs before any filesystem state change; rejection leaves no partial state
- **NFR-2 Usability (covered by TC-7)**: the error message is self-explanatory — a user who has not read the source can act on it
- **NFR-3 Testability (covered by the existence of TC-1 through TC-8 as unit tests)**: validation logic is exercisable in isolation via the symbol-table override pattern
- **NFR-4 Determinism**: same description + same args always yields same outcome; covered transitively by all unit tests passing repeatedly
- **NFR-5 Exit code**: rejected invocation exits non-zero (covered by TC-9)
- **Performance / Security**: N/A — local CLI, no auth surface, validation is O(1) per task creation

### Regression

- **TC-16: Existing test suite unchanged**
  - **Given**: A clean working tree with all changes applied
  - **When**: `prove t/` is run from repo root
  - **Then**: Total passing tests = baseline + new tests in `t/template-copier-slug-validation.t`; no previously-passing test now fails

- **TC-17: `cwf-manage validate` passes after hash refresh**
  - **Given**: All implementation changes applied, hash refreshed in `.cwf/security/script-hashes.json`
  - **When**: `.cwf/scripts/cwf-manage validate` runs
  - **Then**: Reports `OK`; no permission, hash, or structural violation

## Test Environment

### Setup Requirements
- Working repo on branch `feature/119-reject-overlong-task-slugs`
- Implementation phase complete (`f-implementation-exec.md` Status = Finished)
- Perl available with standard `Test::More`, `File::Temp`, `FindBin` modules (already used by existing test suite)
- `prove` available (already used)
- `sha256sum` available (Linux default)
- Working git config (for system tests that exercise branch creation)

### Automation
- Unit tests (TC-1 to TC-8) automated via `prove t/template-copier-slug-validation.t`
- Integration tests (TC-9, TC-10) — partial automation: script invocation can be wrapped in a shell test, output captured. May be done manually for this task and formalised as Perl tests later if pattern emerges
- System tests (TC-11, TC-12) — manual: skill invocation requires the harness; capture results in `g-testing-exec.md`
- FR3 / FR4 / FR5 / regression checks (TC-13 to TC-17) — automated via grep / prove / `cwf-manage validate`

## Validation Criteria
- [ ] All 17 test cases pass
- [ ] `prove t/` shows no new failures vs baseline
- [ ] `cwf-manage validate` returns `OK`
- [ ] Manual smoke test (TC-11) shows the `[CWF] ERROR:` message reaches the user, with no filesystem state created
- [ ] FR3 grep test (TC-13) returns exactly one declaration of `SLUG_MAX_LEN`

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 119
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
17/17 test cases PASS as specified. Coverage matched the plan exactly — no test added or dropped during exec. `prove t/` total: 246 = 238 baseline + 8 new. `cwf-manage validate` clean. See g-testing-exec.md for per-TC outcomes.

## Lessons Learned
See j-retrospective.md.
