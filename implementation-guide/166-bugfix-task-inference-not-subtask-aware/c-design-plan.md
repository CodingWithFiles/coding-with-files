# task inference not subtask-aware - Design
**Task**: 166 (bugfix)

## Task Reference
- **Task ID**: internal-166
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/166-task-inference-not-subtask-aware
- **Template Version**: 2.1

## Goal
Define the minimal architectural changes that let `CWF::TaskContextInference` enumerate active subtasks and converge on the deepest active descendant when ancestor signals are present.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Verified Assumptions
1. **Subtasks share their parent's branch** — `/cwf-new-subtask` (verified in `.claude/skills/cwf-new-subtask/SKILL.md`) creates a directory only; it does **not** run `git checkout -b`. Therefore the `branch` signal returning the top-level number for an active subtask is *correct behaviour*, not a bug. The defect lives in directory enumeration and ancestor/descendant resolution, not in branch parsing.
2. **`CWF::TaskPath` already implements subtask-aware path operations** — `parse_dirname`, `parse_branch`, `resolve_num` (iterative ancestor walk), `find_descendants`, `find_ancestors`, `find_parent`, `get_depth` all handle decimal task numbers and nested directories. Canonical regex: `^(\d+(?:\.\d+)*)-(\w+)-(.+)$`. Reuse, don't duplicate.
3. **Test scaffolding exists** — `t/taskcontextinference.t` already exercises `correlate_signals`, `format_output`, and `get_all_signals`. New regression tests for subtask scenarios slot in alongside existing subtests.
4. **State-file signal already decimal-aware** — `_get_state_file_signal` uses `(\d+(?:\.\d+)*)` and parses task-stack entries correctly. No change needed in this task. (Full convergence to `CWF::TaskPath::parse_dirname` is the scope of the backlog item *Unify implementation-guide directory-scan helpers across `CWF::Backlog` and `CWF::TaskContextInference`*, not this bugfix.)
5. **Hashed files — verified** — `CWF::TaskContextInference` entry (manifest line 82) has **no `permissions` key** → working perms stay at default `100644`. `task-context-inference` entry (manifest line 278) declares `"permissions": "0500"` → working perms must be chmod `0700` per [[feedback-hashed-script-working-perms]] for the duration of edits. Hash refresh for both lands in this same task per [[hash-updates]].

## Key Decisions

D1 and D2 together create the agreed-on candidate set; D3 then closes the conclusive case. The three are interdependent and must land in one commit — none of them is independently shippable.

### D1. Delegate task-path parsing and resolution to `CWF::TaskPath`
- **Decision**: Eliminate every bare `\d+`-style task-number regex and every single-level `opendir` of `implementation-guide/` from `CWF::TaskContextInference`. After this task, **no task-number parsing remains in-module** (state-file signal excluded per Assumption 4). Specific replacements:
  - `_get_branch_signal`: replace `^[^/]+/(\d+)-` capture with `CWF::TaskPath::parse_branch($branch)`. (Resolves the D1/D5 consistency concern: even though subtask branches are not a convention today, parsing via the canonical helper is harmless for top-level branches and removes the last in-module regex.)
  - `_get_recency_signal` and `_get_progress_signal`: replace the top-level scan + `^(\d+)-` regex with the enumeration in D2; per-directory parsing uses `CWF::TaskPath::parse_dirname`.
  - `_get_task_dir` and `_get_task_slug`: **delete these helpers outright**. Their call sites collapse to a single `CWF::TaskPath::resolve_num($task_num)` whose returned hashref already carries `full_path` and `slug`. `_infer_workflow_step` becomes correct-by-derivation once it consumes `resolve_num(...)->{full_path}` instead of the deleted `_get_task_dir`.
  - `_get_worktree_signal`: **unchanged**. (See D4 — out of scope.)
- **Rationale**: `CWF::TaskPath` already encodes the canonical regex, the iterative ancestor walk (`resolve_num`), and recursive enumeration (`find_descendants`). Reuse over duplication ([[feedback-design-tradeoff-priority]]). Deleting the two helpers is a net reduction of code and a direct response to the backlog item *Unify implementation-guide directory-scan helpers across `CWF::Backlog` and `CWF::TaskContextInference`* (partial execution; full CWF::Backlog convergence remains separate).
- **Trade-offs**: Adds a `use CWF::TaskPath` import. No new code surface; net reduction.

