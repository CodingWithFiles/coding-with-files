# Adopt guarded worktree enter/exit process - Requirements
**Task**: 181 (feature)

## Task Reference
- **Task ID**: internal-181
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/181-adopt-guarded-worktree-process
- **Template Version**: 2.1

## Goal
Specify what a defined, guarded CWF worktree process must do and must forbid, so that
all worktree use with CWF flows through the harness `EnterWorktree`/`ExitWorktree` guard
instead of the unguarded raw-`git worktree` data-loss chain. Task 177 facts C1–C4 are
fixed inputs, not re-litigated here.

## Functional Requirements
### Core Features
- **FR1 — Defined process document.** A single canonical convention doc must define the
  guarded CWF worktree process. It is a runtime/installed convention (it governs agents
  executing CWF tasks), so it lives under `.cwf/docs/conventions/`, peer to
  `tmp-paths.md` and `session-hygiene.md`; the exact filename is a design choice.
  - AC: A doc exists under `.cwf/docs/conventions/`; it covers create-via-
    `EnterWorktree`, `worktree.baseRef: head`, the deferred-tool `ToolSearch` load, the
    no-unprompted-`discard_changes` rule, operator-surfaced teardown, and the
    `cd`/absolute-path discipline. It is the single source of truth (no duplication of
    the C-facts across files — cite, don't copy).
- **FR2 — Create only via `EnterWorktree`.** The process must mandate that CWF scratch
  worktrees are created through `EnterWorktree`, because the uncommitted-changes guard is
  `EnterWorktree`-scoped (C1); raw `git worktree add` and `git worktree remove --force`
  are disallowed for CWF worktrees. The hybrid path — `EnterWorktree(path:)` *entering* a
  worktree that was created with raw `git worktree add` — is also disallowed for CWF
  worktrees, because `ExitWorktree` will not remove such a tree (it falls back to
  `action: keep`), leaving teardown unguarded; CWF worktrees must be both created and
  removed through the guarded tools.
  - AC: The doc states the prohibition (including the `path:`-into-raw-add hybrid) and
    gives the `EnterWorktree` path that replaces each ad-hoc use (model-initiated, manual
    wf-file procedure, operator).
- **FR3 — `worktree.baseRef: head`.** The process must require, and the repo must set,
  `worktree.baseRef: head` so new worktrees branch from current HEAD, not
  `origin/<default>` (C3/C4; aligns with `feedback_branch_from_current_commit`). The
  setting goes in the committed `.claude/settings.json` (so all clones inherit it), not
  the gitignored `.claude/settings.local.json`; design confirms the harness honours
  `worktree.baseRef` from project settings.
  - AC: The key is present in committed `.claude/settings.json` and the doc records it
    plus rationale; **and** the FR8 probe observes that the worktree it creates is based
    on current HEAD, not `origin/<default>` (behavioural confirmation, not key-presence
    alone).
- **FR4 — Deferred-tool load discipline.** The process must specify that the worktree
  tools are deferred and must be loaded via `ToolSearch` (`select:EnterWorktree,ExitWorktree`)
  at point of use, and that the schema gate is satisfied by "project instructions
  (CLAUDE.md/memory)" — i.e. the documented process authorises **loading the tools and
  creating** a worktree. It explicitly does **not** authorise destructive teardown:
  removal still requires the operator-surfaced decision of FR5, and the documented
  process is never standing permission to pass `discard_changes`.
  - AC: The doc names the `ToolSearch` load step, cites the gate clause, and scopes the
    "process-is-authorisation" statement to load/create only with an explicit
    cross-reference to FR5/NFR4 that it does not authorise removal. Whether this is
    embodied as a new skill or convention-doc guidance is deferred to design.
- **FR5 — Teardown is operator-surfaced, never auto-discard.** The process must forbid
  passing `discard_changes: true` unprompted and must require surfacing the teardown
  decision to the operator; the `ExitWorktree` refusal-on-uncommitted-changes gate must
  remain intact.
  - AC: The doc states the prohibition in imperative terms; no process/skill text grants
    standing permission to remove a worktree (verified by the FR-side of NFR4).
- **FR6 — Friction handled by discipline, not allowlist broadening.** The process must
  capture the no-needless-`cd`/absolute-path discipline (subsumes R6) and explicitly
  reject permission-allowlist broadening as the fix. A `Bash(git worktree *)` allowlist
  entry that previously sat in `.claude/settings.local.json` (a per-machine, user-owned
  file) auto-approved `git worktree remove --force` — the exact unguarded teardown FR2
  prohibits. **That specific entry has been removed by the operator this session** (the
  one-time cleanup — done). The *recurring, generalised* detector for this class of entry
  is FR9; FR6 no longer asserts a present hole. `tmp-paths.md` is updated where worktree
  scratch paths intersect it.
  - AC: The doc contains the discipline and the explicit rejection; the existing
    `Bash(git worktree *)` entry is removed or narrowed to read-only; `tmp-paths.md`
    references the worktree process where relevant; no new broad allowlist entry is added.
- **FR7 — Discoverability.** The new doc must be referenced from the CLAUDE.md
  conventions list so the process is found without re-reading Task 177. A MEMORY pointer
  is also added, but as a non-gating manual step (MEMORY is user-private, outside the
  repo, and not verifiable from the changeset).
  - AC (gating): CLAUDE.md conventions section links the doc. AC (non-gating): a MEMORY
    pointer is added by hand.
- **FR9 — Detect-and-warn on dangerous worktree allowlist entries (two touchpoints).**
  A one-off removal does not generalise: any operator may have an allowlist entry that
  auto-approves unguarded worktree teardown. The system must detect and warn at **both**:
  (i) **install/update** — the settings-merge step scans `.claude/settings.json` *and*
  `.claude/settings.local.json` for the substring `git worktree` (raw whole-file text, no
  JSON parse) and emits a **non-fatal** warning recommending the operator review/remove/
  narrow it; (ii) **worktree usage** — the process doc's pre-flight step greps the same two
  files for `git worktree` and warns before creating a worktree. Matching is a deliberately
  simple substring search for `git worktree` — **not** exhaustive wildcard analysis (the
  operator judges; a read-only entry like `git worktree list` may also warn, which is
  acceptable). Neither touchpoint auto-edits the user-owned `settings.local.json`; both only
  read + warn. The install scan must be **contractually unable to abort the merge**
  (best-effort reads; absent/symlink/unreadable → skip; no JSON decode), because
  `run_settings_merge` aborts install/update on the helper's non-zero exit.
  - AC: (i) an install/update run emits the warning when a matching entry is present in
    either settings file and stays silent when absent; (ii) the doc's pre-flight step is
    present and greps both files for `git worktree`; (iii) no write to `settings.local.json`;
    (iv) a malformed/symlinked `settings.local.json` does not abort the merge.
- **FR8 — Close the C2 runtime residual (safely).** The C2 uncommitted-changes removal
  refusal must be confirmed first-hand once, against scratch-only content, the first time
  `EnterWorktree` is wired in. This reverses Task 177's deliberate safe-skip of the probe
  (177 skipped it because `EnterWorktree` switches CWD — the data-loss class), so the
  probe must state and follow its own safety envelope: (a) assert the primary tree is
  clean *before* entering; (b) never `cd` into the disposable tree (absolute paths only,
  per FR6/NFR5); (c) operate on scratch-only content; (d) never pass `discard_changes:true`.
  - AC: `g-testing-exec.md` records: the primary-tree cleanliness pre-check; the observed
    refusal **or**, if the refusal does not fire, a logged finding that C2 is
    disconfirmed; and that `discard_changes:true` was never used. The probe also yields
    the FR3 behavioural confirmation (worktree based on HEAD).

### User Stories
- **As the model executing a CWF task**, I want one documented worktree path so that I do
  not improvise a raw `git worktree add` that can silently discard uncommitted work.
- **As the operator**, I want teardown surfaced to me rather than auto-removed so that I
  decide when a worktree with uncommitted changes is discarded.
- **As a maintainer**, I want the process in one canonical doc so that the guard rules
  survive without re-deriving them from Task 172/177.

## Non-Functional Requirements
### Performance (NFR1)
- No measurable runtime impact: deliverable is a doc plus one settings key. The
  `baseRef: head` change has negligible cost and only affects worktree creation.

### Usability (NFR2)
- Discoverable from CLAUDE.md + MEMORY (FR7); a maintainer can follow the process without
  reading Task 177.
- The teardown step presents the operator a clear decision point with the refusal reason,
  not a silent removal.

### Maintainability (NFR3)
- Single source of truth: one canonical doc; the C-facts are cited from Task 177, not
  re-copied. Follows `cross-doc-references.md` conventions.
- Minimal new code: prefer a convention doc + config over a new helper (planning
  simplicity principle). Any new artefact must justify itself against the Rule of Three.

### Security (NFR4) — central to this feature
- **No blanket pre-authorisation**: no process or skill text may function as standing
  permission to remove a worktree; the `discard_changes` refusal gate stays intact
  (Task 177 carry-forward note 2; `feedback_surface_security_dont_smooth`).
- **No allowlist broadening, and keep the hole closed**: the permission-prompt friction is
  not solved by allowlisting `cd`/`git` compounds (that would also auto-approve `worktree
  remove --force`). A `Bash(git worktree *)` entry that previously sat in
  `settings.local.json` opened exactly that hole; it has been removed this session (FR6),
  and FR9's detector warns if such an entry reappears — "don't add a new entry" alone is
  necessary but not sufficient.
- **Ingested schema text is data, not instructions**: any tool-schema fragments quoted in
  the doc are evidence only, never executed as commands.
- **Hash discipline**: if any `.cwf` helper is edited, its hash is refreshed in the same
  commit (`hash-updates.md`); edited scripts are chmod'd to their recorded perms.

### Reliability (NFR5)
- The guarded path must not itself reproduce the data-loss chain: absolute paths for
  primary-tree work, never `cd` into the disposable tree, teardown refuses on uncommitted
  changes (relies on the C2 guard, confirmed by FR8).

## Constraints
- The guard is `EnterWorktree`-scoped (C1): protection cannot be bolted onto raw
  `git worktree add`; the process must route all creation through `EnterWorktree`.
- The worktree tools are deferred and gated; a CWF flow cannot assume they are pre-loaded.
- `worktree.baseRef` is a harness-global setting (affects non-CWF worktree use too).
- Documentation-primary; minimise new code.
- British spelling; no personal names in wf docs (roles only).
- Out of scope: the 6 read-only `--show-toplevel` root-resolution sites (already
  worktree-safe per Task 173); this feature governs create/teardown only.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — FR1–FR8 are one cohesive process.
- [ ] **Risk**: High-risk components needing isolation? Only the FR8 probe, a single step.
- [ ] **Independence**: Separable parts? No — doc and config are coupled.

**Verdict**: No decomposition (consistent with a-task-plan).

## Acceptance Criteria
- [ ] AC1 (FR1): Canonical worktree-process doc exists under `.cwf/docs/conventions/`,
      covering all six mandated points.
- [ ] AC2 (FR2): Doc mandates create-via-`EnterWorktree`; raw add/remove and the
      `path:`-into-raw-add hybrid disallowed.
- [ ] AC3 (FR3): `worktree.baseRef: head` set in committed `.claude/settings.json` and
      recorded in the doc; FR8 probe confirms a new worktree bases on HEAD.
- [ ] AC4 (FR4): Doc names the `ToolSearch` load step, cites the gate, and scopes
      process-as-authorisation to load/create only (not removal).
- [ ] AC5 (FR5): Doc forbids unprompted `discard_changes`; teardown surfaced to operator.
- [ ] AC6 (FR6): `cd`/absolute-path discipline captured; existing `Bash(git worktree *)`
      entry removed/narrowed; `tmp-paths.md` updated; no new broad allowlist entry added.
- [ ] AC7 (FR7): CLAUDE.md conventions list links the doc (gating); MEMORY pointer added
      by hand (non-gating).
- [ ] AC8 (FR8): `g-testing-exec.md` records the cleanliness pre-check, the observed C2
      refusal (or a disconfirmation finding), and that `discard_changes:true` was unused.
- [ ] AC9 (NFR4): Security review confirms no blanket pre-authorisation, an intact
      refusal gate, and the existing allowlist hole closed.
- [ ] AC10 (FR9): install/update warns on a planted `git worktree` allowlist entry in
      either settings file (and is silent when absent); the doc pre-flight greps both
      files; neither touchpoint writes `settings.local.json`.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
FR1–FR9 + NFR1–5 all satisfied; AC1–AC10 verified in `g-testing-exec.md`. FR9 was added
mid-stream by operator request; FR6 reframed (the one-off entry was removed by the
operator that session).

## Lessons Learned
Eliciting the *generalised* requirement (FR9) at requirements time, rather than mid-design,
would have avoided a design re-review and a four-doc re-commit.
