# Fix install.bash reinstall and settings-merge - Implementation Execution
**Task**: 158 (bugfix)

## Task Reference
- **Task ID**: internal-158
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/158-fix-install-bash-reinstall-and-settings-merge
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

## Implementation Steps (from d-implementation-plan.md)

Scope: Option B (settings-only). No apply-artefacts call added to install.bash.

## Actual Results

### Step 1: Harness first (red test)
- **Planned**: Add failing end-to-end test(s) reusing the Task-155 fixture-server pattern.
- **Actual**: Wrote `t/install-bash-reinstall.t` (self-contained copies of the Task-155 `run`/`slurp`/`write_file`/`git_ok`/`cp_rp`/`build_upstream` harness — kept local rather than extracting a shared test lib, which would be scope creep for a bugfix). TC-1..TC-7 per e-testing-plan. Against unfixed code: TC-1, TC-2(die msg), TC-4, TC-5, TC-7 RED as expected; TC-6 green both ways (it guards the tolerated `-x` branch).
- **Deviations**: Initial "clean index" assertion used `git status --porcelain == ''`, which is wrong — post_install legitimately leaves untracked artefacts (settings.json, symlinks, `.cwf/version`) for the consumer to commit (as the Task-155 test does). Replaced with `git diff --cached --name-only == ''` (index == HEAD after the subtree adds), which is the correct proof that no staged CWF deletions leaked. Also fixed `command -v git` (a shell builtin) → `sh -c 'command -v git'`.

### Step 2: Item 1 — force-reinstall commit (`install_subtree`)
- **Planned**: Replace the hardcoded-pathspec block with the `removed` array; commit only the dirs actually `git rm`'d; `die` on a tracked-dir rm failure; drop the blanket `|| true`/`--allow-empty`.
- **Actual**: Implemented exactly per the d-plan snippet, inside the existing `CWF_FORCE` guard. Rewrote the stale comment to describe the real invariant.
- **Deviations**: None.

### Step 3: Item 2 — settings-merge in `post_install`
- **Planned**: Invoke `cwf-claude-settings-merge` after the symlinks and before the version write, `-x`-guarded, `|| die` on failure; both methods (post_install runs for both).
- **Actual**: Implemented exactly per the d-plan snippet. Confirmed the helper self-locates its lib via `FindBin` (`use lib "$FindBin::Bin/../../lib"`), so the bare invocation works without `-I` — matching cwf-manage's `system($helper)`. Confirmed the laid-down helper is mode 100755 (subtree preserves it executable) so the `-x` guard passes. No extra perms edit needed (verified, added nothing).
- **Deviations**: None.

### Step 4: Item 3 — doc fix
- **Planned**: Insert `.claude/agents/` into the §Pathspec coverage prose between `.claude/skills/` and `.claude/hooks/`, matching the helper's `@CWF_INTERNAL_PREFIXES` ordering.
- **Actual**: Single-token insertion on the prose sentence. TC-7 parses both the helper block and the doc backtick tokens and asserts full parity.
- **Deviations**: None.

### Step 5: Suite + manual verification
- **Actual**: New test green (7 subtests). Full Perl suite green (516 tests, 47 files) — the Task-155 e2e now exercises the new merge call during install and still passes. `cwf-manage validate: OK` (neither edited file is hash-tracked → no `script-hashes.json` refresh, as planned). Baked the rules-inject sanity guard into TC-1 (`-s .cwf/rules-inject.txt`), directly guarding the rejected Option A.

## Blockers Encountered

None.

## Security Review

**State**: error

**Classifier note**: The `cwf-security-reviewer-changeset` subagent was invoked
on the implementation changeset (`scripts/install.bash` + `.cwf/docs/skills/security-review.md`;
the new `t/install-bash-reinstall.t` was still untracked so it falls into the
g-phase changeset). Across two runs the subagent prefaced its verdict with
analysis, violating the sentinel-first contract (agent def: "Your VERY FIRST
output line MUST be one of these three sentinels"). Per the three-tier
classification rule this falls through tier-1 (no first-line sentinel) and
tier-2 (no `^\d+[.)]` numbered list, no literal phrase "actionable finding") to
the **conservative `error` default** — the automated gate did not emit a
parseable verdict. Recorded as `error` rather than silently downgrading to
"no findings". **Substantively the review is clean**: both runs concluded
"no findings" / "No actionable security defects", with one non-blocking
category-(e) pattern note (the merged `PERL5OPT` is a compile-time constant
`-CDSLA`; audit only if a future maintainer makes any `settings.json` `env`
value externally sourced). User to adjudicate (accept the clean substance, or
request a re-review). Per the SKILL: do not block on this — surface for the
user to decide.

Verbatim subagent output (second run):

> I now have full context on both changed files. Let me assess each diff hunk against threat categories (a)-(e).
>
> **Diff 1 — security-review.md**: Adds `.claude/agents/` to the CWF-internal unconditional-include prefix list. This *expands* review coverage to a directory holding agent definitions (markdown carrying LLM instructions). This aligns with the maintainer note at line 36 and category (c) — agent files are exactly the kind of instruction-bearing artefact that must be reviewed. No threat introduced; it closes a gap.
>
> **Diff 2 — install.bash, force-removal hunk (lines 176-195)**: Replaces a hardcoded multi-pathspec commit with a dynamic `removed[]` array of dirs actually `git rm`'d. The `git rm`/`rm -rf`/`git commit -- "${removed[@]}"` all operate on the hardcoded loop literals `.cwf .cwf-skills .cwf-rules .cwf-agents` — no user/env-controlled strings interpolated. Array expansion `"${removed[@]}"` is correctly quoted. The error handling now `die`s on a genuinely-tracked dir that fails to `git rm` rather than swallowing it with `|| true`, which is a strict improvement. No injection surface.
>
> **Diff 3 — install.bash, post_install merge-helper hunk (lines 261-272)**: Invokes `.cwf/scripts/command-helpers/cwf-claude-settings-merge` after the `-x` guard. The helper path is a hardcoded literal; the helper is the just-installed CWF copy (within install.bash's established trust boundary); it writes `env.PERL5OPT` as a compile-time constant (`$CANONICAL_PERL5OPT = '-CDSLA'`, line 175); allowlist/hook entries are derived from the installed `.cwf/security/script-hashes.json` and validated via `validate_write_path_allowlist`. The `|| die` aborts before the version-file write, so a partial merge is never recorded as a complete install.
>
> no findings
>
> Both files are clean against threat categories (a)-(e). Pattern-risk note (category (e), non-blocking): the merged helper writes `env.PERL5OPT` only as the compile-time constant `-CDSLA`; safe here because no env var or user-supplied string reaches the `.claude/settings.json` env/permissions surface — audit future uses where a maintainer might make any settings.json `env` value externally sourced.

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed (n/a — bugfix, no requirements phase)
- [x] All design guidance in c-design-plan.md followed (Option B; items 1–3; no apply-artefacts call)
- [x] No planned work deferred without user approval
- [x] If work deferred: Follow-up task created and linked (n/a — residual `.gitignore`/CLAUDE.md drift remains an out-of-scope optional note per d-plan, not deferred work)

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See the per-step "Actual Results" section above. All three items implemented per
Option B; full suite + `cwf-manage validate` green.

## Lessons Learned
The security-review subagent prefaced its `no findings` verdict with analysis,
violating the sentinel-first contract → conservative `error` classification.
Recorded verbatim rather than silently downgraded; flagged for a backlog item.
