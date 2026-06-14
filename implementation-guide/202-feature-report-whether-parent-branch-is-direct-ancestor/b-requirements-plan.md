# report whether parent branch is direct ancestor - Requirements
**Task**: 202 (feature)

## Task Reference
- **Task ID**: internal-202
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/202-report-whether-parent-branch-is-direct-ancestor
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for extending
`context-manager hierarchy` to report whether a task's parent branch is an
ancestor of the current branch (a strict-linear-history signal).

## Terminology
- **Parent branch**: the git branch of the queried task's *parent task*,
  derived as `<type>/<num>-<slug>` from the parent's resolved metadata
  (`TaskPath::format_branch`). A top-level task has no parent task and therefore
  no parent branch.
- **Current branch**: the checked-out branch (`git rev-parse --abbrev-ref HEAD`).
  Normally the queried task's own branch.
- **Ancestor**: the parent branch tip is reachable from the current branch tip,
  i.e. `git merge-base --is-ancestor <parent-branch> HEAD` exits 0. This is the
  condition under which the current branch can ff-only merge back to its parent —
  the archaeological-main linearity invariant.

## Functional Requirements
### Core Features
- **FR1**: `context-manager hierarchy <task> --format=json` MUST emit a new field
  reporting the parent-branch ancestry result. Values: `true` (parent branch is
  an ancestor of current branch), `false` (parent branch exists but is not an
  ancestor — history has diverged), or `null` (undecidable — see FR4). The field
  MUST be a JSON literal (unquoted `true`/`false`/`null`), not a string.
- **FR2**: The parent branch MUST be derived from the queried task's parent task.
  Because `resolve()` returns `parent_path` as a *path string* (e.g. `"28"`), the
  parent path MUST be **re-resolved** to obtain its `(num, type, slug)`, which are
  then passed to `format_branch`. If the task has no parent task, the result is
  `null` (FR4).
- **FR3**: The ancestry test MUST be `git merge-base --is-ancestor <parent-branch>
  HEAD` (exit 0 ⇒ `true`, exit 1 ⇒ `false`). The current branch MUST be obtained
  via `git rev-parse --abbrev-ref HEAD`. No other git semantics. An existing
  precedent for this exact two-step shape (existence guard + list-form
  `--is-ancestor`) lives at `task-workflow.d/delete` (around lines 178–179) and
  SHOULD be the model.
- **FR4**: The result MUST be `null` (never a hard error, never a false
  true/false) in every undecidable case:
  - the queried task has no parent task;
  - the parent task path cannot be resolved, or its directory name does not parse
    into `(num, type, slug)` branch components;
  - the derived parent branch does not exist (existence check false — e.g.
    renamed, merged-and-deleted);
  - the git ancestry command fails for any reason other than the clean
    ancestor/not-ancestor exit (0/1) — e.g. an unborn/empty HEAD.

  Note on detached HEAD: a detached-but-valid HEAD is NOT undecidable.
  `merge-base --is-ancestor <parent> HEAD` resolves `HEAD` to the current commit
  and returns a correct `true`/`false` against it, which is more informative than
  `null`; this is the design-settled behaviour (see c-design-plan). Only an
  unborn/empty HEAD (no commit) falls into the `null` case above.
- **FR5**: The markdown format MUST report the same fact human-readably, as an
  additive line, printed only when a parent branch was resolvable (consistent
  with the existing `Parent:` line being conditional).
- **FR6**: The ancestry-determination logic MUST live in a single testable
  library function (e.g. in `CWF::TaskPath`), not inline shell in the hierarchy
  command, so it can be unit-tested independently of output formatting. This
  function is the single enforcement point for the list-form git invocation
  required by NFR4.

### User Stories
- **As a** CWF maintainer driving the archaeological-main flow **I want**
  `hierarchy` to tell me whether the parent branch is an ancestor of where I am
  **so that** I can confirm strict linear history before deriving an ff-only
  merge target.
- **As a** tool/script consuming `hierarchy --format=json` **I want** a stable
  tri-state field **so that** I can branch on linear / diverged / undecidable
  without parsing prose.

## Non-Functional Requirements
### Performance (NFR1)
- Adds at most two git invocations (a branch-existence check + one
  `merge-base --is-ancestor`); the verifiable bound is the invocation count, no
  measurable change to a typical `hierarchy` call.

### Maintainability (NFR2)
- Perl core modules only; follow `docs/conventions/perl.md` (shebang,
  `PERL5OPT`, `use utf8;`) and the git-path-output convention.

### Security (NFR3)
- All git calls in the new code path — both the branch-existence check **and**
  the `merge-base --is-ancestor` call — MUST be invoked in list form (no shell
  interpolation of the derived branch name), so a crafted task dirname cannot
  inject shell. Branch names originate from on-disk dir names — treat as data,
  never pass through a shell string. **Note:** the existing `TaskPath::branch_exists`
  (`TaskPath.pm:510`) uses backtick/shell-interpolated form (`git branch --list
  '$branch'`); the design MUST NOT route the existence check through that pattern
  — use a list-form check (e.g. `git rev-parse --verify --quiet
  refs/heads/<branch>`) instead.

### Reliability (NFR4)
- Existing `hierarchy` output fields, ordering, and exit codes MUST be unchanged
  (additive only). Undecidable inputs yield `null`, never a non-zero exit or
  stack trace.

## Constraints
- Additive change to `context-manager.d/hierarchy` plus a library function and
  its test; no change to the `hierarchy` CLI surface beyond the new field/line.
- The existing `hierarchy` JSON is hand-rolled string interpolation (no JSON
  encoder in the code path); the new field MUST be emitted as a bare
  `true`/`false`/`null` token, not routed through any quoting helper.
- No new non-core dependencies.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No.
- [ ] **Risk**: high-risk components needing isolation? No.
- [ ] **Independence**: separable parts? No.

No signals triggered — single task.

## Acceptance Criteria
- [ ] AC1: For a subtask whose parent branch is an ancestor of HEAD, JSON field
      is `true` and markdown reports linear/ancestor. The same-tip case
      (HEAD == parent branch tip) also yields `true` (a branch is its own
      ancestor).
- [ ] AC2: For a subtask whose parent branch has diverged from HEAD, the field is
      `false`.
- [ ] AC3: For a top-level task (no parent), and for a subtask whose parent
      branch is absent, the field is `null` — distinct from `false`.
- [ ] AC4: JSON output remains valid and all pre-existing fields/exit codes are
      unchanged; the new field is additive.
- [ ] AC5: The library ancestry function is unit-tested for ancestor, diverged,
      no-parent, and missing-branch cases. The diverged (`false`) case requires a
      synthetic throwaway git repo — the live CWF repo is strictly linear and
      cannot exercise that path.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
FR1–FR6 and NFR1–NFR4 all satisfied; AC1–AC5 all verified (TC-1…TC-9). The
tri-state field is emitted as a bare JSON literal as required (TC-8 confirms via a
real parser). The NFR3 list-form mandate — and the explicit instruction *not* to
route the existence guard through the backtick `branch_exists` — was honoured at
both new git callsites and endorsed by both exec-phase security reviews. FR4's
detached-HEAD wording was refined at design time (detached-but-valid HEAD answers
against the commit; only unborn HEAD is `null`).

## Lessons Learned
*Consolidated in j-retrospective.md.*
