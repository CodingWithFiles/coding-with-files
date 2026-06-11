# update lock fails own clean-tree check - Testing Execution
**Task**: 191 (bugfix)

## Task Reference
- **Task ID**: internal-191
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/191-update-lock-fails-own-clean-tree-check
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Finished" when all pass

## Test Results

### Functional Tests

`prove t/cwf-manage-check-clean-tree.t` → 5 subtests, all PASS.

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-1 | clean tree | returns without dying | no die | PASS | pre-existing regression |
| TC-2 | dirty (tracked + untracked) | dies, lists both | dies, lists `.cwf/version` + `notes.md` | PASS | pre-existing regression |
| TC-3 | git status fails | dies with check-failure msg | dies on `/nonexistent/path` | PASS | pre-existing regression |
| TC-4 | dirty *only* by `.cwf/.update.lock` | returns without dying | no die (lock-only tree clean) | PASS | **new — bug reproducer; FAILS pre-fix** |
| TC-5 | lock + real dirty path | dies, lists real path only | dies, lists `notes.md`, no `.update.lock` | PASS | **new — exclusion-is-exact guard; `unlike` FAILS pre-fix** |

**Red→green evidence (recorded in f-implementation-exec.md Step 1)**: with the
`cwf-manage` source edit stashed, TC-4 failed (`?? .cwf/.update.lock` surfaced as
dirty) and TC-5's `unlike(... .update.lock ...)` failed (lock listed). After the
fix, both pass. This directly demonstrates the self-block is broken (TC-4) and the
exclusion does not mask any sibling dirty path (TC-5).

### Non-Functional Tests
- **Security (exclusion scope)**: TC-5's `unlike` assertion — only the exact lock
  path is hidden; a sibling untracked `.cwf` file is still reported. PASS. The
  exec-phase security-review subagent additionally returned `no findings` (see
  `## Security Review` below).
- **Integrity**: `cwf-manage validate` → `validate: OK` (hash refreshed in the f
  commit, perms at recorded `0700`). PASS.
- Performance/usability/reliability: not applicable to a one-pathspec change.

## Test Failures

None. All planned test cases pass.

(Context: the f-phase full-suite run surfaced one **pre-existing** failure in
`t/cwf-manage-fix-security.t` from local `.claude/agents/*.md` perm drift — not a
defect in this changeset; repaired on sight. Full detail in f-implementation-exec.md
Step 4. Re-verified green here.)

## Coverage Report

- **Critical path (the fix)**: 100% — both the lock-excluded-clean case (TC-4) and
  the exclusion-is-exact case (TC-5) are exercised by direct calls to
  `main::check_clean_tree`.
- **Regression**: `prove t/cwf-manage-*.t` → 8 files, 64 tests, all PASS.
  `prove -r t/` (full suite, run in f phase) → 62 files, 726 tests, all PASS.

## Security Review

**State**: no findings

The live source matches the diff exactly. The git invocation is list-form, retains `-z` and `split /\0/`, and the exclude pathspec interpolates a compile-time constant.

Now let me reason through the threat categories for this testing-exec changeset.

## Security review — Task 191 testing-exec changeset

I reviewed the full changeset at `/tmp/-home-matt-repo-coding-with-files-task-191/security-review-changeset-testing-exec.out` against the five threat categories. The functional code change is identical to what shipped at implementation-exec: a single exact-literal git exclude pathspec in `check_clean_tree`, the shared `$UPDATE_LOCK_REL` constant, the `acquire_update_lock` re-point, the hash refresh, and the two regression subtests (TC-4, TC-5). The testing-exec phase adds the f-implementation-exec.md and other wf step docs to the changeset but no new executable code.

### (a) Bash injection / unsafe command construction
The only executable change is `check_clean_tree` (`.cwf/scripts/cwf-manage:157-179`). I confirmed against the live source: the `git status` spawn is list-form (`open(my $fh, '-|', 'git', '-C', $git_root, ...)`) — no shell, no single-string `system`. The new argument `":(exclude)$UPDATE_LOCK_REL"` interpolates a compile-time constant literal (`.cwf/.update.lock`), never a task slug, branch name, or other partly-controlled string. `acquire_update_lock` interpolates `$git_root` and the same constant into a `sysopen` path, not a shell. No metacharacter exposure. Clean.

