# fix outstanding cwf-manage issues - Plan
**Task**: 159 (feature)

## Task Reference
- **Task ID**: internal-159
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/159-fix-outstanding-cwf-manage-issues
- **Baseline Commit**: 624a38bd5f0927936ab7bcc8ea633ab789e47462
- **Template Version**: 2.1

## Goal
Resolve the four outstanding `cwf-manage` backlog items in one pass over the script: fix the `cwf_version`/`cwf_ref` semver-resolution bug, add a `fix-security --dry-run` preview, converge the copy update method onto `install.bash`, and replace backtick `git` calls with `IPC::Open3`.

## Success Criteria
- [ ] **Version resolution**: `cwf-manage status` reports a resolved semver in the Version field for installs pinned to `HEAD`/branch/SHA that sit on a tagged commit; `cwf_ref` preserves the originally-requested ref rather than being overwritten with the resolved value.
- [ ] **Dry-run preview**: `cwf-manage fix-security --dry-run` prints the chmod actions and unfixable entries it *would* take, mutates nothing on disk, and a regression test asserts no filesystem mutation.
- [ ] **Copy convergence**: the copy update method lays files down via `install.bash` (single laydown path per backlog FR1), the symlink-escape guard is preserved, and the now-redundant `cwf-manage` copy helpers are removed.
- [ ] **Perlcritic cleanup**: `perlcritic` at severity 3 (harsh) reports no backtick-operator violations in `cwf-manage`, with existing behaviour unchanged (full suite green).
- [ ] **Integrity**: `.cwf/security/script-hashes.json` is refreshed in the same commit as each `cwf-manage` modification, and `cwf-manage validate` passes.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium (driven by the copy-method convergence; the other three are surgical)
**Dependencies**: `install.bash` laydown logic, hash-updates convention, existing `cwf-manage` tests

## Major Milestones
1. **Version bug fixed (Very High)**: `resolve_ref`/`cmd_update` no longer conflate `cwf_version` and `cwf_ref`; semver derived via `git describe --tags`.
2. **Dry-run flag landed**: `cmd_fix_security` gains a non-mutating preview path with a regression test.
3. **Copy method converged**: copy laydown delegates to `install.bash`; symlink-escape semantics preserved; dead helpers removed.
4. **Perlcritic clean**: backticks replaced with `IPC::Open3`; severity-3 clean for that policy; behaviour unchanged.

## Risk Assessment
### High Priority Risks
- **Copy-method convergence introduces a security regression** (item 3): `install.bash install_copy` (`cp -r`) currently has no symlink-escape guard; porting `_escapes_src`/`_collapse_dotdot` semantics across is the riskiest change.
  - **Mitigation**: dedicated design-phase decision; preserve the lexical symlink-escape check exactly; test against a malicious-symlink fixture. If porting proves disproportionate, design may recommend deferring item 3 back to the backlog rather than weakening the guard.

### Medium Priority Risks
- **Hash-tracked file drift**: `cwf-manage` is in `script-hashes.json`; a missed same-commit refresh breaks `cwf-manage validate`.
  - **Mitigation**: plan-time disclosure of every hashed-file edit (hash-updates convention); refresh and `validate` before each commit.
- **`IPC::Open3` changes error/exit-status capture vs backticks** (item 4): subtle differences in how non-zero `git` exits are observed.
  - **Mitigation**: preserve existing exit-status checks; run the full `cwf-manage` suite; behaviour-equivalence is an explicit AC.

### Low Priority Risks
- **Security-review 500-line cap fires** on the bundled, test-heavy changeset, classifying the review as `error`.
  - **Mitigation**: stage commits per item to keep each phase's delta small; this is a known follow-up (backlog: "Tune 500-line security-review cap").

## Dependencies
- `install.bash` shared laydown logic (item 3).
- hash-updates convention and `.cwf/security/script-hashes.json`.
- Existing tests: `t/cwf-manage-fix-security.t` and other `cwf-manage` coverage.

## Constraints
- Dog-food repo — all changes go through the CWF workflow; no direct-to-main commits.
- Perl **core modules only** (`IPC::Open3` is core since 5.000 — compliant).
- POSIX-only; macOS system-Perl portability.
- Hash refresh happens in the same commit as the underlying edit.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — four surgical edits, ~1-2 days.
- [ ] **People**: Does this need >2 people? No — solo.
- [x] **Complexity**: Does this involve 3+ distinct concerns? **Yes** — four independent concerns (version bug, dry-run, copy convergence, perlcritic).
- [ ] **Risk**: High-risk components needing isolation? Borderline — only item 3 carries real risk; isolated within its own phase commit.
- [x] **Independence**: Can parts be worked on separately? **Yes** — all four are independent of one another.

**Decision**: 2 signals triggered (Complexity, Independence) — decomposition into subtasks would normally be recommended. The maintainer has made an informed decision to bundle all four into one flat task (they share `cwf-manage`, a single hash refresh, and one review pass; subtasks would add 4× workflow ceremony for small edits). Each item is handled as a separate functional requirement in the requirements/design phases and gets its own phase commit, preserving isolation without sub-directory overhead.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Bundled as decided. Delivered 3 of 4 items in one session: FR1 (version/ref bug), FR2 (`--dry-run`), FR4 (backtick→`git_capture`). FR3 (copy convergence) deferred at the design gate; stays on the backlog. 4 of 5 success criteria met, the copy-convergence criterion explicitly deferred.

## Lessons Learned
The flat-task decision (decomposition check) held up: one file, one hash refresh, one review pass beat 4× subtask ceremony. Deferring FR3 removed the task's only High-risk milestone, which is why the Medium estimate matched the realised effort. See j-retrospective.md.
