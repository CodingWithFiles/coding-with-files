# Refactor BACKLOG to match current code state - Implementation Plan
**Task**: 130 (chore)

## Task Reference
- **Task ID**: internal-130
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/130-refactor-backlog-to-match-current-code-state
- **Template Version**: 2.1

## Goal
Walk every active BACKLOG.md entry interactively with the user; remove obsolete items, edit outdated items, coalesce duplicates. No code changes.

## Workflow
Inventory → triage per entry (user co-review) → batched edits → final cross-doc check.

## Files to Modify
### Primary Changes
- `BACKLOG.md` — sole edit target. Per-entry decisions: remove (work complete), edit (scope shifted), coalesce (duplicate of another entry), keep as-is.

### Supporting Changes
- None expected. If triage uncovers stale references in other docs (e.g. CLAUDE.md, conventions docs) the references are noted and a follow-up task is filed; this task does not touch them.

## Implementation Steps

### Step 1: Inventory
- [ ] **Must do first**: refresh the working list against current HEAD. Grep BACKLOG.md for `^## Task:|^## Bug:` with line numbers and priorities; do not reuse a stale list — the task-plan checkpoint commit alone has shifted no lines, but any subsequent edit will. Re-run if HEAD advances during the task.
- [ ] Note the current baseline (recorded as `26ad3fd` in a-task-plan). If HEAD has advanced, document that and refresh the inventory and cross-checks against the new HEAD before resuming triage.

### Step 1b: Pre-Identified Triage Candidates (advisory, not pre-decided)
The following are flagged from prior context as likely candidates. Triage still walks them with the user; these are starting points, not pre-decisions:
- **Likely remove** — `Add Settings.json Merge Helper Script` (line 317): superseded by `.cwf/scripts/command-helpers/cwf-claude-settings-merge` (idempotent merge, nested keys, dedup, dry-run; tests at `t/cwf-claude-settings-merge.t`).
- **Likely coalesce** — `Lightweight Rollout/Maintenance Templates for Internal Tasks` (line 350, Low) and `Lighter-Weight Rollout/Maintenance Templates for Internal/Developer-Tool Tasks` (line 1820, Medium). The line-1828 note explicitly says the second supersedes the first; merge into one entry, take the higher priority (Medium), and reassess if the combined scope warrants further bump.
- **Needs reclassification** — `Extract CWF Argument Validation Pattern to Documentation` (line 1291) carries `Priority: Needs-Triage`. Triage must reclassify it to a known band (High/Medium/Low/Very Low) or remove it; `Needs-Triage` is not a valid final state.

### Step 2: Triage Pass (per entry)
For each active entry, the user and I agree on one of:

- **Remove** — implementation already shipped (cite commit/task), or the underlying motivation no longer applies.
- **Edit** — partially shipped, scope changed, or framing is stale; rewrite to reflect remaining work.
- **Coalesce** — overlaps with another entry; merge the two and take the higher priority of the pair. Then re-assess: if the combined scope is materially larger than either source, flag for the user to confirm whether the priority should bump further.
- **Keep** — still accurate; no change.

`Needs-Triage` entries must always resolve to one of the four decisions above with a final priority band — they cannot remain `Needs-Triage` in the post-task BACKLOG.

Per-entry checks before deciding:
- [ ] Grep the codebase for the script/file/function the entry names; if it exists, the entry is a candidate for **remove** or **edit**.
- [ ] Before deletion, grep the entry's distinguishing phrase across these locations to catch cross-references: `CLAUDE.md`, `.cwf/docs/conventions/`, `implementation-guide/*/j-retrospective.md`, `BACKLOG.md` itself (forward-references), and `README.md` / `INSTALL.md` / `COMMANDS.md` if present at root.
- [ ] If the entry references "identified in Task N", spot-check that task's outcome via `git log` or the task directory to confirm whether the work was completed.

Order of triage: top-to-bottom by priority band (High → Medium → Needs-Triage → Low → Very Low). Within a band, top-to-bottom by file order.

### Step 3: Apply Edits in Logical Chunks
- [ ] Default approach: a single commit covering all triage decisions, since the expected diff is small (most prior similar chores — Tasks 52, 84 — used one commit).
- [ ] Split into multiple commits only if the cumulative diff is large enough that one diff would be hard to review. If splitting, group by decision type (one commit for all removals, one for edits, one for coalesces) rather than by priority band.
- [ ] Commit messages list each removed/edited/coalesced entry by title and, for removals, cite the implementing commit or task that supersedes it.
- [ ] Skip empty commits — if a band/decision-type yields no changes, don't commit it.

### Step 4: Final Cross-Doc Check
- [ ] After all commits, grep the repo for any reference to entries that were removed (titles, distinguishing phrases) to confirm no orphan links remain in `CLAUDE.md`, `.cwf/docs/conventions/`, `implementation-guide/*/j-retrospective.md`, or root-level `README.md`/`INSTALL.md`/`COMMANDS.md`.
- [ ] Read the resulting BACKLOG.md end-to-end to confirm: grouping is intact, priority bands are still in declared order, no formatting artefacts (orphan `---` separators, double blank lines, empty sections), every active entry has a final priority band (no `Needs-Triage` left behind), and `---` separators sit between every adjacent pair of entries.
- [ ] Run `.cwf/scripts/cwf-manage validate` to catch unrelated regressions introduced by the edits.

### Step 5: Recording Decisions Across Sessions
If triage spans multiple sessions, decisions are recorded in commit messages — the working list is reproducible at any time by re-running the inventory grep against current HEAD and diffing against the original (`git show 26ad3fd:BACKLOG.md`). No external tracking file; if the user pauses mid-session, the next session resumes by re-grepping and skipping entries that have already been removed/edited/coalesced.

## Code Changes
N/A — BACKLOG.md content edits only.

## Test Coverage
**See e-testing-plan.md for complete test plan** (manual review checklist; no executable tests for content edits).

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

If the user pauses the triage mid-pass (e.g. session ends), the in-progress branch is fine to keep — but the task does not move to `g-testing-exec` until every active entry has a decision recorded. Partial triage is not "done".

**If we must defer**:
1. Get user approval with clear rationale
2. Update success criteria to list the specific entries deferred
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
