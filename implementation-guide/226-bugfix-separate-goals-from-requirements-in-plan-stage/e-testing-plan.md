# Separate goals from requirements in plan stage - Testing Plan
**Task**: 226 (bugfix)

## Task Reference
- **Task ID**: internal-226
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/226-separate-goals-from-requirements-in-plan-stage
- **Template Version**: 2.1

## Goal
Verify the KD1–KD6 instruction-doc edits landed correctly and completely. There is no code,
so tests are **deterministic doc-content assertions** (grep / sha256 / `cwf-manage validate`),
which are the binding gates, plus one **confirmatory** behavioural replay.

## Test Strategy
### Test Levels
- **Content assertions (binding)**: grep the edited docs for required/forbidden strings — this
  is the regression suite. A green grep is proof; a red one blocks.
- **Integrity (binding)**: `cwf-manage validate` clean; the `cwf-agent-shared-rules.md` sha256
  in `script-hashes.json` matches, refreshed in the same commit.
- **Propagation (binding)**: grep confirms the reviewer-def→shared-rules links intact and the
  agent defs themselves unmodified by this task.
- **Behavioural replay (confirmatory, soft)**: one scripted scenario. A single green pass is
  not durable proof — it confirms, it does not gate.

### Test Coverage Targets
- 100% of KD1–KD6 covered by at least one binding assertion.
- Every edited file asserted (required strings present, relocated strings absent from origin).

## Test Cases
### Functional Test Cases (binding — deterministic)
- **TC-1 (KD2 remove)**: Given `planning.md` post-edit, When grepped, Then the unfenced prompts
  "What can be removed", "minimal solution", and the "Keeping the system simple…" intro are
  **absent**, and a means-only fence ("applies to the means", "never … the goal") is **present**.
- **TC-2 (KD2 no-orphan)**: Given all task-type phase paths, When checking where "best part is
  no part" now lives, Then it is present (fenced) in universal `planning.md` — so bugfix/hotfix/
  chore still see it — and the challenge-requirements discipline is present in `requirements.md`.
- **TC-3 (KD1 dual-capture)**: Given `planning.md`, `cwf-task-plan/SKILL.md`, and the pool
  template, When grepped, Then each carries the "why AND explicit request / named deliverables"
  instruction and the lossy "single-sentence objective" phrasing is gone from all three.
- **TC-4 (KD1 graceful-empty)**: Given `planning.md` + pool template, Then a "none stated"
  allowance for empty deliverables is present (no pressure to invent).
- **TC-5 (KD3 owner-owned)**: Given `planning.md` + SKILL, Then a "goals are owner-owned / do
  not unilaterally narrow or expand / surface to the owner" statement is present.
- **TC-6 (KD5 checklist)**: Given the `cwf-task-plan` SKILL Success-Criteria list, Then two new
  items (faithful why+request capture; surface scope changes) are present.
- **TC-7 (KD4 rule)**: Given `cwf-agent-shared-rules.md`, Then a new top-level section
  `## Goal integrity and scope changes` exists with the "never a silent de-scope target" rule.
- **TC-8 (KD4 propagation)**: Given the ~10 reviewer agent defs, When grepped, Then all still
  contain the `cwf-agent-shared-rules` link; When `git diff` is checked, Then none of the agent
  defs were modified by this task (only shared-rules changed).
- **TC-9 (KD6 hash integrity)**: Given the edited `cwf-agent-shared-rules.md`, Then its
  `script-hashes.json` sha256 matches `sha256sum` output, `cwf-manage validate` is clean, and
  the manifest change is in the same commit as the doc change.
- **TC-10 (template integrity)**: Given the pool template edit, Then all 5 per-type
  `a-task-plan.md.template` symlinks still resolve to the pool source, and a freshly-created
  scratch task renders the new dual-capture Goal placeholder.

### Non-Functional Test Cases
- **TC-11 (Reliability — replay, CONFIRMATORY/soft)**: Given a mock request naming two explicit
  deliverables (e.g. "add X with mode=a **and** mode=b"), When a fresh planning pass runs, Then
  the Goal records both deliverables (not narrowed to a single "why"), and no reviewer proposes
  silently deferring a named deliverable — it surfaces the scope question instead. Not a gate.
- **Usability**: edited instruction prose reads cleanly and matches each doc's existing voice
  (manual read).

## Test Environment
### Setup Requirements
- The repo working tree after the f-exec edits; no external services, no test DB, no framework.
- Tools: Grep/Read, `sha256sum`, `cwf-manage validate`, `git diff`.

### Automation
- TC-1…TC-10 are shell-grep/`sha256sum`/`validate` one-liners, runnable in g-testing-exec and
  re-runnable as a regression check. TC-11 is a manual/scripted confirmatory replay.

## Validation Criteria
- [ ] TC-1…TC-10 (binding) all pass; `cwf-manage validate` clean.
- [ ] TC-11 (confirmatory) shows no goal-narrowing and no silent de-scope — logged, not gating.
- [ ] Every KD1–KD6 covered by ≥1 binding assertion.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1…TC-10 (binding, deterministic grep/sha256/validate/render) all PASS; TC-11
(confirmatory replay) satisfied by inspection, recorded not gated. See `g-testing-exec.md`.

## Lessons Learned
A behavioural-instruction fix is only as testable as its incident anchor: because the plan
recorded the concrete Task-31 failure chain, TC-11 could be stated at all. The no-orphan
assertion (TC-2, maxim present in *both* docs) is the pattern worth reusing for relocations.
