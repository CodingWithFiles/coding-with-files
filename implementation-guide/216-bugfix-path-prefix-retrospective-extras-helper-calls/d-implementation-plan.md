# Path-prefix retrospective-extras helper calls - Implementation Plan
**Task**: 216 (bugfix)

## Task Reference
- **Task ID**: internal-216
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/216-path-prefix-retrospective-extras-helper-calls
- **Template Version**: 2.1

## Goal
Prefix the 5 bare helper invocations in `.cwf/docs/skills/retrospective-extras.md`
with `.cwf/scripts/command-helpers/`, per the approved design.

**Why it matters (deeper than guess-then-search)**: `.claude/settings.json` keys its
Bash allowlist on the *prefixed* paths (e.g. `Bash(.cwf/scripts/command-helpers/checkpoints-branch-manager:*)`,
`…/context-manager:*`). A bare invocation misses the allowlist entirely and triggers
a permission prompt mid-retrospective — so prefixing removes both the path guess *and*
the prompt.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/docs/skills/retrospective-extras.md` — prefix 5 executed helper invocations (lines 91, 99, 111, 122, 127)

### Supporting Changes
- None. Not tracked in `script-hashes.json` → no hash refresh. No test-file changes required (validation is a grep gate, see below).

## Implementation Steps
### Step 1: Apply the 5 edits (line-scoped Edit calls, not name-wide replace)
- [ ] L91  `checkpoints-branch-manager create` → `.cwf/scripts/command-helpers/checkpoints-branch-manager create`
- [ ] L99  `checkpoints-branch-manager show-history  # Find base commit` → prefixed
- [ ] L111 `checkpoints-branch-manager verify` → prefixed
- [ ] L122 inline `` `context-manager hierarchy <task-path> --format=json` `` → `` `.cwf/scripts/command-helpers/context-manager hierarchy <task-path> --format=json` ``
- [ ] L127 inline `` `context-manager hierarchy <parent_path> --format=json` `` → prefixed

### Step 2: Do NOT touch
- [ ] L86/L118 prose pointers `cwf-version-bump` / `cwf-version-tag` (defer to SKILL.md) — leave bare
- [ ] L21 `workflow-manager` and L45 `cwf-manage` — already correctly pathed, no double-prefix

### Step 3: Validation (grep gate)
- [ ] `grep -nE '(checkpoints-branch-manager|context-manager)' .cwf/docs/skills/retrospective-extras.md | grep -v 'command-helpers/'` returns nothing
- [ ] `.cwf/scripts/cwf-manage validate` clean

**Gate scope decision**: the alternation is limited to the two helpers being fixed.
It is *not* widened to `workflow-manager|cwf-manage` — `cwf-manage` lives at
`.cwf/scripts/cwf-manage` (not under `command-helpers/`), so the `grep -v 'command-helpers/'`
filter would false-positive on the already-correct line 45.

## Code Changes
### Before (representative — fenced block, Step 10.1)
```bash
checkpoints-branch-manager create
```
### After
```bash
.cwf/scripts/command-helpers/checkpoints-branch-manager create
```
### Before (representative — inline, Step 12.1)
Run `context-manager hierarchy <task-path> --format=json`. Read `parent_path` …
### After
Run `.cwf/scripts/command-helpers/context-manager hierarchy <task-path> --format=json`. Read `parent_path` …

## Test Coverage
**See e-testing-plan.md** — verification is the grep gate above plus `cwf-manage validate`; no unit test applies to a prose doc.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

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
All 5 line-scoped edits applied verbatim; the pre-edit content read confirmed the plan's line numbers were still accurate. Grep gate green, validate clean.

## Lessons Learned
The allowlist "why" enrichment (bare invocation misses the settings.json Bash allowlist) turned a cosmetic-looking fix into a runtime-behaviour fix — worth capturing in the commit message, which it was.
