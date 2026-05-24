# converge cwf-manage copy update onto install.bash - Design
**Task**: 161 (feature)

## Task Reference
- **Task ID**: internal-161
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/161-converge-cwf-manage-copy-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Define the architecture for converging the `cwf-manage` copy update method onto `scripts/install.bash`, extracting the symlink-escape guard into a single shared, integrity-covered helper invoked before any copy.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Design seed
This task implements FR3 deferred at Task 159's design gate. The retained Option A/B/C analysis lives at `implementation-guide/159-feature-fix-outstanding-cwf-manage-issues/c-design-plan.md:44-67`. This design is the "Option B done properly" the deferral pre-seeded, with the integrity-boundary and `.cwf-rules` questions resolved below.

## Key Decisions

### D1 — Convergence mechanism: copy branch delegates to `scripts/install.bash` (mirrors subtree)
- **Decision**: Replace the copy branch body (`cwf-manage:490-496`) with the same delegation the subtree branch already uses (`:476-489`): set the env block with `CWF_METHOD=copy` and `system('bash', "$clone_dir/scripts/install.bash")` from `cwd=$git_root`, then reuse the shared rc-handling. The two branches now differ only by the `CWF_METHOD` value, so they collapse into one delegation block with a method variable.
- **Rationale**: Single laydown path (FR1). `install.bash main()` re-clones `file://$clone_dir`, checks out the resolved SHA, and runs `install_copy` — so the target version's installer governs, exactly as for subtree. Removes `update_copy`, `copy_tree` from `cwf-manage`; the guard logic (`_escapes_src`/`_collapse_dotdot`) is **relocated** to D2's helper, not reimplemented.
- **Trade-offs**: A second (local, `file://`) clone on update, identical to the cost the subtree path already pays. The copy branch's direct `create_skill_symlinks`/`create_agent_symlinks` calls become redundant (`install.bash post_install:256-259` creates them) — **subject to the D6 caller audit** before deletion.

### D2 — Guard extraction: new Perl helper `.cwf/scripts/command-helpers/cwf-check-tree-symlinks`
- **Decision**: Port `_escapes_src` and `_collapse_dotdot` (`cwf-manage:546-575`) **verbatim** into a standalone Perl helper. Interface: `cwf-check-tree-symlinks <root>...` — walk each root with `File::Find`, and for each symlink apply the escape check against the root it was found under. On the first violating symlink, print `refusing escaping symlink target: <entry> -> <link>` to STDERR and exit non-zero; exit 0 if all roots are clean. No mutation, no disk-following (lexical canonicalisation only, as today).
- **Rationale**: One audited implementation reused by both entry points (NFR3/NFR4). Living under `.cwf/scripts/` puts it **inside the hash ledger and `@CWF_INTERNAL_PREFIXES`** automatically (the `.cwf/scripts/` prefix already covers `command-helpers/`, verified at `security-review-changeset:57`) — satisfying FR3 with **no `@CWF_INTERNAL_PREFIXES` edit** and matching the pattern `install.bash` already uses to shell out to `.cwf/scripts/command-helpers/cwf-claude-settings-merge` (`install.bash:269`).
- **`@ARGV` decoding (must)**: the guard is launched from bash — bare `bash install.bash` (fresh) or `system('bash', ...)` from `cwf-manage` (update). `PERL5OPT=-CDSLA` is delivered by `.claude/settings.json` env (harness-injected); it is **not** exported by `install.bash` and **not** in the env block `cwf-manage` sets when delegating (`cwf-manage:478-482`). So the guard MUST NOT rely on ambient `-CA`: it MUST self-decode its `@ARGV` path arguments from UTF-8 octets at startup (e.g. `Encode::decode('UTF-8', $_)`), so non-ASCII paths canonicalise correctly regardless of caller env. (`cwf-claude-settings-merge` is unaffected because it reads JSON content, not non-ASCII path args.) Still declare `use utf8;` and `#!/usr/bin/env perl`; core modules only (`Encode` is core).
- **Coverage note**: this is a verbatim port of the *logic*, but **broader scope** — today's copy guard (`copy_tree` in `update_copy`) walks only `.cwf`, `.claude/skills`, `.claude/agents`; `.claude/rules` was never guarded on the copy path. The helper now also guards `.claude/rules` (a real `cp -r` source). Do not trim the root list back to three.
- **Trade-offs**: A new ~40-line helper. Net simpler than today's two divergent copy paths once `update_copy`/`copy_tree` are removed.

