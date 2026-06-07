# Replace git-subtree with read-tree laydown - Design
**Task**: 185 (feature)

## Task Reference
- **Task ID**: internal-185
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/185-replace-git-subtree-with-read-tree-laydown
- **Template Version**: 2.1

## Goal
Define the architecture for a merge-free `read-tree` laydown (default), a retained `copy`
fallback, a refused/migrated `subtree` method, and a read-only merge-commit detection
surface — integrating into the existing `install.bash` dispatch and `cwf-manage`
`cmd_update` delegation rather than forking a parallel laydown.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Spike (top risk retired)
A throwaway-repo spike validated the read-tree mechanics (the a-task-plan top risk).
Results, all confirmed:
- **Source→dest remap works**: resolve a source subtree to its tree object
  (`git rev-parse <fetched>:.claude/skills`) and lay it at a different prefix
  (`git read-tree --prefix=.cwf-skills/ <tree>`). The destination prefix's tree SHA
  **equals the mapped source subtree SHA** for all four pairs (tree-identity preserved).
- **Merge-free**: the post-laydown commit has **one parent**; `git rev-list --merges
  base..HEAD` is empty.
- **Modes preserved**: executable bit (`100755`) and symlink (`120000`) survive.
- **Reinstall is explicit, not silent**: `read-tree --prefix` **refuses** to overlay an
  existing prefix (`error: Entry '…' overlaps … Cannot bind`); clearing the index entries
  under the prefix first (`git rm -r --cached`) then re-reading succeeds.
- **Symlink pre-scan from the tree**: `git ls-tree -r <tree>` enumerates `120000` entries
  without materialising — though the design reuses the existing filesystem guard instead
  (below).

Verified laydown core (per source→dest pair, run with cwd = consumer repo):
```
git fetch --no-tags "$clone_dir" "$ref"          # bring source objects into consumer store
tree=$(git rev-parse "FETCH_HEAD:$src_subpath")  # e.g. FETCH_HEAD:.claude/skills
git read-tree --prefix="$dest/" "$tree"          # index-only; refuses if $dest/ present
# ...after all four prefixes, materialise ONLY the laid-down prefixes (NUL-safe, no
# shell word-split/glob), see Robustness:
git ls-files -z -- .cwf .cwf-skills .cwf-rules .cwf-agents | git checkout-index -f -z --stdin
```
(The spike used `checkout-index -a -f`; production MUST scope materialise to the four
prefixes — the fresh-install path has no clean-tree precondition, so `-a -f` could
overwrite unrelated dirty user files. Correctness/data-safety outranks the listed design
priorities here, per the project tradeoff rule.)

## Key Decisions
### Architecture Choice
- **Decision**: Add a third laydown method `read-tree` in `scripts/install.bash`, make it
  the default, keep `copy` as the documented fallback, and **refuse `subtree`** at
  fresh-install method validation. Existing `subtree` installs are migrated by
  `cwf-manage` `cmd_update`, which **translates** the recorded method to `read-tree`
  before delegating laydown and records `read-tree`. A new read-only helper
  `cwf-detect-merges` reports merge commits, surfaced on demand
  (`cwf-manage check-merges`) and automatically after a subtree→read-tree migration.
- **Rationale**: read-tree is git-native, merge-free, and tree-identity-exact
  (spike-verified). It cooperates with the sha256/perms integrity model rather than
  needing copy's filesystem fix-ups. Housing the change in the existing dispatch +
  `cmd_update` delegation honours NFR3 (no parallel laydown; `cwf-apply-artefacts` stays
  the non-script-artefact home).
- **Trade-offs**: read-tree needs source objects in the consumer object store (one extra
  `git fetch` from the **local** clone — no second network fetch) and an explicit
  index-clear before laydown (read-tree will not silently overlay). `copy` remains for
  environments where that path cannot run.

