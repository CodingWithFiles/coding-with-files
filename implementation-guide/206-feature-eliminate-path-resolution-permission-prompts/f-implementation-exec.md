# Eliminate path-resolution permission prompts - Implementation Execution
**Task**: 206 (feature)

## Task Reference
- **Task ID**: internal-206
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/206-eliminate-path-resolution-permission-prompts
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Actual Results

### Step 1: Verify the UserPromptSubmit stdin contract
- **Planned**: Confirm the `UserPromptSubmit` payload carries `cwd` (no fabricated assumption).
- **Actual**: Confirmed authoritatively against the Claude Code hooks docs (code.claude.com/docs/en/hooks-guide.md): `cwd` is a **common** input field present across all hook events, including `UserPromptSubmit` (fields: session_id, transcript_path, cwd, permission_mode, hook_event_name, prompt; PreToolUse carries it too). The hook's `getcwd()` fallback is belt-and-braces, not load-bearing.
- **Deviations**: None.

### Step 2: Shared lib + tests
- **Planned**: Add `scratch_parent()` / `scratch_dir($num)` to `CWF::Common`; export both; write `t/scratch.t`.
- **Actual**: Both added (`Common.pm`), exported via `@EXPORT_OK`. `scratch_parent()` is pure (no FS); `scratch_dir($num)` validates the num against `^[0-9]+(\.[0-9]+)*$` **before** any FS work, mkdir-then-lstat-rechecks the parent (rejecting `symlink_parent`), mkdirs the leaf at 0700, and never auto-chmods. `t/scratch.t` (TC-1..TC-8) passes.
- **Deviation (recorded)**: `scratch_parent` gained an **optional** `$root` argument so the hook can pass its already-resolved root and the whole turn costs a single `git rev-parse` (NFR1). No-arg behaviour is unchanged (used by `scratch_dir` and the tests). Pure refinement, keeps single-source-of-truth.

### Step 3: The hook
- **Planned**: Create `userpromptsubmit-context-inject` (directive, eval-wrapped, always exit 0, cwd→getcwd→CLAUDE_PROJECT_DIR fallbacks, chdir-return checked, perms 0500); hook test; register via manifest.
- **Actual**: Created at `.cwf/scripts/hooks/userpromptsubmit-context-inject` (`# cwf-hook-event: UserPromptSubmit`, `use lib "$FindBin::Bin/../../lib"` co-depth, JSON::PP + Cwd, body eval-wrapped, always exit 0, chdir guarded, no `check_perl5opt`). chmod 0500. `t/userpromptsubmit-context-inject.t` (TC-9..TC-12, canned stdin→stdout, asserts no `$`/backtick in output) passes. Registered via `cwf-claude-settings-merge`: `.claude/settings.json` now has **two** UserPromptSubmit hooks — the untouched rules-inject `cat` and the new hook — plus its exact allow rule.
- **Deviations**: None.

