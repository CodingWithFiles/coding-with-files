# cwf-init dead UserPromptSubmit hook matcher - Testing Plan
**Task**: 195 (bugfix)

## Task Reference
- **Task ID**: internal-195
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/195-cwf-init-dead-userpromptsubmit-hook-matcher
- **Template Version**: 2.1

## Goal
Validate that `cwf-claude-settings-merge` registers the rules-inject `UserPromptSubmit` hook
in the correct group-wrapper shape, migrates away the dead `PreToolUse`/`UserPromptSubmit`
entry without touching sibling groups, is idempotent, never dies on hand-edited settings,
and surfaces the migration — plus an output-level `/cwf-init` smoke test.

## Test Strategy
### Test Levels
- **Unit (primary)**: New subtests in `t/cwf-claude-settings-merge.t`, mirroring the existing
  fixture harness (`build_fixture` / `write_settings` / `run_helper` / `read_settings`) and
  the `TC-M*`/`TC-U*` naming. The helper is run as a subprocess with cwd = tempdir; assertions
  decode the resulting `.claude/settings.json`.
- **Regression**: full `prove t/cwf-claude-settings-merge.t` plus the rest of `t/` — confirm no
  existing TC-U*/TC-M*/sandbox case changes behaviour (the sandbox-OFF byte-for-byte invariant
  must hold).
- **Output-level smoke (manual, system)**: run the helper in a throwaway dir seeded with the
  dead entry; eyeball the final settings.json shape. Required by the backlog entry and
  MEMORY.md "rebrands/output need an output-level smoke test".

### Test Coverage Targets
- **Critical paths**: 100% — fresh registration, migration, idempotency, defensive guards.
- **Edge cases**: all four malformed-`PreToolUse` shapes; index-0 matcher-bearing group.
- **Regression**: existing suite green, zero behaviour change for non-UserPromptSubmit paths.

## Test Cases
### Functional Test Cases (new subtests)
- **TC-UPS1 — fresh add creates the correct group-wrapper shape**
  - **Given**: a standard manifest fixture, no `hooks` key in settings (this repo's state).
  - **When**: the helper runs.
  - **Then**: `hooks.UserPromptSubmit` is `[ { "hooks": [ { type=>"command",
    command=>"cat .cwf/rules-inject.txt 2>/dev/null || true" } ] } ]` — assert the **exact
    structure** (group wrapper present, no `matcher` key, no flat form), not just command
    presence. Mirrors TC-M1.

- **TC-UPS2 — migration removes the dead entry, preserves siblings**
  - **Given**: settings pre-seeded with `hooks.PreToolUse` containing **two** groups: the dead
    `{ matcher=>"UserPromptSubmit", hooks=>[{...cat...}] }` and a legitimate
    `{ matcher=>"Edit|Write", hooks=>[{command=>"x"}] }`.
  - **When**: the helper runs.
  - **Then**: the dead group is gone; the `Edit|Write` group is untouched; `hooks.PreToolUse`
    still exists (non-empty); `hooks.UserPromptSubmit` now holds the correct hook; stdout
    reports the migration count (≥1).

- **TC-UPS3 — PreToolUse key dropped when it becomes empty**
  - **Given**: settings with `hooks.PreToolUse` = only the dead group.
  - **When**: the helper runs.
  - **Then**: `hooks.PreToolUse` key is **absent** (not `[]`); `UserPromptSubmit` registered.

- **TC-UPS4 — idempotent re-run**
  - **Given**: a settings file already converged by one helper run.
  - **When**: the helper runs again.
  - **Then**: byte-identical result; `hook_added` for the rules-inject command is 0; no
    duplicate `UserPromptSubmit` group/command. Mirrors TC-M3 / TC-6b.

- **TC-UPS5 — defensive against malformed settings (never dies)**
  - **Given**: four sub-fixtures — `PreToolUse` not an array; a group that is not a hash; a
    group missing `matcher`; `matcher` a non-scalar (arrayref).
  - **When**: the helper runs on each.
  - **Then**: exit 0 each time (no die); malformed `PreToolUse` content is left as-is except
    the targeted dead-group removal; `UserPromptSubmit` still registered.

- **TC-UPS6 — index-0 matcher-bearing UserPromptSubmit group (known shape interaction)**
  - **Given**: settings with `hooks.UserPromptSubmit` = `[ { matcher=>"X", hooks=>[] } ]`.
  - **When**: the helper runs.
  - **Then**: the rules-inject command is appended into that index-0 group's `hooks` (per
    `find_or_make_group(undef)`); assert the **resulting shape and that re-run dedupes** (no
    second copy) — not merely "doesn't crash".

