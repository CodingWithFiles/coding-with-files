# Drop perl -I prefix from script invocations - Implementation Execution
**Task**: 121 (chore)

## Task Reference
- **Task ID**: internal-121
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/121-drop-perl-i-prefix-from-script-invocations
- **Template Version**: 2.1

## Goal
Execute the implementation per d-implementation-plan.md.

## Actual Results

### Step 1: Baseline confirmed
- `prove t/` → 253/253 pass.
- `.cwf/scripts/cwf-manage validate` → `[CWF] validate: OK`.
- Inventory grep returned 5 hits across 4 files (as planned):
  - `.claude/skills/cwf-init/SKILL.md:35`
  - `.claude/skills/cwf-security-check/SKILL.md:29`
  - `INSTALL.md:282`
  - `t/cwf-manage-fix-security.t:43,53` (2 lines)

### Step 2: `.claude/skills/cwf-security-check/SKILL.md`
- Replaced `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` with `.cwf/scripts/cwf-manage validate`.

### Step 3: `INSTALL.md`
- Removed lines 281–282 (the `# Check Perl modules load` comment and the `perl -I -MCWF::Common -e ...` line).
- Updated line 285's "All four commands" → "All three commands".

### Step 4: `.claude/skills/cwf-init/SKILL.md`
- Replaced step 1a's prose + code fence with the JSON-driven bootstrap: an inline `perl -MJSON::PP -e` extracts `cwf-manage`'s recorded permissions from `script-hashes.json`, the result chmods `cwf-manage`, then `cwf-manage fix-security` runs.

### Step 5: `t/cwf-manage-fix-security.t`
- Added `use Fcntl qw(:mode);` and `use JSON::PP qw(decode_json);` to the use block.
- Added `_read_recorded_perms($tmp, $entry_name)` helper.
- Added `_ensure_cwf_manage_executable($tmp)` helper (idempotent; uses `S_IXUSR` to skip when user-x is set).
- Replaced `run_fix_security` and `run_validate` to invoke `.cwf/scripts/cwf-manage <subcmd>` directly after calling the bootstrap helper.
- Updated TC-2 assertion: `0700` literal → `_read_recorded_perms($tmp, 'cwf-manage')`.
- Retargeted TC-4's `$other` from `cwf-manage` → `command-helpers/cwf-version-tag`. Updated assertion to use `_read_recorded_perms`.
- Retargeted TC-5's `$fileA` from `cwf-manage` → `command-helpers/cwf-version-tag`. Updated regex (`qr{cwf-manage}` → `qr{cwf-version-tag}`) and assertion.

### Step 6: Verify
- `grep -rn "perl -I.cwf/lib" .claude/ INSTALL.md README.md CLAUDE.md docs/ .cwf/docs/ .cwf/templates/ .cwf/scripts/ .cwf/lib/ t/` → **zero hits**.
- `.cwf/scripts/cwf-manage validate` → `[CWF] validate: OK`.
- `prove t/cwf-manage-fix-security.t` → all 7 subtests pass.
- `prove t/` → 253/253 pass (no regressions).

## Deviations
None. All steps executed as planned.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (grep clean, validate OK, prove green)
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 121
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
