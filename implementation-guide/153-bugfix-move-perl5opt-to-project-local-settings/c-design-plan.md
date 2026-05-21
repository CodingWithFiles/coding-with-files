# move PERL5OPT to project-local settings - Design
**Task**: 153 (bugfix)

## Task Reference
- **Task ID**: internal-153
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/153-move-perl5opt-to-project-local-settings
- **Template Version**: 2.1

## Goal
Decide *how* `env.PERL5OPT=-CDSLA` becomes a project-scoped, auto-installed setting, and which surfaces change.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Background (verified this task)
- Claude Code settings precedence (highest→lowest): managed → CLI → `.claude/settings.local.json` → `.claude/settings.json` → `~/.claude/settings.json`. The first scope defining a key wins; project `.claude/settings.json` overrides user `~/.claude/settings.json`.
- `env` in a project `.claude/settings.json` **is** applied to tool calls and has no trust-gate prompt (unlike hooks).
- `cwf-claude-settings-merge` is already the sole CWF writer of project `.claude/settings.json` (Bash allowlist + Stop hooks). It is invoked by `/cwf-init` step 6d **and** by `cwf-manage update` via `run_settings_merge`. Both paths therefore get any new merge behaviour for free.
- Hash-tracked (refresh required if edited): `cwf-claude-settings-merge`, `.cwf/lib/CWF/Common.pm`, `.cwf/scripts/cwf-manage`.

## Key Decisions

### Decision 1 — Mechanism: extend `cwf-claude-settings-merge` to merge `env.PERL5OPT`
- **Decision**: Add an `env.PERL5OPT` merge step to `cwf-claude-settings-merge`, alongside the existing allowlist/hooks merges. The canonical value `-CDSLA` is a constant in the helper.
- **Rationale**: It is already the one writer of project `.claude/settings.json`, and is already on both the install and update paths. No new helper, no `cwf-manage` edit, no new wiring. Maximises reuse, minimises new code and hash-tracked surface.
- **Trade-offs**: Slightly broadens the helper's stated purpose (allowlist/hooks → "CWF-required project settings"). Mitigated by updating its header comment + `usage()` text. Rejected alternative: a separate `cwf-perl5opt-install` helper — more code, second invocation site to wire into init *and* update, more hash entries. Rejected alternative: keep it purely a doc-target swap (instruct editing project settings by hand) — fails the "install/cwf-manage handle it" intent and leaves a manual step.

### Decision 2 — Merge semantics: add-if-absent, warn-on-mismatch
- **Decision**: If `env.PERL5OPT` is absent, set it to `-CDSLA`. If present and equal, no-op. If present and **different**, leave the existing value untouched and emit `[CWF] WARN: .claude/settings.json env.PERL5OPT is "<val>"; CWF expects "-CDSLA"` on stderr.
- **Rationale**: Idempotent (re-runs add nothing). Preserves a deliberate user override. Surfaces drift rather than silently rewriting — consistent with the project's "surface, never smooth" rule and the existing `[CWF] WARN:`-tolerated convention in this helper (manifest-entry-missing path). Add-only matches how `merge_allow`/`merge_hooks` already behave (never remove/replace existing entries).
- **Trade-offs**: A stale `-CDSL` is not auto-upgraded — but it is now visible via the warning, and the user can fix it. Auto-rewriting would risk `Too late for -CDSLA` surprises for someone who set `-CDSL` on purpose.
- **`--dry-run`**: the mismatch warning MUST fire under `--dry-run` too (dry-run is the natural way to preview drift before an update). Do not gate the warning behind the write path the way the summary line is gated (robustness review F1).

### Decision 3 — Preserve `env` siblings; never replace the `env` object; guard non-hash/non-scalar
- **Decision**: Merge only the `PERL5OPT` key into `settings->{env}` (create `env` if absent). Do not touch other `env` keys. **Type guard** (mirroring the `ref(...)` checks in `merge_hooks`): if `env` is present but not a HASH ref, or `env.PERL5OPT` is present but not a plain scalar string, take the warn path (surface, do not coerce or crash) and leave the file's `env` untouched.
- **Rationale**: Mirrors `merge_allow`/`merge_hooks` key-preserving, defensively-typed behaviour. A user's other project `env` vars must survive; a malformed `env` must not crash the merge or get silently rewritten (robustness review F2).

### Decision 4 — `/cwf-init` step 7 retired, not retargeted
- **Decision**: Replace step 7's "tell the user to edit `~/.claude/settings.json`" with a short note that `env.PERL5OPT` is installed automatically by step 6d's `cwf-claude-settings-merge` and committed by step 8 — no user action. Update the step-6 cross-note (line ~80) and the success-criteria line (~180) to match.
- **Rationale**: With auto-merge, the manual step is redundant; leaving a manual `~/.claude/settings.json` instruction would re-introduce the global-scope bug it set out to fix.

### Decision 5 — `cwf-manage` unchanged
- **Decision**: No edit to `.cwf/scripts/cwf-manage`.
- **Rationale**: `cmd_update` already calls `run_settings_merge` → `cwf-claude-settings-merge`. The new behaviour rides the existing call. Keeps a hash-tracked entry-point out of the changeset (less risk, fewer hash refreshes).

