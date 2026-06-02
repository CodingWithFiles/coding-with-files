# review all changed files not just cwf-internal - Implementation Execution
**Task**: 174 (bugfix)

## Task Reference
- **Task ID**: internal-174
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/174-review-all-changed-files-not-just-cwf-internal
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status

## Actual Results

### Step 1: Code — delete the classifier (D1)
- **Actual**: Re-confirmed line numbers, then deleted `@CWF_INTERNAL_PREFIXES`, `%CWF_INTERNAL_FILES`, `$SCRIPT_INTERPRETER_RE`, `is_cwf_internal`, `looks_like_script`, and the classification loop. Loop replaced with `my @included = @changed;`. Grep confirms zero remaining references to the five symbols. Empty-`@included` invariant verified by reading the final code: `@included` derives solely from `list_changed_files` (length-filtered), the line-151 guard fires before the line-156 `git diff … -- @included`. Net −78 lines.
- **Deviations**: none.

### Step 2: Code comments + header sweep (D3.1)
- **Actual**: Header line 6 reworded; the "File classification" block replaced with a "Changeset scope" block; the Output line de-"filtered"; the "Emit filtered diff" inline comment fixed to "Emit the full diff". Deleted-code comment banners removed with their code.
- **Deviations**: none.

### Step 3: Doc sweep — security-review.md (D3.2)
- **Actual**: § "Pathspec coverage" → "Changeset coverage"; three classification rules replaced with a review-every-file paragraph; the **Maintainer note** (referencing the deleted prefix list) removed; the four CWF-internal "Known limitations" bullets removed, leaving the mid-task-rebase paragraph under a singular "Known limitation" heading; line-26 reword; line-137 and the cap-note "over the included files" → "over all changed files"; verdict-classifier section at ~167 left untouched.
- **Deviations**: none.

### Step 4: Doc sweep — exec SKILLs + agent (D3.3, D3.4)
- **Actual**: Both exec SKILLs' Step 8 prose updated (classification phrase → "emits the full diff over all changed files"; both § references → "Changeset coverage"); agent file line 16 § reference updated. Scoped residual grep clean: zero `CWF-internal`/`Pathspec coverage`/`what counts as security-relevant`; the only surviving `#!`/`shebang` hits are the helper's own shebang and a Perl-convention example in a threat-category (both legitimate).
- **Deviations**: none.

### Step 5: Tests (D5) — and a discovered cross-file gap
- **Actual**: Reconciled `t/security-review-changeset.t` per the D5 map (TC-F5/F6 inverted to assert inclusion; TC-NF5 noise assertion inverted; TC-NF3/NF4 replaced by TC-GUARD1a/b; TC-F1/F2/F4/CAP2 re-justified). Per user feedback mid-exec, also purged every "shebang" mention that implied a now-defunct distinction (the term only survives as fixture header-line content). Added TC-WIDEN1, TC-CAP8, TC-EMPTY1. Reworked `make_cap_repo` to branch-from-main with no recorded baseline so the helper anchors on merge-base and cap counts measure only each test's own files (no a-task-plan.md noise).
- **Deviation (significant)**: The d-plan / e-plan test reconciliation was scoped to `t/security-review-changeset.t` only. Exec revealed **two other test files** asserting on the deleted `@CWF_INTERNAL_PREFIXES`: `t/cwf-check-tree-symlinks.t` TC-7 part (b) (prefix-coverage check) and `t/install-bash-reinstall.t` TC-7 (doc↔helper prefix-list sync). Both were reconciled: the symlink test's part (b) replaced with a note (the guard is now auto-reviewed because *all* files are), the install test's obsolete subtest removed with an explanatory comment + header-comment fix. A repo-wide grep confirms no other live (non-`t/`, non-`implementation-guide/`, non-`CHANGELOG`) references to the deleted symbols remain. **Root cause of the miss**: the plan-review subagents and I treated "the test" as the single co-located test file; cross-file coupling to an internal symbol was not searched for at plan time. (Lesson for retrospective.)

### Step 6: Hash refresh + validate (D4)
- **Actual**: Pre-refresh per-file verification: for both hash-tracked files (helper, `cwf-security-reviewer-changeset.md`) the committed HEAD blob still matched the recorded sha, confirming the only change being blessed is this task's edit; git history showed only known prior task commits. Refreshed both `sha256` entries in `script-hashes.json`; restored helper to recorded `0500` and agent file to `0444`. `cwf-manage validate` → **OK**.
- **Deviations**: none.

