# record commit sha not tag-object sha - Implementation Plan
**Task**: 175 (bugfix)

## Task Reference
- **Task ID**: internal-175
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/175-record-commit-sha-not-tag-object-sha
- **Template Version**: 2.1

## Goal
Apply the `^{commit}` peel at both SHA-resolution sites and refresh the `cwf-manage` hash in the same commit.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `scripts/install.bash` (line 310) — peel `$resolved_ref` to its commit when computing `resolved_sha`. **Not hashed** (repo-root bootstrap, not in `script-hashes.json`).
- `.cwf/scripts/cwf-manage` (line 225, `resolve_sha`) — peel `$ref` to its commit. **Hashed** — see Supporting Changes.

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh the `cwf-manage` `sha256` entry (line 211) in the **same commit** as the edit (hash-updates convention). `permissions` stays `0700` (recorded == current working perm; **no chmod needed** — do not bump or lower).
- `t/version-records-commit-sha.t` (new) — regression test asserting an annotated-tag install/update records the tag's commit SHA, not the tag-object SHA. Reuses the harness *helpers* from `t/cwf-manage-update-end-to-end.t` / `t/install-bash-reinstall.t` (repo build, consumer install, `slurp`), but **must create its own annotated tag** (`git tag -a`) — the existing `build_upstream` helper creates *lightweight* tags (`git tag v0.0.$i`), for which `rev-parse <tag>` already returns the commit and the bug cannot reproduce. Detailed cases in e-testing-plan.

## Implementation Steps
### Step 1: Test first (red)
- [ ] Add `t/version-records-commit-sha.t`: build a source repo, put an **annotated** tag on a commit, run install.bash with `CWF_REF=<tag>`, assert `.cwf/version` `cwf_sha == git rev-parse <tag>^{commit}` and `!= git rev-parse <tag>`. Add the analogous cwf-manage end-to-end update assertion. Confirm it fails against current code.

### Step 2: Fix install.bash
- [ ] Line 310: `rev-parse "$resolved_ref"` → `rev-parse "${resolved_ref}^{commit}"`.

### Step 3: Fix cwf-manage
- [ ] Line 225 (`resolve_sha`): `'rev-parse', $ref` → `'rev-parse', "$ref^{commit}"`.
- [ ] Confirm working perm remains `0700` (no chmod required).
- [ ] Blast-radius confirmed complete: `resolve_sha`'s output feeds `cwf_sha` (`:523`), `git_describe_version` (`:521` → `cwf_version`, unaffected — describe resolves the commit to the same tag name), and the `CWF_REF` re-passed to the delegated install.bash (`:497`, which peels again, idempotently). No other consumer of the resolved SHA needs a change.

### Step 4: Refresh hash (same commit as Step 3)
- [ ] Pre-refresh verify: `git log --oneline <last-hash-set-commit>..HEAD -- .cwf/scripts/cwf-manage` shows only this task's intended edit.
- [ ] `sha256sum .cwf/scripts/cwf-manage` → write the digest into the `cwf-manage` entry (line 211) of `.cwf/security/script-hashes.json`.

### Step 5: Validation (green)
- [ ] `.cwf/scripts/cwf-manage validate` — clean for `cwf-manage` (pre-existing unrelated drifts on `security-review-changeset` / `cwf-security-reviewer-changeset.md` are out of scope; note them, do not absorb).
- [ ] `prove t/version-records-commit-sha.t` passes.
- [ ] `prove t/install-bash-reinstall.t t/cwf-manage-update-end-to-end.t t/cwf-manage-update.t` — no regressions.

## Code Changes
### install.bash:310
```bash
# Before
resolved_sha="$(git -C "$TMPDIR_CWF/cwf-source" rev-parse "$resolved_ref")"
# After
resolved_sha="$(git -C "$TMPDIR_CWF/cwf-source" rev-parse "${resolved_ref}^{commit}")"
```

### cwf-manage:225 (resolve_sha)
```perl
# Before
open my $fh, '-|', 'git', '-C', $clone_dir, 'rev-parse', $ref
# After
open my $fh, '-|', 'git', '-C', $clone_dir, 'rev-parse', "$ref^{commit}"
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five steps executed verbatim, no deviations. Pre-refresh `git log` verify was clean; sha256 refreshed to `7cc0d82…`; `permissions` left `0700` (no chmod). See `f-implementation-exec.md` §Actual Results.

## Lessons Learned
The plan's "create your own annotated tag" instruction (from plan review) was load-bearing — without it the test would have passed vacuously. See `j-retrospective.md`.
