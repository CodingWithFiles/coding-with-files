# fix install allowlist and hook enablement - Implementation Plan
**Task**: 126 (bugfix)

## Task Reference
- **Task ID**: internal-126
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/126-fix-install-allowlist-and-hook-enablement
- **Template Version**: 2.1

## Goal
Add `cwf-claude-settings-merge` per the c-design plan, register it in the integrity manifest, and wire it into `/cwf-init` so a fresh install produces a `.claude/settings.json` with the right `Bash(...)` allowlist entries and CWF Stop hooks.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary changes
- **NEW** `.cwf/scripts/command-helpers/cwf-claude-settings-merge` — the helper. Perl, `#!/usr/bin/env perl`, `use strict; use warnings; use utf8;`, ~120 lines. Implements KD3/KD5/KD7/KD8/KD10/KD11. Shebang matches every other `command-helpers/` helper; `-CDSL` is for git-reading scripts only and this helper does no git.
- **NEW** `t/cwf-claude-settings-merge.t` — Perl `Test::More` test. ~150 lines covering empty input, partial input, user-added Stop hooks (in `[0]` and in `[1]`), idempotency, dry-run, malformed input refusal, and symlink/directory refusal. Specific test cases enumerated in e-testing-plan.md. Fixtures are built inline via `File::Temp::tempdir()` — matches the pattern in `t/cwf-manage-fix-security.t` and `t/validate-security-coverage.t`. No `t/fixtures/` directory.
- **MODIFY** `.cwf/security/script-hashes.json` — one new entry registering `cwf-claude-settings-merge` under `scripts` (sha256 + `permissions: "0500"` per Task 125 min-bits convention). Without this, `t/validate-security-coverage.t` from Task 125 will go RED.
- **MODIFY** `.claude/skills/cwf-init/SKILL.md` — append a new sub-step after Step 6c (numbered "Step 6d") that invokes the helper, mirroring the format of Step 1a's existing sub-step. Update Success Criteria with a matching checkbox.

### Supporting changes
- (No changes to `INSTALL.md` — the helper is invoked from `/cwf-init`, not from `install.bash`.)

## Implementation Steps

### Step 1: Setup
- [ ] Re-read c-design-plan.md KD1–KD11 and the Failure Modes section.
- [ ] Confirm working tree is clean apart from the wf files; verify branch is `bugfix/126-fix-install-allowlist-and-hook-enablement`.
- [ ] Confirm Task 125's coverage test passes today (baseline): `prove t/validate-security-coverage.t`.

### Step 2: Write the helper alongside its test
- [ ] Write `t/cwf-claude-settings-merge.t` with the e-plan test cases. Verify it parses (`perl -c`).
- [ ] Create `.cwf/scripts/command-helpers/cwf-claude-settings-merge` with shebang `#!/usr/bin/env perl`, `use strict; use warnings; use utf8;`, `use FindBin; use lib "$FindBin::Bin/../../lib";`. Implement these subs:
  - **Manifest reader.** Open `.cwf/security/script-hashes.json` via `JSON::PP`. On parse failure → `die "[CWF] ERROR: cannot parse script-hashes.json: $!\n"`. Iterate `scripts.<key>.path`. For each path: refuse if it doesn't start with `.cwf/scripts/` or contains `..`; `stat()` to confirm existence (warn-and-skip if missing); partition per KD3 (`cwf-manage` → top-level; `command-helpers/<name>` no second `/` → top-level helper; `command-helpers/<n>.d/<sub>` → skip; `hooks/<name>` → hook). Build `@allow_entries` and `@hook_entries` (objects with `type`, `command`, `timeout: 5`).
  - **Settings reader.** Check `.claude/` is a regular directory (lstat — refuse if symlink: FR4(b) defence against parent-dir clobber). If `.claude/settings.json` exists, lstat to verify it's a regular file; reject symlink/directory with the error from KD7. Read + parse via `JSON::PP`. Else start from `{}`.
  - **Merge.** Ensure `permissions.allow` is an arrayref; build a hashset of existing strings; append entries from `@allow_entries` not already present, preserving array order. (Note: `JSON::PP->canonical` reorders *object keys* alphabetically but preserves *array element order*, so allowlist append-order survives.) Ensure `hooks.Stop` is an arrayref; for each CWF hook entry, scan every `hooks.Stop[i].hooks[j].command` for an exact match. If absent, append to `hooks.Stop[0].hooks[]` (creating the matcher if `hooks.Stop` is empty).
  - **Atomic write (KD10).** Use `File::Temp->new(DIR => '.claude', TEMPLATE => '.settings.json.XXXXXX', UNLINK => 0)` — same pattern as `CWF::Versioning::bump_to` (`.cwf/lib/CWF/Versioning.pm:119-135`). XXXXXX randomization avoids PID-collision issues. Encode via `JSON::PP->new->pretty->indent_length(2)->canonical`. Write, close, `rename()` over `.claude/settings.json`; on rename failure, unlink temp and die.
  - **CLI.** Iterate `@ARGV`: `--dry-run` → set flag and `next`; `--help`/`-h` → print usage and exit 0; anything else → warn and exit 1. With `--dry-run`, print the encoded JSON to STDOUT and skip the write.