### D3 — Guard invocation: single site in `install_copy`, before the destructive `rm -rf`
- **Decision**: In `install_copy` (`install.bash:211-248`), invoke `"$clone_dir/.cwf/scripts/command-helpers/cwf-check-tree-symlinks"` over the roots about to be copied, **after the `git checkout` (`:218`) but before the `CWF_FORCE` `rm -rf` (`:221-223`)** — not merely before the first `cp -r`. A non-zero exit aborts the install via `die`.
  - **Critical ordering (fail-closed)**: under `CWF_FORCE=1` (always set on the `cwf-manage` update path) `install_copy` does `rm -rf .cwf .cwf-skills .cwf-rules .cwf-agents` at `:221-223`, *between* checkout and the first `cp -r`. A guard placed after that removal would wipe the user's existing install **and then** abort on an escaping source — destructive-then-abort, the opposite of fail-closed. The guard MUST precede the `rm -rf` so a refused source tree leaves the existing install intact.
  - **Single source of truth for roots (no drift)**: the guard-root list and the `cp -r` source list MUST be the same list — define one array of `(source-root, dest)` pairs in `install_copy` and iterate it both for the guard and for the copies (applying the existing `-d` existence guard for the conditional `.claude/rules`/`.claude/agents` roots so the helper is never handed a non-existent root). This prevents a future fifth `cp -r` source from being added without a matching guarded root (the FR4(e) drift risk).
  - `cp -r` preserves in-tree (relative, non-escaping) symlinks as symlinks; the guard only rejects escaping ones, so legitimate template symlinks survive unchanged.
- **Rationale**: Both fresh install (`main → install_copy`) and update (`cwf-manage` delegates → `install.bash main → install_copy`) funnel through this one site, so a single guard call satisfies FR2 for both paths. **This closes a real gap**: a fresh `CWF_FORCE=1 bash install.bash` copy install performs `cp -r` with no symlink-escape guard whatsoever today.
- **Trade-offs**: `install.bash` gains a Perl call at the copy step. Perl is already required at laydown — `post_install` shells out to the Perl `cwf-claude-settings-merge` (`install.bash:269`) — though note `check_prerequisites` (`:42-81`) does **not** currently assert Perl explicitly; this design relies on the existing implicit requirement, not a new check.

### D4 — Trust model: guard runs from the laid-down (target-version) copy
- **Decision**: The guard executed is the one in the clone install.bash operates on (the target version), not `cwf-manage`'s currently-installed copy. Documented and accepted.
- **Rationale**: Consistent with the established "target version's laydown governs" delegation model adopted for subtree in Task 155/159. Choosing to install or update from a source already entails trusting that version's installer.
- **Trade-offs / threat note (for security review)**: Versus today's copy-update path, where `cwf-manage`'s installed (hash-verified) guard checks the clone, convergence shifts the guard to the target-version copy. A wholly-malicious source could ship a neutered guard — but that is out of scope under the same reasoning the subtree path already accepts, and is unchanged by this task for subtree. Set against this: the change is a **net security gain** because it adds a guard to the fresh copy-install path, which has none today.
- **Rejected alternative**: `cwf-manage` runs its own installed guard as a pre-flight before delegating (belt-and-braces). Rejected: reintroduces a second guard-invocation site and re-couples `cwf-manage` to laydown concerns, for a threat already out of scope — directly against FR1's single-path goal.

### D5 — `.cwf-rules`: governed by `run_apply_artefacts`, parity with subtree
- **Decision**: Treat `run_apply_artefacts` (`cwf-manage:503`, unconditional after both branches) as the authoritative `.cwf-rules` step — it already applies the `cwf-rules-bundle` `tree-replace` strategy (`cwf-apply-artefacts:87`). `install_copy`'s `cp -r .cwf-rules` (`install.bash:235`) is then reconciled by that same tree-replace, exactly as on the subtree path today (`install_subtree` adds `.cwf-rules` via subtree, then `run_apply_artefacts` replaces it).
- **Rationale**: No new reconciliation logic. The converged copy update produces the same `.cwf-rules` sequence the subtree update already exercises; the difference from today's copy update (which never laid `.cwf-rules` in `update_copy` but still ran `run_apply_artefacts`) collapses to parity with subtree.
- **Rules symlinks also double-pass (idempotent)**: `post_install` creates `.claude/rules/cwf-*.md` symlinks via `create_cwf_symlinks` (`install.bash:258`), then `run_apply_artefacts` regenerates them via the `claude-rules-symlinks` strategy (`cwf-apply-artefacts:91`). This is pre-existing parity with the subtree path and idempotent; the convergence does not introduce it.
- **Trade-offs**: Relies on `tree-replace` and symlink regeneration being authoritative/idempotent. Expected failure signature: copy-update output diverging from subtree-update output. Verified empirically by AC8 — diff the copy-update vs subtree-update produced trees, covering **both** `.cwf-rules/` contents **and** `.claude/rules/` symlinks.

