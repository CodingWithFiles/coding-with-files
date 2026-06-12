# cwf-init dead UserPromptSubmit hook matcher - Design
**Task**: 195 (bugfix)

## Task Reference
- **Task ID**: internal-195
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/195-cwf-init-dead-userpromptsubmit-hook-matcher
- **Template Version**: 2.1

## Goal
Define how `/cwf-init` registers the rules-inject re-injection hook as a working
`UserPromptSubmit` event, with the correct shape, idempotently, and how the dead
`PreToolUse`/`UserPromptSubmit` entry on existing installs is migrated away.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Verified Facts (measure twice)
1. **Correct hook shape — the backlog's proposed shape is WRONG.** Per the Claude Code
   hooks docs (https://code.claude.com/docs/en/hooks), the three-level nesting is
   **universal across all events**, including matcher-less ones. `UserPromptSubmit`
   ignores `matcher` but still uses the group-wrapper `{ "hooks": [...] }`:
   ```json
   "UserPromptSubmit": [
     { "hooks": [ { "type": "command", "command": "cat .cwf/rules-inject.txt 2>/dev/null || true" } ] }
   ]
   ```
   The backlog's flat form `"UserPromptSubmit": [ { "type": ..., "command": ... } ]`
   is **not** valid — adopting it would replace a dead hook with a malformed one.
2. **The merge helper already emits exactly this shape.** `cwf-claude-settings-merge`'s
   `merge_hooks` + `find_or_make_group` with `matcher = undef` produces
   `"<event>": [ { "hooks": [ ... ] } ]` — the correct group-wrapper form. It buckets
   by arbitrary event string and dedupes commands per-event. It already injects a fixed
   non-manifest value (`env.PERL5OPT` constant) — precedent for a fixed CWF hook.
3. **Migration is safe to scope by matcher.** CWF's own `PreToolUse` hooks use matchers
   `Edit|Write` (planning-write-guard) and `Bash` (sandbox-logging) — never
   `UserPromptSubmit`. Removing exactly the `PreToolUse` group whose
   `matcher == "UserPromptSubmit"` strips the dead entry and nothing else.
4. **Tests** live at `t/cwf-claude-settings-merge.t`. The helper is security-hashed:
   any edit requires a `script-hashes.json` refresh in the same commit ([[hash-updates]]).

## Key Decisions
### D1. Where the fix lives: deterministic helper, not prose (RECOMMENDED — flag for review)
- **Decision**: Move rules-inject hook registration **and** the dead-entry migration
  into `cwf-claude-settings-merge` (step 6d). Reduce `/cwf-init` step 6c to a short note
  that 6d now owns the hook; delete its hand-written JSON block and idempotency prose.
- **Rationale**:
  - The root cause is *prose-driven JSON manipulation by the model* — that is precisely
    what produced the wrong shape. A prose fix leaves that recurrence risk and makes the
    migration (surgical, matcher-scoped JSON surgery) equally prose-driven and fragile.
  - The helper already produces the correct shape (Fact 2) with idempotent dedupe and a
    fixed-constant-injection precedent (`PERL5OPT`). The added logic is small.
  - Aligns with project conventions: bake mandatory work into scripts ([[feedback_bake_in_good_work]]),
    determinism over model judgement, testable via the existing `.t` harness.
- **Trade-offs**: Touches a security-hashed helper (hash refresh + tests required) and
  marginally broadens its contract from "derive from manifest" to "derive from manifest
  + one fixed CWF hook". Higher blast radius than a one-line prose edit, but removes the
  bug class rather than this one instance.
- **Considered alternative — Design A (prose-only)**: Fix step 6c's JSON to the correct
  group-wrapper shape and add prose telling the model to detect+remove the dead
  `PreToolUse`/`UserPromptSubmit` group. Smaller diff, no hashed-script change. Rejected
  as primary: leaves the recurrence risk, and a model-executed migration over arbitrary
  user settings is the fragile part. **Fallback if reviewers want minimal blast radius.**

### D2. Migration semantics (authoritative cleanup)
- **Decision**: On every run, before merging the desired hook, prune from
  `hooks.PreToolUse` any group whose `matcher eq "UserPromptSubmit"`; drop the
  `PreToolUse` key if it becomes empty. Mirrors `reconcile_sandbox`'s
  remove-then-rewrite, grep-filter pattern.
- **Rationale**: Authoritative reconciliation makes the run idempotent and converges any
  install (fresh, dead-entry, already-fixed) to the same correct state. Matcher-scoped
  removal preserves all user- and CWF-authored `PreToolUse` groups (Fact 3).
- **Trade-offs**: A user who *intentionally* created a `PreToolUse` matcher literally
  named `UserPromptSubmit` (a no-op) would lose it — acceptable, as that entry can never
  fire by construction.

### D3. Hook command + idempotency key
- **Decision**: Command string stays byte-identical: `cat .cwf/rules-inject.txt 2>/dev/null || true`,
  defined as a compile-time constant alongside `$CANONICAL_PERL5OPT`. Per-event command
  dedupe in `merge_hooks` already prevents duplicate registration on re-run.
- **Rationale**: Reuses existing idempotency machinery; no new dedupe logic.

### D4. Event-allowlist consistency (RESOLVED: keep in this task, user 2026-06-12)
- **Decision**: Widen the `read_hook_directives` event allowlist (helper line 106,
  `/^(?:Stop|SubagentStop|PreToolUse)$/`) to also admit `UserPromptSubmit`, and update the
  header-comment + `usage()` enumerations to match. The synthetic rules-inject entry is
  injected *after* `partition_manifest` and so does not itself pass through
  `read_hook_directives` — but leaving the allowlist as-is sets a trap: a future hook file
  that legitimately requests `# cwf-hook-event: UserPromptSubmit` would be silently
  downgraded to `Stop`.
- **Rationale**: Consistency (a stated design priority) and trap-removal for one-line cost.
  `merge_hooks` already buckets by arbitrary event string, so this only aligns the
  directive validator with what the merge layer already supports.
- **Trade-off**: Slightly widens what a hook-header directive can request; the value is
  still an inert, anchored string copied into a settings key, never executed.

### D5. Keep-and-fix vs prune-only (RESOLVED: keep-and-fix, user 2026-06-12)
- **Context**: This repo's own `.claude/settings.json` has **no `hooks` key at all** — CWF
  the project does not currently run with a rules-inject hook. A reviewer asked whether the
  hook is worth keeping, since prune-only (delete the dead entry + delete step 6c, never
  re-register) is strictly fewer moving parts.
- **Recommendation**: **Keep and fix.** The rules-inject hook is a deliberate feature
  (Task 99): re-inject CWF rules into context on each user prompt to counter rule-loss over
  long/compacted sessions — the same concern session-hygiene.md codifies. It has never
  worked because it was always registered under the wrong key; the right fix is to make the
  intended feature work, not to delete an un-exercised feature. Prune-only is the documented
  fallback if the maintainer judges the feature unwanted.

## System Design
### Component Overview
- **`cwf-claude-settings-merge` (step 6d helper)**: Gains (a) a fixed
  `UserPromptSubmit` rules-inject hook entry injected into `$hook_entries` before
  `merge_hooks`; (b) a `prune_dead_userpromptsubmit_matcher($settings)` cleanup run before
  the merge; (c) `UserPromptSubmit` added to the `read_hook_directives` event allowlist
  (D4); (d) refreshed header-comment + `usage()` text reflecting the fixed hook. No change
  to allowlist/env/sandbox paths.
- **`/cwf-init` SKILL.md step 6c**: Collapses to a one-line pointer to 6d; JSON block and
  PreToolUse idempotency prose removed. The "step 6b before hook step" hard-ordering note
  (rules-inject.txt must be in place before the hook is registered) is preserved — 6b
  already precedes 6d.

### Data Flow
1. `/cwf-init` runs step 6b (`cwf-apply-artefacts`) → the `.cwf/` subtree (which includes
   `rules-inject.txt`, copied via the install manifest) is in place before 6d.
2. `/cwf-init` runs step 6d (`cwf-claude-settings-merge`):
   a. Read settings → **prune** dead `PreToolUse`/`UserPromptSubmit` group (D2).
   b. Build hook entries from manifest **+ inject** the fixed `UserPromptSubmit`
      rules-inject entry (D1/D3).
   c. `merge_hooks` writes/keeps the correct group-wrapper `UserPromptSubmit` shape,
      deduped per-event.
3. Result: `.claude/settings.json` has a working top-level `UserPromptSubmit` hook and no
   dead `PreToolUse` matcher — on both fresh and previously-installed repos.

## Interface Design
No CLI/flag changes. `cwf-claude-settings-merge` keeps its `[--dry-run]` signature and
stdout summary. The summary's hook count is just `merge_hooks`'s existing return value (no
new per-entry accounting): it reflects the rules-inject entry on first add and is `0` on an
idempotent re-run. Internal additions only:
- Constant: `$CANONICAL_RULES_INJECT_CMD = 'cat .cwf/rules-inject.txt 2>/dev/null || true'`.
- Sub: `prune_dead_userpromptsubmit_matcher($settings)` → returns count pruned. Must be
  **defensive against hand-edited settings** (best-effort, never die), mirroring
  `merge_hooks`/`reconcile_sandbox`: tolerate `hooks` absent or non-hash, `PreToolUse`
  absent or not an array, individual groups not hashes, and `matcher` absent or non-scalar.
  Drop the `PreToolUse` key if it becomes empty after the filter.
- A synthetic hook entry `{ entry => { type=>'command', command=>$CANONICAL_RULES_INJECT_CMD },
  event => 'UserPromptSubmit', matcher => undef }` appended to `$hook_entries`. Injected
  post-`partition_manifest`, deliberately bypassing `read_hook_directives` (the entry is a
  trusted compile-time constant, not a parsed directive).
- **Known shape interaction (not a defect)**: `find_or_make_group($groups, undef)` returns
  `$groups->[0]`. If a downstream user already has a `UserPromptSubmit` group bearing a
  `matcher` at index 0, the rules-inject entry is appended into that group rather than a
  clean matcher-less one. The hook still fires (UserPromptSubmit ignores `matcher`) and
  cross-group command dedupe still prevents duplicates. Record, don't fix.

## Constraints
- Security-hashed helper: refresh `.cwf/security/script-hashes.json` in the same commit
  as the edit, with plan-time disclosure ([[hash-updates]]).
- Correct shape is the group-wrapper form (Verified Fact 1) — not the backlog's flat form.
- Migration must not touch any `PreToolUse` group whose matcher ≠ `UserPromptSubmit`.
- This repo's own `settings.json` has **no `hooks` key** — self-migration is a no-op here;
  the migration value is for downstream installs.

## Decomposition Check
- [ ] **Time / People / Complexity / Risk / Independence**: none triggered. One helper +
  one SKILL.md edit, one concern (hook shape + migration). No decomposition.

## Validation
- [x] Correct hook shape verified against Claude Code docs (group-wrapper, not flat)
- [x] Migration scope verified safe against CWF's own PreToolUse matchers
- [x] Reuse of existing `merge_hooks` machinery confirmed
- [x] Plan review (Step 8) completed — 4 reviewers; findings folded in (D4, defensive
      prune guards, doc-surface updates, factual corrections, shape-interaction note).
      Open item D5 (keep-and-fix vs prune-only) raised to user.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Both load-bearing design calls held through implementation: (1) move registration into the
deterministic `cwf-claude-settings-merge` helper — deleting the prose-driven JSON surgery
that was the bug's root cause; (2) the correct target shape is the three-level group-wrapper
even for `UserPromptSubmit`. D5 resolved keep-and-fix (register the working hook, not just
prune the dead one); D4 resolved keep-in-task (widen the event allowlist + TC-UPS8). No
design rework during exec.

## Lessons Learned
Design paid for itself on a "Low complexity" task by catching the backlog's wrong shape
before any code was written. Prefer a deterministic helper over SKILL.md prose for anything
shape-sensitive — converting model-built structured config into code emission is the durable
fix, not careful wording.