- [ ] `chmod 0500 .cwf/scripts/command-helpers/cwf-claude-settings-merge`.
- [ ] Run the test: `prove t/cwf-claude-settings-merge.t` — must go GREEN.

### Step 3: Register the helper in the integrity manifest
- [ ] Compute the helper's sha256 with `Digest::SHA::sha256_hex`. Per the no-inline-scripts rule, write a small `/tmp/task-126/compute-hash.pl` via the Write tool and run from there.
- [ ] Edit `.cwf/security/script-hashes.json` to add the entry under `scripts`:
  ```json
  "cwf-claude-settings-merge": {
    "path": ".cwf/scripts/command-helpers/cwf-claude-settings-merge",
    "sha256": "<computed>",
    "permissions": "0500"
  }
  ```
- [ ] Bump `last_updated` to today's date.
- [ ] Run `prove t/validate-security-coverage.t` — TC-C1 must still pass (counts: 23/7/2 = +1 in TC-C1 from the new helper).
- [ ] Run `.cwf/scripts/cwf-manage validate` — must report `[CWF] validate: OK` with zero violations.

### Step 4: Wire into `/cwf-init`
- [ ] Edit `.claude/skills/cwf-init/SKILL.md`. Insert a new "### 6d. Register Bash allowlist and Stop hooks" sub-step after Step 6c. Body:
  - Brief sentence explaining what the helper does.
  - Code block: `bash\n.cwf/scripts/command-helpers/cwf-claude-settings-merge\n`.
  - Idempotency note (safe to re-run after `cwf-manage update`).
  - Failure handling: abort `/cwf-init` if the helper exits non-zero or emits any `[CWF] ERROR:` line on stderr; relay the helper's stdout/stderr verbatim. `[CWF] WARN:` lines (e.g. manifest entry missing on disk per KD3 existence check) are logged and tolerated — partial coverage is acceptable, full failure is not.
- [ ] Add a Success Criteria checkbox: `[ ] Bash allowlist + Stop hooks registered via cwf-claude-settings-merge`.
- [ ] No changes needed to Step 8's `git add` — `.claude/settings.json` is already in the staged set.

### Step 5: Verify the bugfix on a fixture
- [ ] In a tempdir, simulate the install scenario: `mkdir -p /tmp/task-126/sandbox/.claude` (Write tool, no on-disk impact to repo). Drop a stub manifest with one `cwf-manage` + one helper + one hook entry. Run the helper from there. Inspect the output `.claude/settings.json` — the diff is the bugfix proof.
- [ ] Re-run from the same dir; confirm zero diff (idempotency).

### Step 6: Commit
- [ ] Single checkpoint commit for f-phase (the existing pattern). Stage: helper, test, manifest update, SKILL.md, f-implementation-exec.md.
- [ ] Run `cwf-manage validate` post-commit; must be `OK`.

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Risks at implementation time
- **Hash registration ordering**: the integrity manifest must be updated *before* the f-phase checkpoint commit, otherwise `cwf-manage validate` (run by `cwf-checkpoint-commit`) fails. Step 3 must precede staging in Step 6. If a partial commit slips through, recover with `git reset HEAD~1` and re-stage everything together.
- **SKILL.md drift**: Step 1a's existing sub-step is the closest stylistic match; copy its formatting exactly to keep the doc consistent.
- **Test isolation**: the helper writes to `.claude/settings.json`. Tests use `File::Temp::tempdir` + `chdir` to isolate from the real `.claude/` — keeps the helper's CLI free of path-injection arguments and matches the pattern in `t/cwf-manage-fix-security.t`.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

If a step is genuinely deferred, document why and create a BACKLOG follow-up.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
