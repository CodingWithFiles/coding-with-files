# Fix security-review changeset construction - Implementation Execution
**Task**: 129 (bugfix)

## Task Reference
- **Task ID**: internal-129
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/129-fix-security-review-changeset
- **Template Version**: 2.1

## Goal
Execute d-implementation-plan.md Steps 1-6 + Step 8 (smoke). Step 7 (test file) is deferred to g-testing-exec.

## Actual Results

### Step 1: Helper script — `security-review-changeset`
- **Planned**: Write the helper at `.cwf/scripts/command-helpers/security-review-changeset` with all classification logic (anchor resolution, CWF-internal-dir rule, shebang sniff with -f/!-l guard, list-form git invocations, anchored interpreter regex, exit-1 error handling).
- **Actual**: Written. ~340 lines of Perl. Uses `CWF::Common::check_perl5opt`, `CWF::TaskPath::parse_branch` and `resolve_num`, `CWF::Versioning::read_config` (eval-wrapped). All git invocations use list-form `open '-|', LIST`. Permissions `0500`.
- **Deviation**: Initially used `die` for error paths, which produces exit 255 (Perl's `die` default). Caught during smoke test that `--task-num='foo;bar'` returned exit 255 instead of the spec'd exit 1. Converted all `die` calls to `warn …; exit 1;` per the existing CWF helper convention (see `cwf-checkpoint-commit:14-15`). Verified post-fix: `--task-num='foo;bar'` now returns exit 1.

### Step 2: Helper script — fallback path
- **Planned**: Trunk resolution via `cwf-project.json:trunk` → `git symbolic-ref refs/remotes/origin/HEAD` → `main`; validate via `git check-ref-format --branch`; anchor = `git merge-base HEAD <trunk>`.
- **Actual**: Implemented in `resolve_anchor_from_fallback()`. `read_config` is eval-wrapped so a missing/malformed `cwf-project.json` falls through cleanly. `git check-ref-format --branch` is used as the validator (instead of a hand-rolled regex per d-plan).
- **Deviation**: None.

### Step 3: Template + template-copier change
- **Planned**: Add `**Baseline Commit**: {{baselineCommit}}` to `.cwf/templates/pool/a-task-plan.md.template`. Extend `template-copier-v2.1` with `--baseline-commit=<sha>` and `$vars{baselineCommit}` mapping.
- **Actual**: Both edits applied. Template copier now accepts the optional argument; absent → renders as empty string (acceptable for synthetic flows).
- **Deviation**: None.

### Step 4: Skill changes — cwf-new-task and cwf-new-subtask
- **Planned**: Capture `git rev-parse HEAD` before branch creation; pass `--baseline-commit="$BASELINE_COMMIT"` to `task-workflow create`. Add user-note about base-branch verification.
- **Actual**: Both SKILLs updated. Note added in both about the baseline being whatever HEAD is at invocation time and the user's responsibility for being on the intended base branch.
- **Deviation**: None.

### Step 5: Doc + exec-SKILL refactor (SSOT)
- **Planned**: Rewrite `.cwf/docs/skills/security-review.md` § "Pathspec coverage" as a contract description; replace `git diff $(git merge-base HEAD main)..HEAD -- <pathspec>` line in both exec SKILLs with helper invocation.
- **Actual**: Doc rewritten — names the helper, documents the two-tier anchor resolution, the three classification rules, the `git check-ref-format` trunk guard, and the v1 known limitations (library files outside CWF dirs, shebang-less sourced scripts, uncommon interpreters, BOM, mid-task rebase). Both exec SKILLs Step 8 line updated.
- **Deviation**: None.

### Step 6: Hash-tracking
- **Planned**: chmod 0500; sha256sum; add entry under top-level `scripts` section of `script-hashes.json`; run `cwf-manage validate`.
- **Actual**: Helper at `0500`. Initial entry added with sha `9a6d021864…`. After the `die` → `warn; exit 1;` fix, sha changed; entry updated to `29a1a6cf2167…`. `template-copier-v2.1`'s sha also updated (was `36382370e5…`, now `2bfa724502…` after `--baseline-commit` arg added). `.cwf/scripts/cwf-manage validate` returns `[CWF] validate: OK`.
- **Deviation**: Had to update two SHAs (helper + template-copier) rather than one — both changed.

### Step 7: Test
- **Planned**: Write `t/security-review-changeset.t`.
- **Actual**: Deferred to g-testing-exec phase per the workflow split. Plan Step 7 will be executed there.
- **Deviation**: Phase-split deviation only; test will be written before testing-exec is marked Finished.

### Step 8: Validation (smoke)
- **Planned**: `cwf-manage validate` clean; manual smoke on this branch.
- **Actual**:
  - `cwf-manage validate` → `[CWF] validate: OK`.
  - Helper invoked on this branch with `--phase=implementation`: returns `reviewed 0 files, 0 lines, anchor=9ac3f96` (matches `main` tip — fallback path exercised because this task's `a-task-plan.md` was created before the new field). The committed phase changes (a/c/d/e wf files) are markdown under `implementation-guide/...`, which is correctly excluded from review (not a CWF-internal dir; no shebang). Once this implementation exec is committed, the helper-script + templates + SKILLs + doc edits will appear on subsequent invocations because they are all under CWF-internal directories.
  - Helper invoked with `--task-num='foo;bar'` → exits 1 with diagnostic on stderr (defence-in-depth check).
- **Deviation**: None.

## Blockers Encountered
None.

## Deferral Check
- [x] All Steps 1-6 + Step 8 (smoke) executed.
- [x] All success criteria from a-task-plan.md addressed; criterion 5 (this task's own g-exec changeset bounded) will be confirmed in g-testing-exec.
- [x] All design decisions (KD-1..KD-6 in c-design-plan.md) implemented as specified.
- [x] Step 7 deferred to g-testing-exec (intentional phase split per CWF v2.1; not scope deferral).
- [x] No work descoped without rationale; all decisions traceable to plan-review findings or CWF conventions.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: error

error: changeset exceeds 500-line review cap; split the change or perform manual review

Note for human reviewer: the helper itself reports `reviewed 8 files, 593 lines, anchor=9ac3f96` — anchor matches `main` tip, so the diff is correctly scoped to *this task's own work* (no inflation from earlier unmerged predecessors). The cap is hit purely because the helper script + doc rewrite + four SKILL edits + template + template-copier add up to ~600 lines for this single bugfix.

Manual review of the eight files against threat categories (a)–(e):

- (a) **Bash injection**: All git invocations in the new helper use list-form `open '-|', 'git', @args` or `system 'git', @args`. No `qx{}` with interpolation, no `system($string)` shell-string form. The trunk name flowing into `git merge-base HEAD <trunk>` is gated by `git check-ref-format --branch <trunk>` first — git itself rejects `..`, `.`, control chars, leading `/`, `@{`, etc. The `--task-num` CLI value is regex-validated against `^\d+(\.\d+)*$` before any FS access.
- (b) **Perl + git path handling**: shebang `#!/usr/bin/perl -CDSL`, `use utf8;`. `git diff --name-only -z` is used; output `\0`-split. No newline-splitting of git output anywhere. List-form invocation throughout.
- (c) **Prompt injection via `{arguments}`**: no SKILL `{arguments}` flow added or changed by this task. The helper takes structured CLI args, none of which feed LLM context directly. The exec SKILLs' `{phase}` token is the only flow into the security-review prompt template, and `{phase}` is constrained to `implementation` or `testing` by the helper's argument parser.
- (d) **Env-var handling**: no env-var reads added or modified.
- (e) **Pattern-based risks**:
  - The shebang interpreter regex `^(?:perl|bash|...|powershell)$` is anchored at both ends. **Safe here because** the regex is applied only after the file's first 128 bytes have been read with `<:raw` and the first line confirmed to begin with `#!`. **Audit future uses** where this regex is reused without those preconditions — an unanchored alternative could match arbitrary substrings. Documented as an inline source comment and in `.cwf/docs/skills/security-review.md`.
  - The 40-char SHA regex `[0-9a-f]{40}` is anchored within `^- \*\*Baseline Commit\*\*:\s+(...)\s*$`. **Safe here because** CWF presently uses SHA-1 baselines. **Audit future uses** if CWF migrates to SHA-256 (64 hex chars) — both this regex and any callers that recompute / re-record baselines must change in lockstep. Documented as an inline source comment.
  - The shebang-sniff is guarded by `-e && -f && !-l` to skip symlinks, FIFOs, sockets, and devices — defends against a diff entry that resolves to `/dev/zero` or similar. **Safe here because** the guard runs before `open`. **Audit future uses** of the same sniff helper (`looks_like_script`) — moving the guard outside the function would re-introduce the DoS surface.

No findings to action; the cap-overflow is a known consequence of the implementation's own size and is tracked separately in the BACKLOG entry "Quantitatively justify the security-review subagent line-count cap".

## Lessons Learned
- Perl `die` returns exit 255 by default, not the helper-contract's spec'd exit 1. Convert to `warn …; exit 1;` for any new CWF helper from the start.
- Two SHAs updated (helper + template-copier-v2.1), not one — adding an optional argument to a hash-tracked script is still a content change requiring re-hashing. `cwf-manage validate` is the gate.