### Step 7 (user-directed, mid-exec): rename `test-paths` → `max-lines-exclude-paths`
- **Why**: the first Step 8 run hit the cap at **706 production lines > 500** —
  exit 2, recorded `error`, subagent NOT invoked, and (per "surface, never
  smooth" + the prior-session lesson) **no hand-built smaller changeset**. The
  706 was dominated by this task's own wf step docs counting as production
  (design Risk 1 on its own diff). The user chose to add `implementation-guide/**`
  to the cap-discount set — which exposed that the key name `test-paths` was now
  a misnomer (it excludes non-test paths too). User directed an in-task rename to
  `max-lines-exclude-paths`.
- **Actual**: Renamed `security.review.test-paths` → `security.review.max-lines-exclude-paths`
  across the helper (sub `test_path_excludes` → `max_lines_exclude_paths`, call
  site, 4 header comments, usage text), `security-review.md` (3 mentions + a
  deprecation note), both exec SKILLs, and this repo's `cwf-project.json` (which
  now lists `t/**` + `implementation-guide/**`). **Backward-compat**: the helper
  reads the new key, falls back to the legacy `test-paths` with a stderr
  deprecation warning (helper 379–383) — no adopter breaks on upgrade. Per the
  user's upgrade-support decision, both exec SKILLs now **surface any helper
  `warning:` line regardless of exit code** so the deprecation nudge reaches
  users during normal runs. New `t/security-review-changeset.t` TC-CAP9 asserts
  the legacy key still discounts + warns. The key is not scaffolded anywhere, so
  new users only ever see the new name.
- **Deviations**: this whole rename is scope beyond the approved a/c/d/e plan —
  a user-directed addition during exec. Documented here; the committed plan docs
  (a/c/d/e) still describe the original `test-paths`-based design and were left
  as the historical record.

## Test Results
- `t/security-review-changeset.t`: 25/25 subtests pass (24 + new TC-CAP9).
- Full `t/` suite: **All tests successful. Files=54, Tests=643.**
- `cwf-manage validate`: **OK** (after the pre-existing perm drift was clamped — see Blockers).

## Blockers Encountered

### Pre-existing permission drift (NOT task 174; diagnosed and worked around)
Three files — `.cwf/scripts/command-helpers/context-manager.d/location`,
`.cwf/scripts/migrations/migrate-v2.1-file-order`,
`.cwf/scripts/command-helpers/template-copier-v2.0` — sat at working-tree perm
`0700` against their recorded `0500` ceiling. All three were **content-modified
in Task 173** (`c886856`, this task's baseline; verified via `git show --stat`),
whose stated goal was worktree-safe repo-root resolution — but it skipped the
standing obligation to `chmod` edited `0500` scripts back to `0500`. git stores
only mode `100755`, so the distinction was lost at commit and `validate` flags
the live `0700`. Pre-existing to task 174; produced 12 of the initial full-suite
failures (`cwf-manage-fix-security.t`, `cwf-manage-update-end-to-end.t`).
Clamping the three to `0500` (what `fix-security` does; a working-tree-only
change git does not track, so it cannot enter task 174's diff) cleared those
failures. **Not folded into task 174 per the user's instruction; flagged for a
separate housekeeping task or a `cwf-manage fix-security` run.**

### Cross-file test reconciliation gap (in-scope; fixed)
The d/e plan scoped test reconciliation to `t/security-review-changeset.t` only.
Exec found `t/cwf-check-tree-symlinks.t` TC-7(b) and `t/install-bash-reinstall.t`
TC-7 also asserting on the deleted `@CWF_INTERNAL_PREFIXES`. Both reconciled
(symlink test's part (b) replaced with a note; install test's obsolete subtest
removed with explanation). Repo-wide grep confirms no other live references.

## Security Review

**State**: no findings

After the user-directed cap-config change, the helper was re-run on task 174's
final changeset: `reviewed 14 files, 1522 lines (208 production),
anchor=c886856, includes uncommitted` → **exit 0** (208 production < 500 cap;
the full 1522-line diff still emitted to the subagent — `implementation-guide/**`
and `t/**` discounted from the count only). The `cwf-security-reviewer-changeset`
subagent reviewed the changeset against FR4(a–e); `security-review-classify`
returned **`no findings`**. Verbatim output below.

<verbatim subagent output — see /tmp scratch; verdict block:>

```cwf-review
state: no findings
summary: Classifier removal strictly widens review coverage; cap/back-compat logic preserves all fail-safes (NUL reject, exit-1 on bad pattern, unconfigured=production); deprecated test-paths key affects cap count only, never review inclusion.
```

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (review-all-files; cap test-aware; docs swept; tests reconciled; hashes refreshed)
- [x] All design guidance in c-design-plan.md followed (D1–D5)
- [x] No planned work deferred without surfacing
- [x] Cross-file test gap (2 files) reconciled in-task, not deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None. All code/doc/test work complete; full suite green (643 tests); `validate: OK`; Step 8 security review returned `no findings`.

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
"Surface, never smooth" held under pressure: when the cap fired at 706 > 500 on this
task's own changeset, exec recorded `error` and did not hand-build a smaller changeset
(the prior-session anti-pattern) — it was resolved by a legitimate config change. The
cross-file `@CWF_INTERNAL_PREFIXES` coupling and the Task-173 perm drift both consumed
diagnosis time that a plan-time symbol-deletion sweep / clean baseline would have saved.
See j-retrospective.md.
