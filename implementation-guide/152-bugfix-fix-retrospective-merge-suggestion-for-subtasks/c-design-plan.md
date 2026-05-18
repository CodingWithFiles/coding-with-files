# fix retrospective merge suggestion for subtasks - Design
**Task**: 152 (bugfix)

## Task Reference
- **Task ID**: internal-152
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/152-fix-retrospective-merge-suggestion-for-subtasks
- **Template Version**: 2.1

## Goal
Choose where to put the parent-branch derivation logic and the `sleep 1 && git` prefix so the retrospective skill emits a correct, paste-ready merge command for both top-level tasks and subtasks.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Decision 1: Skill-prose derivation, sourced from parent directory on disk (no new helper)

**Decision**: Inline derivation in the canonical wording at `.cwf/docs/skills/retrospective-extras.md`; SKILL.md keeps Step 12 as a one-line reference to that anchor (matching the existing pattern at SKILL.md Steps 6/8/10). For the parent branch lookup, resolve from the on-disk parent task directory, not from string manipulation of the current branch name.

**Rationale**:
- The retrospective skill already runs `context-manager hierarchy <task-path> --format=json` in the preamble. That single call yields the **current** task's `task_type`, `task_num`, `task_slug`, and `parent_path` (the parent task number, e.g. `"20"` for subtask `"20.2"`; empty for top-level). For top-level tasks the skill needs **zero** extra calls beyond the preamble; for subtasks it needs **one** extra call to resolve the parent's type and slug.
- The branch name on disk follows `<task_type>/<task_num>-<task_slug>` by `/cwf-new-task` and `/cwf-new-subtask` convention. Stripping the last `.N` from the current branch name is brittle: the slug after the number is the *subtask's* slug, not the parent's. Disk is the source of truth.
- A new helper would add a script, a hash, and a lockstep dependency on the branch-naming convention. Cost > benefit for a single-call site whose output the user reads, not pipes.
- Per the Progressive Disclosure Pattern (CLAUDE.md): SKILL.md stays terse; `retrospective-extras.md` carries the procedure. One source of truth, one place to update if the convention changes.

**Trade-offs**:
- LLM composes the string at retrospective time, less deterministic than helper output. Mitigated by writing the procedure as numbered steps that name the exact JSON fields.
- The retrospective skill never *executes* the merge — output is for human eyes. A wrong-looking command fails loudly on paste; there is no silent-corruption blast radius that a helper would mitigate.

### Decision 2: Trunk resolution for top-level tasks

**Decision**: Hardcode `main` in the wording for now. Do not introduce a `cwf-project.json:trunk` field as part of this task.

**Rationale**:
- The closest precedent is `.cwf/docs/skills/security-review.md:28`, which documents the planned fallback chain (`cwf-project.json:trunk` → `git symbolic-ref refs/remotes/origin/HEAD` → hardcoded `main`) for `security-review-changeset`. The chain is **documented, not yet wired**. Adopting it here would double the eventual reuse cost; better to ship it once across both call sites when a non-`main` adopter shows up.
- The reporter is on `main`; subtask-to-main is exactly the bug to fix. Top-level → `main` is correct for the reporter today.

**Loud-failure behaviour for non-`main` trunks** (today, unchanged by this task): if an adopter's trunk is e.g. `master`, the suggested `git checkout main` fails loudly with "did not match any file(s) known to git" — no destructive operation is attempted. Acceptable: surfacing, not smoothing.

### Decision 3: `sleep 1 && git` prefix scope and provenance

**Decision**: Prefix only the first git invocation in the chain. Carry the convention in the wording for now; add a BACKLOG entry to promote it to a referenced `.cwf/docs/conventions/` doc.

**Rationale**:
- Lock contention happens because Claude Code spawns a background `git` at idle that briefly holds `.git/index.lock`. The `sleep 1` at the head of the `&&` chain clears the window; the second `git merge` runs back-to-back in the same shell line. Empirically the chained second git has not been observed to hit the lock — this is an observation, not a probability claim, so per-command prefixing is unnecessary.
- The `sleep 1 && git` convention lives in MEMORY.md and global CLAUDE.md today, both maintainer-local. This task is the **first wf doc to bake the convention into installed wording other adopters will see**. The scope is narrow and explicit: the prefix applies only to (a) Bash-tool calls that invoke `git`, and (b) suggested user-facing `git ff` merge commands — both because Claude Code spawns a background `git` that briefly holds `.git/index.lock`. Promoting the convention to `.cwf/docs/conventions/` (referenced by skills) rather than copy-pasting the rule per skill is a follow-up — BACKLOG entry, not in-scope here.

**Trade-offs**:
- Adopters who do not run inside Claude Code see a benign `sleep 1` they can strip; no behavioural cost.

