# security-review cap weights production over tests - Implementation Execution
**Task**: 168 (chore)

## Task Reference
- **Task ID**: internal-168
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/168-security-review-cap-weight-production-code
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status when complete

## Actual Results

### Step 1: Setup
- **Planned**: confirm branch / baseline `bcf37b4` / clean tree.
- **Actual**: on `chore/168-…`; baseline `bcf37b4` recorded in a-task-plan.md; tree clean apart from the untracked f/g/j stubs created by `/cwf-new-task`.

### Step 2: Helper — production-weighted count + cap
- **Planned**: `--max-lines=N` parse+validate; `sub test_path_excludes`; `sub count_production_lines`; `(P production)` in the summary; exit 2 on breach.
- **Actual**: implemented in `.cwf/scripts/command-helpers/security-review-changeset`:
  - `--max-lines=(.+)` added to the arg loop and to `%opt`; validated `/^[1-9]\d*$/` (rejects `0`, `007`, non-numeric) → exit 1.
  - `test_path_excludes()` — eval-guarded `read_config()`, reads `security.review.test-paths`, skips refs/empty/NUL entries, returns `map { ":(glob,exclude)$_" }`.
  - `count_production_lines($anchor,\@included,\@exclude)` — sums added+deleted from `git diff --numstat … -- @included @exclude`; binary `-` rows → 0; returns 0 for empty included list.
  - stderr summary extended to `reviewed N files, M lines (P production), anchor=…` (both the empty-changeset and the main path); `(P production)` sits between `M lines` and `anchor=` so the strict `t/…:559` anchor still matches via its `.+`.
  - exit 2 with `cap exceeded: P production lines > N` when `--max-lines` set and `P > N` (after stdout already printed).
  - header comment + `print_usage()` document `--max-lines` and the new exit code 2.
- **Deviations**: none.

### Step 3: SKILL wiring + self-config
- **Planned**: both exec SKILLs pass `--max-lines=500`, branch on exit code, drop `wc -l`; add `security.review.test-paths: ["t/**"]` to `cwf-project.json`.
- **Actual**: Step 8 rewritten in both `cwf-implementation-exec/SKILL.md` and `cwf-testing-exec/SKILL.md` — capture stdout + exit code + stderr; branch 0-empty / 0-nonempty / 2 (cap, error, skip subagent) / other-nonzero (construction failure, error, skip subagent). `wc -l` removed from both. `implementation-guide/cwf-project.json` gained `security.review.test-paths: ["t/**"]` (CWF dogfoods the field).
- **Deviations**: none.

### Step 4: Documentation
- **Planned**: cap subsection in `security-review.md`; helper header/usage.
- **Actual**: added "### Production-weighted review cap" under "Pathspec coverage" — count definition, `:(glob,exclude)` matching, exit 2 / exit 1 contract, fail-safe direction, cross-language coverage limitation, helper named as source of truth. Helper header/usage updated in Step 2.
- **Deviations**: none.

### Step 5: Tests + hash + validation
- **Planned**: TC-CAP1–7; refresh helper hash; restore 0700; `cwf-manage validate`; output-level smoke check.
- **Actual**:
  - Added `make_cap_repo` + TC-CAP1–7 to `t/security-review-changeset.t`. `prove -v` → **21/21 subtests pass** (14 pre-existing incl. the strict `:559` anchor + 7 new).
  - Refreshed `security-review-changeset` sha256 in `.cwf/security/script-hashes.json` to `064df660…`; working perms restored to 0700 (manifest minimum stays 0500).
  - `cwf-manage validate` → only the pre-existing `install-manifest.json` 0600-vs-0444 finding (standing backlog item, out of scope); the helper hash validates cleanly.
  - Output-level smoke: `security-review-changeset --phase=implementation --max-lines=500` on this task's own diff → `reviewed 6 files, 491 lines (149 production)`, rc=0. The 491 raw lines would have nearly tripped the old 500-raw cap; production-weighted it is 149 — the exact false-cap this task removes.
