# Group Stop-hook warning by task number - Testing Plan
**Task**: 200 (bugfix)

## Task Reference
- **Task ID**: internal-200
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/200-group-stop-hook-warning-by-task-number
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for Group Stop-hook warning by task number.

## Test Strategy
### Test Levels
- **Unit/behavioural**: A new `t/stop-uncommitted-changes-warning.t` (Test::More,
  core-only) drives the hook as a subprocess and asserts its stdout JSON.
- No integration/system/acceptance layers — the hook is a single leaf script.

### Harness shape
The hook reads no stdin; it runs `git status … -- 'implementation-guide/*/[a-j]-*.md'`
against the **cwd** git tree. So each case:
1. builds a throwaway git repo in a `File::Temp` dir (`git init`, local
   `user.email`/`user.name`);
2. plants `implementation-guide/<dir>/[…/]<x>-*.md` files (untracked is enough —
   the query uses `--untracked-files=all`);
3. runs the hook **by absolute path** with cwd = the temp repo, so its
   `$FindBin::Bin/../../lib` still resolves `CWF::TaskPath` from the real repo
   while the git query sees the planted tree;
4. captures stdout + exit, decodes the JSON with `JSON::PP`, asserts on
   `systemMessage`.
Helper `run_hook($tmp)` returns `($json_or_undef, $exit)`. `git status --porcelain`
emits records **sorted lexicographically by pathname** (not file-plant order), so
group/file order in the assertions is git's path sort — e.g. `199` before `30`,
`28` before `30`, `30` before `scratch`. (Corrected during execution; the original
"file-plant order controls git-status order" framing here was inaccurate.)

### Coverage Targets
- Every success criterion (grouping, single-task elision, no-group-dropped,
  exit 0 / valid JSON) has ≥1 dedicated case.
- Critical path (single-task elision = byte-identical to baseline) covered by TC-1/TC-2.

## Test Cases
### Functional Test Cases
- **TC-1 — single task, ≤3 files (elision)**
  - **Given**: untracked `199-discovery-x/{a-task-plan,c-design-plan}.md`
  - **When**: hook runs
  - **Then**: `⚠ Uncommitted: a-task-plan.md, c-design-plan.md` — no `N:` prefix, no `+more`
- **TC-2 — single task, >3 files (flat overflow, baseline-identical)**
  - **Given**: 8 untracked wf files under one task dir
  - **When**: hook runs
  - **Then**: first 3 basenames `, `-joined + ` +5 more`, no number prefix (criterion 2)
- **TC-3 — two tasks (grouping)**
  - **Given**: dirty files under `199-…` and `30-…`
  - **When**: hook runs
  - **Then**: `199: …; 30: …` — each group number-prefixed, joined by `; ` (criterion 1)
- **TC-4 — nested subtask number**
  - **Given**: dirty file at `28-feature-p/28.1-chore-c/f-implementation-exec.md` plus a file in another task
  - **When**: hook runs
  - **Then**: that group keyed `28.1` (via `parse_dirname`), not `28`
- **TC-5 — multi-task with per-group overflow (no group dropped)**
  - **Given**: 4 files in `199-…`, 1 file in `30-…`
  - **When**: hook runs
  - **Then**: `199: …, …, … +1 more; 30: a-task-plan.md` — the `30` group and its file
    still present despite the first group overflowing (criterion 3 / top risk)
- **TC-6 — non-task parent dir (fallback key)**
  - **Given**: untracked `implementation-guide/scratch/a-task-plan.md` (matches glob, parent not `<num>-<type>-<slug>`)
  - **When**: hook runs
  - **Then**: grouped under raw key `scratch`; file surfaced, not dropped or `undef`
- **TC-7 — clean tree**
  - **Given**: no dirty wf files
  - **When**: hook runs
  - **Then**: no stdout (empty), exit 0

### Non-Functional Test Cases
- **Exit-0 invariant**: every case asserts `exit == 0` (hook must never trap).
- **Valid JSON**: every non-empty output decodes as a single-line JSON object
  with a `systemMessage` key (`JSON::PP`).
- **Portability**: test uses core modules only (`Test::More`, `File::Temp`,
  `FindBin`, `JSON::PP`) — no CPAN deps.

## Test Environment
### Setup Requirements
- `git` on PATH; per-test `File::Temp` repo with local identity (never the real tree).
- Hook invoked by absolute path; cwd switched to the temp repo per case.

### Automation
- `prove -v t/stop-uncommitted-changes-warning.t`; runs under the existing `t/` suite.

## Validation Criteria
- [ ] TC-1…TC-7 passing
- [ ] Exit-0 invariant + valid-JSON assertions passing on every case
- [ ] `.cwf/scripts/cwf-manage validate` clean (sha256 + 0500 perms)
- [ ] No regression in the wider `t/` suite

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All seven planned cases plus the exit-0/valid-JSON invariants implemented in
`t/stop-uncommitted-changes-warning.t` (20 assertions, all PASS). One plan
inaccuracy found and corrected during execution: the harness-shape note claimed
file-plant order controls git-status order — git `status --porcelain` actually
sorts records by pathname, so expectations were written to match git's sort
(no behavioural impact: the hook preserves whatever order git returns). All
validation criteria met (full `t/` suite green at 782 tests; `cwf-manage validate`
clean).

## Lessons Learned
*Captured in j-retrospective.md*
