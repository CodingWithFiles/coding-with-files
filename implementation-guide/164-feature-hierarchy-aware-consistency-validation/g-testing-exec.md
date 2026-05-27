# hierarchy-aware consistency validation - Testing Execution
**Task**: 164 (feature)

## Task Reference
- **Task ID**: internal-164
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/164-hierarchy-aware-consistency-validation
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready (Perl `prove`, core modules, git for Tier C)
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps (none)
- [x] Status set to Finished — all pass

## How to run
`prove t/validate-consistency.t` (or full suite `prove t/`). Tier-C branch cases auto-skip
when git is unavailable. All new fixtures are synthetic nested task trees in throwaway
`tempdir`s — the live `implementation-guide/` is never touched.

## Test Results

### Functional Tests
All cases from e-testing-plan.md mapped 1:1 to subtests in `t/validate-consistency.t`.
`t/validate-consistency.t` = **20 subtests PASS**; full suite **600 tests PASS** (was 585;
+15 new subtests). `cwf-manage validate` clean.

| Test ID | Maps to | Expected | Status | Tier |
|---------|---------|----------|--------|------|
| TC-R1 | missing implementation-guide -> empty | no violations | PASS | no-git |
| TC-R2 | matching **Task** num -> no task violation | no `**Task**` | PASS | git |
| TC-R3 | mismatched **Task** num -> violation | `**Task**` | PASS | git |
| TC-R4 | Finished task branch mismatch -> not flagged | no `**Branch**` | PASS | git |
| TC-R5 | flat active+finished, off-current-branch | exactly 1 `**Branch**` (set+order locked) | PASS | git |
| TC-1  | FR1 nested wrong **Task** | 1 `**Task**`, file in nested dir | PASS | no-git |
| TC-2  | FR2 ancestor satisfied-by-descendant | 0 `**Branch**` | PASS | git |
| TC-2b | FR2 grandparent (multi-level) ancestor | 0 `**Branch**` | PASS | git |
| TC-2c | FR2 numeric near-miss sibling (1.1 vs 1.10) | 1 `**Branch**` (1.1 only) | PASS | git |
| TC-3a | FR3 unrelated off-chain task | 1 `**Branch**` (task 2) | PASS | git |
| TC-3b | FR3 duplicate-branch fail-closed | 1 `**Branch**` (task 3), no crash | PASS | git |
| TC-4a | FR4 Finished parent + active child | 1 `**Status**`, names 1.1 | PASS | no-git |
| TC-4b | FR4 Cancelled parent (terminal) | 1 `**Status**` | PASS | no-git |
| TC-4c | FR4 inverse (terminal child/active parent) | 0 `**Status**` | PASS | no-git |
| TC-4d | FR4 missing-status child | 0 `**Status**` | PASS | no-git |
| TC-4e | FR4 complete leaf, no descendants | 0 `**Status**` | PASS | no-git |
| TC-4f | FR4 nearest-descendant tiebreak | 1 `**Status**`, "active descendant 1.1" | PASS | no-git |

### Non-Functional Tests
| Test ID | Concern | Result |
|---------|---------|--------|
| TC-S1 | NFR4 symlinked subtask dir not followed (`-l` before `-d`) | PASS — no violation references the external target |
| TC-W  | NFR5 no warnings; ancestry walk reaches `get_parent`->undef | PASS — 0 warnings under `$SIG{__WARN__}` trap |
| NFR1  | performance | single recursive pass; no dedicated perf test (advisory tool, tree bounded by dir count) |
| Security | no new shell/env surface | confirmed by Step 8 changeset review below |

**Test-design notes (deviations from e-testing-plan, all tightenings):**
- The plan grouped most cases under one big git `SKIP` block. In execution, FR1, all FR4
  completeness cases, TC-S1 and TC-W were made **git-independent**: they run against a plain
  `tempdir` (so `_current_branch` returns undef -> branch pass is skipped) and assert only on
  the `**Task**`/`**Status**`/file-path field of interest. This runs more coverage in minimal
  environments and matches the plan's stated intent ("branch-dependent cases skip cleanly when
  git is unavailable"). Only the directional branch cases (TC-2/2b/2c, TC-3a/3b, TC-R5) remain
  Tier-C git-gated, since they need a controlled current branch.
- TC-W exercises `_is_ancestor` (and thus `get_parent` reaching undef) via the **completeness**
  pass rather than the branch pass, so it needs no git while still proving the warning-free path;
  a second assertion confirms the completeness pass actually ran.

## Test Failures
None. (The only transient failures during implementation — two `cwf-manage` integrity tests —
were the expected hash-drift signal, resolved by the in-commit `script-hashes.json` refresh
recorded in f-implementation-exec.md.)