### D6 — Dead-code removal gated on a caller audit and on the guard being live elsewhere
- **Decision**: Before deleting any sub, enumerate every caller in `cwf-manage` (`grep -n 'subname'`). Definitely removed: `update_copy`, `copy_tree` (copy-branch-only). Removed if-and-only-if no other caller: the copy branch's `create_skill_symlinks`/`create_agent_symlinks` calls. After deletion, re-check unused imports — `File::Copy` (`copy`) is the prime removal candidate (only `copy_tree` uses it); `File::Find` (`find`) and `File::Path` (`rmtree`/`make_path`) likely stay because `create_*_symlinks` use `make_path` and any retained helpers may use them, so confirm rather than assume.
- **Ordering constraint (security-critical)**: `update_copy`/`copy_tree` are the *current* home of the guard logic. They MUST NOT be deleted until (a) `cwf-check-tree-symlinks` exists and is in the hash ledger, and (b) `install_copy` invokes it — otherwise there is a window where the copy path lays down a tree with no escape guard. Enforce the D2→D3→D1/D6 order.
- **Rationale**: Task 155 orphan-enumeration lesson; prevents breaking an unrelated caller and prevents a guard-coverage gap during the refactor.

### D7 — Integrity refresh
- **Decision**: Add a `scripts` entry for `cwf-check-tree-symlinks` to `.cwf/security/script-hashes.json` (path/permissions/sha256) in the same commit that creates the helper. Refresh `cwf-manage`'s recorded sha256 in the same commit that edits it. No `install-manifest.json` entry is needed — that file tracks post-processed artefacts (gitignore lines, rules bundle), not plain scripts, which are laid down as part of the `.cwf/` tree.
- **Rationale**: Hash-updates convention; keeps `cwf-manage validate` green at every phase commit (FR6/AC9).

## System Design

### Component Overview
- **`cwf-check-tree-symlinks`** (new, `.cwf/scripts/command-helpers/`): the sole symlink-escape guard. Pure validation, no mutation.
- **`install_copy`** (`scripts/install.bash`): invokes the guard against the clone, then performs the `cp -r` laydown. Now the single copy-laydown implementation.
- **`cmd_update` copy branch** (`cwf-manage`): delegates to `install.bash` (D1). No longer owns laydown or the guard.
- **`run_apply_artefacts` → `cwf-apply-artefacts`** (unchanged): authoritative `.cwf-rules` and other artefact application after laydown.

### Data Flow
**Fresh copy install**: `install.bash main` → clone + checkout → `install_copy` → **guard(clone roots)** → abort-or-`cp -r` → `post_install` (symlinks, settings-merge, version).
**Copy update**: `cwf-manage update` → clone + resolve SHA → copy branch sets env (`CWF_METHOD=copy`, `CWF_FORCE=1`, `CWF_SOURCE=file://$clone_dir`, `CWF_REF=$sha`) → `system bash install.bash` → [same fresh-install flow on the local clone] → back in `cwf-manage`: `run_apply_artefacts` → `run_settings_merge` → `apply_exact_perms_or_die` → authoritative version write.

### Interface Design
```
cwf-check-tree-symlinks <root>...
  exit 0            all symlinks under all roots are in-tree
  exit non-zero     first escaping symlink found; message on STDERR:
                    "refusing escaping symlink target: <entry> -> <link>"
  (no stdout, no filesystem mutation, lexical canonicalisation only)
```
Escape definition (preserved verbatim from `_escapes_src`): target is absolute, OR resolves outside the root after `..` collapsing, OR resolves to exactly the root.

## Constraints
- Reuse the audited Perl logic verbatim; no second-language reimplementation (NFR4).
- Core Perl modules only; POSIX-only; `PERL5OPT=-CDSLA` + `use utf8;` (project Perl convention).
- Hash refresh in the same commit as each hashed-file edit (D7).
- Guard must run before any mutation and be fail-closed (NFR5).

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [x] **Complexity**: 3+ concerns? Borderline — new helper, install.bash edit, cwf-manage convergence, ledger refresh; all coupled around one convergence and sequenced (D2 before D3 before D1).
- [ ] **Risk**: isolation needed? Guard relocation is the sensitive part but is a verbatim port with both-path regression tests.
- [ ] **Independence**: separable? No — the helper must exist before either caller can use it.

**Decision**: Flat task. No subtasks.

## Validation
- [ ] Design review completed (Step 8 plan review below)
- [ ] FR1-FR5 each map to a decision (FR1→D1/D6, FR2→D2/D3, FR3→D2/D7, FR4→D1, FR5→D5)
- [ ] Integrity boundary resolved (D2/D7): guard inside ledger + prefixes, no prefix edit

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
D1–D7 implemented as designed. D2's location choice (`.cwf/scripts/command-helpers/cwf-check-tree-symlinks`) gave ledger + `@CWF_INTERNAL_PREFIXES` coverage for free (no prefix edit). D3 (guard before the destructive `rm -rf`) was realised with an added `[[ -x ]]` precheck so a missing helper fails closed rather than silently skipping. D4 (guard runs from the target-version copy) is the one trust-model statement that needed explicit documentation in rollout/maintenance.

## Lessons Learned
Choosing the guard's location to sit inside the existing `.cwf/scripts/` prefix — rather than co-locating with `install.bash` at repo-root `scripts/` — was the decision that made FR2/FR3/NFR4 mutually consistent at zero extra coverage cost. A relocated security check must take its integrity coverage with it. See j-retrospective.md.
