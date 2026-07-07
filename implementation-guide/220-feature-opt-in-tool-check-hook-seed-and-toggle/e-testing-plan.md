# opt-in tool-check hook seed and toggle - Testing Plan
**Task**: 220 (feature)

## Task Reference
- **Task ID**: internal-220
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/220-opt-in-tool-check-hook-seed-and-toggle
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for opt-in tool-check hook seed and toggle.

## Test Strategy
### Test Levels
- **Unit** (`t/tool-check.t`, extend) — pure `resolve_active` / `merge_seed`, no I/O.
- **Hook integration** (`t/pretooluse-bash-tool-check.t`, extend) — the flag on the real
  hot path, fed JSON on stdin with temp-fixture layer files (HOME/root pointed at a
  `File::Temp` dir).
- **Helper integration** (`t/tool-check-seed.t`, new) — `on|off|seed` end-to-end against
  temp-fixture settings files.
- **System/manual** (recorded in g) — the `/cwf-init` opt-in decline path (skill-level).

### Test Coverage Targets
- **Every AC1–AC9 has ≥1 automated test** (traceability table below).
- **Critical paths 100%**: fail-open, the kill-switch short-circuit, and the symlink-safe writes.
- **Regression**: full `prove t/` green — the existing Task-201 hook/lib behaviour unchanged.

## Test Cases (Given/When/Then)

### Unit — `t/tool-check.t`
- **TC-U1** (AC1/DK2 default-true): **Given** no trusted layer defines `active` **When**
  `resolve_active` runs **Then** returns 1.
- **TC-U2** (DK2 boolean-only coercion): **Given** layers with `active` = `"false"` (string),
  `0`, `null`, `[]` **When** resolved **Then** each is ignored (falls through → 1); a real
  JSON `false` → 0; real `true` → 1.
- **TC-U3** (DK1/AC7 precedence): **Given** trusted list `[project-local active:false,
  user-global active:true]` **When** resolved **Then** 0 (project-local wins); and given only
  user-global `false` → 0.
- **TC-U4** (AC6 no-clobber): **Given** `@existing` holds a user-edited id X and `@starter`
  holds X+Y **When** `merge_seed` **Then** X unchanged, Y appended, `($added,$skipped)=(1,1)`.
- **TC-U5** (merge_seed baseline): **Given** empty `@existing` **Then** all starter added, skipped 0.

### Hook integration — `t/pretooluse-bash-tool-check.t`
- **TC-H1** (AC1 live toggle): **Given** a rule that denies cmd C, `active:false` **When** the
  hook runs on C **Then** allow (exit 0, empty stdout); flip to `active:true`, re-run **Then**
  deny — no process restart.
- **TC-H2** (AC1 zero-rules): **Given** `active:true`, no rules **Then** allow.
- **TC-H3** (AC2/NFR5 fail-open): **Given** settings that are absent / `{}` / malformed JSON /
  a symlink **When** the hook runs **Then** allow in every case.
- **TC-H4** (AC7 true trusted precedence): **Given** user-global `active:true`+rules and
  project-local `active:false` **Then** hook allows (off).
- **TC-H5** (DK1 security-load-bearing): **Given** user-global rules active and a **checked-in**
  `active:false` **Then** hook still **denies** (checked-in `active` ignored — a cloned repo
  cannot silence the user).
- **TC-H6** (F2 documented degradation): **Given** project-local `active:false` then corrupted
  to invalid JSON **Then** hook falls through to active (deny) — proving the degradation is the
  documented deny-safe direction.
- **TC-H7** (NFR1 short-circuit before compile): **Given** a project-local `perl` rule whose
  body would `die` at compile, with `active:false` **When** the hook runs **Then** allow with
  no compile attempted (proves `resolve_active` short-circuits before the compile/match loop).
- **TC-H8** (`--check` consistency): **Given** any layer state **When** `--check` runs **Then**
  its "Effective active" equals the hot-path `resolve_active(trusted_layers(...))` result; per-layer
  `active` shown.

