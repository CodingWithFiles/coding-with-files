# Resolve tool-check hook paths from git root - Testing Execution
**Task**: 224 (bugfix)

## Task Reference
- **Task ID**: internal-224
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/224-resolve-tool-check-hook-paths-from-git-root
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

`prove -v t/validate-hooks.t` — **46 assertions, 46 pass, 0 fail, 0 skip**
(TC-6b ran rather than skipped: `$> != 0` on this host.)

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-1  | bare relative `.cwf/` command | unrooted | unrooted | PASS | assertion 1 |
| TC-2  | canonical generated form | rooted | rooted | PASS | assertion 2 |
| TC-3  | rules-inject, prefix mid-string | rooted | rooted | PASS | assertion 3 — guards D1 |
| TC-4  | `permissions.allow` bare pattern | 0 violations | 0 violations | PASS | assertion 9 — guards D2 |
| TC-4b | unrooted command in `hooks` tree | 1 violation, all 5 fields | as expected | PASS | assertions 10-15 |
| TC-5  | absolute path | unrooted | unrooted | PASS | assertion 4 — pins accepted false positive |
| TC-5b | unbraced `$CLAUDE_PROJECT_DIR/` | unrooted | unrooted | PASS | assertion 5 — pins accepted false positive |
| TC-5c | `.cwf` without trailing slash | rooted (not flagged) | rooted | PASS | assertion 6 — pins accepted false negative |
| TC-6  | malformed JSON | 1 `json-parse`, no die | as expected | PASS | assertions 16-18 |
| TC-6b | present-but-unreadable (mode 0000) | 1 `json-parse`, no die | as expected | PASS | assertions 19-21; ran (non-root) |
| TC-6c | symlinked settings file | 1 `json-parse`, refused | as expected | PASS | assertions 22-24 |
| TC-7  | canonical fixture, no `settings.local.json` | 0 violations | 0 violations | PASS | assertions 25-26 — absence gate |
| TC-7b | 7 malformed `hooks` shapes | 0 violations, no die (each) | as expected | PASS | assertions 27-40 |
| TC-8  | doc registers no bare-relative command | no match | no match | PASS | assertion 45 — mutation-verified below |
| TC-9  | generator still emits the literal | present | present | PASS | assertion 46 — mutation-verified below |

Three assertions beyond the plan's enumerated cases were added and pass: predicate totality
for `undef` and a hashref (assertions 7-8), the absent-`.claude/` case (41-42), and
`settings.local.json` being scanned with the violation naming the local file (43-44).

### Mutation verification — proving TC-8 and TC-9 are not vacuous

Two of the plan's validation criteria assert that the source-assertion tests **fail** when
their guarded site regresses. A green test proves nothing on its own here, so each was
verified by mutating the real site, observing red, and reverting:

- **TC-8**: reverted `stop-hooks-framework.md:164` to the bare-relative form →
  `Failed test 'TC-8: …registers no bare-relative .cwf/ command'`, 1/46 failed. Reverted
  with `git checkout --`; suite green again. TC-8 is real.
- **TC-9**: the generator is mode `0500`, so the mutation needed a temporary `chmod u+w`.
  Replaced it with a copy stripped of all 6 occurrences of the `${CLAUDE_PROJECT_DIR}/`
  literal → `Failed test 'TC-9: cwf-claude-settings-merge still emits …'`. Restored via
  `git checkout --`, re-clamped to the **recorded** `0500`, confirmed by `stat`. TC-9 is real.

After both reverts: `git status` clean, `cwf-manage validate` → OK.

### System test — `cwf-manage validate` end-to-end on the live tree

Fixtures prove the module; they cannot prove the **wiring**. `cwf-manage validate` resolves
its own git root internally and cannot be pointed at a tempdir, so this was exercised against
the real `.claude/settings.json` and reverted.

Mutated line 22 (a genuine hook command) to the bare-relative form, leaving line 84 — a
`permissions.allow` entry, `Bash(.cwf/scripts/hooks/stop-stale-status-detector)` — untouched.
This single mutation tests D1 and D2 simultaneously.

