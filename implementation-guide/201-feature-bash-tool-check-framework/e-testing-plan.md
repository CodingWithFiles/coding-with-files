# Bash tool-check framework - Testing Plan
**Task**: 201 (feature)

## Task Reference
- **Task ID**: internal-201
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/201-bash-tool-check-framework
- **Template Version**: 2.1

## Goal
Validate the framework's FRs/ACs: matching + guidance, three-layer merge,
repeat-bypass, fail-open under every failure mode, the Perl trust boundary, and
the install/upgrade gitignore wiring.

## Test Strategy
### Test Levels
- **Unit** (`t/tool-check.t`): pure `CWF::ToolCheck` policy — merge, override,
  matching, `decide_repeat`, provenance drop, compile-failure handling. No git,
  no live hook; `Test::More` + tempdir, mirroring `t/planning-guard.t`.
- **Integration / system** (`t/pretooluse-bash-tool-check.t`): the hook driven
  end-to-end via crafted stdin JSON, with `$HOME` and the state dir pointed at
  tempdirs. Mirrors `t/pretooluse-planning-write-guard.t`.
- **Regression**: `t/cwf-claude-settings-merge.t`, `t/installmanifest-integrity.t`,
  and `cwf-manage validate` must stay green after the new hook+lib+manifest edits.
- **Acceptance**: the no-op-when-no-rules dogfood check + `--dry-run` registration
  check from the implementation plan.

### Coverage Targets
- **Critical paths (100%)**: deny-with-guidance, allow-on-no-match, repeat-bypass
  state machine, the entire fail-open matrix, the checked-in `perl`-drop, and the
  never-`re 'eval'` guarantee. These are correctness/security-bearing.
- **Edge cases**: duplicate-id, absent-id override, over-cap command, malformed
  session_id, missing/corrupt state, per-layer malformed/symlinked files.
- **Regression**: existing suite unchanged.

## Test Cases

### Functional — lib (unit)
- **TC-1 Merge precedence (AC2)**
  - **Given** rules in all three layers, a shared id overridden in project-local,
    and a brand-new id added in the checked-in layer.
  - **When** `merge_rules` runs.
  - **Then** order is user-global → checked-in → project-local by first-seen
    position; the override replaces fields in place (position preserved); the new
    id is appended.
- **TC-2 Disable + hand-errors (AC2)**
  - **Given** an `enabled:false` entry for a lower-layer id; a duplicate id within
    one layer; an override of an id present in no layer.
  - **When** `merge_rules` runs.
  - **Then** the disabled id is absent from the eval list; duplicate-within-layer
    resolves last-in-doc-order; the absent-id override is a silent no-op (no die).
- **TC-3 Provenance-keyed Perl drop (FR7e / security)**
  - **Given** identical `perl` rules tagged `checked-in`, `user-global`,
    `project-local`; and a rule whose JSON *content* claims a different origin.
  - **When** `load_layer` runs per provenance.
  - **Then** the `checked-in` `perl` rule is dropped before any compile; the other
    two are kept; provenance is taken from the arg, never from content.
- **TC-4 PCRE match + no code-eval (FR2 / FR7b)**
  - **Given** a data `regex` rule, and a pattern containing `(?{ system(...) })`.
  - **When** `rule_matches` evaluates each against a command.
  - **Then** the data regex matches as expected; the `(?{...})` pattern does NOT
    execute (dies → caught → no-match), proving `re 'eval'` is never enabled.
- **TC-5 Over-cap + decide_repeat truth table**
  - **Given** a >64 KB command; and the four `(matched, last==cur)` combinations.
  - **When** `rule_matches` / `decide_repeat` run.
  - **Then** over-cap ⇒ no-match; `decide_repeat` returns deny / bypass / allow
    matching the documented 2×2 + no-match row.
- **TC-6 compile_perl resilience**
  - **Given** a syntactically broken `perl` string.
  - **When** `compile_perl` runs.
  - **Then** it returns undef and does not die.

### Functional — hook (integration/system)
- **TC-7 Deny with verbatim guidance (FR1 / FR7c)**
  - **Given** a project-local rule matching `sed -n`.
  - **When** a PreToolUse Bash event for `sed -n '1,5p' f` is piped to the hook.
  - **Then** stdout is the deny JSON with `permissionDecisionReason` = the rule's
    `guidance` verbatim; the reason contains no part of the command; exit 0.
- **TC-8 Allow on no match (FR1)**
  - **Given** the same rule set.
  - **When** a non-matching command event is piped.
  - **Then** empty stdout, exit 0.
