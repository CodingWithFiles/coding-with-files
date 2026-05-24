# converge cwf-manage copy update onto install.bash - Requirements
**Task**: 161 (feature)

## Task Reference
- **Task ID**: internal-161
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/161-converge-cwf-manage-copy-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for converging the `cwf-manage` copy update method onto `scripts/install.bash`, preserving the upstream symlink-escape guard and extending it to the fresh copy-install path.

## Functional Requirements
### Core Features

- **FR1 — Copy update delegates laydown to `scripts/install.bash`**. The `cmd_update` copy branch (`cwf-manage:490-496`) MUST lay files down through `scripts/install.bash`, mirroring the subtree branch (`:476-489`) — single laydown path. No duplicate copy-laydown code may remain in `cwf-manage`. Treat the affected subs by fate:
  - **Removed** (copy-branch-only, dead after convergence): `update_copy`, `copy_tree`.
  - **Relocated, not deleted** (the audited guard logic, reused per FR2): `_escapes_src`, `_collapse_dotdot` move into the single shared guard helper — they are not reimplemented and not dropped.
  - **Contingent on caller audit**: the copy branch's direct `create_skill_symlinks`/`create_agent_symlinks` calls (`:495-496`) become redundant if `scripts/install.bash post_install` (`:256-259`) already creates the symlinks; remove them **only** if the audit proves no other caller in `cwf-manage` relies on them.
  - Every sub marked for removal MUST have all callers enumerated and proven unreferenced before deletion (Task 155 lesson); the audit MUST also check whether any core-module import becomes unused.
  - **Acceptance**: a copy-method update produces the same installed tree as today via the `scripts/install.bash` path; no `update_copy`/`copy_tree` call remains in the copy branch; `grep` shows no orphaned reference to any deleted sub; full suite green.

- **FR2 — Symlink-escape guard preserved and applied before copy on both paths**. The upstream-symlink-escape protection currently in `_escapes_src`/`_collapse_dotdot` (`cwf-manage:546-575`) MUST be preserved at equivalent strength — refusing a symlink whose target is (a) absolute, (b) `..`-escapes the source root, **or** (c) resolves to exactly the source root (`_escapes_src:553`, all three branches) — and MUST run over the upstream clone contents **before any `cp -r`** (a post-copy guard is too late; `cp -r` copies an escaping symlink verbatim). The guard MUST apply to **both** the converged copy-update path **and** the fresh copy-install path (`scripts/install.bash` `install_copy`, `:211-248`), which has no guard today.
  - **Acceptance**: a copy-method **update** and a fresh copy-method **install** each refuse an upstream tree containing (a) an absolute-target symlink, (b) a `..`-escaping symlink, and (c) a source-root-equal symlink, aborting before any file is written; a non-escaping symlink is preserved as today.

- **FR3 — Extracted guard is integrity-covered and lands inside the trust boundary**. The guard logic MUST be reachable by `scripts/install.bash` before copying, and the artefact that holds it MUST be verified by `cwf-manage validate` (recorded in `.cwf/security/script-hashes.json`) **and** matched by the security-review-changeset auto-include set (`@CWF_INTERNAL_PREFIXES`, `security-review-changeset:56-66`). Note the boundary tension carried from Task 159 D3: repo-root `scripts/` is **outside** both the hash ledger and `@CWF_INTERNAL_PREFIXES` (and `scripts/install.bash` itself is auto-reviewed only via the shebang-sniff fallback, not the unconditional CWF-internal include). Therefore the guard MUST NOT live in repo-root `scripts/`; it must land where existing coverage applies — under `.cwf/scripts/` (e.g. `.cwf/scripts/command-helpers/`, which the `.cwf/scripts/` prefix and the ledger already cover, and which is the pattern `scripts/install.bash` already uses by shelling out to `.cwf/scripts/command-helpers/cwf-claude-settings-merge` at `:269`) — or the design MUST add the chosen location to **both** the manifest and `@CWF_INTERNAL_PREFIXES`.
  - **Acceptance**: the guard artefact appears in `script-hashes.json` and is matched by `@CWF_INTERNAL_PREFIXES`; `cwf-manage validate` reports OK and **detects a deliberate tamper** of the guard (negative assertion, not merely presence in the list); the guard does not reside in repo-root `scripts/`.

