# Resolve tool-check hook paths from git root - Implementation Execution
**Task**: 224 (bugfix)

## Task Reference
- **Task ID**: internal-224
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/224-resolve-tool-check-hook-paths-from-git-root
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan

## Implementation Steps (from d-implementation-plan.md)

Steps 1-5 executed in order. See Actual Results below.

## Actual Results

### Step 1: Patterns first
- **Planned**: Re-read `Agents.pm`, `read_layer_file`, and `cmd_validate`'s composed-list shape.
- **Actual**: All three read. `Agents.pm` confirmed as the shape to mirror (`@EXPORT_OK
  qw(validate)`, `validate($git_root)`, the six-key violation hashref). `read_layer_file`
  (`pretooluse-bash-tool-check:85-95`) confirmed as the guarded read+decode idiom:
  `-e` absence, `-f && !-l`, `open ... or return`, `eval { decode }`, gate on
  `ref $json ne 'HASH'`. `cmd_validate` confirmed at `cwf-manage:603-634`, nine validators
  composed as a flat list, print loop renders `actual` via `printf "%s"`.
- **Deviations**: None. The `read_json_file` reuse dead-end recorded in the plan was not
  re-litigated.

### Step 2: Test first (red)
- **Planned**: Write `t/validate-hooks.t` with TC-1..TC-9; TC-6b carries the `$> == 0` skip
  guard; confirm it fails for the right reason.
- **Actual**: Written; 46 assertions. First run failed with
  `Can't locate CWF/Validate/Hooks.pm in @INC` — the intended red (module absent), not a
  typo. TC-6b guard copied from the `t/artefacthelpers.t:139-148` precedent, restoring
  `chmod 0600` before `CLEANUP`. TC-6c gained its own `skip` for filesystems without
  symlink support.
- **Deviations**: One authoring bug caught before the first run — `$ROOTED` was initially
  written as `'\${CLAUDE_PROJECT_DIR}/…'`, whose literal backslash would have made the
  fixture an invalid JSON escape. Corrected to a plain single-quoted `'${…}'` (no
  interpolation in single quotes, so the `$` is already literal).

### Step 3: Minimal implementation (green)
- **Planned**: Create `CWF::Validate::Hooks` (predicate, guarded `_read_settings`, `validate`
  with the absence gate pinned in `validate` itself); wire two lines into `cwf-manage`.