- **TC-UPS7 — --dry-run writes nothing**
  - **Given**: settings with the dead entry.
  - **When**: helper runs with `--dry-run`.
  - **Then**: file on disk unchanged; stdout previews the merged result. Mirrors TC-U4.

- **TC-UPS8 (only if D4 kept) — directive-driven UserPromptSubmit hook honoured**
  - **Given**: a `.cwf/scripts/hooks/` stub whose header has `# cwf-hook-event: UserPromptSubmit`.
  - **When**: the helper runs.
  - **Then**: it registers under `hooks.UserPromptSubmit` (not downgraded to `Stop`),
    proving the widened allowlist. Mirrors TC-M2/TC-M4.

### Non-Functional Test Cases
- **Reliability**: TC-UPS5 is the graceful-degradation case — best-effort over user-edited
  settings, never abort the install/update (consistent with `warn_on_worktree_allowlist`).
- **Security**: confirm the hook `command` value in output is byte-identical to the
  compile-time constant (no interpolation) — guards the FR4(e) invariant.
- **Integrity**: `cwf-manage validate` clean after the same-commit sha256 refresh;
  `cwf-manage fix-security --dry-run` reports no permission drift (helper at recorded 0500).

## Test Environment
### Setup Requirements
- Perl with `JSON::PP`, `Test::More`, `File::Temp` (core; per project Perl-core-only rule).
- Reuse the existing `t/cwf-claude-settings-merge.t` harness helpers; no new scaffolding.
- Output-level smoke: a throwaway dir with `.cwf/security/script-hashes.json` + a seeded
  dead-entry `settings.json`; run the helper, read back the file.

### Automation
- `prove -v t/cwf-claude-settings-merge.t` for the new subtests; full `prove t/` for regression.
- No CI config change — tests run under the existing `t/` runner.

## Validation Criteria
- [ ] TC-UPS1..7 passing (TC-UPS8 iff D4 kept)
- [ ] Full `t/` suite green — no regression in TC-U*/TC-M*/sandbox cases
- [ ] Output-level `/cwf-init`-path smoke test shows a working top-level `UserPromptSubmit`
      hook and no dead `PreToolUse` matcher
- [ ] `cwf-manage validate` clean; `fix-security --dry-run` no drift
- [ ] Migration count surfaced in stdout (TC-UPS2)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None — D5 keep-and-fix, D4 keep-in-task (user 2026-06-12). TC-UPS8 and the
synthetic-entry cases are all in scope.

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-UPS1–8 + the two regression updates (TC-U1/TC-U4) all PASS — 41 subtests in
`t/cwf-claude-settings-merge.t`. Full suite 749 tests, 748 PASS at exec time; the single red
was the in-flight `security-review-changeset.t` TC-VALIDATE assertion 3, an artefact of
non-terminal plan statuses, resolved by the retrospective status sweep.

## Lessons Learned
The defensive-shape coverage (four malformed `PreToolUse` shapes in TC-UPS5) was cheap to
write and directly retired the migration's reliability risk over hand-edited settings.
Output-level smoke testing on a scratch repo proved the end-to-end shape that source-level
unit tests alone cannot.
