# Eliminate path-resolution permission prompts - Requirements
**Task**: 206 (feature)

## Task Reference
- **Task ID**: internal-206
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/206-eliminate-path-resolution-permission-prompts
- **Template Version**: 2.1

## Goal
Define what a zero-prompt project-root / scratch-path resolution mechanism must do and how well, without prescribing the mechanism (that is the design phase).

## Problem Statement
Task 204 added an inline "anchor the shell" block to ~20 skills and an inline `${repo_root//\//-}` scratch-derivation snippet to `cwf-new-task`, `cwf-new-subtask`, and the `tmp-paths` convention. Each block contains nested command substitution (`$(...)`) and/or parameter expansion (`${//}`). The harness allowlists Bash commands by prefix (e.g. `Bash(.cwf/scripts/command-helpers/context-manager:*)`); a command string containing substitution/expansion cannot be statically matched, so it prompts. Observed effect (per Task 205 kickoff): a prompt on nearly every such call, destroying flow.

## Two distinct jobs (scope clarification)
The Task 204 inline blocks do **two different things**, and the mechanism must treat them separately because a child process cannot change its parent shell's working directory:
- **Job A — cwd-anchoring**: the skill "anchor the shell" block runs `cd` to the repo root so subsequent *relative* `.cwf/...` invocations resolve (needed only when cwd is not already the root, e.g. a worktree or subdirectory).
- **Job B — scratch-path derivation**: the `tmp-paths` / task-creation snippets compute and `mkdir` the per-task scratch path string.
FR1 covers both jobs but does not assume one mechanism serves both; the design phase decides whether Job A is solved (e.g. invoking helpers by absolute path, an allowlisted `cd`, or dropping the block) separately from Job B.

