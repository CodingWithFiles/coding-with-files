# Audit show-toplevel sites for worktree-safety - Implementation Execution
**Task**: 173 (bugfix)

## Task Reference
- **Task ID**: internal-173
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/173-audit-show-toplevel-sites-for-worktree-safety
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [ ] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [ ] Verify all prerequisites met
- [ ] Execute implementation steps sequentially
- [ ] Update "Actual Results" for each step
- [ ] Document any deviations from plan
- [ ] Update status to "Implemented" when complete

## OQ resolutions (maintainer-confirmed before exec)
- **OQ-1 (task-stack)**: no change — capture feeds error text only; per-worktree stack is correct.
- **OQ-2 (location)**: report both main + worktree; preserve the `2>&1` diagnostic on the worktree line.
- **OQ-3 (cwf-init)**: investigated — `cwf-apply-artefacts` takes `git_root` as a required positional (`$pos[0]`) and has **no** internal `find_git_root` fallback, so the arg **is load-bearing**. Kept the capture, made it worktree-safe (did not drop it).
- **OQ-4 (cwf-manage)**: routed its own resolver, list-form `git_capture`, `die` contract + fallback preserved.

## Actual Results

### Step 1: Failing test first (TDD) — DONE
- **Planned**: Worktree test asserting the resolver returns the MAIN root; must fail pre-fix.
- **Actual**: Added `t/find-git-root-worktree.t` (TC-1..TC-4). Pre-fix run: TC-1 failed (`find_git_root` returned the worktree `/tmp/.../wt` instead of `/tmp/.../repo`); TC-2/3/4 passed. Empirically confirmed git 2.43.0 behaviour first (worktree `--show-toplevel` = worktree; `--path-format=absolute --git-common-dir` = main `/.git`).

### Step 2: Repoint the choke-point — DONE
- **Actual**: Rewrote `CWF::Common::find_git_root` to derive the main root from `git rev-parse --path-format=absolute --git-common-dir`, stripping the trailing `/.git`, with a documented `--show-toplevel` fallback and the `undef`-outside-repo contract preserved. Transitive callers (Versioning, Backlog, backlog-manager) fixed for free — verified by suite.
- **Deviation**: did **not** use `File::Spec` (see Deviation 2).

### Step 3: Route inline-backtick sites — DONE
- **Actual**: Routed `TaskPath.pm`, `WorkflowFiles.pm`, `template-copier-v2.0`, `template-copier-v2.1`, `migrate-v2.1-file-order` to `find_git_root()` with the appropriate `use CWF::Common qw(find_git_root)` import/plumbing per file.
- **Deviation**: `checkpoints-branch-manager:11` reclassified to **no change** (see Deviation 1).

### Step 4: Class A CWD + prose — DONE
- **Actual**: `update-cwf-skill-docs.sh` — replaced `cd "$(--show-toplevel)"` with a worktree-safe `repo_root` (subshell `cd`, no persistent CWD move) + bash array for the doc glob (space-safe); failure-guarded (`|| exit 1`). `cwf-init/SKILL.md` and `tmp-paths.md` prose updated to the worktree-safe derivation.

### Step 5: OQ-dependent sites — DONE
- **Actual**: `location` dual-report (main + worktree, `2>&1` preserved); `cwf-manage` own resolver repointed (list-form, `die` + fallback); `task-stack` left unchanged.

### Step 6: Hashes, perms, validate — DONE
- **Actual**: Refreshed `sha256` for the 8 edited hashed artefacts (`Common.pm`, `TaskPath.pm`, `WorkflowFiles.pm`, `template-copier-v2.0/v2.1`, `migrate-v2.1-file-order`, `context-manager.d/location`, `cwf-manage`); `update-cwf-skill-docs.sh`/`cwf-init`/`tmp-paths.md` are unhashed (no entry). Pre-refresh: working tree was clean before this task, so the only diffs are this task's edits (no foreign changes absorbed). `cwf-manage validate` → OK. Perms unchanged (validate clean — recorded ceilings respected; `.pm` stay non-exec).

## Verification
- `prove t/find-git-root-worktree.t` → TC-1..TC-4 pass post-fix (TC-1 demonstrably failed pre-fix).
- `prove t/` → **all 640 tests pass** across 54 files (new test included).
- `cwf-manage validate` → OK.
- **Live smoke test** of `context-manager location`: from the main tree all three lines equal the repo root; from a real linked worktree it reports `main` = canonical root and `worktree` = the disposable tree distinctly. No stray worktrees leaked.
- Audit-completeness grep: every residual `--show-toplevel` is an accounted-for disposition (resolver fallback, Class C delete guard, error-message-only task-stack/checkpoints-branch-manager, location diagnostic line, install.bash bootstrap, test helper, and "do NOT" comments).

