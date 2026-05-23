# Converge cwf-manage update onto install.bash - Requirements
**Task**: 155 (feature)

## Task Reference
- **Task ID**: internal-155
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/155-converge-cwf-manage-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Define what a converged install/update lifecycle must do: one shared laydown consumed by both `install.bash` and `cwf-manage update`, with update running the target version's laydown, while preserving the update-only steps that `install.bash` lacks.

## Functional Requirements
### Core Features
- **FR1 — Single shared laydown**: Exactly one implementation of laydown (subtree split/add or copy + staging-dir set + symlink creation) is consumed by both fresh install and update. Adding or removing a staging dir requires editing one location, not symmetric edits in two scripts.
  - **Includes resolving the rules-delivery asymmetry**: `install.bash` lays down **four** staging dirs — `.cwf`, `.cwf-skills`, `.cwf-rules`, `.cwf-agents` (rules as a 4th subtree); `cmd_update` lays down **three** (`.cwf`, `.cwf-skills`, `.cwf-agents`) and delivers rules via `cwf-apply-artefacts` instead. The converged laydown must reconcile this to one mechanism, applied consistently by both paths.
  - AC: the staging-dir set is defined in a single source; both install and update reference it. AC asserts the **count and identity** of the staging-dir set (not merely "edited in one place"), and that rules are delivered by one named mechanism on both paths. A structural test/grep confirms no second independent copy of the laydown logic.
- **FR2 — Update runs target-version laydown**: `cwf-manage update <ref>` performs laydown using the *target* version's logic (e.g. by invoking the freshly-cloned target's `install.bash` via the `CWF_FORCE` remove-then-add path), not the installed (old) version's logic. (The exact delegation mechanism is a design-phase decision; the requirement is that the target version's laydown governs.)
  - AC: an end-to-end test updating to a target whose laydown differs from the installed version produces the *target's* directory structure.
- **FR3 — No subtree-pull squash conflicts across a version gap**: Update across a multi-version gap completes without `git subtree pull --squash` add/add conflicts (achieved via fresh remove-then-add rather than squash-merge).
  - AC: an end-to-end fixture test **with `cwf_method=subtree`** (the only method that has the squash-conflict problem; `copy` already does remove-then-add) spanning ≥2 minor versions completes cleanly with no conflict markers and a non-zero artefact diff.
- **FR4 — Preserve accreted update-only steps**: Convergence retains every step `cmd_update` has that `install.bash` lacks: update lock (flock), settings-parseable validation, install-manifest-SHA tamper check, clean-tree check, `cwf-apply-artefacts`, `cwf-claude-settings-merge`, manifest-SHA pin write. None may be dropped or reordered in a way that regresses them.
  - AC: end-to-end test asserts each step's observable effect (lock released at end, rules applied, settings merged, manifest SHA pinned, clean-tree enforced).
