# Configurable changeset-review max-lines cap - Implementation Plan
**Task**: 218 (feature)

## Task Reference
- **Task ID**: internal-218
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/218-configurable-changeset-review-max-lines-cap
- **Template Version**: 2.1

## Goal
Implement the `CLI // config // 500` cap resolver and `config_max_lines()` reader in
`security-review-changeset`, set this repo's cap to 1000, and refresh the hash.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/scripts/command-helpers/security-review-changeset` — the resolver, the new
  sub, and the doc text inside the file (see Implementation Steps for line anchors).

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh the `security-review-changeset`
  `sha256` entry (line 373) in the **same commit** (hashed path → plan-time
  disclosure, hash-updates convention). Permissions stay `0500` (recorded ceiling).
- `implementation-guide/cwf-project.json` — add `security.review.max-lines: 1000`
  beside `max-lines-exclude-paths` (lines 39-44).
- `.cwf/docs/skills/security-review.md` — document the new key + precedence at
  line 47 (beside the `--max-lines` / `max-lines-exclude-paths` prose).

<!-- No symbols deleted — the default literal moves into a constant; no Deletes line. -->

## Implementation Steps
### Step 1: Setup
- [ ] Confirm on branch `feature/218-...`; read `c-design-plan.md` D1–D3.
- [ ] Pre-refresh verification (hash-updates §Pre-refresh): run
      `git log --oneline <last-hash-set-commit>..HEAD -- .cwf/scripts/command-helpers/security-review-changeset`
      and confirm the intervening commits are the known, intended edits before
      touching the hash. Document the result in `f-implementation-exec.md`.

### Step 2: Core Implementation (`security-review-changeset`)
- [ ] Add file-scoped `my $DEFAULT_MAX_LINES = 500;` beside the other top-of-file
      `my` declarations (near `$PROG`). **Placement invariant**: it MUST be declared
      *before* `print_usage` (line 311) so the `<<"USAGE"` heredoc can interpolate it;
      declaring it after the sub silently breaks POD interpolation.
- [ ] Line 135: change `max_lines => 500` → `max_lines => undef` in `%opt`.
- [ ] Leave the CLI-validation block (lines 167-171) unchanged — it validates
      `--max-lines` only `if (defined …)`, staying **fatal (exit 1)** on a bad CLI value.
- [ ] Immediately after line 171, add the resolver:
      `$opt{max_lines} = config_max_lines() // $DEFAULT_MAX_LINES unless defined $opt{max_lines};`
- [ ] Add `config_max_lines()` in the Subroutines section beside
      `max_lines_exclude_paths()` (~line 559), per design D2: eval-guarded
      `read_config`, `ref … eq 'HASH'` navigation down `security.review`, read
      `max-lines`; `undef`/missing → silent default; `ref $v` (bool/array/object)
      **or** non-positive-integer scalar (`0`, negative, leading-zero — rejected by
      the shared `^[1-9]\d*$` contract, CLI/config parity) → **warn** (key name only)
      + return `undef`; else `"$v" + 0`.

### Step 3: Testing
- [ ] See `e-testing-plan.md`. Cover: CLI>config>default precedence (incl. explicit
      `--max-lines=500` beats config 1000), config valid int, numeric-string accepted,
      bool/array/object/non-integer scalar warn+degrade, missing/null silent+degrade,
      invalid CLI still fatal (exit 1), 501–1000 passes at cap 1000.
- [ ] Run existing suite (`t/`) for no regressions.

### Step 4: Documentation
- [ ] Header comment (the "defaults to 500" literal at line 33, in the banner
      spanning 29-41): note the cap also reads `security.review.max-lines`
      (precedence CLI > config > default). This plain-`#` prose stays a
      hand-maintained literal — cannot interpolate `$DEFAULT_MAX_LINES` (design F3).
- [ ] POD `print_usage` (`<<"USAGE"`, lines 327-330): change the `--max-lines` prose
      to `defaults to $DEFAULT_MAX_LINES` (interpolates) and note the config key +
      precedence.
- [ ] `security-review.md:47`: document `security.review.max-lines`, its precedence,
      and fail-safe degradation (malformed → warn → default).

### Step 5: Validation
- [ ] `sha256sum .cwf/scripts/command-helpers/security-review-changeset`; write the
      digest into `script-hashes.json` line 373 (same commit).
- [ ] Restore working perms to recorded `0500` (`chmod 0500`), not a bumped 0700.
- [ ] `.cwf/scripts/cwf-manage validate` → clean (no sha256 / permission drift).
- [ ] Set `implementation-guide/cwf-project.json` cap to 1000; manual smoke: a
      >500-≤1000-line changeset now passes.

## Code Changes
### Before (arg parse, line 135)
```perl
my %opt = (wf_step => undef, task_num => undef, max_lines => 500, verbose => 0);
```
### After (line 135 + resolver after line 171)
```perl
my %opt = (wf_step => undef, task_num => undef, max_lines => undef, verbose => 0);
# … existing --max-lines validation block (fatal on invalid CLI value) …
$opt{max_lines} = config_max_lines() // $DEFAULT_MAX_LINES
    unless defined $opt{max_lines};
```
### New sub (beside `max_lines_exclude_paths`) — see design D2 for the full body.

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.
Documentation (header/POD/security-review.md), the hash refresh, and the config
change are in-scope for this task, not deferrable.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
The five-step plan (setup+pre-refresh verify → core impl → tests → docs → validate+
config+hash) executed with zero step deviations on the code itself; full detail in
f-implementation-exec. The one deviation was incidental permission drift on two
Task-217 files surfaced by validate (handled fix-on-sight), not a plan gap.

## Lessons Learned
The plan's Step 1 "verify the hashed helper has no intervening un-blessed edits since
its last hash" paid off: the pre-refresh `git log 9972522..HEAD` was empty and the
live digest matched, so the refresh signed a known-clean baseline rather than an
unreviewed shape.
