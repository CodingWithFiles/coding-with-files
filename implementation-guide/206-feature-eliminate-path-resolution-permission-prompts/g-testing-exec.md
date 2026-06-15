# Eliminate path-resolution permission prompts - Testing Execution
**Task**: 206 (feature)

## Task Reference
- **Task ID**: internal-206
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/206-eliminate-path-resolution-permission-prompts
- **Template Version**: 2.1

## Goal
Execute the e-testing-plan.md test cases and record results — without the test
process itself tripping a permission prompt (the property under test). All
dynamic logic ran inside `.t`/Perl via the already-allowlisted `prove`; the
hook was verified with canned stdin, not a live turn.

## Test Execution Summary
- **Full suite**: `prove -l -j4 t/` → **72 files, 874 tests, all pass**.
- **cwf-manage validate**: **OK** (hashes refreshed in the f-phase commit).
- **Prime directive honoured**: no agent-issued `$VAR`/`${...}`/`$(...)`/backtick/`$?`
  one-liner was used to drive tests; migration guards use `grep -F`.

## Test Case Results

### Functional — `t/scratch.t` (scratch_parent / scratch_dir)
- **TC-1 scratch_parent happy path (byte-identical)**: PASS
- **TC-2 worktree main-root**: PASS
- **TC-3 not_a_repo (no FS)**: PASS
- **TC-4 scratch_dir happy path, mode 0700**: PASS
- **TC-5 bad_num rejects + NO FS work** (`1..2`,`..`,``,`1/2`,`a`,`1.`,`.1`,`1;rm`): PASS
- **TC-6 leading-zero / dotted accepted** (`007`,`1.01`): PASS
- **TC-7 symlink-parent reject, target not chmod-ed**: PASS
- **TC-8 idempotent re-call, mode unchanged**: PASS

### Functional — `t/userpromptsubmit-context-inject.t` (hook, canned stdin→stdout)
- **TC-9 happy path: 3 literals, exit 0, no `$`/backtick in output**: PASS
- **TC-10 unusable payload cwd → no wrong root, exit 0**: PASS
- **TC-11 missing/empty cwd & malformed JSON → fail-open, exit 0**: PASS
- **TC-12 not-a-repo → cwd-only, exit 0**: PASS

### Regression / integration
- **TC-13 security-review-changeset after `scratch_dir` refactor**: PASS — full
  `t/security-review-changeset.t` green (47 subtests); the symlink-parent case
  still exits 1 (verdict-guard "error" class preserved), stderr now reports
  `scratch unavailable (symlink_parent)`. Helper verified end-to-end: wrote a
  2237-line changeset via the new path.
- **TC-14 settings.json has two UserPromptSubmit hooks + allow rule**: PASS —
  the rules-inject `cat` (unchanged) and `userpromptsubmit-context-inject` are
  both registered; the exact `Bash(.cwf/scripts/hooks/userpromptsubmit-context-inject)`
  allow rule is present.
- **TC-15 migration guard**: PASS — `grep -rlF 'anchor the shell' .claude/skills/`
  and `grep -rlF 'repo_root//' .claude/skills/` both empty; `t/skill-anchor-drift.t`
  (inverted into the migration guard) green.

### Non-Functional
- **Security (FR4)**: covered by TC-5 (validate-before-FS), TC-7 (symlink defence,
  no chmod), TC-9 (no shell-expansion tokens emitted). Reviewed in Step 8.
- **Reliability**: TC-10/11/12 — hook always exits 0, never blocks a turn.
- **Performance (NFR1)**: hook costs a single `git rev-parse`/turn (`scratch_parent`
  accepts the hook's pre-resolved root). No benchmark (non-regression target).

### Acceptance smoke (live in-session injection) — DEFERRED, honestly recorded
- **Planned**: a real turn shows the injected `CWF PATHS` block and a migrated
  skill runs with zero path-resolution prompts.
- **Actual**: the hook was registered into `.claude/settings.json` this session,
  but Claude Code loads `settings.json` at **session start** — this turn's
  context shows only the rules-inject `CWF RULES` block, **not** a `CWF PATHS`
  block. Live injection therefore takes effect on the **next session start**
  (same session-cache behaviour as agent definitions). The hook's output is
  unit-verified now (TC-9..TC-12, canned stdin→stdout). The live confirmation is
  deferred to a fresh session and noted for rollout (h). Not fabricated as
  observed.

## Coverage
- Critical paths (num-validate-before-FS, symlink reject, no-chmod, not-a-repo
  degradation, hook fail-open) 100% covered by TC-1..TC-12.
- Full suite (874 tests) green — no regressions in adjacent helpers
  (`find-git-root-worktree`, `security-review-*`, `cwf-manage-fix-security`).

## Security Review

**State**: no findings

Reviewed the testing-exec changeset (executable surface byte-identical to
implementation-exec; this phase adds the test files + wf docs). All five FR4
threat categories pass: test files use list-form git/exec, validate-before-FS
ordering (TC-5), `local`-ised env, and temp-only symlink fixtures (TC-7 proves
no auto-chmod). The verbatim `cwd` injection is safe under the single-user trust
model (gated on `-d`, hook header + tmp-paths.md) — audit if the `-d` gate is
relaxed, `cwd` is sourced from a multi-tenant/remote payload, or a fourth
less-trusted injected field is added.

```cwf-review
state: no findings
summary: Test files use list-form git/exec, validate-before-FS, localised env, and temp-only symlink fixtures; verbatim cwd injection is safe under the single-user trust model (audit if cwd source or the -d gate changes).
```

## Best-Practice Review

**State**: no findings

no findings: no applicable best practices (best-practice-resolve matched 0 entries for task 206 / testing-exec)

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- A UserPromptSubmit hook's *live* effect can't be self-observed in the session
  that registers it — settings load at session start. Verify behaviour via a
  canned-stdin `.t` and defer the live smoke to a fresh session, rather than
  claiming an unobserved injection.
