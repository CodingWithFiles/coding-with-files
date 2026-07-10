# Resolve tool-check hook paths from git root - Implementation Plan
**Task**: 224 (bugfix)

## Task Reference
- **Task ID**: internal-224
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/224-resolve-tool-check-hook-paths-from-git-root
- **Template Version**: 2.1

## Goal
Implement the `CWF::Validate::Hooks` rooting check, wire it into `cwf-manage validate`, and
correct the bare-relative hook-command example in `stop-hooks-framework.md`, per
`c-design-plan.md` D1–D5.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- `.cwf/lib/CWF/Validate/Hooks.pm` *(new, hashed)* — exports `validate($git_root)`; carries
  the pure predicate `command_is_rooted($command)` as an unexported package sub. Modelled
  line-for-line on `.cwf/lib/CWF/Validate/Agents.pm` (same signature, same violation hashref,
  same `@EXPORT_OK qw(validate)` by-request export).
- `.cwf/scripts/cwf-manage` *(edit, hashed, 0700)* — two lines: a `use CWF::Validate::Hooks ();`
  alongside the eight siblings (currently lines 30-37), and one
  `CWF::Validate::Hooks::validate($git_root),` entry in `cmd_validate`'s composed list
  (currently lines 607-615). No other change; the existing violation print loop
  (lines 623-629) already renders `category/file/field/actual/expected/fix`.
- `.cwf/docs/workflow/stop-hooks-framework.md` *(edit)* — line 164 only:
  `".cwf/scripts/hooks/subagentstop-security-verdict-guard"` →
  `"${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/subagentstop-security-verdict-guard"`.
  **Do not touch lines 115 and 138** — those are prose file-path references, correctly bare.

### Supporting Changes
- `t/validate-hooks.t` *(new)* — TC-1..TC-9 per `c-design-plan.md` §Test cases.
- `.cwf/security/script-hashes.json` *(edit, same commit)* — new `CWF::Validate::Hooks` key
  under the existing `lib` section (mirroring the `CWF::Validate::Agents` entry at lines
  126-129: `path` + `sha256`, **no `permissions` key** — it is a `use`d module, not an
  executable), and a refreshed `sha256` for `.cwf/scripts/cwf-manage` under `scripts`.

*No `- **Deletes**:` line — this task deletes no named symbol.*

## Implementation Steps

### Step 1: Patterns first
- [ ] Re-read `.cwf/lib/CWF/Validate/Agents.pm` end-to-end as the shape to mirror
- [ ] Re-read `read_layer_file` in `.cwf/scripts/hooks/pretooluse-bash-tool-check` — the
      established "degrade a bad file to nothing, never die" read+decode idiom that
      `_read_settings` mirrors
- [ ] Confirm `cmd_validate`'s composed-list shape and the violation print loop

**Reuse considered and rejected** (recorded so it is not re-litigated at exec): `cwf-manage`
already imports `CWF::ArtefactHelpers::read_json_file`, which looks like the natural reader.
It **dies** on both open and parse failure (`ArtefactHelpers.pm:34,39`) — precisely the abort
the no-die guard exists to prevent — and it carries no `-f && !-l` symlink guard. Wrapping it
in `eval` would restore the die-safety it lacks while still missing the symlink check, saving
nothing. Hand-rolling the small guarded read is correct here, not duplication.

### Step 2: Test first (red)
- [ ] Write `t/validate-hooks.t` with TC-1..TC-9
- [ ] **TC-6b must carry a root skip-guard.** It makes a file unreadable with `chmod 0000`,
      but root's effective uid bypasses `-r`, so under root the `open` succeeds, no violation
      is emitted, and the test goes red through no fault of the code. Dev containers and CI
      commonly run as root. Mirror the established precedent at `t/artefacthelpers.t:139-148`
      (also `t/pretooluse-bash-tool-check.t:215-222`):
      ```perl
      SKIP: {
          skip 'root effective uid bypasses -r', 1 if $> == 0;
          # ... chmod 0000, assert one json-parse violation ...
          chmod 0600, $path;   # restore so CLEANUP can unlink
      }
      ```
- [ ] Run it; confirm it fails for the right reason (module absent), not a typo

