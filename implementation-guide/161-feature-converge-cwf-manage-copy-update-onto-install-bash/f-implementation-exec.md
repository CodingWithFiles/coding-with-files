# converge cwf-manage copy update onto install.bash - Implementation Execution
**Task**: 161 (feature)

## Task Reference
- **Task ID**: internal-161
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/161-converge-cwf-manage-copy-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Execute the implementation following d-implementation-plan.md (D2→D3→D1/D6) and e-testing-plan.md.

## Actual Results

### Step 1 — guard helper + its tests (D2) — commit a5d1079
- **Planned**: new `.cwf/scripts/command-helpers/cwf-check-tree-symlinks` porting `_escapes_src`/`_collapse_dotdot` verbatim; self-decode `@ARGV`; one `File::Find` per root; validation-only; fail-closed; `caller()` guard. New `t/cwf-check-tree-symlinks.t`.
- **Actual**: Helper written (117 lines), escape subs copied byte-for-byte. `@ARGV` decoded via `Encode::decode('UTF-8', …)`. `check_root` runs one `File::Find::find` per root closing over `$src`; inspects only `-l` entries; `readlink` failure and escaping target both `exit 1`; no roots → `exit 2`. `chmod 0500` + `git add` → committed mode `100755`. Test covers all six escape cases incl. **source-root-equal** (`'..'`), clean multi-root, escaping refusal + message, per-root attribution, pool-pointing allowed, usage error. `prove`: 7 subtests green.
- **Deviations**: (1) Test uses `POSIX::_exit` in the forked child (not `exit`) to avoid running the parent's inherited `File::Temp` CLEANUP. (2) The `readlink`-failure branch is covered by inspection, not a test — a `-l` lstat with a failing `readlink` is a TOCTOU/permission race not reproducible portably; noted in the test file.

