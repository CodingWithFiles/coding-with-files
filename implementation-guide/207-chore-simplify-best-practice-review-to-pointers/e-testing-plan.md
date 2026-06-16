# Simplify best-practice review to doc pointers - Testing Plan
**Task**: 207 (chore)

## Task Reference
- **Task ID**: internal-207
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/207-simplify-best-practice-review-to-pointers
- **Template Version**: 2.1

## Goal
Prove the slimmed resolver emits the right tag-matched **path list**, keeps the
project-path confinement guarantee, degrades gracefully on the removed surface,
and that nothing of the old URL/manifest machinery survives anywhere in the tree.

## Test Strategy
### Test Levels
- **Unit/integration**: `t/best-practice-resolve.t` — synthetic repo + isolated
  `$HOME`, run the helper as a subprocess, assert on its stdout count line, the
  `.out` path-list payload, stderr diagnostics, and exit code (existing harness;
  rewritten for the new contract).
- **Regression**: the full `prove t/` suite must stay green (esp.
  `skill-anchor-drift.t`, which guards the exec SKILL bodies edited here).
- **Output-level smoke**: run the real helper against a hand-built config and
  grep the `.out` for the path list and for **absence** of removed markers.
- **Static absence sweep**: repo grep confirming no orphaned references to the
  removed surface outside immutable task-205 history.

### Coverage Targets
- Every retained resolver behaviour (config merge, tag union, precedence,
  confinement, dedup, fail-open) has a passing TC.
- 100% of the removed surface is covered by a negative assertion (URL entry,
  no sentinel, no `### URLS`, no `[TRUNCATED]`).

## Test Cases
### Functional (in `t/best-practice-resolve.t`)
- **TC-pathlist** (new): file + dir pointers resolve to a path list.
  - **Given**: a project config with a file entry and a dir entry, both tag-matched.
  - **When**: the helper runs for the task.
  - **Then**: the `.out` lists the resolved **file path** and the **dir path**
    (the dir as-is, not its members); count line = 2; no `### SOURCE`/sentinel.
- **TC-tags** (adapt TC-6/7/8): casefold exact-token match; no substring; empty
  T ⇒ 0 matches; T = `active-tags` ∪ per-task `**Tags**`.
- **TC-precedence** (adapt TC-4): project entry wins on `documentation`
  collision; `active-tags` unioned.
- **TC-failopen-broken** (adapt TC-3): unparseable config ⇒ 0 entries + stderr
  diagnostic, exit 0.
- **TC-failopen-absent** (adapt TC-5): neither config present ⇒ exit 0, count 0,
  and a `.out` **is still written** (header assertion re-pointed off content).
- **TC-dedup** (adapt TC-11): two entries with the same realpath ⇒ path emitted
  once.
- **TC-confine-file** (adapt TC-12): a project file/dir pointer realpath-escaping
  the git root ⇒ rejected, lands in `### SKIPPED`, not in the path list.
- **TC-confine-dir** (new): a project **dir** pointer resolving outside the root
  (e.g. `../../etc`) ⇒ rejected (guards the dropped per-member walk).
- **TC-url-degrades** (new): a `https://…` entry (stale config) ⇒ treated as a
  relative path → "missing or unreadable" → `### SKIPPED`; exit 0, not error.
- **TC-emptydir** (adapt TC-10): an empty/missing dir pointer ⇒ SKIPPED note,
  not a silent vanish.
- **TC-user-trusted**: a user-config pointer outside the repo is **not** rejected
  (user paths stay trusted) — retained from the existing user-path TC.

### Removed (delete these TCs)
- TC-1 URL leg + `allow-url-fetch`/`url-allow-hosts` host-allowlist cases.
- Inlining/sentinel/`### URLS`/byte-cap (`--max-bytes`)/`--max-files` member-cap
  TCs, and dir-member **content** assertions (`FILE_BODY`, `DIR_MEMBER`).

### Non-Functional / cross-cutting
- **Security**: TC-confine-file + TC-confine-dir prove the retained confinement;
  the residual symlink-escape-within-a-confined-dir risk is documented (not
  tested — it is an accepted, advisory-only residual).
- **Integrity**: `cwf-manage validate` ⇒ OK after the same-commit hash refresh
  for the 3 changed tracked files.
- **Reliability**: fail-open TCs prove a broken/absent config never reads clean
  and never aborts.

## Test Environment
- POSIX + system Perl, core modules only (per project constraint); no network.
- `prove t/best-practice-resolve.t` for the unit suite; `prove t/` for full
  regression. Synthetic repos/configs built in tempdirs by the existing harness.

## Validation Criteria
- [ ] `prove t/best-practice-resolve.t` green on the rewritten suite.
- [ ] `prove t/` green (no regressions; skill-anchor-drift passes).
- [ ] Smoke `.out` shows the path list and contains no `sentinel`, `### URLS`,
      `[TRUNCATED]`, or `### SOURCE`.
- [ ] `git grep -nE 'allow-url-fetch|url-allow-hosts|make_sentinel|### URLS|WebFetch'`
      over `.cwf` + `.claude` (excluding `implementation-guide/`) is clean.
- [ ] `cwf-manage validate` ⇒ OK.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