## Functional Requirements
### Core Features
- **FR1 (zero-prompt outcome)**: Routine project-root anchoring (Job A) and scratch-path derivation (Job B) must be achievable through invocations the harness can match with fixed-prefix allow rules, so they do **not** prompt. Acceptance: each documented invocation form is matchable by a single `Bash(...:*)` allow rule and issues no prompt in a default session. (Design constraint: the issued command string carries no command substitution `$(...)` / parameter expansion `${...}`; see Constraints.)
- **FR2 (migrate all inline blocks)**: Every site carrying a Task-204 inline anchor or `${//}` scratch-derivation block migrates to the FR1 mechanism (or drops the block where it becomes unnecessary): the ~20 skill "anchor the shell" blocks, `cwf-new-task` and `cwf-new-subtask` Step-5 scratch provisioning, and the `tmp-paths` convention's canonical snippet. Acceptance: `grep -rln 'anchor the shell\|gcd=$(git rev-parse\|repo_root//'` over `.claude/skills/` returns nothing; no consumer is told to hand-roll `${repo_root//\//-}`. (NB: grep for the bare token `git-common-dir` is **not** a valid signal — the replacement mechanism will itself call `git rev-parse --git-common-dir` internally.)
- **FR3 (single source of truth + supersede prior decision)**: The `tmp-paths` convention documents the FR1 mechanism as the single source of truth, and its "Out of scope" bullet (`tmp-paths.md:205-207`) that **deferred** a path-computing helper ("not worth the hash-tracking surface") is rewritten to record that Task 206 supersedes it — the prompt-storm is the new evidence that changes the cost/benefit. Acceptance: the deferred-helper bullet no longer reads as current policy.
- **FR4 (path conformance, worktree-stable)**: For any repo and task number, the mechanism produces a scratch path conforming to the `tmp-paths` canonical form and equal to the current snippet's output **where the current snippet is correct**, in both a plain checkout and a linked worktree. Acceptance: a golden test asserts canonical-form equality across both cases; it does not freeze any latent snippet bug (e.g. trailing-slash handling).
- **FR5 (allowlist documented + mechanism-unavailable behaviour)**: The required allowlist entries are documented for the user to opt into, and the mechanism's own failure modes (file missing, non-executable, hash-check failure) produce a clear, non-silent error rather than a wrong path. Acceptance: documented allowlist diff; an explicit test for the mechanism-unavailable path.
- **FR6 (non-repo tolerance)**: Outside a git repo the mechanism degrades exactly as the current snippet does (non-fatal; scratch deferred to first use, does not block task creation). Acceptance: invoking outside a repo exits non-fatally with the documented fallback.

### Out of scope (explicit)
- The `pretooluse-bash-tool-check` hook's own root-resolution/dashify is carved out by `tmp-paths.md:196-204` and is **not** migrated here.
- The `security-review-changeset` helper hand-rolls parent derivation + symlink-reject (`tmp-paths.md:114-126`); whether it becomes a consumer of the FR1 mechanism is **deferred to design**, not assumed.

### User Stories
- **As a** CWF user driving a skill **I want** path resolution to not prompt **so that** my flow is not interrupted on nearly every tool call.
- **As a** CWF maintainer **I want** one source of truth for root/scratch derivation **so that** I migrate snippets once, not per-skill.

## Non-Functional Requirements
### Performance (NFR1)
- Resolution adds at most one `git rev-parse` per invocation; no measurable latency regression versus the current snippet.

### Usability (NFR2)
- Net reduction in permission prompts is the headline outcome; the invocation form must be obvious and copy-pasteable in skill docs.
- Errors (not a repo, bad task number) produce a clear, actionable message.

### Maintainability (NFR3)
- Single source of truth for the derivation logic; skills reference it, never re-implement it.
- Mechanism is unit-testable in isolation from the harness.

### Security (NFR4)
- Preserve the `tmp-paths` symlink-attack defences: two-level `mkdir -m 0700` first-use guard and parent-symlink reject.
- Validate the task-number argument against the anchored pattern `^[0-9]+(\.[0-9]+)*$` before it reaches any path or shell context — this rejects `..`, empty/`.`/`..` components, and traversal vectors that bare "digits and dots only" would admit. Primary defence is **list-form invocation** (no shell interpolation of the number); the regex is defence-in-depth.
- Env-var trust: the mechanism inherits the existing single-user `$TMPDIR` trust posture documented in `tmp-paths.md:70-73` (no new trust); if a design chooses a root env var, its value must be validated, not blindly trusted.

### Reliability (NFR5)
- Worktree-safe: always resolves the MAIN repo root via `--git-common-dir`, never a per-worktree path.
- Deterministic and idempotent: repeated invocation yields the same path and safely re-creates a reaped scratch dir — but idempotent re-creation must **not** weaken fail-closed behaviour (re-invocation on a dir owned by another user still fails closed; surface, never smooth).

## Constraints
- macOS system Perl / POSIX sh; core Perl modules only (no new dependencies).
- Cannot modify the harness permission engine; must work within prefix-based allowlisting.
- Hashed-file edits refresh `script-hashes.json` in the same commit (hash-update convention).
- Must not regress Task 204's project-root-not-cwd behaviour.

## Decomposition Check
- [ ] **Time**: >1 week? No (1-2 days).
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one mechanism then a mechanical migration.
- [ ] **Risk**: High-risk components needing isolation? No — risk concentrated in the design-phase mechanism choice.
- [ ] **Independence**: Separable parts? No — migration is strictly downstream of mechanism choice.

**Verdict**: 0 signals — single task.

## Acceptance Criteria
- [ ] AC1 (FR1): Each documented invocation form (Job A and Job B) matches a single `Bash(...:*)` allow rule and issues no prompt in a default session; issued command strings contain no `$(...)`/`${...}`.
- [ ] AC2 (FR2): `grep -rln 'anchor the shell\|gcd=$(git rev-parse\|repo_root//'` over `.claude/skills/` returns nothing; the two task-creation skills carry no inline `${//}` scratch expansion.
- [ ] AC3 (FR3): The `tmp-paths.md:205-207` deferred-helper bullet is rewritten to record Task 206 supersession; the convention names the FR1 mechanism as single source of truth.
- [ ] AC4 (FR4): Golden test asserts canonical-form scratch-path equality old-vs-new in plain-checkout and worktree cases, without freezing any latent snippet bug.
- [ ] AC5 (FR1/FR5): Allowlist diff documented and an end-to-end migrated-skill run shows zero routine path-resolution prompts (recorded in g-testing-exec); a test covers the mechanism-unavailable path (missing/non-exec/hash-fail).
- [ ] AC6 (FR6/NFR4/NFR5): Non-repo fallback is non-fatal; symlink-defence (`mkdir -m 0700`, parent-symlink reject) preserved; task-number validation rejects `..`/empty components (explicit negative test); idempotent re-creation stays fail-closed.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