### Step 2 — ledger entry (D7) — commit a5d1079
- **Planned**: add `cwf-check-tree-symlinks` to `script-hashes.json` (sha256 via `sha256sum`, `0500`); validate; checkpoint.
- **Actual**: Entry added (sha256 via `sha256sum` — implementation diversity vs the validator's `Digest::SHA`). `cwf-manage validate`: OK. Committed with helper + test.

### Step 3 — wire guard into install_copy (D3) — commit 233a26d
- **Planned**: one `(src:dest)` pairs list; guard the present roots **before** the `rm -rf`; loop `cp -r` over the same list.
- **Actual**: `install_copy` rewritten — one `pairs` array, `roots` built with the `-d` filter, guard invoked before the `CWF_FORCE` `rm -rf`, `cp -r` loop over the same `pairs`. Existing `t/install-bash-reinstall.t` green. Smoke test (scratch dir): clean copy install lays down `.cwf`; an absolute-target symlink in the upstream is refused with the guard message and **no `.cwf` is written** (fail-closed).
- **Deviations**: Added an explicit `[[ -x "$guard" ]] || die …` precheck. Rationale: FR2/NFR5 require the guard to run before any copy; if the target ref predates the helper the clone won't contain it, and a silent skip would be a fail-open that violates FR2. The precheck makes that case fail-closed with a clear message rather than a cryptic "No such file or directory". Trade-off: a fresh copy install of a pre-guard ref via the *new* installer is refused (marginal; the matching-version installer for that ref is the natural path).

### Step 4 — converge cwf-manage + remove dead code (D1, D6) — commit 10adbc0
- **Planned**: caller audit; collapse copy branch into one delegation block; delete `update_copy`/`copy_tree`/`_escapes_src`/`_collapse_dotdot` and (audit clearing) `create_skill_symlinks`/`create_agent_symlinks`; prune unused imports; remove migrated subtests; refresh hash.
- **Actual**: Caller audit confirmed all six subs are copy-branch-only and that `install.bash post_install` (`:257-259`) creates all three symlink kinds for both methods — so the copy branch's symlink calls are redundant. `if/elsif/else` collapsed into one method-validated delegation block. All six subs deleted (340 lines). Migrated `copy_tree`/`_escapes_src` subtests + the dead `require` removed from `t/cwf-manage-update.t`. `cwf-manage` hash refreshed in the same commit. Full suite `prove -lr t/`: **527 tests green**; `cwf-manage validate`: OK. Full convergence smoke (scratch dir): copy install → `cwf-manage update` (copy delegation) succeeds, method stays `copy`, `cwf_ref` recorded, `.cwf`+`.cwf-rules` present, rules symlink created.
- **Deviations**: Removed **five** unused imports, not three. The d-plan named `File::Find`/`File::Copy`/`File::Path`; deleting `_escapes_src` (used `File::Spec`) and the symlink subs (used `basename`) also orphaned `File::Spec` and `File::Basename`. Verified against HEAD that both were used only inside the deleted subs before removal.

## Security Review

**State**: no findings

The full task changeset is 741 lines (> the 500-line review cap) because `cwf-manage` drops ~340 lines of now-dead copy-laydown code. Per the skill's "split the change" remedy, the review was scoped to the three production source files (463 lines — the actual attack surface): `cwf-check-tree-symlinks`, `cwf-manage`, `scripts/install.bash`. The 340-line deletion is pure removal (no attack surface; the guard logic it removes was ported verbatim into the reviewed helper). The two test files (`t/cwf-check-tree-symlinks.t` new, `t/cwf-manage-update.t` deletions) were excluded as non-production test code. Subagent verdict on the source split:

> no findings
>
> Implementation-phase changeset reviewed against threat categories (a)–(e). The three production files are clean.
>
> Verification notes (not findings):
> - The `_escapes_src`/`_collapse_dotdot` guard in the new helper is a byte-for-byte verbatim port of the prior cwf-manage implementation (confirmed via `git log -S`). The comparison logic (`canon eq src_canon` → escape; `index($canon, "$src_canon/") == 0` → in-tree; else escape) is unchanged — no regression in escape semantics.
> - The guard is fail-closed at every boundary: missing/non-executable guard binary → `die`; zero roots → exit 2 → `die`; `readlink` failure → exit 1; first escaping target → exit 1. The check runs *before* any `rm -rf`/`cp -r`, so a compromised upstream cannot land an out-of-tree symlink even partially.
> - Single-source-of-truth `pairs` list is genuinely shared: guard-roots loop and copy loop compute `src` identically with the same `[[ -d "$src" ]]` filter — a future copy source cannot be added unguarded.
> - All env-var flow into `install.bash` is via `local %ENV` + list-form `system('bash', $installer)` (no shell); `$method` is validated to `subtree|copy` before use. Consistent with the documented-safe pattern at cwf-manage:255.
> - No dangling references to the six removed subs remain in cwf-manage (grep clean).
>
> Pattern-risk observation, safe here (category (e)): `_escapes_src` computes `$src_canon = _collapse_dotdot(File::Spec->rel2abs($src))`, resolving a relative `$src` against the process cwd. Safe at both current callsites because `$src` is always absolute (install.bash passes `$clone_dir/...` rooted at a `mktemp -d` path). Audit any future caller that passes a *relative* root.

No actionable findings; the pattern-risk note is an advisory invariant to preserve, already documented in the helper's comments. Nothing to fix before Step 9.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed (Step 1–4).
- [x] All success criteria from a-task-plan.md met (single laydown path; guard on both fresh-install and update; integrity-covered; env + `.cwf-rules` preconditions reconciled; suite + validate green).
- [x] All requirements from b-requirements-plan.md addressed (FR1–FR5; NFR1–NFR5).
- [x] All design guidance in c-design-plan.md followed (D1–D7).
- [x] No planned work deferred. The rigorous integration test cases (TC-3..TC-8) are written in g-testing-exec per the e-plan; this phase verified the behaviour via scratch-dir smoke tests.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
