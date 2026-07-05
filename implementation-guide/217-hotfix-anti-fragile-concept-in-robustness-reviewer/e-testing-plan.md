# Anti-fragile concept in robustness reviewer - Testing Plan
**Task**: 217 (hotfix)

## Task Reference
- **Task ID**: internal-217
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/217-anti-fragile-concept-in-robustness-reviewer
- **Template Version**: 2.1

## Goal
Validate that the anti-fragile clause is present, accurate, concise, and
integrity-clean. This is a docs-only prose edit — no code, no test framework;
"tests" are deterministic checks plus a prose read-through, mapped to the
a-task-plan success criteria.

## Test Strategy
### Test Levels
- **Content checks** (deterministic): grep for the term, word-count delta,
  untouched-file confirmation.
- **Integrity check** (deterministic): `cwf-manage validate` after the hash
  refresh.
- **Prose review** (judgement): re-read each edited sentence against the three
  success criteria.

### Test Coverage Targets
Every a-task-plan success criterion maps to at least one test case below; every
edited file is covered by the integrity check. No numeric coverage target
applies to a prose edit.

## Test Cases
### Functional Test Cases
- **TC-1 — term present, scoped**: (success criterion 1)
  - **Given**: the edit(s) applied.
  - **When**: Grep tool for `anti-fragil` over `.claude/agents/`.
  - **Then**: the term appears in the intended file(s) (changeset reviewer, and
    plan reviewer iff both-file scope chosen) and in NO other file.

- **TC-2 — distinguishes anti-fragile from robust**: (success criterion 1)
  - **Given**: the edited step-3 sentence.
  - **When**: read it.
  - **Then**: it names the fragile → robust → anti-fragile spectrum, making
    "strengthens under stress" distinct from "resists" — not a synonym for robust.

- **TC-3 — concise, no bloat**: (success criterion 2)
  - **Given**: the diff of the changeset reviewer file.
  - **When**: inspect the added lines.
  - **Then**: the addition is the two-sentence clause only (no new section,
    bullet, or heading); no pre-existing guidance duplicated.

- **TC-4 — every criterion is diff-observable**: (success criterion 3)
  - **Given**: the edited step-3 sentence for the changeset reviewer (static-diff
    input, no Bash).
  - **When**: check each named property.
  - **Then**: all are visible in a diff (fail-safe defaults, defensive fallbacks,
    bad-input handling); no runtime-only term (`load`, `partial failure`,
    `self-hardening`) is present.

- **TC-5 — verdict semantics preserved**: (success criterion 3)
  - **Given**: the edited sentence plus the unchanged verdict block.
  - **When**: read the advisory clause.
  - **Then**: it states anti-fragility is advisory and its mere absence is not a
    `findings` trigger, so robust-but-not-anti-fragile diffs are not false
    positives.

- **TC-6 — integrity refreshed in same commit**: (design constraint)
  - **Given**: the edit(s) staged with the `script-hashes.json` refresh.
  - **When**: run `.cwf/scripts/cwf-manage validate`.
  - **Then**: exit 0 — no sha256 or permission drift; edited file(s) back at 0444.

- **TC-7 — single-role boundary held**: (design constraint)
  - **Given**: the change.
  - **When**: confirm `cwf-agent-shared-rules.md` is not in the diff.
  - **Then**: the anti-fragile guidance stayed out of shared rules (inclusion bar).

### Non-Functional Test Cases
- **Regression (reviewer still parseable)**: the changeset reviewer's `cwf-review`
  verdict block is byte-unchanged, so `security-review-classify` still parses it.
- N/A: performance, security-auth, usability — no runtime surface changes.

## Test Environment
### Setup Requirements
- The repo working tree on the task branch; no test data, services, or mocks.

### Automation
- `cwf-manage validate` is the only tool invocation; the remaining checks are
  Grep-tool reads and a manual prose read. No CI hook specific to this task.

## Validation Criteria
- [ ] TC-1 … TC-7 all pass
- [ ] `cwf-manage validate` exits 0
- [ ] Verdict block byte-unchanged (regression)
- [ ] No unintended file in the diff

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 7 test cases + regression executed and passed in g-testing-exec.md.

## Lessons Learned
For a prose edit, deterministic checks (grep, `validate`, diff-of-verdict-block)
plus a prose read-through are sufficient and map cleanly to success criteria.
