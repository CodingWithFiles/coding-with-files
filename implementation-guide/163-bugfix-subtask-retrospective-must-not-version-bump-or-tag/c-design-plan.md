# subtask retrospective must not version-bump or tag - Design
**Task**: 163 (bugfix)

## Task Reference
- **Task ID**: internal-163
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/163-subtask-retrospective-must-not-version-bump-or-tag
- **Template Version**: 2.1

## Goal
Make a subtask's retrospective skip version-bump and version-tag deterministically, with a clean no-op rather than the current misleading "unknown argument" error.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Root Cause
The `cwf-retrospective` skill invokes the version helpers unconditionally with the resolved task number:
- Step 9 → `cwf-version-bump --task-num={current_task_num}` (`.claude/skills/cwf-retrospective/SKILL.md:50`)
- Step 11 → `cwf-version-tag --task-num={current_task_num} ...` (`SKILL.md:54`)

All three sibling helpers parse the argument with the identical `^--task-num=(\d+)$` (`cwf-version-bump:19`, `cwf-version-tag:21`, `cwf-version-next:19`). A subtask number is decimal (e.g. `3.2`), so it fails the integer match and the scripts emit `unknown argument: --task-num=3.2` and exit 1.

Conceptually this is correct to reject but wrong in shape: version actions are release events keyed to an **integer** top-level task number (`v{major}.{minor}.{patch}`, patch = task number; `last_released` must match `^v\d+\.\d+\.\d+$`). A subtask merges to its **parent task branch**, not trunk (`retrospective-extras.md:127`), so nothing is released when a subtask completes. A subtask must therefore *skip* these steps cleanly, not error.

## Key Decisions

### Decision 1 — Guard in the scripts, not in skill prose
- **Decision**: Add a deterministic subtask guard so a `--task-num` denoting a subtask (decimal) becomes a clean no-op: print `skipped: version actions apply to top-level tasks only (subtask {N})` and `exit 0`. Bare-integer values follow the existing path unchanged.
- **Rationale**: Project convention (`feedback_bake_in_good_work`) — agents skip optional work, so correctness guarantees belong in scripts, not in instructions the retrospective agent may not follow. The **sole runtime consumer** is the retrospective skill, which already handles the `skipped:` output contract ("On `skipped` ... nothing further to stage", `SKILL.md:50`), so behaviour composes with no skill logic change.
- **Trade-offs**: Widens each script's *recognised* input set (to also match decimal numbers, which it then skips) but not the *mutating* set. The module backstop (`next_version` still enforces `^\d+$`, `Versioning.pm:81`) is retained, so a bare integer remains the only value that can reach a mutation or a `git tag`.

