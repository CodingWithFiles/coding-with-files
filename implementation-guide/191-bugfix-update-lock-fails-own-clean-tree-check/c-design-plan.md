# update lock fails own clean-tree check - Design
**Task**: 191 (bugfix)

## Task Reference
- **Task ID**: internal-191
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/191-update-lock-fails-own-clean-tree-check
- **Template Version**: 2.1

## Goal
Define the fix that makes `check_clean_tree` ignore CWF's own ephemeral
`.cwf/.update.lock`, breaking the self-block without weakening the dirty-tree gate
or disturbing the D8 lock-before-check ordering.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Root Cause (confirmed)
- `cmd_update` (`cwf-manage:462`) acquires the lock **before** `check_clean_tree`
  (`:471`). The ordering is the D8 concurrency invariant (`:458-461`): two
  concurrent updates must not both pass clean-tree before one blocks.
- `acquire_update_lock` (`:254-267`) `sysopen`s `.cwf/.update.lock` with `O_CREAT`,
  so the file exists on disk by the time the check runs.
- `check_clean_tree` (`:151-176`) runs
  `git status --porcelain -z --untracked-files=all -- .cwf .cwf-skills .cwf-rules .cwf-agents`.
  The lock lives under `.cwf`, so it appears as `?? .cwf/.update.lock` unless
  `.gitignore` lists it — and that ignore line is only added *by the update itself*
  (`install-manifest.json:10-14`). Pre-artefact installs are therefore unable to
  ever pass the gate.

## Key Decisions
### Decision: exclude the lock via a git pathspec (not a re-order, not a record-parse)
- **Decision**: Add the magic exclude pathspec `':(exclude).cwf/.update.lock'` to
  the existing `git status` argument list in `check_clean_tree`, so the lock is
  filtered by git before any output is produced.
- **Rationale**:
  - Keeps the D8 ordering untouched — the check stays after lock acquisition; we
    only make the check *lock-aware*.
  - Git does the filtering, so the Perl side keeps treating each NUL record
    opaquely (no parsing of the `XY␣PATH` porcelain prefix, no rename-pair edge
    cases). This is the readability/consistency win over a post-`split` filter.
  - The exclusion is an **exact path**, not a glob, so it cannot mask any other
    uncommitted change (addresses the over-broad-exclusion risk from the plan).
    Security note for future maintainers: this stays safe only while it is an
    exact literal — never widen it to a glob (`:(exclude).cwf/*.lock`) or a
    directory prefix, which would let an attacker-planted file hide from the gate.
  - The exclude filters the lock in **every** state (untracked, or — hypothetically
    — tracked-and-modified), not just the untracked `??` case that triggers the
    bug today. That is intended: the lock is CWF's own ephemeral artefact and must
    never count toward dirtiness regardless of how git happens to classify it.

**Implementation trap (do not absolutise the pathspec):** the single source of
truth is the *repo-relative* string `.cwf/.update.lock`. The two consumers compose
it differently and must keep doing so — `acquire_update_lock` joins it to
`$git_root` to get an absolute path for `sysopen`; `check_clean_tree` passes it
**bare** as the exclude value, because `git -C $git_root status` already resolves
pathspecs relative to `$git_root` (matching the existing positive pathspecs
`.cwf`, `.cwf-skills`, …). Absolutising the exclude pathspec would break the
`-C`-relative match and silently re-open the bug.
- **Trade-offs**:
  - `:(exclude)` magic-pathspec syntax is marginally less familiar than a literal
    path, mitigated by an inline comment naming it as the lock-self-exclusion.
  - Exclude pathspecs require at least one positive pathspec — already satisfied by
    the four existing scope paths.

### Rejected alternatives
- **Re-order: acquire lock after clean-tree** — would also hide the symptom but
  breaks the D8 invariant (the concurrency window the comment exists to close).
  Rejected.
- **Post-`split` record filter in Perl** — must parse the porcelain record format
  (`substr($_, 3)`) and handle rename pairs; couples the check to git's output
  shape. More fragile than letting git exclude. Rejected.
