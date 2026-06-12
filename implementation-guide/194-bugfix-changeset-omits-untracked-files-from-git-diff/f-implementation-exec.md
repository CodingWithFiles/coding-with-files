# changeset omits untracked files from git diff - Implementation Execution
**Task**: 194 (bugfix)

## Task Reference
- **Task ID**: internal-194
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/194-changeset-omits-untracked-files-from-git-diff
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met (on branch, helper at recorded 0500 perms)
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Implemented" when complete

## Actual Results

### Step 1: Cleanup machinery below `my $PROG` (END block + decls)
- **Planned**: Add `@UNTRACKED_TO_RESET`, `$MAIN_PID = $$`, and a PID-guarded,
  `$?`-preserving, non-fatal `END` block using list-form `system('git','reset',...)`.
- **Actual**: Added exactly as planned, with a block comment documenting each guard
  (PID guard, list-form `system`, `$? = $saved`, mandatory `--`). Helper line ~118.
- **Deviations**: None.

### Step 2: `list_untracked_files()` sub
- **Planned**: No-parameter sub: `git ls-files --others --exclude-standard -z`, NUL-split,
  `grep length`.
- **Actual**: Added next to `list_changed_files` with a comment noting it is
  anchor-independent and that git owns the exclude matching.
- **Deviations**: None.

### Step 3 / 3a: PID-guard pin + signal handlers
- **Planned**: Comment at the `git_check` fork site pinning the `$$ == $MAIN_PID`
  invariant; install `$SIG{INT}=$SIG{TERM}=sub{exit(130)}` on the mutating path only.
- **Actual**: Both done. Fork-site comment added at the `exit 127` child path; signal
  handlers installed inside `if (@untracked)` before `add -N`.
- **Deviations**: None.

### Step 4 / 5: Wire untracked enumeration into main flow + widen suffix
- **Planned**: Dirty probe stays before `-N`; `@untracked = list_untracked_files()`;
  populate reset list + handlers + `git add -N -- @untracked`;
  `@included = (@changed, @untracked)`; suffix fires on `dirty_rc==1 || @untracked`.
- **Actual**: Done. The early `my @included = @changed;` was replaced with a comment
  deferring assembly; `@included` is now built after the dirty probe + intent-to-add.
  Explicit-concat comment warns against re-running `list_changed_files` post-`-N`.
- **Deviations**: None. Ordering constraint (probe before `-N`) preserved.

### Step 6: Body + count unchanged
- **Actual**: Confirmed `capture_git('diff', $anchor, '--', @included)` and
  `count_production_lines(...)` were not touched — they now see untracked files via
  intent-to-add. This is the design's whole point.
- **Deviations**: None.

### Step 7: Header comment block
- **Actual**: Updated the "Changeset scope" block (untracked inclusion + transient
  `add -N` + restore) and the stderr-suffix prose (suffix now fires for untracked-only).
- **Deviations**: None.

### Step 8: Hash refresh + perms
- **Actual**: `cwf-manage validate` correctly surfaced the sha256 drift; refreshed the
  `security-review-changeset` entry in `.cwf/security/script-hashes.json` to
  `60458e57...facdc9`. `cwf-manage validate` → OK. Helper perms already at recorded
  0500 (no chmod needed).
- **Deviations**: None.

### Smoke test (live, in this repo)
The repo's own untracked f/g/j workflow guide files made a live test possible:
- Before fix the helper would have reviewed only tracked changes.
- After fix: `reviewed 9 files ... includes uncommitted`, exit 0; the 3 untracked files
  appear as `+++ b/...` new-file hunks in the `.out` body.
- Post-run `git status --porcelain` shows the untracked files still `??` (no residual
  `A `/intent-to-add) — END-block restore confirmed on the normal-exit path.

Automated TC-1…TC-7 are written and run in g-testing-exec.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (verified by smoke test; automated
      coverage in g-testing-exec)
