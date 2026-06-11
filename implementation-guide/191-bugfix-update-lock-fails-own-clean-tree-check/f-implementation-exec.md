# update lock fails own clean-tree check - Implementation Execution
**Task**: 191 (bugfix)

## Task Reference
- **Task ID**: internal-191
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/191-update-lock-fails-own-clean-tree-check
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Actual Results

### Step 1: Tests first (red)
- **Planned**: Add TC-4 (lock-only → clean) and TC-5 (lock + real dirty path →
  dies, lists real path only) to `t/cwf-manage-check-clean-tree.t`; confirm they
  fail against current code.
- **Actual**: Both subtests added before `done_testing()`. Red demonstrated by
  stashing the `cwf-manage` source edit and running the suite against unfixed code:
  TC-4 failed (`?? .cwf/.update.lock` surfaced as dirty) and TC-5's
  `unlike(... .update.lock ...)` failed (lock listed). Exactly the predicted
  reproducer. Fix then restored via `git stash pop`.
- **Deviations**: Core edits were applied before the red run (edit-then-stash
  rather than write-tests-first), but the red state was still demonstrated
  explicitly against the unfixed source. Net evidence identical.

### Step 2: Core implementation (green)
- **Planned**: Add `$UPDATE_LOCK_REL` constant; append `:(exclude)$UPDATE_LOCK_REL`
  to `check_clean_tree`'s pathspec; re-point `acquire_update_lock`'s `$path` at the
  constant.
- **Actual**: All three edits applied verbatim to `.cwf/scripts/cwf-manage`, plus
  the optional doc-comment tidy at the `acquire_update_lock` header (literal
  `.cwf/.update.lock` → "the update lock") so the constant is the only place the
  path string lives. `prove t/cwf-manage-check-clean-tree.t` → TC-1..TC-5 all pass.
- **Deviations**: None.

### Step 3: Hash + perms (same commit)
- **Planned**: Restore working perms to recorded `0700`; refresh sha256 at
  `script-hashes.json:220`; `cwf-manage validate` → OK.
- **Actual**: `chmod 0700 .cwf/scripts/cwf-manage`; new sha256
  `e84de3eb212eda6f8803ac7366da95462c7c2e5c64b5886331bb41caaa8bb1af` written to the
  entry; `cwf-manage validate` → `validate: OK`.
- **Deviations**: None.

### Step 4: Full regression
- **Planned**: Run the whole `t/` suite — no regressions.
- **Actual**: `prove -r t/` → 62 files, 726 tests, all pass.
- **Deviations**: First full run surfaced one **pre-existing** failure in
  `t/cwf-manage-fix-security.t` (test 10): the live `.claude/agents/*.md` files had
  drifted on disk to `0400` (recorded floor `0444`), failing the fixture's
  floor assertion. Confirmed pre-existing by re-running with all my tracked edits
  stashed — still failed. Git stores these as `100644` (it does not track the
  `0400`/`0444` distinction), so a fresh checkout gets umask-default perms and
  passes; only this working tree was drifted (harness agent-def materialisation).
  `cwf-manage fix-security` repaired 0 files (it clamps to the recorded value as a
  *ceiling*; `0400 ≤ 0444` already validates). Fixed on sight by restoring the five
  agent files to the recorded `0444`. Re-ran full suite → green. This drift is not
  part of the task's changeset (no tracked mode change) and required no commit.

## Blockers Encountered

None. (The pre-existing fix-security drift above was repaired on sight, not a
blocker — see Step 4 deviations.)

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed (N/A — bugfix, no b phase)
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred without user approval
- [x] If work deferred: Follow-up task created and linked (none deferred)

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Security Review

**State**: no findings

The recorded hash `e84de3eb...` matches the current file — the hash refresh is consistent with the source edit, committed together per the hash-updates convention.

Now I have everything I need to reason through the threat model.

## Security review — Task 191 implementation-exec changeset

I reviewed the full changeset at `/tmp/-home-matt-repo-coding-with-files-task-191/security-review-changeset-implementation-exec.out` against the five threat categories. The functional change is small: a single git pathspec exclusion in `check_clean_tree` plus a centralised lock-path constant, hash refresh, test additions, and workflow/backlog docs.

