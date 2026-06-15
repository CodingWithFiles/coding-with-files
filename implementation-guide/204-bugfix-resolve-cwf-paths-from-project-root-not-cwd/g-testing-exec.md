# Resolve .cwf paths from project root, not cwd - Testing Execution
**Task**: 204 (bugfix)

## Task Reference
- **Task ID**: internal-204
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/204-resolve-cwf-paths-from-project-root-not-cwd
- **Template Version**: 2.1

## Goal
Execute the tests in e-testing-plan.md against the implementation.

## Test Results

### Automated (Perl `prove t/`)
`prove t/` → **860 tests, all PASS** across **69 .t files** (67 prior + 2 new).
`cwf-manage validate` → **OK** (only the `cwf-claude-settings-merge` hash changed,
refreshed in-commit).

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1  | anchor at root = no-op | cwd unchanged | cwd unchanged | PASS |
| TC-2  | subdir: bare call fails, anchor-then-call succeeds | 127 then ok | exit 127 then `probe-ran` | PASS |
| TC-3  | from linked worktree → MAIN root | main root | main root | PASS |
| TC-4  | outside repo = tolerant no-op | cwd unchanged | cwd unchanged | PASS |
| TC-5a | byte-identical anchor across SKILL.md | exactly 1 each | 20 skills, 1 each | PASS |
| TC-5b | anchor before first action (coverage) | present+before | all referencing skills | PASS |
| TC-10 | allowlist smoke (dry-run) | relative entries unchanged | `0` allow added, relative | PASS |
| TC-11 | integrity | validate OK; only generator hash | validate OK; 1 hash | PASS |
| TC-13 | hook commands carry literal prefix | non-empty `${CLAUDE_PROJECT_DIR}/` | all prefixed | PASS |
| TC-14 | gate-independent prune, no dups, count | all 6 + legacy, no dup | re-linked, 1 copy | PASS |
| TC-15 | ownership-scoped prune (no substring) | user hook kept | kept | PASS |
| TC-16 | fail-open closed (off-cwd exec) | prefixed runs, relative 127 | runs / 127 | PASS |
| TC-17 | hook allowlist stays relative | relative | relative | PASS |

(TC-1–4 in `t/skill-root-anchor.t`; TC-5a/b in `t/skill-anchor-drift.t`; TC-13–17
in `t/cwf-claude-settings-merge.t`; existing settings-merge assertions updated for
the prefixed form, TC-U3 reworked for re-linking.)

### In-session / manual (Phase-0 spike — recorded in f-implementation-exec.md)
| Test ID | Test Case | Result |
|---------|-----------|--------|
| TC-6 (P0.1) | no new permission prompt at root | PASS (no-redundant-cd never matches the guarded `cd "$r"`) |
| TC-7 (P0.3) | passes `pretooluse-bash-tool-check` | PASS (hook does not block the anchor) |
| TC-8 (P0.4/A1) | Read/Edit `.cwf/docs/...` resolution off-root | A1 corrected: resolves against shell cwd → the anchor fixes it too (relative Read succeeds post-anchor) |
| TC-9 (P0.5) | cwd persists across Bash calls | PASS |

### Non-Functional / Security
- **TC-12 (injection / FR4)**: `cwf-security-reviewer-changeset` over the 33-file
  changeset → **no findings** (verdict classified by `security-review-classify`).
  Recorded in f-implementation-exec.md § Security Review.

## Test Failures
None. (During this phase the full suite initially flagged 1 failure — the
workflow-status validator — because f-implementation-exec.md carried the invalid
status `Implemented`; corrected to `Finished` and folded into the f checkpoint.
Re-run: all green.)

## Coverage Report
Critical-path (anchor: at-root/subdir/worktree/outside; hooks: prefix/prune/
fail-open-closed) at 100% per e-testing-plan targets. No line-coverage % target
(shell-idiom-in-markdown + generator edit + tests).

## Security Review

**State**: no findings

`cwf-security-reviewer-changeset` over the testing-exec changeset (33 files, 276
production lines) → **no findings** (classified by `security-review-classify`).
Focal point (d): confirmed `${CLAUDE_PROJECT_DIR}/` is emitted as a compile-time
literal (`$` backslash-escaped; rules-inject single-quoted), never `$ENV{...}` at
generate-time — FR4(e) constant-command invariant preserved, with TC-13 defending
the interpolate-to-empty regression and TC-15 the ownership-scoped prune. Pattern
notes (anchored-full-string prune; test `system()` interpolating fixture paths)
are mitigated/test-only. Full output in the scratch dir
(`security-review-output-testing-exec.out`).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
The full-suite run caught an invalid status (`Implemented` in f) via the
workflow-status validator before sign-off — the validator is doing its job as a gate.
Output-level verification of the generator (dry-run + real-run) confirmed the
prefix/prune/no-duplicate behaviour that source-grepping alone could not.