```
[HOOKS] .claude/settings.json
  Field:    hook-command
  Actual:   .cwf/scripts/hooks/stop-stale-status-detector
  Expected: a command whose .cwf/ paths are prefixed with ${CLAUDE_PROJECT_DIR}/
  Fix:      Re-run .cwf/scripts/command-helpers/cwf-claude-settings-merge to regenerate the hook registrations.

[CWF] 1 violation(s) found.        (exit 1)
```

**Exactly one** violation — the `permissions.allow` pattern on line 84 was correctly not
flagged (D2 holds end-to-end, not just in the fixture). Restored; `git diff` empty;
`cwf-manage validate` → OK.

*Environment note*: `.claude/settings.json` is a sandbox bind-mount, so `git checkout --` fails
(`unable to unlink old …: Device or resource busy`) and `cp` onto it fails (`Read-only file
system`). The Edit tool writes it successfully. Reverted that way; verified byte-identical via
an empty `git diff`.

### Regression

`prove -r t/` → **77 files, 1054 tests, all pass.** No existing test regressed.

### Non-Functional Tests

- **Security**: asserted by inspection per plan (no test). Confirmed: the predicate matches
  `${CLAUDE_PROJECT_DIR}` as a literal and never expands it; no `system`/backtick/shell-string
  construction; fixed-width lookbehind, no unbounded quantifier, so no ReDoS; `actual` reaches
  `printf` as an **argument** against a fixed `%s` format (`cwf-manage:626`), never as a format
  string. Independently confirmed by the security reviewer below.
- **Reliability**: TC-6 / TC-6b / TC-6c / TC-7b are the reliability suite. Every path by which
  a bad settings file could abort `validate` degrades to a violation. Verified no exception
  propagates in any of the 11 degradation cases (each asserts `is($@, '')`).
- **Usability**: TC-4b asserts `fix` names the remedy (`cwf-claude-settings-merge`) rather than
  describing the problem. The live-tree run above shows the rendered message.
- **Performance**: not applicable, per plan. Two small JSON reads per `validate` invocation.

## Test Failures

None outstanding. The only reds observed were the two **deliberate** mutations above (TC-8,
TC-9) and the expected test-first red in phase `f` (module absent), all resolved.

## Coverage Report

Branch coverage of the critical path, enumerated rather than measured (the plan explicitly
declines a line-coverage percentage for an ~80-line module):

- `command_is_rooted`: both interesting inputs (rooted / unrooted), all three accepted
  imprecisions, and both totality guards (`undef`, non-scalar) — 8 assertions.
- `_read_settings`: all four failure branches (non-regular, symlink, `open` failure, decode
  failure) and the success branch — covered by TC-6/6b/6c and every passing fixture.
- `validate`: absence gate (TC-7), present-but-unusable (TC-6/6b/6c), both settings files
  (assertions 43-44), absent `.claude/` (41-42).
- `_scan_hooks`: every type-check-before-descent guard, via TC-7b's seven malformed shapes
  plus the happy path.

## Validation Criteria (from e-testing-plan.md)
- [x] TC-1..TC-9 pass (TC-6b ran; not root on this host)
- [x] `prove -r t/` green — no regression
- [x] `cwf-manage validate` OK on the live tree
- [x] `t/validate-hooks.t` fails if `stop-hooks-framework.md:164` is reverted — **verified by mutation**
- [x] `t/validate-hooks.t` fails if the generator's prefix literal is removed — **verified by mutation**
- [x] `.cwf/scripts/cwf-manage` at recorded `0700`; hashes refreshed in the same commit (`253bc7a`)

## Security Review

**State**: no findings

I've read the complete changeset (all 1824 lines) and the CWF threat model in `.cwf/docs/skills/security-review.md`. This is the `testing-exec` review, so the changeset is the full branch diff; the load-bearing new artefact for this phase is the test file `t/validate-hooks.t`, layered on top of the already-reviewed module `.cwf/lib/CWF/Validate/Hooks.pm`, the two-line `cwf-manage` wiring, the doc fix, the hash refresh, and the a–j task docs. The task is itself a security-hardening change (it enforces `${CLAUDE_PROJECT_DIR}/`-rooting of hook commands so they cannot fail open from a subdirectory).

My analysis by threat category:

**(a) Bash injection / unsafe command construction.** No shell surface anywhere in the new code. `t/validate-hooks.t` uses only `open`, `chmod`, `symlink`, `tempdir`, `make_path` — no `system`, no backticks, no `qx`. The module constructs no commands. Clean.

**(b) Perl helpers consuming git/user output without `-z` / input validation.** The test never shells out to git; it builds hermetic fixtures under `File::Temp::tempdir(CLEANUP => 1)` and passes `$git_root` as a plain path. `_read_settings` opens `<:raw`, slurps, and decodes with `JSON::PP` inside `eval`, gating on `ref $decoded eq 'HASH'` rather than `$@` truthiness, and every level of the `hooks` tree is type-checked before descent — TC-7b exercises seven malformed shapes and asserts no die. Clean.

**(c) Prompt injection via user-supplied strings.** The violation `actual` field echoes a hook command verbatim from `.claude/settings.{json,local.json}` (the latter user-owned/gitignored). Traced to `cwf-manage:628` `printf "  Actual:   %s\n"` — a data argument against a fixed `%s` format, human-facing stdout, not re-piped into agent context. TC-4b pins `actual` to the verbatim command. Handled correctly; already documented in the design.

**(d) Unsafe environment-variable handling.** The predicate matches `${CLAUDE_PROJECT_DIR}` as a literal and never expands it. Neither the module nor the test reads any environment variable into a path/`chmod`/`rm`/`open` sink. TC-6b's `chmod 0000`/`chmod 0600` and TC-6c's `symlink` operate only on tempdir fixture paths; the real `~/.cwf` and live `.claude/` are never written. Clean.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** Two observations, both benign, recorded not actioned:
- The predicate `m{(?<!\$\{CLAUDE_PROJECT_DIR\}/)\.cwf/}` uses a fixed-width lookbehind with no unbounded quantifier — no ReDoS. Safe as written; audit any future variant introducing a variable-length alternation ahead of the lookbehind.
- The test fixture helper `settings_with_command` (`t/validate-hooks.t:415`+) builds JSON by string-interpolating `$command`/`$extra{allow}` rather than encoding via `JSON::PP`. Safe here because every caller passes controlled string literals; a `"`/`\` in an input would yield malformed JSON — a correctness footgun in test scaffolding, not a security one. Audit future reuse if ever fed a value containing JSON metacharacters. `_read_settings` also slurps the whole file and decodes at `JSON::PP` default depth — safe because both scan targets are small local config read by the operator's own `cwf-manage`; audit reuse against attacker-sized/attacker-nested inputs where `max_size`/`max_depth` would matter.

Per the review boundary I did not re-verify the SHA256 refresh in `script-hashes.json` or file permissions — those are `cwf-manage validate`'s deterministic responsibility.

No actionable security concerns. The test file is hermetic (tempdir-scoped, read-only against the live repo for TC-8/TC-9), the change is defensive, and the one untrusted-data flow is correctly contained.

Relevant files:
- `/home/matt/repo/coding-with-files/t/validate-hooks.t`
- `/home/matt/repo/coding-with-files/.cwf/lib/CWF/Validate/Hooks.pm`
- `/home/matt/repo/coding-with-files/.cwf/scripts/cwf-manage`

```cwf-review
state: no findings
summary: testing-exec changeset clean; hermetic tempdir-scoped test, no shell/git/env sinks, untrusted `actual` reaches printf as a %s argument, predicate regex has no ReDoS.
```

## Best-Practice Review

**State**: findings

I've read the changeset in full and the applicable Perl best-practice sources. The Go and Postgres sources listed in the context file do not apply — this changeset contains no Go and no SQL. It is entirely Perl plus CWF workflow markdown. For this testing-exec review I focused on the two load-bearing Perl artefacts, with emphasis on the test file: the validator module `.cwf/lib/CWF/Validate/Hooks.pm` and its test `t/validate-hooks.t`. I assessed them against `testing-debugging.md`, `io.md`, and `regular-expressions.md`.

## What I checked and concluded

**Test discipline (`testing-debugging.md` 229/232/233/234) — well aligned.** `t/validate-hooks.t` was written test-first and confirmed to fail for the right reason before implementation (recorded in `f-implementation-exec.md` Step 2). It covers the error path heavily, not just the happy path: negative predicate cases (TC-1, TC-5, TC-5b), malformed JSON (TC-6), unreadable file (TC-6b), symlink refusal (TC-6c), and seven distinct malformed-`hooks`-tree shapes (TC-7b). Boundary/pathological inputs per guideline 233 are exercised directly — `undef` and a hashref are passed to the predicate. This is a strong match to the chapter's core discipline.

**Test toolchain (`testing-debugging.md` 230/231) — correct given the constraint.** The file uses `Test::More` + `done_testing` and runs under `prove`. The source suggests `Test2::V0` for new files, but that comes from the non-core `Test2::Suite`, and CWF is bound to core-only modules for system-Perl portability. The source itself states `Test::More` "remains correct… where you want zero new deps (it is core)". No divergence to action.

**Strictures (`testing-debugging.md` 235/236) — satisfied.** Both the module and the test carry `use strict; use warnings; use utf8;`.

**I/O in the test fixtures (`io.md` 125–130, 136) — satisfied, and the prior finding is fixed.** `write_file` uses three-arg lexical `open my $fh, '>:raw', $path or die`, the braced `print {$fh} $content or die` (136), and — the key point for a write handle — a checked `close $fh or die` (129/130). This is the exact divergence the implementation-exec best-practice review raised (unchecked write-handle close); it is now closed in this changeset. The source-assertion reads (TC-8/TC-9) use `<:encoding(UTF-8)` layers and the `do { local $/; <$fh> }` slurp idiom (133); their unchecked `close` on a read handle is explicitly excused by `io.md` 130 "When not". The `grep { … } <$fh>` list-context read in TC-8 is a small known-size doc file, which `io.md` 131 "When not" permits.

## Findings (one, minor / advisory)

1. **Regex patterns omit `/x` and use `\.` rather than `[.]`** — present in both the module and the test. In `.cwf/lib/CWF/Validate/Hooks.pm` the predicate `m{(?<!\$\{CLAUDE_PROJECT_DIR\}/)\.cwf/}` (changeset line 84), and in `t/validate-hooks.t` the TC-8 scan pattern `/"command"\s*:\s*"\.cwf\//` and the TC-9 pattern `qr/\$\{CLAUDE_PROJECT_DIR\}\//`. `regular-expressions.md` 147 ("always use `/x`", Perl::Critic `RequireExtendedFormatting`) and 155 (prefer `[.]` to `\.`, `ProhibitEscapedMetacharacters`) both diverge here. This is genuinely a divergence from the cited source. It is minor, carries no ReDoS exposure (the module lookbehind is fixed-width with no unbounded quantifier, consistent with 169), and is already dispositioned in the task's own docs (`d-implementation-plan.md` §Plan Review and `f-implementation-exec.md` §Post-review fix) as a conscious choice to match the sibling `Agents.pm` style under "Integration beats perfection". I surface it because the source disagrees; whether it is worth acting on is the user's call.

