# Delete most-recent task only - Requirements
**Task**: 136 (feature)

## Task Reference
- **Task ID**: internal-136
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/136-delete-most-recent-task-only
- **Template Version**: 2.1

## Goal
Define the functional and non-functional behaviour of a "delete most-recent task" command — the inverse of `/cwf-new-task` — and enumerate the refusal cases that protect the project from renumbering, lost work, and history rewrites.

## Functional Requirements

### Core Features

- **FR1 — Command surface**: A user-invocable command exists that takes a task path (e.g. `136`, `48.1`) and deletes that task if (and only if) every refusal check passes.
  - **Acceptance**: Running the command on a valid most-recent task removes the task directory, task branch, checkpoints branch (if it exists), and task-stack entry (if topmost) in a single invocation.

- **FR2 — Reverse-of-create semantics**: Deletion removes exactly what `/cwf-new-task` (and any subsequent checkpoint commits) created on the task branch — nothing more.
  - **Acceptance**: After deletion of a freshly-created task with no work beyond the create step: (a) `git status` is clean on the original branch; (b) `git ls-tree -r HEAD` matches the pre-create baseline; (c) `.cwf/task-stack` matches the pre-create baseline; (d) the `implementation-guide/` tree matches the pre-create baseline; (e) the task branch and any checkpoints branch are gone. Reflog and loose objects are not compared.

- **FR3 — "Most-recent" check**: The command refuses if the target task is not the most-recent task at its level of the hierarchy.
  - **"Most-recent" definition**: The task with the highest decimal-suffix sibling number under its parent directory. For top-level tasks, siblings live directly under `implementation-guide/` (the highest top-level number). For nested tasks, siblings live under the immediate parent (e.g. for `3.2.4`, siblings are the `3.2.N` directories under `…/3-…/3.2-…/`; `3.2.5` existing blocks deletion of `3.2.4`). Sibling enumeration must use `find_siblings()` from `CWF::TaskPath` — no hand-rolled traversal.
  - **Acceptance**: Attempting to delete task `135` when `136` exists fails with a specific error naming `136` as the blocker. Same for nested siblings.

- **FR4 — Leaf check**: The command refuses if the target task has surviving subtasks.
  - **Acceptance**: Attempting to delete task `100` while `100.1` exists fails with a specific error naming the surviving subtask(s).

