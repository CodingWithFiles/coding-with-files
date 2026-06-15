# Resolve .cwf paths from project root, not cwd - Implementation Execution
**Task**: 204 (bugfix)

## Task Reference
- **Task ID**: internal-204
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/204-resolve-cwf-paths-from-project-root-not-cwd
- **Template Version**: 2.1

## Goal
Anchor each skill's cwd to the main repo root (surfaces 1+2) and re-link hook
registration to `${CLAUDE_PROJECT_DIR}/` (surface 3) so relative `.cwf/...`
resolves from any cwd, without breaking the permission allowlist.

## Phase 0 — Spike results (gate)
Ran the canonical idiom in this repo and a fixture worktree:
- **P0.1 PASS** — anchor at cwd==root raised no permission prompt. Mechanistic
  cause confirmed: the user-global `no-redundant-cd` tool-check only fires on a
  `cd` whose target it can *prove* equals cwd (`.`, `$PWD`, abspath==cwd); the
  anchor's `cd "$r"` targets a variable behind a `[ "$PWD" = "$r" ]` guard → never
  flagged.
- **P0.2 PASS** — from a subdir, a bare relative `.cwf/...` call fails exit 127;
  anchor-then-call succeeds. The live `cd "$r"` (cwd≠root) also raised no prompt.
- **P0.3 PASS** — `pretooluse-bash-tool-check` does not block the anchor.
- **P0.4 → A1 CORRECTED** — the Read tool resolves a relative `file_path` against
  the **shell cwd**, not the project root. Doc-reads therefore break too, but the
  **same anchor fixes them** (cwd persists; a relative Read succeeds after the
  anchor). Scope *narrowed* (one mechanism covers surfaces 1+2).
- **P0.5 PASS** — cwd persists across separate Bash tool calls.
- **P0.6 PASS** — the idiom run from a fixture **linked worktree** anchors to the
  **MAIN** root (verified via a throwaway fixture, honouring the no-raw-worktree
  convention). Mechanism is identical to `find_git_root()` (`--git-common-dir`,
  Task 173) — confirmed mechanically, empirically, and by design intent. Edge: the
  idiom's plain `dirname` does not replicate find_git_root's `--show-toplevel`
  submodule fallback; it matches the `tmp-paths.md` idiom and CWF-as-a-submodule
  is unsupported — acceptable.
- **P0.7** — `cwf-init`: the tolerant idiom no-ops pre-repo; same block, no special
  variant; anchored above its existing `**First**` line.

## Mid-exec discovery (folded in by user decision)
The spike surfaced **surface 3**: all hook commands in `.claude/settings.json`
were bare-relative `.cwf/scripts/hooks/...`, so from a non-root cwd the harness
could not locate them and the hook **failed open silently** (`PreToolUse:Bash hook
error … not found`, non-blocking). Two of these are gates
(`pretooluse-bash-tool-check`, `subagentstop-security-verdict-guard`) and one
injects the standing CWF rules. The anchor cannot fix this (hooks fire before the
command body). Per user decision the fix was **folded into Task 204**; design (c),
implementation (d), and testing (e) plans were amended and re-reviewed (round 2)
before this execution.

## Actual Results

### Step 2-3: Skill cwd anchor (surfaces 1+2)
- **Planned**: Insert the byte-identical anchor block at each skill's first Bash
  action — 17 skills above their `**First**: … context-manager location` line; 3
  (cwf-current-task, cwf-delete-task, cwf-backlog-manager) via a new first-action
  block above their per-subcommand examples. `test-cwf-skill` excluded.
- **Actual**: Done via an idempotent insertion helper for the 17; manual edits for
  the 3. **20 skills** carry exactly one anchor block; `test-cwf-skill` carries
  none. Pilot (cwf-status) verified rendering before rollout.
- **Deviations**: cwf-backlog-manager's anchor placed at the top of `## Context`
  (above the Helper-path prose) so it precedes the skill's first `.cwf/scripts/`
  use.

