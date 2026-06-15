# Eliminate path-resolution permission prompts - Design
**Task**: 206 (feature)

## Task Reference
- **Task ID**: internal-206
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/206-eliminate-path-resolution-permission-prompts
- **Template Version**: 2.1

## Goal
Choose the concrete mechanism that delivers the requirements' zero-prompt outcome for both jobs (cwd-anchoring and scratch derivation), with the fewest moving parts and zero/near-zero new allowlist entries.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## What actually triggers the prompt (grounding)
The harness allowlists Bash by command-string prefix (e.g. `Bash(.cwf/scripts/command-helpers/context-manager:*)`). It prompts on **any** agent-issued command string that contains a shell variable or expansion of *any* kind — `$VAR`, `${VAR}` parameter expansion, command substitution `$(...)`, backticks, and built-in variables such as `$?` — because the dynamic expansion defeats static prefix matching, regardless of what it resolves to. (Confirmed in-session: a bare `context-manager location` runs prompt-free, while a trailing `; echo "EXIT: $?"` or any `${//}`/`$(...)` trips the prompt.) The fix for both jobs is therefore the same and stronger than "avoid `$(...)`": **the agent-issued command string must contain no shell variables/expansions at all — only literal text (the helper name plus literal positional args).** This is why `context-manager scratch 206` (all-literal) is prompt-free while the inline `${TMPDIR:-/tmp}`/`${repo_root//…}`/`$(git …)` snippet is not.