### (b) Perl helpers consuming git output without `-z`
`check_clean_tree` retains `-z` (`:166`) and `split /\0/` over NUL-separated records (`:176`), treating each record opaquely. The design deliberately lets git filter via the exclude pathspec rather than parsing the porcelain `XY␣PATH` prefix in Perl, which preserves NUL-safety and avoids rename-pair edge cases. The new test code (TC-4, TC-5 in `t/cwf-manage-check-clean-tree.t`) uses three-argument `open` with explicit mode and a literal path under a `tempdir` repo — no git-output parsing, no untrusted interpolation. No regression to the git-path-output convention.

### (c) Prompt injection via user-supplied strings
No SKILL or prompt surface changed. The wf step docs and BACKLOG entries added in this changeset are static prose authored by the workflow, not user free-text flowing into LLM context. One thing worth noting explicitly: the f-implementation-exec.md file (changeset lines 665-807) embeds my own prior implementation-exec security review verbatim, including a `cwf-review` fenced block (lines 794-797). This is recorded process history inside a `.md` file, not a second verdict block in *my* response — it does not affect the deterministic classifier, which parses only the subagent's response text, not files in the diff. No injection risk; the exclude pathspec is a constant, never derived from `{arguments}` or a task slug.

### (d) Unsafe environment-variable handling
No new env vars. The change does not touch `CWF_SOURCE`, clone, chmod, or rm paths. The lock path is a fixed repo-relative literal, not env-influenced. The f-implementation-exec.md notes a `CWF_UPGRADE_RESOLVE` env var in a backlog entry, but that is a description of a separate, future bugfix — not a code change in this diff.

### (e) Pattern-based risks (safe-here-but-risky-elsewhere)
The exclude pathspec `":(exclude).cwf/.update.lock"` is an exact literal path. It is safe here because it hides exactly one file — CWF's own ephemeral lock — and nothing else. The two carry-over framings (already documented in the inline comment and c-design-plan.md, which is the correct framing):

- **Safe here because the exclude is an exact literal; audit future edits that widen it.** If broadened to a glob (`:(exclude).cwf/*.lock`) or a directory prefix, an attacker-planted file matching the pattern could hide from the clean-tree gate and ride into an `update`. The narrowness is the safety property. TC-5's `unlike($@, qr{\.update\.lock})` plus `like($@, qr{notes\.md})` assertions directly pin this — proving a sibling dirty path is still reported and only the exact lock path is excluded.
- **Safe here because `acquire_update_lock`'s symlink/TOCTOU guard (`-l` precheck + `O_NOFOLLOW`) runs before the check under the D8 ordering; audit any re-ordering.** Excluding the lock from `check_clean_tree` does not weaken lock-path defence — the excluded path is always the guard-validated regular file. If a future change moved the check before lock acquisition, this reasoning would no longer hold.

These are not defects; I record them as the category-(e) "audit future uses" framing.

### Integrity note (boundary with `cwf-manage validate`)
Per the boundary, I do not duplicate deterministic hash/permission checks. For completeness: the recorded sha256 (`e84de3eb...`) matches the current `cwf-manage` and was refreshed in the same changeset, consistent with the hash-updates convention. No stale-hash smell.

### Conclusion
No actionable security concerns. The testing-exec changeset adds only test code and process docs on top of an already-reviewed, behaviour-narrowing code change. All safety invariants hold: list-form spawn, `-z` parsing, D8 ordering, and the symlink/TOCTOU guard. The new tests (TC-4 lock-only-clean, TC-5 exclusion-is-exact) pin exactly the safety-relevant property that the exclusion cannot mask a sibling dirty path, which strengthens the category-(e) invariant rather than introducing any new risk.

```cwf-review
state: no findings
summary: Testing-exec adds only TC-4/TC-5 tests and process docs over an already-reviewed exact-literal exclude pathspec; list-form spawn, -z parsing, D8 ordering and symlink/TOCTOU guard all preserved; hash refreshed in-change.
```

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
The pre-existing `t/cwf-manage-fix-security.t` test-10 failure (agent-perm drift)
recurs in any working tree and is unrelated to the task in flight; it belongs in a
durable fix (existing Medium backlog item), not repeated on-sight repair. See
j-retrospective.md.
