# Converge cwf-manage update onto install.bash - Design
**Task**: 155 (feature)

## Task Reference
- **Task ID**: internal-155
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/155-converge-cwf-manage-update-onto-install-bash
- **Template Version**: 2.1

## Goal
`cmd_update` orchestrates update-only concerns but delegates **all laydown** to the target ref's `scripts/install.bash`, sharing a single clone, so install and update cannot drift and the target version's laydown governs.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Architecture Choice — delegate laydown to target `install.bash` (backlog option c)
- **Decision**: `cmd_update` keeps its update-only prelude/postlude (lock, validations, clean-tree, apply-artefacts, settings-merge, manifest-SHA pin, exact perms) but replaces its own `update_subtree`/`update_copy`/`create_*_symlinks` laydown with a delegated call to the **freshly-cloned target ref's** `scripts/install.bash`, run with `CWF_FORCE=1` (remove-then-add).
- **Rationale**:
  - Solves the chicken-and-egg: laydown is the *target* version's code, so future cross-version jumps get the target's laydown even when the installed `cwf-manage` is old (FR2).
  - Eliminates the `subtree pull --squash` add/add conflict structurally — `CWF_FORCE` does `git rm` + fresh `subtree add --squash`, never a squash *pull* across a missing merge base (FR3). The documented `CWF_FORCE` workaround already proves this.
  - install and update share one literal laydown implementation → cannot drift (FR1); a new staging dir is one edit in `install.bash`.
- **Trade-offs**:
  - Update now **executes code** from the cloned ref (FR10 trust boundary) — accepted: same trust as a fresh `bash install.bash`.
  - Update commit shape changes: a force reinstall emits a "remove existing install" commit + per-subtree `add --squash` commits, instead of `subtree pull --squash` commits. Acceptable and is the mechanism that avoids the conflict.
  - `install.bash` needs a small extension to share the existing clone (see Single-Clone Integration) so we do not clone twice (NFR1).