## Rejected candidate (carried from requirements)
- **Env var for the root** (backlog candidate b): rejected. Task 204 established `CLAUDE_PROJECT_DIR` is hooks-only and absent from the general Bash tool environment (claude-code #33815). No env-var fast-path.

## Mechanism pivot (supersedes the call-a-helper approach)
A helper the agent *calls* can only ever deliver the **side effect** prompt-free — the moment the agent needs the helper's **value** (the path) it must capture it with `$(...)` and check `$?`, the exact tokens that trip the prompt (robustness review, design-phase Finding 1). The fix is to never make the agent resolve anything: **a hook injects the paths into the agent's context, mechanically, every turn.** The agent then uses literal absolute paths directly — zero resolution commands, zero shell expansions, zero prompts. (Confirmed feasible: the existing `UserPromptSubmit` hook already injects the CWF rules block every turn via `cat .cwf/rules-inject.txt`, and hooks have `${CLAUDE_PROJECT_DIR}` — the very env var that is hooks-only and absent from the Bash tool, per Task 204.)

## Key Decisions

### Decision 1 — Job A (anchoring): a **second** `UserPromptSubmit` hook emits cwd + project root
- **Decision**: Add a `UserPromptSubmit` hook script (`.cwf/scripts/hooks/userpromptsubmit-context-inject`) that, each turn, emits two literal absolute paths into context: (1) **current directory**, (2) **project root directory**. It registers itself via a `# cwf-hook-event: UserPromptSubmit` directive (the manifest-driven mechanism in `cwf-claude-settings-merge:9-17,95-131`) and a `script-hashes.json` manifest entry — so `cwf-claude-settings-merge` auto-registers AND auto-allowlists it on regen. It is a **second, independent** `UserPromptSubmit` hook **alongside** the existing rules-inject `cat`; it does **not** touch, supersede, or re-emit the rules. (UserPromptSubmit fires every registered hook; their stdouts concatenate into context.)
- **Why not supersede the `cat`**: `$CANONICAL_RULES_INJECT_CMD` is a frozen FR4(e) security constant in `cwf-claude-settings-merge:404`; replacing it means surgery on that helper's prune/emit machinery and risks double-injection. A separate single-responsibility hook (paths only) avoids all of it, and keeps the resilient `cat … 2>/dev/null || true` rules path exactly as-is. **No hand-edit of `.claude/settings.json`** (registration is manifest-driven, not hand-written); **`cwf-claude-settings-merge` is not modified**.
- **Root resolution (pin the real API)**: `CWF::Common::find_git_root()` takes **no argument** — it resolves from the hook process's cwd. The hook therefore: read payload `cwd` (fallback `Cwd::getcwd()`); validate it is a non-empty existing dir; `chdir` to it; call `find_git_root()` for the worktree-safe **main** root; if undef, fall back to `$ENV{CLAUDE_PROJECT_DIR}` (guaranteed in the hook env per Task 204); if still unresolved, emit the cwd line only. (Do **not** use `git -C` — project convention discourages it.)
- **Consequence**: The agent always has the literal root + cwd in context, so it invokes helpers and reads/writes by **literal absolute path** — the per-skill "anchor the shell" block (the prompt-storm's main source, 20 skills) is **deleted outright**, replaced by nothing.
- **Fail-open**: the hook wraps its body in `eval` and **always exits 0** on the prompt path (precedent: `subagentstop-security-verdict-guard:17`); malformed/empty stdin, a `find_git_root` failure, or any exception → emit nothing (or cwd-only) and exit 0. It must never block a turn. (The rules block is unaffected — it is the separate `cat` hook.)
- **Must-verify-first**: that the `UserPromptSubmit` stdin payload actually carries `cwd` (PreToolUse does — `pretooluse-bash-tool-check:209`; UserPromptSubmit is a different event). Implementation Step 1 is a 3-line stdin-dump probe (no fabricated assumptions); the `getcwd()`/`CLAUDE_PROJECT_DIR` fallbacks make the hook correct even if the payload omits `cwd`.

### Decision 2 — Job B (scratch): hook emits a `$num`-free scratch parent; split shared lib; no subcommand
- **Decision**: The same hook emits a **third** literal — the canonical scratch parent `${TMPDIR:-/tmp}/cwf<dashified-root>/` — via a new **pure, `$num`-free** `CWF::Common::scratch_parent()` (string only, **no filesystem work**). The agent forms the per-task leaf by appending `task-<num>` as a literal and creating it with `mkdir -m 0700 -p <literal>` (allowlisted, no expansion). The agent cannot derive the parent itself (dashifying the root needs `${root//\//-}`, a prompting expansion), so emitting it pre-computed is the value. **`security-review-changeset` is refactored onto a sibling `scratch_dir($num)`** (= `scratch_parent()` + leaf `mkdir 0700` + symlink-reject guard) so the security-sensitive write-time derivation lives in exactly one place. **No `context-manager scratch` subcommand** — the agent never calls a resolver (drops the dispatcher change, `.d/scratch`, its perms, and its hash entry from scope).
- **Why the hook does no filesystem work**: the symlink-reject + `mkdir 0700` is a *writer-time* defence; the hook only emits a string. Running it every turn would be wasted work + a new per-turn failure surface, and the hook has no task number anyway (the parent is `$num`-independent). Keeping `scratch_parent()` pure leaves only `not_a_repo` for the hook to handle.
- **Rationale / trade-offs**: Same injection channel kills the inline `${repo_root//\//-}` derivation (the 2 task-creation skills + the convention) as it kills the anchor block. DRY: collapses the duplicated `security-review-changeset:255-287` block to one tested place. Brings `security-review-changeset` (hashed, tested) into scope; its tests must still pass. Reverses `tmp-paths.md`'s "helper deferred" bullet — the prompt-storm flips that cost/benefit, and a shared lib is a smaller surface than the deferred bullet imagined.

### Decision 3 — `scratch_parent()` / `scratch_dir()` contracts + failure semantics
Two pure functions (no `exit`, no `print`), unit-testable:
- **`scratch_parent()`** — `$num`-free, no filesystem. Returns `($parent, undef)` or `(undef, 'not_a_repo')`. `s{/}{-}g` dashify (leading `/`→leading `-`); base `${TMPDIR:-/tmp}` with trailing-slash strip. Used by the hook.
- **`scratch_dir($num)`** — `scratch_parent()` + per-task leaf, **and** the write-time guard. Returns `($path, undef)` or `(undef, $kind)`, `$kind ∈ {not_a_repo, bad_num, symlink_parent, mkdir_failed}`. Validate `$num` against anchored `^[0-9]+(\.[0-9]+)*$` **before** any filesystem work (rejects `..`, empty/`.` components, `/`, metacharacters; leading zeros accepted — assert in tests). Then: `mkdir -m 0700` parent **then** re-`lstat` reject a **symlinked** parent (`-d && !-l`) — mkdir-then-recheck ordering preserved (race-tolerant, per `security-review-changeset:271-273`); **never auto-chmod** a foreign/wrong-mode parent (surface, never smooth — carry the `:274-276` comment into the function); leaf left to the fail-closed `mkdir`/write (no hostile-leaf probe — only a writer can). Used by `security-review-changeset` (and any future writer).
- **Consumer mapping**: hook calls `scratch_parent()` — `not_a_repo` → omit the scratch line (benign, matches today's non-fatal "deferred to first use", FR6). `security-review-changeset` maps any `scratch_dir` `(undef,$kind)` to its existing `warn + exit 1` (preserves the exit-1 "error" classification the SubagentStop guard relies on).

## System Design
### Component Overview
- **`CWF::Common::scratch_dir($num)`** (new, in `.cwf/lib/CWF/Common.pm`): the pure derivation+guard of Decision 3; added to `@EXPORT_OK`.
- **`.cwf/scripts/hooks/userpromptsubmit-context-inject`** (new): `UserPromptSubmit` hook, **paths only** (does not emit rules). Reads stdin JSON for `cwd` (fallback `getcwd()`); `chdir` + `find_git_root()` (fallback `$ENV{CLAUDE_PROJECT_DIR}`) for the root; `scratch_parent()` for the scratch line; prints the CWF PATHS block. Carries a `# cwf-hook-event: UserPromptSubmit` directive. `#!/usr/bin/env perl`, `use utf8;`, `check_perl5opt()`, core-only, perms 0500, whole body `eval`-wrapped, always exit 0.
- **`.cwf/security/script-hashes.json`**: **add** the new hook entry (path, `"permissions":"0500"`, sha256); refresh `CWF/Common.pm` and `security-review-changeset`. Same commit (hash-update convention). The manifest entry is also what makes `cwf-claude-settings-merge` register + allowlist the hook.
- **`.claude/settings.json`**: registration is **manifest-driven** — run `cwf-claude-settings-merge` (or `/cwf-init` regen) so it adds the new hook as a second `UserPromptSubmit` entry and its allow rule. No hand-edit; `cwf-claude-settings-merge` source is **not** modified; the rules-inject `cat` entry is untouched.
- **`security-review-changeset`**: replace inline block (`:255-287`) with a `scratch_dir($task_num)` call; tests must still pass (still exit-1 on failure).
- **`tmp-paths.md`**: document the hook-injected scratch parent + `scratch_parent`/`scratch_dir` as the single source of truth; rewrite the "helper deferred" bullet (`:205-207`), fix the "Trivially derivable — no helper script" line (`:148`), re-point the threat-model prose (`:114-126`) at the shared functions, **preserve** the `pretooluse-bash-tool-check` carve-out (`:196-204` — it keeps its own `s{[^A-Za-z0-9]+}{-}g` rule, NOT folded onto `scratch_parent`), and re-label the shell Derivation snippet (`:36-47`) as spec, not agent-use.
- **~20 `SKILL.md` files**: delete the "anchor the shell" block outright (no replacement note — injected context carries root + cwd). `.claude/skills/` is not hash-tracked.
- **`cwf-new-task` / `cwf-new-subtask` Step 5**: replace the inline `${repo_root//\//-}` derivation + `mkdir` with a literal `mkdir -m 0700 -p <injected-scratch-parent>/task-<num>` instruction (no expansion), referencing the injected scratch parent.

### Data Flow (per turn)
1. User submits a prompt → both `UserPromptSubmit` hooks fire: the existing `cat` (rules) and the new paths hook.
2. Paths hook: resolve cwd (payload→`getcwd()`), `chdir`+`find_git_root()` (→`CLAUDE_PROJECT_DIR` fallback) → root; `scratch_parent()` → scratch parent string. No filesystem work.
3. Hook prints the `CWF PATHS` block (cwd, project root, scratch parent — literals); the `cat` independently prints the rules. Both concatenate into context.
4. Agent uses those literals directly for all `.cwf/...` invocations and scratch writes — no `$(...)`, `${...}`, backticks, or `$?` ⇒ no prompt.

## Interface Design
```
New paths hook stdout (injected context), happy path:
----
CWF PATHS (use these literal absolute paths directly; do not re-resolve):
  cwd:          <abs current directory>
  project_root: <abs main repo root>
  scratch:      <abs ${TMPDIR:-/tmp}/cwf<dashified-root>>   # leaf: <scratch>/task-<num>
----
Not a git repo / unresolved root:  emit cwd line only; omit project_root + scratch.
No usable cwd:                      emit nothing.
Hook always exits 0 (never blocks the turn); rules block is the separate cat hook, unaffected.
```
`scratch_parent()` (internal): `($parent, undef)` | `(undef,'not_a_repo')`, no filesystem.
`scratch_dir($num)` (internal, writers): `($path, undef)` | `(undef, $kind∈{not_a_repo,bad_num,symlink_parent,mkdir_failed})`.

## Security note (FR4)
- **FR4(c/e)** — the injected PATHS values are repo-derived absolute paths under the single-user threat model (`tmp-paths.md:68-73`), not free text or `{arguments}`; the hook interpolates no untrusted string into the block. Safe *here* because of that invariant; would need re-review if the block ever echoed task descriptions or git output.
- **FR4(d)** — payload `cwd` flows into `chdir` then `git rev-parse` (no shell); trusted only under the single-user model; unusable `cwd` fails closed to cwd-only/nothing, never a wrong root.

## Constraints
- Hashed files: refresh `CWF/Common.pm` + `security-review-changeset`; **add** the new hook; all in the same commit (hash-update convention). Executable scripts/hooks 0500. (No `context-manager`/`.d/scratch` — subcommand dropped.)
- Core Perl only; POSIX sh; macOS system Perl.
- Must not modify the harness permission engine or `cwf-claude-settings-merge`; works within prefix allowlisting + manifest-driven hook registration.

## Decomposition Check
- [ ] **Time**: >1 week? No (1-2 days).
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one injection hook + one shared lib + a mechanical migration; both "jobs" share the same root cause and the same fix (inject, don't resolve).
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Separable parts? No — migration is downstream of the hook + lib.

**Verdict**: 0 signals — single task.

## Validation
- [ ] `scratch_dir($num)` parent is byte-identical to the current `tmp-paths` snippet form for the same repo+num, in plain checkout and linked worktree (golden unit test, FR4); `find_git_root()` returns the **main** root from a worktree cwd.
- [ ] `scratch_dir` failure modes: `not_a_repo`, `bad_num` (incl. `..`, `1..2`, empty component, `1/2`, leading-zero accepted), `symlink_parent` (no auto-chmod), `mkdir_failed`; `bad_num` performs **no** filesystem work.
- [ ] Hook: emits cwd + project_root (+ scratch) literals on the happy path; outside a repo emits cwd only and still exits 0 (never blocks the turn); preserves the existing rules-block content. Output contains **no** shell-expansion tokens for the agent to echo.
- [ ] `security-review-changeset` existing tests pass after refactor to `scratch_dir` (still exit-1 on scratch failure).
- [ ] Re-confirm Task 204's subdir regression test exercises self-resolving **scripts** (still pass), not the removed prose anchor block.
- [ ] Migration grep (fixed-string `-F`, dodging the `$`-anchor trap): `grep -rlF 'anchor the shell' .claude/skills/` returns nothing; no SKILL Step-5 fenced ```bash block contains `repo_root//`.
- [ ] Hashes refreshed for `CWF/Common.pm`, `security-review-changeset`, and **added** for the new hook, in the same commit; `cwf-manage validate` clean. (No `context-manager`/`.d/scratch` changes — subcommand dropped.)
- [ ] Zero-prompt smoke (g-testing-exec): a real turn shows the injected CWF PATHS block and a migrated skill runs with no path-resolution prompt — without the *test commands themselves* tripping a prompt (drive via allowlisted `prove`; keep dynamic logic inside Perl).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