- **TC-9 Repeat-bypass state machine (FR4 / AC3)**
  - **Given** a temp `$HOME` + state dir; rule matching X.
  - **When** X is piped (call 1), X again (call 2), then Y, then X (call 4).
  - **Then** call 1 denies; call 2 emits empty stdout (bypass); call 4 denies
    again (the intervening Y reset the streak).
- **TC-10 Malformed session_id (FR7d)**
  - **Given** a session_id containing `../` or `/`.
  - **When** a matching command is piped twice.
  - **Then** no state file is written under the dir; the command is denied both
    times (never bypasses); no path escapes the state dir.
- **TC-11 No config ⇒ no-op (FR5)**
  - **Given** no rule files in any layer.
  - **When** any command event is piped.
  - **Then** empty stdout, exit 0 — identical to the hook being absent.

### Non-Functional

- **Security (FR7) — covered by TC-3, TC-4, TC-7, TC-10**, plus:
  - **TC-12 State-file symlink safety**: a pre-planted `<sid>.last` symlink in the
    state dir is not followed (temp-file + atomic rename); the dir is `0700`.
- **Reliability / fail-open (FR5, NFR5) — TC-13 matrix**: each of {bad-JSON stdin,
  unreadable layer file, symlinked layer file, invalid regex, dying `perl`,
  hanging `perl` at compile-time, hanging `perl` at runtime, over-cap command,
  missing state, corrupt state} ⇒ empty stdout + exit 0. One sub-case per row.
- **Performance / DoS (NFR1) — TC-14 ReDoS bound**: a known-pathological pattern +
  input run through the REAL hook path under an external `timeout 5` (the
  registration SIGKILL bound). **Then** the call returns within the bound and
  fails open — proving the guaranteed bound holds even where the in-process alarm
  may not pre-empt (robustness F1). Asserts total wall-clock, not just that the
  alarm fired.
- **Usability (NFR2) — TC-15 `--check`**: `--check` over a layer set containing a
  dropped checked-in `perl` rule and an overridden id lists both and prints the
  effective ordered list; exits 0 when all parse, **non-zero when a layer fails to
  parse** (robustness F3). Human-facing only.

### Install / upgrade (FR6)
- **TC-16 gitignore idempotency**: covered by the existing `cwf-apply-artefacts`
  / `installmanifest-integrity` suites once the new `lines` entry is present —
  assert fresh-apply adds `.cwf/tool-check/*/settings.local.json` and a re-apply
  adds no duplicate. Extend `t/cwf-apply-artefacts.t` only if the new line is not
  already exercised by its line-additive cases.

## Test Environment
### Setup
- POSIX + system Perl (core modules only: `Test::More`, `JSON::PP`,
  `Digest::SHA`, `Time::HiRes`, `POSIX`, `File::Temp`, `File::Path`).
- Tempdirs for `$HOME` (user-global layer), repo root (project layers), and
  `${TMPDIR}` (state dir) so no real config or real `~/.cwf/` is touched.
- The hook is invoked directly (stdin pipe) — no Claude Code registration needed
  for the test path. TC-14 wraps the invocation in an external `timeout`.
- No database involved.

### Automation
- `prove t/tool-check.t t/pretooluse-bash-tool-check.t` plus the regression set;
  runs in the same manual/`prove` harness as the rest of `t/`. No CI change.

## Validation Criteria
- [ ] All TC-1…TC-16 pass.
- [ ] Critical paths (deny/allow, bypass, fail-open matrix, perl-drop,
      no-`re 'eval'`) at 100%.
- [ ] `cwf-manage validate` → OK; `t/cwf-claude-settings-merge.t`,
      `t/installmanifest-integrity.t` green.
- [ ] TC-14 proves the DoS bound under the external timeout.
- [ ] No-config no-op confirmed (TC-11).

## Decomposition Check
- [ ] Time >1 week? No. — [ ] People >2? No. — [x] Complexity (covered above) —
  [ ] Risk isolated? handled. — [x] Independence. **Proceed as one task.**

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned cases (TC-1…TC-16) were authored and executed; every one passed. TC-16 was
covered by the existing `t/cwf-apply-artefacts.t` + `t/installmanifest-integrity.t` suites
rather than a new test, since the gitignore-line behaviour already had coverage.

## Lessons Learned
Authoring the plan test-first (TDD in implementation-exec) caught two real defects before
the testing phase. The fail-open matrix and ReDoS-bound cases needed an external `timeout`
harness to assert the guaranteed bound, not just the best-effort in-process alarm.
