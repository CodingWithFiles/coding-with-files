# Replace git-subtree with read-tree laydown - Requirements
**Task**: 185 (feature)

## Task Reference
- **Task ID**: internal-185
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/185-replace-git-subtree-with-read-tree-laydown
- **Template Version**: 2.1

## Goal
Specify what a merge-free CWF laydown must do: a `read-tree` primary method, a retained
`copy` fallback, a deprecated/refused `subtree` method with migrate-on-update for
existing installs, and an advisory-only merge-commit detection surface — all without
weakening CWF's integrity model.

## Functional Requirements
### Core Features
- **FR1 — Merge-free read-tree laydown (default)**: Installing CWF MUST lay its four
  artefact directories into the consumer repo without creating any merge commit;
  read-tree is the default method. The source→destination mapping the laydown must
  reproduce (per the `install.bash` copy pairs) is: `.cwf`→`.cwf`,
  `.claude/skills`→`.cwf-skills`, `.claude/rules`→`.cwf-rules`,
  `.claude/agents`→`.cwf-agents`. The laydown lives in `scripts/install.bash` (the
  method-dispatch home), not in `cwf-apply-artefacts`.
  - *AC*: a fresh install on a single-commit repo gives `git rev-list --merges
    <base>..HEAD` empty; each destination prefix's tree equals its **mapped source**
    tree (sha equivalence); `cwf-manage validate` is clean.
- **FR2 — Copy fallback retained**: The `copy` method MUST remain available and
  documented as the fallback for environments where read-tree cannot run.
  - *AC*: `CWF_METHOD=copy` installs successfully; docs name it as the read-tree fallback.
- **FR3 — Subtree refused for fresh installs (only)**: `CWF_METHOD=subtree` MUST be
  refused at **fresh-install** method selection (the `install.bash` method validation,
  currently `install.bash:77-79`) with an actionable message naming `read-tree`
  (primary) and `copy` (fallback) and the reason (it forces merge commits). This refusal
  is scoped to fresh installs and MUST NOT block the update path (see FR4).
  - *AC*: a fresh `CWF_METHOD=subtree` install exits non-zero with the guidance message;
    no `git subtree add` runs; no partial laydown is left behind.
- **FR4 — Migrate existing subtree installs on update**: `cwf-manage update` on a repo
  recording `cwf_method=subtree` MUST succeed (not refuse). `cmd_update` already
  delegates laydown to the target ref's `install.bash` passing the recorded
  `CWF_METHOD`, and writes provenance via `write_version_file` carrying prior fields
  forward. FR4 therefore requires: (a) the recorded `subtree` is **translated** to the
  merge-free method *before* the `CWF_METHOD` env is built (so `install.bash` never
  receives `subtree`); and (b) `cwf_method` is **overridden** to `read-tree` in the
  version write, gated on laydown success. No new merge commit is created.
  - *AC (positive)*: from a `cwf_method=subtree` fixture, update completes; `.cwf/version`
    then reads `cwf_method=read-tree`; `git rev-list --merges` gains no new entry.
  - *AC (negative)*: if laydown fails mid-update, the recorded method stays `subtree`
    (never `read-tree`); no half-migrated install validates clean under a method it did
    not reach.