### Rejected alternatives
- **(a) Shared bash library under `scripts/lib/` sourced by both** — `cwf-manage` is Perl; it cannot `source` a bash lib without shelling out anyway, and a bash lib sourced by `install.bash` + invoked-as-subprocess by Perl is two consumption models for one lib. More moving parts than delegating to the whole script. Does not by itself solve the chicken-and-egg (the *installed* lib still runs unless we also clone+run the target's copy — which is option c).
- **(b) Single Perl helper invoked by both** — would require rewriting `install.bash`'s laydown in Perl and making the bash bootstrap call Perl, inverting the bootstrap dependency (install must run with zero CWF artefacts present). Larger blast radius, worse for the curl-pipe-bash bootstrap.

## System Design

### Component responsibilities (post-convergence)
- **`scripts/install.bash`** — *single source of truth for laydown*: clone/checkout (or reuse injected clone), the 4 staging-dir subtrees (`.cwf`, `.cwf-skills`, `.cwf-rules`, `.cwf-agents`) or copy equivalents, the 3 symlink sets (skills/rules/agents), and the base `.cwf/version` write. Used by fresh install and (via delegation) by update.
- **`cwf-manage cmd_update`** — *update orchestration only*: acquire lock → validate settings parseable → validate manifest SHA (tamper) → check clean tree → resolve+validate ref → delegate laydown to `install.bash` → exact-perms pass → `cwf-apply-artefacts` (non-staging artefacts) → `cwf-claude-settings-merge` → augment `.cwf/version` with manifest-SHA pin. No laydown logic of its own.
- **`cwf-apply-artefacts`** — *non-staging artefacts*: `CLAUDE.md` preamble, `.gitignore` lines, `.cwf/rules-inject.txt`. Its `.cwf-rules/` tree + rule-symlink duties become redundant on update (now owned by `install.bash`); they are idempotent (re-applies identical source content) so this is safe — see Open Questions for whether to formally narrow its update-mode scope.
- **Exact-perms step** — applies recorded perms from `script-hashes.json` (FR5).

### Clone integration via `file://` re-source (NFR1) — no new env var
Problem: `install.bash:main()` clones `$CWF_SOURCE` into its own `mktemp -d` (deleted on EXIT); `cmd_update` already clones to its own tempdir and needs that checkout afterward (for `apply-artefacts` source + resolved SHA).
- **Decision**: `cmd_update` does the single *network* clone to `$clone_dir`, then delegates with `CWF_SOURCE=file://$clone_dir` and `CWF_REF=<resolved SHA>`. `install.bash` re-clones from that **local** path (sub-second; it already special-cases `file://` at `install.bash:89`) into its own temp, lays down, and cleans up its own temp. `cmd_update` keeps `$clone_dir` for `apply-artefacts` + SHA.
- **Why not a new `CWF_CLONE_DIR` env var**: a clone-dir-injection var would need its own path validation (symlink/`..`/non-`.git` rejection) inside `install.bash` and a skip-cleanup branch — more surface for no measurable gain. NFR1's AC is a *time budget*, and a local clone of a small repo is sub-second, so the simpler `file://` re-source satisfies it. `install.bash` needs **no change** for clone handling.
- **Trade-off**: one local re-clone (cheap) rather than zero. Accepted for the smaller blast radius and absence of a new public env-var contract.

### Delegation preconditions (robustness)
`install.bash` uses bare `git` (no `-C`) and asserts `PWD == git_root` (`install.bash:57-62`); it also refuses an existing `.cwf/` unless `CWF_FORCE=1` (`:72`). The delegated `system` call therefore must:
- set child **cwd = `$git_root`** (else install.bash operates on the wrong repo or dies at `:60`);
- pass **`CWF_FORCE=1`** (mandatory — this is the remove-then-add path, FR3);
- pass **`CWF_REF` = the SHA `cmd_update` already resolved** (not the raw user ref), so install.bash's internal `resolve_ref` cannot re-resolve `latest`/a tag to a different commit;
- pass `CWF_METHOD` from `.cwf/version` so the installed method is preserved.

### Rules-delivery reconciliation (FR1) — single ownership
Today: `install.bash` lays `.cwf-rules` as a 4th subtree + rule symlinks; `update_subtree` omits it and `cwf-apply-artefacts` recreates rules. Post-convergence, `install.bash` owns `.cwf-rules` laydown + rule symlinks on **both** paths (one mechanism).
- **Decision (resolves former Open Question 1)**: narrow `cwf-apply-artefacts` update-mode to the **non-staging** artefacts only (`CLAUDE.md` preamble, `.gitignore`, `.cwf/rules-inject.txt`). Drop its two now-redundant inventory entries on the update path — `cwf-rules-bundle` (tree-replace) and `claude-rules-symlinks` (regenerate, `baseline_source => 'derived'`) at `cwf-apply-artefacts:87,91` — since `install.bash` now owns both. This gives each artefact a single owner rather than two byte-identical paths defended by "idempotency" (which would itself be a drift risk, contradicting FR1).
- `check_clean_tree` must be widened to include `.cwf-rules` (currently only `.cwf`/`.cwf-skills`/`.cwf-agents`) because the force path will `git rm -rf .cwf-rules`.
- **Symlink-helper reuse**: keep `install.bash`'s *generic* `create_cwf_symlinks($src,$target,$glob,$test,$label)` (`install.bash:122-148`) as the single symlink implementation; drop `cwf-manage`'s type-specific `create_skill_symlinks`/`create_agent_symlinks`. **Caveat**: `create_agent_symlinks` (`cwf-manage:580-608`) carries extra collision/stray-file handling the generic helper lacks — the implementation-plan must decide whether that behaviour is ported into the generic helper or consciously dropped (do not silently lose it).

### Version-file reconciliation (FR6)
`install.bash:post_install` writes a 6-key `.cwf/version` without `cwf_install_manifest_sha`. After delegation, `cmd_update` re-reads the version file, adds `cwf_install_manifest_sha = compute_install_manifest_sha()`, and rewrites — exactly one effective pinned state. Verified by a second consecutive update passing `validate_install_manifest_sha`.

### Exact-perms reconciliation (FR5)
`cmd_fix_security` is additive-only (`cwf-manage:776`) — it never lowers an over-permissioned file, so it cannot reduce a blanket-0755 file to a recorded 0500. Convergence needs an **exact-set** pass.
- **Decision (resolves former Open Question 2)**: extend `cmd_fix_security`'s single hash-verify walk with a mode parameter (`additive` vs `exact-set`); the exact-set mode applies `chmod $exact` (0444/0500/0700) instead of the additive guard. **One walk over `script-hashes.json`, not a parallel sibling sub** (a second walk would be the duplication this task exists to remove).
- **SHA mismatch is fatal here** (distinct from `cmd_fix_security`'s user-facing "unfixable report"): post-laydown every hashed file must match by construction, so a mismatch signals a *corrupt laydown* and must abort `cmd_update` before the manifest pin — not skip the entry.
- This pass **supersedes both** residual blanket chmods after convergence: `update_copy`'s `chmod 0755` (`cwf-manage:533`) and `install_copy`'s `chmod u+rx` (`install.bash:229`) — neither should remain reachable on the update path.
- **Fresh-install asymmetry (intended)**: the exact-set pass lives in `cmd_update`, so a *fresh* `bash install.bash` ends at install.bash's baseline perms and does **not** get exact perms. This is acceptable because `validate`'s `(actual & expected) == expected` accepts the baseline; tightening fresh-install perms is out of scope (tracked separately — `BACKLOG.md:1088`).

### Ref validation & list-form spawn (FR9, NFR4)
`resolve_ref`/`resolve_sha` currently interpolate `$ref` inside backticks (`cwf-manage:142,151`) — an injection surface. Validation is **two ordered phases** to avoid the circular trap of "validating via the surface being fixed":
1. **Lexical validation of the `<ref>` string with no git involvement**: reject leading `-` (option injection) and shell/path metacharacters; ideally `git check-ref-format` *as a list-form call* with the candidate after `--`.
2. **Existence check via list-form `git rev-parse`** (`open '-|', 'git', '-C', $dir, 'rev-parse', '--verify', '--', $ref`) — only after phase 1.

The `install.bash` delegation is a list-form `system` with the child environment set explicitly (`CWF_FORCE`, `CWF_REF`, `CWF_SOURCE`, `CWF_METHOD`) and cwd = `$git_root` — no shell parsing — and uses `system` (**not** `exec`) so the Perl lock scope-guard survives (NFR5).

### Force-reinstall commit safety (robustness/security)
`install.bash`'s `CWF_FORCE` path does `git rm -rf` of the staging dirs then `git commit --allow-empty -m "...remove existing install..."` (`install.bash:169-178`). Two hazards:
- **Unrelated staged work**: that commit operates on the whole index, so a user's unrelated *staged* changes would be swept into the "remove existing install" commit. `check_clean_tree` only guards `.cwf*` paths, so it does not prevent this. **Decision**: the force-reinstall commit must use an explicit pathspec (`git commit -- .cwf .cwf-skills .cwf-rules .cwf-agents`) so it captures only CWF paths. (This is a change to `install.bash`'s force block.)
- **Swallowed failures**: the force block guards `git rm`/commit with `2>/dev/null || true` (`:172,177`), so some remove-step failures will not surface as non-zero exit — weakening the "non-zero exit aborts `cmd_update`" net. This sits within the **accepted** non-atomic remove-then-add residual risk (NFR5); the design accepts it rather than re-architecting the force block, and the FR7 `CWF_FORCE` reinstall is the recovery.

### Data flow (converged `cwf-manage update <ref>`)
1. Acquire flock on `.cwf/.update.lock` (scope-held).
2. Validate `settings.json` parseable; validate install-manifest SHA (tamper); check clean tree (now incl. `.cwf-rules`).
3. Validate `<ref>` (phase 1 lexical → phase 2 list-form existence); `git clone` source → `$clone_dir` (single network clone); resolve SHA.
4. `system` install.bash with cwd=`$git_root`, `CWF_FORCE=1`, `CWF_SOURCE=file://$clone_dir`, `CWF_REF=<resolved SHA>`, `CWF_METHOD` → laydown (subtrees/copy + symlinks + base version).
5. Exact-perms pass (exact-set mode) over `script-hashes.json` entries; SHA mismatch ⇒ fatal abort.
6. `cwf-apply-artefacts $git_root $clone_dir` (non-staging artefacts only — narrowed).
7. `cwf-claude-settings-merge`.
8. Re-read `.cwf/version`, add `cwf_install_manifest_sha`, rewrite.
9. Lock released on return.

## Interface Design

### `install.bash` env-var contract (no new vars; change in **bold**)
| Var | Existing meaning | Change |
|-----|------------------|--------|
| `CWF_METHOD` | subtree\|copy | unchanged (update passes installed method) |
| `CWF_REF` | ref to install | update passes the **already-resolved SHA** |
| `CWF_SOURCE` | repo URL | update passes **`file://$clone_dir`** (local re-source) |
| `CWF_FORCE` | overwrite existing | update always sets `1` |

Behavioural change inside `install.bash` (not a new var): the force block's commit gains an explicit CWF pathspec (see Force-reinstall commit safety).

### `cmd_update` → `install.bash` invocation
List-form `system` with explicit child env **and cwd = `$git_root`**; non-zero exit aborts `cmd_update` before the version-file/manifest step (mirrors existing `run_apply_artefacts`/`run_settings_merge` abort-on-nonzero pattern). install.bash's own `[CWF]` logging surfaces to the user.

### Exit-code propagation
install.bash uses `set -euo pipefail` and exits non-zero on failure; `cmd_update` treats any non-zero as fatal (die before manifest pin), leaving no partial pinned state.

## Constraints
- POSIX-only, core-Perl-only (`cwf-manage`), Bash 4+ (`install.bash`).
- `cwf-manage` modification ⇒ same-commit `script-hashes.json` refresh; `install.bash` is outside the hash ledger (no refresh obligation).
- Forward-only: cannot fix installs already on a pre-fix `cwf-manage` (their old updater runs). Recovery = documented manual `CWF_FORCE` reinstall (FR7).

## Decomposition Check
- [x] **Complexity**, [x] **Risk**, [x] **Independence** triggered (as in a/b). **Kept monolithic per user decision (2026-05-22).** Milestones sequenced: harness → install.bash `CWF_CLONE_DIR` extension → cmd_update delegation + exact-perms + version reconcile.

## Open Questions (resolve in implementation-plan)
1. `create_agent_symlinks`'s extra collision/stray-file handling (`cwf-manage:580-608`): port into the generic `create_cwf_symlinks` or consciously drop? (Must be a deliberate decision, not silent loss.)
2. Exact ordering of the exact-perms pass relative to `apply-artefacts` (perms before or after non-staging artefacts are written) — both touch the tree; confirm no entry is re-permissioned by a later step.

(Former Open Questions on apply-artefacts scope, exact-perms factoring, and the force-commit/staged-work interaction are now resolved decisions in System Design above.)

## Validation
- [ ] Design satisfies FR1-FR10 (traceability checked)
- [ ] Single-clone integration verified to add no second clone (NFR1)
- [ ] Lock/spawn mechanism (`system`, not `exec`) preserves lock-release guarantee (NFR5)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 155
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Subtree-delegation design implemented as specified. Open Question 2 (exact-perms ordering) resolved in exec: `apply_exact_perms_or_die` runs **after** apply-artefacts/settings-merge so the tree is fully laid down before perms are set.

## Lessons Learned
The design under-enumerated which call sites each deleted helper served, producing an over-scoped deletion list (`create_*_symlinks`, narrowing `cwf-apply-artefacts`) that exec had to correct because the copy path still needs them. Future convergence designs should list the remaining callers of every helper marked for deletion. See j-retrospective.md.
