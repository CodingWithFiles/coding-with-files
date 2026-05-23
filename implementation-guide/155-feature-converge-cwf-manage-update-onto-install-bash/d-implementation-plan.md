# Converge cwf-manage update onto install.bash - Implementation Plan
**Task**: 155 (feature)

## Task Reference
- **Task ID**: internal-155
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/155-converge-cwf-manage-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Implement the converged update path per c-design-plan.md: `cmd_update` delegates laydown to the target ref's `install.bash` (via `file://` re-source), with hardened ref validation, an exact-perms pass, single rules ownership, and version-file reconciliation.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why". Sequence by milestone: **harness first** (so the convergence is testable), then install.bash, then cmd_update, then apply-artefacts narrowing, then docs.

## Files to Modify
### Primary Changes
- `.cwf/scripts/cwf-manage` — for the **subtree** method, replace `update_subtree`+`create_skill_symlinks`+`create_agent_symlinks` with delegation to install.bash; **keep `update_copy` (and `copy_tree`/`_escapes_src`/`_collapse_dotdot`) for the copy method** (see Risks — copy convergence deferred). Add two-phase ref validation; convert `resolve_ref`/`resolve_sha` backticks (`:142,151`) to list-form; widen `check_clean_tree` to `.cwf-rules`; extract `cmd_fix_security`'s hash-verify walk into a sub that **returns** mismatches (entry point keeps its `exit`), add an `exact-set` mode, call it from `cmd_update` with fatal-on-mismatch; reconcile `.cwf/version` (re-read → add `cwf_install_manifest_sha` → rewrite); **delete** `update_subtree`, `create_skill_symlinks`, `create_agent_symlinks`.
- `scripts/install.bash` — force-block commit gains explicit CWF pathspec (`:177`). No copy-path change (copy method stays on `cwf-manage`'s `update_copy`).
- `.cwf/scripts/command-helpers/cwf-apply-artefacts` — narrow update-mode: skip `cwf-rules-bundle` + `claude-rules-symlinks` inventory entries (`:87,91`) now owned by install.bash; keep CLAUDE.md/.gitignore/rules-inject.

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh hashes for `cwf-manage` and `cwf-apply-artefacts` **in the same commit** as their edits (per hash-updates convention).
- `t/fixtures/upstream-server/` — new: bare git repo + 3-5 scripted CWF-shaped commits (≥2 minor versions, one manifest-schema bump).
- `t/cwf-manage-update-end-to-end.t` — new: clone fixture → install → modify fixture → update → assert (FR8).
- `INSTALL.md` (or canonical update doc) — document the forward-only `CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<src> bash install.bash` recovery (FR7).

## Implementation Steps

### Step 1: End-to-end fixture harness (Milestone 1 — testable substrate)
- [ ] Build `t/fixtures/upstream-server/` as a bare repo with scripted commits spanning ≥2 minor versions, including a manifest-schema bump and a downgrade target. Each scripted commit's `install-manifest.json` must be internally consistent with its own `install.bash`, so the downgrade pin→re-read→`validate_install_manifest_sha` loop (FR6 AC) closes. Mirror existing test conventions (`Test::More`, `tempdir`, raw I/O) from `t/cwf-manage-update.t`.
- [ ] Add `t/cwf-manage-update-end-to-end.t` skeleton that clones the fixture into a temp working copy, runs `install.bash`, then `cwf-manage update` with cwd at the temp root (relies on `find_git_root()` resolving the temp repo). Assert it currently fails/red against pre-convergence behaviour where applicable.
- [ ] Include an **unrelated-staged-work** scenario: stage an unrelated file (e.g. `README.md`) before update, assert it is NOT swept into the force-reinstall remove commit (guards the pathspec change in Step 2).

### Step 2: install.bash hardening
- [ ] Force-block commit (`install.bash:177`) → explicit pathspec `git commit -- .cwf .cwf-skills .cwf-rules .cwf-agents` so unrelated staged work is not swept in. Keep the `|| true` guard (an empty-pathspec commit exits non-zero by design); the real safety net is `subtree add`'s own non-zero exit under `set -e` (`:182-191`) — do not "harden" the `|| true` away.

### Step 3: cwf-manage ref validation + list-form (FR9, NFR4)
- [ ] Add phase-1 lexical `<ref>` validation **before any git call**: allow only `[A-Za-z0-9._/-]` plus the literal `latest`; reject a leading `-` and any `..` path segment.
- [ ] Convert **both** `resolve_ref` and `resolve_sha` backtick git calls to list-form `open '-|'`/`system` with a `--` terminator (phase-2 existence check).

### Step 4: cwf-manage delegation (Milestone 2 — core convergence, subtree method)
- [ ] Widen `check_clean_tree` to include `.cwf-rules`.
- [ ] In `cmd_update`'s subtree branch, replace `update_subtree`+`create_skill_symlinks`+`create_agent_symlinks` with a single `system` delegation to install.bash: cwd=`$git_root`, env `CWF_FORCE=1`, `CWF_SOURCE=file://$clone_dir`, `CWF_REF=$sha` (the **resolved SHA** from `resolve_sha`, not the raw `$resolved` ref), `CWF_METHOD=$method`. Distinguish spawn-failure (`$rc == -1`), signal death (`$rc & 127`), and non-zero exit (`$rc >> 8`); any of these ⇒ `die_msg` (abort before manifest pin). Keep the copy branch on `update_copy`.
- [ ] Port `create_agent_symlinks`'s collision `die` (`:605-607`) into install.bash's generic `create_cwf_symlinks`, then delete `update_subtree`, `create_skill_symlinks`, `create_agent_symlinks`.

### Step 5: cwf-manage exact-perms + version reconcile (Milestone 3)
- [ ] Extract `cmd_fix_security`'s hash-verify walk into a sub that **returns** mismatches (the `exit`-based entry point stays for standalone `fix-security`). Add a mode param (`additive` default; `exact-set` applies `chmod $exact`).
- [ ] Call the walk in `exact-set` mode from `cmd_update` after delegation; a returned SHA mismatch ⇒ `die_msg` (fatal: corrupt laydown), before the manifest pin.
- [ ] After delegation, re-read `.cwf/version`, add `cwf_install_manifest_sha = compute_install_manifest_sha()`, rewrite (FR6).

### Step 6: apply-artefacts narrowing
- [ ] Narrow update-mode to skip `cwf-rules-bundle` + `claude-rules-symlinks`; verify CLAUDE.md/.gitignore/rules-inject still applied.
- [ ] **Verify ordering invariant**: no `script-hashes.json` entry lives under a path that `apply-artefacts` (Step 6) writes *after* the exact-perms pass (Step 5), else it would be left unpermissioned. The narrowing should remove the rules tree from update-mode; confirm no hashed file remains written post-perms.

### Step 7: hashes + docs
- [ ] Refresh `script-hashes.json` for `cwf-manage` + `cwf-apply-artefacts` (same commit as edits).
- [ ] Document forward-only `CWF_FORCE` recovery (FR7).
- [ ] File a BACKLOG item for deferred copy-method convergence (port escape check or shell out to a shared checker).

### Step 8: Validation
- [ ] `t/cwf-manage-update-end-to-end.t` green for all three scenarios (version gap [subtree], manifest bump, downgrade).
- [ ] Full `t/` suite green (no regressions); `cwf-manage validate` clean.

## Key Code Change (illustrative — the security-sensitive delegation)
### Before (`cmd_update`, cwf-manage:374-386)
```perl
if ($method eq 'subtree') { update_subtree($git_root, $clone_dir, $resolved); }
elsif ($method eq 'copy') { update_copy($git_root, $clone_dir, $resolved); }
create_skill_symlinks($git_root);
create_agent_symlinks($git_root);
```
### After (subtree → delegate to target install.bash; copy unchanged)
```perl
if ($method eq 'subtree') {
    # $sha is the resolved SHA from resolve_sha (NOT the raw $resolved ref) —
    # so install.bash's own resolve_ref cannot re-resolve to a different commit.
    local %ENV = (%ENV,
        CWF_FORCE => '1', CWF_METHOD => $method,
        CWF_SOURCE => "file://$clone_dir", CWF_REF => $sha);
    my $rc = system('bash', "$clone_dir/scripts/install.bash"); # cwd already $git_root
    if    ($rc == -1)      { die_msg("failed to spawn install.bash: $!"); }
    elsif ($rc & 127)      { die_msg(sprintf("install.bash killed by signal %d", $rc & 127)); }
    elsif ($rc >> 8)       { die_msg(sprintf("install.bash laydown failed (exit %d)", $rc >> 8)); }
} else {
    update_copy($git_root, $clone_dir, $resolved);   # copy method retains _escapes_src
}
```
(Only the four `CWF_*` keys are contract vars; if a future `install.bash` reads another `CWF_*` var, re-check this inherited-env override.)

## Test Coverage
**See e-testing-plan.md for complete test plan** — primary: `t/cwf-manage-update-end-to-end.t` (FR8 three scenarios), plus regression of `t/cwf-manage-update.t` prelude tests and a perms-exactness check (FR5: sample 0444/0500/0700, one outside `.cwf/scripts`).

## Validation Criteria
**See e-testing-plan.md** — all FR ACs traceable; `cwf-manage validate` passes post-update with exact perms; second consecutive update passes `validate_install_manifest_sha`.

## Implementation Risks / Decisions
- **Copy-path convergence deferred (security-driven decision)**: `cwf-manage`'s `update_copy` uses `copy_tree`+`_escapes_src` to refuse upstream symlinks whose targets escape the source tree; `install.bash`'s `install_copy` uses plain `cp -r` with **no** such check. Re-implementing this lexical `..`-collapsing escape primitive in bash is ~30 lines of new, security-sensitive code in a language poorly suited to it — a correctness/maintenance liability. **Decision**: converge only the **subtree** method (the default, and the path with the chicken-and-egg, squash-conflict, and 3-vs-4 staging-dir drift). Keep `update_copy` (+ `copy_tree`/`_escapes_src`/`_collapse_dotdot`) for the copy method, retaining the proven Perl check and keeping the existing 5 `copy_tree` tests (`t/cwf-manage-update.t:147-256`) valid. Copy-method convergence is a follow-up (file a BACKLOG item). This keeps `cmd_update` branching on method but with single laydown ownership per branch (subtree→install.bash; copy→update_copy).
- **`cmd_fix_security` exit→return**: the exact-set caller in `cmd_update` needs the walk to *return* a fatal status so `cmd_update` can `die_msg` before the manifest pin (preserving the lock-scope/abort-clean guarantee, NFR5). The existing `exit`-based entry point must not be called inline from update — extract the walk.
- **Commit-shape change**: a converged subtree update emits a remove commit + per-subtree `add --squash` commits instead of `subtree pull --squash`. Expected; assert in the end-to-end test rather than treating as regression.
- **`create_agent_symlinks` collision `die`**: port the security-relevant `die`-on-regular-file-at-`cwf-*`-path (`cwf-manage:605-607`) into install.bash's generic `create_cwf_symlinks`; do not drop it silently.

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
**Next Action**: /cwf-testing-plan 155
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All steps executed with 3 documented deviations (subtree-only convergence; `cwf-apply-artefacts` not narrowed; exact-perms after artefacts). Full detail in f-implementation-exec.md.

## Lessons Learned
The plan's Step 4/6 deletion-and-narrowing list assumed total convergence; given the copy path is retained, those deletions were unsafe and were corrected at exec. The plan should have been validated against the copy path's call sites before listing deletions. See j-retrospective.md.
