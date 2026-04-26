# Build uncommitted changes warning Stop hook - Implementation Execution
**Task**: 113 (feature)

## Task Reference
- **Task ID**: internal-113
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/113-build-uncommitted-changes-warning-stop-hook
- **Template Version**: 2.1

## Goal
Execute the implementation per d-implementation-plan.md.

## Actual Results

### Step 1: Write the hook script
- **Planned**: Perl script at `.cwf/scripts/hooks/stop-uncommitted-changes-warning` with `#!/usr/bin/perl -CDSL`, `use strict; use warnings;`, `eval` block running `git status --porcelain -z --untracked-files=all`, NUL-split parsing, basename via Task 104 idiom, capped output, single trailing `exit 0`. `chmod 0500`.
- **Actual**: Script written and chmod'd. **Deviation**: added `use utf8;` after smoke testing revealed double-encoded mojibake on the literal `⚠` glyph. Plan said to use the JSON-escape `\\u26a0` (matching Task 104), but during exec we switched to the literal `⚠` for cleaner output and consistency with the `-CDSL` UTF-8-native philosophy. `-CDSL` covers I/O streams but not source encoding; without `use utf8;` the source bytes get treated as Latin-1 and double-encoded on output. Confirmed fix by inspecting bytes (`xxd` shows `e2 9a a0` — correct UTF-8 for U+26A0).

### Step 2: Register hook in settings
- **Planned**: backup → append second command object to `hooks.Stop[0].hooks` → add relative-path permission allow entry → `jq -e .` to confirm valid JSON.
- **Actual**: backup written to `/tmp/settings.local.json.bak.113`. Both edits applied via Edit tool. `jq -e .` returned valid. `jq '.hooks.Stop[0].hooks | length'` → 2 (both hooks present). The harness auto-added an absolute-path permission entry (`/home/matt/repo/coding-with-files/.cwf/scripts/hooks/stop-uncommitted-changes-warning`) on first invocation, identical to what happened for Task 104's hook — expected and benign.

### Step 3: Smoke test
- **TC: Untracked path** — current working tree has 5 untracked wf files (f, g, h, i, j); hook output: `{"systemMessage":"⚠ Uncommitted: f-implementation-exec.md, g-testing-exec.md, h-rollout.md +2 more"}`, exit 0. ✓
- **TC: Staged path** — `git add f-implementation-exec.md`; hook fires correctly, exit 0. ✓
- **TC: Unstaged path** — appended a space to `a-task-plan.md` (committed); hook reported it at the front of the list, exit 0. Reverted with `git checkout --`. ✓
- **TC: Non-git cwd** — `(cd /tmp && echo '{}' | <abs-path>)`; empty stdout, exit 0. ✓
- Conflict-state test (`UU`/`AA`/`DD`) deferred to g-testing-exec per plan.
- `cwf-manage validate` → OK.

### Step 4: Verify side-by-side with Task 104 hook
- `jq '.hooks.Stop[0].hooks | length'` → 2 ✓
- Both entries have `timeout: 5` ✓
- Live verification (both hooks firing on the same Stop event) deferred to g-testing-exec.

## Deviations from Plan
1. **Added `use utf8;`** — caught during smoke testing (script emitted double-encoded UTF-8 because `-CDSL` doesn't cover source encoding). Updated `docs/conventions/perl-git-paths.md` to document this gotcha alongside the `-CDSL`/`-z` convention.
2. **Switched from `\\u26a0` JSON escape to literal `⚠`** — cleaner output, consistent with the `-CDSL` UTF-8-native approach. The plan specified `\\u26a0` to mirror Task 104; during exec we judged the literal cleaner now that the convention supports UTF-8 end-to-end.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (SC1–SC5)
  - SC4 reads "settings.json" but actual location is `settings.local.json` — corrected during requirements phase (b/AC5); a-plan still has the old wording.
- [x] All requirements from b-requirements-plan.md addressed (AC1–AC6 covered by Step 3 smoke tests; AC6 live observation deferred to g)
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred without rationale (conflict + AC6 live observation deferred to g-testing-exec, which is the appropriate phase)

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 113
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- `-CDSL` ≠ `use utf8;`. The shebang governs I/O streams; the pragma governs source bytes. If the source contains non-ASCII literals, both are required. Worth a permanent note in the conventions doc (done).
- Hand-construct JSON via `qq()` is fine for one-line outputs, but if more fields land here later we should consider `JSON::PP` (core module) to avoid manual escaping.