- **FR4 — Copy delegation passes the full env contract**. The copy branch MUST pass the same env block the subtree branch uses (`cwf-manage:478-482`): `CWF_FORCE=1`, `CWF_METHOD=copy`, `CWF_SOURCE=file://$clone_dir`, `CWF_REF=$sha`. `CWF_FORCE=1` is mandatory — `scripts/install.bash` aborts (exit 3) if `.cwf/` exists unless forced (`:72-75`), and `.cwf/` always exists during an update; existing-tree removal shifts from `update_copy`'s `rmtree` to `install_copy`'s `CWF_FORCE` rm-rf branch (`:221-223`).
  - **Acceptance**: a copy-method update over an existing `.cwf/` install completes successfully (does not abort with "already installed").

- **FR5 — `.cwf-rules` laydown and removal-set reconciled (no double-handling)**. Today `update_copy` removes and re-lays only `.cwf`, `.cwf-skills`, `.cwf-agents` (`cwf-manage:608-610`) and **never touches `.cwf-rules`**; `install_copy`'s force branch removes `.cwf .cwf-skills .cwf-rules .cwf-agents` (`scripts/install.bash:222`) and copies `.cwf-rules` (`:235`). Convergence therefore **widens the removal set** so copy update now deletes and recreates `.cwf-rules`. The final `.cwf-rules` handling MUST be reconciled against `run_apply_artefacts` (`cwf-manage:503`, which itself lays down `.cwf-rules/` via `cwf-apply-artefacts`' `tree-replace` strategy) so `.cwf-rules` is laid down exactly once and consistently with the subtree/fresh-install result — no double-handling or inconsistent staging.
  - **Acceptance**: after a copy-method update, `.cwf-rules` is present, complete, laid down exactly once, and identical to the subtree-method result; an update interrupted mid-removal is recoverable by a fresh install (consistent with the laydown-in-progress "suggest fresh install on failure" behaviour).

### User Stories
- **As a security-conscious operator** I want a fresh copy-method install to refuse an upstream tree with out-of-tree symlinks **so that** a compromised source cannot plant out-of-tree references into my `.cwf/` (parity with the update path, which already refuses this) — this is the net-new behaviour.
- **As a maintainer** I want the guard inside the hash ledger and the auto-review set **so that** a tamper of the security check is caught by `cwf-manage validate` and re-reviewed on edit.

## Non-Functional Requirements
### Performance (NFR1)
- The guard adds at most one lexical walk of the upstream clone before copy; no added network clone, no measurable user-visible latency.

