# move PERL5OPT to project-local settings - Implementation Plan
**Task**: 153 (bugfix)

## Task Reference
- **Task ID**: internal-153
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/153-move-perl5opt-to-project-local-settings
- **Template Version**: 2.1

## Goal
Concrete edit list to implement the design: `merge_env` in `cwf-claude-settings-merge`, retargeted docs/warning, hash refresh, dogfood commit.

## Files to Modify
1. **`.cwf/scripts/command-helpers/cwf-claude-settings-merge`** (HASHED) — add `merge_env`; broaden header comment (lines 3–12) and `usage()` (24–28); call `merge_env` in main; extend summary + dry-run lines (187, 192).
2. **`.cwf/lib/CWF/Common.pm`** (HASHED) — retarget `check_perl5opt` warning (the `~/.claude/settings.json` string is line 22; warning block 21–23) and POD (settings.json mention line 149) to project `.claude/settings.json`, without over-promising the bare-shell case. (Re-grep exact `old_string` at edit time — line offsets are advisory.)
   - **`t/common.t`** — `check_perl5opt` subtests (lines 18–45) assert warn/no-warn **count only**, not message text, so the retarget needs **no test edit**. Confirm this at edit time; do not over-edit.
3. **`.claude/skills/cwf-init/SKILL.md`** — retire step 7 (lines 141–154, incl. the `grep -q 'PERL5OPT' ~/.claude/settings.json` pre-check); update step-6 cross-note (line 80); update success criterion (line 180). Step 8 `git add` (line 159) already includes `.claude/settings.json` — **no change needed**, confirm only.
4. **`INSTALL.md`** — retarget **both** surfaces: Post-Install step 3 (lines 254–269) and Troubleshooting (line 316), to project `.claude/settings.json`; add a one-line migration note (project value overrides any leftover global; removal optional).
5. **`docs/conventions/perl.md`** — lines 20–21: `~/.claude/settings.json` → project `.claude/settings.json`.

## Supporting Changes
- **`.cwf/security/script-hashes.json`** (HASHED-FILE REFRESH) — refresh `sha256` for `cwf-claude-settings-merge` and `CWF::Common` in this same commit (per `.cwf/docs/conventions/hash-updates.md`). Plan-time grep confirms these two are the only hashed paths in the Files-to-Modify list (`cwf-manage` is deliberately untouched; SKILL.md / INSTALL.md / perl.md are not hashed).
- **`.claude/settings.json`** (this repo, currently untracked) — commit env-only file (dogfood, Decision 8) after the commit-time env-only guard.
- **`BACKLOG.md`** — add a Low follow-up: single-source-of-truth for the canonical `-CDSLA` value (Decision 7), currently duplicated across INSTALL.md, perl.md, SKILL.md, Common.pm, and the new helper constant.

## Implementation Steps

### Step 1 — `merge_env` in `cwf-claude-settings-merge`
Add a canonical constant and a single-key merge function (not a list-merger). Mirror the `ref(...)` defensiveness of `merge_hooks`:

```perl
my $CANONICAL_PERL5OPT = '-CDSLA';

# Merge env.PERL5OPT into project settings: add-if-absent, warn-on-mismatch.
# Single key, constant value — direct check, not a list merge.
# Returns 1 if the key was added, 0 otherwise. Warnings fire regardless of
# --dry-run (dry-run is how a user previews drift before an update).
sub merge_env {
    my ($settings) = @_;
    my $env = $settings->{env};

    if (defined $env && ref($env) ne 'HASH') {
        warn "[CWF] WARN: .claude/settings.json 'env' is present but not an object; leaving it untouched\n";
        return 0;
    }
    $settings->{env} = $env = {} unless defined $env;

    my $cur = $env->{PERL5OPT};
    if (!defined $cur) {
        $env->{PERL5OPT} = $CANONICAL_PERL5OPT;
        return 1;
    }
    if (ref($cur) ne '') {
        warn "[CWF] WARN: .claude/settings.json env.PERL5OPT is present but not a string; leaving it untouched\n";
        return 0;
    }
    if ($cur ne $CANONICAL_PERL5OPT) {
        warn "[CWF] WARN: .claude/settings.json env.PERL5OPT is \"$cur\"; CWF expects \"$CANONICAL_PERL5OPT\". Leaving the existing value untouched.\n";
    }
    return 0;
}
```

Wire into main (after `merge_hooks`):
```perl
my $env_added = merge_env($settings);
```
Extend both report lines:
- dry-run (≈187): `... $hook_added hook entries, $env_added env keys (dry-run)\n`
- write   (≈192): `... $hook_added hook entries, $env_added env keys\n`

Broaden header comment (3–12) and `usage()` (24–28): "Register CWF Bash allowlist, Stop hooks, and required env vars (`PERL5OPT`) in `.claude/settings.json`."

**Security note (FR4(e))**: the written value MUST stay a compile-time constant. `.claude/settings.json` `env` is applied to every tool-call environment with no trust-gate, so any future change that writes a non-constant or externally-sourced value through `merge_env` would put attacker-influenceable data on the tool-call env path. Keep `$CANONICAL_PERL5OPT` a literal; add a one-line comment by the constant saying so.

### Step 2 — retarget `check_perl5opt` (`CWF::Common`)
Replace the warning body (lines 21–23) with project-settings guidance that does not over-promise the bare-shell case, e.g.:
```
WARNING: PERL5OPT lacks the -C flags needed for Unicode handling.
CWF installs env.PERL5OPT=-CDSLA into this project's .claude/settings.json
(run 'cwf-manage update' if it is missing, then restart Claude Code so the
session picks it up). Note: a script run outside a Claude Code tool call
won't inherit that setting — export PERL5OPT=-CDSLA in your shell for
those cases.
```
Update the POD (148–149) to match (project settings.json, not `~/.claude/settings.json`).