- **Acquire the lock outside `.cwf`** (e.g. under `/tmp`) — widens the change
  surface, loses the symlink-TOCTOU guard's locality, and is a larger behavioural
  shift than warranted. Rejected.

### Decision: single source of truth for the lock path
- **Decision**: Introduce one file-scoped lexical `my $UPDATE_LOCK_REL = '.cwf/.update.lock';`
  (repo-relative), used by both `acquire_update_lock` (joined to `$git_root`) and
  `check_clean_tree` (as the exclude pathspec value).
- **Rationale**: The path would otherwise be a literal duplicated across the two
  subs that must stay in lock-step; a drift between them silently reopens the bug.
  Matches the script's existing file-scoped-lexical style (`$update_in_progress`,
  `:46`).
- **Trade-offs**: One new module-level lexical; negligible.

## System Design
### Component Overview
- **`$UPDATE_LOCK_REL`** (new, file scope): canonical repo-relative lock path.
- **`acquire_update_lock`** (changed): builds its absolute path from
  `$git_root` + `$UPDATE_LOCK_REL` instead of an inline literal. Behaviour
  unchanged.
- **`check_clean_tree`** (changed): appends `":(exclude)$UPDATE_LOCK_REL"` to the
  `git status` pathspec list. Sole behavioural change.

### Data Flow (update pre-flight, after fix)
1. `cmd_update` → `acquire_update_lock` creates `.cwf/.update.lock` (D8 unchanged).
2. `cmd_update` → `check_clean_tree` runs `git status … :(exclude).cwf/.update.lock`.
3. git omits the lock from output; any *other* dirty path under the scope dirs is
   still reported → die as before. A tree dirty only by the lock → returns clean.

**Security division of labour:** excluding the lock from `check_clean_tree` does
*not* weaken lock-path attack detection. The symlink/TOCTOU guard (`-l` precheck +
`O_NOFOLLOW`, `:257-261`) lives in `acquire_update_lock`, which runs *before* the
check (D8). So the excluded path is always the guard-validated regular file;
`check_clean_tree` was never the component defending the lock path, and still
isn't.

## Interface Design
No external interface change. `check_clean_tree($git_root)` and
`acquire_update_lock($git_root)` keep their signatures and return contracts. The
only observable difference is that a tree whose sole change is `.cwf/.update.lock`
now passes instead of aborting.

## Constraints
- Perl core-only; POSIX-portable (macOS system Perl). `:(exclude)` is a git
  pathspec feature, not a Perl dependency.
- Hashed file: refresh `.cwf/security/script-hashes.json` for `cwf-manage` in the
  same commit; restore working perms to the recorded value (0700) after editing,
  per the hash-updates convention.
- Must not alter the D8 lock-before-check ordering.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one change to one sub plus a shared constant.
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Separable parts? No.

**Conclusion**: 0 signals. No decomposition.

## Validation
- [ ] Design review completed (Step 8 plan review)
- [ ] Approach verified against the actual `check_clean_tree` / `acquire_update_lock` source
- [ ] Existing test harness (`t/cwf-manage-check-clean-tree.t`) confirmed able to exercise the fix directly

### Regression test cases (hand to e-testing-plan as acceptance criteria)
- **TC-lock-only**: tree dirty *solely* by `.cwf/.update.lock` → `check_clean_tree`
  returns without dying. Fails on current code, passes after the fix — this is the
  bug reproducer.
- **TC-lock-plus-real**: `.cwf/.update.lock` present *and* a second untracked/dirty
  path under `.cwf` → still dies and lists the real path. Proves the exclusion is
  exact, not over-broad (guards the High-priority risk from the plan).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design implemented verbatim: git exclude-pathspec in `check_clean_tree`, shared
`$UPDATE_LOCK_REL` constant, `acquire_update_lock` re-point. The "do not absolutise
the pathspec" trap and the security division-of-labour note both held in exec — no
re-open of the bug, security review `no findings`.

## Lessons Learned
The bare-vs-absolute pathspec distinction was the subtle part; documenting it in
design meant it was implemented right first time. Letting git filter (not a Perl
post-split filter) kept the NUL-`-z` contract intact. See j-retrospective.md.
