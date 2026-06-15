# Eliminate path-resolution permission prompts - Testing Plan
**Task**: 206 (feature)

## Task Reference
- **Task ID**: internal-206
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/206-eliminate-path-resolution-permission-prompts
- **Template Version**: 2.1

## Goal
Verify the shared `scratch_parent`/`scratch_dir` lib, the paths-injecting hook, the `security-review-changeset` refactor, and the skill/convention migration — **without any test or verification command itself tripping a permission prompt** (the property under test).

## Prime directive — testing must not trip prompts
The whole point of this task is eliminating shell-var-induced permission prompts, so the test process must model that:
- **Drive everything through the already-allowlisted `prove` rule** (`Bash(prove *)` in settings.local.json). All dynamic logic lives **inside** `.t`/Perl, never in agent-issued shell.
- **No ad-hoc `$VAR`/`${...}`/`$(...)`/backtick/`$?` one-liners** from the agent. Any helper script goes to a file (under the injected scratch path) and is run by **literal** path.
- **Verify the hook inside a `.t`** by feeding it canned stdin and asserting stdout — **not** by triggering a live turn (which we cannot script deterministically anyway).
- Migration/grep guards use fixed-string `grep -F` (the `$` in `gcd=$(` is a regex anchor — a plain BRE grep silently matches nothing; see Task-206 design note).

## Test Strategy
### Test Levels
- **Unit (Perl, `t/*.t` via `prove`)**: `scratch_parent` / `scratch_dir` contract + failure taxonomy; the hook's stdout for canned stdin.
- **Integration**: `security-review-changeset` end-to-end after the refactor (its existing test(s)); `cwf-claude-settings-merge` registers the new hook as a second `UserPromptSubmit` entry.
- **System / regression**: full `prove` suite green; `cwf-manage validate` clean (hashes refreshed); Task-204 self-resolving-script regression still passes.
- **Acceptance (manual, g-phase)**: a real turn shows the injected `CWF PATHS` block and a migrated skill runs with no path-resolution prompt.

### Coverage Targets
- **Critical paths (100%)**: num-validation-before-FS, symlink-parent reject, no-auto-chmod, not-a-repo degradation, hook fail-open/always-exit-0.
- **Edge cases**: every `$kind`; chdir-failure; missing/empty payload `cwd`; worktree main-root.
- **Regression**: existing `security-review-changeset`, `find-git-root-worktree`, and the full suite.

## Test Cases
### Functional — `t/scratch.t` (new; pattern: `Test::More` + `CWFTest::Fixtures::create_git_repo`, chdir-based, per `t/find-git-root-worktree.t`)
- **TC-1 scratch_parent happy path**: **Given** a git repo, **When** `scratch_parent()` runs from its root, **Then** returns `("${TMPDIR:-/tmp}/cwf<dashified-abs-root>", undef)` byte-identical to the `tmp-paths.md` snippet form (assert `s{/}{-}g`, leading-dash, trailing-slash strip of `$TMPDIR`).
- **TC-2 worktree main-root**: **Given** a linked worktree (built with `git worktree add`, as in `find-git-root-worktree.t`), **When** `scratch_parent()` runs from the worktree cwd, **Then** the parent uses the **main** root, identical to TC-1 (not the worktree path).
- **TC-3 not_a_repo**: **Given** a non-repo dir, **When** `scratch_parent()`/`scratch_dir(206)`, **Then** `(undef,'not_a_repo')`; no filesystem created.
- **TC-4 scratch_dir happy path**: **Given** a repo, **When** `scratch_dir('206')`, **Then** `("…/task-206", undef)` and the dir exists mode `0700` (both parent and leaf).
- **TC-5 bad_num rejects + NO filesystem work**: **Given** a repo, **When** `scratch_dir` on each of `'1..2'`, `'..'`, `''`, `'1/2'`, `'a'`, `'1.'`, `'.1'`, `'1;rm'`, **Then** `(undef,'bad_num')` **and** no dir created (assert the path does not exist) — guards the FR4(e) traversal/injection invariant.
- **TC-6 leading-zero accepted**: `scratch_dir('007')` / `'1.01'` → success (lock the contract deliberately).
- **TC-7 symlink-parent reject, no chmod**: **Given** the scratch parent pre-created as a symlink to an attacker dir, **When** `scratch_dir(206)`, **Then** `(undef,'symlink_parent')`, the symlink is **not** followed, and its target mode is **unchanged** (no auto-chmod — surface, never smooth).
- **TC-8 idempotent re-call**: **Given** the leaf already exists `0700`, **When** `scratch_dir(206)` again, **Then** success, same path, mode unchanged.

