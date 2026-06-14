# Nest tmp scratch dirs under per-project parent dir - Requirements
**Task**: 203 (feature)

## Task Reference
- **Task ID**: internal-203
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/203-nest-tmp-scratch-dirs-under-per-project-parent
- **Template Version**: 2.1

## Goal
Nest per-task scratch dirs under a single per-project parent dir, document the optional
allowlist rule the nesting enables, and provision + signpost the dir at task start.

## Functional Requirements
### Core Features
- **FR1 (Canonical form)**: The canonical scratch path becomes
  `${TMPDIR:-/tmp}/cwf<dashified-repo>/task-<num>/`, where `<dashified-repo>` is the
  absolute repo path with every `/`→`-` (**leading dash preserved**, as today). The `cwf`
  prefix **abuts** that leading dash — no extra separator — so the parent renders as
  `cwf-home-matt-repo-coding-with-files` (not `cwf--home-…`). Worked example (task 203):
  `${TMPDIR:-/tmp}/cwf-home-matt-repo-coding-with-files/task-203/`. *Acceptance*:
  `tmp-paths.md` states this form with the worked example; the old sibling form
  `${TMPDIR:-/tmp}/<dashified-repo>-task-<num>/` no longer appears as canonical.
- **FR2 (Two-level creation)**: First-use creates the parent (`mkdir -m 0700 -p <parent>`)
  then the task leaf (`mkdir -m 0700 <parent>/task-<num>`), 0700 on both. No sentinel file
  (the named parent is itself the marker; rationale in c-design rejected-alternatives).
  *Acceptance*: derivation snippet in `tmp-paths.md` performs the two steps; 0700 on parent
  **and** leaf.
- **FR3 (Helper conformance)**: `security-review-changeset` writes its `.out` to
  `<parent>/task-<num>/security-review-changeset-<step>.out`. *Acceptance*: the helper's
  path derivation and its 0700 mkdir use the nested form; existing `.out` contract
  (atomic write, 0600 mode) is unchanged.
- **FR4 (Documented allowlist pattern — no settings edit)**: The nested form lets a user
  collapse per-task script-execution prompts into one stable allowlist rule. CWF **does not
  modify** any `settings.json`/`settings.local.json` (machine-specific, user-owned).
  *Acceptance*: `tmp-paths.md` documents the optional rules a user MAY add, with correct
  syntax — `Write(//tmp/cwf-<repo>/**)` for the Write tool (gitignore-style: `//` absolute,
  `**` subtree) and `Bash(/tmp/cwf-<repo>/*)` for script execution (Bash rules match the
  command string; `*` spans `/`; `**` is **not** supported in `Bash()`). Syntax is confirmed
  against `code.claude.com/docs/en/permissions.md` and the existing `settings.local.json`
  (`Read(//tmp/**)`, `Bash(/tmp/…)`), not asserted. The doc must state the granularity
  trade-off: one subtree rule allowlists execution of scripts written into **any** task leaf
  by **any** session — a deliberate, user-owned widening bounded to this project's parent
  under the single-user model. No settings file is touched by this task.
- **FR5 (Provision + active-use guidance)**: At task start `/cwf-new-task` creates the parent
  **and** the task leaf (`mkdir -m 0700 -p "${TMPDIR:-/tmp}/cwf<dash>/task-<num>"`) and
  surfaces the path; `tmp-paths.md` tells the agent to use `…/cwf<dash>/task-<num>/` for all
  scratch. Provisioning failure is **non-fatal** to task creation (clear warning; never
  blocks directory/branch creation — task creation does not need scratch). `/cwf-new-subtask`
  reuses the same project parent with its own `task-<subnum>/` leaf. Consumers still
  create-on-demand (FR2) as a safety net against a `/tmp` reaper. *Acceptance*: `/cwf-new-task`
  provisions parent+leaf (non-fatal on failure) and surfaces the path; `tmp-paths.md`
  instructs the agent to use the leaf.
- **FR6 (Reference sweep)**: All in-repo references to the old sibling form are updated to
  the nested form, except documented carve-outs (history files; the `-tool-check` state
  dir, D5). Known surface: `tmp-paths.md`, `CLAUDE.md` (Tmp Paths bullet, ~line 89),
  `security-review-changeset` (comments + derivation), `.cwf/docs/skills/` mentions.
  *Acceptance*: a grep distinguishing old (`<repo>-task-<num>`, dash) from new
  (`cwf-<repo>/task-<num>`, slash) returns only carved-out occurrences of the old form.

### User Stories
- **As a** devops operator **I want** all CWF scratch grouped under one clearly-named
  `cwf-<repo>/` parent **so that** I can see at a glance what in `/tmp` is CWF-owned and
  which `task-<num>/` leaves are live vs. deletable.
- **As an** agent running a task **I want** a stable, pre-created per-task scratch dir
  **so that** one-off scripts and captured output have an obvious home; and **as a** user
  **I want** to optionally add one allowlist rule **so that** those runs stop prompting.

