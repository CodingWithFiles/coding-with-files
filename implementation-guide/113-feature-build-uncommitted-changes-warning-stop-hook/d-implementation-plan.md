# Build uncommitted changes warning Stop hook - Implementation Plan
**Task**: 113 (feature)

## Task Reference
- **Task ID**: internal-113
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/113-build-uncommitted-changes-warning-stop-hook
- **Template Version**: 2.1

## Goal
Create the hook script and register it alongside Task 104's existing Stop hook.

## Files to Create
- `.cwf/scripts/hooks/stop-uncommitted-changes-warning` — the new Perl hook script

## Files to Modify
- `.claude/settings.local.json` — append a second command entry to the existing `hooks.Stop[0].hooks` array
- `.claude/settings.local.json` — add a permission allow entry for the new hook path (mirrors existing `Bash(.cwf/scripts/hooks/stop-stale-status-detector)` entry at line 80)

## Implementation Steps

### Step 1: Write the hook script
- [ ] Create `.cwf/scripts/hooks/stop-uncommitted-changes-warning` structured as:
  - `#!/usr/bin/perl -CDSL` — matches the convention used by other CWF Perl helpers (`template-copier-v2.1`, `status-aggregator-v2.1`, `context-inheritance-v2.1`). Task 104's bare `#!/usr/bin/env perl` is the project outlier; we don't replicate that mistake.
  - `use strict; use warnings;`
  - No `FindBin`/`use lib` (we don't import `CWF::TaskState` — no git utilities exist in `.cwf/lib/CWF/` per Step 1 codebase check)
  - Single `eval { ... };` block wrapping all logic; **one** `exit 0;` placed *after* the eval block (matches Task 104). `return` from inside eval to skip output; never call `exit` inside eval.
- [ ] Inside the eval block:
  - Run `git status --porcelain -z --untracked-files=all -- 'implementation-guide/*/[a-j]-*.md' 2>/dev/null` via backticks. Capture into a single scalar — do not `chomp` (the output ends with NUL, not newline).
  - `my @records = split /\0/, $output; @records = grep { length } @records;` — split on NUL boundaries, drop empty records.
  - For each record: `my $path = substr($record, 3);` (skip 2-char code + space). Then take basename via the Task 104 idiom `map { m{([^/]+)$} ? $1 : $_ }` — fallback covers any path the regex can't capture.
  - `return` from eval if no records
  - Cap at 3 displayed basenames using `@dirty[0 .. ($#dirty > 2 ? 2 : $#dirty)]`; append `" +@{[$#dirty - 2]} more"` when `@dirty > 3` (mirror Task 104 lines 35-37 exactly)
  - Print `qq({"systemMessage":"\\u26a0 Uncommitted: $msg"}\n)` — same Unicode-escape style as Task 104 line 39 (`⚠` is the wire form of `⚠` shown in the c-design-plan examples)
- [ ] `chmod 0500 .cwf/scripts/hooks/stop-uncommitted-changes-warning` (matches Task 104 permissions)

### Step 2: Register hook in settings
- [ ] Backup current settings: `cp .claude/settings.local.json /tmp/settings.local.json.bak.113`
- [ ] Edit `.claude/settings.local.json` via the Edit tool:
  - Append a second object to `hooks.Stop[0].hooks` after the existing stop-stale-status-detector entry:
    ```json
    {
      "type": "command",
      "command": ".cwf/scripts/hooks/stop-uncommitted-changes-warning",
      "timeout": 5
    }
    ```
  - Add `"Bash(.cwf/scripts/hooks/stop-uncommitted-changes-warning)"` to `permissions.allow` (relative form matching the existing relative entry; do not duplicate as absolute path — the absolute entry at line 82 for the Task 104 hook was auto-added by the harness on first invocation, not authored)
- [ ] `jq -e . .claude/settings.local.json` — confirm valid JSON after the edit. If `jq` returns non-zero: `cp /tmp/settings.local.json.bak.113 .claude/settings.local.json` to restore, then re-edit carefully.

### Step 3: Smoke test
- [ ] **Untracked path** (default state during this task — no setup needed): `echo '{}' | .cwf/scripts/hooks/stop-uncommitted-changes-warning` — expect JSON with the wf file basenames in systemMessage, exit 0
- [ ] **Staged path**: temporarily stage a wf file (`git add <file>`), invoke hook, verify it appears, `git restore --staged <file>` to revert
- [ ] **Unstaged path**: temporarily modify a committed wf file, invoke hook, verify it appears, `git checkout -- <file>` to revert
- [ ] **Clean path** (commit all wf changes first, then test): expect zero output, exit 0
- [ ] **Non-git cwd**: `(cd /tmp && echo '{}' | /home/matt/repo/coding-with-files/.cwf/scripts/hooks/stop-uncommitted-changes-warning)` — expect zero output, exit 0
- [ ] Exhaustive porcelain-class coverage (UU/AA/DD/RR conflicts, R rename, etc.) deferred to e-testing-plan / g-testing-exec — Step 3 covers the primary three classes which together exercise the parsing pipeline
- [ ] Run `.cwf/scripts/cwf-manage validate` — expect OK

### Step 4: Verify side-by-side with Task 104 hook
- [ ] Confirm both hooks are listed under `hooks.Stop[0].hooks` (`jq '.hooks.Stop[0].hooks | length' .claude/settings.local.json` returns 2)
- [ ] Live verification deferred to g-testing-exec — the hooks fire on real Stop events which can only be observed during normal use

## Validation Criteria
- [ ] Script exists, is executable (mode 0500), and is owned by user
- [ ] Script exits 0 on every test path (clean tree, dirty tree, non-repo cwd)
- [ ] settings.local.json is valid JSON and contains both Stop hook entries
- [ ] Permission allow entry for the new hook is present
- [ ] `cwf-manage validate` passes

## Test Coverage
Concrete cases (formalised in e-testing-plan):
- Clean working tree (no wf changes) → no output, exit 0
- Single untracked wf file → JSON with one basename, exit 0
- Single staged wf file → JSON with one basename, exit 0
- Single unstaged (modified) wf file → JSON with one basename, exit 0
- 4+ dirty wf files → JSON capped at 3 names + "+N more"
- Non-git cwd → no output, exit 0
- Conflict state (`UU`) on a wf file → reported as uncommitted, exit 0

## Decomposition Check
- [x] **Time**: No — well under 1 day
- [x] **People**: No — single developer
- [x] **Complexity**: No — 2 files touched
- [x] **Risk**: No — fully reversible (delete script, remove array entry)
- [x] **Independence**: No — script and registration are coupled

**Result**: 0/5 signals triggered. No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 113
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
