# Nest tmp scratch dirs under per-project parent dir - Implementation Execution
**Task**: 203 (feature)

## Task Reference
- **Task ID**: internal-203
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/203-nest-tmp-scratch-dirs-under-per-project-parent
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

See d-implementation-plan.md Steps 1–5. Results below.

## Actual Results

### Step 1: Tests first (red)
- **Actual**: Extended `t/security-review-changeset.t` — TC-OUTFILE now asserts the
  nested `…/cwf<dash>/task-<num>/…` shape and **both** parent and leaf at 0700; added
  TC-PARENT-SYMLINK (symlinked parent → exit 1, diagnostic, no write-through; teardown via
  a dedicated `@CLEANUP_SYMLINK` unlink list) and TC-PARENT-REUSE (pre-existing 0755 parent
  reused unchanged — observable no-auto-chmod); extended the END block to remove the
  `task-<num>` leaf **and** the now-empty `cwf<dash>` parent. New assertions failed red
  against the old sibling-form helper, as expected.
- **Deviations**: TC-PARENT-SYMLINK / TC-PARENT-REUSE derive the real scratch path from a
  first clean run (then re-plant / chmod) rather than recomputing it, making them robust to
  any path canonicalisation in `find_git_root()`. No behavioural change vs. plan.

### Step 2: Helper (green)
- **Actual**: `security-review-changeset` now assembles `$parent = "$base/cwf${dashed}"` and
  `$scratch = "$parent/task-${task_num}"`; two-level `mkdir 0700` (parent then leaf) with the
  `-d && !-l` parent-symlink reject (lstat), recheck after mkdir (race-tolerant), and an inline
  comment recording the deliberate omission of the `pretooluse-bash-tool-check` chmod-clamp.
  Header comment and usage text updated to the nested form.

### Step 3: Hash refresh (same commit)
- **Actual**: `sha256sum` → updated the `security-review-changeset` entry in
  `.cwf/security/script-hashes.json` (`b5662d45…` → `2f031317…`). Pre-refresh
  `git log …-- <path>` confirmed the only intervening change is this task's edit (HEAD = Task
  199 baseline). `cwf-manage validate` clean for the helper. Also clamped two unrelated
  pre-existing permission-drift entries on sight (`context-manager.d/hierarchy`,
  `task-workflow.d/delete`, 0700→0500) via `cwf-manage fix-security` per the fix-on-sight rule.

### Step 4: Docs + skills
- **Actual**: Rewrote `tmp-paths.md` (canonical nested form, derivation snippet creating parent
  + leaf, worked example, artefact examples, sandbox-alignment form, two-level threat-model
  guard + helper parent-symlink defence-in-depth, new "Permission allowlist (optional,
  user-owned)" section with verified `Write(//…/**)` / `Bash(/…/*)` syntax and the
  per-project-vs-per-task granularity trade-off + no-secrets caution, the `-tool-check`
  carve-out in Out-of-scope, agent active-use guidance). Updated `CLAUDE.md` Tmp Paths bullet.
  Added the non-fatal provisioning step to `/cwf-new-task` (after branch create) and
  `/cwf-new-subtask` (after Create-Subtask; no `git checkout -b`), both reusing the canonical
  snippet. No settings file touched (D4).