## System Design

### Components touched

- **`.claude/skills/cwf-retrospective/SKILL.md`**:
  - Step 12 prose: collapse to one-line reference to `retrospective-extras.md#suggest-merge-step-12` (matches the existing Steps 6/8/10 pattern).
  - Gotcha #2 (line 15): currently says *"Step 10 says 'Suggest Merge' — output the merge command…"*; the step number is stale (it's now Step 12) and "merge command" should not imply main-only. Update wording to "Step 12 suggests the merge — output the command, never execute it."
- **`.cwf/docs/skills/retrospective-extras.md`** — `## Suggest Merge (Step 12)` section: replace the hardcoded `git checkout main && git merge --ff-only {task-branch}` block with the derivation rule (below).
- **`.cwf/docs/workflow/versioning-standard.md`** — line 76: "Suggest the merge to main to the user" → "Suggest the merge to the parent (parent task branch for subtasks; trunk for top-level tasks) — human action".

**Hash-update disclosure** (per `.cwf/docs/conventions/hash-updates.md` plan-time rule): grepped `.cwf/security/script-hashes.json` — **none** of the three target files are hashed. No hash refresh required this commit.

### Derivation rule (the wording that lands in `retrospective-extras.md`)

> 1. Run `context-manager hierarchy <task-path> --format=json`. Read `parent_path` and (for the current task's branch name) `task_type`, `task_num`, `task_slug`. The current task branch is `<task_type>/<task_num>-<task_slug>`.
> 2. If `parent_path` is empty: target is `main`. Suggest:
>    `sleep 1 && git checkout main && git merge --ff-only <current-task-branch>`
> 3. If `parent_path` is non-empty: run `context-manager hierarchy <parent_path> --format=json`; read `task_type`, `task_num`, `task_slug` from the parent. Parent branch is `<task_type>/<task_num>-<task_slug>`. Suggest:
>    `sleep 1 && git checkout <parent-branch> && git merge --ff-only <current-task-branch>`
> 4. If the step-3 helper call exits non-zero: print the helper's stderr and the raw `parent_path` value; do **not** emit a `git checkout` line. The user investigates (renamed/missing parent directory) before retrying.

**Branch-existence not verified before suggestion** (accepted limitation): the parent task **directory** existing on disk does not guarantee the parent **branch** exists in git (it may have been deleted post-merge, never pushed locally, etc.). Subtask merges happen close in time to parent task work, so stale parent branches are user error caught loudly by `git checkout` failure on paste. Adding `git rev-parse --verify` would shift the failure earlier but not change the outcome. Out of scope.

**Security note for a future maintainer** (per FR4(e), to be inlined as a one-line comment in `retrospective-extras.md` near the derivation): *Output is for human paste only. If ever lifted into a helper that executes the command, switch to list-form `system()` to keep slug interpolation safe.*

### Data flow
1. Skill enters Step 12 with `<task-path>` already in context (from preamble).
2. Skill (per `retrospective-extras.md`) constructs the command string via the derivation rule.
3. Skill prints the command to the user; never executes.

## Interface Design
No new interfaces. The artefact is the wording in `retrospective-extras.md`; the user reads and pastes the command.

## Constraints
- Behavioural: skill must still only *suggest*, never execute (CLAUDE.md Critical Rules + MEMORY.md "Never execute merge to main").
- Convention: branch naming `<type>/<num>-<slug>` is set by `/cwf-new-task` and `/cwf-new-subtask`; this skill consumes that convention.
- File integrity: none of the three target files are hashed (see disclosure above) — no `.cwf/security/script-hashes.json` change required.

## Decomposition Check
- [x] **Time**: <1 day — no decomposition
- [x] **People**: Single-author edit — no decomposition
- [x] **Complexity**: Single concern — no decomposition
- [x] **Risk**: Low — no decomposition
- [x] **Independence**: Atomic — no decomposition

## Validation
- [x] Design review completed (4 parallel subagents: improvements, misalignment, robustness, security)
- [ ] Architecture approved (pending user review)
- [x] Integration points verified (no script changes; three doc files; hash file unaffected)

## Follow-ups (BACKLOG)
- Promote the `sleep 1 && git` prefix convention to a `.cwf/docs/conventions/` doc that skills can reference, rather than copying the rule into each user-facing command suggestion. Scope of the rule: Bash-tool git calls and user-facing suggested git ff merge commands only — name must always include `git`.
- When a non-`main` adopter appears (or `security-review-changeset` needs it first), wire the documented trunk-resolution fallback chain (`cwf-project.json:trunk` → `git symbolic-ref refs/remotes/origin/HEAD` → `main`) across `retrospective-extras.md` and `security-review-changeset` in one go.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 152
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