### Why not commit the laydown
Like `install_copy` today, `install_read_tree` **does not create a commit** — it leaves
the laydown staged in the index/worktree for the user (or `/cwf-init`) to commit. This is
the property that fixes the bug: CWF stops dictating commit structure. (read-tree leaves
the laydown *staged* because it is index-based; copy leaves it unstaged — both are
"no commit by CWF", which is the invariant that matters.)

## System Design
### Component Overview
- **`scripts/install.bash` → `install_read_tree(clone_dir, ref)`** (new): (1) reuse the
  existing `cwf-check-tree-symlinks` guard over the clone roots — fail-closed, before any
  change to the consumer tree (identical call to `install_copy`; the clone is checked out
  at the same ref the subsequent `git fetch` resolves, so the scanned filesystem and the
  laid-down tree are the same object); (2) `git fetch --no-tags` source objects from the
  clone; (3) clear existing index+worktree under the four dest prefixes — **unconditional**
  (not `CWF_FORCE`-gated like `install_copy`'s `rm -rf`, because `read-tree --prefix`
  refuses to overlay an existing prefix), using `git rm -r --cached --ignore-unmatch`
  (no-op on a fresh repo) + worktree removal; **clear all four, then read all four**, so a
  mid-laydown `read-tree` failure leaves a recoverable state; (4) `read-tree --prefix`
  each mapped source subtree; (5) `checkout-index` to materialise **only the four
  prefixes** (not `-a`). Dies (non-zero) on guard/fetch/read-tree failure (FR3/NFR4
  fail-closed); recovery is re-run (the unconditional clear makes it idempotent).
  The four source→dest pairs are a **single shared list** (hoisted to a file-level
  `readonly` array consumed by the guard, `install_copy`, and `install_read_tree`) — not
  redeclared per function (install.bash already keeps a pair-list SoT comment at :220).
- **`scripts/install.bash` → dispatch & default** (changed): default
  `CWF_METHOD=read-tree`; `case` gains `read-tree)`; method validation **refuses
  `subtree`** with guidance naming read-tree (primary) + copy (fallback) + reason;
  `install_subtree()` is removed.
- **`cwf-manage` → `cmd_update`** (changed): accept `read-tree` in the method check
  (line 483); when the recorded method is `subtree`, set the laydown method to `read-tree`
  **before** building the `CWF_METHOD` env (so `install.bash` never receives `subtree`),
  and **add** `$v{cwf_method} = 'read-tree'` to the authoritative version-write block
  (521–526). Note: today that block does *not* set `cwf_method` (it carries the loaded
  value forward), so this is a new assignment, not an edit of an existing one — without it
  a migrated install would re-record `subtree`. The write is reached only after the
  laydown/artefacts/perms rc checks succeed; if any of those die first, `.cwf/version`
  keeps `cwf_method=subtree` while the tree is already read-tree-laid — the intended
  **fail-closed** outcome, and re-running `update` resumes the migration idempotently
  (the unconditional index-clear above makes the re-laydown safe).
- **`command-helpers/cwf-detect-merges`** (new, read-only, Perl/core-only): enumerate
  merge commits on `HEAD`; classify a merge as CWF-originated when the subject matches
  `^Add CWF (core|skills|rules|agents) ` **and** it carries a subtree marker — either a
  `git-subtree-dir:` trailer on the merge, or a second parent whose subject is
  `Squashed '…' content` (these are two distinct signals, not the same field).
  **Under-claim on ambiguity** (subject-only → counted in total, NOT in the CWF subset —
  never over-claim a user's own merge). Output **counts only** (total + CWF subset +
  advisory guidance); it MUST NOT echo raw commit subjects into the report. Reads git
  output **NUL-separated** (`git rev-list --merges` has no `-z`, and subjects can contain
  newlines — so per-commit reads via `git log -z --format=…`/`git show -s`, never a
  newline-split of a combined stream; exact invocation pinned in d-plan per
  `git-path-output.md`). Classified strings are **display-only** — never reused as command
  arguments. **Always exit 0** (never aborts a caller). *Why keep the CWF subset (not just
  a total):* the accountability split is a task requirement — CWF owns the merges it
  created and explicitly disclaims the user's own; the report is **idempotent** and keeps
  reporting the same merges on every run post-migration (history is not rewritten), which
  is expected, not a failed migration.
