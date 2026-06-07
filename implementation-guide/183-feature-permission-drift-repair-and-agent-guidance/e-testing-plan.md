# Permission-drift repair and agent guidance - Testing Plan
**Task**: 183 (feature)

## Task Reference
- **Task ID**: internal-183
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/183-permission-drift-repair-and-agent-guidance
- **Template Version**: 2.1

## Goal
Define how AC1–AC6 are verified for a docs-only change: output-level grep checks of the three
edited files, a behavioural induce-drift→fix repro (FR6), and a `cwf-manage validate` regression.
AC5 (backlog retire) is verified at retrospective (j).

## Test Strategy
### Test Levels
- **Output-level (primary)**: grep the three edited files for the rule, boundary, pointers, and
  byte-identical command — there is no code, so the "source-grep alone is insufficient" lesson
  applies in reverse: the docs *are* the deliverable, so grep of the shipped text is the
  appropriate level.
- **Behavioural (system)**: the FR6 induce-drift→`validate`→`fix-security`→`validate: OK`
  reproduction, exercising the real `cwf-manage` clamp path the guidance points at.
- **Regression**: `cwf-manage validate` clean after the edits; `git status` shows only the three
  doc files (no `script-hashes.json`, no mode bits).

### Test Coverage Targets
- Every AC (AC1–AC4, AC6) has ≥1 dedicated case here; AC5 is deferred to j with its own check.
- No code ⇒ no line-coverage metric; coverage is "every AC has a deterministic check".

## Test Cases
### Functional Test Cases
- **TC-SWEEP (AC1)**:
  - **Given**: the current tree.
  - **When**: `cwf-manage fix-security --dry-run` then `cwf-manage validate`.
  - **Then**: fix-security **exits 0** reporting `0` file(s) to repair (exit 0 specifically, so a
    coexisting sha256 `UNFIXABLE` cannot read as success); validate reports no permission violation.
- **TC-RULE (AC2)**:
  - **Given**: edited `hash-updates.md`.
  - **When**: grep for the `## Fix permission drift on sight` heading and its body.
  - **Then**: the section exists; it contains the command `cwf-manage fix-security`
    **byte-identical** to the string in `CWF/Validate/Security.pm`'s `Fix:` line; it explicitly
    rejects the defer-as-"out of scope"/"separate backlog item" response; and it gives ≥1
    role/incident-phrased negative example (no personal names).
- **TC-BOUNDARY (AC3)**:
  - **Given**: the new section.
  - **When**: grep its body.
  - **Then**: it states permission-clamp is the only auto-repairable violation AND sha256/content
    drift is surface-not-smooth (cross-referencing `## What NOT to build`); it states the
    working-tree-only / no-committable-diff persistence (cross-referencing "Recorded permissions
    are a ceiling"); and it contains **no** instruction to recompute a hash to clear `validate`.
- **TC-POINTERS (AC2)**:
  - **Given**: edited `checkpoint-commit.md` and `CLAUDE.md`.
  - **When**: grep both.
  - **Then**: `checkpoint-commit.md` carries the fix-on-sight/surface-not-smooth note on **both**
    the Script and Manual paths, each cross-referencing
    `.cwf/docs/conventions/hash-updates.md#fix-permission-drift-on-sight` in the **repo-rooted
    inline-backtick** form (no `../` relative path); `CLAUDE.md`'s Hash Updates entry has the
    pure-pointer bullet.
- **TC-XREF (AC2, link integrity)**:
  - **Given**: the cross-reference anchor `#fix-permission-drift-on-sight`.
  - **When**: derive the GitHub heading slug of `## Fix permission drift on sight`.
  - **Then**: the slug equals the anchor (lowercase, spaces→hyphens) — the link resolves.
- **TC-NOSURFACE (AC4)**:
  - **Given**: the task's full diff against the baseline.
  - **When**: inspect changed paths and `cwf-manage` help/usage.
  - **Then**: only the three doc files changed; no change to `cwf-manage` or any script; no new
    subcommand/flag; no `script-hashes.json` entry added or modified.

### Non-Functional Test Cases
- **TC-REPRO (AC6, reliability/security — the centrepiece)**:
  - **Given**: a clean tree and a recorded-`0500` tracked script (e.g.
    `.cwf/scripts/command-helpers/security-review-changeset`).
  - **When**: `chmod 0700 <script>` (induce drift) → `cwf-manage validate` → `cwf-manage
    fix-security` → `cwf-manage validate` → `git status`.
  - **Then**: validate **flags** the drift after the chmod (signal not lost); fix-security clamps
    it back to `0500`; validate returns `OK`; `git status` is clean (no diff — the mode change is
    within the same `100755` git class). Interrupt-recovery: re-running fix-security is idempotent.
- **TC-VALIDATE (AC4, regression)**:
  - **Given**: the completed edits.
  - **When**: `cwf-manage validate`.
  - **Then**: `validate: OK` (docs-only; no hash/perm desync).

### Deferred to retrospective (j)
- **TC-RETIRE (AC5)**: after the CHANGELOG `## Task 183:` section exists,
  `backlog-manager retire --task=183` removes the Task-173 item from `backlog-manager list` and
  records it under `### Retired Backlog Items`; `backlog-manager validate` stays clean.

## Test Environment
### Setup Requirements
- A working CWF tree; `cwf-manage`, `backlog-manager`; `git`. No production data; the TC-REPRO
  chmod is on a tracked script in the working tree and is fully reverted by the clamp.
- British-spelling / no-superlatives / no-personal-names checks are manual reads of the new prose.

### Automation
- Ad-hoc commands run in g-testing-exec (no new harness — there is no code to unit-test). The
  existing `t/` suite is unaffected (no scripts changed) and is re-run as a regression smoke.

## Validation Criteria
- [ ] TC-SWEEP: fix-security --dry-run exit 0 / 0 files; validate no perm violation (AC1)
- [ ] TC-RULE + TC-BOUNDARY: rule, boundary, byte-identical command, example present (AC2/AC3)
- [ ] TC-POINTERS + TC-XREF: both-path note + index pointer, repo-rooted backtick xref resolves (AC2)
- [ ] TC-NOSURFACE: only three doc files changed; no new surface; no hash change (AC4)
- [ ] TC-REPRO: induce-drift → validate flags → fix → validate OK → clean git status (AC6)
- [ ] TC-VALIDATE: `validate: OK` regression
- [ ] TC-RETIRE: deferred to j (AC5)

## Decomposition Check
Unchanged: 0 signals. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
