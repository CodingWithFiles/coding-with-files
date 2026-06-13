# Align scratch tmp-paths with /tmp/claude sandbox - Testing Plan
**Task**: 199 (discovery)

## Task Reference
- **Task ID**: internal-199
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/199-align-scratch-tmp-paths-with-tmpclaude-sandbox
- **Template Version**: 2.1

## Goal
Validate that scratch-path resolution honours `$TMPDIR` (with correct
empty-string and unset semantics), that the security defences and gates survive,
and that the convention/agent-guidance is consistent — separating the
sandbox-independent path-construction checks (runnable now) from the sandbox
denial check (BLOCKED-ENV in the unsandboxed dev session).

## Test Strategy
### Test Levels
- **Integration** (primary): `t/security-review-changeset.t` runs the helper as a
  subprocess and parses the reported `.out` path — exercises the real
  `$TMPDIR` → `$scratch` construction end-to-end.
- **Static gates**: AC3 grep, `cwf-manage validate`, output-level smoke.
- **Manual / BLOCKED-ENV**: the sandbox denial check (FR7) — requires a genuinely
  sandboxed session, which the dev session is not.

### Test Coverage Targets
- **Critical path** (`$TMPDIR` honoured, empty-string defence): 100% — three
  explicit subtests.
- **Regression**: full `t/security-review-changeset.t` green; no behavioural
  change to the existing diff/cap/baseline subtests.
- **Edge cases**: unset vs empty `$TMPDIR`, trailing slash, foreign-owned dir
  (fail-closed).

## Test Cases
### Functional Test Cases (sandbox-independent — runnable in dev)
- **TC-TMPDIR-1** (honour set `$TMPDIR`):
  - **Given**: a synthetic CWF repo; `local $ENV{TMPDIR} = tempdir(CLEANUP=>1)`.
  - **When**: the helper runs and reports its `.out` path.
  - **Then**: the `.out` path is under `$TMPDIR/<dashified>-task-<num>/`.
- **TC-TMPDIR-2** (unset → `/tmp`, no regression):
  - **Given**: `delete local $ENV{TMPDIR}` (truly unset, not bare `local`).
  - **When**: the helper runs.
  - **Then**: the `.out` path is under `/tmp/<dashified>-task-<num>/`.
- **TC-TMPDIR-3** (empty-string defence — load-bearing):
  - **Given**: `local $ENV{TMPDIR} = ''`.
  - **When**: the helper runs.
  - **Then**: the `.out` path **matches `^/tmp/`** and **does NOT match `^/-`**
    (no filesystem-root collapse). Fails if the `length`-check is dropped.
- **TC-RED**: before the Step-2 code edit, TC-TMPDIR-1 and TC-TMPDIR-3 **fail**
  against the current hardcoded `/tmp/` construction (red/green discipline).

### Non-Functional Test Cases
- **Security — fail-closed (NFR4)**: the `unless -d / mkdir 0700 / exit 1` guard
  and the 0600 write remain; on a pre-existing foreign-owned scratch dir the
  helper fails closed (existing behaviour; verify unchanged, no new test needed
  unless a foreign-dir fixture is cheap).
- **Security — hash integrity (NFR4)**: `cwf-manage validate` clean after the
  `security-review-changeset` edit + same-commit `script-hashes.json` refresh.
- **Reliability — regression (NFR5)**: full `prove t/security-review-changeset.t`
  green; the other test files unaffected.
- **Consistency (NFR3) — AC3 grep gate**:
  `grep -rn '/tmp/' .cwf/docs/conventions/tmp-paths.md .cwf/scripts/command-helpers/security-review-changeset`
  shows only `${TMPDIR:-/tmp}` / `$base`-rooted forms; zero bare-`/tmp/${...}-task-`
  scratch literals. **Carve-outs** (legitimate, excluded): `template-copier`
  `/tmp/test`, `security-review.md:104` `/tmp/cwf-update`, INSTALL.md install-time,
  historical `implementation-guide/`/BACKLOG/CHANGELOG, user-owned `settings.local.json`.
- **Output smoke (rebrand-smoke discipline)**: run the helper in a synthetic repo
  with `TMPDIR` set to a known dir; confirm the produced `.out` actually lands
  under `$TMPDIR` (artefact-level, not just source grep).

### BLOCKED-ENV (FR7 — sandbox denial; needs a sandboxed session)
- **TC-SANDBOX-DENY**: under an **active** sandbox, a bare-`/tmp/<x>` write is
  **denied** and a `/tmp/claude/<x>` write is **permitted**.
  - **Status**: BLOCKED-ENV — the dev session is unsandboxed (the legacy
    `/tmp/cwf-probe-legacy-199` mkdir succeeded). Record the exact repro in
    g-testing for a later sandboxed run; do not waive silently.
- **TC-SANDBOX-TMPDIR** (D2 pivot fact): under an active sandbox, confirm
  `TMPDIR=/tmp/claude` is set in the process env.
  - **Status**: BLOCKED-ENV. Resolution decides FR4 disposition for class-(c):
    set → (ii) no-op; unset → spin out the class-(c) follow-up (BACKLOG).

## Test Environment
### Setup Requirements
- Dev: existing `t/security-review-changeset.t` harness (`run_helper_raw`
  fork/exec inherits `%ENV`; `out_path` parse; `END` cleanup). No new scaffolding.
- BLOCKED-ENV: a genuinely sandboxed Claude Code session on a host with the
  sandbox active.
### Automation
- `prove t/security-review-changeset.t` (local). No CI in this repo; manual `prove`.

## Validation Criteria
- [ ] TC-TMPDIR-1/2/3 pass; TC-RED confirmed (red before edit).
- [ ] Full `t/security-review-changeset.t` green (regression).
- [ ] `cwf-manage validate` clean (hash refreshed same commit).
- [ ] AC3 grep gate green with documented carve-outs.
- [ ] Output smoke: `.out` lands under a set `$TMPDIR`.
- [ ] FR7 TC-SANDBOX-* recorded BLOCKED-ENV with repro (or run if a sandbox is available).
- [ ] FR4 class-(c) disposition recorded against the TMPDIR pivot fact.

## Decomposition Check
- [ ] Time >1 week? No. — [ ] People >2? No. — [ ] Complexity 3+? No. —
  [ ] Risk isolation? No. — [ ] Independence? Class-(c) follow-up only if D2 falsified.
**Conclusion**: single task; no decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