- [ ] b-requirements-plan.md — N/A (bugfix has no requirements phase)
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Running the helper in this repo was a free, high-fidelity smoke test — the
repo's own untracked f/g/j guide files exercised the new path on real data
before a single unit test was written, catching nothing but confirming the
end-to-end shape (9 files reviewed, index restored). Eating the dogfood paid off.

## Security Review

**State**: no findings

The recorded sha256 in the diff (`60458e57...facdc9`) matches the on-disk file exactly, and that's the deterministic concern owned by `cwf-manage validate` anyway. Now I have what I need to complete the review.

### Security review — Task 194 implementation-exec changeset

I reviewed the full changeset against the five threat categories in `.cwf/docs/skills/security-review.md`. The substantive change is to one Perl helper, `.cwf/scripts/command-helpers/security-review-changeset`; the rest of the diff is the hash refresh for that helper plus newly-created workflow guide markdown (template scaffolding, no executable content).

**(a) Bash injection / unsafe command construction.** Every new git invocation uses list-form spawn — no shell parses any path. The new `list_untracked_files()` calls `capture_git('ls-files', '--others', '--exclude-standard', '-z')`, which routes through the existing `open(my $fh, '-|', 'git', @args)` list-form open. The intent-to-add and reset calls — `capture_git('add', '-N', '--', @untracked)` and `system('git', 'reset', '-q', '--', @UNTRACKED_TO_RESET)` — are both list-form. No `system($string)`, no backticks introduced. Clean.

**(b) git output consumed without `-z` / input validation.** `list_untracked_files()` uses `git ls-files --others --exclude-standard -z` and `split /\0/`, matching the sibling `list_changed_files` and the `git-path-output` convention. Untracked paths with embedded newlines are handled correctly. Path classification (ignored-file exclusion) is delegated entirely to git's `--exclude-standard` — no Perl-side path matching is introduced, preserving the helper's stated invariant. Clean.

**Option-injection (FR4(e)) — the load-bearing detail, verified safe.** Untracked filenames arrive verbatim from `git ls-files -z` and a file can legitimately be named `-rf` or `--foo`. All three git commands that take these paths as arguments place the `--` end-of-options separator before them: `add -N --`, `reset -q --`. The body-diff and numstat code paths downstream consume `@included` through the same `--`-guarded pattern (the design pins this and TC-6 tests it). A dash-prefixed untracked file is treated as a pathspec, not an option. Safe.

**(d) Unsafe environment-variable handling.** No new env-var consumption. N/A.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere).** Two patterns worth recording, both safe as written:

1. The `END` block's reset runs unconditionally on every non-SIGKILL exit and is guarded by `$$ == $MAIN_PID` so it cannot fire inside `git_check`'s forked child (whose `exit 127` path would otherwise trigger it). Safe here because the only fork site is `git_check` and a comment pins the invariant at that fork site. Audit future uses: if a second fork site is added, or `git_check` switches to `POSIX::_exit`, the PID guard must remain intact — a child that runs this END would `git reset` the parent's index. The in-code comment already flags this for the next editor.

2. The `END` block deliberately uses bare `system(...)` rather than the `capture_git`/`git_check` wrappers, precisely so it never `exit`s and never clobbers the caller's exit code (it saves/restores `$?`). Safe here because the reset is best-effort and a failure leaves only content-free intent-to-add residue. Audit future uses: any code copied out of this END that needs the wrappers' fail-hard behaviour would silently swallow git errors — the non-fatal posture is specific to cleanup-on-exit.

**Read-only contract.** The change transiently mutates the index (`git add -N`) but restores it via the END block plus INT/TERM handlers installed before the mutation. Intent-to-add carries no content, so even an un-restored entry loses no working-tree data and is cleared by a plain `git reset`. The dirty-probe ordering (probe before `add -N`) correctly prevents the intent-to-add from flipping the `includes uncommitted` disclosure. No data-loss surface.

No actionable security concerns. The markdown guide files are inert scaffolding. The pattern-risk notes under (e) are already mitigated by in-code comments and do not require changes.

```cwf-review
state: no findings
summary: list-form spawn, -z parsing, and load-bearing -- option-injection guards all correct; index restore is PID-guarded and exit-code-safe
```
