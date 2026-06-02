# review all changed files not just cwf-internal - Testing Plan
**Task**: 174 (bugfix)

## Task Reference
- **Task ID**: internal-174
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/174-review-all-changed-files-not-just-cwf-internal
- **Template Version**: 2.1

## Goal
Reconcile `t/security-review-changeset.t` to the review-all-files behaviour (D5), and add the three new cases the design requires: widening regression, cap fail-safe direction, and guard-removal safety.

## Test Strategy
### Test Level
Single level: the existing **integration** harness in `t/security-review-changeset.t`
— each subtest builds a synthetic git repo, runs the helper as a subprocess,
and asserts on stdout / stderr / exit. No new harness, no mocking; the helper's
contract is observable end-to-end. This is the right (and only) level: the bug
is in which files reach the diff, which is only visible by running the helper
against a real repo.

### Coverage target
Every behavioural claim in c-design D1–D2 has at least one asserting subtest:
all-files-included (was: classified-in), non-script-file-included (was:
excluded), test-file-reviewed-but-discounted, empty-diff→0-files, cap fires on
production-weighted count, guard-removal is safe.

## D5 — Per-subtest reconciliation map
Source file: `t/security-review-changeset.t` (768 lines). Each existing subtest
falls in exactly one bucket.

### DELETE / REPLACE (assert behaviour of deleted guards)
- **TC-NF3** (`symlink path is skipped (does not follow target)`, ~411) — asserted
  `unlike($out, qr{dangerous-link})` via the `-l` guard. The guard is deleted.
  **Replace** with the symlink half of TC-GUARD1 (below): the symlink is now
  *included*, and `git diff` emits its **link-target text** (the blob), not the
  dereferenced target's contents.
- **TC-NF4** (`FIFO is skipped (does not block on sysread)`, ~434) — already a weak
  `ok(1)` smoke for the `-f` guard; guard deleted. **Replace** with the FIFO half
  of TC-GUARD1: helper **completes without hanging** when a FIFO is in the working
  tree / diff window (git, not the helper, handles the non-regular file).

### INVERT (assert the now-false exclusion as inclusion)
- **TC-F5** (`binary blob outside CWF dirs is excluded`, ~247) → assert
  `like($out, qr{tools/blob})` and `reviewed 1 files` (was `unlike` + `reviewed 0 files`).
- **TC-F6** (`plain-text notes outside CWF dirs are excluded`, ~266) → assert
  `like($out, qr{notes\.txt})` (was `unlike`). Rename subtest to "…is included".
- **TC-NF5** (`helper completes quickly … noise files (no shebang) excluded`, ~485) →
  the `cmp_ok($elapsed, '<', 5)` perf assertion **stays**; invert the last
  assertion to `like($out, qr{noise/file})` (200 no-shebang files are now in the
  changeset). Perf claim still holds — `git diff` is O(diff), the helper does no
  per-file content sniff any more.

### RE-JUSTIFY (assertion holds; rationale/name was classifier-specific)
- **TC-F1** (extensionless CWF-internal script, ~131) — still included; reword
  comment "included because all files are reviewed" (was: CWF-internal/shebang).
- **TC-F2** (consumer python with shebang, ~150) — still included; reword "included
  because all files are reviewed" (was: "via shebang sniff"). This is the key
  honesty fix — the file is no longer included *because* it has a shebang.
- **TC-F4** (binary blob under `.cwf/scripts/`, ~229) — still included; reword
  "all files reviewed" (was: "regardless of shebang").
