# Skip non-regular files in untracked sweep - Testing Plan
**Task**: 209 (bugfix)

## Task Reference
- **Task ID**: internal-209
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/209-skip-non-regular-files-in-untracked-sweep
- **Template Version**: 2.1

## Goal
Verify the `-f || -l` filter excludes the char-device bind-mount case (the bug)
without regressing untracked regular-file or symlink inclusion.

## Test Strategy
### Test Levels
The helper is a non-modular Perl script; the established pattern (its own
`t/security-review-changeset.t`) is **integration tests** that build a synthetic
git repo and run the helper as a subprocess, asserting on stdout/stderr/exit.
New cases follow that pattern — no unit layer, no new harness.

### Adjacent existing coverage (do not duplicate)
- **TC-GUARD1a**: a *tracked* symlink (to `/dev/null`) is reviewed, link-text as
  blob. Covers the tracked path, not the untracked sweep.
- **TC-GUARD1b**: an *untracked* FIFO present in the tree does not block/hang the
  helper. Confirms (matching empirical fact) that git does **not** enumerate
  fifos via `ls-files --others`, so a fifo never reaches `git add -N`. The bug
  therefore cannot be reproduced with a fifo — only with a char/block device.

### Coverage targets
- Critical path (the filter): 100% — both retained types (regular, symlink) and
  the excluded type that actually reproduces the bug (char device).
- Regression: the full `t/security-review-changeset.t` passes unchanged.

## Test Cases
### Functional Test Cases
- **TC-209-1** (portable): untracked symlinks are retained in the sweep
  - **Given**: a synthetic repo with two untracked symlinks — one to `/dev/null`
    and one dangling (`-> /nonexistent`) — plus a normal untracked file.
  - **When**: the helper runs.
  - **Then**: exit 0; both symlink paths appear in the changeset body and the
    `includes uncommitted` suffix is present. Guards the `-l` retention so a
    future bare-`-f` narrowing (which drops both, since `-f` is false for a
    dangling symlink and a symlink-to-device) fails this test. SKIP if the
    filesystem cannot create symlinks (mirror TC-GUARD1a's guard).

- **TC-209-2** (Linux-gated): a char-device untracked entry no longer aborts
  - **Given**: a synthetic repo with a normal untracked file `keep.txt` and a
    path `masked` that is a regular file bind-mounted over with `/dev/null`,
    performed inside a `unshare -rm` user+mount namespace so the helper runs in
    the same namespace and `git ls-files --others` enumerates `masked` as a char
    device.
  - **When**: the helper runs inside that namespace.
  - **Then**: exit 0 (pre-fix it exits 1 — the reported abort); `masked` is
    absent from the changeset; `keep.txt` is still reviewed.
  - **SKIP** (clean, not fail) when any of: `unshare` binary absent;
    `unshare -rm` fails (unprivileged user namespaces disabled); `mount --bind`
    fails inside the namespace. Probe cheaply first and `skip` with a reason.

### Non-Functional Test Cases
- **Reliability**: TC-209-2 also implicitly confirms the END-block index restore
  is not reached on the no-abort path (the masked entry is never `add -N`'d).
- No performance, security-auth, or usability dimensions apply to a path filter.

## Test Environment
### Setup Requirements
- `git`, Perl core (`Test::More`, `File::Temp`, `POSIX`) — already required by
  the existing test file.
- TC-209-2 only: `/usr/bin/unshare`, unprivileged-user-namespace support, and
  bind-mount capability. Absent any of these the case SKIPs.

### Automation
- Run via `prove t/security-review-changeset.t` (or `prove t/`); same as today.

## Validation Criteria
- [ ] TC-209-1 passes (or SKIPs only where symlinks are unsupported).
- [ ] TC-209-2 passes on Linux with userns (SKIPs cleanly elsewhere).
- [ ] Red-then-green confirmed: TC-209-2 reproduces exit 1 on the unpatched
      helper, exit 0 after the fix (documented in g-testing-exec).
- [ ] Full `t/security-review-changeset.t` green; `cwf-manage validate` clean.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