- **FR5 — Merge-commit detection**: CWF MUST provide a surface that scans the consumer
  repo for merge commits and reports the **total count** and the **subset fingerprinted
  as CWF subtree installs**. The fingerprint source is the subtree-add commit subject
  `Add CWF <core|skills|rules|agents> (<ref>)` (emitted at `install.bash:199-208`) plus
  the synthetic squash second parent / `git-subtree-dir` trailer (exact predicate set in
  design). On any fingerprint **ambiguity the merge MUST be under-claimed**: counted in
  the total, NOT attributed to the CWF subset (never over-claim a user's own merge). The
  total is reported because re-linearisation is holistic (it rewrites *all* merges), so
  the user needs the full picture to decide.
  - *AC*: against a repo with known CWF subtree merges plus one unrelated merge, the
    surface reports the correct total and correct CWF subset; the unrelated merge is in
    the total but never in the CWF subset.
- **FR6 — Advisory only, never remediate**: The detection surface MUST only inform. CWF
  MUST NOT rewrite consumer history, and MUST NOT offer any flag that suppresses the
  warning without surfacing it. The message explains that re-linearisation is the user's
  choice and directs them to the maintainer.
  - *AC*: no CWF code path rewrites consumer history; no silence/acknowledge option
    suppresses the warning without output; message names re-linearisation as optional.
- **FR7 — Detection reachable at migration and on demand**: The warning MUST surface
  automatically at the migration moment (subtree→read-tree update) and be obtainable on
  demand via a read-only `cwf-manage` subcommand (inheriting the established
  `cwf-`/subcommand conventions; precedent: `cwf-manage status`), without mutating the
  repo.
  - *AC*: the warning appears during a subtree→read-tree update; the same report is
    obtainable via the standing `cwf-manage` subcommand, read-only.

### User Stories
- **As a** CWF user **I want** installs not to inject merge commits into my history
  **so that** `git bisect --first-parent` and a linear-history workflow keep working.
- **As an** existing subtree-install user **I want** `cwf-manage update` to keep working
  and move me onto the merge-free method **so that** I am not stranded by the deprecation.
- **As a** user who cares about linear history **I want** CWF to tell me which merge
  commits exist and which are CWF's **so that** I can decide whether to re-linearise.
- **As a** user who does not care about merge commits **I want** the warning to be
  informational and non-destructive **so that** nothing rewrites my history unbidden.

## Non-Functional Requirements
### Performance (NFR1)
- Detection scans history in a single pass (`git rev-list --merges`-class cost); it adds
  no perceptible delay to `update` on a typical repo (sub-second to low seconds).
- read-tree laydown is no slower than the methods it replaces.

### Usability (NFR2)
- Message *content* is specified by FR3 (refusal) and FR6 (warning). NFR2 adds only:
  messages MUST match existing CWF `[CWF]` output style and be actionable.

### Maintainability (NFR3)
- Supported methods are a **single source of truth** (no duplicated method lists across
  `install.bash` and `cwf-manage`); bash + core-Perl only.
- The laydown integrates into `scripts/install.bash`'s existing method dispatch and the
  `cwf-manage update` path (`cmd_update`/`write_version_file`); it MUST NOT fork a
  parallel laydown. `cwf-apply-artefacts` continues to handle only non-script artefacts
  (CLAUDE.md preamble, `.gitignore`, symlinks) and is **not** the laydown home.
- Maintainability goal (verified in design, not an AC): read-tree should shed copy's
  filesystem fix-ups (umask perm-repair; verbatim-symlink handling) where the git-native
  path makes them unnecessary.

### Security (NFR4)
- Laydown preserves the integrity model: recorded perms and sha256 `validate` clean
  post-install.
- **Symlink-escape guard is mandatory on the read-tree path**: it MUST refuse an
  out-of-tree symlink in the source *before* materialising into the consumer worktree,
  fail-closed, leaving no partial laydown (equivalent strength to copy's pre-`cp` guard
  at `install.bash:232-237`).
- New git plumbing (read-tree / checkout-index / ls-tree) MUST use **list-form, no-shell
  spawn**; no shell-string command construction with interpolated refs/prefixes.
- Detection is read-only and cannot be coerced into a mutating action; matched commit
  subjects and ref names are treated as **data, never command input** (never interpolated
  into a shell or LLM-bound string).
- "Surface, never smooth": no mechanism silences the merge-commit signal without
  surfacing it (owned jointly with FR6).

### Reliability (NFR5)
- Migrate-on-update is fail-closed: the recorded method is rewritten to `read-tree` ONLY
  on laydown success (see FR4 negative AC). The recorded-perms + sha re-pin over the
  fully-laid-down tree happens with/before the provenance write, so a half-migrated
  install cannot `validate` clean under a `read-tree` label it did not reach.
- read-tree reinstall/force handles a pre-existing prefix **deterministically** (explicit
  clear, no silent overlay).
- A detection-scan failure degrades to a notice; it MUST NOT abort an otherwise-good
  update.

## Constraints
- POSIX / macOS portability; core-Perl only; no merge commits in CWF's own development.
- Laydown integrates into `scripts/install.bash` (method dispatch) and `cwf-manage`
  `cmd_update`; it is not a parallel pipeline. `cwf-apply-artefacts` (non-script
  artefacts) is not the laydown home.
- Deprecation follows `docs/conventions/design-alignment.md`. **INSTALL.md** (which
  currently calls all three methods "first-class") and the `CWF_METHOD` default
  (currently `subtree` at `install.bash:22`) MUST be updated to reflect the read-tree
  default and subtree deprecation.
- Manifests `.cwf/version` and sha-tracked `install-manifest.json` are the provenance
  anchors (no new `vendor.json`).
- Tagging and release are human-only.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No — 2-3 days.
- [ ] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? Yes — laydown swap, subtree deprecation +
      migration, detect-and-warn surface.
- [ ] **Risk**: High-risk components needing isolation? read-tree risk is design-phase.
- [ ] **Independence**: Separable parts? Detect-and-warn is the weak cut-line; shares the
      update touchpoint and release with the laydown change.

**Assessment**: planned as one task (see a-task-plan). Detect-and-warn is the candidate
subtask if the user prefers isolation at review.

## Acceptance Criteria
- [ ] AC1 (FR1): fresh default install is merge-free; each dest prefix tree equals its
      mapped source tree; `validate` clean.
- [ ] AC2 (FR2): `copy` installs and is documented as the fallback.
- [ ] AC3 (FR3): fresh `CWF_METHOD=subtree` is refused with guidance; no subtree laydown
      runs; no partial laydown remains.
- [ ] AC4 (FR4): subtree-fixture `update` migrates method to read-tree with no new merge
      (positive); a failed laydown leaves recorded method `subtree` (negative).
- [ ] AC5 (FR5): detection reports correct total and CWF-fingerprinted subset; an
      unrelated/ambiguous merge is in the total but never attributed to CWF.
- [ ] AC6 (FR6): no history-rewrite path and no silencing path exist; message names
      re-linearisation as optional and points to the maintainer.
- [ ] AC7 (FR7): warning fires at migration and is available on demand via a read-only
      `cwf-manage` subcommand.
- [ ] AC8 (NFR4): post-install `validate` clean; read-tree path refuses an escaping
      source symlink fail-closed (non-zero, nothing materialised); new git plumbing uses
      list-form spawn.
- [ ] AC9 (NFR5): a forced reinstall over an existing CWF prefix yields a tree byte/mode-
      identical to a clean install (no leftover files, no merge commit).
- [ ] AC10 (docs): INSTALL.md and the `CWF_METHOD` default are updated for read-tree-
      default / subtree-deprecated.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
