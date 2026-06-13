# Bash tool-check framework - Implementation Plan
**Task**: 201 (feature)

## Task Reference
- **Task ID**: internal-201
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/201-bash-tool-check-framework
- **Template Version**: 2.1

## Verified Integration Surfaces (measured this task)
- **`.cwf/security/script-hashes.json` `scripts` section is the single driver**:
  `cwf-claude-settings-merge` walks it (`:143`) → Bash allowlist + hook
  registration; `cwf-manage validate` checks the same entries for sha256 +
  recorded permissions. Hooks carry a `permissions` key (`0500`); libs carry NO
  `permissions` key (regular `100644`, per [[feedback_hashed_script_working_perms]]).
- **`install-manifest.json`** holds only non-script artefacts; the one gitignore
  line is added to the `gitignore-entries` `lines` array there (`:10-14`).
- **`.cwf/docs/`** is essentially not hash-tracked (1 lone exception) → the new
  schema doc needs no hash entry.
- **`t/cwf-claude-settings-merge.t`** builds its OWN fixture manifest (`mk_entry`),
  not the real `script-hashes.json` → adding the real hook does NOT touch its
  golden. (Confirmed `:114`.)
- **Lib test pattern**: `Test::More` + `use lib "$FindBin::Bin/../.cwf/lib"` +
  tempdir fixtures (mirror `t/planning-guard.t`).

## Conventions (both new Perl files)
`#!/usr/bin/env perl`, `use strict; use warnings; use utf8;` (per
`docs/conventions/perl.md`); core modules only. The schema doc gives a one-line
nod to `.cwf/docs/conventions/tmp-paths.md` for the `-tool-check/` state dir
(per-session runtime state, a namespacing-rule extension of the `-task-<num>`
form). `compile_perl` is invoked BY the hook inside the alarm window (the lib
stays pure/alarm-free), which is why it is a distinct helper.

## Files to Create
1. **`.cwf/lib/CWF/ToolCheck.pm`** — pure policy (no I/O, no git):
   - `load_layer($decoded, $provenance)` → normalised rule list tagged with
     `$provenance` (`user-global` | `checked-in` | `project-local`). Drops
     `perl` rules whose provenance is `checked-in` **here, before any compile**.
     Provenance is the caller-supplied arg only — never read from rule content.
   - `merge_rules(\@layers)` → single ordered list (user-global → checked-in →
     project-local). New `id` appended (keeps first-seen eval position); repeated
     `id` in a later layer replaces fields in place; `enabled:false` removes the
     id; duplicate id within a layer → last-in-doc-order wins; disable/override
     of an absent id → no-op.
   - `compile_perl($code_string)` → coderef or undef (compiles under guarded
     `eval`, returns undef on failure — caller drops + fails open). Caller is
     responsible for arming the alarm around this AND the invocation.
   - `rule_matches($rule, $cmd, $coderef_or_undef)` → bool. Regex branch does a
     data-only `$cmd =~ /$pat/` (NEVER `use re 'eval'`); over-cap (>64 KB) and
     undef coderef → no-match.
   - `decide_repeat($matched, $last_denied_hash, $cur_hash)` → one of
     `allow` / `deny` / `bypass` per the 2×2 truth table (match? × equal-hash?)
     plus the no-match→allow+clear row. (Truth-table form, not "5 cases".)
2. **`.cwf/scripts/hooks/pretooluse-bash-tool-check`** — thin I/O wrapper, whole
   body in `eval` (any exception ⇒ empty stdout, exit 0). chmod `0500`.
   - Header directives: `# cwf-hook-event: PreToolUse`, `# cwf-hook-matcher: Bash`.
   - Reads stdin JSON → `tool_input.command`, `session_id`, `cwd`. Non-Bash
     `tool_name` or absent command ⇒ exit 0.
   - Locates 3 layer files (`$HOME/.cwf/...`, `$root/.cwf/...` ×2 via
     `find_git_root`); each absent/unreadable/symlink/bad-JSON ⇒ that layer
     contributes nothing (per-layer degrade).
   - Merges via lib; arms ONE `Time::HiRes::alarm` (2 s) around the whole
     compile+match loop, `$SIG{ALRM}` ⇒ fail-open; first-match-wins. **The 2 s
     alarm is BEST-EFFORT** — in-process `SIGALRM` may not pre-empt a catastrophic
     backtrack mid-match on some Perl builds. The **correctness-bearing** bound is
     the registration `timeout => 5` SIGKILL from `cwf-claude-settings-merge`: a
     hook killed for running long does not block the call (fail-open at the
     harness layer). The design's fork/SIGKILL alternative is NOT adopted — the
     harness kill already provides the guaranteed bound, so an in-hook fork would
     be redundant cost on the hot path. (Robustness F1.)
   - **State ordering** (robustness F2): read state → run the bounded match →
     write/clear state ONLY after a clean decision. Never write-then-match (that
     opens a stale-bypass window). If the harness SIGKILLs mid-match, no state is
     written ⇒ "not a repeat" on the next call (NFR5) — fails open.
   - Repeat-state: sanitise `session_id` (`^[A-Za-z0-9._-]{1,200}$` else no
     state); dir `${TMPDIR:-/tmp}/<dashified-repo>-tool-check/` `mkdir -m 0700`;
     file `<sid>.last` = hex sha256 of last denied command, written via
     **temp-file-in-dir + atomic rename** (NOT `open '>'` onto a possibly-symlink
     `<sid>.last`), mode 0600 (security note 1).
   - Emits deny JSON (reason = `guidance` verbatim) or empty stdout. Hot path
     SILENT.
   - `--check [file]` mode (out of hot path, **human-facing diagnostic only —
     never pipe its output back into agent context**, security note 2): load+merge,
     print dropped/invalid/overridden rules + the effective ordered list. Exit 0
     when all layers parse; **non-zero if any layer fails to parse** so a user can
     detect a broken rule file in a script (robustness F3).