- **FR5 — chmod reconciliation (least-privilege exact perms)**: Post-update file permissions equal the **exact** recorded perms from `script-hashes.json` — the recorded set is `0444` (read-only data/agent files), `0500`, and `0700` (no `0755`) — replacing the blanket `chmod 0755`. Scope spans all recorded sections (`agents`/`data` 0444, `lib`/`scripts` 0500, dirs 0700), not just `.cwf/scripts`.
  - **Note**: this needs *exact-set* logic (remove excess bits), which the existing `cmd_fix_security` does **not** provide — it is additive-only (`cwf-manage:776` skips when required bits are already present and never lowers an over-permissioned file). Reusing `fix-security` as-is would leave blanket-`0755` files at `0755`. The design must extend `fix-security` (or add exact-set logic) so excess bits are removed.
  - AC: after update, perms **equal** the recorded value (not merely "validate passes" — `validate`'s `(actual & expected) == expected` semantics already accept the over-permissioned status quo). Sample at least one `0444` entry and one entry **outside `.cwf/scripts/`**, plus a `0500` and `0700` entry. `cwf-manage validate` also passes.
- **FR6 — Single, correct version-file write**: The `.cwf/version` write is reconciled so `cwf_install_manifest_sha` (D12) is written exactly once and not lost or double-written (`install.bash`'s `post_install` writes a 6-key version file *without* the manifest SHA; `cmd_update` adds it as the 7th key — a naive delegation drops the pin).
  - AC: after update, `.cwf/version` contains a valid `cwf_install_manifest_sha`; a **second** update immediately afterward passes `validate_install_manifest_sha` without a false-positive tamper error (proves the pin was written, not dropped).
- **FR7 — Documented forward-only recovery path**: Document the one-time `CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<src> bash install.bash` recovery for installs stuck on a pre-fix `cwf-manage`. No code claims to auto-repair pre-fix installs.
  - AC: `INSTALL.md` (or the canonical update doc) documents the recovery path and states the forward-only limitation.
- **FR8 — End-to-end test harness**: Build `t/fixtures/upstream-server/` (bare repo + 3-5 scripted CWF-shaped commits) and `t/cwf-manage-update-end-to-end.t` covering: cross-version-gap update (subtree method), manifest schema bump, and downgrade/rollback.
  - AC: the new test runs green and exercises all three scenarios. Out of scope: SIGKILL-during-rename atomicity, interactive D/A prompt branches.
- **FR9 — Ref/source input validation**: The user-supplied `<ref>` (`update <ref>`, `rollback <ref>`) is validated before it flows into any `git clone`/`checkout`/`subtree` or `bash install.bash` invocation — reject option-injection (leading `-`) and shell/path metacharacters (e.g. `git check-ref-format` and/or a `--` argv terminator).
  - AC: a test passing a ref of `--foo`, `;rm`, or `../escape` is rejected before any clone/checkout/exec side effect.
- **FR10 — Named trust boundary for target-version code execution**: Delegating laydown to the target ref's `install.bash` (FR2) means `cwf-manage update` now **executes code** fetched from `CWF_SOURCE` at `<ref>`, where today it lays down data only. This trust escalation is stated explicitly: the source/ref are trusted to the same degree as a fresh `bash install.bash` from that source, and the resolved SHA is recorded so the manifest-SHA tamper check still gates subsequent updates.
  - AC: the requirements/docs name this as code execution from the cloned ref (not "no new trust assumptions"); the resolved SHA is pinned in `.cwf/version` (per FR6).

### User Stories
- **As a** CWF maintainer **I want** install and update to share one laydown **so that** adding a staging dir is a single edit and the two paths cannot drift.
- **As a** CWF end user on an old install **I want** `cwf-manage update` to span multiple versions cleanly **so that** I am not blocked by `subtree pull --squash` conflicts.

## Non-Functional Requirements
### Performance (NFR1)
- Update wall-clock is dominated by the network clone (unchanged); convergence must not add a second clone or a second full subtree pass. No hard SLA.
- Acceptance: the end-to-end test completes within the existing suite's per-test time budget (no new multi-minute hang).

### Usability (NFR2)
- On a *graceful* step failure (non-crash), the error identifies which step failed and how to recover; the update must not leave a half-written `.cwf/version` or a held lock.
- Consistency: update and install emit comparable `[CWF]` progress logging.

### Maintainability (NFR3)
- Per-staging-dir maintenance drops from ~12 edits (6 in each script) to ~3 in one place (single source of truth for the staging-dir set + laydown).
- Single responsibility: the shared laydown does laydown only; update-only concerns (lock, manifest pin, artefacts, settings merge) stay in the update orchestration layer.

### Security (NFR4)
- Preserve existing protections: symlink-escape rejection (`_escapes_src`), flock update lock, install-manifest-SHA tamper detection.
- **`install.bash` is configured by environment variables** (`CWF_REF`, `CWF_SOURCE`, `CWF_FORCE`, `CWF_METHOD`), not positional argv. If update shells out to it, use a **list-form spawn** (`system` with the child environment set explicitly, no shell parsing) and validate the env-var *values* (ref, source) before placing them in the child environment. (See FR9 for ref validation.)
- **Trust boundary (FR10)**: executing the target ref's `install.bash` is code execution from the clone — a real escalation over today's data-only laydown. It is trusted to the same degree as a fresh `bash install.bash` from `CWF_SOURCE`; the resolved SHA is recorded (FR6) so the tamper check still gates.
- `script-hashes.json` hash refresh for `cwf-manage` occurs in the same commit as its modification. (`scripts/install.bash` lives outside `.cwf/` and is not in the hash ledger, so it carries no same-commit refresh obligation.)
- No new *network endpoints* beyond the existing `CWF_SOURCE` clone.

### Reliability (NFR5)
- Update is fail-safe under *graceful* step failure: no partial laydown that fails `validate` is left committed, and the lock is always released (scope-guarded filehandle).
- **Residual risk (accepted)**: remove-then-add laydown has a non-atomic window; a crash (e.g. SIGKILL) between remove and add can leave a partial tree. This is out of scope (FR8) and documented as a known limitation, recovered via the FR7 `CWF_FORCE` reinstall.
- Laydown delegation must use a `system`-style spawn (parent process survives), **not** `exec` — otherwise the Perl scope-guard that releases the flock never runs and the lock guarantee breaks.
- Downgrade/rollback (`cwf-manage rollback <older-ref>`) remains supported through the same converged path.

## Constraints
- POSIX-only, core-Perl-only (`cwf-manage`), Bash 4+ (`install.bash`).
- Forward-only: nothing shippable can repair installs already running a pre-fix `cwf-manage` (the old updater performs the update). Recovery is the documented manual `CWF_FORCE` path.
- Dog-fooding: this repo is itself the upstream; end-to-end tests must operate on a fixture remote and a temp working copy, never mutating the real repo's `.cwf/`.
- `cwf-manage` modifications require a same-commit `script-hashes.json` refresh.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Likely >1 week (consolidates 3 entries).
- [ ] **People**: No (solo).
- [x] **Complexity**: 3+ concerns (laydown convergence, chmod reconciliation, harness). **Triggered.**
- [x] **Risk**: High-risk install/update path. **Triggered.**
- [x] **Independence**: Harness and chmod separable from core convergence. **Triggered.**

3 signals triggered; **kept monolithic per user decision (2026-05-22)** recorded in a-task-plan.md. Concerns tracked as sequenced milestones (harness first).

## Acceptance Criteria
Per-FR ACs above are the single source of truth. Task-level roll-up for traceability:
- [ ] Shared laydown + rules-asymmetry resolved (FR1)
- [ ] Target-version laydown, no cross-version squash conflict (FR2, FR3)
- [ ] Accreted update-only steps preserved (FR4); exact least-privilege perms (FR5); manifest SHA pinned across two updates (FR6)
- [ ] Forward-only recovery documented (FR7); harness + three scenarios green (FR8)
- [ ] Ref validation (FR9) and trust boundary named (FR10)

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 155
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
FR1 delivered subtree-only; FR2/FR3/FR5/FR6/FR9/FR10 met and covered by `t/cwf-manage-update-end-to-end.t`; FR4 accreted steps preserved; FR7 (docs) and FR8 (harness) delivered. FR1 copy-path deferred to BACKLOG.

## Lessons Learned
The requirements assumed both install methods would converge onto one laydown. In practice FR1 was bounded to the subtree path because the copy path's symlink-escape guard (`_escapes_src`) has no cheap bash equivalent — a requirement-level constraint that only became visible at design/exec. See j-retrospective.md.
