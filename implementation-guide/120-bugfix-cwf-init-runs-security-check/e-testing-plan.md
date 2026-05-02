# cwf-init runs security check - Testing Plan
**Task**: 120 (bugfix)

## Task Reference
- **Task ID**: internal-120
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/120-cwf-init-runs-security-check
- **Template Version**: 2.1

## Goal
Validate that `cwf-manage fix-security` deterministically repairs fixable permission deltas, refuses to act on unfixable ones (missing/tampered), and is idempotent — and that `/cwf-init` correctly delegates to it and aborts on non-zero exit.

## Test Strategy

### Test Levels
- **Unit/integration tests** (`prove t/cwf-manage-fix-security.t`): exercise the new subcommand directly against a temp `.cwf/` fixture. This is the primary correctness gate — pure Perl, no LLM, fully deterministic.
- **Regression**: full `prove t/` to confirm no existing test regressed (especially the existing `validate-*.t` files and the `cwf-manage-*.t` series).
- **Self-validation**: `cwf-manage validate` and `cwf-manage fix-security` on the development repo to confirm no hash drift.
- **Manual smoke (skill-level)**: invoke `/cwf-init` end-to-end in a scratch checkout to confirm the LLM-orchestrated `1a` step calls fix-security correctly and respects exit codes.

### Test Coverage Targets
- 100% of the algorithm's classification table (Design Decision 2 in c-design-plan.md): no-op, repair, refuse-tamper, refuse-missing, mixed, unparseable hashes file, idempotent re-run.
- Exit-code coverage: `0` only when the post-repair validate is clean; `1` for any unfixable state.
- SKILL-side: both branches of step `1a` (continue / abort) exercised manually in g-testing-exec.

## Test Cases

### Functional — automated (`t/cwf-manage-fix-security.t`)

For each case below: setup is `system("cp -r .cwf $tmp/.cwf")` from the repo root; mutation per case; invocation is `perl -I$tmp/.cwf/lib $tmp/.cwf/scripts/cwf-manage fix-security` with cwd = `$tmp`.

- **TC-1: Clean install — no-op**
  - **Given**: Pristine fixture, all files match recorded perms and sha256.
  - **When**: Run fix-security.
  - **Then**: Exit 0; no `chmod` lines in stdout (or summary `repaired 0 file(s)`); subsequent `cwf-manage validate` exits 0.

- **TC-2: Stripped perms, sha intact — repair to recorded perms**
  - **Given**: `chmod 0644` on every `.cwf/scripts/` file.
  - **When**: Pre-validate (must fail with `permissions` violations); run fix-security; post-validate.
  - **Then**: fix-security exits 0; stdout names each repaired file with target perms; post-validate exits 0; each repaired file's perms exactly match `script-hashes.json` (e.g. `0500`/`0700`/`0755`, not blanket `0755`).

