# task inference not subtask-aware - Implementation Plan
**Task**: 166 (bugfix)

## Task Reference
- **Task ID**: internal-166
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/166-task-inference-not-subtask-aware
- **Template Version**: 2.1

## Goal
Translate the c-design-plan decisions D1–D3 into a concrete, ordered file-by-file edit list, with hash-refresh disclosure and a complete validation sequence.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why".

The single executable commit lands all of D1+D2+D3+tests+hash-refresh together (per D5 "must land together — not independently shippable"). No partial check-in.

## Files to Modify
### Primary Changes
- `.cwf/lib/CWF/TaskContextInference.pm` — the entire defect surface. Concrete edits per Implementation Step 2 below. Working perms stay at `100644` (no `permissions` key in manifest — verified, Assumption 5 of c-design-plan).

### Supporting Changes
- `t/taskcontextinference.t` — append 8 new subtests covering the validation cases enumerated in c-design-plan §Validation. New file? No — append to the existing test file.
- `.cwf/security/script-hashes.json` — refresh the `sha256` entry at line 84 for `CWF::TaskContextInference` per [[hash-updates]]. The `task-context-inference` script entry (line 281) is **not** refreshed because the script is unchanged (D1 confirms: thin CLI wrapper, no edit needed).

### Files Explicitly NOT Modified
- `.cwf/scripts/command-helpers/task-context-inference` — script is unchanged (interface stability per c-design-plan §Interface Design).
- `.cwf/lib/CWF/TaskPath.pm` — already implements every primitive we need (Verified Assumption 2). No edit.
- `.cwf/lib/CWF/TaskState.pm` — `state_achievable($task_dir)` consumed unchanged; we just pass it `full_path` from `resolve_num` instead of a constructed string.

## Implementation Steps

### Step 1: Patterns (read existing call sites before editing)
- [ ] Re-read `TaskContextInference.pm` lines 230-431 (the five signal collectors) to confirm no other regex or `opendir` site was missed.
- [ ] Re-read `TaskPath.pm` lines 109-200 (`resolve_num`, `resolve_branch`), 373-403 (`find_children`), 447-480 (`find_ancestors`, `find_descendants`), 414-435 (`find_siblings` — the existing top-level-scan precedent) to confirm return-hashref shapes and the proper primitive for each call site.
- [ ] (No grep needed for callers of `_get_task_dir`/`_get_task_slug`; both are `_`-prefixed private and not exported. The Step 5 pre-commit grep covers post-edit verification.)

### Step 2: Code changes in `CWF::TaskContextInference`

