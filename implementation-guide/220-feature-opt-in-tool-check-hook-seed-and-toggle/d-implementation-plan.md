# opt-in tool-check hook seed and toggle - Implementation Plan
**Task**: 220 (feature)

## Task Reference
- **Task ID**: internal-220
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/220-opt-in-tool-check-hook-seed-and-toggle
- **Template Version**: 2.1

## Goal
Implement opt-in tool-check hook seed and toggle following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes (hash-tracked → refresh in same commit)
- `.cwf/lib/CWF/ToolCheck.pm` — add `use JSON::PP ();` (core; needed for `is_bool` where it
  is used, not by caller luck). Add pure `resolve_active(\@trusted_decoded_high_to_low)` and
  `merge_seed(\@existing, \@starter)`; add both to `@EXPORT_OK`. Refresh sha256.
- `.cwf/scripts/hooks/pretooluse-bash-tool-check` — `load_merged` returns decoded layer
  objects alongside merged rules (single read pass); hot path gains
  `return unless resolve_active(...)` after `return unless @$merged`; `run_check` gains an
  "Effective active" line + per-layer `active`. Import `resolve_active`. Refresh sha256.
- `.cwf/scripts/command-helpers/tool-check-seed` — **NEW** helper (`on|off|seed`).
  Embeds the regex-only starter ruleset; symlink-safe dir creation (per-level `-d && !-l`)
  + atomic preserving RMW (temp+`O_EXCL`+`rename`, 0600); rejects unknown subcommand
  (non-zero, no write); echoes state via `resolve_active`. **Add a `0500` entry to
  `.cwf/security/script-hashes.json`** (shape: `path`/`permissions`/`sha256`, sha256 via
  `sha256sum`) in the same commit.

### Supporting Changes (not hash-tracked)
- `.claude/skills/cwf-config/SKILL.md` — parse `tool-check <on|off|seed>` → dispatch to the
  new helper; retain `init|list|reset`.
- `.claude/skills/cwf-init/SKILL.md` — new opt-in confirm step (after 6d, before the step-8
  commit; default **decline**) → on accept run `tool-check-seed seed`.
- `.gitignore` — **reconcile via `cwf-apply-artefacts`** (idempotent, dedupes against
  existing lines), **not** by hand-editing. The only missing manifest line is
  `.cwf/tool-check/*/settings.local.json` (`install-manifest.json:14` already declares it;
  `.cwf/.update.lock` is **already** present at `.gitignore:8` — do not re-add). The
  manifest needs **no** change — this **supersedes design DK3's "add to the manifest"
  wording** (stale; the glob is already there). **This ignore entry is a security control**,
  not cosmetic: the project-local layer honours `perl` rules, so keeping
  `settings.local.json` out of `git` is the sole guard against a committed project-local
  `perl` rule executing on every cloner (the clone-untrusted-execution hazard the
  checked-in `perl` drop also prevents).
- `.cwf/docs/tool-check-rules.md` — document `active`, its trusted-layer precedence
  (checked-in ignored), default-true, the seed, the toggle surface, **and** the
  security rationale for gitignoring `settings.local.json`.
- `BACKLOG.md` — correct the Task-219 R3 entry (strike "not shipped / this-repo-only";
  note the corpus predates the Jul-6 user-global ruleset; re-scope to seed+toggle+lint).
- Tests — see Test Coverage.

<!-- No named symbols are deleted. -->

## Implementation Steps
### Step 1: Setup
- [ ] Branch already checked out; re-read c-design DK1–DK5 + the reviewer-driven edits.

### Step 2: Pure policy first (`CWF::ToolCheck.pm`) + unit tests
- [ ] Add `use JSON::PP ();`.
- [ ] Add `resolve_active(\@trusted_decoded_high_to_low)`: walk high→low; a layer "defines"
      `active` iff the value **is a JSON boolean** (`JSON::PP::is_bool`); skip
      undef/error/non-boolean; default `1`.
- [ ] Add `merge_seed(\@existing, \@starter)`: append starter ids absent from `@existing`;
      never overwrite; return `(\@merged, $added, $skipped)`. **Rules-only** — the caller is
      responsible for preserving other top-level settings keys (see Step 4).
- [ ] Extend `t/tool-check.t`: boolean-only coercion (`"false"`/`0`/`null` ignored, real
      `false` honoured), high→low precedence, default-true, `merge_seed` no-clobber + counts.

### Step 3: Hook hot-path + `--check` (`pretooluse-bash-tool-check`)
- [ ] `load_merged` returns the per-layer decoded objects in its existing low→high order
      (no second stat/read — NFR1).
- [ ] Define the **`trusted_layers`** transform (inline or a small named hook sub): from the
      low→high decoded list `[user-global, checked-in, project-local]`, select and reverse to
      **`[project-local, user-global]`** — **checked-in excluded** (DK1, security-load-bearing).
