# Lint agent files for ignored allowed-tools key - Testing Plan
**Task**: 193 (hotfix)

## Task Reference
- **Task ID**: internal-193
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/193-lint-agent-files-for-ignored-allowed-tools-key
- **Template Version**: 2.1

## Goal
Define the test strategy for `CWF::Validate::Agents` — the validator flagging the
silently-ignored `allowed-tools:` key in CWF agent frontmatter.

## Test Strategy
### Test Levels
- **Unit** (`t/validate-agents.t`): exercise `validate($git_root)` directly over
  synthetic tempdir fixtures — the same pattern as `t/validate-templates.t`. This is
  the primary level; it covers detection, scan-target resolution, and the violation
  hashref contract without touching the repo's real agent files.
- **Integration** (`cwf-manage validate` on the real tree): confirms the wire-in and
  that the live corpus (all five `cwf-*` agents already on `tools:`) produces zero
  violations and exit 0.
- **Regression** (`prove t/`): the full suite passes — no collateral breakage.

There are no non-functional dimensions of substance here (a read-only, core-Perl,
in-process line scanner over ~5 small files); performance/load testing is N/A.

### Test Coverage Targets
- **Critical path** (bad-key detected; clean tree silent): 100% — both directions covered.
- **Edge cases**: body-only occurrence, unterminated frontmatter, no-frontmatter,
  non-CWF filename, installed-context (`.cwf-agents/`) path — all covered.
- **Regression**: existing `t/` suite green; `cwf-manage validate` green on real tree.

## Test Cases
All fixtures are built under `File::Temp::tempdir(CLEANUP => 1)`; `$git_root` is the
temp root. The real `.claude/agents/` is never written. Each case calls
`CWF::Validate::Agents::validate($root)` and asserts on the returned list.

### Functional Test Cases
- **TC-1 — happy path (correct key)**
  - **Given**: `$root/.claude/agents/cwf-x.md` with frontmatter using `tools: Read, Grep`.
  - **When**: `validate($root)` runs.
  - **Then**: returns `()` — 0 violations.

- **TC-2 — bad key flagged (core requirement)**
  - **Given**: `$root/.claude/agents/cwf-x.md` whose frontmatter contains
    `allowed-tools: Read, Grep`.
  - **When**: `validate($root)` runs.
  - **Then**: exactly 1 violation; `category=AGENTS`,
    `file=.claude/agents/cwf-x.md`, `field=frontmatter-key`,
    `actual=allowed-tools:`, `expected=tools:`, and `fix` matches `/tools:/`.

- **TC-3 — body occurrence is not flagged (no false positive)**
  - **Given**: `cwf-x.md` with valid `tools:` frontmatter, then a closing `---`, then
    body prose containing the literal `allowed-tools:` (e.g. in a code sample).
  - **When**: `validate($root)` runs.
  - **Then**: 0 violations — only the frontmatter block is inspected.

- **TC-4 — installed-context scan target (`.cwf-agents/`)**
  - **Given**: `$root/.cwf-agents/cwf-x.md` with `allowed-tools:` in frontmatter and
    **no** `$root/.claude/agents/` directory.
  - **When**: `validate($root)` runs.
  - **Then**: 1 violation with `file=.cwf-agents/cwf-x.md` — confirms the
    prefer-`.cwf-agents/` branch is exercised, not a vacuous pass.

- **TC-5 — non-CWF filename ignored**
  - **Given**: `$root/.claude/agents/other.md` (no `cwf-` prefix) with `allowed-tools:`.
  - **When**: `validate($root)` runs.
  - **Then**: 0 violations — the validator only polices the `cwf-*` namespace.

- **TC-6 — no frontmatter**
  - **Given**: `cwf-x.md` whose line 1 is not `---` (plain body text mentioning
    `allowed-tools:`).
  - **When**: `validate($root)` runs.
  - **Then**: 0 violations.

- **TC-7 — unterminated frontmatter**
  - **Given**: `cwf-x.md` with opening `---` on line 1, `allowed-tools:` a few lines
    down, and **no** closing `---` before EOF.
  - **When**: `validate($root)` runs.
  - **Then**: 0 violations — an unclosed block is not valid frontmatter and the whole
    file must not be scanned (guards the TC-3 invariant on malformed input).

- **TC-8 — multiple bad files, deterministic**
  - **Given**: two `cwf-*.md` files both with `allowed-tools:`.
  - **When**: `validate($root)` runs.
  - **Then**: 2 violations, one per file, file paths sorted (readdir order sorted),
    one violation per file (no duplicates from multiple frontmatter lines).

### Integration / Regression
- **TC-9 — real tree stays green**: `cwf-manage validate` exits 0 on the current repo
  (all five agents use `tools:`), proving zero false positives on the real corpus and
  that the wire-in did not break the other validators.
- **TC-10 — full suite**: `prove t/` passes with `t/validate-agents.t` included.

### Non-Functional Test Cases
- **Security**: covered by the plan-review security pass — read-only validator, no
  command construction, no env reads, no prompt-injection surface. Nothing to test at runtime.
- **Reliability**: malformed-input handling is TC-6/TC-7; an unreadable/odd file should
  not crash the run (validator follows `Templates.pm` die-on-opendir-failure semantics
  only for a missing scan dir, which is itself guarded by the `-d`/glob skip).

## Test Environment
### Setup Requirements
- Core Perl + `Test::More`, `File::Temp`, `File::Path` (all core) — same as the
  sibling `t/validate-*.t` tests. No network, no DB, no external services.
- Fixtures self-contained per subtest via `tempdir(CLEANUP => 1)`.

### Automation
- Run via `prove t/validate-agents.t` (single file) and `prove t/` (full suite).
- Integration check via `.cwf/scripts/cwf-manage validate`.

## Validation Criteria
- [ ] TC-1..TC-8 pass in `t/validate-agents.t`.
- [ ] TC-9: `cwf-manage validate` → `validate: OK` on the real tree.
- [ ] TC-10: `prove t/` green (no regressions).
- [ ] `cwf-manage validate` also confirms PerlConventions + hash integrity for the new
      module and the edited `cwf-manage`.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 10 cases executed and passed (g-testing-exec.md, `1896afb`). TC-7 (unterminated
frontmatter) caught a real ordering defect during implementation — the test plan earned its
keep. `cwf-manage validate` green on the real tree; full suite 734 tests pass.

## Lessons Learned
Asserting "the check did something" (TC-4: the `.cwf-agents/` branch actually inspected a
file) is as valuable as asserting its verdict — it guards against a vacuous pass. Full set
in j-retrospective.md.