Order is bottom-up: imports → enumeration helper → signals → correlator → caller glue. The correlator stays a pure function (its only inputs are signal hashes; resolution is the caller's job, applied review finding "drop `chosen_resolved`").

- [ ] **Add** `use CWF::TaskPath qw(parse_dirname resolve_num resolve_branch find_descendants find_ancestors find_base_dir get_depth);` near the top, beside `use CWF::TaskState`.

- [ ] **Add** new private helper `_enumerate_all_tasks()` returning a list of `{num, full_path}` hashrefs covering every top-level task and every descendant. Justification against Rule of Three: two internal callers (recency, progress) plus the test fixture's enumeration assertion ≥ 3 distinct uses within this change. Promotion of this scan into `CWF::TaskPath` (with `find_siblings`'s identical top-level loop folded in) is deliberately deferred to the *Unify implementation-guide directory-scan helpers* backlog item — the wider blast radius (changing `find_siblings`'s call sites elsewhere) does not belong in this bugfix.
  - Use `my $base = find_base_dir() // 'implementation-guide';` (parity with `CWF::TaskPath::build_glob`'s pattern, avoids the existing hardcode-`'implementation-guide'` smell in the new code).
  - `glob("$base/*-*-*")`, parse each dirname via `parse_dirname`, skip entries whose `num` contains a dot (defensive: `next if $num =~ /\./;`).
  - For each surviving top-level entry `T`, push `{num, full_path}` for `T` itself, then push `find_descendants($T->{num})` results (which are already in the canonical hashref shape).
  - Termination is guaranteed by `find_descendants`/`find_children` recursing strictly by increasing `get_depth`; no cycle guard required.

- [ ] **`_get_branch_signal`**: replace `m{^[^/]+/(\d+)-}` with a single call to `resolve_branch($branch)` (which composes `parse_branch` + `resolve_num`). On undef return, signal is null. On hashref return, `top => $resolved->{num}` (decimal-form string, which is what we want for the correlator).

- [ ] **`_get_recency_signal`**: drop the `opendir` + `^(\d+)-` block. Iterate `_enumerate_all_tasks()`, compute `_get_dir_max_mtime($task->{full_path})` per entry, retain the existing exponential-decay scoring, the descending sort, and the `splice(@candidates, 0, 5)` cap. `_get_dir_max_mtime` is still single-level by design — per-task semantics unchanged; only the set of *task dirs* it's called on widens.

- [ ] **`_get_progress_signal`**: same shape as recency — iterate `_enumerate_all_tasks()`, call `_calculate_task_progress($task->{full_path})`, retain the score-positive filter and the top-5 cap.

- [ ] **Delete** `_get_task_dir` (lines 560-578) and `_get_task_slug` (lines 491-509) outright.

- [ ] **`_infer_workflow_step`**: change signature from `$task_num` to `$task_dir`. The function body never used `$task_num` after the `_get_task_dir` lookup; all current logic is purely directory-driven (workflow-file scan for `In Progress`, then most-recent-mtime fallback). Removing the lookup is a net deletion. Update both internal call sites (correlated and uncorrelated branches of `infer_task_context`) to pass `$resolved->{full_path}` in (next bullet).

- [ ] **`correlate_signals`**: implement the 8-step predicate from c-design-plan §D3 verbatim. Keep the function **pure** — no `resolve_num` calls on its return shape. Existing return keys (`confidence`, `chosen_task`, `candidates`, `signals`, `top_tasks`) unchanged. Internal use of `get_depth` is fine — it's a pure string operation on dotted task numbers. Internal use of `resolve_num`/`find_ancestors` (step 5/6 of D3) is filesystem-driven but acceptable: the predicate inherently requires checking ancestry on disk.

- [ ] **`infer_task_context` glue**:
  - **Conclusive path** (today lines 101-115): after `correlate_signals` returns `chosen_task`, call `my $resolved = resolve_num($task_num);` once. Derive `task_slug = ($resolved // {})->{slug} // 'unknown'` and `workflow_step = _infer_workflow_step(($resolved // {})->{full_path})`.
  - **Uncorrelated path** (today lines 74-77): iterate candidates; for each, `my $r = resolve_num($task);`, then `push @task_slugs, ($r // {})->{slug} // 'unknown'; push @workflow_steps, _infer_workflow_step(($r // {})->{full_path}) // 'unknown';`. One `resolve_num` per candidate (unavoidable — N candidates).
  - **No-signals path**: unchanged.

- [ ] **Remove** any stale comment lines referencing the deleted helpers.

### Step 3: Append regression tests to `t/taskcontextinference.t`
- [ ] **Concrete subtests deferred to `e-testing-plan.md`** — that phase owns the 1-to-1 mapping from c-design-plan §Validation test-level bullets to subtests, including which existing subtests already cover which baseline cases. This plan binds f-implementation-exec to "tests for every Validation bullet exist and pass"; it does not pre-count them.
- [ ] **Test-isolation rule**: any subtest that needs a tempdir fixture for `resolve_num`/`find_descendants` must `my $saved = Cwd::getcwd; chdir $tmpdir; …; chdir $saved;` *inside the subtest* — restore cwd before `done_testing` (the temp `CLEANUP => 1` runs at interpreter exit; leaving cwd inside it triggers `rmtree` warnings on some platforms). No END-block-based cwd restore.
- [ ] **No new non-core deps**. `Test::More`, `File::Temp`, `Cwd`, `FindBin` are all already used by the file (or are core). `File::chdir` is non-core and is **not** introduced ([[feedback-perl-core-only]]).

### Step 4: Hash refresh and validate
- [ ] After all source edits, `sha256sum .cwf/lib/CWF/TaskContextInference.pm` and replace the matching `sha256` value in `.cwf/security/script-hashes.json` (entry at line 84 — `CWF::TaskContextInference`). The single-commit constraint of this task (§Scope Completion) makes the [[hash-updates]] per-file `git log <last-hash-set-commit>..HEAD -- <path>` pre-refresh check inapplicable here — the source edit and the hash refresh land together, so there is no intervening commit to verify. State this in the f-exec commit body for the archivist.
- [ ] Run `.cwf/scripts/cwf-manage validate` — must report clean.
- [ ] Run `prove -v t/taskcontextinference.t` — must be green (existing subtests + the new ones from e-testing-plan).
- [ ] Run full `prove -r t/` — must be green (no regressions in sibling tests).

### Step 5: Pre-commit verification (mechanical)
- [ ] `git diff --stat` to confirm only the three files above (`.pm`, `t/taskcontextinference.t`, `script-hashes.json`) are touched.
- [ ] `git diff` review against c-design-plan §D1–D3 — every bullet maps to a visible diff hunk.
- [ ] `git grep -nE '\([\\]d\+\)' .cwf/lib/CWF/TaskContextInference.pm` — must return only the `_get_state_file_signal` line (which keeps `(\d+(?:\.\d+)*)` per Assumption 4). All other bare `(\d+)` regex must be gone.
- [ ] `git grep -nE '_get_task_(dir|slug)' .cwf/` — must return 0 results (helpers fully deleted).
- [ ] No working-perm restore needed — the .pm has no `permissions` key per Assumption 5.

## Code Changes
**See c-design-plan.md §Key Decisions D1–D3 for rationale.** This plan deliberately does **not** repeat code-shape diagrams — the design's decision text plus the file-by-file edit list above is the single source of truth for what changes.

## Test Coverage
**See e-testing-plan.md for the complete test plan.** This implementation plan binds 8 subtests to the validation cases listed in c-design-plan §Validation (test-level). e-testing-plan will expand each into concrete assertions, fixtures, and Tier classification.

## Validation Criteria
**See e-testing-plan.md for execution-level validation.** This plan's binding criteria for declaring f-implementation-exec complete:
- Implementation Step 5 pre-commit checks all pass.
- `cwf-manage validate` clean.
- `prove -r t/` green.
- `git diff` review against this plan and c-design-plan shows full coverage with no out-of-scope edits.

## Scope Completion
**IMPORTANT**: All of D1+D2+D3+tests+hash-refresh land in one commit. No deferred work; no follow-up tasks required by design. If during exec a hidden dependency surfaces (e.g. an unexpected caller of `_get_task_dir`), surface it and revise this plan rather than deferring.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 166
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All Step-1..Step-5 items executed. Diff stat: `.pm` net +197/-93, `t/taskcontextinference.t` +234, `script-hashes.json` +1/-1. Step 5 grep description had a minor inaccuracy — the `\(\\d\+\)` literal pattern matches the worktree line (preserved per D4), not the state-file line (which uses `(\d+(?:\.\d+)*)`). Substantive scope contract upheld; deviation recorded in f-implementation-exec.md.

## Lessons Learned
- When a plan asserts a grep result, derive it by running the grep — don't read it off the code by inspection. The state-file regex is *not* a bare `(\d+)`, so the grep flagged a different line than the plan claimed it would. The safety-net intent held; the description didn't.
- Files modified counter was correct (3 — `.pm`, `t/`, `script-hashes.json`); files NOT modified was correct (`task-context-inference`, `CWF::TaskPath`, `CWF::TaskState` all unchanged).
