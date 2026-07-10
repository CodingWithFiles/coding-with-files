# Resolve tool-check hook paths from git root - Testing Plan
**Task**: 224 (bugfix)

## Task Reference
- **Task ID**: internal-224
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/224-resolve-tool-check-hook-paths-from-git-root
- **Template Version**: 2.1

## Goal
Prove that `CWF::Validate::Hooks` flags an unrooted `.cwf/` hook command, stays silent on
every legitimate shape it will meet in the wild, degrades rather than dies on a bad settings
file, and that the two source sites the design binds together (the doc example, the
generator's literal) cannot drift.

## Test Strategy

### Test Levels
- **Unit**: the pure predicate `command_is_rooted` — a total string→bool function, tested
  directly with no filesystem.
- **Integration**: `validate($git_root)` against hermetic fixture trees built under
  `File::Temp::tempdir`, exercising file discovery, the absence gate, degradation paths, and
  the `hooks`-only scan.
- **System**: `cwf-manage validate` on the live tree returns OK (run at the checkpoint
  commit, not in `t/`).
- **Source assertion**: TC-8 / TC-9 grep committed files to bind the three sites where the
  `${CLAUDE_PROJECT_DIR}/` literal appears.

### Test Coverage Targets
- **Critical path** (the predicate, and the `hooks`-tree walk): 100% of branches
- **Edge cases**: absent file, present-but-unreadable, malformed JSON, symlinked settings,
  malformed `hooks` tree at each nesting level
- **Regression**: full `t/` suite green; the false-positive shapes (TC-3, TC-4) are the
  regression guard — they are the shapes that would get this validator switched off
- **Not targeted**: line-coverage percentage. The module is ~80 lines; branch enumeration
  above is the meaningful measure.

### Why these cases and not more
The predicate has exactly two interesting inputs (rooted, unrooted) and three *accepted*
imprecisions (absolute path, unbraced expansion, `.cwf` without slash). Each imprecision gets
a test that pins the **current** behaviour, so a future change to any of them is a deliberate
decision rather than an accident. That is the whole point of testing an accepted trade-off.

## Test Cases

### Functional Test Cases — unit (pure predicate)

- **TC-1**: A bare relative `.cwf/` hook command is unrooted
  - **Given**: the command string `.cwf/scripts/hooks/subagentstop-security-verdict-guard`
  - **When**: `command_is_rooted` is called
  - **Then**: returns false (a violation-worthy command)

- **TC-2**: The canonical generated form is rooted
  - **Given**: `${CLAUDE_PROJECT_DIR}/.cwf/scripts/hooks/pretooluse-bash-tool-check`
  - **When**: `command_is_rooted` is called
  - **Then**: returns true

- **TC-3**: The rules-inject shape, whose prefix sits mid-string, is rooted *(guards D1)*
  - **Given**: `cat "${CLAUDE_PROJECT_DIR}/.cwf/rules-inject.txt" 2>/dev/null || true`
  - **When**: `command_is_rooted` is called
  - **Then**: returns true
  - **Why it matters**: a "command must start with the prefix" rule would fail here. This is
    the shipped registration; a false positive on it makes `validate` permanently red.

- **TC-5**: An absolute path is reported unrooted *(pins an accepted false positive)*
  - **Given**: `/home/u/repo/.cwf/scripts/hooks/x`
  - **When**: `command_is_rooted` is called
  - **Then**: returns false
  - **Why it matters**: deliberate. A machine-specific absolute path does not survive
    `git clone`. The test records that this is a choice, not an oversight.

- **TC-5b**: The unbraced expansion is reported unrooted *(pins an accepted false positive)*
  - **Given**: `$CLAUDE_PROJECT_DIR/.cwf/scripts/hooks/x`
  - **When**: `command_is_rooted` is called
  - **Then**: returns false

- **TC-5c**: A `.cwf` reference without a trailing slash is not matched *(pins the accepted
  false negative)*
  - **Given**: `cd .cwf && ./scripts/hooks/x`
  - **When**: `command_is_rooted` is called
  - **Then**: returns true (no violation) — documented gap, safe while every hook command
    targets a file under `.cwf/scripts/…`

### Functional Test Cases — integration (fixture tree)

- **TC-4**: `permissions.allow` entries are never scanned *(guards D2)*
  - **Given**: a fixture `.claude/settings.json` with a clean, rooted `hooks` tree **and** a
    `permissions.allow` array containing `Bash(.cwf/scripts/hooks/stop-stale-status-detector)`
  - **When**: `validate($fixture_root)` runs
  - **Then**: zero violations
  - **Why it matters**: those entries are match patterns, not exec paths. Both real settings
    files carry them today; a whole-document scan would fire on ~6 legitimate entries.

- **TC-4b**: An unrooted command inside the `hooks` tree is caught
  - **Given**: a fixture whose `hooks.PreToolUse[0].hooks[0].command` is bare-relative
  - **When**: `validate($fixture_root)` runs
  - **Then**: exactly one violation, `category => 'HOOKS'`, `field => 'hook-command'`,
    `file => '.claude/settings.json'`, and `actual` equal to the offending command verbatim

- **TC-6**: Malformed JSON degrades to a violation, never a die
  - **Given**: a fixture `.claude/settings.json` containing `{ not json`
  - **When**: `validate($fixture_root)` runs
  - **Then**: exactly one violation with `field => 'json-parse'`; no exception propagates
  - **Why it matters**: a die here would abort the other eight validators.

- **TC-6b**: A present-but-unreadable settings file degrades to a violation, never a die
  - **Given**: a fixture `.claude/settings.json` at mode `0000`
  - **When**: `validate($fixture_root)` runs
  - **Then**: exactly one violation with `field => 'json-parse'`
  - **Guard**: wrapped in `SKIP: { skip 'root effective uid bypasses -r', N if $> == 0; … }`,
    restoring `chmod 0600` before `CLEANUP` — root reads a `0000` file regardless, so the
    assertion is meaningless (and red) under root. Precedent: `t/artefacthelpers.t:139-148`.

- **TC-6c**: A symlinked settings file is refused, not followed
  - **Given**: `.claude/settings.json` is a symlink to a valid JSON file elsewhere
  - **When**: `validate($fixture_root)` runs
  - **Then**: exactly one violation with `field => 'json-parse'` (the `-f && !-l` guard)

- **TC-7**: A fixture tree in the canonical generated form validates clean
  - **Given**: a fixture `.claude/settings.json` whose every hook command is
    `${CLAUDE_PROJECT_DIR}/`-rooted, and **no** `settings.local.json`
  - **When**: `validate($fixture_root)` runs
  - **Then**: zero violations — proving the absence gate skips the missing optional file
    rather than reporting `json-parse` on it
  - **Why a fixture and not `$git_root`**: the live tree contains the gitignored,
    machine-specific `.claude/settings.local.json`. A contributor whose local file happened to
    carry a bare-relative command would see the suite go red through no fault of the change
    under test. Live-tree cleanliness is asserted by `cwf-manage validate` at the checkpoint
    commit, which is the real acceptance signal.

- **TC-7b**: A malformed `hooks` tree is skipped, not fatal
  - **Given**: fixtures where, in turn, `hooks` is an array, an event maps to a scalar, a
    group lacks `hooks`, and a hook entry's `command` is a hashref
  - **When**: `validate($fixture_root)` runs
  - **Then**: zero violations and no exception at every level (type-check before descent)

### Source Assertion Test Cases

- **TC-8**: The doc teaches only the rooted form *(guards D5)*
  - **Given**: `.cwf/docs/workflow/stop-hooks-framework.md`
  - **When**: scanned for hook-**command** lines — the pattern must be scoped to the
    `"command": ".cwf/` context
  - **Then**: no match
  - **Trap**: a whole-file grep for `.cwf/scripts/hooks/` fails **forever**, fix or no fix.
    Lines 115 and 138 are prose file-path references and are correctly bare; only line 164 is
    a registration. Verified during design.

- **TC-9**: The generator still emits the canonical literal *(guards D5)*
  - **Given**: `.cwf/scripts/command-helpers/cwf-claude-settings-merge`
  - **When**: scanned for the literal `${CLAUDE_PROJECT_DIR}/`
  - **Then**: present
  - **Why it matters**: the literal lives in three places (generator, validator, doc) by
    deliberate choice (D5 — below the Rule of Three, not worth a shared constant in a second
    hashed file). This test is what makes that choice safe. TC-3 does **not** do this; an
    earlier draft of the design wrongly claimed it did.

### Non-Functional Test Cases
- **Security**: covered by construction, asserted by inspection at exec, not by a test —
  the predicate matches `${CLAUDE_PROJECT_DIR}` as a *literal* and never expands it; there is
  no `system`/backtick/shell-string construction; the fixed-width lookbehind has no unbounded
  quantifier and so no ReDoS exposure; `actual` reaches `printf` as an **argument**, never as
  a format string (`cwf-manage:626`).
- **Reliability**: TC-6 / TC-6b / TC-6c / TC-7b are the reliability suite — every path by
  which a bad settings file could abort `validate` degrades to a violation instead.
- **Usability**: the violation's `fix` field must name the remedy
  (`cwf-claude-settings-merge`) rather than describe the problem. Asserted in TC-4b.
- **Performance**: not applicable. Two small JSON reads, once per `cwf-manage validate`
  invocation. This is not a hot path (contrast the tool-check hook, which is).

## Test Environment

### Setup Requirements
- Perl core only: `Test::More`, `File::Temp`, `File::Path`, `JSON::PP`, `FindBin`
- Fixture trees built under `tempdir(CLEANUP => 1)`; no git repo needed — `validate` takes
  `$git_root` as a plain argument and never shells out
- The real `~/.cwf` and the live `.claude/` are never written by the tests
- `t/validate-hooks.t` carries `use strict; use warnings; use utf8;`

### Automation
- Framework: `Test::More` with `done_testing`, matching every sibling in `t/`
- Invocation: `prove -r t/` (bare — `PERL5OPT` is already set in the environment)
- Single file during development: `prove -q t/validate-hooks.t`
- CI/CD: no separate pipeline; the suite plus `cwf-manage validate` run at each checkpoint
  commit via `cwf-checkpoint-commit`

## Validation Criteria
- [ ] TC-1..TC-9 pass (TC-6b skipped, not failed, when running as root)
- [ ] `prove -r t/` green — no regression in the existing files
- [ ] `cwf-manage validate` OK on the live tree
- [ ] `t/validate-hooks.t` fails if `stop-hooks-framework.md:164` is reverted (TC-8 is real)
- [ ] `t/validate-hooks.t` fails if the generator's prefix literal is removed (TC-9 is real)
- [ ] `.cwf/scripts/cwf-manage` at recorded `0700`; hashes refreshed in the same commit

## Expected Verdicts vs Locked Rules
No test expects `cwf-manage validate` to pass on a tree containing an unrooted CWF hook
command; no test asserts a fixture may carry `permissions`-only `.cwf/` references *and* be
flagged. These two would contradict D2 and the task goal respectively. Checked: none present.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
46 assertions, all pass; TC-6b ran rather than skipped (non-root host). TC-8 and TC-9 were each
mutation-verified: the guarded site was regressed, the test observed red, and the site reverted.
A live-tree system test (mutate one real hook command in `.claude/settings.json`, run
`cwf-manage validate`, revert) produced exactly one violation — confirming D2 end-to-end, since
the `permissions.allow` bare pattern was not flagged. Full suite: 77 files, 1054 tests, green.
See `g-testing-exec.md`.

## Lessons Learned
The plan's instinct to pin each accepted imprecision with its own test (TC-5, TC-5b, TC-5c) was
right, but the plan's real payoff was TC-8 and TC-9 — and only because execution went further
than the plan asked and *mutation-verified* them. Both are "the source still says X" assertions,
which pass just as happily against a typo'd pattern that matches nothing. A green source
assertion is not evidence until you have watched it fail. The plan should have specified the
mutation step rather than leaving it to be improvised at `g`.