- **`cwf-manage` → `cmd_check_merges`** (new subcommand): a one-line delegate to
  `cwf-detect-merges` (FR7 on-demand surface); register it in the `%dispatch` table
  (cwf-manage :846) and `cmd_help` (:803/:810). It adds no reporting logic of its own.

### Data Flow
1. **Fresh install (read-tree)**: `install.bash main` → prereqs → clone source to TMPDIR →
   method validation (refuse `subtree`) → `install_read_tree` (guard → fetch → clear →
   `read-tree`×4 → `checkout-index`) → `post_install` (symlinks, settings merge, write
   `.cwf/version` with `cwf_method=read-tree`) → user commits the staged laydown.
2. **Update of a subtree install (migration)**: `cwf-manage update` → read `.cwf/version`
   (`cwf_method=subtree`) → lock/clean-tree/manifest checks → clone+checkout target ref →
   **translate** method `subtree`→`read-tree` → delegate to target `install.bash` with
   `CWF_METHOD=read-tree` → `run_apply_artefacts` → `apply_exact_perms_or_die` → write
   version (`cwf_method=read-tree`) → invoke `cwf-detect-merges` to warn about
   pre-existing merge commits → user commits.
3. **On-demand detection**: `cwf-manage check-merges` → `cwf-detect-merges` → read-only
   report; repo unchanged.

### Interface Design
- `.cwf/version` method field: `cwf_method=read-tree | copy` (never `subtree` after a
  migration; `subtree` only ever appears in a pre-migration install).
- `cwf-detect-merges`: human report only (no `--porcelain` — no in-tree parser consumes
  machine output; add one later if a consumer appears); counts only; exit 0 always. Form:
```
[CWF] Merge commits on this branch: 7 total.
[CWF]   4 originate from old CWF subtree installs (fingerprinted).
[CWF]   3 are from elsewhere in your repo — CWF makes no claim on those.
[CWF] CWF will not modify your history. If you want a linear history, re-linearisation
[CWF] is required; it is your choice. Contact the maintainer for help.
```
- `cwf-manage check-merges`: read-only; prints the report; exit 0.
- `install_read_tree`: no stdout contract beyond `log` lines; fail-closed exit on error.

## Constraints
- `read-tree --prefix` and `checkout-index` are long-standing git plumbing (portability
  is not a concern); the source objects are fetched from the **local** clone (no extra
  network). New git plumbing uses **list-form spawn** (NFR4) — no shell interpolation of
  refs/prefixes.
- `checkout-index -a` materialise relies on the clean-tree precondition `cmd_update`
  already enforces; fresh install proceeds from the user's committed state.
- Hash tracking: editing `.cwf/scripts/cwf-manage` and adding
  `.cwf/scripts/command-helpers/cwf-detect-merges` are hash-tracked — refresh
  `script-hashes.json` in the **same commit** (hash-updates convention).
  `scripts/install.bash` lives outside `.cwf/` and is **not** hash-tracked.
- Deprecation per `docs/conventions/design-alignment.md`; INSTALL.md (currently labels all
  three methods "first-class") and the `CWF_METHOD` default flip updated alongside.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? Yes — laydown, deprecation+migration,
      detection. Cohesive within one release; planned as one task (see a-task-plan).
- [ ] **Risk**: High-risk components needing isolation? The read-tree risk is retired by
      the spike above.
- [ ] **Independence**: Separable parts? `cwf-detect-merges` is the weak cut-line but
      shares the `cmd_update` touchpoint and release.

## Validation
- [x] Design review completed (read-tree spike; 4-agent plan review)
- [ ] Integration points verified: `install.bash` dispatch/default,
      `cmd_update` method translation + version override, `cwf-detect-merges` reuse from
      both `cmd_update` and `cmd_check_merges`
- [ ] Hash-tracked edits (`cwf-manage`, new `cwf-detect-merges`) refresh
      `script-hashes.json` in the same commit

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