### Step 4: Refactor the existing consumer
- **Planned**: Point `security-review-changeset` at `scratch_dir`; tests green; still exit-1 on failure.
- **Actual**: Inline ~33-line derivation block replaced with a `scratch_dir($task_num)` call mapping any `(undef,$kind)` to the existing `warn + exit 1`. Import swapped `find_git_root`→`scratch_dir`. `t/security-review-changeset.t` green (the symlink-rejection test's expected stderr updated to the new `scratch unavailable (symlink_parent)` message; exit-1 preserved). Verified end-to-end below (wrote 2237-line changeset via the new path).
- **Deviations**: None.

### Step 5: Migrate skills + convention
- **Planned**: Delete the anchor block from 20 skills; replace Step-5 derivation in the 2 task-creation skills with a literal-path mkdir; update `tmp-paths.md` (a–f).
- **Actual**: Anchor block (byte-identical across all 20) removed via a deterministic scratch script (`strip-anchor-block.pl`), leaving one blank line between the surrounding paragraphs. `cwf-new-task`/`cwf-new-subtask` Step-5 now instruct an all-literal `mkdir -m 0700 -p <injected-scratch-parent>/task-<num>` referencing the injected scratch parent (non-fatal prose preserved). `tmp-paths.md` updated: snippet relabelled as spec-not-for-agents; "Single source of truth (Task 206)" note added; threat-model prose re-pointed at `scratch_dir`; "Trivially derivable" line and "helper deferred" bullet rewritten to record supersession; the `pretooluse-bash-tool-check` carve-out left intact.
- **Deviations**: None.

### Step 6: Hashes + validate
- **Planned**: Refresh/add hashes; `cwf-manage validate` clean; full `prove` green; migration grep empty.
- **Actual**: `script-hashes.json` — refreshed `CWF/Common.pm` + `security-review-changeset` sha256; **added** the `userpromptsubmit-context-inject` entry (`"permissions":"0500"`, sha256). `cwf-manage validate`: **OK**. Full suite: **874 tests, all pass**. Migration grep (`grep -rlF`): `anchor the shell` and `repo_root//` both empty under `.claude/skills/`.
- **Deviations**: (1) `t/skill-anchor-drift.t` (Task 204) asserted the anchor block was *present* — its premise is inverted by this task, so it was rewritten as the migration guard (TC-15: the prompting constructs stay removed; task-creation skills carry the literal mkdir). (2) Two Task-205 agent files (`cwf-best-practice-reviewer-changeset.md`, `cwf-plan-reviewer-best-practice.md`) had drifted to 0400 vs their recorded 0444 (over-clamped in a prior session); restored to 0444 on sight per the permission-drift convention (content unchanged → no hash refresh).

## Security Review

**State**: no findings

## Security Review — Task 206 changeset (implementation-exec)

Reviewed executable surface: the new hook, `scratch_parent`/`scratch_dir`, the `security-review-changeset` refactor, settings.json registration + allowlist, hash-record update, four test files. The ~20 SKILL.md edits + task docs are non-executable.

- **(a) Bash injection**: no new shell-string construction; hook resolves root via `chdir`+`find_git_root()` (no shell); refactor removes inline derivation. No findings.
- **(b) input validation**: `scratch_dir` validates num against anchored pattern before any FS work (TC-5); hook JSON-decodes in a nested eval, type-guards and existence-checks `cwd`. No findings.
- **(c) prompt injection**: hook emits cwd/project_root/scratch; root + scratch derive from git output + pure transform; `cwd` is the user's own dir under the single-user trust model, on a labelled line, fail-closed on unusable cwd. Accepted posture, not a regression.
- **(d) env vars**: `TMPDIR`/`CLAUDE_PROJECT_DIR` only build paths that are 0700-mkdir'd with symlink-reject; never to a shell. No findings.
- **(e) patterns**: documented the no-chmod symlink guard (audit callers that trust returned mode without a fail-closed write) and the hook's `chdir` (short-lived process, guarded) — both already documented inline; no change requested.

Verdict: no actionable security concerns.

```cwf-review
state: no findings
summary: Hook + scratch_dir/scratch_parent validate inputs before FS work, no shell-string construction, symlink-reject defence retained with no auto-chmod (tested); injected cwd is within the documented single-user trust model.
```

## Best-Practice Review

**State**: no findings

no findings: no applicable best practices (best-practice-resolve matched 0 entries for task 206 / implementation-exec)

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- The UserPromptSubmit `cwd` field is documented and reliable; the fallback is defence-in-depth.
- A Task-204 guard test (anchor-present) had to be inverted, not just deleted — the regression we now want is the opposite (anchor stays absent). Migrating a feature means migrating its tests.
- `grep` for `gcd=$(...)`/`repo_root//` must be fixed-string (`-F`): the `$`/`/` are regex-active and a BRE silently matches nothing.
