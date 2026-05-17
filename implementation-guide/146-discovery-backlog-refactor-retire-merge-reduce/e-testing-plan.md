# Backlog refactor: retire, merge, reduce - Testing Plan
**Task**: 146 (discovery)

## Task Reference
- **Task ID**: internal-146
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/146-backlog-refactor-retire-merge-reduce
- **Template Version**: 2.1

## Goal
Verify every acceptance criterion from b-requirements is satisfied by the f-phase commit sequence, plus exercise pre-flight and halt-on-failure paths on synthetic inputs.

## Test Strategy

### Test Levels
- **System**: end-to-end against the real BACKLOG.md / CHANGELOG.md on this branch. Most ACs verify post-batch state.
- **Integration**: pre-flight script's interaction with `CWF::Backlog` / `CWF::Common` against fixture inputs in the scratch dir.
- **Negative**: pre-flight rejects malformed artefacts; helper failure halts the batch (synthetic-input cases).

No unit tests added (per c-design D1: no new code to unit-test). The validator and parser already have their own test suite under `t/` and are exercised in-band by every commit on this branch.

### Test Coverage Targets
- **AC coverage**: 7/7 ACs from b-requirements have a corresponding TC.
- **Pre-flight checks**: 4/4 D8 conditions have a positive case (real artefact) and a negative case (synthetic bad input).
- **Halt protocol**: at least one synthetic failure exercises each of the two D6 paths (pre-commit discard, post-commit revert).

## Test Cases

### Functional (AC-mapping)

- **TC-AC1 -- Coverage equals baseline entry count**
  - **Given**: Step 1 has captured `baseline.sha`; Step 2's `recommendations.md` is committed; Step 3 approval is committed.
  - **When**: `grep -c '^## Recommendation: ' implementation-guide/146-.../recommendations.md` and `git show "$(cat /tmp/.../baseline.sha)":BACKLOG.md | grep -c '^## Task: '` are run.
  - **Then**: both counts are equal. No `## Recommendation:` row is missing a `## Task:` baseline entry, and no baseline entry is unreferenced.

- **TC-AC2 -- Approval precedes content mutations**
  - **Given**: f-phase has completed Step 6 and Step 7.
  - **When**: `git log --oneline -- recommendations.md` and `git log --oneline -- BACKLOG.md CHANGELOG.md` are inspected on this branch.
  - **Then**: the most recent artefact commit (approval or pre-flight resolution) is older than every commit listed by the second command.

- **TC-AC3 -- CHANGELOG seed is the first CHANGELOG mutation on the branch**
  - **Given**: f-phase complete.
  - **When**: `git log --oneline --reverse "$(cat /tmp/.../baseline.sha)..HEAD" -- CHANGELOG.md`.
  - **Then**: the first listed commit is the Step 5 "Seed CHANGELOG block" commit.

- **TC-AC4 -- Per-commit validator and round-trip clean** (worktree replay per d-Step 7)
  - **Given**: f-phase complete; a temp worktree at `/tmp/.../validate-worktree/` is set up.
  - **When**: each commit reachable from `HEAD` and unreachable from `baseline.sha` that touches BACKLOG.md or CHANGELOG.md is checked out into the worktree and `backlog-manager validate` is run.
  - **Then**: every invocation exits 0.

- **TC-AC5 -- Merge-enrichment trace findable in survivor (BACKLOG)**
  - **Given**: f-phase complete; for each `merge` row in the approved artefact, the listed `Carry-overs:` phrases are known.
  - **When**: `grep -F` is run against BACKLOG.md for each phrase (case-sensitive substring; paraphrasing permitted per FR6).
  - **Then**: every listed phrase is findable in BACKLOG.md under the surviving entry's body. (FR6 says the trace lives in the survivor, not in the retired CHANGELOG block -- earlier wording of this TC pointed at CHANGELOG and was incorrect; corrected here.)

- **TC-AC6 -- Diff-scoped ASCII purity on recommendations.md**
  - **Given**: f-phase complete.
  - **When**: `git diff "$(cat /tmp/.../baseline.sha)..HEAD" -- implementation-guide/146-.../recommendations.md | LC_ALL=C grep -cP '^\+.*[^\x00-\x7F]'`.
  - **Then**: output is exactly `0`. (BACKLOG.md / CHANGELOG.md non-ASCII handling is delegated to the validator and round-trip property, both already gated in TC-AC4.)

- **TC-AC7 -- No orphan broken commits**
  - **Given**: f-phase complete.
  - **When**: `git log --oneline "$(cat /tmp/.../baseline.sha)..HEAD"` is inspected.
  - **Then**: every revert commit (if any) pairs with the commit it reverts; the body of every revert commit contains a fenced code block citing the failing tool output; no commit is left in a state that the validator rejects.

### Negative / pre-flight (TC-PF-{1..4})

Each runs the pre-flight script against a synthetic recommendations artefact stored under `/tmp/.../tests/`; not against the real artefact. The fixtures are throwaway.