- **Actual**: Module created at `.cwf/lib/CWF/Validate/Hooks.pm` (145 lines). The absence
  gate `next unless -e $abs;` sits in `validate`, **not** collapsed into `_read_settings`'s
  `$ok`, so `$ok == 0` unambiguously means present-but-unusable. `command_is_rooted` is an
  unexported package sub; only `validate` is in `@EXPORT_OK`. `cwf-manage` gained exactly
  two lines (`use CWF::Validate::Hooks ();` at line 38; the `validate($git_root),` entry in
  `cmd_validate`'s list). 45/46 assertions green — TC-8 correctly still red, awaiting Step 4.
- **Deviations**: None.

### Step 4: Documentation
- **Planned**: Fix `stop-hooks-framework.md:164` only; leave lines 115 and 138 (prose
  file-path references) alone.
- **Actual**: Line 164 rewritten to the rooted form. Lines 115/138 untouched. TC-8 went
  green, which is the proof the assertion is real rather than vacuous — it was red before
  this step and green after, with nothing else changed.
- **Deviations**: None.

### Step 5: Hashes and validation (same commit)
- **Planned**: `sha256sum` both files; per-file `git log` pre-refresh verification; update
  `script-hashes.json`; clamp perms if bumped; `cwf-manage validate` OK; `prove -r t/` green.
- **Actual**:
  - Pre-refresh verification: last hash-set commit is `3da49ca` (Task 223). `git log
    3da49ca..HEAD -- .cwf/scripts/cwf-manage` returns **empty** — no intervening commit
    touched the file, so the working-tree change is solely this task's. The new module has
    no history to verify.
  - `CWF::Validate::Hooks` added under `lib` (path + sha256, **no `permissions` key** — it
    is a `use`d module, not an executable, matching the `Agents.pm` entry). `cwf-manage`
    sha256 refreshed under `scripts`.
  - Permissions needed no clamping: `cwf-manage` remained at its recorded `0700`, and the
    new module is `0600`, matching its `Agents.pm` sibling. Checked, not assumed.
  - `cwf-manage validate` → `[CWF] validate: OK`.
  - `prove -r t/` → **77 files, 1054 tests, all pass.**
- **Deviations**: None.

### Post-review fix
The best-practice reviewer flagged an unchecked `close` on a **write** handle in the test's
`write_file` fixture helper (`io.md` 129/130 — the check matters most for writes; read
handles are explicitly excused). Fixed: `print ... or die` / `close ... or die`. Suite
re-run green. The reviewer's other finding (regex omits `/x`, uses `\.` over `[.]`) was
**not** actioned — it is the conscious style-match with the sibling `Agents.pm` already
recorded in `d-implementation-plan.md` §Plan Review.

## Blockers Encountered

None.

## Security Review

**State**: no findings

I have reviewed the complete changeset for Task 224 implementation-exec. My analysis by threat category follows.

## Review

The reviewable code surface is small: a new validator module `.cwf/lib/CWF/Validate/Hooks.pm`, a two-line wiring change in `.cwf/scripts/cwf-manage`, a one-line doc correction in `stop-hooks-framework.md`, a new test `t/validate-hooks.t`, plus the hash refresh, BACKLOG entry, and the a–j task-doc markdown. The task is itself a security-hardening change — it enforces that hook commands are rooted at `${CLAUDE_PROJECT_DIR}/` so they cannot fail open from a subdirectory.

**(a) Bash injection / unsafe command construction.** The new module constructs no shell commands: no `system`, no backticks, no `qx`. It only opens files and decodes JSON. `cwf-manage` gains a `use` line and one list entry — no command construction. Clean.

**(b) Perl helpers consuming git/user output without `-z` / input validation.** The module never shells out to git; it takes `$git_root` as a plain argument and reads two fixed config paths. `_read_settings` opens `<:raw`, slurps, and decodes with `JSON::PP->new->decode` inside `eval`, gating on `ref $decoded eq 'HASH'` rather than `$@` truthiness (avoiding the false-but-defined-`$@` false-negative). Every level of the `hooks` tree is type-checked (`ref eq 'HASH'`/`'ARRAY'`) before descent, so a malformed user-editable tree degrades to zero violations, never a die. The `-f && !-l` guard refuses a symlinked settings file. Robust and idiomatic. Clean.

**(c) Prompt injection via user-supplied strings.** The violation `actual` field echoes a hook `command` verbatim from settings files — and `.claude/settings.local.json` is user-owned and gitignored, so this is untrusted reflected data. I traced its sink: `cwf-manage:628` renders it as `printf "  Actual:   %s\n", $v->{actual}` — a data argument against a fixed `%s` format, not a format string, so there is no format-string injection, and the output lands on the human-facing `cwf-manage validate` stdout, not back into agent context. The design (`c-design-plan.md` §"`actual` is an untrusted display string") already identifies this and the constraint that the value must never be re-piped into agent context or re-executed. Handled correctly.

**(d) Unsafe environment-variable handling.** The predicate matches `${CLAUDE_PROJECT_DIR}` as a literal string and never expands it; the module reads no environment variables. No env var reaches a path/`chmod`/`rm`/`open` sink. Clean.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** Two observations, both benign and worth recording rather than actioning:
- The predicate regex `m{(?<!\$\{CLAUDE_PROJECT_DIR\}/)\.cwf/}` uses a fixed-width lookbehind and carries no unbounded quantifier — no ReDoS exposure. Safe as written; audit any future variant that introduces a variable-length alternation ahead of the lookbehind.
- `_read_settings` slurps the whole file into memory and `JSON::PP` decodes with default depth limits. Safe here because both scan targets are small local config files read by the operator's own `cwf-manage` — no privilege boundary is crossed. Audit future reuse of this read idiom against attacker-sized or attacker-nested inputs, where an explicit `max_size`/`max_depth` would matter.

Per the review boundary, I did not re-verify the SHA256 refresh in `script-hashes.json` or file permissions — those are `cwf-manage validate`'s deterministic responsibility, not this reviewer's.

No actionable security concerns. The change is defensive, mirrors the established `CWF::Validate::Agents` precedent, and the one untrusted-data flow is correctly contained.

```cwf-review
state: no findings
summary: Hook-rooting validator; no shell/git/env sinks, untrusted `actual` reaches printf as a %s argument (safe), regex has no ReDoS.
```

## Best-Practice Review

**State**: findings

I've read the changeset and the applicable Perl best-practice sources. The Go and Postgres sources listed in `best-practice-context-implementation-exec.out` are not applicable — this changeset is entirely Perl (a new validator module `.cwf/lib/CWF/Validate/Hooks.pm`, its test `t/validate-hooks.t`, a one-line `cwf-manage` wiring change, a doc fix, and CWF workflow artefacts). I assessed the Perl code against `error-handling.md`, `regular-expressions.md`, and `io.md`.

## What I checked and concluded

**Error handling — well aligned, with a justified constraint-driven divergence.** `_read_settings` catches `JSON::PP` decode failure with `eval` and gates on the *result* (`return (undef, 0) unless ref $decoded eq 'HASH'`), never on `$@` truthiness. That is exactly the falsy-error/`$@`-clobbering mitigation `error-handling.md` guideline 184 prescribes. The chapter's headline drift note ("prefer native `try`/`catch` or `Try::Tiny` over raw `eval`") is not honoured, but the design (`c-design-plan.md` §Error-handling idiom) explicitly rejects both — `Try::Tiny` is non-core and native `try` needs 5.34+, colliding with CWF's core-only/system-Perl constraint. Given that constraint the safe-`eval` form is the correct realisation, and the module never returns silently on failure (it emits a `json-parse` violation), so the throwing philosophy (171/175) is respected within the established `CWF::Validate::*` return-a-violation-list contract. Not a divergence I'd act on.

**Deliberate no-die posture is sound.** The module returns violation hashrefs rather than throwing, and degrades every bad-file path (missing/unreadable/symlink/malformed) to a `json-parse` violation. `error-handling.md` 175 "When not" and the sentinel carve-out cover this — a die here would abort the eight sibling validators. The `-f && !-l` symlink guard and three-arg lexical `open my $fh, '<:raw', $abs or return (undef, 0)` satisfy `io.md` 125/126/128/129. Reading raw bytes then `JSON::PP`-decoding is correct (JSON is a byte format); the `:raw` layer is not a violation of the text-encoding rule (128½).

## Findings (all minor / advisory)

1. **Regex omits `/x` and uses `\.` rather than `[.]`** — `.cwf/lib/CWF/Validate/Hooks.pm:84`, predicate `m{(?<!\$\{CLAUDE_PROJECT_DIR\}/)\.cwf/}`. `regular-expressions.md` 147 ("always use `/x`", Perl::Critic `RequireExtendedFormatting`) and 155 (prefer `[.]` to `\.`, `ProhibitEscapedMetacharacters`) both diverge here. `d-implementation-plan.md` §Plan Review records this as a conscious choice to match the sibling `Agents.pm` style (Integration-beats-perfection). No ReDoS exposure — the lookbehind is fixed-width with no unbounded quantifier, consistent with 169. Justified, but it is a divergence from the cited source.

2. **`write_file` closes a write filehandle without checking the result** — `t/validate-hooks.t:415` (`close $fh;` after `print {$fh} $content`). `io.md` 129 ("never open, close, or print without checking the result") and 130 (the check "matters most for *writes*") both apply to a write handle. The read-handle `close $fh` in `_read_settings` is *not* a finding — `io.md` 130 "When not" explicitly excuses read handles. This one is write-side, in test-fixture code, so low stakes, but it is a genuine divergence. (The `print {$fh}` brace form at the same site correctly follows 136.)

Everything else — the `do { local $/; <$fh> }` slurp in TC-9 (`io.md` 133), the `'<:encoding(UTF-8)'` layers on the source-assertion reads (128½), and the checked `open ... or die` calls throughout the test — matches the sources. Both findings are stylistic/minor and one is explicitly justified in the task's own plan; the user decides whether either is worth acting on.

```cwf-review
state: findings
summary: Two minor Perl-best-practice divergences (regex missing /x and [.] per regular-expressions.md 147/155; unchecked write-handle close in test per io.md 129/130); one is a documented conscious choice. Go/Postgres sources not applicable.
```

**Disposition**: finding 2 fixed (see §Post-review fix). Finding 1 accepted as the documented
conscious choice.

## Improvements Review

**State**: no findings

I've reviewed the changeset against the improvements focus. Here's what I checked and concluded.

## What the changeset adds

The substantive new code is `.cwf/lib/CWF/Validate/Hooks.pm` (145 lines), wired into `cwf-manage`'s `cmd_validate` via one `use` line and one call. The rest is wf-step docs, a BACKLOG entry, a new test file (`t/validate-hooks.t`), the doc fix in `stop-hooks-framework.md`, and the corresponding hash refreshes.

## Reuse assessment

The new module mirrors the existing `CWF::Validate::Agents` precedent closely — same `@EXPORT_OK qw(validate)` by-request export, same `{category, file, field, actual, expected, fix}` violation hashref, same "resolve target, walk, emit violations" shape, and it slots into the existing `cmd_validate` composed list and print loop with no changes to the aggregation/exit logic. That is the right existing pattern to extend, and the wiring is minimal (two lines in `cwf-manage`), so the result ships with about as few changes as this kind of validator can.

I looked specifically for a reusable settings-reader the module could have called instead of hand-rolling `_read_settings`:

- `CWF::ArtefactHelpers::read_json_file` — *dies* on both open and parse failure and carries no `-f && !-l` symlink guard, so it is unsuitable for the "degrade, never die" requirement (a die would abort the eight sibling validators). The plan (`d-implementation-plan.md` Step 1) already records this dead-end.
- The `read_settings`/`read_layer_file` guarded read+decode idioms it says it mirrors live in *scripts* (`cwf-claude-settings-merge` and `pretooluse-bash-tool-check` at line 85), not in an importable lib module. Reusing them would require extracting a shared reader into a lib and editing a second hash-tracked file to remove a ~10-line, two-site duplication — below the Rule of Three and net-negative on risk. The existing codebase already tolerates this per-validator pattern (`Config.pm`, `Security.pm` each roll their own `eval { decode_json }`), so `_read_settings` follows precedent rather than introducing avoidable new duplication.

I also checked the D1 predicate against the generator's existing `prune_stale_relative_cwf_hooks` detector. These are deliberately different (narrow anchored-equality to drive a *rewrite* vs broad substring-lookbehind to drive a *report*), and the design (`c-design-plan.md` D1) justifies why neither should adopt the other's predicate. That is a reasoned distinction, not a duplicate.

Nothing in the diff re-adds an existing helper or does the same job with more code than needed. The change reuses the Agents validator scaffold, wires in minimally, and its only hand-rolled piece is constrained by a real "must not die" requirement that no existing importable helper satisfies.

```cwf-review
state: no findings
summary: Extends the existing CWF::Validate::Agents validator pattern with minimal wiring; hand-rolled guarded read is justified (no importable degrade-not-die reader exists) and follows per-validator precedent.
```

## Robustness Review

**State**: no findings

I've now confirmed the precedents the diff claims to mirror. My robustness assessment follows.

## What I checked

The only load-bearing new logic is `CWF::Validate::Hooks.pm` (changeset lines 19–164) plus its test file; the rest of the changeset is a two-line wiring edit into `cwf-manage`, a one-character doc fix, hash-table refreshes, and CWF workflow guide docs (planning/design/testing/exec/retro) that carry no executable robustness surface.

I compared the new module against the two precedents it names:

- `CWF::Validate::Agents` (`.cwf/lib/CWF/Validate/Agents.pm`) — the sibling validator, which *dies* on `open`/`opendir` failure.
- `read_layer_file` in `.cwf/scripts/hooks/pretooluse-bash-tool-check` — the "degrade a bad file to nothing, never die" read+decode idiom.

## Robustness findings

The diff handles its error and edge cases soundly, and in several places deliberately climbs the fragile→anti-fragile spectrum:

1. **Fail-safe read (line 90–99).** `_read_settings` guards `-f && !-l`, `open` failure, `JSON::PP` decode failure, and `ref $decoded eq 'HASH'`, collapsing every failure to `(undef, 0)` and never dying. This is a conscious improvement over the `Agents.pm` precedent, which dies on `open`. The design rationale (a die would abort the eight sibling validators; `settings.local.json` is user-owned with machine-specific perms) is correct and the divergence is the more robust choice.

2. **Absence gate correctly separated from error (line 107–113).** `validate` keeps `next unless -e $abs` distinct from the `$ok == 0` json-parse path. Collapsing the two — the tempting simplification — would emit a spurious violation on every project lacking the (gitignored, optional) `settings.local.json`. The code resists that trap, and the test at changeset lines 1539–1545 (TC-7) pins it.

3. **Type-check before descent at every tree level (`_scan_hooks`, lines 121–144).** `hooks` → event → group → `hooks[]` → `command` each gets a `ref eq HASH/ARRAY` or `defined && !ref` guard before use. A malformed user-edited tree is skipped, never fatal. TC-7b (changeset 1547–1565) exercises seven distinct malformed shapes.

4. **Total predicate (`command_is_rooted`, lines 81–85).** `undef` and non-scalar inputs return "rooted" rather than warning/dying under `use strict; use warnings`, keeping the pure function safe when called directly from tests.

5. **Test suite defends the degradation paths, not just the happy path.** TC-6/6b/6c cover malformed JSON, unreadable file, and symlink refusal; TC-6b carries the `$> == 0` root skip-guard (changeset 1515–1525) so root's `-r` bypass does not produce a false red in containerised CI. This is the correct handling of a real environmental edge case.

## One advisory observation (not a finding)

The absence gate uses `-e $abs`, which follows symlinks. A *broken* symlink at `.claude/settings.json` (dangling target) therefore resolves as absent and is silently skipped, whereas an intact symlink is deliberately refused with a `json-parse` violation (TC-6c). There is a slight asymmetry between "symlink is refused" and "broken symlink reads as absent". I am not raising this as a finding because (a) it degrades safely — no crash, no wrong-way-fragile break — and (b) it is consistent with the established `read_layer_file` precedent, which likewise treats `-e` as its absence test. Correctness ordering (correct > maintainable > performant) is respected throughout; there is no performance-driven shortcut and no inverted priority.

The changeset was fully readable and the review completed. The executable surface handles its errors and edge cases soundly and leans anti-fragile.

```cwf-review
state: no findings
summary: Hooks validator degrades-not-dies on bad settings, type-checks every tree level, separates absence from error; one benign symlink/-e asymmetry noted as advisory only.
```

## Misalignment Review

**State**: no findings

I have enough to assess misalignment. Here is my review.

## What I checked

The changeset adds a new validator, `CWF::Validate::Hooks`, that flags CWF hook commands in `.claude/settings.json`/`.claude/settings.local.json` that are not rooted at `${CLAUDE_PROJECT_DIR}/`. I checked the new module against the project's existing abstractions and conventions:

1. **Validator module pattern.** `/home/matt/repo/coding-with-files/.cwf/lib/CWF/Validate/Hooks.pm` mirrors the established `CWF::Validate::Agents` precedent precisely: `use strict; use warnings; use utf8; use Exporter 'import';`, `our @EXPORT_OK = qw(validate)`, a `validate($git_root)` entry point, and the exact same violation hashref shape (`category, file, field, actual, expected, fix`). It is one module per fail-open footgun, consistent with `Agents.pm`.

2. **`cmd_validate` composition.** The wiring in `/home/matt/repo/coding-with-files/.cwf/scripts/cwf-manage` adds `use CWF::Validate::Hooks ();` alongside the eight sibling imports and one `CWF::Validate::Hooks::validate($git_root),` entry in the flat composed list — matching how every existing validator is registered. The violation keys the module emits line up exactly with the `printf` loop at `cwf-manage:625-631`.

3. **JSON read idiom.** `_read_settings` reuses the degrade-to-nothing-never-die read+decode idiom from `read_layer_file` in `pretooluse-bash-tool-check` (`-f && !-l` guard, guarded `open`, `eval`-wrapped decode gated on `ref eq 'HASH'`), rather than inventing a new one. The plan explicitly considered and rejected reusing `CWF::ArtefactHelpers::read_json_file`; I verified that claim — `read_json_file` (`ArtefactHelpers.pm:31-41`) dies on both open and parse failure and has no symlink guard, so it is genuinely unsuitable for a validator that must not abort its siblings.

4. **The one deliberate divergence.** Unlike `Agents.pm`, which dies on `open`/`opendir` failure, `Hooks.pm` degrades a bad file to a `json-parse` violation. This is a considered divergence, documented in both `c-design-plan.md` (§Data Flow step 3) and the module header, with a codebase precedent (`read_layer_file`). It is justified (a user-owned `settings.local.json` with machine-specific permissions must not kill the other eight validators), so it is alignment-with-intent, not reinvention.

5. **Conventions.** `JSON::PP` is core (no new dependency); the test `t/validate-hooks.t` uses `Test::More` + `File::Temp` + `done_testing` matching every sibling in `t/`, and carries `use strict; use warnings; use utf8;`. The doc fix touches only the one stale registration example, the hash refresh is in the same commit per `hash-updates.md`, and the new lib module carries no `permissions` key (matching the `Agents.pm` precedent for `use`d modules).

## Conclusion

The changeset reuses the project's existing validator abstraction, the established violation-hashref contract, the `cmd_validate` composition pattern, and the degrade-not-die read idiom rather than reinventing any of them. The single divergence from the nearest precedent (`Agents.pm`'s die-on-error) is intentional, documented, and backed by its own in-repo precedent. No misalignment findings.

```cwf-review
state: no findings
summary: New CWF::Validate::Hooks reuses the Validate::* module pattern, violation-hashref contract, cmd_validate composition, and the degrade-not-die read idiom; the sole divergence from Agents.pm is intentional and precedented.
```

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed (N/A — bugfix has no b phase)
- [x] All design guidance in c-design-plan.md followed (D1–D5)
- [x] No planned work deferred without user approval
- [x] If work deferred: Follow-up task created and linked (nothing deferred)

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Implementation was a single clean green run because the plan had already absorbed five reviewer
findings. The one thing execution added on its own was catching, before the first test run, that
`$ROOTED` had been written as `'\${CLAUDE_PROJECT_DIR}/…'` — a literal backslash that would have
made every JSON fixture an invalid escape and sent every integration test down the `json-parse`
path, passing for the wrong reason. Fixture data deserves the same scrutiny as the code it feeds.