### Step 3: Minimal implementation (green)
- [ ] Create `.cwf/lib/CWF/Validate/Hooks.pm`:
      - `use strict; use warnings; use utf8;` + `Exporter 'import'`;
        `our @EXPORT_OK = qw(validate);` — **`command_is_rooted` is a plain package sub, not
        exported.** Nothing imports it: `cmd_validate` calls `validate` fully-qualified and
        the tests call `CWF::Validate::Hooks::command_is_rooted(...)` fully-qualified.
        Exporting it would advertise API surface with no importer (`dead-code-audit.md`
        §Plan-time heuristics) and diverge from the `Agents.pm` precedent, which exports
        only `validate`.
      - `command_is_rooted($c)` — pure: return false iff
        `$c =~ m{(?<!\$\{CLAUDE_PROJECT_DIR\}/)\.cwf/}`
      - `_read_settings($abs)` — **called only for a path that already exists.** Returns
        `($decoded, $ok)`; guards `-f && !-l`, `open` failure, and `JSON::PP` decode failure,
        **all** as `$ok = 0`. Gate on `ref $decoded eq 'HASH'`, never on `$@` truthiness
        (§Error-handling idiom).
      - `validate($git_root)` — for each of `.claude/settings.json` and
        `.claude/settings.local.json`:
        1. **`next unless -e $abs;`** — the absence gate lives *here*, before the call
        2. call `_read_settings($abs)`; `$ok == 0` now unambiguously means *present but
           unreadable/undecodable* → one `json-parse` violation
        3. else walk `hooks` → event → group → `hooks[]` → `command`, type-checking every
           level before descent, and emit one `hook-command` violation per offending command

      **The absence gate must not collapse into `$ok`.** `_read_settings` returns `$ok = 0`
      for absent *and* unreadable alike. If an implementer drives the `json-parse` decision
      off `$ok` alone, then every project lacking `.claude/settings.local.json` — the common
      case, since it is gitignored and user-owned — emits a spurious violation, and the
      validator is switched off within a day. Keep the existence check in `validate`.
- [ ] Add the `use` line and the `cmd_validate` entry in `cwf-manage`
- [ ] Run `t/validate-hooks.t` → green

### Step 4: Documentation
- [ ] Fix `stop-hooks-framework.md:164` (line 164 only)
- [ ] Confirm TC-8 now passes (it should have been red until this step)

### Step 5: Hashes and validation (same commit)
- [ ] `sha256sum .cwf/lib/CWF/Validate/Hooks.pm .cwf/scripts/cwf-manage`
- [ ] Pre-refresh verification per `hash-updates.md#pre-refresh-verification`, **per file**:
      `git log --oneline <last-hash-set-commit>..HEAD -- <path>` for `cwf-manage`, confirming
      the only intervening change is this task's. (The new module has no history to verify.)
- [ ] Add/update both entries in `.cwf/security/script-hashes.json`
- [ ] `chmod` `cwf-manage` back to its **recorded** `0700` if the edit bumped it — recorded
      permissions are a ceiling
- [ ] `.cwf/scripts/cwf-manage validate` → OK
- [ ] Full suite: `prove -r t/` → all pass

## Code Changes

### `cwf-manage` — the entire source change (2 lines)
Before:
```perl
use CWF::Validate::Agents           ();
...
        CWF::Validate::Agents::validate($git_root),
    );
```
After:
```perl
use CWF::Validate::Agents           ();
use CWF::Validate::Hooks            ();
...
        CWF::Validate::Agents::validate($git_root),
        CWF::Validate::Hooks::validate($git_root),
    );
```

### `stop-hooks-framework.md:164`
Before:
```json
        "command": ".cwf/scripts/hooks/subagentstop-security-verdict-guard",
```
After:
```json
        "command": "${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/subagentstop-security-verdict-guard",
```

### The predicate (the only novel logic)
```perl
# A .cwf/ path handed to the harness must be rooted at the project dir.
# Fixed-width lookbehind: '${CLAUDE_PROJECT_DIR}/' is 22 chars.
sub command_is_rooted {
    my ($command) = @_;
    return 1 unless defined $command && !ref $command;
    return $command !~ m{(?<!\$\{CLAUDE_PROJECT_DIR\}/)\.cwf/};
}
```
An undefined or non-scalar command is *rooted* by definition (nothing to execute) — the
caller's type check has already skipped it; this is belt-and-braces so the predicate is
total when called directly from tests.