- **FR5 — Already-merged check**: The command refuses if the tip of the task branch is reachable from `main` (i.e. the task's squash commit is part of [archaeological main](`.cwf/docs/glossary.md#archaeological-main`) and is therefore immutable history).
  - **Acceptance**: When `git merge-base --is-ancestor <task-branch-tip> main` succeeds, deletion is refused with a message naming the merge commit on main and pointing the user at the archaeological-main glossary entry. `--force` does not override this check.

- **FR6 — Unmerged work check**: The command refuses if the task branch contains commits beyond the workflow-phase checkpoint commits the script recognises, unless `--force` is given. The exact detection mechanism is a design-phase decision; from the requirements side, what matters is that ordinary "I made a `/cwf-new-task` typo" cases succeed without `--force`, and that any commit a user added by hand requires `--force`.
  - **Acceptance**: Freshly-created tasks (only create + checkpoint commits on the branch) delete without `--force`. Adding any commit the script does not recognise as a wf-phase checkpoint blocks deletion by default; `--force` overrides with an explicit warning that lists the commit subjects that will be lost. `--force` applies *only* to FR6 — it never overrides FR3, FR4, FR5, FR7, or FR8.

- **FR7 — Atomic refusal**: If any refusal check fails, the command makes no changes to the filesystem, git refs, or task-stack.
  - **Acceptance**: After a failed run, `git status`, `git branch`, the implementation-guide tree, and `.cwf/task-stack` are byte-identical to their pre-run state.

- **FR8 — Task-stack handling**: If the target task is the topmost (last) entry on `.cwf/task-stack`, it is popped using the existing `flock`-protected task-stack helper. If it appears on the stack but is not the topmost entry, deletion is refused.
  - **Acceptance**: Stack manipulation routes exclusively through the existing task-stack helper; no hand-rolled file ops. Refusal message names the topmost task that is blocking.

### User Stories

- **As a** CWF maintainer **I want** to undo a freshly-created task **so that** a typo in description, wrong type, or accidental creation doesn't pollute the implementation-guide tree.
- **As a** CWF maintainer **I want** the command to refuse non-most-recent deletions **so that** I never have to renumber sibling tasks, edit BACKLOG references, or reason about gaps.
- **As a** CWF maintainer **I want** clear refusal messages **so that** I know exactly which check failed and what to do (delete the blocking subtask, recreate from a parent, etc.).

## Non-Functional Requirements

### Performance (NFR1)
- Response time: < 1 s for the typical case (one task directory, two branches, optional stack pop).
- Resource usage: negligible — operates on a handful of files and refs.
- No new long-running processes or background work.

### Usability (NFR2)
- Error messages name the specific failing check and the specific blocker (task number, branch name, or commit subject).
- Successful deletion prints a short summary of what was removed (directory, task branch, checkpoints branch, stack entry).
- Follows the same `<num> [<type>] "description"`-style argument convention as `/cwf-new-task` (path-only here — type and description are not needed).

### Maintainability (NFR3)
- Implemented as a helper script + thin skill, mirroring the create direction (`task-workflow create` → `task-workflow delete`).
- All refusal checks live in one ordered list inside the helper so they can be re-read or extended without hunting through layers.
- Sibling resolution, branch-name formatting, and path resolution use existing helpers (`CWF::TaskPath::find_siblings`, `format_branch`, `resolve_num`) — no reimplementation.

### Security (NFR4)
- **Path validation**: the resolved task directory must live under `implementation-guide/` and match the canonical `<num>-<type>-<slug>` (or nested) pattern. After resolution, `realpath()` of the target must be a string-prefix of `realpath(implementation-guide/)` — guards against a task directory that is itself a symlink pointing outside the tree. Pattern adopted from `CWF::Validate::Templates`'s `lstat`/link-target checks.
- **Ref scoping**: only branches matching `<type>/<num>-<slug>` and `<type>/<num>-<slug>-checkpoints` may be deleted; the main branch and any unrelated branches are never touched, even with `--force`. Both branch names must be validated with `git check-ref-format --branch <name>` before any `git branch -D` call (same pattern used by `security-review-changeset`).
- **No env-var or external-input branching**: behaviour is determined solely by repo state and the task-path argument; no env-var gates that could be set in CI to escalate behaviour.
- **No prompt-injection surface**: the script is plain Perl/shell — no LLM in the loop, no eval of repo content.
- **Script-hash integrity is out of scope**: the delete command does not re-verify its own SHA. Hash drift is `cwf-manage validate`'s job; this command relies on that being run separately, same as every other helper in `.cwf/scripts/command-helpers/`.

### Reliability (NFR5)
- Atomic semantics: refusal checks complete before any destructive action; first error aborts with no side-effects.
- Idempotent on partial state: if a previous run was interrupted leaving (say) the task-stack entry but not the directory, the next run completes the cleanup rather than aborting on "directory missing".
- Never touches main, BACKLOG.md, CHANGELOG.md, or task directories that aren't the target.

## Constraints
- POSIX-only project; no GNU-isms or Linux-only flags.
- Perl core modules only (macOS system-Perl portability).
- Must use existing `flock`-based task-stack locking — no hand-rolled file ops.
- Must not modify BACKLOG.md or CHANGELOG.md — finished-task history is immutable; deletion only applies to tasks that were never finished.
- Must not rely on `find` or `sed` in the Bash tool (per project conventions); helpers use Perl + `git ls-files -z`.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — 1-2 days.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — single concern: refuse-or-delete.
- [ ] **Risk**: Are there high-risk components that need isolation? No — risk is mitigated by refusal checks, which are intrinsic to the feature.
- [ ] **Independence**: Can parts be worked on separately? No — script and skill are tightly coupled.

No decomposition warranted.

## Acceptance Criteria
- [ ] AC1: A user-invocable command exists that performs reverse-of-create deletion on a valid most-recent task.
- [ ] AC2: Each refusal case (FR3-FR8) is verified end-to-end with a test case and a recognisable error message. Successful deletion leaves repo state matching the pre-create baseline (per FR2 acceptance criteria); refused deletion leaves repo state byte-identical to pre-run.
- [ ] AC3: Stack interactions go exclusively through the existing `flock`-protected helper.
- [ ] AC4: No code path touches main, BACKLOG.md, CHANGELOG.md, or any task outside the target.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All functional requirements (FR1–FR8) and non-functional requirements implemented as written. No FR was added, removed, or relaxed during implementation. Test matrix in g-testing-exec.md covers each FR explicitly.

## Lessons Learned
Writing FRs as numbered refusal-or-allow predicates (e.g., FR3 = "refuse if not most-recent", FR6 = "refuse if non-checkpoint commits since baseline") made the design phase's 10-check enumeration almost mechanical. For refusal-heavy features, "predicate per FR" is a useful requirements shape.
