# Skip non-regular files in untracked sweep - Design
**Task**: 209 (bugfix)

## Task Reference
- **Task ID**: internal-209
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/209-skip-non-regular-files-in-untracked-sweep
- **Template Version**: 2.1

## Goal
Filter the untracked-file sweep in `security-review-changeset` so only
git-indexable path types reach `git add -N`, preventing the helper aborting on
non-regular untracked entries (sandbox device masks).

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Problem Statement
`list_untracked_files()` (security-review-changeset:504) returns every path from
`git ls-files --others --exclude-standard`. Those paths are passed to
`capture_git('add', '-N', '--', @untracked)` (line 240). `capture_git`
(line 351) **dies with exit 1 on any non-zero git status**.

A sandbox harness (e.g. Claude Code) bind-mounts `/dev/null` (a char device)
over config dotfiles at the repo root as a defensive mask. `git ls-files
--others` enumerates these as untracked, but `git add -N` cannot intent-to-add a
non-regular file and exits non-zero — aborting the whole reviewer. Neither
component is broken; they fail to compose when the working tree contains
untracked non-regular files.

## Key Decisions
### Decision: filter in `list_untracked_files()`, keep regular files + symlinks
- **Decision**: After splitting the `ls-files` output, keep an entry only when
  it is a regular file (`-f`) or a symlink (`-l`); drop everything else
  (char/block devices, fifos, sockets).
- **Rationale**:
  - Regular files and symlinks are exactly the object types git can
    intent-to-add and render in a diff. A symlink's blob is its link text, so
    `git add -N` succeeds and TC-GUARD1a already pins that symlinks must remain
    reviewed — hence `-l` is kept, not just `-f`.
  - `-f` follows symlinks; a symlink-to-regular-file is caught by `-f` too, but
    `-l` additionally retains dangling symlinks and symlinks-to-devices (git
    stores their link text regardless of target), so the `-f || -l` union is
    correct. Verified empirically (git 2.43): both `ln -s /dev/null` and a
    dangling symlink are enumerated by `ls-files --others` and accepted by
    `git add -N`; both are `-f`-false and `-l`-true, so `-l` is load-bearing.
  - **Precedent**: `.cwf/scripts/hooks/stop-stale-status-detector:23` already
    uses `grep { -f $_ } @changed` to filter a git-derived path list to regular
    files. This site diverges to `-f || -l` because, unlike that hook (which
    drops deleted-in-diff paths and never needs symlinks), the untracked sweep
    must retain symlinks so `git add -N` can intent-to-add their link-text blob
    (pinned by the existing tracked-symlink guard TC-GUARD1a).
  - Filetests resolve relative to the helper's cwd, which is the same cwd git
    ran in, so the relative paths from `ls-files` resolve consistently (no
    chdir occurs between enumeration and filtering). `-l` uses lstat (stat on
    the link itself), so it is immune to a target swap between enumeration and
    the filetest; the filter guards composition robustness, not a trust
    boundary, so the residual TOCTOU window is benign here. A future reuse of
    this predicate to gate a *security* decision would need to revisit that.
- **Trade-offs**: A non-regular untracked path is silently excluded from the
  reviewed set. This is acceptable: such a path can never be diffed or
  intent-to-added, so it carries no reviewable content; the device masks are
  harness noise, not repo changes.
- **Enumeration nuance (verified, git 2.43)**: `git ls-files --others` already
  skips fifos and sockets (readdir reports their concrete d_type), so they
  never reach `git add -N` and the filter is belt-and-braces for them. The
  filter is *load-bearing only* for char/block devices, which a bind-mount
  surfaces as a `DT_UNKNOWN`→non-regular entry that git DOES enumerate and
  `git add -N` rejects (`can only add regular files, symbolic links or
  git-directories`). The reproduction requires a mount namespace
  (`unshare -rm` + `mount --bind /dev/null`), so it is Linux-only — see the
  testing plan for the SKIP gate.

### Decision: drop silently, do not warn
- **Decision**: Excluded entries produce no stderr output.
- **Rationale**: The helper's `warn`+exit-1 convention is the "error"
  classification the SubagentStop verdict guard relies on; an incidental
  `warning:` line on every sandboxed run would be noise and risks misreads. The
  "surface, never smooth" rule targets integrity/tampering signals — a
  `/dev/null` mask is neither. The existing `reviewed N files` summary already
  reflects the true reviewed set.

## System Design
### Component Overview
- **`list_untracked_files()`** (the only changed unit): enumerate untracked
  non-ignored paths, then filter to git-indexable types before returning.
- **Callers unchanged**: the `@untracked` consumer block (add -N, END-block
  reset list, included-set concat, dirty suffix) operates on the filtered list
  with no other change.

### Data Flow
1. `git ls-files --others --exclude-standard -z` → raw NUL-separated paths.
2. `split /\0/` + `grep { length }` → candidate path list (unchanged).
3. **New**: `grep { -f $_ || -l $_ }` → git-indexable paths only.
4. Returned to caller → `git add -N` (now never sees a non-regular path).

## Interface Design
No external interface change: `list_untracked_files()` keeps its signature
(no args, returns a list of path strings). Output is a subset of the prior
output. No config keys, no CLI flags, no consumer-site changes.

## Constraints
- POSIX core-Perl only; `-f`/`-l` filetests are built-ins (no module).
- Hash refresh for the edited script lands in this task's commit
  (hash-updates convention).
- British spelling in prose; `use utf8;` already present in the script.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one filter expression.
- [ ] **Risk**: high-risk components needing isolation? No.
- [ ] **Independence**: parts separable? No.

No signals triggered — single-function change.

## Validation
- [ ] Design review completed (plan-review map/reduce)
- [ ] Integration points verified (callers of `list_untracked_files` unchanged)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
