# expand script-hashes to helpers and hooks - Implementation Plan
**Task**: 125 (chore)

## Task Reference
- **Task ID**: internal-125
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/125-expand-script-hashes-to-helpers-and-hooks
- **Template Version**: 2.1

## Goal
Register every executable script under `.cwf/scripts/command-helpers/` (top-level trampolines + `*.d/` subcommands, Perl and POSIX shell alike) and `.cwf/scripts/hooks/` in `.cwf/security/script-hashes.json`, lower recorded permissions to a `0500` minimum (default; per-file override only if it would break execution), and add a regression test so the integrity surface stays complete.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/security/script-hashes.json` —
  1. add 17 new entries to the `scripts` section (12 Perl + 5 POSIX shell);
  2. lower recorded `permissions` to `0500` for the 4 pre-existing drift entries (`cwf-set-status`, `migrate-v2.1-file-order`, `task-context-inference`, `task-stack`) — the recorded `0755` is overstated; `0500` (owner r+x) is the minimum that allows execution and is consistent with most existing entries;
  3. record all 17 new entries with `permissions: "0500"` (default policy);
  4. bump `last_updated`.

### Supporting Changes
- `t/validate-security-coverage.t` — **new** Perl test. Walks `.cwf/scripts/command-helpers/**` (incl. `*.d/`) and `.cwf/scripts/hooks/*`, parses `script-hashes.json`, asserts each file is registered. Permanent regression guard against future helpers slipping out of the integrity surface.

### Files NOT Modified (deliberately)
- `.cwf/scripts/cwf-manage` — no behavioural change; its hash entry remains valid.
- `.cwf/lib/CWF/Validate/Security.pm` — already supports arbitrary keys within sections (verified at `lib/CWF/Validate/Security.pm:76` — iterates `sort keys %file_entries` with no parsing). No code change needed.
- The 12 scripts themselves — content is unchanged; this task is purely about the manifest.

## Inventory: 17 files to register

All currently 0700 on disk. Recorded perms in JSON: `0500` (min-bits semantics; `Validate::Security` checks `actual & expected == expected`, so 0500 passes for actual 0500/0700/0755).

| Path                                                                  | Recorded perms | Type             |
| --------------------------------------------------------------------- | -------------- | ---------------- |
| `.cwf/scripts/command-helpers/context-manager`                        | 0500           | Perl trampoline  |
| `.cwf/scripts/command-helpers/context-manager.d/hierarchy`            | 0500           | Perl subcommand  |
| `.cwf/scripts/command-helpers/context-manager.d/inheritance`          | 0500           | Perl subcommand  |
| `.cwf/scripts/command-helpers/context-manager.d/location`             | 0500           | Perl subcommand  |
| `.cwf/scripts/command-helpers/context-manager.d/version`              | 0500           | Perl subcommand  |
| `.cwf/scripts/command-helpers/task-workflow`                          | 0500           | Perl trampoline  |
| `.cwf/scripts/command-helpers/task-workflow.d/create`                 | 0500           | Perl subcommand  |
| `.cwf/scripts/command-helpers/workflow-manager`                       | 0500           | Perl trampoline  |
| `.cwf/scripts/command-helpers/workflow-manager.d/control`             | 0500           | Perl subcommand  |
| `.cwf/scripts/command-helpers/workflow-manager.d/status`              | 0500           | Perl subcommand  |
| `.cwf/scripts/command-helpers/cwf-find-task-numbering-structure`      | 0500           | POSIX sh helper  |
| `.cwf/scripts/command-helpers/cwf-load-autoload-config`               | 0500           | POSIX sh helper  |
| `.cwf/scripts/command-helpers/cwf-load-existing-tasks`                | 0500           | POSIX sh helper  |
| `.cwf/scripts/command-helpers/cwf-load-project-config`                | 0500           | POSIX sh helper  |
| `.cwf/scripts/command-helpers/cwf-load-status-sections`               | 0500           | POSIX sh helper  |
| `.cwf/scripts/hooks/stop-stale-status-detector`                       | 0500           | Perl hook        |
| `.cwf/scripts/hooks/stop-uncommitted-changes-warning`                 | 0500           | Perl hook        |

Plus 4 in-place updates (perms-only, no new entries):

| Path                                                                  | Old recorded | New recorded | Reason                              |
| --------------------------------------------------------------------- | ------------ | ------------ | ----------------------------------- |
| `.cwf/scripts/command-helpers/cwf-set-status`                         | 0755         | 0500         | drift: actual is 0700; 0755 too loose |
| `.cwf/scripts/migrations/migrate-v2.1-file-order`                     | 0755         | 0500         | drift: actual is 0700                  |
| `.cwf/scripts/command-helpers/task-context-inference`                 | 0755         | 0500         | drift: actual is 0700                  |
| `.cwf/scripts/command-helpers/task-stack`                             | 0755         | 0500         | drift: actual is 0700                  |

## Hash-key naming

Within the `scripts` section the existing convention is bare names (`task-context-inference`, `template-copier-v2.1`). For `*.d/` entries we use `<parent>.d/<sub>` keys so the directory relationship is visible in the JSON; the validator does not parse keys (`Validate::Security.pm:76`), so embedded `/` and `.` are safe.

Examples:
- `"context-manager.d/hierarchy"` → `path: ".cwf/scripts/command-helpers/context-manager.d/hierarchy"`
- `"workflow-manager.d/control"` → `path: ".cwf/scripts/command-helpers/workflow-manager.d/control"`

For hooks, no collision risk: `"stop-stale-status-detector"`, `"stop-uncommitted-changes-warning"`.

## Out of scope (explicit, do not silently expand)

1. **End-user `refresh-hashes` command** — BACKLOG out-of-scope clause; trust boundary stays at the upstream maintainer.
2. **Migrating POSIX shell helpers to Perl** — out of scope here. Captured as a separate backlog item (Perl-vs-Bash audit + migration).

## Implementation Steps

### Step 1: Setup
- [x] Confirm 17-file inventory (above) + 4 perms-drift updates.
- [x] Confirm `Validate::Security` accepts arbitrary keys within sections.
- [x] Confirm permissions for each new file via `stat -c %a` (all 0700; recording 0500 with min-bits semantics).
- [x] Confirm shell helpers run from `#!/bin/sh` (verified `cwf-load-project-config`, `cwf-find-task-numbering-structure`).

### Step 2: Compute SHA256s
- [ ] Write `/tmp/task-125/compute-hashes.pl` (file, not `perl -e`) that reads each of the 17 paths with `:raw` mode and prints `Digest::SHA::sha256_hex` per file as a JSON fragment.
- [ ] Run; visually diff the fragment against the inventory list.

### Step 3: Splice into `script-hashes.json`
- [ ] Edit `.cwf/security/script-hashes.json`:
  - Insert 17 new entries into `scripts` map, alphabetised by key for diff readability.
  - Verify each new key follows the convention from § "Hash-key naming": top-level files use bare names (`context-manager`, `cwf-load-autoload-config`); `*.d/` files use `<parent>.d/<sub>` keys (`context-manager.d/hierarchy`); hooks use bare names.
  - Update the 4 drift entries' `permissions` from `"0755"` → `"0500"`.
  - Update `last_updated` to today (2026-05-03).
- [ ] Verify JSON is parseable via probe script `/tmp/task-125/check-json.pl` (no-inline-script rule).

### Step 4: Run `cwf-manage validate`
- [ ] `.cwf/scripts/cwf-manage validate`.
- [ ] Expect: **0 violations** total — 17 new entries hash-clean, perms drift fixed.
- [ ] If any fail: stop and diagnose (most likely cause: stale hash captured during script edit; recompute).

### Step 5: Coverage regression test
- [ ] Create `t/validate-security-coverage.t` modelled on `t/validate-perl-conventions.t`:
  - `use lib "$FindBin::Bin/../.cwf/lib"` (no `HARNESS_PERL_SWITCHES`).
  - `use Test::More` + `use File::Find`.
  - Parse `.cwf/security/script-hashes.json` with `JSON::PP` (same module `Validate::Security` uses).
- [ ] Logic:
  1. Read `script-hashes.json`; build `%registered = path => 1` from `scripts` and `lib` sections (`$entry->{path}`).
  2. `File::Find::find` over `.cwf/scripts/command-helpers/` and `.cwf/scripts/hooks/` with a `wanted` callback that:
     - skips directories (`-d _`),
     - skips symlinks (`-l _` — defensive: maintainer environments shouldn't have symlinks here, and following them could pull in arbitrary files),
     - keeps regular files only (no shebang filter — every executable script under these directories must be registered, regardless of language).
     - sorts the resulting file list before assertions for deterministic output.
  3. Assert each file appears in `%registered`.
- [ ] Three subtests with explicit expected counts:
  - **TC-C1** "Top-level command-helpers registered" — expect 22 hits (14 already-registered + 8 new in this task: 3 Perl trampolines + 5 POSIX shell helpers).
  - **TC-C2** ".d/ subcommands registered" — expect 7 hits (4 `context-manager.d/` + 1 `task-workflow.d/` + 2 `workflow-manager.d/`).
  - **TC-C3** "Hooks registered" — expect 2 hits (`stop-stale-status-detector`, `stop-uncommitted-changes-warning`).
- [ ] Demonstrate the test is meaningful: run **before** Step 3's JSON splice and confirm RED on TC-C1/C2/C3; run **after** Step 3 and confirm GREEN. (TC-NF1 in e-testing-plan turns this into an executable check via a synthetic-file probe.)

### Step 6: Run full test suite
- [ ] `prove -r t/` — expect new test green and zero regressions in the existing baseline.

### Step 7: Refresh `script-hashes.json` entry for itself? (NO)
- The JSON file is *read* by `Validate::Security`; it is not in any `scripts` or `lib` section (and shouldn't be — it would be self-referential).

## Code Changes
### Before (`.cwf/security/script-hashes.json`, `scripts` section)
```json
"scripts" : {
    "checkpoints-branch-manager" : { "path": "...", "permissions": "0500", "sha256": "..." },
    /* ... 18 existing entries ... */
}
```

### After
```json
"scripts" : {
    "checkpoints-branch-manager" : { "path": "...", "permissions": "0500", "sha256": "..." },
    "context-manager" : { "path": ".cwf/scripts/command-helpers/context-manager", "permissions": "0700", "sha256": "<computed>" },
    "context-manager.d/hierarchy" : { "path": ".cwf/scripts/command-helpers/context-manager.d/hierarchy", "permissions": "0700", "sha256": "<computed>" },
    /* ... 10 more new entries, alphabetised ... */
    /* 18 existing entries continue */
}
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

Headline:
- TC-U1: Coverage test asserts all 12 new files registered (red without entries, green after).
- TC-I1: `cwf-manage validate` clean on the 12 new entries.
- TC-I2: Planted-byte-flip on one new entry triggers `[SECURITY] sha256`; revert clears.
- TC-NF1: Coverage test fails when a synthetic new file is dropped into `.cwf/scripts/command-helpers/` without a corresponding entry.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

If user accepts the optional expansion to include `cwf-find-*`/`cwf-load-*` POSIX shell helpers during d-plan review, fold them into Step 2/3 inventory; otherwise open a follow-up backlog item rather than deferring inside this task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Plan executed without deviation. All 17 hashes captured cleanly on first attempt; no recompute needed. The `<parent>.d/<sub>` key shape with embedded `/` works as predicted (validator iterates `sort keys` without parsing). 4 drift entries lowered to `0500`; `cwf-manage validate` reported zero violations after the splice.

## Lessons Learned
Reading `Validate::Security.pm:76` before committing to the key shape paid for itself — the embedded `/` would otherwise have been a question mark. Min-bits semantics turn out to be the right default for new entries; future plans should record `0500` and only raise per-file if execution genuinely needs higher bits.