- **TC-CAP2** (~655) — comment `test file is in the changeset (shebang-included)`
  → "in the changeset (all files reviewed)"; the t/** discount assertion is
  unchanged and still the point of the test.

### UNCHANGED (anchor / cap / validation — independent of the classifier)
TC-F3 (unmerged-predecessor anchor), TC-F7 (subtask baseline), TC-F8 (malformed
baseline fallback), TC-NF1 (trunk `..` rejected), TC-NF2 (`--task-num` injection
rejected), TC-Task141 (staged+unstaged window), TC-CAP1/CAP3/CAP4/CAP5/CAP6/CAP7.
These use `.cwf/scripts/*` (included before and after) or test the anchor/cap/CLI
surface the design leaves untouched. Verify-only at exec; no edit expected.

## New Test Cases

### TC-WIDEN1 — non-script consumer source is reviewed and counted
- **Given**: a synthetic repo (via `make_cap_repo`, no `test-paths`) with a changed
  `src/app.js` — no shebang, outside `.cwf/`/`.claude/`.
- **When**: helper runs with `--max-lines=1000`.
- **Then**: `like($out, qr{src/app\.js})` (in the emitted diff) **and** the
  `(N production)` field counts its added lines (`> 0`). This is the bug's
  headline: a consumer's application file is now reviewed. (TC-F5/F6 prove
  *inclusion*; TC-WIDEN1 additionally proves it *counts as production*.)

### TC-CAP8 — unconfigured test path counts as production (fail-safe direction)
- **Given**: `make_cap_repo` with **no** `security.review.test-paths`; a changed
  `t/foo.t` (50 lines).
- **When**: helper runs with `--max-lines=10`.
- **Then**: `is($rc, 2)` — with no test-paths configured, the test file is **not**
  discounted and counts toward the cap, so the cap fires. Documents that the cap
  fires earlier (never later) when unconfigured — not a regression. Pairs with
  TC-CAP2 (configured `t/**` → discounted → under cap).

### TC-EMPTY1 — genuinely empty diff stays empty (no whole-tree leak)
- **Given**: a synthetic repo where the recorded baseline **equals** HEAD/worktree
  state — no changed files between anchor and working tree.
- **When**: helper runs.
- **Then**: `is($rc, 0)`, `like($err, qr{reviewed 0 files})`, and `is($out, '')`.
  This is the highest-consequence invariant: it proves the line-193 `!@included`
  guard fires so a bare `git diff $anchor --` (no pathspec → whole-tree) can never
  run once the classifier is gone. No existing subtest asserts the empty case
  directly — this closes it.

### TC-GUARD1 — guard-removal safety (MANDATORY; sole evidence for D1's DoS claim)
- **Given**: a synthetic repo with (a) a committed symlink `dangerous-link → /dev/null`
  and (b) a FIFO present per the TC-NF4 setup shape.
- **When**: helper runs.
- **Then**:
  - Symlink: `like($out, qr{dangerous-link})` and the diff body shows the
    **target string** `/dev/null` as the blob, proving git did not dereference
    and read the target. Falsifiable: a leak would show `/dev/null`'s (empty)
    *content* framed as a regular-file diff, or block.
  - FIFO: helper **exits within the existing time bound** (no hang) — git stats
    the FIFO, the helper never opens it (the sniff that did is gone).
  - Keep the `SKIP` guards for filesystems without symlink/`mkfifo` support.

## Test Environment
- **Harness**: `prove` / `Test::More`, run as `t/security-review-changeset.t`.
- **Deps**: core only (`File::Temp`, `File::Path`, `POSIX`, `Cwd`, `FindBin`) —
  already used; no new modules (per core-only constraint).
- **Isolation**: each subtest gets its own `tempdir(CLEANUP => 1)` synthetic repo;
  no contact with the real repo or any production data.
- **Run**: `chmod +x t/security-review-changeset.t && t/security-review-changeset.t`,
  then the full `t/` suite for regressions.

## Validation Criteria
- [ ] All reconciled + new subtests pass; full `t/` suite green.
- [ ] TC-WIDEN1 proves a non-script consumer file is reviewed **and** counted.
- [ ] TC-GUARD1 (mandatory) passes with falsifiable symlink/FIFO observables.
- [ ] No subtest still asserts a non-CWF / non-script file is *excluded*.
- [ ] Empty-diff path still yields exit 0 / `reviewed 0 files` (covered by the
      unchanged empty-changeset behaviour; add a bare-no-changes assertion if not
      already implied by an existing subtest).
- [ ] `cwf-manage validate` reports no *new* violations after the hash refresh.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned subtests executed and passed (see g-testing-exec.md). The plan's D5
reconciliation map and the mandatory TC-GUARD1 / TC-WIDEN1 / empty-diff cases were
all implemented; TC-EMPTY1 added an explicit bare-no-changes assertion (the plan had
left this as "add if not already implied"). Two unplanned test files were reconciled
and TC-CAP9 was added for the deprecated config key. Final: 25 subtests in
`t/security-review-changeset.t`; full suite Files=54, Tests=643, all green.

## Lessons Learned
The plan's coverage targets were sound; the gap was scope, not strategy — the test
plan inherited the implementation plan's single-file assumption about where the
deleted symbol was referenced. See j-retrospective.md.