- **TC-PF-1 -- Slug collision detection**
  - **Given**: a fixture artefact whose `--id=<slug>` matches more than one baseline entry (synthesised by creating two BACKLOG entries whose titles differ only by punctuation, in a fixture BACKLOG.md under the scratch dir).
  - **When**: pre-flight is run.
  - **Then**: exit non-zero; output names the offending slug and suggests `--exact-title=`.

- **TC-PF-2 -- Dangling merge target**
  - **Given**: a fixture artefact whose `merge` row's `Target:` selector matches no other row.
  - **When**: pre-flight is run.
  - **Then**: exit non-zero; output names the offending row and the missing target.

- **TC-PF-3 -- Cycle detection**
  - **Given**: a fixture artefact with rows A merge -> B and B merge -> A.
  - **When**: pre-flight is run.
  - **Then**: exit non-zero; output names the cycle.

- **TC-PF-4 -- Carry-over round-trip safety**
  - **Given**: a fixture artefact whose `merge` row lists a carry-over phrase starting with `### ` or `- Priority:`.
  - **When**: pre-flight splices the phrase into a fixture surviving entry and round-trips through `parse_backlog_tree`.
  - **Then**: round-trip is NOT byte-identical (the parse re-classifies the phrase as metadata or heading); pre-flight exits non-zero; output names the offending carry-over.

### Negative / halt protocol (TC-HALT-{1,2})

- **TC-HALT-1 -- Pre-commit failure (discard path)**
  - **Given**: apply loop is mid-batch; the next row is a synthetic `retire` whose `--id=<slug>` does not match any baseline entry (inject by editing the in-memory artefact for this test run only).
  - **When**: `backlog-manager retire ...` is invoked; it `info`s "not found in BACKLOG (already retired?)" and returns 0; but the validator then reports the original entry still present (no-op).
  - **Then**: the iteration's expected mutation did not happen; `git status` shows no working-tree change; the loop halts and surfaces. (Note: helper's no-op-on-already-retired behaviour means this case does not produce a regression, but the apply loop should still report "no-op observed" for the user's awareness rather than silently advancing.)

- **TC-HALT-2 -- Post-commit failure (revert path)**
  - **Given**: a synthetic post-commit failure (e.g. force a corruption by directly editing BACKLOG.md after the helper-clean commit but before the per-commit validator replay in TC-AC4 -- this test runs in a sandbox branch, not on the working branch).
  - **When**: per-commit replay detects the regression.
  - **Then**: `git revert <bad-sha>` produces a revert commit whose body contains a fenced code block with the validator output; the revert commit itself round-trips clean; the failure is surfaced.

### Non-Functional

- **Performance**: `backlog-manager validate` on the post-batch BACKLOG.md / CHANGELOG.md completes in under 1s (b-NFR1). Measured in g-phase by `time backlog-manager validate`.
- **Security**: every helper invocation uses argv form (no `bash -c`); every revert commit's tool-output paste is fenced (D6). Verified by visual inspection of the commit log.
- **Usability**: `recommendations.md` is plain markdown viewable in any editor. Verified by opening in a text editor and confirming no upper-plane Unicode characters (also covered by TC-AC6).
- **Reliability**: discard-on-failure leaves the working tree at HEAD; revert-on-post-commit-failure leaves history append-only. Both verified by TC-HALT-1 / TC-HALT-2.

## Test Environment

### Setup
- Repo at the Task 146 branch head with all prior phases committed.
- Scratch dir `/tmp/-home-matt-repo-coding-with-files-task-146/` (already created in Step 1 of f-phase) with `baseline.sha`, `preflight.pl`, and a `tests/` subdir for fixture artefacts.
- No external services. No mocks. No fixtures committed to the repo.

### Automation
- All tests are Bash one-liners or pre-flight invocations. No test runner.
- No CI integration: g-phase runs these by hand and records results in `g-testing-exec.md`.

## Validation Criteria
- [ ] All TC-AC{1..7} pass.
- [ ] All TC-PF{1..4} pass (negative-case detection works).
- [ ] All TC-HALT{1,2} pass (halt paths behave correctly under synthetic failure).
- [ ] Non-functional checks (performance, security, usability, reliability) recorded with measurements / observations.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
7/7 TC-AC PASS; 3/4 TC-PF PASS + 1 PARTIAL (TC-PF-4 narrower bash regex; no real-artefact impact); 2/2 TC-HALT PASS via simulation; 4/4 NFR checks PASS. Validator measured at 0.087s.

## Lessons Learned
**TC-AC5 originally pointed the merge-trace grep at CHANGELOG.md** -- FR6 places the trace in the surviving BACKLOG entry. Self-consistent test, wrong artefact. The plan-review subagents missed it because they check internal plan consistency, not FR -> TC fidelity. Lesson: add an explicit "does TC-N interrogate the same artefact FR-M names?" pass to test-plan review. Fix landed in g-phase as commit 9891039.