### Decision 2 — Shared predicate in `CWF::Versioning` (resolved: shared, not inline)
- **Decision**: Add an exported predicate `is_subtask_num($n)` to `CWF::Versioning` (returns true iff `$n =~ /^\d+(?:\.\d+)+$/`) and call it from all **three** triplet helpers (`cwf-version-bump`, `cwf-version-tag`, `cwf-version-next`).
- **Rationale**: Plan review corrected the call-site count from two to **three** identical parsers — Rule of Three is met, and `feedback_design_tradeoff_priority` (reuse over duplication, always) applies. `CWF::Versioning` already owns task-number shape policy (`next_version`'s `^\d+$`), so the predicate lives naturally beside it. Centralising means one place to change if the version scheme ever admits a sub-patch, and the predicate is directly unit-testable in `versioning.t`.
- **Trade-offs**: One extra exported symbol and a `use` import in each helper, versus three near-identical inline checks. Chosen per the project's standing reuse convention.

### Decision 3 — Cover all three triplet helpers
- **Decision**: Apply the guard to `cwf-version-bump`, `cwf-version-tag`, **and** `cwf-version-next`. `cwf-version-next` is read-only and not in the retrospective auto-flow, but `versioning-standard.md:6,59` advertises the three as a "triplet" with a uniform `--task-num=N` contract; fixing two and leaving the third emitting the misleading error would create intra-triplet inconsistency.
- **Rationale**: Consistency across the documented set; near-zero marginal cost once the shared predicate exists.

### Decision 4 — Docs clarify the policy; skill commands unchanged
- **Decision**: Document "version actions run only at the top-level task retrospective; subtask numbers are a clean no-op" in `versioning-standard.md`, and add a one-line clarifier to retrospective Steps 9 & 11. No change to the skill's commands (the `skipped:` handling already exists).
- **Rationale**: Deterministic behaviour lives in the scripts; the doc explains *why* a subtask retrospective reports "skipped". The SKILL.md clarifier is explanatory-only and kept minimal (plan-review improvements Finding 5).

## System Design
### Components touched
- **`CWF::Versioning`** (`.cwf/lib/CWF/`): add + export `is_subtask_num`.
- **`cwf-version-bump`**, **`cwf-version-tag`**, **`cwf-version-next`** (`.cwf/scripts/command-helpers/`): relax arg capture to accept a hierarchical number, route subtasks to the clean-skip via `is_subtask_num`.
- **`versioning-standard.md`** (`.cwf/docs/workflow/`): document top-level-only policy.
- **`cwf-retrospective/SKILL.md`**: one-line clarifier on Steps 9/11.
- **`t/cwf-version-bump.t`, `t/cwf-version-tag.t`, `t/cwf-version-next.t`, `t/versioning.t`**: new assertions (see e-testing-plan).

### Control flow (per helper, after change)
The skip branch lives **inside the `@ARGV` parse loop**, before `read_config()`/the `eval` block — so a subtask short-circuits with no config read, no mutation, no git call (satisfies the "no side effects" guarantee even when `cwf-project.json` would otherwise `die`):
1. Capture `--task-num=V` with the relaxed anchored pattern `^--task-num=(\d+(?:\.\d+)*)$` (integer **or** dotted).
2. If `is_subtask_num(V)` → print skip line, `exit 0`.
3. Else (`V` is a bare integer) → existing path: `$task_num = V + 0`, then `next_version` → `bump_to`/`tag_at`/print, honouring config flags and idempotency.
4. Any value **not** matching step 1 (e.g. `3.`, `.2`, `3..2`, non-numeric) → existing `unknown argument` error, exit 1, unchanged.

## Interface Design
Output contract additions (all three helpers, subtask input):
- stdout: `skipped: version actions apply to top-level tasks only (subtask {N})` — the `skipped:` prefix is **load-bearing** (the skill keys on it, `SKILL.md:50`).
- exit code: `0`
- side effects: none (no `cwf-project.json` write; no git tag; no config read).

`--help`/usage text gains a one-line note that subtask numbers are skipped.

## Constraints
- The semver scheme (integer patch = task number) is fixed; the fix excludes subtasks rather than reshaping the version format.
- `.cwf` script/lib edits require a hash refresh to `.cwf/security/script-hashes.json` in the same commit as the edit (`docs/conventions/hash-updates.md`); the implementation plan must disclose this. Working perms restored to 0700 after edit (`feedback_hashed_script_working_perms`).
- `CWF::Versioning` must remain core-Perl only (`feedback_perl_core_only`); the predicate is a bare regex, no new deps.

## Plan Review Outcomes (Step 8)
Four parallel reviewers (improvements, misalignment, robustness, security). Applied:
- **Third consumer `cwf-version-next`** (misalignment/robustness/improvements): corrected the "sole consumers" error; added it to scope (Decision 3).
- **Decision 2 resolved to shared predicate** (misalignment/robustness): three sites + reuse-over-duplication memory.
- **Anchored regex + edge cases** (security/robustness): `3.` / `.2` / `3..2` must hit the error path, not skip; pinned as test cases.
- **Skip occurs in parse loop before config read** (robustness): made explicit in control flow.
- **`skipped:` prefix is the integration contract** (improvements/misalignment): pinned in Interface Design.
- **Minimal SKILL.md edits** (improvements Finding 5): reduced to a single clarifier line; behaviour stays in scripts.
Security review: no FR4 findings — the change narrows (not widens) the input that reaches `git tag`; `next_version`'s `^\d+$` backstop preserved.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one concern across two parallel scripts.
- [ ] **Risk**: high-risk components needing isolation? No.
- [ ] **Independence**: separable parts? No.

No decomposition signals; single bugfix task.

## Validation
- [x] Design review completed (plan-review subagents, Step 8) — findings applied above
- [x] Decision 2 resolved (shared predicate in `CWF::Versioning`)
- [ ] Integration points verified (skill "skipped" handling already present)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four design decisions implemented as specified: shared `is_subtask_num` in `CWF::Versioning`, the in-loop skip before `read_config()` across all three helpers, docs clarifying the policy, no skill command change. The control-flow contract (skip before any side effect) was verified by test TC-2.

## Lessons Learned
The single most valuable design correction — the third consumer (`cwf-version-next`) — came from plan review, not initial analysis. The lesson (grep the helper family for the shared parser before stating a consumer count) is carried into `j-retrospective.md` §Recommendations.
