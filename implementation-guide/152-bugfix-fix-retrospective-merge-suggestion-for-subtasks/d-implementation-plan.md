# fix retrospective merge suggestion for subtasks - Implementation Plan
**Task**: 152 (bugfix)

## Task Reference
- **Task ID**: internal-152
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/152-fix-retrospective-merge-suggestion-for-subtasks
- **Template Version**: 2.1

## Goal
Apply the three-file wording change defined in `c-design-plan.md`: replace the hardcoded `git checkout main` suggestion with a parent-aware derivation rule, apply the `sleep 1 && git` prefix to the suggested command, and keep a single source of truth in `retrospective-extras.md`.

## Workflow
Patterns first → Edit → Verify by grep + rendered-example walk-through → Commit message explains "why".

**Edit-anchor convention**: line numbers below are advisory (a snapshot at plan time). The `Edit` tool's `old_string` is the authoritative anchor — use the Before/After strings in the Code Changes section.

## Files to Modify

### Primary Changes
- `.cwf/docs/skills/retrospective-extras.md` — replace the `## Suggest Merge (Step 12)` block (lines 116–123) with the derivation rule + paste-ready `sleep 1 && git …` examples for the top-level and subtask cases, plus the one-line FR4(e) maintainer note (visible italicised text, not an HTML comment).
- `.claude/skills/cwf-retrospective/SKILL.md` —
  - Step 12 (lines 56–58): collapse to a single-line reference to `retrospective-extras.md#suggest-merge-step-12`, matching the existing pattern at Steps 6, 8, 10.
  - Gotcha #2 (line 15): change "Step 10 says 'Suggest Merge'" → "Step 12 suggests the merge". Keep the gotcha title "Never execute merge to main" unchanged — it documents the standing behaviour rule (the merge is never auto-executed regardless of target), and that rule is unchanged by this task.
- `.cwf/docs/workflow/versioning-standard.md` (line 76): "Suggest the merge to main to the user (human action)" → "Suggest the merge to the parent (parent task branch for subtasks; trunk for top-level tasks) — human action".

### Supporting Changes
- `BACKLOG.md` — append two follow-up entries via `backlog-manager add` (bundled into this same task per [[commit-backlog-changes]] memory):
  1. Promote the `sleep 1 && git` prefix convention to a referenced `.cwf/docs/conventions/` doc. Scope (carry over verbatim): Bash-tool git calls and user-facing suggested git ff merge commands only.
  2. Wire the documented trunk-resolution fallback chain (`cwf-project.json:trunk` → `git symbolic-ref refs/remotes/origin/HEAD` → `main`) across `retrospective-extras.md` and `security-review-changeset` when a non-`main` adopter appears or `security-review-changeset` lands it first.

### Files NOT Modified (intentional)
- `.cwf/security/script-hashes.json` — none of the three primary target files are listed (verified at plan time; see Step 4 below for the exact grep that proves it). No hash refresh needed.
- `.cwf/rules-inject.txt:4` (`"Never execute merge to main — suggest the command, do not run it."`) — same rationale as the SKILL.md gotcha title: this is the behaviour rule, not the suggested command. The rule still holds (never execute the suggested merge); broadening its wording is wording-creep beyond the bug.
- No script changes; no new helper.

## Implementation Steps

### Step 1: Edit `retrospective-extras.md`
- [ ] Replace the existing `## Suggest Merge (Step 12)` block with the rendering in Code Changes below.
- [ ] Per design: branch-existence is intentionally not verified — `git checkout` fails loudly on paste. Do **not** add a `git rev-parse --verify` pre-check.

### Step 2: Edit `.claude/skills/cwf-retrospective/SKILL.md`
- [ ] Gotcha #2: change only the step number ("Step 10 says" → "Step 12 suggests the merge — output the command for the user to run, never execute it yourself. Merges are a human decision."). Title stays as-is.
- [ ] Step 12: replace the bullet block per Code Changes below.

### Step 3: Edit `.cwf/docs/workflow/versioning-standard.md`
- [ ] Line 76: replace per Code Changes below.

### Step 4: BACKLOG entries
- [ ] Use `backlog-manager add` for each of the two entries. Field values per Design § Follow-ups.

### Step 5: Verification
- [ ] **Hash-disclosure re-check** (one command, reproducible): `grep -E '"(retrospective-extras\.md|cwf-retrospective/SKILL\.md|versioning-standard\.md)"' .cwf/security/script-hashes.json` — expected: exit 1, no output.
- [ ] **Stale-string grep** (combined; covers both phrases): `grep -rEn 'checkout main && git merge --ff-only|merge to main' .cwf/ .claude/` — expected hits, all benign:
  - `.cwf/docs/skills/retrospective-extras.md` — the literal command inside the **Step-2 example fence** of the new wording (this is the documented example, not a hardcoded suggestion).
  - `.claude/skills/cwf-retrospective/SKILL.md:15` — gotcha title (unchanged behaviour rule).
  - `.cwf/rules-inject.txt:4` — behaviour rule (unchanged).
  - Anything else is a regression.