### Step 3 — `/cwf-init` SKILL.md
- Replace step 7 (141–154) with a short note: PERL5OPT is installed automatically by step 6d (`cwf-claude-settings-merge`) into project `.claude/settings.json` and committed by step 8 — no user action, no `~/.claude/settings.json` edit, and remove the `grep -q ... ~/.claude/settings.json` pre-check.
- Line 80 cross-note: drop "not the global `~/.claude/settings.json` used for PERL5OPT in step 7" (step 7 no longer edits the global file).
- Line 180 success criterion: reword to "PERL5OPT merged into project `.claude/settings.json` via `cwf-claude-settings-merge`".
- Confirm line 159 `git add` already lists `.claude/settings.json` (no edit).

### Step 4 — INSTALL.md
- Step 3 (254–269): retarget to project `.claude/settings.json`; note CWF writes it automatically during install (`cwf-init`) and `cwf-manage update`; add migration line: a leftover `~/.claude/settings.json` value is harmless because the project value overrides it; removal optional.
- Line 316 (Troubleshooting): retarget to project `.claude/settings.json`.

### Step 5 — perl.md
Lines 20–21: "Configured in your project's `.claude/settings.json` under `"env"` (installed automatically by CWF), or your shell's startup file for non-tool-call invocations."

### Step 6 — Hash refresh (same commit)
Per `.cwf/docs/conventions/hash-updates.md`, for each of `cwf-claude-settings-merge` and `.cwf/lib/CWF/Common.pm`:
1. Pre-refresh verify: `git log --oneline <last-hash-set-commit>..HEAD -- <path>` — confirm intervening commits are this task's known edits (per file, not assumed-shared).
2. `sha256sum <path>` → new digest.
3. Edit the matching `sha256` entry in `.cwf/security/script-hashes.json`.

### Step 7 — Dogfood commit of repo `.claude/settings.json`
**Pollution is the likely state, not the exception**: once Step 1 lands, running the helper locally (or any `cwf-claude-settings-merge` invocation) writes `permissions`/`hooks` into the working-tree `.claude/settings.json` alongside `env`. So do not `git add` the working-tree file blindly. Concrete re-derivation: write a fresh env-only file `{"env":{"PERL5OPT":"-CDSLA"}}` (via the Write tool to a scratch path, then move into place, or stage explicitly), `git add .claude/settings.json`, and confirm the **staged** content is env-only:
```bash
git show :.claude/settings.json   # must print only the env object — no permissions/hooks
```
The working tree may keep the polluted (gitignored-intent) version; only the staged blob must be env-only. (This repo keeps machine-specific allowlist/hooks in gitignored `settings.local.json`, so an env-only tracked `settings.json` is the intended end state.)

### Step 8 — Verification (closing grep, repo-wide)
Run repo-wide with explicit exclusions rather than a fixed file list, so it proves "no survivor anywhere" and stays self-maintaining:
```bash
git grep -nE '~/\.claude/settings\.json' -- ':!implementation-guide/' ':!CHANGELOG.md'
```
Must return **no PERL5OPT-related hits** (any survivor re-introduces the bug). `CHANGELOG.md` is excluded deliberately — its `~/.claude/settings.json` mentions are immutable history (BACKLOG/CHANGELOG carve-out), correctly left untouched. Then `cwf-manage validate` clean (modulo the pre-existing, unrelated `cwf-plan-reviewer-misalignment.md` permission drift tracked in BACKLOG).

## Test Coverage
Authoritative test list lives here until `e-testing-plan.md` is written in the next phase (that file is currently the unedited template — the cross-reference is not yet load-bearing). Core:
- **Extend the existing `t/cwf-claude-settings-merge.t`** (reuse its `build_fixture` tempdir harness — do **not** create a new test file) with `merge_env` cases: absent→adds; equal→no-op (added=0); mismatch→warn + value untouched; non-hash `env`→warn + untouched; non-scalar `PERL5OPT`→warn + untouched; sibling `env` keys preserved.
- End-to-end: run the helper against a temp settings.json and assert `env.PERL5OPT` present and report line shows the env count.
- `t/common.t` `check_perl5opt` subtests assert behaviour (warn count), not text — **no edit expected**; confirm green after the message retarget.
- Closing repo-wide grep (Step 8).

## Validation Criteria
- [ ] `merge_env` covers all four branches with the type guard.
- [ ] Both report lines and the header/usage text updated.
- [ ] Hash entries refreshed in-commit; `cwf-manage validate` clean.
- [ ] Closing grep finds no surviving `~/.claude/settings.json` PERL5OPT references.
- [ ] Repo `.claude/settings.json` committed env-only.

## Decomposition Check
- [ ] Time >1 week? No. People >2? No. Complexity 3+ concerns? No. Risk isolation? No. Independence? No.

**Verdict**: No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Implementation plan complete. 4 plan-review subagents, findings folded in: Common.pm line anchors corrected + `t/common.t` no-edit note (misalignment); extend existing `t/cwf-claude-settings-merge.t` not a new file (misalignment); `check_perl5opt` message gains a restart note (robustness); Step 7 dogfood guard given concrete env-only re-derivation + staged-blob check (robustness/security); Step 8 grep made repo-wide with exclusions (improvements); FR4(e) constant-only audit note on `merge_env` (security). No new implementation steps added.

## Lessons Learned
Implementation-review corrections (line-anchor accuracy, extend-the-existing-test, env-only re-derivation, repo-wide grep) all proved worthwhile at exec time. Full learnings in `j-retrospective.md`.