- **Deviations**: none.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] No b-requirements / c-design phases for a chore (N/A)
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 168
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

Now I have the full context. Let me reason through the threat categories.

**Category (a) — Bash/shell injection.** The new code paths add no shell. `capture_git` uses list-form `open(my $fh, '-|', 'git', @args)`, which bypasses the shell entirely; `git_check` uses `exec('git', @args)` list-form. The new `count_production_lines` routes through `capture_git` with `git`, `diff`, `--numstat`, `$anchor`, `--`, included paths, and the exclude pathspecs — all as discrete list args, no interpolation into a shell. The new `--max-lines` value is never passed to git; it's compared numerically in Perl only. No `system("...")` string form, no backticks, no `qx`, no `eval` of external data. Clean.

**Category (b) — git/input handling.**

1. `--max-lines` validation: `/^[1-9]\d*$/` rejects `0`, leading-zero forms (`007`), negatives, non-numeric, and embedded shell metacharacters. The value is only used in a Perl `>` comparison, never reaches git. The regex anchors both ends so no newline-injection slips through.

2. `test-paths` values flow from `cwf-project.json` into git pathspec args. The defensive filtering in `test_path_excludes` skips refs, undef/empty strings, and any value containing a NUL byte. Each surviving value is prefixed with the literal `:(glob,exclude)` magic and passed as a single list arg. Because it's list-form, a value like `../escape` or `; rm -rf /` cannot break out into a shell — at worst git itself rejects it. TC-CAP7 confirms `../escape` makes git fatal, and `capture_git` treats git's non-zero exit as a hard `exit 1` rather than a silent empty result. Correct fail-safe: a config the consumer can't make git accept yields an error, never a silent discount that would shrink the production count and let an over-cap diff slip through unreviewed.

3. numstat parsing: only the first two tab-separated columns are read, and only after confirming both are `/^\d+$/` (or `-` for binary → 0). The path column is never parsed, so git's path-quoting / rename arrow / C-quoting cannot misclassify. Binary files contribute 0 (TC-CAP6). Malformed/blank lines skipped via `defined` guards.

4. The anchor passed to `count_production_lines` is the same validated 40-hex SHA / merge-base SHA used everywhere else, so no new injection surface.

**Category (c) — prompt injection.** The full diff is emitted to stdout and handed to the subagent verbatim, exactly as before — the cap mechanism does not alter what reaches the subagent, only whether the SKILL invokes it. The cap is computed from numstat integers, not diff body text, so no attacker-controlled content feeds the cap decision. The exit-2 stderr line is fully numeric; exit-1 stderr is recorded as text, not re-executed.

**Category (d) — env-var handling.** No new environment variable reads. `check_perl5opt()` unchanged. No new `$ENV{...}` access. Clean.

**Category (e) — pattern-based / future-reuse risks.** All currently safe. The `read_config`-then-derive-excludes pattern fails open to *more* review (empty excludes → no discount → cap fires earlier). Audit note for future reuse: if repurposed for a decision where "empty list" means "permit more," the default would flip from conservative to permissive. `:(glob,exclude)` prefixing of a value with its own `:(` magic produces a malformed pathspec git rejects → exit 1 (fail-safe); a consumer cannot smuggle a positive re-including pathspec. The `--max-lines` plumbing is symmetric across both exec SKILLs and matches the helper's exit codes (0/1/2). No DoS regression: one extra `git diff --numstat` bounded by diff size (TC-NF5).

No actionable findings.

```cwf-review
state: no findings
summary: --max-lines validated and never reaches git; test-paths excludes are NUL/ref/empty-filtered, list-form pathspecs, fail-safe to exit 1 (no silent discount); cap computed from numstat integers only.
```

## Lessons Learned
A stray `chmod +x` on the test file leaked a `100644→100755` mode change into the checkpoint (amended out). `prove`-run tests do not need the executable bit. See `j-retrospective.md` § What Could Be Improved.