### Step 4: Hook registration (surface 3) — `cwf-claude-settings-merge`
- **Planned**: Emit hook commands with the literal `${CLAUDE_PROJECT_DIR}/` prefix;
  repoint `$CANONICAL_RULES_INJECT_CMD`; add a frozen `$LEGACY_RULES_INJECT_CMD`;
  add an anchored full-string, gate-state-independent prune
  (`prune_stale_relative_cwf_hooks`) over all 6 manifest hooks + legacy literal,
  called before `merge_hooks`, count surfaced; in-commit hash refresh.
- **Actual**: All done. The `$` is backslash-escaped in the emitter so Perl emits
  the literal token (an ordering bug — the prune referencing `$LEGACY` before its
  `my` declaration — was caught at first run and fixed by moving the constant above
  the function). Dry-run + real run on this repo: all 5 CWF hook commands prefixed,
  **"re-linked 5 stale relative CWF hook commands"**, `0` allowlist entries added,
  no duplicates, idempotent on re-run. Hook **allowlist** entries stay relative.
- **Hash**: `sha256` for `cwf-claude-settings-merge` refreshed in
  `script-hashes.json` (pre-refresh `git log` verification clean); working perms
  restored to recorded 0500. `cwf-manage validate` → OK.
- **Permission drift fixed on sight**: validate flagged a pre-existing 0700→0500
  drift on `security-review-changeset` (not a file this task touched); clamped via
  `cwf-manage fix-security` rather than deferring.

### Step 5: Tests
- **Actual**: `t/skill-root-anchor.t` (TC-1..TC-4: at-root no-op, subdir two-halves
  exit-127, worktree main-root, outside-repo tolerant); `t/skill-anchor-drift.t`
  (TC-5a byte-identical form + TC-5b coverage/position); extended
  `t/cwf-claude-settings-merge.t` (TC-13 prefix, TC-14 gate-independent prune +
  no-dup + count, TC-15 ownership/no-substring, TC-16 fail-open-closed via real
  off-cwd exec, TC-17 allowlist relative). Updated existing assertions that
  expected the bare-relative command form; reworked TC-U3 for the re-link behaviour.

### Step 6: Validation
- `prove t/` → **860 tests, all pass** across **69 .t files** (incl. the 2 new).
- `cwf-manage validate` → OK (only `cwf-claude-settings-merge` hash changed).
- Changed-file guard: 20 SKILL.md + `.claude/settings.json` +
  `cwf-claude-settings-merge` + `script-hashes.json` — as planned; the perm clamp
  left no git-mode change.

## Blockers Encountered
None unresolved. (Perl lexical-ordering bug in the prune — fixed in-exec.)

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (resolution from any cwd; subdir
      demonstrated by test; worktree main-root verified; suite + validate green,
      hash refreshed in-commit)
- [x] All design guidance in c-design-plan.md followed (incl. round-2 amendments)
- [x] No planned work deferred

## Security Review

**State**: no findings

Reviewed by `cwf-security-reviewer-changeset` over the 33-file changeset (276
production lines). Verdict verbatim:

- **(a) Bash injection**: the anchor interpolates only `$gcd`/`$r` (from quoted
  `git rev-parse` output), always double-quoted; the `-n` guard prevents `cd ""`.
  No `{arguments}`/slug/branch reaches the `cd` target. Clean.
- **(b) Perl/git output**: `prune_stale_relative_cwf_hooks` iterates parsed JSON
  (not git porcelain), anchored full-string match, defensive `ref` guards. Clean.
- **(c) Prompt injection**: anchor consumes no user input; runs before task-path
  parsing. Clean.
- **(d) Env handling**: `${CLAUDE_PROJECT_DIR}` emitted as a literal compile-time
  token (never `$ENV{...}` at generate-time), preserving the FR4(e) constant-command
  invariant; the cwd anchor does not depend on the env var. Clean.
- **(e) Pattern note (informational)**: the prune's safety rests on anchored
  full-string equality — never relax it to a substring/regex match (would delete
  user wrapper hooks). Already documented inline.

Verdict block: `state: no findings` (confirmed by `security-review-classify`).
Full output in the task scratch dir
(`security-review-output-implementation-exec.out`).

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