### Decision 6 — `check_perl5opt` warning retargeted, behaviour unchanged
- **Decision**: `CWF::Common::check_perl5opt` still only warns when `$ENV{PERL5OPT}` lacks `-C`, but the message now points at the project `.claude/settings.json`. Wording must not over-promise: the warning fires on the *ambient process env*, which Claude Code populates from settings for tool calls but which is empty for a bare-shell/cron/hook invocation. So the message should say PERL5OPT belongs in project `.claude/settings.json` (run `cwf-manage update` if absent) **and** note that a script run outside a Claude tool call won't inherit it — rather than implying re-running `/cwf-init` fixes a bare shell.
- **Rationale**: Runtime guidance should match the new install location without misleading the bare-shell case. Behaviour (warn-only, never fix) is unchanged — the auto-merge is the fix path (robustness review F4).

### Decision 7 — Canonical-value duplication left as-is (out of scope)
- **Decision**: `-CDSLA` remains a literal in several docs plus the new helper constant. Do not build a single-source-of-truth mechanism this task.
- **Rationale**: Scope discipline — the bug is *location*, not *deduplication*. A "single source for the canonical PERL5OPT value" is a separate, pre-existing concern; note it as a BACKLOG follow-up rather than expand this task.

### Decision 8 — Dogfood: commit this repo's own `.claude/settings.json`
- **Decision**: This CWF dev repo currently has an **untracked** `.claude/settings.json` containing `{"env":{"PERL5OPT":"-CDSLA"}}`. Commit it (env key only) as part of this task so the repo dogfoods its own fix.
- **Rationale**: The repo develops CWF using CWF; the fix says PERL5OPT belongs in committed project settings. Committing the env-only file is harmless (the maintainer's Bash allowlist/hooks live in gitignored `settings.local.json`) and demonstrates the end state.
- **Confirmed** by the maintainer during design review: commit this repo's `.claude/settings.json` (env key) as part of this task.
- **Commit-time guard** (security review): before `git add`, verify the tracked file contains *only* the `env` key (no `permissions`/`hooks`). If the merge helper or a local edit has injected allowlist/hook entries, those are machine-specific and must not be committed — re-derive an env-only file for the commit.

## System Design

### Component Overview
- **`cwf-claude-settings-merge`** (modified): gains `merge_env($settings)` returning count added; reports it in the summary line and `--dry-run` output. Canonical constant `PERL5OPT => -CDSLA`.
- **`CWF::Common::check_perl5opt`** (modified): warning text retargeted.
- **Docs** (modified): `INSTALL.md`, `.claude/skills/cwf-init/SKILL.md`, `docs/conventions/perl.md`.
- **`.cwf/security/script-hashes.json`** (modified): refreshed entries for the two hash-tracked code files.

### Data Flow (install)
1. `/cwf-init` step 6d runs `cwf-claude-settings-merge`.
2. Helper reads project `.claude/settings.json` (or `{}`), merges allowlist + hooks + `env.PERL5OPT`, atomically writes.
3. `/cwf-init` step 8 `git add .claude/settings.json` + commit.

### Data Flow (update)
1. `cwf-manage update` → `run_settings_merge` → same helper → same merge → atomic write. User commits as part of their update.

## Interface Design
`merge_env(\%settings) -> $added` (0 or 1), parallel to `merge_allow`/`merge_hooks`. Unlike those (which loop a list of entries), `merge_env` handles exactly one key with a constant value — implement it as a direct `exists`/type/equality three-way branch, not a generalised list-merger (improvements review: avoid premature abstraction for one key). Summary line extended: `[CWF] settings: added N allowlist entries, M hook entries, P env keys`. `--dry-run` reports the same counts (and still fires the mismatch warning per Decision 2). `merge_env` runs *after* `read_settings`, so it inherits that function's symlink guard (lines 95-109) and JSON-parse-or-die (line 117) — no new read/write path, no redundant error handling (robustness review F3 / security review).

## Constraints
- Hash refresh in-commit for `cwf-claude-settings-merge` + `Common.pm`.
- Core Perl only; `use utf8;`; `#!/usr/bin/env perl` (helper already conforms).
- `atomic_write_text` / `validate_write_path_allowlist` reused as-is.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2? No.
- [ ] **Complexity**: 3+ concerns? No.
- [ ] **Risk**: isolation needed? No.
- [ ] **Independence**: separable parts? No.

**Verdict**: No decomposition.

## Validation
- [x] Design review (plan-review subagents) completed — 4 reviewers; no design-soundness defects; refinements folded into Decisions 2/3/6/8 + Interface; surface-inventory findings carried to the implementation plan.
- [ ] User plan review before exec (per request).
- [x] Integration points verified: both `/cwf-init` step 6d and `cwf-manage update` (`run_settings_merge`, cwf-manage:393) reach the merge helper.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design complete; plan-review subagent findings folded in (see Lessons Learned).

## Lessons Learned
Verifying the load-bearing premise (project `env` overrides user `env`, no trust-gate) against Claude Code's docs before design de-risked the whole task. Reviewers confirmed the mechanism and surfaced the dry-run-warn, type-guard, and message-scope refinements. Full learnings in `j-retrospective.md`.