### Usability (NFR2)
- A refused escaping symlink MUST produce a clear, actionable error naming the offending entry and its target, on both the install and update paths (parity with today's `die_msg("refusing escaping symlink target: ...")`).

### Maintainability (NFR3)
- Convergence collapses two copy-laydown implementations (`cwf-manage` + `scripts/install.bash`) to one and removes the dead subs; the guard exists as a single implementation reused by both entry points.

### Security (NFR4)
- MUST NOT weaken upstream-symlink-escape protection under any option (no out-of-tree symlink may be written into the installed `.cwf/`). Reuse the existing audited Perl lexical logic; do **not** reimplement path canonicalisation in a second language.
- Because `scripts/install.bash` is bash and the audited guard is Perl, the guard MUST be extracted as a **single shared helper invoked by both** `scripts/install.bash` and `cwf-manage` — this is what makes NFR4, FR2, and FR3 mutually consistent (one audited implementation, called from both entry points, living inside the trust boundary).
- Extends the existing protection to the fresh copy-install path (net security gain).

### Reliability (NFR5)
- The guard MUST be fail-closed and evaluated before any filesystem mutation, so a refused tree leaves no partial laydown.
- The `CWF_FORCE` removal semantics MUST preserve the existing "remove existing, then lay down fresh" outcome. Note the removal set now also includes `.cwf-rules` (FR5); an update interrupted mid-removal MUST be no worse than today — recoverable by a fresh install.

## Constraints
- Dog-food repo — all changes go through the CWF workflow; no direct-to-main commits.
- Perl **core modules only**; POSIX-only (macOS system-Perl portability).
- **Hash refresh in the same commit as the underlying edit** (hash-updates convention); `cwf-manage validate` MUST pass after every phase commit. (Standing convention — gated by AC9, not minted as a task-specific FR.)
- Must not weaken the symlink-escape guard under any design option (carried from Task 159 b-requirements NFR4).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No (1-2 days).
- [ ] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? Borderline — convergence, guard-on-both-paths, integrity coverage, and two preconditions; all coupled around a single laydown convergence.
- [ ] **Risk**: high-risk component needing isolation? Guard relocation is sensitive but isolated and de-risked by Task 159 D3.
- [ ] **Independence**: separable? No — FR1 depends on FR2/FR3 (cannot converge without the guard being callable and verified); FR4/FR5 are preconditions of FR1.

**Decision**: Flat task. The FRs are sequential and coupled around one convergence; Task 159 deliberately scoped this as a single focused follow-up. No subtasks.

## Acceptance Criteria
- [ ] AC1 (FR1): copy-method update lays down via `scripts/install.bash`; no `update_copy`/`copy_tree` call remains in the copy branch; produced tree matches today's.
- [ ] AC2 (FR1): every removed sub's callers enumerated; `grep` shows no orphaned reference; any newly-unused core import removed; full suite green.
- [ ] AC3 (FR2): copy-method **update** refuses an absolute-target, a `..`-escaping, **and** a source-root-equal upstream symlink (all three `_escapes_src` branches); a non-escaping symlink is preserved.
- [ ] AC4 (FR2): fresh copy-method **install** refuses the same three escaping cases (previously-unguarded gap closed).
- [ ] AC5 (FR2): guard fires before any file is copied — an escaping tree leaves no partial laydown.
- [ ] AC6 (FR3): guard artefact recorded in `script-hashes.json`, matched by `@CWF_INTERNAL_PREFIXES`, **and** a deliberate tamper is detected by `cwf-manage validate`; the guard does not reside in repo-root `scripts/`.
- [ ] AC7 (FR4): copy-method update over an existing `.cwf/` install succeeds (full env block incl. `CWF_FORCE=1`; no "already installed" abort).
- [ ] AC8 (FR5): after a copy-method update, `.cwf-rules` is laid down exactly once and identical to the subtree-method result (no double-handling); an interrupted mid-removal is recoverable by fresh install.
- [ ] AC9 (integrity convention): `.cwf/security/script-hashes.json` refreshed in the same commit as each hashed-file edit; `cwf-manage validate` passes at every phase commit.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All of FR1–FR5 delivered; AC1–AC9 each demonstrated by ≥1 passing TC (AC9 as the process gate — `validate` clean at every phase commit). The net-new behaviour from the user story (fresh copy install refusing out-of-tree symlinks) is covered by TC-3; the maintainer story (tamper caught by `validate`) by TC-7. The guard landed under `.cwf/scripts/command-helpers/`, satisfying FR3's "inside the trust boundary, not repo-root scripts/" without any `@CWF_INTERNAL_PREFIXES` edit.

## Lessons Learned
Stating the removal/relocation fate of each sub explicitly in FR1 (removed vs relocated vs contingent-on-audit) made the exec-phase deletion unambiguous — the only surprise was the import count, which the requirement framed as "check whether any core-module import becomes unused" but didn't enumerate. See j-retrospective.md.