- **TC-3: SHA mismatch — refuse, do not chmod, suggest `git pull` / `cwf-manage update`**
  - **Given**: Append a byte to `.cwf/scripts/cwf-manage`; also `chmod 0644` it.
  - **When**: Run fix-security.
  - **Then**: Exit 1; output names the tampered path with field `sha256`; output contains recovery-hint substrings `git pull` *and* `cwf-manage update`; the file's perms are still `0644` (no chmod attempted on a file we can't verify); file content is still tampered (we don't restore content).

- **TC-4: Missing tracked file — refuse, suggest `git pull` / `cwf-manage update`**
  - **Given**: Delete `.cwf/scripts/command-helpers/context-manager`. Strip perms on a different file (e.g. `cwf-manage` to `0644`) to confirm best-effort fix.
  - **When**: Run fix-security.
  - **Then**: Exit 1; output names the missing path with field `existence`; output contains recovery-hint substrings `git pull` and `cwf-manage update`; the *other* file is repaired (best-effort); validate still reports the existence violation.

- **TC-5: Mixed — repair fixable, refuse unfixable**
  - **Given**: Strip perms on file A (sha intact), tamper file B (append byte).
  - **When**: Run fix-security.
  - **Then**: Exit 1; output shows A repaired and B flagged with recovery hint; A's perms restored; B's perms unchanged; B's content unchanged.

- **TC-6: Unparseable hashes file — exit 1 immediately, suggest `git pull` / `cwf-manage update`**
  - **Given**: Overwrite `.cwf/security/script-hashes.json` with `not-json`.
  - **When**: Run fix-security.
  - **Then**: Exit 1; stderr names the hashes file and the parse error; output contains recovery-hint substrings `git pull` and `cwf-manage update`; no chmods applied to any file.

- **TC-7: Idempotency**
  - **Given**: TC-2 setup → fix-security (now repaired).
  - **When**: Run fix-security a second time.
  - **Then**: Second call is a no-op (exit 0, repaired 0 file(s)).

### Functional — manual smoke (skill-level, executed in g-testing-exec)

- **TC-8: End-to-end repair flow**
  - **Given**: A scratch git checkout with `find .cwf/scripts -type f -exec chmod 0644 {} \;` applied. No `implementation-guide/`.
  - **When**: User invokes `/cwf-init` in Claude Code.
  - **Then**: SKILL step `1a` runs `cwf-manage fix-security`. Exit 0. Init proceeds through steps 2–8 and creates the init commit. Final repo state has correct perms restored.

- **TC-9: End-to-end abort on tampering**
  - **Given**: Scratch repo as TC-8, but with one tracked script tampered (append byte).
  - **When**: User invokes `/cwf-init`.
  - **Then**: SKILL step `1a` runs fix-security; exit 1. LLM relays the subcommand's stdout/stderr verbatim and appends `[CWF] /cwf-init aborted: ...`. No CLAUDE.md edit, no settings.json edit, no init commit.

- **TC-10: Idempotency via second `/cwf-init`**
  - **Given**: Repo where `/cwf-init` already completed (TC-8 outcome).
  - **When**: User invokes `/cwf-init` again.
  - **Then**: Step `1a` fix-security is a no-op (exit 0). Subsequent steps are idempotent per existing skill behaviour. No duplicate `.claude/settings.json` entries; no second init commit.

### Non-Functional

- **Reliability**: TC-3, TC-4, TC-9 confirm the abort path mutates no further state (perms unchanged on unverifiable files; no init scaffolding written). Verified by `git status` / file-listing snapshots before and after.
- **Determinism**: TC-2 demonstrates that fix-security sets the *exact* recorded perms (e.g. `0500` for files recorded as `0500`), not a blanket `0755`. Verified by stat-ing each repaired file and comparing against `script-hashes.json`.
- **Usability**: TC-3, TC-4, TC-5, TC-6 outputs are inspected for clarity — each unfixable entry has a visible `field`/`actual`/`expected` block (mirroring `cwf-manage validate`'s format) plus a `Recovery:` line suggesting `git pull` (CWF source) or `cwf-manage update` (installed project).
- **Security**: fix-security never chmods a file whose sha256 doesn't match; TC-3 verifies this directly.

## Test Environment

### Setup Requirements
- Repo at HEAD of `bugfix/120-cwf-init-runs-security-check`
- Perl 5.10+ with `Digest::SHA` (core), `JSON::PP` (core), `Test::More` (core), `File::Temp` (core)
- `cp` (POSIX shell utility) for fixture cloning
- For TC-8/9/10: a separate scratch git checkout (or worktree) to avoid mutating the development repo

### Automation
- `prove t/cwf-manage-fix-security.t` — primary correctness gate
- `prove t/` — full regression
- `cwf-manage validate` and `cwf-manage fix-security` (on dev repo) — self-check
- Manual TC-8/9/10 executed during g-testing-exec; results recorded inline in `g-testing-exec.md`

## Validation Criteria
- [ ] All TC-1 through TC-7 pass under `prove t/cwf-manage-fix-security.t`
- [ ] `prove t/` shows no new failures vs the baseline recorded in d-implementation-plan Step 1
- [ ] `cwf-manage validate` and `cwf-manage fix-security` both exit 0 on the development repo
- [ ] TC-8 manual smoke: scratch repo with stripped perms init's cleanly via fix-security
- [ ] TC-9 manual smoke: scratch repo with tampered script aborts at step `1a`, no further state mutated
- [ ] TC-10 idempotency: second `/cwf-init` produces no duplicate config entries

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 120
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
