# Sync docs and README with current CWF state - Testing Plan
**Task**: 232 (chore)

## Task Reference
- **Task ID**: internal-232
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/232-sync-docs-and-readme-with-current-cwf-state
- **Template Version**: 2.1

## Goal
Verify the doc edits make each corrected claim match the shipping implementation, introduce
no new stale claim, and change nothing outside the intended prose — all by deterministic,
re-runnable grep/ls checks against the live tree (no repo-state mutation).

## Test Strategy
### Test Levels
- **Fact-correctness checks**: each edited claim (skill list, permission model, plan/exec
  wording, version-example format) asserted against ground truth (`ls .claude/skills/`,
  the `hash-updates.md` ceiling convention, `.cwf/templates/pool/` phase sets).
- **No-regression / scope-containment**: the change set touches only the intended docs and
  no hash-tracked file; `cwf-manage validate` and `prove -r t/` stay green.
- **Convention acceptance**: British spelling, no superlatives, "CwF" in prose, no personal
  names in the edited passages.

### Coverage Targets
- **100% of the d-plan edits** have a matching assertion (skill-list, permission model ×2
  files, README plan/exec ×3 anchors, version examples).
- **Negative assertions**: no bare-tag `git describe` example introduced; README ~L26 and
  the audited-clean files (COMMANDS.md, INSTALL.md) unchanged.
- Deliberately **out of scope**: no generated-artefact smoke test (removed at plan review —
  prose edits do not flow into template output; not a rebrand).

## Test Cases
### Functional
- **TC-1 — Skill-list completeness (no missing, no invented)**
  - **Given**: the edited CLAUDE.md and `ls .claude/skills/`.
  - **When**: each `/cwf-*` name in CLAUDE.md's skill list is matched against real skill
    dirs, and each of the 20 command dirs is matched against the list.
  - **Then**: exact correspondence — `cwf-current-task` and `cwf-backlog-manager` now
    present; `test-cwf-skill` still absent (internal); no name without a dir; `cwf-manage`
    still labelled the management **script**, not a skill.
- **TC-2 — Permission-model states the ceiling invariant**
  - **Given**: edited CLAUDE.md and DESIGN.md permission passages.
  - **When**: read and compared to `.cwf/docs/conventions/hash-updates.md` and real
    `cwf-manage validate`/`fix-security` behaviour.
  - **Then**: the prose says recorded permissions are an upper bound — `validate` flags a
    file only when *more* permissive than recorded, `fix-security` clamps *down*, recorded
    modes include `0444`; the string "minimum 0500" no longer asserts the inverse.
- **TC-3 — README plan/exec wording is accurate and bounded**
  - **Given**: edited README.md.
  - **When**: the three "split into planning/execution" anchors (~L65, ~L118–119, ~L154)
    are read.
  - **Then**: each is hedged (only implementation and testing have `-exec` phases); ~L26
    (file-structure line) is unchanged.
- **TC-4 — `git describe` examples preserve format, not a bare tag**
  - **Given**: edited CLAUDE.md and DESIGN.md version examples.
  - **When**: grep for the `git describe` example.
  - **Then**: it shows the `<tag>-<n>-g<sha>` shape (genericised, e.g. `v1.1.x-<n>-g<sha>`);
    no bare `v1.1.231` collapse; the old `v1.1.187` pin is gone.
- **TC-5 — Config-value samples match the owner's version-example decision**
  - **Given**: CWF-PROJECT-SPEC.md (~L52, ~L122) and README (~L215–216).
  - **When**: inspected.
  - **Then**: consistent with the recorded owner decision — either left as-is (default) or
    uniformly refreshed to the current era; never a mix, never format-broken.
- **TC-6 — No new stale count/version claim**
  - **Given**: the full edited change set.
  - **When**: grep for stale quantitative claims (old skill counts, `minimum 0500`,
    superseded version pins) across the edited docs.
  - **Then**: none survive; historical refs in CHANGELOG/BACKLOG untouched.
- **TC-7 — Scope containment (only intended files; no hash-tracked file)**
  - **Given**: `git status` / `git diff --stat` for the change set.
  - **When**: the changed-file list is compared to the d-plan's file set and to
    `.cwf/security/script-hashes.json`.
  - **Then**: only CLAUDE.md, DESIGN.md, README.md (and CWF-PROJECT-SPEC.md iff the owner
    opted to refresh) changed; COMMANDS.md and INSTALL.md unchanged; **no** edited path
    appears in `script-hashes.json`.

### Non-Functional
- **TC-8 — Integrity + suite green**
  - **Given**: the edited tree.
  - **When**: `.cwf/scripts/cwf-manage validate` and `prove -r t/` run.
  - **Then**: `validate: OK` (docs-only → no sha256/permission drift) and the full suite
    passes (unaffected by prose edits). **If validate reports a sha256 change, STOP** — a
    doc sync must not touch a hashed blob.
- **TC-9 — Prose conventions**
  - **Given**: the edited passages.
  - **When**: read.
  - **Then**: British spelling, no superlatives, "CwF" in prose (paths/namespaces keep
    casing), no personal names.

## Test Environment
### Setup
- The live working tree on the task branch (docs-only edits; safe to check in place — no
  history rewrite, no DB, no repo-state mutation).
- Tools: `ls`/`grep` (read-only), `.cwf/scripts/cwf-manage`, `prove`.

### Automation
- All checks are one-shot read-only commands; results captured verbatim into
  g-testing-exec. No throwaway-task generation, no CI integration (one-off chore).

## Validation Criteria
- [ ] TC-1..TC-9 all pass on the edited tree.
- [ ] Every d-plan edit has a passing assertion; audited-clean files unchanged.
- [ ] `cwf-manage validate` OK and `prove -r t/` green (TC-8).
- [ ] No hash-tracked file in the change set (TC-7).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1..TC-9 all PASS on the live tree; `validate: OK`; suite `Files=78, Tests=1077, PASS`. See
g-testing-exec.md.

## Lessons Learned
Grep/ls checks were the complete verification for a prose-only sync; the removed
generated-artefact smoke test would have exercised nothing (not a rebrand). Right call.
