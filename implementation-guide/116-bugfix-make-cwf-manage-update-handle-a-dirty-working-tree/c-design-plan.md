# Make cwf-manage update handle a dirty working tree - Design
**Task**: 116 (bugfix)

## Task Reference
- **Task ID**: internal-116
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/116-make-cwf-manage-update-handle-a-dirty-working-tree
- **Template Version**: 2.1

## Goal
Detect uncommitted changes under `.cwf/` and `.cwf-skills/` before `cwf-manage update` runs destructive operations, and abort with a clear, actionable message. Replace the current opaque `git subtree` failure (subtree method) and silent `rmtree`-then-overwrite (copy method) with a single CWF-prefixed error.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Decision 1 — Fail-fast over auto-stash
- **Decision**: Detect a dirty working tree and **die** with an actionable error. Do **not** auto-stash.
- **Rationale**:
  - Correctness > maintainability > performance. Fail-fast has no failure modes of its own; auto-stash adds several (lost stash if `git stash pop` conflicts mid-update, user surprised by stash they didn't ask for, partial restore on mid-update failure).
  - The user's stash dance (`git stash` → `cwf-manage update` → `git stash pop`) is two extra commands and remains entirely under their control. Surfacing the recommended commands in the error message is enough — we don't need to run them.
  - **Reversibility**: trivially upgradeable to auto-stash later if external-user demand warrants it. The helper signature stays the same; only the helper body changes.
- **Trade-offs**:
  - +Simpler implementation (~15 lines vs ~50 with auto-stash + restore + failure-mode logging).
  - +No risk of silent stash retention or pop conflicts.
  - −Marginally less convenient for the friction-tolerant user; this is offset by a clear error showing the exact 3-command recipe.

### Decision 2 — Scope the check to `.cwf/` and `.cwf-skills/`, not repo-wide
- **Decision**: `git status --porcelain -z --untracked-files=all -- .cwf .cwf-skills`. Repo-wide cleanliness is **not** required.
- **Rationale**:
  - These are the only paths `update_subtree` and `update_copy` write to destructively. A user with unrelated working-tree changes elsewhere (their own project files, docs, etc.) has no business being blocked from updating CWF.
  - `git subtree pull` itself only fails when conflicting paths are dirty, but its error doesn't say so — that's the bug. By scoping our pre-check to the exact paths CWF will touch, the error message is precise.
  - **`.claude/skills/cwf-*` is intentionally NOT in scope**, despite `create_skill_symlinks` (line 324) unlinking and recreating those entries on every update. The contents are CWF-managed symlinks regenerated from `.cwf-skills/`; users do not edit them, and `git status` reports no diff for unchanged symlinks. Including `.claude/skills` would over-block: a user editing their own non-CWF skill (`.claude/skills/my-skill/...`) has nothing to do with the CWF update path. Risk is low: if a user has manually edited a `cwf-*` symlink to point elsewhere, the recreation step will silently overwrite it — same behaviour as today, and in practice this is a deliberate symlink, not an accidental file edit.
- **Trade-offs**:
  - +Focused error: "you have changes under `.cwf/`" beats "you have changes somewhere".
  - +Doesn't block users mid-task on their own work.
  - −One slightly subtle case: a user with `.gitignore`'d files in `.cwf/` won't trip the check, which is correct (they're explicitly ignored), but `--untracked-files=all` would surface them if they aren't ignored.

### Decision 3 — Include untracked files in "dirty"
- **Decision**: `--untracked-files=all`. Untracked files inside `.cwf/` are dirty.
- **Rationale**:
  - `update_copy` runs `rmtree("$git_root/.cwf")` and **silently destroys untracked files** along with everything else. This is the worst-case data-loss path and is covered by including untracked.
  - `update_subtree`'s `git subtree pull` may not directly conflict with an untracked file, but the user almost certainly cares about it — surfacing it is the safer default.
- **Trade-offs**:
  - +Catches the silent-destruction case under copy method.
  - −Slightly more aggressive than strictly necessary for subtree method, but consistency between paths beats per-method special casing.

### Decision 4 — Single insertion point in `cmd_update` (before clone)
- **Decision**: Call the check **after** `read_version_file` + `resolve_source` succeed, **before** `tempdir`/`git clone`. Both `subtree` and `copy` paths are protected by a single check; no per-method duplication.
- **Rationale**:
  - Cheap-fail-first: source resolution is local, the dirty-tree check is local, the clone is the first network/IO-heavy step. Failing dirty before clone saves bandwidth and ~1–2s.
  - The check is method-agnostic — it precedes the `if ($method eq 'subtree')` branch.
- **Trade-offs**:
  - +One call site; one mental model.
  - −Source resolution happens before the dirty check, so a user with both an unset `CWF_SOURCE` and a dirty tree sees the source error first. Acceptable: they need to fix that anyway, and the dirty-tree error will surface on the next run.

### Decision 5 — Helper signature mirrors Task 115's `resolve_source`; one emission point
- **Decision**: `sub check_clean_tree { my ($git_root) = @_; ... die_msg($full_message) if dirty; }`. Hardcode `'.cwf'` and `'.cwf-skills'` inside the helper — there's only one caller and one set of paths. Helper calls `die_msg` directly with the **complete** error (header + file list + recipe). No `eval` wrapper at the call site.
- **Rationale**:
  - Symmetry with `resolve_source($v_ref)`, `read_version_file($git_root)`, and every other helper in `cwf-manage` — they all `die_msg` (which `print STDERR; exit 1`). No reason to invent an asymmetric raw-`die` contract here.
  - Speculative reuse (a hypothetical `cwf-manage rollback --safe` mode) doesn't justify present-day indirection. If a future caller really needs the terse-only form, that's a refactor when it's needed, not a design bet now.
- **Trade-offs**:
  - +Single emission point — what the user sees is what the helper says, no two-place coupling.
  - +Call site reduces to one line: `check_clean_tree($git_root);`.
  - −Helper text is update-specific (mentions `cwf-manage update`); a hypothetical future caller would have to refactor. Acceptable: refactor when it happens.

### Decision 6 — Error message shape: single block, no cap
- **Decision**: One message, emitted via `die_msg`, listing **all** dirty entries (no truncation):
  ```
  [CWF] ERROR: Working tree has uncommitted changes under .cwf, .cwf-skills:
    M  .cwf/scripts/cwf-manage
    ?? .cwf/notes.md
  Stash or commit them, then re-run:
    git stash
    cwf-manage update [ref]
    git stash pop
  ```
- **Rationale**:
  - The user needs three things in this order: (a) confirmation they have uncommitted changes (and where), (b) the exact recipe to recover, (c) reassurance their changes weren't touched (implicit from "abort" + status codes preserved).
  - **No cap**: the typical case is 0–2 dirty files. A user with 30 dirty files in `.cwf/` is in deep enough trouble that seeing all 30 is more useful than truncating. Removes ~5 lines of helper code and one dedicated subtest. If "too long" complaints arise, that's a polish follow-up.
- **Trade-offs**:
  - +One block, no formatting branches.
  - +No "deliberate divergence from Task 113" rationale to maintain.
  - −Long lists print fully; acceptable.

### Decision 7 — Status output reuses `git status --porcelain -z` pattern; check exit code
- **Decision**: Use list-form `open '-|', 'git', '-C', $git_root, 'status', '--porcelain', '-z', '--untracked-files=all', '--', '.cwf', '.cwf-skills'`. NUL-delimited output. **The displayed file list preserves the porcelain status code** (`M  `, `??`, `UU`, etc.) verbatim.
- **Exit-code handling**: After the `git status` invocation, **check `$?`**. If non-zero, `die_msg("Failed to check working tree status (git status exited non-zero)")`. Treating a failed `git status` as "clean and proceed" would silently re-introduce the very class of failure mode this task fixes.
- **Rationale**:
  - Same idiom as Task 113's `stop-uncommitted-changes-warning` line 16 — NUL-safe; list-form avoids shell quoting altogether.
  - `--porcelain` (v1) is the stable contract; status codes preserved verbatim in the user-facing list.
- **Trade-offs**: One extra line of defensive code; no observable cost on the happy path.

### Decision 8 — `cmd_status`, `cmd_list_releases`, `cmd_help`, `cmd_validate` unchanged
- **Decision**: Read-only commands do **not** check for a dirty tree. Only `cmd_update` (and via it, `cmd_rollback`, which calls `cmd_update`) does.
- **Rationale**: A dirty tree is irrelevant for read-only operations. Forcing cleanliness everywhere would be over-reach.

## System Design

### Component Overview
- **`check_clean_tree($git_root)`**: New helper in `.cwf/scripts/cwf-manage`. Runs `git status --porcelain -z --untracked-files=all -- .cwf .cwf-skills`, splits on NUL, calls `die_msg(...)` with header + file list + recipe if any entries are present. Returns nothing on clean.
- **`cmd_update`**: Modified call site. Single new line (`check_clean_tree($git_root);`) inserted between `resolve_source` and the existing `log_msg("Updating CWF...")`.
- **`cmd_rollback`**: Unchanged — already delegates to `cmd_update`, so it's automatically covered. Verified by reading lines 257–263.
- **`cmd_help` heredoc**: Add a `Notes:` subsection between `Environment:` and `Examples:`. ASCII-only. **This is the single source of truth for the new behaviour** — no duplication into the file-header comment.

### Data Flow
1. User runs `cwf-manage update [ref]`
2. `cmd_update` reads `.cwf/version` (existing)
3. `cmd_update` calls `resolve_source` (existing, Task 115)
4. **`cmd_update` calls `check_clean_tree($git_root)` ← new**
5. On dirty: `check_clean_tree` calls `die_msg` with full message (header + files + recipe); process exits 1. Working tree untouched.
6. On clean: `cmd_update` proceeds to `tempdir` → `git clone` → method dispatch (existing)

### Interface Design
- **No external interface changes** (no new commands, no new flags, no new env vars).
- **One new exit path** in `cmd_update` (dirty-tree die). Exit code: whatever `die_msg` already produces (`exit 1` per the existing pattern).
- **One new help-text block**: ASCII, no em-dashes, follows Task 115's "Environment:" precedent for placement.

### Data Models
N/A — no persisted data, no schema changes.

## Failure Modes
| Mode | Detection | Behaviour |
|------|-----------|-----------|
| `git status` exits non-zero (e.g., not a git repo, corrupt `.git`) | `$?` non-zero after the system/backtick call | **Die** via `die_msg("Failed to check working tree status (git status exited non-zero)")`. We do **not** treat a failed status check as "clean and proceed"; that would silently re-introduce the silent-destruction class this task is fixing. In practice `cmd_update` already runs from a `find_git_root()`-resolved repo so this is a near-impossible path, but the defensive check costs one line. |
| Repo with conflicts mid-rebase/merge | `git status --porcelain` returns `UU` / `AA` etc. — non-empty | Dirty path; same error as any other dirty entry. Pre-update is not the time to be in mid-rebase. |
| `.gitignore`'d files inside `.cwf/` | Not surfaced by `--untracked-files=all` (ignored files are excluded by design) | Treated as clean — correct: user explicitly said "ignore these". |
| Symlinks (e.g., `.claude/skills/cwf-*`) | Tracked symlinks: regular `M` if changed; not modifiable in practice | No special-case needed. |
| Very long file lists | All entries printed | No cap. Typical case is 0–2 files; long lists are rare and the user benefits from seeing all of them. |

## Constraints
- Perl-only; no new CPAN deps. `system()` (already used elsewhere in `cwf-manage`) and the existing `die_msg`/`log_msg` helpers cover everything.
- `-CDSL` + `use utf8;` already in place (Task 115). Error message is ASCII-only to keep the surface trivial.
- `.cwf/security/script-hashes.json` re-hash required (foreseeable; explicit checklist item in d-impl-plan).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: <1 day — no decomposition needed
- [ ] **People**: Single contributor — no decomposition needed
- [ ] **Complexity**: One helper, one call site, one help-block update — single concern
- [ ] **Risk**: Fail-fast eliminates the auto-stash risk surface — no isolation needed
- [ ] **Independence**: Not parallelisable — no decomposition needed

**Verdict**: 0/5 signals triggered.

## Validation
- [x] Design review (3 parallel subagents — Improvements / Misalignment / Robustness) completed; see summary below
- [x] Decisions cross-checked against existing patterns (Task 113 hook line 16/21–26; Task 115 `resolve_source` helper; `cwf-manage` `cmd_update` line 210–254)
- [x] Failure modes enumerated

### Plan Review Summary
**Applied (initial review — 3 parallel subagents)**:
- *Robustness (HIGH)* — `.claude/skills/cwf-*` intentionally out of scope (CWF-managed; over-blocking unrelated user skills outweighs the marginal symlink-overwrite risk). Documented in Decision 2.
- *Robustness (MEDIUM)* — exit-code check on `git status` (Decision 7). A non-zero `$?` dies; doesn't silently proceed.

**Applied (second pass — `/simplify`)**:
- Decisions 5/6 collapsed: helper now calls `die_msg` directly with the full message. Removed the "helper terse / recipe at call site" split, the `eval` wrapper, the "raw `die` not `die_msg`" asymmetric contract, and the speculative-future-caller justification.
- Helper signature simplified: `check_clean_tree($git_root)`. `@paths` parameter dropped — only one caller, only one set of paths.
- Cap-overflow logic dropped. Show all dirty entries. Removes ~5 lines of helper code and a dedicated test case.
- File-header comment duplicate dropped. `cmd_help` heredoc is the single source of truth.

**Not applied**:
- *Improvements (LOW)* — source-error-before-dirty-error: already acceptable in Decision 4.
- *Robustness (LOW)* — partial-failure recovery hint: the file list surfaces partial state without extra prose.
- *Robustness (LOW)* — `find_git_root` race: covered by the exit-code die.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 116
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