Everything else in the two files matches the sources. Note that `g-testing-exec.md` in this changeset is still the unfilled template (placeholder `FT1 | … | PASS` row, `Status: Backlog`) — that is a workflow-completeness observation, not a best-practice-source divergence, so it is outside the scope of this review.

```cwf-review
state: findings
summary: One minor Perl divergence carried in the module predicate and the test patterns (regex omits /x and uses \. per regular-expressions.md 147/155); documented as a conscious style-match. The earlier unchecked write-close (io.md 129/130) is fixed in this changeset. Go/Postgres sources not applicable.
```

**Disposition**: the single finding is the same accepted style-match dispositioned at phase `f`
(match the sibling `Agents.pm`; no ReDoS exposure). No change. The reviewer's note that
`g-testing-exec.md` was an unfilled template is an artefact of review ordering — the changeset
is built before this file is written; it is filled by this commit.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Two techniques carried this phase and are worth reusing. **Mutation verification** turned TC-8
and TC-9 from decorative into real — both were green before anything proved they could go red.
**The live-tree system test** proved the wiring, which fixtures structurally cannot: a validator
that is never composed into `cmd_validate` passes every unit test it has. It also surfaced that
`.claude/settings.json` is a sandbox bind-mount — `git checkout --` fails on it (*Device or
resource busy*) and `cp` fails (*Read-only file system*); only the Edit tool writes it.
