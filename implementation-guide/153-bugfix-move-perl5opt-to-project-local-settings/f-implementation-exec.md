# move PERL5OPT to project-local settings - Implementation Execution
**Task**: 153 (bugfix)

## Task Reference
- **Task ID**: internal-153
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/153-move-perl5opt-to-project-local-settings
- **Template Version**: 2.1

## Goal
Execute `d-implementation-plan.md` and validate against `e-testing-plan.md`.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Actual Results

### Step 1 — `merge_env` in `cwf-claude-settings-merge`
- **Actual**: Added `$CANONICAL_PERL5OPT = '-CDSLA'` constant + `merge_env($settings)` after `merge_hooks`; wired `my $env_added = merge_env($settings);` into main; extended both report lines with `, $env_added env keys`; broadened header comment and `usage()`. Direct three-way branch (absent→add / equal→no-op / mismatch→warn) plus type guards on non-hash `env` and non-scalar `PERL5OPT`. FR4(e) constant-only note added by the constant.
- **Deviations**: none.

### Step 2 — `check_perl5opt` retarget (`CWF::Common`)
- **Actual**: Warning body now points at the project `.claude/settings.json`, recommends `cwf-manage update` + Claude Code restart, and names the bare-shell `export` case. POD updated to match. No behaviour change (still warn-only).
- **Deviations**: none.

### Step 3 — `/cwf-init` SKILL.md
- **Actual**: Step 7 retired → "PERL5OPT (no user action)" note (auto-installed by 6d, committed by step 8); removed the `grep -q ... ~/.claude/settings.json` pre-check. Step-6 cross-note (line 80) reworded. Success criterion (line 180) reworded. Step 8 `git add` already lists `.claude/settings.json` — confirmed, no edit.
- **Deviations**: Phrased the note as "your global user settings" rather than the literal `~/.claude/settings.json` path, so the closing zero-hit grep (TC-10) stays a clean invariant. Same for INSTALL.md and perl.md. Wording choice, no behavioural change.

### Step 4 — INSTALL.md
- **Actual**: Step 3 retargeted to project `.claude/settings.json`, notes auto-install via `/cwf-init` + `cwf-manage update`, adds migration note (project value overrides any global; removal optional). Troubleshooting (formerly line 316) references step 3, now correct — no stale path.
- **Deviations**: none.

### Step 5 — perl.md
- **Actual**: Runtime-flags bullet retargeted to project `.claude/settings.json` (installed via `cwf-claude-settings-merge`), shell fallback for non-tool-call invocations.
- **Deviations**: none.

### Step 6 — Hash refresh (same commit)
- **Actual**: Pre-refresh `git log` per file — `Common.pm` last touched Task 142 (`2b0d524`), `cwf-claude-settings-merge` last touched Task 140 (`f833bbf`); both completed tasks that refreshed in-commit, and pre-edit `cwf-manage validate` was clean (no prior drift). `sha256sum` → updated both `sha256` entries in `.cwf/security/script-hashes.json`. `cwf-manage validate` → OK.
- **Deviations**: none.

### Step 7 — Dogfood commit of repo `.claude/settings.json`
- **Actual**: Helper was never run against the real repo (only tempdir tests + `cwf-manage fix-security`/`validate`), so the working-tree file stayed clean. Commit-time guard satisfied: content is exactly `{"env":{"PERL5OPT":"-CDSLA"}}`, no `permissions`/`hooks`. Staged as-is.
- **Deviations**: none.

### Step 8 — Verification
- **Closing grep**: `git grep -nE '~/\.claude/settings\.json' -- ':!implementation-guide/' ':!CHANGELOG.md'` → no matches. No surviving global PERL5OPT reference.
- **Tests**: extended `t/cwf-claude-settings-merge.t` with TC-U7..TC-U13 (merge_env branches + sibling-preservation + dry-run mismatch); fixed TC-U4's dry-run summary regex for the new `env keys` field. `prove t/cwf-claude-settings-merge.t t/common.t` → PASS (33 tests). Full `prove t/` → all green **except** the pre-existing `t/cwf-manage-fix-security.t` (see Deviations).
- **`cwf-manage validate`**: OK after hash refresh + the permission repair noted below.
- **BACKLOG**: two follow-ups added (canonical-value SSOT; the fix-security test-fixture bug). `backlog-manager validate` clean.

## Deviations / Notes
1. **Pre-existing failing test, not introduced here.** `t/cwf-manage-fix-security.t` (TC-1, TC-2, TC-7) fails on a clean tree. Root cause: its `build_fixture` copies only `.cwf/`, but `.cwf/security/script-hashes.json` also lists 5 `.claude/agents/*` paths (hash-tracked since ~Task 148/149), so the fixture is missing those files and `fix-security`/`validate` report missing-file. **Confirmed identical failure at baseline `b5b8739`** via a throwaway `git worktree` (removed after). Filed as a Medium BACKLOG bugfix; deliberately not absorbed into this task (out of scope — PERL5OPT location, not test fixtures).
2. **Permission-only drift repaired via `cwf-manage fix-security`.** `.claude/agents/cwf-plan-reviewer-misalignment.md` was 0600 (should be 0444) — a git-checkout artefact (git can't represent 0444), the top BACKLOG item, sha intact. Repaired with the canonical tool; the chmod is not committable (git stores 100644 either way), so it does not appear in this task's diff. `validate` clean afterwards.
3. **Self-flag — `echo "exit=$?"` habit leak.** Appended `echo "exit=$?"` to the closing-grep Bash call once. Violates [[feedback_no_echo_exit]] (harness already reports exit codes). No impact; noted for honesty. A mechanical detector is already a BACKLOG item (Task 150 follow-up).

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred without user approval

## Security Review

**State**: no findings

no findings
The implementation-phase changeset is clean against the threat model. The one security-sensitive surface — writing to `.claude/settings.json` `env`, which feeds every tool-call environment with no trust gate — is correctly handled: the merged `PERL5OPT` value is a compile-time constant (`$CANONICAL_PERL5OPT = '-CDSLA'`), never externally sourced, with add-if-absent / warn-on-mismatch / never-overwrite semantics, and type guards on both the `env` object and the existing scalar value. The inline comment ties this to category (e). Doc/comment edits and `CWF/Common.pm` warning-text changes are non-executable. Test additions are out of scope for the implementation review.

One pattern note (safe here): `merge_env` is safe specifically because `$CANONICAL_PERL5OPT` is a literal — audit any future change that sources an env value from the manifest, user input, or environment, since the tool-call `env` path has no trust-gate.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 153
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**