## Deviations from plan
1. **`checkpoints-branch-manager:11` reclassified Class B → no-change.** The plan (from the design table) assumed this site anchored canonical checkpoint-branch state. In fact `$git_root` there is used only inside `get_script_rel_path()` to relativise the script's *own* path for diagnostic message prefixes (`$SCRIPT_PATH`, lines 21–49). Routing it to the main tree would be *wrong* — from a linked worktree the running script is under the worktree, so a main-tree prefix would fail the match and fall back to the bare name. Same error-message-only class as `task-stack` (OQ-1). Left unchanged; audit disposition recorded.
2. **`File::Spec` not used; literal `/.git` suffix strip instead — in both resolvers.** Design/d-plan specified `File::Spec` parent derivation (per the security finding). But the existing test `t/cwf-manage-update.t` TC-8 asserts `cwf-manage` must **not** import `File::Spec` (a prior cleanup removed it as orphaned). Since `--path-format=absolute` already guarantees an absolute path, stripping the literal `/.git` suffix (`s{/\.git$}{}`) is a well-defined parent derivation with no canonicalisation gap. Applied consistently to both `CWF::Common::find_git_root` and `cwf-manage`'s resolver — keeps the two resolvers identical in style and respects the existing invariant. (The earlier `File::Spec->splitdir` sketch also had a leading-`/` bug; the strip avoids it entirely.)
3. **OQ-3 outcome: capture kept, not dropped.** Investigation showed `cwf-apply-artefacts` has no internal root resolution, so the `GIT_ROOT` arg is load-bearing — made it worktree-safe rather than removing it.

## Blockers Encountered
None. (Initial full-suite run showed 3 `cwf-manage` test failures: one real — the `File::Spec` invariant, fixed per Deviation 2; the others were expected pre-hash-refresh drift, cleared by Step 6.)

## Security Review

**State**: no findings

I have the full diff and the threat model. Let me reason through each threat category.

This changeset's theme is worktree-safety: replacing `git rev-parse --show-toplevel` with a main-tree resolution via `--git-common-dir`, centralised in `CWF::Common::find_git_root`. Let me examine each category.

**(a) Bash injection / unsafe command construction**

The new git invocations are all argument-free constants — `git rev-parse --path-format=absolute --git-common-dir`. No interpolation of slugs, branch names, or paths into the command string. In `cwf-manage`, the call uses list-form `git_capture('rev-parse', '--path-format=absolute', '--git-common-dir')`, which is the recommended `execvp` pattern (no shell). The shell snippets in `cwf-init/SKILL.md` and `update-cwf-skill-docs.sh` also pass no user data into the git command. Clean.

One thing worth checking in `update-cwf-skill-docs.sh`: the new `cmd_docs=( "$repo_root"/.claude/commands/cwf-*.md )` and `sed -i ... "${cmd_docs[@]}"`. The `$repo_root` is derived from `git rev-parse` output (a trusted path under git's control, not user input), and the array form correctly quotes the prefix while preserving the glob. No injection surface — the only variable is a git-resolved repo path. Clean.

**(b) Perl helpers consuming git/user output without `-z` / input validation**

The new `find_git_root` uses backticks on an argument-free command and processes single-value output with `chomp` plus a regex suffix strip — no NUL/list parsing needed since `--git-common-dir` returns one path. The `s{/\.git$}{}` strip relies on `--path-format=absolute` guaranteeing an absolute path; fallback to `--show-toplevel` preserves prior behaviour for submodule gitdirs. `cwf-manage` uses list-form `git_capture` and indexes `$cd->[0]`. Clean.

**(c) Prompt injection via user-supplied strings**

`context-manager.d/location` now prints `$main_root` and `$worktree_root` (latter via `2>&1`). Values are git-resolved paths / git error text, not free-text slugs, printed as quoted diagnostic values, not instructions — same trust level as the prior single-root print. No new prompt-injection surface. Clean.

**(d) Unsafe environment-variable handling**

No new env vars. `update-cwf-skill-docs.sh` sets `CDPATH=` before `cd --` (hardening: neutralises inherited `CDPATH`); `--` guards a `-`-leading dirname. No env var feeds `chmod`/`rm`/`open` unvalidated. Clean.

**(e) Pattern-based risks (safe-here-but-risky-elsewhere)**

The `$common =~ s{/\.git$}{}` literal-suffix strip is **safe here because** `--path-format=absolute` guarantees an absolute path and the common dir ends in `/.git`, with an explicit `--show-toplevel` fallback when it does not (documented inline in both `Common.pm` and `cwf-manage`). Future auditors: anyone reusing the strip should rely on the same `--show-toplevel` fallback rather than assume the strip always matches (e.g. custom `GIT_DIR` names, bare-repo edge cases). The fall-through is the safe failure mode. No action required.

`2>/dev/null` on the resolver's `--git-common-dir` backtick vs `2>&1` on the diagnostic `--show-toplevel` in `location` is the correct asymmetry — the resolver suppresses error text so it never contaminates the returned path, while the diagnostic deliberately surfaces it.

**Summary**

All five categories check out. Security-neutral-to-positive refactor: centralises root resolution, argument-free git commands, list-form spawn preserved in `cwf-manage`, `CDPATH=`/`--` hardening, safe-fallback invariant documented inline. No actionable security concerns.

```cwf-review
state: no findings
summary: Worktree-safe root resolution refactor; argument-free git calls, list-form spawn preserved in cwf-manage, CDPATH=/-- hardening in shell, safe --show-toplevel fallback documented inline. No injection, env, or prompt-injection surface introduced.
```

## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (if applicable)
- [ ] All design guidance in c-design-plan.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 173
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