3. **`.cwf/docs/tool-check-rules.md`** — schema, one worked `regex` + one worked
   `perl` example, the per-layer trust table, precedence/override/disable rules,
   `~/.cwf/` placement, `--check` usage. (No active rules shipped.)
4. **`t/tool-check.t`** — lib unit tests (see Test Coverage).
5. **`t/pretooluse-bash-tool-check.t`** — hook end-to-end tests.

## Files to Modify
6. **`.cwf/install-manifest.json`** — add `".cwf/tool-check/*/settings.local.json"`
   to the `gitignore-entries` `lines` array.
7. **`.cwf/security/script-hashes.json`** — add two `scripts` entries: the hook
   (`path`, `permissions: "0500"`, `sha256`) and the lib (`path`, `sha256`, no
   `permissions`). Compute hashes with `sha256sum` (implementation diversity at
   the verifier boundary, per [[feedback_complexity_over_continuity]]). Hash
   refresh is in THIS commit with the file add (per [[hash-updates]]).

## Implementation Steps (TDD: patterns → test → minimal impl → refactor green)
1. **Lib + lib tests first**: write `t/tool-check.t` against the `CWF::ToolCheck`
   contract, then implement `CWF::ToolCheck.pm` to green. Pure, deterministic,
   no live hook needed.
2. **Hook + e2e tests**: write `t/pretooluse-bash-tool-check.t` driving the hook
   with crafted stdin (no registration needed), then implement the wrapper to
   green.
3. **Schema doc** `.cwf/docs/tool-check-rules.md`.
4. **Manifest edits**: gitignore line (install-manifest.json); chmod hook `0500`;
   add hook+lib to script-hashes.json with `sha256sum`-computed hashes.
5. **Validate + full suite**: `cwf-manage validate` (expect OK); `prove` the two
   new tests + `t/cwf-claude-settings-merge.t` + `t/installmanifest-integrity.t`
   (guard against manifest drift).
6. **Dogfood registration check**: confirm `cwf-claude-settings-merge --dry-run`
   reports the new hook under `PreToolUse`/`Bash` and that with no rule files the
   hook is a strict no-op (manual: pipe a sample Bash event → empty stdout).

## Test Coverage
**Lib (`t/tool-check.t`)** — pure:
- merge ordering across 3 layers; override-by-id keeps eval position;
  `enabled:false` removes; duplicate-id-within-layer last-wins; disable/override
  of absent id = no-op (AC2).
- `load_layer` drops `checked-in` `perl` rules and does NOT drop them for the
  other two provenances; provenance taken from arg, not content (security F2).
- `rule_matches`: PCRE fires; `(?{...})` in a config pattern does NOT execute
  (dies → caught → no-match), proving no `re 'eval'`; over-64 KB ⇒ no-match.
- `decide_repeat` full truth table (improvements F4).
- `compile_perl` returns undef on syntax error (no die).

**Hook (`t/pretooluse-bash-tool-check.t`)** — e2e via stdin:
- match ⇒ deny with `guidance` verbatim; reason never contains the command
  (FR7c); no-match ⇒ empty stdout/exit 0.
- repeat-bypass across two invocations sharing a temp `$HOME`/state dir: X→deny,
  X→allow(bypass), then intervening Y resets so X→deny again (AC3).
- session_id with `..`/`/` ⇒ no state written, never bypasses (FR7d).
- **fail-open matrix** (AC4): bad-JSON stdin; unreadable layer; symlinked layer;
  invalid regex; dying `perl`; **hanging `perl` (compile-time AND runtime) bounded
  by alarm**; over-cap command; missing/corrupt state — each ⇒ empty stdout/exit 0.
- **ReDoS demonstration**: a known-pathological pattern + input. The test must
  prove the GUARANTEED bound holds on a build where the alarm may NOT pre-empt —
  i.e. exercise the real hook path under the harness `timeout => 5` SIGKILL (or
  an equivalent external timeout), asserting the call is bounded and fails open,
  not merely that the in-process alarm fired (robustness F1).
- no config files anywhere ⇒ no-op (FR5).
- `--check` lists a dropped checked-in `perl` rule and an overridden id.

## Validation Criteria
- [ ] `prove t/tool-check.t t/pretooluse-bash-tool-check.t` green.
- [ ] `t/cwf-claude-settings-merge.t`, `t/installmanifest-integrity.t` still green.
- [ ] `cwf-manage validate` → OK (hook `0500`, lib `100644`, hashes match).
- [ ] `--dry-run` settings-merge shows the hook registered under PreToolUse/Bash.
- [ ] With no rule files, a sample Bash event yields empty stdout (no-op).
- [ ] ReDoS test proves the total bound < harness timeout.

## Decomposition Check
- [ ] Time >1 week? No. — [ ] People >2? No. — [x] Complexity 3+ concerns (lib,
  hook, manifest) but tightly coupled. — [ ] Risk isolated? handled. —
  [x] Independence: separable but coupled. **Proceed as one task.**

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned steps executed. Manifest edits were correct: `install-manifest.json` carries
only the gitignore `lines` array, and `script-hashes.json` is the sole hook-registration
driver — both updated in-task with the new hook/lib entries and the manifest self-hash refresh.

## Lessons Learned
Editing a hash-tracked file (`install-manifest.json`) requires refreshing its own sha256 in
the same commit — caught and handled in-task per the hash-updates convention rather than
deferred. The plan's manifest steps were verified against the live schema before relying on them.