### Functional — `t/<hook>.t` (new; canned-stdin → stdout)
- **TC-9 happy path**: **Given** stdin `{"cwd":"<repo>"}`, **When** the hook runs, **Then** stdout contains literal `cwd:`, `project_root:`, `scratch:` lines; exit 0; **stdout contains no `$` or backtick** (assert with a regex — the anti-prompt invariant).
- **TC-10 chdir-failure / unusable cwd**: **Given** stdin `cwd` pointing at a non-existent/unreadable dir, **When** the hook runs, **Then** it does **not** emit a (wrong) project_root; emits cwd-only or nothing; exit 0.
- **TC-11 missing/empty cwd & malformed JSON**: **Given** stdin `{}` / `""` / garbage, **When** the hook runs, **Then** exit 0, no crash, no partial/garbage paths (fail-open).
- **TC-12 not-a-repo**: **Given** `cwd` a non-repo dir (and `CLAUDE_PROJECT_DIR` unset in the test env), **When** the hook runs, **Then** cwd-line only; exit 0.

### Regression / integration
- **TC-13**: `security-review-changeset` existing test(s) pass unchanged after the `scratch_dir` refactor; scratch-failure still maps to **exit 1** (error class the SubagentStop guard relies on).
- **TC-14**: after `cwf-claude-settings-merge`, `.claude/settings.json` has **two** `UserPromptSubmit` entries (the `cat` + the new hook) and the new hook's allow rule; the `cat` command string is unchanged.
- **TC-15 (migration guard)**: `grep -rlF 'anchor the shell' .claude/skills/` → empty (run via Grep tool / inside a `.t`, not an agent `$`-laden one-liner); no Step-5 fenced ```bash block in the two task-creation skills contains `repo_root//`.

### Non-Functional
- **Security (FR4)**: covered by TC-5 (input validation before FS), TC-7 (symlink defence + no-chmod), TC-9 (no shell-expansion tokens emitted), and the design's single-user `cwd`/`$TMPDIR` trust note.
- **Reliability**: TC-10/11/12 (hook never blocks a turn — always exit 0).
- **Performance**: hook adds ≤1 `git rev-parse` per turn; no separate benchmark (NFR1 is a non-regression, not a target).
- **Usability**: the headline outcome — verified in the g-phase acceptance smoke (no path-resolution prompt on a migrated skill).

## Test Environment
- POSIX shell, macOS/Linux system Perl, **core modules only**; `prove` (already allowlisted). `File::Temp`/`CWFTest::Fixtures` for repo + worktree fixtures (test-context `git worktree add` is acceptable — the worktree-process convention governs agent/skill use, not test fixtures).
- Hook tests inject `CLAUDE_PROJECT_DIR` / stdin explicitly so they do not depend on the live session env.
- No production data; all writes under `File::Temp` dirs or the canonical scratch path.

## Validation Criteria
- [ ] `t/scratch.t` and the hook `.t` pass (TC-1…TC-12); full `prove` suite green (no regressions).
- [ ] TC-13/14/15 pass; `cwf-manage validate` clean with hashes refreshed in the same commit.
- [ ] g-phase: injected `CWF PATHS` block observed and a migrated skill runs with **zero** path-resolution prompts — established without the test/verification commands themselves prompting.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