### Helper integration — `t/tool-check-seed.t`
- **TC-S1** (AC6 seed idempotent): **Given** `seed` run twice **Then** identical checked-in file.
- **TC-S2** (AC6 no-clobber report): **Given** a user-edited starter id present **When** `seed`
  **Then** the edit is preserved and the skip is reported.
- **TC-S3** (RMW preserves top-level keys): **Given** checked-in settings with an unrelated
  pre-existing top-level key **When** `seed` **Then** that key survives; only rules change.
- **TC-S4** (AC3 toggle target + security control): **Given** `off` **When** it runs **Then**
  only `settings.local.json` changes, no git-tracked file is modified, and
  `git check-ignore .cwf/tool-check/bash/settings.local.json` reports **ignored**.
- **TC-S5** (FR2 state transitions): **Given** `seed`→`off`→`on` **Then** effective active is
  on→off→on; each idempotent on repeat.
- **TC-S6** (AC8 symlink safety): **Given** a pre-planted symlink at the target file and at a
  parent dir component **When** any write runs **Then** it does not write through the symlink;
  the resulting real file is mode 0600.
- **TC-S7** (FR2 unknown subcommand): **Given** `tool-check-seed bogus` **Then** exit non-zero,
  usage to stderr, **no** file written.
- **TC-S8** (F3 seed ordering ⇒ on): **Given** a prior `off` **When** `seed` **Then** rules
  present in checked-in **and** the project-local `active:false` cleared → effective on.

### Non-functional coverage
- **Performance (NFR1)**: TC-H7 (no compile when inactive).
- **Security (NFR4)**: TC-H5 (clone-suppression closed), TC-S4 (check-ignore control), TC-S6 (symlink writes).
- **Reliability (NFR5)**: TC-H3, TC-H6, TC-S1/S5 (idempotency).

## AC → Test traceability
| AC | Covered by |
|----|-----------|
| AC1 live toggle / zero-rules | TC-H1, TC-H2, TC-U1 |
| AC2 fail-open (absent/empty/malformed/symlink) | TC-H3 |
| AC3 config echo + toggle leaves tracked files clean + ignored | TC-S4, TC-S5 |
| AC4 regex-only, fires/no-ops | TC-S1 (seeded set), TC-H1 |
| AC5 cwf-init decline inert | System/manual (g) |
| AC6 seed idempotent + no-clobber | TC-S1, TC-S2, TC-U4 |
| AC7 project-local overrides (trusted precedence) | TC-H4, TC-U3 |
| AC8 symlink-safe writes, 0600 | TC-S6 |
| AC9 docs + validate + same-commit hash refresh | g checklist + `cwf-manage validate` |

## Test Environment
- Perl **core** + `prove` (TAP); no network, no DB.
- Fixtures via `File::Temp`; hook tests point HOME/root at the temp tree and feed the hook
  JSON on stdin; helper tests run against a temp git repo for the `git check-ignore` assertion.
- Runner: `prove t/tool-check.t t/pretooluse-bash-tool-check.t t/tool-check-seed.t`, then full `prove t/`.

## Validation Criteria
- [ ] All TCs above pass; every AC1–AC9 traced.
- [ ] Full `prove t/` green (no Task-201 regression).
- [ ] `cwf-manage validate` OK with same-commit hash refresh (hook, `ToolCheck.pm`, new helper).

## Decomposition Check
Unchanged: 1 borderline signal (complexity). **Do not decompose.**

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Planned coverage delivered (39 subtests) plus one regression added during exec: TC-S9
(broken symlinked user-global → `off` still exits 0), from the robustness finding.

## Lessons Learned
A test asserting a *negative* (sentinel absent / probe didn't run) needs its positive
control in the same case — TC-H7's first form silently didn't write and would have
passed as a no-op without one.