### (a) Bash injection / unsafe command construction
The only executable change is to `check_clean_tree` (`.cwf/scripts/cwf-manage:157-188`). The `git status` invocation remains list-form (`open(my $fh, '-|', 'git', '-C', $git_root, ...)`) — no shell, no single-string `system`. The new argument `":(exclude)$UPDATE_LOCK_REL"` interpolates a compile-time constant literal (`.cwf/.update.lock`), not any user- or task-controlled string. No metacharacter exposure. `acquire_update_lock` likewise interpolates `$git_root` and the same constant into a `sysopen` path, not a shell. Clean.

### (b) Perl helpers consuming git output without `-z` / input validation
`check_clean_tree` retains `-z` and `split /\0/` over NUL-separated records (`:166`, `:176`), and continues to treat each record opaquely. The design deliberately lets git do the filtering rather than parsing the porcelain `XY␣PATH` prefix in Perl — this preserves NUL-safety and avoids the rename-pair edge cases a post-split filter would introduce. No regression to the git-path-output convention.

### (c) Prompt injection via user-supplied strings
No SKILL/prompt surface changed. The new BACKLOG entries and wf step docs are static prose authored by the workflow, not user free-text flowing into LLM context. The exclude pathspec is a constant, never derived from `{arguments}` or a task slug. Nothing here widens the prompt-injection surface.

### (d) Unsafe environment-variable handling
No new env vars. The change does not touch `CWF_SOURCE`, clone, chmod, or rm paths. The lock path is a fixed repo-relative literal, not env-influenced.

### (e) Pattern-based risks (safe-here-but-risky-elsewhere)
The exclude pathspec `":(exclude).cwf/.update.lock"` is an **exact literal path**. It is safe here because it hides exactly one file — CWF's own ephemeral lock — and nothing else. Worth noting for future maintainers (the design doc and inline comment at `.cwf/scripts/cwf-manage:160-164` already flag both of these, which is the correct framing):

- **Safe here because the exclude is an exact literal; audit future edits that widen it.** If this were ever broadened to a glob (`:(exclude).cwf/*.lock`) or a directory prefix (`:(exclude).cwf/cache`), an attacker-planted file matching the pattern could hide from the clean-tree gate and ride into an `update`. The narrowness is the safety property; keep it literal.
- **Safe here because `acquire_update_lock`'s symlink/TOCTOU guard runs before the check (D8 ordering); audit any re-ordering.** Excluding the lock from `check_clean_tree` does not weaken lock-path defence, because the `-l` precheck + `O_NOFOLLOW` (`:269-273`) validates the path earlier in `cmd_update`. The excluded path is always the guard-validated regular file. If a future change moved the check before lock acquisition, this reasoning would no longer hold.

These are not defects in the diff — the implementation is correct and the invariants are documented inline. I record them only as the category-(e) "audit future uses" framing the threat model asks for.

### Integrity note (boundary with `cwf-manage validate`)
Per the security-review boundary, I do not duplicate deterministic hash/permission checks. For completeness only: the recorded sha256 (`e84de3eb...`) matches the current `cwf-manage` and was refreshed in the same changeset, consistent with the hash-updates convention. No stale-hash smell.

### Conclusion
No actionable security concerns. The change narrows behaviour (one exact path excluded from a dirty-tree scan), preserves all existing safety invariants (list-form spawn, `-z` parsing, D8 ordering, symlink/TOCTOU guard), and introduces no new input flow. The accompanying tests (TC-4 lock-only-clean, TC-5 exclusion-is-exact) directly pin the safety-relevant property that the exclusion cannot mask a sibling dirty path.

```cwf-review
state: no findings
summary: Exact-literal git exclude pathspec; list-form spawn, -z parsing, D8 ordering and symlink/TOCTOU guard all preserved; hash refreshed in-change.
```

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Stashing only the `cwf-manage` edit (leaving the new tests in place) was a clean way
to evidence red mid-exec when core and tests land together. `fix-security` treats
recorded perms as a ceiling, so it will not raise a below-floor drift — the
`.claude/agents/*.md` `0400`→`0444` repair had to be manual. See j-retrospective.md.