## Test Coverage
**See e-testing-plan.md for complete test plan** — TC-1..TC-9 are specified in
`c-design-plan.md` §Test cases. Split: TC-1/2/3/5/5b call `command_is_rooted` directly
(pure); TC-4/6/6b/7 build a fixture tree and call `validate($fixture_root)`; TC-8/TC-9 are
source assertions against the doc and the generator.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

Gate before marking Finished:
- `prove -r t/` green (including the new file)
- `cwf-manage validate` → OK on the live tree
- `.cwf/scripts/cwf-manage` back at recorded `0700`

## Risks specific to execution
- **Editing a hashed file leaves perms bumped.** `cwf-manage` is recorded `0700`. If the
  edit path bumps it, `validate` fails on a permission violation. Clamp with
  `cwf-manage fix-security` on sight (it is fix-on-sight, never deferred).
- **TC-8 written as a whole-file grep** would fail forever (prose refs at 115/138). The test
  must scope to the `"command": ".cwf/` context. Verified: only line 164 is a command.
- **`PerlConventions` validator polices the new module.** It requires `use utf8;` in every
  file matching `^package\s+CWF::`. The module must carry it or `validate` fails — which is
  the intended behaviour, but would be a confusing self-inflicted red at Step 3.

## Plan Review
Five reviewers (improvements, misalignment, robustness, security, best-practice) plus the
mechanical check. Applied:

- **Robustness — TC-6b false red under root.** `chmod 0000` does not stop root from reading;
  the test needed the `$> == 0` skip guard used at `t/artefacthelpers.t:139-148`. Added.
- **Robustness — absent/unreadable collapse.** `_read_settings` returns `$ok = 0` for both;
  driving the `json-parse` violation off `$ok` alone would fire on every project without a
  (gitignored) `settings.local.json`. The existence gate is now pinned inside `validate`.
- **Misalignment — needless export.** `command_is_rooted` dropped from `@EXPORT_OK`; it has
  no importer and the precedent exports only `validate`.
- **Improvements — reuse dead end recorded** (`read_json_file` dies; unsuitable).

Noted, no change: regex `/x` and `[.]`-over-`\.` style (matches the sibling's style); no
`$VERSION` in the module (matches `Agents.pm`; single-use internal package) — both conscious.

Security review: no findings. The predicate matches `${CLAUDE_PROJECT_DIR}` as a *literal*
and never expands it; the fixed-width lookbehind carries no ReDoS exposure; the reflected
`actual` field reaches a `printf "%s"` **argument**, not a format string.

Mechanical check: 4 `path-advisory` findings, all adjudicated benign — two are files this
task creates (`Hooks.pm`, `t/validate-hooks.t`), one is the slash-separated field list
`category/file/field/actual/expected/fix`, one is a quoted JSON string literal.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Executed as planned, no deviations. `CWF::Validate::Hooks.pm` created (145 lines); `cwf-manage`
gained exactly the two planned lines; `stop-hooks-framework.md:164` corrected (115/138 left
bare, as instructed); `t/validate-hooks.t` written first and confirmed red for the right reason
(module absent). Hashes refreshed in the same commit (`253bc7a`) after a per-file `git log`
check showed no intervening change to `cwf-manage`. Permissions needed no clamping — `cwf-manage`
stayed at its recorded `0700` and the new module at `0600`, matching its `Agents.pm` sibling.
See `f-implementation-exec.md` for the step-by-step record.

## Lessons Learned
The plan's two most valuable paragraphs were both defensive, and both came from plan review
rather than from me: the pinned absence gate (do not drive the `json-parse` violation off
`$ok` alone, or every project without a gitignored `settings.local.json` gets a spurious
violation) and the TC-6b root skip-guard (`chmod 0000` does not stop root). Both would have
shipped as real defects. Writing "reuse considered and rejected" for `read_json_file` also
paid off — two independent changeset reviewers checked that claim and confirmed it rather than
re-proposing the reuse.