## Coverage Report
Every FR (FR1–FR5) and the two security/reliability NFRs (NFR4 symlink, NFR5 no-warnings) have
at least one asserting case; the branch and completeness decision points are each covered at all
polarities (leaf found/absent/ambiguous; ancestor/sibling/unrelated; complete-with-active-
descendant / inverse / missing-status / no-descendant; nearest-descendant tiebreak). AC1–AC5 all
satisfied (see Validation Criteria in e-testing-plan.md).

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See Test Results above. 20/20 in `t/validate-consistency.t`; full suite 600/600; both
exec-phase security reviews `no findings`.

## Lessons Learned
Asserting on a single violation field (`**Task**`/`**Status**`/`**Branch**`) lets
completeness and FR1 cases run git-free without branch-noise interference.

## Security Review

**State**: no findings

This confirms the node-gate is robust. `parse_dirname` only matches directory names of the form `<digits[.digits]*>-<word>-<rest>` and returns the numeric portion via a constrained regex (`\d+(?:\.\d+)*`). So `$num` fed into `_is_ancestor`/`get_parent` is always a well-formed dotted-decimal string — there's no way for a crafted directory name to inject anything other than digits-and-dots into the version arithmetic. `get_parent` uses exact-equality string comparison (`eq`), and the diff's comment correctly notes this structurally rejects numeric near-misses (1 vs 11, 1.1 vs 1.10), which TC-2c verifies.

I now have everything I need. Let me summarise the review.

## Security review — testing phase

**Files in scope:**
- `.cwf/lib/CWF/Validate/Consistency.pm` (CWF-internal `.cwf/lib/` — unconditional include)
- `t/validate-consistency.t` (Perl shebang — conditional include)

**(a) Bash injection / unsafe command construction.** The test's `set_branch` (line 44) uses single-string `system("git -C '$repo' checkout -q -b '$branch'")`, which invokes a shell. At every callsite `$branch` is a fixed test literal (`feature/1.1`, `feature/1.10`, `feature/shared`, `feature/1.1.1`, `feature/2`, `feature/other`) and `$repo` is a `File::Temp` path — no shell metacharacters, no single quotes that would break the surrounding `'...'` quoting. Safe at all current callsites. The other `system` call (`git --version >/dev/null 2>&1`) is a fixed literal. The production `_current_branch` backtick is pre-existing and unchanged by this diff.

**(b) Perl helpers consuming git/user output without `-z` / validation.** The new traversal (`_collect_nodes`, `_build_node`) uses `readdir`, not git porcelain, so `-z` newline-splitting hazards do not arise. The security-relevant addition is the symlink defence at `Consistency.pm:86` — `next if -l $full` is correctly placed BEFORE the `-d` test (which stat-follows symlinks), confining traversal to `implementation-guide/`. TC-S1 exercises this by symlinking an external dir into the tree and asserting no violation references the target. The node-gate `parse_dirname` (verified in `TaskPath.pm:305`) only matches `^(\d+(?:\.\d+)*)-(\w+)-(.+)$`, so the version string fed into `get_parent`/`version_compare` is always well-formed dotted-decimal — no injection surface into the ancestry arithmetic.

**(c) Prompt injection.** No LLM context, no `{arguments}` substitution. Violation `fix` strings are `cwf-manage validate` diagnostics, not model-interpreted instructions. Nothing to flag.

**(d) Unsafe env-var handling.** No env vars read or written; `$git_root`/`$repo` originate from function arguments and `File::Temp`. Nothing to flag.

**(e) Pattern-based risks (reported with required framing, not defects):**
1. `set_branch`'s single-string `system` form (test line 44) is **safe here because** every caller passes a fixed string literal for `$branch` and a `File::Temp` path for `$repo`; **audit future uses** where `$branch` becomes a fixture/data/env-sourced parameter or could contain a `'` or shell metacharacter — switch to list-form `system("git","-C",$repo,"checkout","-q","-b",$branch)` if that day comes.
2. `_build_node`'s `_violation` interpolation of the real directory name `$dir_name` into the fix message (`Consistency.pm:62`) is **safe here because** the string is only ever emitted as a validation diagnostic, never shelled or `eval`'d; **audit future uses** if any consumer starts routing violation `fix` text into a shell command or an LLM tool-selection path.

No actionable defects. The symlink-before-`-d` ordering and the regex-constrained node-gate are the right defensive choices, and the test suite covers them. The two category-(e) items are pattern observations, not concerns requiring a change in this diff — the diff's own summary note already acknowledges the test-literal invariant.

```cwf-review
state: no findings
summary: Test + library diff is clean; symlink-skip-before-stat and regex-gated version parsing are sound. Two category-(e) pattern observations (single-string set_branch system, diagnostic dir-name interpolation) are safe at all current callsites, no change needed.
```
