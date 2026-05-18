# fix retrospective merge suggestion for subtasks - Testing Plan
**Task**: 152 (bugfix)

## Task Reference
- **Task ID**: internal-152
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/152-fix-retrospective-merge-suggestion-for-subtasks
- **Template Version**: 2.1

## Goal
Verify the documentation-only wording changes produce the correct paste-ready merge command for both top-level and subtask cases, and leave no live hardcoded `git checkout main` suggestion in shipped CWF prose.

## Test Strategy

This is a documentation-only task. There is no executable code under test; the artefact is wording in three markdown files plus two BACKLOG entries. The "tests" are deterministic grep assertions plus a hand-rendering of the derivation rule against two known inputs.

### Test Levels
- **Static text**: grep-based assertions over `.cwf/` and `.claude/` for stale/regressed strings.
- **Rendering**: hand-apply the derivation rule from `retrospective-extras.md` to two scenarios (top-level and subtask) and compare the produced command against the expected string.
- **Integration (light)**: confirm `context-manager hierarchy <task-path> --format=json` still emits the JSON fields the derivation rule names (`parent_path`, `task_type`, `task_num`, `task_slug`) — pre-existing behaviour, smoke-tested for regression.
- **Validate**: run `.cwf/scripts/cwf-manage validate` post-commit; the only expected finding is the pre-existing `.claude/agents/cwf-plan-reviewer-misalignment.md` permission drift (tracked in BACKLOG, unrelated to this task).

### Test Coverage Targets
- 100% of the three primary files edited contain the new wording.
- 0 residual live hits on the two stale phrases (`checkout main && git merge --ff-only`, `merge to main`) outside the explicit allow-list documented in `d-implementation-plan.md` Step 5.
- Both scenarios in the hand-rendering produce the exact expected command string.

## Test Cases

### TC-1: top-level task renders to `main`
- **Given**: a hypothetical top-level task `152` with `task_type=bugfix`, `task_slug=fix-retrospective-merge-suggestion-for-subtasks`, and `context-manager hierarchy 152 --format=json` reporting `parent_path=""`.
- **When**: the maintainer follows the derivation rule in the new `## Suggest Merge (Step 12)` section.
- **Then**: the rule produces exactly `sleep 1 && git checkout main && git merge --ff-only bugfix/152-fix-retrospective-merge-suggestion-for-subtasks`.

### TC-2: subtask renders to parent task branch (not `main`)
- **Given**: a hypothetical subtask `20.2` with parent `task_type=feature`, parent `task_num=20`, parent `task_slug=reminder-panel`, current `task_type=feature`, current `task_num=20.2`, current `task_slug=email-notifications`, and `context-manager hierarchy 20.2 --format=json` reporting `parent_path="20"`.
- **When**: the maintainer follows the derivation rule.
- **Then**: the rule produces exactly `sleep 1 && git checkout feature/20-reminder-panel && git merge --ff-only feature/20.2-email-notifications` (i.e. **not** `main`).

### TC-3: parent helper failure produces no `git checkout` line
- **Given**: a subtask where step-3 of the derivation rule's helper call (`context-manager hierarchy <parent_path> --format=json`) exits non-zero (e.g. parent directory renamed).
- **When**: the maintainer follows the derivation rule.
- **Then**: the rule prints the helper's stderr and the raw `parent_path` value, and emits **no** `git checkout` line. The user investigates before retrying.

### TC-4: no live hardcoded `main` suggestion remains in shipped prose
- **Given**: the post-implementation tree.
- **When**: running `grep -rEn 'checkout main && git merge --ff-only|merge to main' .cwf/ .claude/`.
- **Then**: every hit appears in the documented allow-list (`d-implementation-plan.md` Step 5):
  - `.cwf/docs/skills/retrospective-extras.md` — Step-2 example fence of the new wording.
  - `.claude/skills/cwf-retrospective/SKILL.md:15` — gotcha title (unchanged behaviour rule).
  - `.cwf/rules-inject.txt:4` — behaviour rule (unchanged).
  - No other hits.

### TC-5: hash-disclosure assertion holds
- **Given**: the three primary target files.
- **When**: running `grep -E '"(retrospective-extras\.md|cwf-retrospective/SKILL\.md|versioning-standard\.md)"' .cwf/security/script-hashes.json`.
- **Then**: exit code 1, no output. (No hash refresh required this commit.)

### TC-6: SKILL.md Step 12 follows the existing single-line reference pattern
- **Given**: the post-implementation `.claude/skills/cwf-retrospective/SKILL.md`.
- **When**: inspecting Step 12.
- **Then**: Step 12's Primary bullet ends with a `Read \`.cwf/docs/skills/retrospective-extras.md#suggest-merge-step-12\` for the derivation rule …` reference, matching the style of Steps 6, 8, 10.

### TC-7: BACKLOG entries added cleanly
- **Given**: BACKLOG.md after `backlog-manager add` for the two follow-ups.
- **When**: running `.cwf/scripts/command-helpers/backlog-manager validate`.
- **Then**: exit 0, no format errors. Both new entries visible at `backlog-manager list`.

### TC-8: `context-manager hierarchy --format=json` smoke-test (regression guard)
- **Given**: the existing helper.
- **When**: running `.cwf/scripts/command-helpers/context-manager hierarchy 152 --format=json`.
- **Then**: output is valid JSON containing keys `parent_path`, `task_type`, `task_num`, `task_slug`. (Pre-existing behaviour; this test guards against an unrelated helper change silently breaking the derivation rule.)

### Non-Functional Test Cases
- **Security**: no new code; FR4(a)–(e) review of the design and implementation plans already passed (security-reviewer agent in both rounds returned "no actionable findings"). No re-test needed.
- **Performance**: N/A — doc-only change.
- **Usability**: covered by TC-1/TC-2 (the user-visible artefact is the paste-ready command string; the hand-rendering verifies the human-readable shape).
- **Reliability**: covered by TC-3 (explicit failure-mode behaviour).

## Test Environment

### Setup Requirements
- Working `git` and the existing `.cwf/scripts/command-helpers/` tree.
- `bash` for the grep one-liners (already required by CWF).
- No new tooling, no test database, no mocks.

### Automation
- All assertions are single-command bash invocations; no test framework involved.
- TC-1 and TC-2 are hand-rendered against the rule (LLM applies the four-step procedure to the named inputs). No fixture data.
- The CWF repo has no native subtasks, so TC-2 uses the reporter's `20.2` scenario as a hypothetical. End-to-end verification against a real subtask is out of scope per `d-implementation-plan.md` Step 5.

## Validation Criteria
- [ ] TC-1 through TC-8 all pass.
- [ ] `cwf-manage validate` reports no new violations beyond the pre-existing `cwf-plan-reviewer-misalignment.md` permission drift.
- [ ] No regression in `context-manager hierarchy --format=json` JSON shape.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 152
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