### D2. Recency and progress signals enumerate top-level **plus** every descendant
- **Decision**: Build each signal's candidate set as `{T} ∪ find_descendants(T)` for every top-level task `T`. Top-level enumeration uses TaskPath: `glob("$base_dir/*-*-*")` filtered via `parse_dirname` (no dot in `num`). Per-task mtime / progress calculation is unchanged — the change is solely *which* directories enter the candidate set. The existing `splice(@candidates, 0, 5)` cap stays.
- **Rationale**: Subtask dirs sit inside parent dirs; today's single-level `opendir` cannot see them. With this change recency and progress can finally surface `28.2` as their top candidate when the user's recent work is in a subtask.
- **Trade-offs**: For repos with deep subtask nesting the candidate set grows (was ~150, becomes ~150 + descendants). `find_descendants` recurses via `find_children` which `resolve_num`s each child, so cost is O(descendants × depth) `glob` calls per inference run. Per design-priority order (correctness > maintainability > performance), this is acceptable; we do not optimise as part of this bugfix. If a future measurement shows it dominates, a memoised single-pass enumerator in `CWF::TaskPath` is the natural follow-up.

### D3. Ancestry-collapse rule in `correlate_signals` — deterministic predicate
- **Decision**: Replace today's string-equality unique-check with the following algorithm:
  1. Let `U` = the set of non-null signal top tasks (deduplicated).
  2. If `|U| == 1`: return `correlated`, `chosen_task = U[0]` (today's path, unchanged).
  3. Otherwise compute `depth(t)` via `CWF::TaskPath::get_depth(t)` for each `t ∈ U`. Let `D` be the subset with maximum depth.
  4. If `|D| > 1`: return `uncorrelated` (tied deepest on disjoint branches — e.g. `{28.2, 28.3}`).
  5. Let `deepest = D[0]`. If `CWF::TaskPath::resolve_num(deepest)` returns undef (stale/deleted reference): return `uncorrelated`.
  6. Compute `A = {deepest} ∪ { a->{num} : a ∈ CWF::TaskPath::find_ancestors(deepest) }`.
  7. If `U ⊆ A`: return `correlated`, `chosen_task = deepest`.
  8. Else: return `uncorrelated`.
- **Rationale**: With D2 in place, the reported scenario produces signals `{branch: 28, recency: 28.2, progress: 28.2}`. Step 7 collapses `{28, 28.2}` to `28.2`. Multi-level chains (`{28, 28.2, 28.2.1}` → `28.2.1`) work the same way. Truly conflicting signals across chains (`{28.2, 20}`) remain uncorrelated. The branch signal pointing at the parent is *consistent with* an active subtask, not in conflict with it (subtasks share branches — Assumption 1).
- **Edge cases (deliberately specified)**:
  - **Ties at deepest** (step 4): uncorrelated. Two depth-2 subtasks of the same parent are not on a single chain.
  - **Stale deepest** (step 5): if `resolve_num` returns undef (e.g. signal cached after directory was deleted), fall back to today's path. This is graceful degradation, not a new failure mode.
  - **Orphaned subtask** (parent directory missing): `find_ancestors` gates on `task_exists` (`TaskPath.pm:447-459`); if the parent dir is missing, `A` does not contain the parent, step 7 fails, result is uncorrelated. Acceptable — orphaned subtasks are a malformed-repo state and should surface as uncorrelated rather than be silently accepted.
- **Trade-offs**: Correlation semantics gain one extra step. The predicate is fully specified above; implementation is mechanical.

### D4. Out of scope (deliberate)
- **Worktree-signal regex extension**. Original draft included loosening `task[_-]?(\d+)` to accept decimals. Dropped: the bug report did not involve worktrees, no current worktree convention uses decimals, and widening the regex now would be an extension point without a consumer. Reconsider if/when a decimal-worktree convention emerges.
- **Branch-naming convention for subtasks**. Subtasks correctly inherit the parent's branch (Assumption 1). If we ever decide subtasks should have their own branches, that is a separate design conversation, not a bugfix. D1's `parse_branch` delegation is forward-compatible with that change.
- **`CWF::Backlog` directory-scan refactor**. The related Low-priority backlog item covers full convergence; this task partially executes it for `TaskContextInference` only.
- **State-file signal refactor**. Already decimal-aware (Assumption 4); leave for the backlog item.
- **Status signal**. Was removed in an earlier task; comment in `get_all_signals` documents why.
- **Performance optimisation of `find_descendants`** (see D2 trade-offs).

## System Design

### Component Overview
- **`CWF::TaskContextInference`** — signal aggregator + correlator. Modified: directory-scanning signals delegate to TaskPath; `correlate_signals` learns the ancestry-collapse rule.
- **`CWF::TaskPath`** — canonical task-path operations. **Unchanged** — already does what we need.
- **`task-context-inference`** (script) — thin CLI wrapper. **Unchanged** — output format and exit codes are stable.

### Data Flow
1. `task-context-inference` invokes `infer_task_context()`.
2. `get_all_signals()` collects five signals. Three of them (recency, progress, and the path-helper internals consumed by `_infer_workflow_step`) now resolve task directories via `CWF::TaskPath::resolve_num` / `find_descendants` instead of single-level scans.
3. `correlate_signals()` deduplicates top tasks, then applies the ancestry-collapse rule:
   - If `|unique| == 1`: correlated, today's path unchanged.
   - If `|unique| > 1` and `CWF::TaskPath::find_ancestors(deepest)` ∪ `{deepest}` ⊇ unique: correlated on `deepest`.
   - Otherwise: uncorrelated (today's path).
4. `format_output` emits the same simple/verbose lines — no schema change.

### Interface Design
No public-API change. `correlate_signals` keeps its signature (`\@signals → \%result`) and its return-hash keys (`confidence`, `chosen_task`, `candidates`, `signals`, `top_tasks`). Helper-fn signatures unchanged. Script exit codes unchanged. CLI output unchanged.

### Data Models
No new data structures. Signal hashrefs stay shaped as:
```
{ name, weight, candidates => [{ task, score }], top, null }
```
where `task` may now be a decimal-form string (`"28.2"`) instead of integer-only.

## Constraints
- Perl core modules only ([[feedback-perl-core-only]]).
- No CPAN deps, no shell-outs beyond existing ones.
- `cwf-manage validate` must remain clean post-change (hash refresh in this task's exec commit per [[hash-updates]]).
- Top-level inference behaviour must not regress; the conclusive resolution of task 166 from this very session is the baseline.

## Decomposition Check
- [x] **Time**: ~1 day → no.
- [x] **People**: solo → no.
- [x] **Complexity**: one module touched + small correlate-rule extension + tests → one concern → no.
- [x] **Risk**: mitigable in-task via the existing test framework → no.
- [x] **Independence**: D1+D2+D3 must land together → not independently shippable → no.
→ **No subtasks.**

## Validation
Plan-level (this phase):
- [x] Design review completed (map/reduce subagents; synthesised findings applied).
- [x] D1 reuse confirmed against `CWF::TaskPath` public exports (`parse_branch`, `parse_dirname`, `resolve_num`, `find_descendants`, `find_ancestors`, `get_depth`).
- [x] Manifest entries verified — `.pm` has no `permissions` key, script entry has `"permissions": "0500"` (Assumption 5).

Test-level (to be implemented in `g-testing-exec`; covered concretely in `e-testing-plan`):
- [ ] **Single-chain conclusive**: signals `{28, 28.2}` collapse to `28.2` (the canonical reported scenario).
- [ ] **Multi-level chain conclusive**: signals `{28, 28.2, 28.2.1}` collapse to `28.2.1`.
- [ ] **Tied deepest on disjoint branches**: `{28.2, 28.3}` remains uncorrelated.
- [ ] **Disjoint chains**: `{28.2, 20}` remains uncorrelated (the bug report's full scenario, post-D2).
- [ ] **Stale deepest**: deepest top fails `resolve_num` → uncorrelated, no exception.
- [ ] **Orphaned subtask**: subtask whose parent dir is absent → uncorrelated.
- [ ] **Top-level-only baseline**: existing top-level inference scenarios remain green (the conclusive task-166 path observed at plan time is one such scenario).
- [ ] **Descendants enumerated**: in a fixture repo with subtask `X.Y`, recency/progress include `X.Y` in their candidate sets.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 166
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
D1, D2, D3 implemented as specified. D4 honoured — no worktree regex change, no subtask-branch convention work, no `CWF::Backlog` refactor, no state-signal touch, no performance work. Correlator remained pure (no `chosen_resolved` return-key leak); `resolve_branch` replaced the inline regex in `_get_branch_signal`. The 8-step D3 predicate transliterated to Perl without surprises.

## Lessons Learned
- The map/reduce design review removed three drift items (worktree regex extension, `chosen_resolved` field, double-resolve in `_infer_workflow_step`) before exec. Each was plausible-looking gold-plating; each was correctly dropped.
- `find_ancestors` gating on `task_exists` is the right shape for the orphaned-subtask edge case — no special-casing needed in the predicate itself.
