# changelog header brand name - Testing Plan
**Task**: 184 (bugfix)

## Task Reference
- **Task ID**: internal-184
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/184-changelog-header-brand-name
- **Template Version**: 2.1

## Goal
Validate the two deliverables: (1) CWF's own `CHANGELOG.md:3` reads `Coding with Files (CWF)`; (2) `CHANGELOG-005` warns on a stale-brand intro, stays silent on a canonical intro or body-only "(CIG)", and escalates under `--strict`.

## Test Strategy
### Test Levels
- **Unit Tests** (`t/backlog-tree-validate.t`): `CHANGELOG-005` rule behaviour against in-memory CHANGELOG fixtures via `parse_and_validate_changelog` + `has_rule`/`get_rule` (existing harness helpers).
- **CLI/integration**: `--strict` warning→error promotion exercised through `backlog-manager validate --strict` (escalation lives in the caller, not `validate_changelog_tree`).
- **System/regression**: full `prove t/`; `cwf-manage validate` on the live repo; output-level smoke grep of `CHANGELOG.md`.
- **Acceptance**: the corrected intro line is present and no production artefact in scope still carries the stale brand.

### Test Coverage Targets
- **Critical paths**: 100% — every `CHANGELOG-005` branch (fires / silent-canonical / silent-body-only / severity / strict-escalation).
- **Regression**: existing `t/backlog-tree-validate.t` rules (CHANGELOG-001..004) and full suite unaffected.
- **No new uncovered code**: the only new code is the `CHANGELOG-005` block; all branches exercised.

## Test Cases
### Functional Test Cases (unit — `t/backlog-tree-validate.t`)
- **TC-1 — fires on stale intro**
  - **Given**: a CHANGELOG whose intro contains `# Changelog\n\nAll notable changes to the Code Implementation Guide (CIG) project…`
  - **When**: `parse_and_validate_changelog($bytes)`
  - **Then**: `has_rule($errs, 'CHANGELOG-005')` is true; the finding's `severity` is `warning`; `line` is 1.

- **TC-2 — silent on canonical intro**
  - **Given**: the same intro but with `Coding with Files (CWF)`
  - **When**: validated
  - **Then**: `has_rule($errs, 'CHANGELOG-005')` is false (and CHANGELOG-001 still passes).

- **TC-3 — silent when only the body has "(CIG)" (intro-scoping proof)**
  - **Given**: a canonical intro plus a `## Task 59: …` entry whose body text contains `Code Implementation Guide (CIG)`
  - **When**: validated
  - **Then**: `CHANGELOG-005` does **not** fire — confirms the scan is bound to `$tree->{intro}`, never the body.

- **TC-4 — severity is warning, not error (default)**
  - **Given**: the stale-intro fixture from TC-1
  - **When**: validated (no strict)
  - **Then**: the `CHANGELOG-005` finding's `severity eq 'warning'`; a non-strict `backlog-manager validate` exits 0 (warning printed, not fatal).

- **TC-5 — escalates under `--strict` (CLI)**
  - **Given**: a temp repo/file with the stale-intro fixture
  - **When**: `backlog-manager validate --strict` is run against it
  - **Then**: it exits non-zero and reports `CHANGELOG-005` as an error (existing generic promotion; no rule-specific code).

### Non-Functional Test Cases
- **Reliability**: TC-3 guards the one real failure mode (false positive on historical body entries). No I/O, concurrency, or perf surface — the change is a read-only in-memory scan.
- **Security**: no new attack surface (no file writes, no new exec, no env-var reads, no untrusted input). `cwf-manage validate` integrity check still passes after the `Backlog.pm` sha256 refresh.
- **Usability**: the warning message names the canonical string `Coding with Files (CWF)` so a reader knows the expected value.

### Acceptance / system
- **TC-6 — header corrected**: `grep -n "Coding with Files (CWF)" CHANGELOG.md` matches line 3; `grep -n "Code Implementation Guide (CIG)" CHANGELOG.md` returns **no** line-3 match (only historical body entries remain).
- **TC-7 — live validate clean**: `cwf-manage validate` → OK, and `CHANGELOG-005` does not fire on CWF's own (now-canonical) CHANGELOG.
- **TC-8 — no regressions**: `prove t/` all green.

## Test Environment
### Setup Requirements
- Perl + `Test::More` (core); existing `t/` harness. In-memory fixtures via the file-`tempfile` `write_tmp` helper already in `t/backlog-tree-validate.t`.
- TC-5 needs a throwaway temp dir with a minimal repo layout for the `backlog-manager validate --strict` CLI run (reuse existing CLI-test scaffolding patterns in `t/`).

### Automation
- All automated under `prove t/`; no manual steps except the TC-6/TC-7 smoke checks (also scriptable as grep assertions).

## Validation Criteria
- [ ] TC-1..TC-8 all pass
- [ ] `prove t/` fully green (no regressions)
- [ ] `cwf-manage validate` OK after `Backlog.pm` sha256 refresh
- [ ] Smoke grep: line 3 canonical; stale string only in historical body

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All TC-1..TC-8 passed on first execution in the g phase (see g-testing-exec.md for
the results table). TC-3 (body-only "(CIG)" silent) confirmed the intro-scoping
invariant both in-memory and against the live `CHANGELOG.md`. Full suite: 698
tests green.

## Lessons Learned
The TC-3 intro-scoping case was the test that mattered — it is the one guarding the
single real failure mode (false positives on legitimate historical body entries).
A brand-drift guard without that case would have been actively harmful.