## Non-Functional Requirements
### Performance (NFR1)
- No measurable change; one extra `mkdir` at first use per task. Negligible.

### Usability (NFR2)
- Derivation snippet stays copy-pastable and ≤ a handful of shell lines.
  (One-canonical-form anti-drift is already pinned by FR1's acceptance; not restated here.)

### Maintainability (NFR3)
- Single source of truth for the convention remains `tmp-paths.md`; the helper mirrors it.
- Helper path derivation kept self-documenting; behaviour covered by a `t/` test.

### Security (NFR4)
- **NFR4a (parent guard)**: The atomic `mkdir 0700` on the parent plus the fail-closed
  `0600` `.out` write remain the containment boundary (unchanged from today; `.out` keeps
  atomic same-dir temp+rename). As defence-in-depth for the now-shared, longer-lived parent,
  the helper additionally rejects a parent that is a **symlink** — the check is `-d && !-l`
  so it catches a symlink *to a directory* (which a bare `-d` would silently accept, the
  dangerous case) — with warn + exit 1. It does **not** re-assert ownership/mode (that stays
  enforced by the fail-closed write — avoids a TOCTOU stat masquerading as the boundary) and
  **never auto-chmods** a wrong-mode parent (surface, never smooth). Leaf keeps explicit
  `0700`; a pre-planted **leaf** symlink is **intentionally** left to the fail-closed `0600`
  write (no redundant leaf check that would masquerade as the boundary). An existing
  non-owned parent is tolerated only because leaf creation / the `.out` write then fails closed.
- **NFR4b**: `$TMPDIR` continues to be honoured verbatim under the single-user threat
  model; no new untrusted-input surface introduced.

### Reliability (NFR5)
- Idempotent first-use: re-running on an existing owned parent/leaf is a no-op.
- Helper fails closed (warn + exit 1) if it cannot create or write the scratch path (unchanged).

## Constraints
- POSIX-only; Perl core modules only; `use utf8;` in any Perl touched.
- Single-user host threat model unchanged.
- Hash refresh for any edited hashed script lands in the same commit as its edit.
- No `settings.json`/`settings.local.json` edits (user-owned; documented pattern only).
- Carve-outs preserved: `INSTALL.md` one-shot paths, `BACKLOG.md`/`CHANGELOG.md`/older
  `implementation-guide/` history, and the `-tool-check` state dir (D5).
- **Out of scope**: shared-parent lifecycle/cleanup — `task-<num>/` leaves accumulate under
  the parent; pruning is the devops operator's call (the stated user story), not automated here.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: >1 week? No
- [x] **People**: >2 people? No
- [x] **Complexity**: 3+ distinct concerns? No
- [x] **Risk**: High-risk components needing isolation? No
- [x] **Independence**: Parts separable? No — convention + sole consumer move together

**Conclusion**: No decomposition (0 signals).

## Acceptance Criteria
- [ ] AC1 (FR1/FR2): `tmp-paths.md` canonical form is nested; derivation snippet creates
      parent (`mkdir -m 0700 -p`) then leaf (`mkdir -m 0700`); 0700 on both; no sentinel
- [ ] AC2 (FR3): `security-review-changeset` writes `.out` under nested path; `t/` test
      asserts derived path shape and parent+leaf 0700 mode
- [ ] AC3 (FR4): `tmp-paths.md` documents the optional `Write(//tmp/cwf-<repo>/**)` and
      `Bash(/tmp/cwf-<repo>/*)` rules (correct syntax) and the per-project granularity
      trade-off; **no** settings file is modified
- [ ] AC4 (FR5): `/cwf-new-task` provisions parent+leaf at creation (non-fatal on failure,
      never blocks branch creation) and surfaces the path; `tmp-paths.md` tells the agent to
      use the leaf
- [ ] AC5 (FR6): grep anchored on `-task-` (so it does not flag `-tool-check`) distinguishing
      old (`<repo>-task-N`, dash) from new (`cwf-<repo>/task-N`, slash) finds only carved-out
      occurrences; `CLAUDE.md` updated; `-tool-check` form intact
- [ ] AC6 (NFR4a): parent that is a symlink (incl. symlink-to-dir, via `-d && !-l`) → warn +
      exit 1; no auto-chmod; leaf-symlink case left to the fail-closed write (no redundant check)
- [ ] AC7: full `t/` suite passes; any edited hashed script's hash refreshed in same commit

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
AC1–AC7 all satisfied (see g-testing-exec.md for the evidence). AC3 was met by
documentation only — no settings file modified (D4). NFR4a's owner/mode stat (AC6) was
refined in design to "symlink-reject (`-d && !-l`) + fail-closed write", which is what
shipped and is covered by TC-PARENT-SYMLINK / TC-PARENT-REUSE.

## Lessons Learned
*Consolidated in j-retrospective.md.*
