# subtask retrospective must not version-bump or tag - Testing Execution
**Task**: 163 (bugfix)

## Task Reference
- **Task ID**: internal-163
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/163-subtask-retrospective-must-not-version-bump-or-tag
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Test Results

### Targeted run (the four touched files)
`prove -l t/versioning.t t/cwf-version-bump.t t/cwf-version-tag.t t/cwf-version-next.t` → **45 tests, PASS**.

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-U1/U2 (`TC-V7c`) | `is_subtask_num` truth table (9 rows) | true for dotted, false for integer/malformed/undef | as expected | PASS |
| TC-1 (bump/tag/next) | `--task-num=3.2` → clean skip | exit 0, `skipped:` line, no write/tag/print | as expected | PASS |
| TC-2 (bump/tag/next) | `--task-num=3.2` with absent/malformed config | exit 0 + skip line (short-circuit before read_config) | as expected | PASS |
| TC-3 (bump/tag/next) | `--task-num=3.`/`.2`/`3..2` | exit 1 `unknown argument` | as expected | PASS |
| TC-4 (regression) | existing integer subtests | unchanged | all pass | PASS |
| TC-5 (tag) | `--task-num=3.2 --message=foo`, both orders | exit 0 + skip line | as expected | PASS |
| TC-6 (integrity) | `cwf-manage validate` for the 4 hashed files | clean | clean | PASS |

### Full suite
`prove -l t/` → **51 files, 585 tests; 583 PASS, 2 FAIL**.

## Test Failures

`t/cwf-manage-fix-security.t` — TC-1 ("reports zero repairs") and TC-8 (".../cwf-security-reviewer-changeset.md perms satisfy recorded floor 0444").

**Root cause — pre-existing, unrelated to Task 163.** The working-tree file
`.claude/agents/cwf-security-reviewer-changeset.md` is `0600` (rw-------), below the
recorded `0444` floor. Evidence it is not a Task 163 regression:
- Last committed by Task 162 (`53926d0`, the branch baseline); `git diff --name-only main..HEAD` does not list it — Task 163 never touches it.
- Committed git mode is `100644`, identical to its passing sibling `cwf-plan-reviewer-improvements.md`; the difference is **working-tree perms only** (sibling on disk is `0444`, this one drifted to `0600`, timestamped today).
- `cwf-manage validate` flagged this same drift at **every** checkpoint commit from the a-phase onward, before any code change.
- A fresh checkout would not carry the drift.

The 2 failures reproduce identically on the baseline commit with the same local drift.
Out of scope for this version-helper bugfix; surfaced to the maintainer. Remedy is a
one-line `chmod 0444 .claude/agents/cwf-security-reviewer-changeset.md` (or
`.cwf/scripts/cwf-manage fix-security`), tracked separately.

## Coverage Report
All e-testing-plan validation criteria met (TC-U1/U2, TC-1..TC-6). New behaviour and the
predicate contract are covered at both unit (predicate truth table) and integration
(real-script subprocess) levels; integer/regression paths unchanged.

## Security Review

**State**: error

The deterministic classifier (`security-review-classify`) returned `error` because the
testing-phase subagent response omitted the required `cwf-review` verdict block — a
verdict-format issue, not a detected defect. The reviewer's prose verdict was "no
findings": it confirmed the test additions use only hardcoded literal args through the
pre-existing `run_script` backtick harness (no attacker data), tempdir/chdir hygiene is
standard, and the production short-circuit narrows (not widens) what reaches `tag_at`, so
the digits-only invariant feeding `git tag` (Versioning.pm:165) is preserved.

Note: the implementation-phase review (f-implementation-exec.md) also classified `error`
for the same missing-block reason. The agent's verdict-block omission is consistent within
this session and may be a session-cached agent definition rather than a live defect;
re-test in a fresh session before treating it as a bug. Surfaced for user decision per the
exec-skill contract (do not block on the review result).

Verbatim subagent output:

```
I have everything I need. Let me confirm my analysis of the key security-relevant points:

1. **`tag_at` digits-only invariant (Versioning.pm:159-188)**: `tag_at` receives `$version`, which is composed via `next_version` from `major_minor + task_num`. The `task_num` is `$n + 0` (numeric coercion) in the helper, and the helper only reaches the tag path for bare integers (`is_subtask_num` short-circuits any dotted value with `exit 0`, and the capture regex rejects malformed values like `3.`/`.2`/`3..2`). So `$version` feeding `git tag -l '$version'` (line 177, interpolated into a shell backtick) remains `v{major}.{minor}.{integer}`. The production diff does not widen what reaches `tag_at` — dotted subtask numbers exit before any `next_version`/`tag_at` call. The digits-only invariant is preserved. Note line 177 uses single-quote shell interpolation of `$version`, but `$version` is regex-validated upstream; the diff does not change that, and the `is_subtask_num` short-circuit narrows rather than widens the input. Line 187 correctly uses list-form `system()` for the actual tag creation.

2. **Test harness shell construction (`run_script`)**: All three `.t` files build `my $cmd = join(' ', $SCRIPT, @args) . ' 2>&1'` and run it via backticks. The `@args` are hardcoded test literals (`--task-num=3.2`, `--task-num=3.`, `--message=foo`, etc.) — no attacker-controlled or external data flows into them. This is a pre-existing pattern and the new subtests follow it identically with literal args. The values `3.`, `.2`, `3..2` contain no shell metacharacters.

3. **Tempdir / chdir hygiene**: Tests use `tempdir(CLEANUP => 1)` and `chdir $orig_cwd` after each subtest — standard, no symlink-following writes to predictable paths.

4. **`is_subtask_num` is shape classification, not sanitisation**: The comment explicitly documents the input contract (already-numeric task id, not arbitrary user text). The anchored pattern `^\d+(?:\.\d+)+$` is correct and the truth table in TC-V7c locks the contract.

No security concerns in the test additions, and the production diff preserves the digits-only invariant feeding `git tag`.

no findings
Test additions use only hardcoded literal args (no attacker data) through the pre-existing `run_script` backtick harness; the production short-circuit narrows rather than widens what reaches `tag_at` (Versioning.pm:159-188), so the digits-only invariant feeding `git tag` (line 177) is preserved.
```

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None — 2 full-suite failures are pre-existing local perms drift, not Task 163 regressions (see Test Failures)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Distinguishing a pre-existing environmental failure (the Task 162 perms drift) from a task regression required checking `git diff main..HEAD` and the committed git mode, not just the failing test names. The two `error` security classifications (here and in f) both stemmed from a missing `cwf-review` block on otherwise-clean reviews — corroborating the open Task 162 follow-up. See `j-retrospective.md`.
