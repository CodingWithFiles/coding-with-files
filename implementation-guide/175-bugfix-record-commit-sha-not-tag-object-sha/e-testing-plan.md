# record commit sha not tag-object sha - Testing Plan
**Task**: 175 (bugfix)

## Task Reference
- **Task ID**: internal-175
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/175-record-commit-sha-not-tag-object-sha
- **Template Version**: 2.1

## Goal
Prove an annotated-tag install/update records the tag's **commit** SHA (not the tag-object SHA), with no regression to other ref forms.

## Test Strategy
### Test Levels
- **End-to-end (primary)**: `t/version-records-commit-sha.t` (new) drives the real `install.bash` and the installed `cwf-manage` against a file:// upstream — the same fixture-server *pattern* as `t/cwf-manage-update-end-to-end.t` / `t/install-bash-reinstall.t` (each `.t` is self-contained; helpers re-implemented per sibling-test convention, not imported).
- **Regression**: the named existing suites must pass unchanged.

### Critical insight (drives fixture design)
The shared `build_upstream` helper creates **lightweight** tags (`git tag v0.0.$i`), for which `rev-parse <tag>` already returns the commit — the bug cannot reproduce. The new test therefore creates its own **annotated** tag (`git tag -a`) on an upstream commit. `git rev-parse <annotated-tag>` (tag object) ≠ `git rev-parse <annotated-tag>^{commit}` (commit) is the discriminator every assertion turns on.

### Coverage targets
- **Critical path**: both SHA-resolution sites (install.bash:310, cwf-manage resolve_sha:225) covered by an annotated-tag case. 100%.
- **Regression**: lightweight-tag / branch / raw-SHA / HEAD paths.

## Test Cases
### Functional Test Cases
- **TC-1 — install.bash records the commit SHA for an annotated tag**
  - **Given**: an upstream repo with an **annotated** tag `vX` on commit `C` (where `rev-parse vX` ≠ `rev-parse vX^{commit}`)
  - **When**: a consumer runs `install.bash` with `CWF_REF=vX` (subtree method)
  - **Then**: `.cwf/version` has `cwf_sha=<rev-parse vX^{commit}>` (== `C`) and **NOT** `cwf_sha=<rev-parse vX>` (the tag object). Assert both with `like`/`unlike`, mirroring the `cwf-manage-update-end-to-end.t:334` idiom.

- **TC-2 — cwf-manage update to an annotated tag records the commit SHA**
  - **Given**: a consumer installed at an older tag; upstream has annotated tag `vY` on commit `D`
  - **When**: `cwf-manage update vY`
  - **Then**: rewritten `.cwf/version` has `cwf_sha=<rev-parse vY^{commit}>`, **not** the tag object; **and** `cwf_version=vY` (regression guard — `git_describe_version` still resolves the commit to the tag name).

- **TC-3 — copy method shares the fix (no duplicate case)**
  - `resolved_sha` is computed once in `install.bash:main()` **before** the method branch, so the copy path records the identical `cwf_sha` as subtree. **Not separately tested** — calling this out explicitly (no silent coverage cap): a copy-method case would exercise the same line 310 with no added signal.

- **TC-4 — no regression for non-annotated refs (peel is idempotent)**
  - `<ref>^{commit}` is a no-op for lightweight tags, branches, raw commit SHAs, and `HEAD`. These paths are already exercised by `build_upstream`-based assertions in the existing E2E suites; no new dedicated case is added. Stated explicitly so the absence is a decision, not a gap.

### Non-Functional Test Cases
- **Integrity (TC-5)**: after the `cwf-manage` edit + same-commit hash refresh, `cwf-manage validate` reports **no** `cwf-manage` violation. The two pre-existing unrelated drifts (`security-review-changeset` 0700/0500, `cwf-security-reviewer-changeset.md` 0600/0444) are out of scope and must be neither absorbed nor masked.
- **Security**: no new injection surface — the `^{commit}` suffix is appended to an already-`resolve_ref`-validated ref and passed list-form (Perl) / double-quoted single-arg (Bash). No assertion needed beyond the existing list-form invocation.

## Test Environment
### Setup Requirements
- Bash 4+ (test skips otherwise, per `install-bash-reinstall.t:42-44`), git, core Perl + `Test::More`.
- Deterministic git identity env vars (mirror `install-bash-reinstall.t:37-40`).
- `tempdir(CLEANUP => 1)` upstream + consumer repos; no writes to the real repo.

### Automation
- `prove t/version-records-commit-sha.t` (new).
- Regression: `prove t/install-bash-reinstall.t t/cwf-manage-update-end-to-end.t t/cwf-manage-update.t`.

## Validation Criteria
- [ ] New test **fails against current code** (red) before the fix, passes after (green)
- [ ] TC-1, TC-2, TC-5 pass
- [ ] Named regression suites pass unchanged
- [ ] `cwf-manage validate` clean for `cwf-manage` (pre-existing unrelated drifts excluded)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1, TC-2, TC-5 all PASS; TC-3/TC-4 correctly not separately cased. New test red→green; named regressions + full suite (645 tests) green. See `g-testing-exec.md` §Test Results.

## Lessons Learned
Run the full suite, not just the named regressions — only `prove t/` surfaced the unrelated TC-8 perm-floor failure. See `j-retrospective.md` §Process Learnings.