- [ ] **Hand-render walk-through** for both scenarios (no live helper call needed; the rule itself is what we're checking):
  - Top-level (`152`): hand-apply the derivation rule using values already in scope — `parent_path=""`, `task_type=bugfix`, `task_num=152`, `task_slug=fix-retrospective-merge-suggestion-for-subtasks` → expected suggestion `sleep 1 && git checkout main && git merge --ff-only bugfix/152-fix-retrospective-merge-suggestion-for-subtasks`.
  - Subtask (synthetic `20.2`, no native subtasks in this repo): given hypothetical parent `task_type=feature`, `task_num=20`, `task_slug=reminder-panel`, and current `task_type=feature`, `task_num=20.2`, `task_slug=email-notifications` → expected `sleep 1 && git checkout feature/20-reminder-panel && git merge --ff-only feature/20.2-email-notifications`. (This synthetic case is the cited reporter scenario; end-to-end live verification against a real subtask is out of scope — the CWF repo has no subtasks of its own.)

## Code Changes

(Design wording in `c-design-plan.md` is the canonical source; the renderings below are the implementation-time concrete shape.)

### `retrospective-extras.md` — Suggest Merge (Step 12) — Before
```markdown
## Suggest Merge (Step 12)

(Step 11 — `cwf-version-tag` — runs after the squash; see SKILL.md)

```bash
git checkout main
git merge --ff-only {task-branch}
```
```

### `retrospective-extras.md` — Suggest Merge (Step 12) — After
```markdown
## Suggest Merge (Step 12)

(Step 11 — `cwf-version-tag` — runs after the squash; see SKILL.md)

Derive the merge target from the current task's position in the hierarchy:

1. Run `context-manager hierarchy <task-path> --format=json`. Read `parent_path` and (for the current task's branch name) `task_type`, `task_num`, `task_slug`. The current task branch is `<task_type>/<task_num>-<task_slug>`.
2. If `parent_path` is empty, the task is top-level. Target is `main`. Suggest:
   ```bash
   sleep 1 && git checkout main && git merge --ff-only <current-task-branch>
   ```
3. If `parent_path` is non-empty, the task is a subtask. Run `context-manager hierarchy <parent_path> --format=json`; read the parent's `task_type`, `task_num`, `task_slug`. Parent branch is `<type>/<num>-<slug>`. Suggest:
   ```bash
   sleep 1 && git checkout <parent-branch> && git merge --ff-only <current-task-branch>
   ```
4. If the step-3 helper call exits non-zero, print the helper's stderr and the raw `parent_path` value; do **not** emit a `git checkout` line. The user investigates (renamed/missing parent directory) before retrying.

*Maintainer note: output is for human paste only. If this is ever lifted into a helper that executes the command, switch to list-form `system()` to keep slug interpolation safe.*
```

### `cwf-retrospective/SKILL.md` Step 12 — Before
```markdown
**Step 12 (Next Steps)**:
- **Primary**: Suggest merge to user (do not execute): `git checkout main && git merge --ff-only <task-branch>`
- **Alt**: Create follow-up tasks, share learnings
```

### `cwf-retrospective/SKILL.md` Step 12 — After
```markdown
**Step 12 (Next Steps)**:
- **Primary**: Suggest merge to user (do not execute). Read `.cwf/docs/skills/retrospective-extras.md#suggest-merge-step-12` for the derivation rule (covers top-level and subtask cases).
- **Alt**: Create follow-up tasks, share learnings
```

### `cwf-retrospective/SKILL.md` Gotcha #2 — Before
```markdown
2. **Never execute merge to main**: Step 10 says "Suggest Merge" — output the merge command for the user to run, never execute it yourself. Merges are a human decision.
```

### `cwf-retrospective/SKILL.md` Gotcha #2 — After
```markdown
2. **Never execute merge to main**: Step 12 suggests the merge — output the command for the user to run, never execute it yourself. Merges are a human decision.
```

### `versioning-standard.md` line 76 — Before / After
- Before: `6. Suggest the merge to main to the user (human action)`
- After:  `6. Suggest the merge to the parent (parent task branch for subtasks; trunk for top-level tasks) — human action`

## Test Coverage
**See e-testing-plan.md for complete test plan.** Documentation-only change; tests are the grep assertions and hand-rendered command walk-through above.

## Validation Criteria
**See e-testing-plan.md.** Pass = success criteria in `a-task-plan.md` met (top-level and subtask renderings correct; only benign residual stale-string hits in the listed files).

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

All four edits (three primary files + BACKLOG.md) land in the f-implementation-exec phase commit. No deferral planned.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 152
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
