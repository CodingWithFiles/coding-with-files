# Resolve .cwf paths from project root, not cwd - Testing Plan
**Task**: 204 (bugfix)

## Task Reference
- **Task ID**: internal-204
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/204-resolve-cwf-paths-from-project-root-not-cwd
- **Template Version**: 2.1

## Goal
Validate that (1) the cwd anchor fixes relative `.cwf/...` resolution from any cwd,
is a no-op at root with no new permission prompt, and is worktree-safe; (2) the
surface-3 hook fix emits `${CLAUDE_PROJECT_DIR}/`-prefixed hook commands that
resolve+execute off-root (fail-open closed) without duplicates or collateral
prune; and (3) neither breaks the existing suite, `cwf-manage validate`, or the
permission allowlist (only the generator's hash changes, refreshed in-commit).

## Test Strategy
### Test Levels
- **Automated (Perl `prove t/`, Test::More)** — (a) the anchor idiom's behaviour +
  drift/coverage guard, modelled on `t/find-git-root-worktree.t` (reuse
  `CWFTest::Fixtures::create_git_repo` + `git worktree add`); (b) the surface-3
  hook-registration behaviour, extending `t/cwf-claude-settings-merge.t`
  (prefix emission, prune/no-duplicate, ownership-scoped prune, fail-open-closed,
  allowlist-unchanged).
- **Manual / in-session (harness-interactive)** — the Phase-0 spike items that
  depend on the live permission layer / tool resolution and cannot run under
  `prove` (prompt behaviour, hook, Read/Edit resolution, cwd persistence).
  Executed during f-implementation-exec and recorded there.
- **Regression** — full existing suite + `cwf-manage validate` + allowlist smoke.

### Test Coverage Targets
- **Critical path** (anchor idiom: at-root no-op, from-subdir fix, from-worktree
  main-root, outside-repo no-op; hook registration: prefix emitted, prune closes
  fail-open without duplicates): 100%.
- **Regression**: existing `t/` suite and `cwf-manage validate` stay green; the
  **only** hashed file changed is `cwf-claude-settings-merge` (refreshed in-commit).
- **No coverage %% target** — change is shell-idiom-in-markdown + generator edit +
  tests, not measurable-line code.

## Test Cases
### Automated — `t/skill-root-anchor.t` (new)
- **TC-1 (at-root no-op)**:
  - **Given**: a fixture git repo with the anchor idiom; cwd == repo root.
  - **When**: the idiom runs.
  - **Then**: cwd is unchanged (the `[ "$PWD" = "$r" ]` branch skips `cd`).
- **TC-2 (from subdirectory — the bug)**:
  - **Given**: a fixture repo containing `.cwf/scripts/...`; cwd a subdirectory.
  - **When**: a bare relative `.cwf/...` call is attempted, THEN the anchor runs
    and the same relative call is retried.
  - **Then**: (a) the bare call fails with **exit 127** (proves the bug + guards
    against a silent anchor no-op); (b) the post-anchor call **succeeds**
    (two-halves, robustness F4).
- **TC-3 (from linked worktree — worktree-safety, P0.6)**:
  - **Given**: a main repo + a linked worktree (`git worktree add`); cwd inside
    the worktree.
  - **When**: the idiom runs.
  - **Then**: cwd resolves to the **MAIN** root, not the worktree root.
- **TC-4 (outside a git repo — tolerant, bootstrap)**:
  - **Given**: cwd a non-repo tempdir.
  - **When**: the idiom runs.
  - **Then**: it is a no-op (no error, cwd unchanged); fail-to-original-bug, never
    fail-to-wrong-root.

### Automated — `t/skill-anchor-drift.t` (new, drift + coverage guard)
- **TC-5a (byte-identical idiom across SKILL.md sites — form)**:
  - **Given**: all `.claude/skills/*/SKILL.md` files.
  - **When**: the canonical anchor block is extracted from each.
  - **Then**: every skill that invokes `.cwf/...` contains exactly one copy of the
    **byte-identical** canonical block. **Scope: SKILL.md only** — must NOT grep
    `tmp-paths.md` / `update-cwf-skill-docs.sh` (those use the variable-assignment
    form by the no-cd convention; including them false-positives). NB: both files
    exist (`git ls-files` confirms `.cwf/scripts/update-cwf-skill-docs.sh`); the
    exclusion is deliberate, not a missing-file workaround.
- **TC-5b (coverage — anchor present, Robustness F3)**:
  - **Given**: the set of SKILL.md files that reference `.cwf/...` in a Bash
    invocation (or relative Read/Edit doc-ref).
  - **When**: each is scanned.
  - **Then**: **every** such skill contains the anchor block **before** its first
    `.cwf/...` reference. Guards the silent-regression case a form-only check
    misses: a skill that *omits* the anchor entirely still passes "all present
    forms are identical" but breaks off-root.

### Manual / in-session (Phase-0 spike, recorded in f)
- **TC-6 (P0.1 — no prompt at root)**: invoking an anchored skill from cwd==root
  raises **no** new permission prompt vs today. **Gate** — failure rejects the approach.
- **TC-7 (P0.3 — hook)**: the anchor passes `pretooluse-bash-tool-check` with no
  block/warn (hook confirmed inert/fail-open; this re-verifies in-session).
- **TC-8 (P0.4 — Read/Edit resolution, A1)**: a skill's `Read .cwf/docs/...` ref
  resolves when cwd ≠ root. If it does NOT → stop, scope expands (per d Step 0).
- **TC-9 (P0.5 — cwd persistence)**: cwd set by the anchor persists to the next
  Bash tool call in the same skill invocation.

### Non-Functional / Security
- **TC-10 (allowlist smoke, output-level — security finding)**:
  - **Given**: the edited skills.
  - **When**: `.cwf/scripts/command-helpers/cwf-claude-settings-merge --dry-run`.
  - **Then**: emitted relative `Bash(.cwf/scripts/...:*)` entries are **unchanged**
    (command strings stayed relative; allowlist still matches).
- **TC-11 (integrity)**: `.cwf/scripts/cwf-manage validate` passes; `git diff`
  shows the **only** hashed-file change is `cwf-claude-settings-merge` (its
  `sha256` refreshed in the same commit per the hash-updates convention) — no other
  hashed script and no unexpected `script-hashes.json` entry changed.
- **TC-12 (injection — security)**: anchor interpolates only quoted git output;
  static review confirms no `{arguments}`/slug/branch reaches the `cd` target.

### Surface 3 — hook registration (new, `t/cwf-claude-settings-merge.t` extension)
- **TC-13 (hook commands carry the literal prefix)**:
  - **Given**: a fixture repo + manifest; run `cwf-claude-settings-merge`.
  - **When**: the generated `.claude/settings.json` is parsed.
  - **Then**: every CWF hook `command` begins with the **literal** string
    `${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/` (and the rules-inject command is
    `cat "${CLAUDE_PROJECT_DIR}/.cwf/rules-inject.txt" 2>/dev/null || true`). The
    prefix is **non-empty** — guards the Perl `$`-interpolation-to-empty regression
    (a bare `/.cwf/...` must fail this assertion).
- **TC-14 (prune replaces, no duplicates)**:
  - **Given**: a settings.json pre-seeded with **bare relative** CWF hook commands
    for all 6 manifest hooks *and* the legacy rules-inject literal (incl. the
    sandbox-gated R3/guard, to prove gate-state-independence).
  - **When**: the generator runs.
  - **Then**: (a) no bare-relative CWF hook command remains; (b) no duplicate
    (relative + prefixed) pair for any hook; (c) the prune count is **surfaced**
    on stdout (and on `--dry-run`).
- **TC-15 (prune is ownership-scoped — no collateral deletion, security)**:
  - **Given**: a settings.json containing a **user-authored** hook whose command
    merely *contains* `.cwf/scripts/hooks/` as a substring (e.g. a wrapper) but is
    not an exact CWF command.
  - **When**: the generator runs.
  - **Then**: the user hook is **untouched** (anchored full-string match, never
    substring).
- **TC-16 (fail-open closed — hook resolves+executes from non-root cwd)**:
  - **Given**: the prefixed hook command from the regenerated settings.json, with
    `CLAUDE_PROJECT_DIR` set to the repo root.
  - **When**: the command is executed from a **subdirectory** cwd (mirrors the
    harness firing a hook off-root).
  - **Then**: the hook script is **located and runs** (no exit 127) — directly
    asserting the silent fail-open is closed (Robustness F2/F5). Contrast: the
    pre-fix bare-relative command fails exit 127 from the same cwd.
- **TC-17 (allowlist unchanged)**: the `permissions.allow` hook entries remain the
  bare relative `Bash(.cwf/scripts/hooks/<name>)` form (D6 deciding constraint).

## Test Environment
### Setup Requirements
- Perl with `Test::More` (core); fixtures via `t/lib/CWFTest::Fixtures`.
- `git` available (worktree support) for TC-3.
- A clean working tree for TC-11 (`git diff` assertions).

### Automation
- `prove t/` runs TC-1–TC-5, TC-10–TC-11, TC-13–TC-17. TC-6–TC-9 are in-session
  manual. (TC-3 needs `git worktree`; TC-14/TC-16 pre-seed a fixture settings.json.)
- No CI change required; same `prove` entry point as the existing 69 tests.

## Validation Criteria
- [ ] TC-1–TC-5 (incl. TC-5a form + TC-5b coverage) pass under `prove t/`
- [ ] TC-6 (no new prompt at root) confirmed — **gate**
- [ ] TC-7–TC-9 confirmed in-session
- [ ] TC-10 allowlist entries unchanged
- [ ] TC-11 `cwf-manage validate` green; **only** `cwf-claude-settings-merge` hash
      changed (refreshed in-commit); no other hashed-file diff
- [ ] TC-12 injection review clean
- [ ] TC-13 hook commands carry the non-empty `${CLAUDE_PROJECT_DIR}/` prefix
- [ ] TC-14 prune replaces all 6 hooks + legacy literal, no duplicates, count surfaced
- [ ] TC-15 user-authored hooks untouched (ownership-scoped prune)
- [ ] TC-16 prefixed hook resolves+executes from non-root cwd (fail-open closed) — **gate**
- [ ] TC-17 allowlist hook entries stay relative
- [ ] Full existing `t/` suite green (no regressions)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned cases executed and passed (results table in g-testing-exec.md). The two
gates (TC-6 no new prompt at root; TC-16 fail-open closed off-cwd) both passed. The
new `t/skill-anchor-drift.t` form+coverage guard required tuning — keying on the
`context-manager location` marker and stripping the Scope section to avoid
false-positives from earlier `.cwf/...` mentions.

## Lessons Learned
A form-only drift check is insufficient: a skill that *omits* the anchor passes "all
present forms are identical". The coverage half (TC-5b: anchor before first action) is
what actually guards the silent off-root regression.