### Step 5: Validation
- **Actual**: Full `prove t/` = 808/809 pass. The single failure is TC-VALIDATE (asserts the
  *live* repo's `cwf-manage validate` exits 0) — red purely from Task 203's in-flight phase
  files carrying template placeholder statuses ("Planning"/"Requirements"/… — invalid per
  `cwf-project.json`). This is pre-existing at HEAD (those files were committed during
  planning), not a regression from this change; `validate-workflow.t` (fixture-based) passes.
  It resolves at the status sweep before retrospective (j). Security/permission portions of
  validate are clean. Output-level smoke: helper wrote its `.out` to
  `/tmp/cwf-home-matt-repo-coding-with-files/task-203/…` with parent + leaf both 0700, parent
  basename begins with `cwf`. Grep sweep: no stale sibling-form refs in active docs/scripts
  (the one `-task-` hit is the deliberate rejected-basename counter-example); `-tool-check`
  form intact (D5).

## Blockers Encountered

None. (TC-VALIDATE red is an expected in-flight-status artifact, documented under Step 5 —
not a blocker.)

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed (if applicable)
- [x] All design guidance in c-design-plan.md followed (if applicable)
- [x] No planned work deferred without user approval
- [x] If work deferred: Follow-up task created and linked (n/a — nothing deferred)

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*Consolidated in j-retrospective.md.*

## Security Review

**State**: no findings

## Security review — Task 203 implementation-exec changeset

I reviewed the diff at `/tmp/cwf-home-matt-repo-coding-with-files/task-203/security-review-changeset-implementation-exec.out` against the FR4(a–e) threat categories under the single-user developer-host model. The substantive code change is the two-level mkdir + symlink-reject in `.cwf/scripts/command-helpers/security-review-changeset` (lines 260–288); the rest is docs, skills, two new-task scratch-provisioning snippets, the test file, and the in-commit hash refresh.

### (a) Injection / command execution
No new shell-out, `system`, backticks, `eval`, or string-built commands. The new path is assembled by pure Perl string interpolation (`$parent`, `$scratch`) and consumed only by `mkdir`/`-d`/`-l`/`atomic_write_text`. The doc/skill snippets use `mkdir -m 0700 -p "$scratch"` with the variable quoted, and `repo_root`/`base` are command-substitution outputs of `git rev-parse` and `${TMPDIR:-/tmp}`, not user-typed tokens. No injection surface introduced.

### (b) Path traversal / symlink / TOCTOU
This is the focus area and it is handled correctly:
- **Components are validated before they reach the path.** `$task_num` is constrained to `/^\d+(?:\.\d+)*$/` (line 162) — no `/`, no `..`, no NUL — so the `task-${task_num}` leaf cannot traverse. `$wf_step` is checked against the fixed `%WF_STEP` allowlist (lines 130–158) before becoming the `.out` filename. The `cwf` and `task-` segments are literals. `$repo_root` comes from `find_git_root()` (absolute, worktree-safe) with `s{/}{-}g` dashing, so it contributes no live separators to the parent name.
- **The symlink reject uses correct lstat semantics.** `unless (-d $parent && !-l $parent)` (line 277) is the right idiom: `-l` does not follow the link, so a symlink-to-directory (which a bare `-d` would silently accept) is rejected. The recheck deliberately runs *after* the `mkdir` (lines 270 → 277), which the comments correctly justify as race-tolerant (a concurrent create by another session passes; a symlink still fails) and as also catching a non-symlink step-1 mkdir failure (fail-closed).
- **No TOCTOU masquerade.** The review framing is honest: the containment boundary remains the atomic `mkdir 0700` plus the fail-closed `0600` `.out` write (`atomic_write_text` uses same-dir temp+rename, replacing rather than writing through a pre-planted leaf symlink — line 290–295). The symlink check is correctly scoped as defence-in-depth, not re-asserting ownership/mode via a racy `stat`. Leaving the leaf to the fail-closed write (no redundant leaf check) is consistent with that posture.
- **No auto-chmod of a foreign parent** (deliberately diverging from the `pretooluse-bash-tool-check` clamp). This is the safer choice: clamping a pre-existing wrong-mode parent owned by someone else would be a "smooth, don't surface" anti-pattern, and the in-code comment guards against reintroduction by copy. TC-PARENT-REUSE asserts the 0755 parent is left unchanged.
- **Shared, longer-lived parent — pattern-based note (category (e)/(b)):** the nested form makes `cwf<dash>/` a stable, shared directory across all tasks and sessions, where the old sibling form was per-task. The helper's symlink reject is safe here because (i) it is single-user, (ii) the boundary is the fail-closed write, and (iii) the parent mode is 0700 on first create. Audit future consumers of this parent that do NOT go through the helper: the ad-hoc doc/skill snippets (`mkdir -m 0700 -p`) and the D6 provisioning step intentionally omit the `-l` reject. That is acceptable as documented (best-effort, non-fatal, and any consuming *write* still hits the helper's reject or the fail-closed write), but if a future writer trusts the shared parent without its own fail-closed write or `-l` check, the symlink-to-dir gap would reopen. No action needed now; flagged for reuse vigilance.

### (c) Secret / credential exposure
No secrets in the diff. The `.out` stays mode 0600 in a 0700 dir. The docs retain and strengthen the no-secrets-in-scratch caution (tmp-paths.md), correctly noting it matters *more* now that the allowlist subtree may be pre-approved for execution. The hash refresh exposes nothing.

### (d) Untrusted-input handling / prompt-injection surface
The skill/doc additions are workflow instructions to the agent, not new ingestion of untrusted external content. The `$task_num`/`$wf_step` inputs are the only externally-shaped values and both are allowlist/regex-gated before filesystem use. `$TMPDIR` is honoured verbatim, explicitly trusted under the single-user model (the doc states this and the rationale) — consistent with prior behaviour, no new trust extension.

### (e) Environment-variable handling
`$TMPDIR` handling is unchanged in spirit: `(defined $ENV{TMPDIR} && length) ? ... : '/tmp'` with a trailing-slash strip (lines 261–262), matching the shell `${TMPDIR:-/tmp}` form. No new env vars introduced. The Perl helper and the shell snippets agree on derivation. The one widening worth recording is the documented allowlist granularity trade-off (per-project subtree vs per-task) — this is a conscious, user-owned, single-user-bounded decision stated plainly in tmp-paths.md, and CWF edits no settings file itself. In scope as a documented trade-off, not a defect.

### Integrity
The recorded sha256 in `.cwf/security/script-hashes.json` matches the working-tree helper byte-for-byte (`2f0313…d7a5`), permissions stay `0500`, refreshed in the same commit per the hash-updates convention. Tests (TC-PARENT-SYMLINK, TC-PARENT-REUSE, extended TC-OUTFILE, END-block cleanup) exercise the security-critical paths, including write-through verification through the planted symlink.

No actionable security concerns. The diff is clean under the stated threat model.

```cwf-review
state: no findings
summary: Path components allowlist/regex-gated; lstat symlink-reject correct and honestly framed as defence-in-depth over a fail-closed boundary; no-auto-chmod is the safer choice; hash refreshed in-commit and verified. Single-user model upheld.
```
