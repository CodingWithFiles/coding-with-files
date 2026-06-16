# Simplify best-practice review to doc pointers - Testing Execution
**Task**: 207 (chore)

## Task Reference
- **Task ID**: internal-207
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/207-simplify-best-practice-review-to-pointers
- **Template Version**: 2.1

## Goal
Execute the test plan in e-testing-plan.md and record results.

## Test Results

### Unit/integration — `prove t/best-practice-resolve.t`
**PASS** — 13 subtests, all green (suite rewritten for the revised verbatim-path
contract; see f-implementation-exec.md § Revision). The resolver now emits the
`documentation` path verbatim, so the suite asserts verbatim emission rather than
any DOCS/SKIPPED catalog:

| Subtest             | What it proves |
|---------------------|----------------|
| TC-verbatim         | matched entries emitted as `- <tags>: <path>`, file + absolute dir paths verbatim |
| TC-no-checks        | nonexistent + outside-repo paths emitted verbatim (no existence check, no confinement) |
| TC-multitag         | an entry lists all its tags on one line |
| TC-schema-invalid   | missing-doc / empty-tags entries skipped with naming diagnostic; valid loads |
| TC-failopen-broken  | unparseable config → 0 entries + diagnostic, exit 0 |
| TC-precedence       | project wins on `documentation` collision; active-tags unioned |
| TC-failopen-absent  | absent config → exit 0, 0 matches, `.out` still written |
| TC-tags-casefold    | casefold exact-token match; no substring |
| TC-tags-empty       | empty T → 0 matches |
| TC-tags-union       | T = active-tags ∪ per-task `**Tags**` |
| TC-argvalidation    | task-num / phase / unknown-arg guards → exit 1, no confirmation |
| TC-branch-signal    | count is the 0 vs ≥1 branch signal |
| TC-classifier       | exec verdict reuses `security-review-classify` |

**Deviation note**: the test plan (e) was written against the earlier path-list
design (DOCS/SKIPPED, confinement, dir-walk). The maintainer directed a further
simplification to verbatim path emission during exec review, so those cases
(confinement, dedup, empty-dir, URL-degrade) were dropped and replaced by
verbatim-emission cases. Full rationale in f-implementation-exec.md § Revision.

### Regression — `prove t/`
**PASS** — 866 tests / 72 files, all successful. No regressions; `skill-anchor-drift.t`
green (it guards the exec SKILL bodies edited here).

### Output-level smoke test
**PASS** (re-run after the revision). The resolver against a config with a
project file (`CHANGELOG.md`) and an absolute `~/analysis`-style dir produced
exactly:
```
# Best-practice sources for task 207 (applicable tags: smoke)
- smoke: CHANGELOG.md
- smoke, go: /home/matt/analysis/golang-best-practice
```
Paths verbatim, no catalog. Absence sweep over the feature files for
`allow-url-fetch|url-allow-hosts|make_sentinel|### URLS|### SOURCE|### DOCS|### SKIPPED|WebFetch|max-bytes|max-files|sentinel|confined|realpath`
is clean (sole hit: the intentional "Paths are not confined" Limitations note).

### Static absence sweep
**PASS** — `git grep -nE 'allow-url-fetch|url-allow-hosts|make_sentinel|### URLS|WebFetch'`
over `.cwf` + `.claude` (excluding `implementation-guide/`, `CHANGELOG.md`) is
clean (the remaining `manifest`/`sentinel` hits are unrelated install-/integrity-
manifest and CLAUDE.md-sentinel machinery).

### Integrity
**PASS** — `cwf-manage validate: OK` after the same-commit hash refresh for the
three changed tracked files (resolver + both agent defs).

## Validation Criteria (from e-testing-plan.md)
- [x] `prove t/best-practice-resolve.t` green on the rewritten suite.
- [x] `prove t/` green (no regressions; skill-anchor-drift passes).
- [x] Smoke `.out` shows the path list and contains no `sentinel`, `### URLS`,
      `[TRUNCATED]`, or `### SOURCE`.
- [x] `git grep` for the removed surface is clean.
- [x] `cwf-manage validate` ⇒ OK.

## Test Failures
None.

## Security Review

**State**: findings (advisory — carried forward from the revised exec review)

The revised production code (verbatim-path resolver + agents) was reviewed at
implementation-exec on the full changeset (cap surfaced). For testing-exec the
production content is byte-identical (only the non-production `g-testing-exec.md`
doc differs), so the verdict is carried forward: one **advisory** category-(e)
pattern-risk — project-path confinement was deliberately removed; safe for this
read-only advisory feature because the reviewer agents are read-only, with audit
guidance to restore confinement if any future consumer gains a write/exec/network
sink. No blocking defect. Full text in f-implementation-exec.md § Revision.

## Best-Practice Review

**State**: no findings

`best-practice-resolve --task-num=207 --phase=testing-exec` reported 0 matched
entries (no `.cwf/best-practices.json` in this repo). No agent launched —
`no findings: no applicable best practices`.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- Asserting verbatim path emission (`^- <tags>: <path>$` against the `.out`) is
  simpler and more robust than the earlier content/path-presence assertions —
  once the helper stopped transforming the path, the tests stopped needing to
  account for realpath/platform differences.
- "Simpler" had two iterations: removing inlining/URLs/sentinel, then removing
  existence-check/confinement/dedup/catalog entirely. The second cut came from
  exec review — worth reaching for the barest version earlier.