- [ ] Insert `return unless resolve_active(trusted_layers(...))` **after**
      `return unless @$merged` and **before** the compile/match loop.
- [ ] `run_check`: derive its "Effective active" line through the **same** `resolve_active` +
      `trusted_layers` filter (no divergence from the hot path); also print per-layer `active`.
- [ ] Extend `t/pretooluse-bash-tool-check.t`: active-off allows a would-deny cmd; absent/
      malformed/symlinked flag fail-open; **true trusted-precedence — project-local
      `active:false` overrides a user-global `active:true`** (checked-in `active` ignored).

### Step 4: The `tool-check-seed` helper + tests
- [ ] Starter set: **regex-only, sourced from the documented anti-pattern corpus**
      (`.cwf/docs/skills/cwf-agent-shared-rules.md` anti-patterns table + the
      `feedback_no_*` MEMORY entries / `tool-check-rules.md` examples) — do **not** invent
      fresh patterns.
- [ ] Write the helper: `seed` (checked-in preserving RMW, **then** clear project-local
      `active:false`), `on`/`off` (project-local preserving RMW). The preserving RMW **reads
      the existing file symlink-safely** (`-f && !-l`, mirror `read_layer_file`) and
      **writes back all pre-existing top-level keys** (incl. a checked-in `active`), changing
      only rules / the `active` key. Unknown subcommand → non-zero + usage, no write.
      Symlink-safe per-level dir creation + atomic temp+`O_EXCL`+`rename` (0600). **Check
      every syscall/exit status** (`sysopen`/`rename`/`close`, and `sha256sum`) — no
      best-effort. Inline state echo via `resolve_active`.
- [ ] New `t/tool-check-seed.t`: seed idempotent; re-seed preserves a user-edited id
      (no-clobber + skip report); **seed preserves an unrelated pre-existing top-level key**;
      on/off idempotent; `git check-ignore .cwf/tool-check/bash/settings.local.json` asserts
      ignored (the security control); symlinked target/dir not written through; unknown
      subcommand exits non-zero.
- [ ] Add the `0500` hash entry for the helper to `script-hashes.json`.

### Step 5: Skill wiring + gitignore + docs + backlog
- [ ] `/cwf-config` `tool-check` dispatch; `/cwf-init` opt-in confirm step.
- [ ] Reconcile `.gitignore` by running `cwf-apply-artefacts` (adds only the missing
      tool-check glob; verify the diff is that one line). Update `tool-check-rules.md`
      (incl. the security rationale); correct the R3 backlog entry.

### Step 6: Validation
- [ ] `prove t/tool-check.t t/pretooluse-bash-tool-check.t t/tool-check-seed.t` green;
      full `prove t/` no regressions.
- [ ] Refresh sha256 for `ToolCheck.pm` + the hook; confirm `cwf-manage validate` OK.
- [ ] Manual smoke: `tool-check-seed seed` then `--check` shows active + rules; `off` silences.

## Code Changes
### Settings schema (extended, backward-compatible)
```jsonc
// Before: { "rules": [ ... ] }
// After:  { "active": true|false /* JSON bool only, optional */, "rules": [ ... ] }
```

### Hook hot path (insertion point)
```perl
# Before (pretooluse-bash-tool-check, run_hook):
my ($merged)  = load_merged($root);
return unless @$merged;                       # no rules -> strict no-op

# After:
my ($merged, $notes, $decoded) = load_merged($root);   # $decoded low->high, same read pass
return unless @$merged;                                # no rules -> strict no-op
# trusted_layers: [project-local, user-global] high->low, checked-in EXCLUDED (DK1)
return unless resolve_active(trusted_layers($decoded));# kill-switch, before compile/match
```

## Test Coverage
**See e-testing-plan.md for complete test plan** — unit (`resolve_active`, `merge_seed`),
hook integration (active flag, fail-open, precedence), and helper (`on|off|seed`, symlink
safety, idempotency, no-clobber, unknown-subcommand).

## Validation Criteria
**See e-testing-plan.md** — every AC1–AC9 mapped to a test; `cwf-manage validate` OK with
same-commit hash refresh.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Decomposition Check
Unchanged: 1 borderline signal (complexity) — sequenced pure-lib → hook → helper → wiring,
each with its own tests. **Do not decompose.**

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned steps executed with no deferrals (see f-implementation-exec.md). The
manifest already declared the gitignore glob, so the planned manifest edit (DK3) was a
no-op — `cwf-apply-artefacts` reconciled the single line.

## Lessons Learned
`eval` cannot trap an `exit` — a helper that fails via `exit 1` inside `eval` is
uncatchable; the fix is an explicit soft-return mode, not a wider `eval`. Verify the
error-propagation contract of a called helper before wrapping it.
