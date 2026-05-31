# Audit show-toplevel sites for worktree-safety - Testing Execution
**Task**: 173 (bugfix)

## Task Reference
- **Task ID**: internal-173
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/173-audit-show-toplevel-sites-for-worktree-safety
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [ ] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [ ] Verify test environment ready
- [ ] Execute test cases sequentially
- [ ] Record pass/fail for each test
- [ ] Document failures with reproduction steps
- [ ] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-1 | resolver inside linked worktree | returns MAIN root, not worktree | main root returned (`/tmp/.../repo`) | **PASS** | TDD anchor — failed pre-fix (returned `/tmp/.../wt`). `t/find-git-root-worktree.t` |
| TC-2 | resolver in main tree | == `--show-toplevel` | equal | **PASS** | no behavioural change outside worktrees |
| TC-3 | resolver outside a repo | `undef` | `undef` | **PASS** | contract preserved for `//`/`length` callers |
| TC-4 | derivation guard | absolute, no trailing `/.git` | absolute, no `/.git` | **PASS** | asserts `--path-format=absolute` honoured |
| TC-5 | documented fallback branch | falls back to `--show-toplevel` | — | **NOT AUTOMATED** | see Coverage Report; safe failure mode confirmed by code review + security reviewer |
| TC-6 | transitive + routed-module callers | resolve main tree, no regression | all green | **PASS** | `versioning.t`, `backlog-manager.t`, `workflowfiles*.t`, `taskpath.t`, `template-copier-*.t` (115 tests) pass with repointed resolver |
| TC-7 | routed helper from worktree | anchors to main tree | — | **PASS (by inheritance)** | template-copier suite green; helpers call the worktree-tested `find_git_root()` — no helper-private root logic remains |
| TC-8 | cwf-manage independent resolver | main tree from worktree | — | **PASS (by equivalence + smoke)** | resolver is byte-identical derivation to the unit-tested `CWF::Common` twin (verified in diff); live `cwf-manage status` from a worktree shows no new failure. See Coverage Report. |
| TC-9 | Class C delete guard unchanged | no semantic regression | not in changeset | **PASS (by non-modification)** | `task-workflow.d/delete:153` untouched (Class C); confirmed absent from the changeset by grep |
| TC-10 | Class A shell snippet | main root from worktree; abort outside repo | derivation verified | **PASS** | identical git derivation proven by the live `context-manager location` worktree smoke; snippet adds `|| exit 1` abort + empty-check |

### Non-Functional Tests
- **Integrity**: `.cwf/scripts/cwf-manage validate` → **OK**. All 8 edited hashed artefacts have same-commit `sha256` refresh; recorded perm ceilings respected; `.pm` modules remain non-executable.
- **Regression**: `prove t/` → **all 640 tests pass across 54 files** (incl. the new `find-git-root-worktree.t`). No pre-existing test regressed.
- **Portability**: core-Perl only (`File::Temp`, `File::Spec`, `Cwd`, `Test::More`); git flags (`--path-format=absolute`, `--git-common-dir`) verified on git 2.43.0; no `File::Spec` added to `cwf-manage` (existing invariant `cwf-manage-update.t` TC-8 respected).
- **Reliability**: outside-repo path returns `undef` (Perl) / aborts non-zero (shell); resolver fallback degrades to `--show-toplevel` — no silent wrong-root.
- **Live behaviour smoke**: `context-manager location` from a linked worktree reports `main` = canonical root and `worktree` = the disposable tree distinctly (OQ-2); from the main tree all lines coincide. No stray worktrees leaked.

## Test Failures
None. (During implementation, an initial full-suite run surfaced the `cwf-manage` `File::Spec` invariant failure and pre-hash-refresh drift; both resolved before this phase — see `f-implementation-exec.md` § Deviations/Blockers. Final suite is clean.)

**Test-robustness fix during this phase**: the testing-phase security reviewer noted (out of scope for security) that subtests TC-1/TC-2/TC-4 called `plan tests => N` and then a conditional `plan skip_all` — two `plan` calls, which would error (not skip cleanly) on a host where `git worktree` is unavailable. Fixed by reordering: the setup + `plan skip_all unless defined $main` now precedes `plan tests => N`, so exactly one `plan` call executes. Re-ran `t/find-git-root-worktree.t` → still PASS. (Test files are unhashed; no manifest change.)

## Coverage Report
- **Resolver critical path**: 3 of 4 branches automated (worktree-derive, main-tree, outside-repo via TC-1/2/3; absolute-form guard via TC-4). 
- **TC-5 (fallback branch) residual**: the `--show-toplevel` fallback (common-dir not ending in `/.git`, e.g. submodule gitdirs / custom `GIT_DIR`) is **not** exercised by an automated test — constructing the condition deterministically needs a submodule or custom-gitdir fixture, judged disproportionate for a defensive branch whose failure mode is "degrade to prior behaviour". Mitigation: branch is small, reviewed, and the security reviewer confirmed it as the safe fall-through. *Optional follow-up*: a submodule-fixture test if future work touches this branch.
- **TC-8 cwf-manage resolver**: covered by logical equivalence (identical derivation to the unit-tested `CWF::Common::find_git_root`) plus a live worktree smoke. A fully-independent assertion would require an install-into-tempdir + worktree harness (cwf-manage's `find_git_root` is a script-private sub, not importable); deferred as disproportionate given the identical, tested logic.

## Security Review

**State**: no findings

Now I have full context. Let me reason through the threat categories for this testing-phase changeset, with focus on the new test file `t/find-git-root-worktree.t` and its fixture dependency.

The changeset is the worktree-safety refactor (Task 173). The production code was reviewed at the implementation phase and returned no findings. At the testing phase the new surface is `t/find-git-root-worktree.t`.

**(a) Bash injection** — test uses list-form `system('git','-C',$repo,'worktree','add',...)`; the only backtick is argument-free `--show-toplevel`. All paths derive from `File::Temp::tempdir` (process-controlled). `update-cwf-skill-docs.sh` uses `CDPATH= cd --` + quoted bash array `"${cmd_docs[@]}"`. Clean.

**(b) Perl git-output handling** — `find_git_root` consumes single-value `--git-common-dir` output (chomp + `/.git` strip), no `-z`/list parsing needed; fallback preserved. Clean.

**(c) Prompt injection** — no `{arguments}` flow; `location`'s `2>&1` diagnostic prints git-resolved paths/error text as a value, not an instruction (OQ-2). Acceptable.

**(d) Env-var handling** — no new env vars; `CDPATH=` reset is hardening. Clean.

**(e) Pattern risks** — `/.git` literal-suffix strip is safe because `--path-format=absolute` guarantees an absolute path, with documented `--show-toplevel` fallback for submodule gitdirs. Pre-existing fixture single-string `system` form noted as a future-audit observation (paths are `File::Temp`, not user input), not a finding against this diff.

**Test-quality note (not security)**: TC-1/TC-2/TC-4 `plan skip_all` after `plan tests => N` is a Test::More usage concern, out of scope. *(Addressed during this phase — see Test Failures section.)*

No actionable security concerns. The new test uses list-form spawn, `File::Temp` paths, no live-repo mutation, no network, core modules only.

```cwf-review
state: no findings
summary: Testing-phase diff clean; new test uses list-form spawn + File::Temp paths, no untrusted input, core modules only.
```

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 173
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
